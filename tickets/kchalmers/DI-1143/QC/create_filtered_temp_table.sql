-- Create a filtered temp table with specific date range
-- Using more restrictive filters to reduce data volume

CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.TEMP_PLAID_SAMPLE_FILTERED AS
WITH recent_oscilar AS (
    SELECT 
        DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
        DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
        DATA:data:integrations[3]:response AS plaid_response
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
    AND DATA:data:input:oscilar:timestamp::date >= DATEADD('day', -7, CURRENT_DATE())
    LIMIT 100
)
SELECT 
    oscilar_record_id,
    oscilar_timestamp,
    plaid_response
FROM recent_oscilar
WHERE plaid_response IS NOT NULL;