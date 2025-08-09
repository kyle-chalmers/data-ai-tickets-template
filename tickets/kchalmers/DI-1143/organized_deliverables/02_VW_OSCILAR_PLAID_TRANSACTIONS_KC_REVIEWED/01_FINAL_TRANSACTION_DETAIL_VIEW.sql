-- VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS_TRANSACTIONS Recreation Query
-- This query flattens individual Plaid transactions to match the historical structure
-- 
-- Target: Emulates VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS_TRANSACTIONS DDL
-- Individual transactions: DATA:data:integrations[3]:response:items[0]:accounts[0]:transactions[N]
-- One row per transaction for detailed transaction analysis
WITH oscilar_base AS (
    SELECT 
        -- Core Oscilar metadata
        DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
        DATA:data:input:oscilar:request_id::varchar AS oscilar_request_id,
        DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
        
        -- Entity identifiers  
        DATA:data:input:payload:applicationId::varchar AS application_id,
        DATA:data:input:payload:borrowerId::varchar AS borrower_id,
        
        -- Extract Plaid Assets response using dynamic parsing
        integration.value:response AS plaid_assets_response
        
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
    LATERAL FLATTEN(input => DATA:data:integrations) integration
    WHERE 
        -- Apply filter early for performance (test applications)
        DATA:data:input:payload:applicationId::VARCHAR IN ('2278944', '2159240', '2064942', '2038415', '1914384')
        -- Only records with successful Plaid Assets responses
        AND integration.value:name::STRING = 'Plaid_Assets'
        AND integration.value:response:items IS NOT NULL
        AND ARRAY_SIZE(integration.value:response:items) > 0
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
    -- Fields from VW_PLAID_ASSET_REPORT_USER (for linking)
    oscilar_timestamp AS Record_Create_Datetime,
    plaid_assets_response:asset_report_id::varchar AS Asset_Report_Id,
    --NULL AS Lead_Guid,  -- Commented out due to inconsistent request_id
    application_id AS application_id,
    borrower_id AS customer_id,
    NULL AS Plaid_Token_Id,  -- Would need to get from Plaid_Assets parameters
    
    -- Transaction detail fields matching target DDL structure
    account_data:account_id::varchar AS account_id,
    NULL AS account_owner,  -- Not available in Oscilar data
    transaction_data:amount::varchar AS transaction_amount,
    CASE 
        WHEN transaction_data:category IS NOT NULL AND transaction_data:category != '[]'
        THEN transaction_data:category
        ELSE NULL
    END AS transaction_category,
    transaction_data:category_id::varchar AS transaction_category_id,
    transaction_data:date::varchar AS transaction_date,
    transaction_data:date_transacted::varchar AS date_transacted,
    transaction_data:iso_currency_code::varchar AS transaction_iso_currency_code,
    transaction_data:location AS transaction_location,
    transaction_data:name::varchar AS transaction_name,
    transaction_data:original_description::varchar AS transaction_original_description,
    transaction_data:payment_meta AS transaction_payment_metadata,
    transaction_data:payment_meta:byOrderOf::varchar AS transaction_by_order_of,
    transaction_data:payment_meta:payee::varchar AS transaction_payee,
    transaction_data:payment_meta:payer::varchar AS transaction_payer,
    transaction_data:payment_meta:paymentMethod::varchar AS transaction_payment_method,
    transaction_data:payment_meta:paymentProcessor::varchar AS transaction_payment_processor,
    transaction_data:payment_meta:ppdId::varchar AS transaction_ppdId,
    transaction_data:payment_meta:reason::varchar AS transaction_reason,
    transaction_data:payment_meta:referenceNumber::varchar AS transaction_reference_Number,
    transaction_data:pending::varchar AS transaction_pending,
    transaction_data:pending_transaction_id::varchar AS pending_transaction_id,
    transaction_data:transaction_id::varchar AS transaction_id,
    transaction_data:transaction_type::varchar AS transaction_type,
    transaction_data:unofficial_currency_code::varchar AS transaction_unofficial_currency_code,
    
    -- Additional transaction fields
    transaction_data:merchant_name::varchar AS merchant_name,
    transaction_data:check_number::varchar AS check_number

FROM transactions_flattened

-- Order by entity, account, then transaction date (most recent first)
ORDER BY 
    application_id,
    account_index, 
    transaction_data:date::date DESC,
    transaction_index;