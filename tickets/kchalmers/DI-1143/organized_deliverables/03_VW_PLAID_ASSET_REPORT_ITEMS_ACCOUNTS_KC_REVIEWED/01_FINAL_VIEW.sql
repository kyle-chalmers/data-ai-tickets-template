-- VW_OSCILAR_PLAID_ACCOUNT Alignment Query
-- This query transforms Oscilar data to match historical VW_PLAID_TRANSACTION_ACCOUNT structure
-- Account-level data with GIACT bank verification integration using working base pattern

WITH oscilar_base AS (
    SELECT 
        -- Core Oscilar metadata
        DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
        DATA:data:input:oscilar:request_id::varchar AS oscilar_request_id,
        DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
        
        -- Entity identifiers
        DATA:data:input:payload:applicationId::varchar AS application_id,
        DATA:data:input:payload:borrowerId::varchar AS borrower_id,
        
        -- Extract both response and full integration object for parameters access
        integration.value:response AS plaid_assets_response,
        integration.value AS plaid_integration
        
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
)

SELECT 
    -- Core fields matching other organized deliverables
    
    -- Core timestamp and metadata fields (matching target DDL)
    oscilar_timestamp AS Record_Create_Datetime,
    plaid_assets_response:asset_report_id::varchar AS Asset_Report_Id,
    --NULL AS Lead_Guid,  -- Commented out due to inconsistent request_id
    application_id AS Lead_Id,
    borrower_id AS Member_Id,
    plaid_integration:parameters:access_tokens[0]::STRING AS Plaid_Token_Id,
    
    -- Report metadata (missing from our query)
    NULL AS schema_version,  -- Not available in Oscilar
    plaid_assets_response:date_generated::varchar AS asset_report_timestamp,
    NULL AS prev_asset_report_id,  -- Not available
    plaid_assets_response:client_report_id::varchar AS client_report_id,
    plaid_assets_response:date_generated::varchar AS date_generated,
    plaid_assets_response:days_requested::varchar AS days_requested,
    
    -- Item-level fields (missing from our query)
    item_data:date_last_updated::varchar AS date_last_updated,
    item_data:institution_id::varchar AS institution_id,
    item_data:institution_name::varchar AS institution_name,
    item_data:item_id::varchar AS item_id,
    
    -- Account identification from Plaid Assets
    account_data:account_id::varchar AS account_id,
    account_data:days_available::varchar AS days_available,
    account_data:historical_balances AS historical_balances,
    account_data:mask::varchar AS account_mask,
    account_data:name::varchar AS account_name,
    account_data:official_name::varchar AS account_official_name,
    account_data:subtype::varchar AS account_subtype,
    account_data:transactions AS account_transactions,
    account_data:type::varchar AS account_type,
    
    -- Account balances (matching target DDL field names)
    account_data:balances:available::varchar AS account_balances_available,
    account_data:balances:current::float AS account_balances_current,
    account_data:balances:iso_currency_code::varchar AS account_balances_isoCurrencyCode,
    account_data:balances:unofficial_currency_code::varchar AS account_balances_unofficialCurrencyCode,
    
    -- Account owners (missing from our query)
    account_data:owners AS account_owners

FROM accounts_flattened

-- Quality filters
WHERE account_data IS NOT NULL  -- Ensure we have account data
  AND account_data:account_id IS NOT NULL  -- Must have Plaid account ID

-- Order by most recent first
ORDER BY oscilar_timestamp DESC, account_index;