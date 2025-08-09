-- VW_OSCILAR_PLAID_TRANSACTION_SUMMARY Query
-- This query provides account-level transaction summary data
-- 
-- Purpose: Account-level aggregation with transaction counts and metadata
-- Location: DATA:data:integrations[3]:response:items[0]:accounts[0]:transactions[]
-- One row per account with transaction summary information
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

accounts_with_transactions AS (
    SELECT 
        base.*,
        item.index AS item_index,
        item.value AS item_data,
        account.index AS account_index,
        account.value AS account_data,
        -- Count transactions for this account
        ARRAY_SIZE(account.value:transactions) AS total_transactions
    FROM oscilar_base base,
    LATERAL FLATTEN(input => base.plaid_assets_response:items) item,
    LATERAL FLATTEN(input => item.value:accounts) account
    WHERE account.value:transactions IS NOT NULL
      AND ARRAY_SIZE(account.value:transactions) > 0
)

SELECT 
    -- Historical VW_PLAID_TRANSACTION structure mapping
    
    -- Core timestamp and metadata fields
    oscilar_timestamp AS RECORD_CREATE_DATETIME,
    --application_id AS LEAD_GUID,  -- Commented out due to inconsistent request_id
    application_id AS application_id,
    borrower_id AS customer_id,
    oscilar_request_id AS PLAID_REQUEST_ID,
    total_transactions AS TOTAL_TRANSACTIONS,  -- ✅ NOW AVAILABLE from transaction count
    --'oscilar_v1' AS SCHEMA_VERSION,  -- Identifying this as Oscilar source
    TO_TIMESTAMP(plaid_assets_response:date_generated::varchar) AS PLAID_CREATE_DATE,  -- Asset report generation date
    
    -- Plaid Assets specific fields
    plaid_assets_response:asset_report_id::varchar AS ASSET_REPORT_ID,
    plaid_assets_response:asset_report_token::varchar AS ASSET_REPORT_TOKEN,
    plaid_assets_response:days_requested::int AS DAYS_REQUESTED,
    
    -- Account identification
    account_index AS ACCOUNT_INDEX,
    account_data:account_id::varchar AS ACCOUNT_ID,
    account_data:days_available::int AS ACCOUNT_DAYS_AVAILABLE,
    
    -- Store raw transaction data for flattening in detail view
    account_data:transactions AS TRANSACTIONS_RAW,
    account_data AS ACCOUNT_RAW,
    item_data AS ITEM_RAW,
    
    -- Metadata for troubleshooting
    oscilar_record_id AS OSCILAR_RECORD_ID,
    item_index AS PLAID_ITEM_INDEX

FROM accounts_with_transactions

-- Quality filters
WHERE total_transactions > 0  -- Only include accounts with transaction data

-- Order by most recent first, then by account
ORDER BY oscilar_timestamp DESC, account_index;