-- DI-1143: Extract Oscilar Records with Plaid Access Tokens
-- This query retrieves all records from vw_oscilar_verifications that contain actual Plaid access tokens
-- Total expected records: 5,171

SELECT 
    -- Oscilar metadata
    DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
    DATA:data:input:oscilar:request_id::varchar AS oscilar_request_id,
    DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
    
    -- Application/Entity identifiers
    DATA:data:input:payload:applicationId::varchar AS application_id,
    DATA:data:input:payload:borrowerId::varchar AS borrower_id,
    DATA:data:input:payload:firstName::varchar AS first_name,
    DATA:data:input:payload:lastName::varchar AS last_name,
    
    -- Plaid access tokens (primary filter criteria)
    DATA:data:input:payload:plaidAccessTokens AS plaid_access_tokens,
    ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) AS token_count,
    
    -- Account information
    DATA:data:input:payload:accounts AS accounts_array,
    ARRAY_SIZE(DATA:data:input:payload:accounts) AS account_count,
    
    -- Extract first account details for convenience
    DATA:data:input:payload:accounts[0]:accountNumber::varchar AS primary_account_number,
    DATA:data:input:payload:accounts[0]:routingNumber::varchar AS primary_routing_number,
    DATA:data:input:payload:accounts[0]:id::varchar AS primary_plaid_account_id,
    DATA:data:input:payload:accounts[0]:plaidAccessToken::varchar AS primary_plaid_token,
    
    -- Full JSON for detailed analysis
    DATA AS full_json_data

FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS

WHERE 
    -- Filter for records with actual Plaid access tokens
    CONTAINS(DATA::string, 'plaidAccessToken')
    AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
    AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0

ORDER BY 
    DATA:data:input:oscilar:timestamp DESC;