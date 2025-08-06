-- DI-1143: Validate Plaid Record Count
-- Simple count query to verify the 5,171 records with Plaid access tokens

SELECT COUNT(*) AS total_records_with_plaid_tokens
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE 
    CONTAINS(DATA::string, 'plaidAccessToken')
    AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
    AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0;

-- Additional breakdown for analysis
SELECT 
    ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) AS token_count,
    COUNT(*) AS record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE 
    CONTAINS(DATA::string, 'plaidAccessToken')
    AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
    AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0
GROUP BY ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens)
ORDER BY token_count;