-- Approach 1: Query base table with minimal JSON extraction
-- Only extract what we need for validation

CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.TEMP_OSCILAR_MINIMAL AS
SELECT 
    DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
    DATA:data:input:payload:applicationId::varchar AS lead_guid,
    DATA:data:input:payload:borrowerId::varchar AS member_id,
    DATA:data:integrations[3]:name::varchar AS integration_name,
    -- Only check if response exists, don't parse it yet
    CASE WHEN DATA:data:integrations[3]:response IS NOT NULL THEN 1 ELSE 0 END AS has_response
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
LIMIT 1000;