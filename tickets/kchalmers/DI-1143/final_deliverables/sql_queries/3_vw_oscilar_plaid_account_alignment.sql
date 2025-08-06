-- DI-1143: Create VW_OSCILAR_PLAID_ACCOUNT Alignment View
-- This view transforms Oscilar data to match historical VW_PLAID_TRANSACTION_ACCOUNT structure
-- 
-- IMPORTANT: This view provides ACCOUNT-LEVEL data only
-- Transaction-level data is NOT available in Oscilar due to Plaid API failures
--
-- DO NOT EXECUTE without approval - this is for review purposes only

CREATE OR REPLACE VIEW DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT AS
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
        DATA:data:input:payload:firstName::varchar AS first_name,
        DATA:data:input:payload:lastName::varchar AS last_name,
        
        -- Account array for flattening
        DATA:data:input:payload:accounts AS accounts_array,
        DATA:data:input:payload:plaidAccessTokens AS plaid_tokens_array,
        
        -- Integration responses for metadata
        DATA:data:integrations AS integrations_array,
        
        -- Full data for fallback
        DATA AS full_oscilar_data
        
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE 
        -- Only records with Plaid access tokens
        CONTAINS(DATA::string, 'plaidAccessToken')
        AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
        AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0
),

accounts_flattened AS (
    SELECT 
        base.*,
        accounts.index AS account_index,
        accounts.value AS account_data
    FROM oscilar_base base,
    LATERAL FLATTEN(input => base.accounts_array) accounts
),

giact_metadata AS (
    SELECT 
        af.*,
        -- Extract GIACT integration response for account metadata
        giact_integration.value:response AS giact_response
    FROM accounts_flattened af,
    LATERAL FLATTEN(input => af.integrations_array) giact_integration
    WHERE giact_integration.value:name::string = 'giact_5_8'
)

SELECT 
    -- Historical VW_PLAID_TRANSACTION_ACCOUNT structure mapping
    
    -- Core timestamp and metadata fields
    oscilar_timestamp AS RECORD_CREATE_DATETIME,
    application_id AS LEAD_GUID,  -- Using applicationId as primary entity identifier
    NULL AS LEAD_ID,  -- ❌ NOT AVAILABLE in Oscilar
    borrower_id AS MEMBER_ID,
    oscilar_request_id AS PLAID_REQUEST_ID,
    NULL AS TOTAL_TRANSACTIONS,  -- ❌ NO TRANSACTION DATA available
    'oscilar_v1' AS SCHEMA_VERSION,  -- Identifying this as Oscilar source
    oscilar_timestamp AS PLAID_CREATE_DATE,  -- Using Oscilar timestamp as proxy
    
    -- Account index and identification
    account_index AS ACCOUNT_INDEX,
    account_data:id::varchar AS ACCOUNT_ID,  -- Plaid account ID when available
    CASE 
        WHEN LEN(account_data:accountNumber::varchar) > 4 
        THEN CONCAT('****', RIGHT(account_data:accountNumber::varchar, 4))
        ELSE account_data:accountNumber::varchar 
    END AS ACCOUNT_MASK,  -- Masked account number for security
    
    -- Account descriptive information
    COALESCE(
        giact_response:BankName::varchar,
        'Unknown Institution'
    ) AS ACCOUNT_NAME,  -- Using institution name from GIACT
    
    COALESCE(
        giact_response:BankName::varchar,
        'Unknown Institution'  
    ) AS ACCOUNT_OFFICIAL_NAME,  -- Same as account name from GIACT
    
    -- Account classification from GIACT
    CASE 
        WHEN giact_response:BankAccountType::varchar LIKE '%Checking%' THEN 'checking'
        WHEN giact_response:BankAccountType::varchar LIKE '%Savings%' THEN 'savings'  
        WHEN giact_response:BankAccountType::varchar IS NOT NULL THEN LOWER(giact_response:BankAccountType::varchar)
        ELSE 'depository'  -- Default assumption
    END AS ACCOUNT_SUBTYPE,
    
    'depository' AS ACCOUNT_TYPE,  -- Assuming all are depository accounts
    
    -- Verification status
    CASE 
        WHEN giact_response:VerificationResponse::int = 6 THEN 'verified'
        WHEN giact_response:VerificationResponse::int IS NOT NULL THEN 'processing'
        ELSE 'unverified'
    END AS ACCOUNT_VERIFICATION_STATUS,
    
    -- Balance information - ✅ NOW AVAILABLE from Plaid Assets when successful
    COALESCE(
        GET_PATH(full_oscilar_data, 'data.integrations[3].response.items[0].accounts[' || account_index || '].balances.available')::float,
        NULL
    ) AS ACCOUNT_BALANCE_AVAILABLE,
    
    COALESCE(
        GET_PATH(full_oscilar_data, 'data.integrations[3].response.items[0].accounts[' || account_index || '].balances.current')::float,
        NULL
    ) AS ACCOUNT_BALANCE_CURRENT,
    
    COALESCE(
        GET_PATH(full_oscilar_data, 'data.integrations[3].response.items[0].accounts[' || account_index || '].balances.iso_currency_code')::varchar,
        'USD'
    ) AS ACCOUNT_BALANCE_ISO_CURRENCY_CODE,
    
    COALESCE(
        GET_PATH(full_oscilar_data, 'data.integrations[3].response.items[0].accounts[' || account_index || '].balances.limit')::float,
        NULL
    ) AS ACCOUNT_BALANCE_LIMIT,
    
    COALESCE(
        GET_PATH(full_oscilar_data, 'data.integrations[3].response.items[0].accounts[' || account_index || '].balances.unofficial_currency_code')::varchar,
        NULL
    ) AS ACCOUNT_BALANCE_UNOFFICIAL_CURRENCY_CODE,
    
    -- Additional useful fields for debugging/analysis
    account_data:accountNumber::varchar AS SOURCE_ACCOUNT_NUMBER,  -- Full account number (be careful with PII)
    account_data:routingNumber::varchar AS SOURCE_ROUTING_NUMBER,
    GET_PATH(plaid_tokens_array, '[0]')::varchar AS PRIMARY_PLAID_TOKEN,  -- First token
    ARRAY_SIZE(plaid_tokens_array) AS PLAID_TOKEN_COUNT,
    
    -- GIACT verification details for debugging
    giact_response:AccountResponseCode::int AS GIACT_ACCOUNT_RESPONSE_CODE,
    giact_response:CustomerResponseCode::int AS GIACT_CUSTOMER_RESPONSE_CODE,
    giact_response:CreatedDate::timestamp AS GIACT_VERIFICATION_DATE,
    
    -- Metadata for troubleshooting
    oscilar_record_id AS OSCILAR_RECORD_ID,
    first_name AS SOURCE_FIRST_NAME,
    last_name AS SOURCE_LAST_NAME

FROM giact_metadata

-- Quality filters
WHERE account_data IS NOT NULL  -- Ensure we have account data
  AND account_data:accountNumber IS NOT NULL  -- Must have account number

-- Order by most recent first
ORDER BY oscilar_timestamp DESC, account_index
);

-- Add comments explaining the view
COMMENT ON VIEW DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT IS 
'Oscilar-to-DATA_STORE alignment view for Plaid account data. 
BREAKTHROUGH: Now includes balance information from successful Plaid Assets responses.
This view provides account-level information with GIACT verification and Plaid balance data when available.
Created for DI-1143: Align Oscilar Plaid Data Structure With Historical Plaid DATA_STORE Structure';