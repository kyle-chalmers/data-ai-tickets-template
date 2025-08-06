-- DI-1143: Create VW_OSCILAR_PLAID_TRANSACTION_DETAIL Alignment View
-- This view flattens individual Plaid transactions to match historical VW_PLAID_TRANSACTION_DETAIL structure
-- 
-- BREAKTHROUGH: Complete transaction detail data available in Plaid Assets responses
-- Individual transactions: DATA:data:integrations[3]:response:items[0]:accounts[0]:transactions[N]
--
-- DO NOT EXECUTE without approval - this is for review purposes only

CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION_DETAIL AS
(
WITH oscilar_base AS (
    SELECT 
        -- Core Oscilar metadata
        DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
        DATA:data:input:oscilar:request_id::varchar AS oscilar_request_id,
        DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
        
        -- Entity identifiers
        DATA:data:input:payload:applicationId::varchar AS application_id,
        DATA:data:input:payload:borrowerId::varchar AS borrower_id,
        
        -- Extract Plaid Assets response
        DATA:data:integrations[3]:response AS plaid_assets_response
        
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE 
        -- Only records with successful Plaid Assets responses
        DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
        AND DATA:data:integrations[3]:response:items IS NOT NULL
        AND ARRAY_SIZE(DATA:data:integrations[3]:response:items) > 0
),

accounts_flattened AS (
    SELECT 
        base.*,
        item.index AS item_index,
        item.value AS item_data,
        account.index AS account_index,
        account.value AS account_data
    FROM oscilar_base base,
    LATERAL FLATTEN(input => base.plaid_assets_response:items) item,
    LATERAL FLATTEN(input => item.value:accounts) account
    WHERE account.value:transactions IS NOT NULL
      AND ARRAY_SIZE(account.value:transactions) > 0
),

transactions_flattened AS (
    SELECT 
        af.*,
        transaction.index AS transaction_index,
        transaction.value AS transaction_data
    FROM accounts_flattened af,
    LATERAL FLATTEN(input => af.account_data:transactions) transaction
)

SELECT 
    -- Base fields from VW_PLAID_TRANSACTION (inherited)
    oscilar_timestamp AS RECORD_CREATE_DATETIME,
    application_id AS LEAD_GUID,
    NULL AS LEAD_ID,  
    borrower_id AS MEMBER_ID,
    oscilar_request_id AS PLAID_REQUEST_ID,
    ARRAY_SIZE(account_data:transactions) AS TOTAL_TRANSACTIONS,
    'oscilar_v1' AS SCHEMA_VERSION,
    TO_TIMESTAMP(plaid_assets_response:date_generated::varchar) AS PLAID_CREATE_DATE,
    
    -- Account fields (inherited from VW_PLAID_TRANSACTION_ACCOUNT)
    account_index AS ACCOUNT_INDEX,
    account_data:account_id::varchar AS ACCOUNT_ID,
    
    -- Account details from Plaid Assets
    CASE 
        WHEN LEN(account_data:mask::varchar) > 0 THEN account_data:mask::varchar
        ELSE CONCAT('****', RIGHT(account_data:account_id::varchar, 4))
    END AS ACCOUNT_MASK,
    
    account_data:name::varchar AS ACCOUNT_NAME,
    account_data:official_name::varchar AS ACCOUNT_OFFICIAL_NAME,
    account_data:subtype::varchar AS ACCOUNT_SUBTYPE,
    account_data:type::varchar AS ACCOUNT_TYPE,
    account_data:verification_status::varchar AS ACCOUNT_VERIFICATION_STATUS,
    
    -- Balance information - ✅ NOW AVAILABLE from Plaid Assets
    account_data:balances:available::float AS ACCOUNT_BALANCE_AVAILABLE,
    account_data:balances:current::float AS ACCOUNT_BALANCE_CURRENT,
    account_data:balances:iso_currency_code::varchar AS ACCOUNT_BALANCE_ISO_CURRENCY_CODE,
    account_data:balances:limit::float AS ACCOUNT_BALANCE_LIMIT,
    account_data:balances:unofficial_currency_code::varchar AS ACCOUNT_BALANCE_UNOFFICIAL_CURRENCY_CODE,
    
    -- Transaction detail fields - ✅ ALL AVAILABLE from transaction data
    transaction_data:authorized_date::varchar AS TRANSACTION_AUTHORIZED_DATE,
    ARRAY_TO_STRING(transaction_data:category, ', ') AS TRANSACTION_CATEGORY,  -- Flatten category array
    transaction_data:category_id::varchar AS TRANSACTION_CATEGORY_ID,
    transaction_data:date::varchar AS TRANSACTION_DATE,
    transaction_data:iso_currency_code::varchar AS TRANSACTION_ISO_CURRENCY_CODE,
    
    -- Location information as JSON string (matches historical format)
    CASE 
        WHEN transaction_data:location IS NOT NULL 
        THEN transaction_data:location::varchar
        ELSE NULL
    END AS TRANSACTION_LOCATION,
    
    transaction_data:merchant_name::varchar AS TRANSACTION_MERCHANT_NAME,
    transaction_data:name::varchar AS TRANSACTION_NAME,
    transaction_data:original_description::varchar AS TRANSACTION_ORIGINAL_DESCRIPTION,
    transaction_data:payment_channel::varchar AS TRANSACTION_PAYMENT_CHANNEL,
    
    -- Payment metadata as JSON string
    CASE 
        WHEN transaction_data:payment_meta IS NOT NULL 
        THEN transaction_data:payment_meta::varchar
        ELSE NULL
    END AS TRANSACTION_PAYMENT_META,
    
    transaction_data:pending::varchar AS TRANSACTION_PENDING,
    transaction_data:pending_transaction_id::varchar AS TRANSACTION_PENDING_TRANSACTION_ID,
    transaction_data:check_number::varchar AS TRANSACTION_CODE,  -- Map check_number to transaction_code
    transaction_data:transaction_id::varchar AS TRANSACTION_ID,
    transaction_data:transaction_type::varchar AS TRANSACTION_TYPE,
    transaction_data:unofficial_currency_code::varchar AS TRANSACTION_UNOFFICIAL_CURRENCY_CODE,
    
    -- Transaction amount - ✅ CRITICAL FIELD NOW AVAILABLE
    transaction_data:amount::float AS TRANSACTION_AMOUNT,
    
    -- Additional useful fields for Prism requirements
    transaction_data:date_transacted::varchar AS TRANSACTION_DATE_TRANSACTED,
    
    -- Prism-specific fields derived from transaction data
    CASE 
        WHEN transaction_data:amount::float < 0 THEN 'credit'  -- Negative amounts are money in (credits)
        WHEN transaction_data:amount::float > 0 THEN 'debit'   -- Positive amounts are money out (debits)
        ELSE 'unknown'
    END AS TRANSACTION_DEBIT_CREDIT_INDICATOR,
    
    -- Credit category information
    transaction_data:credit_category:primary::varchar AS TRANSACTION_CREDIT_CATEGORY_PRIMARY,
    transaction_data:credit_category:detailed::varchar AS TRANSACTION_CREDIT_CATEGORY_DETAILED,
    
    -- Metadata for debugging and analysis
    transaction_index AS TRANSACTION_INDEX,
    oscilar_record_id AS OSCILAR_RECORD_ID,
    plaid_assets_response:asset_report_id::varchar AS ASSET_REPORT_ID

FROM transactions_flattened

-- Order by entity, account, then transaction date (most recent first)
ORDER BY 
    application_id,
    account_index, 
    transaction_data:date::date DESC,
    transaction_index
);

-- Add comments explaining the view
COMMENT ON VIEW DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION_DETAIL IS 
'Oscilar-to-DATA_STORE alignment view for individual Plaid transaction details.
BREAKTHROUGH: Complete transaction detail data available in Plaid Assets responses.
This view provides all transaction-level fields required for Prism vendor integration.
Includes amounts, dates, descriptions, merchant info, categories, and balance data.
Created for DI-1143: Align Oscilar Plaid Data Structure With Historical Plaid DATA_STORE Structure';