-- QC Test 3: Historical vs Oscilar Schema Comparison
-- Purpose: Compare one record from each source to validate schema alignment
-- Validates: Column structure, data format consistency, field mappings

WITH historical_sample AS (
    SELECT 
        'HISTORICAL' as source,
        RECORD_CREATE_DATETIME::STRING as RECORD_CREATE_DATETIME,
        ASSET_REPORT_ID,
        LEAD_GUID,
        LEAD_ID,
        MEMBER_ID,
        PLAID_TOKEN_ID,
        SCHEMA_VERSION,
        ASSET_REPORT_TIMESTAMP,
        PREV_ASSET_REPORT_ID,
        CLIENT_REPORT_ID,
        DATE_GENERATED,
        DAYS_REQUESTED::STRING as DAYS_REQUESTED,
        ITEM_INDEX::STRING as ITEM_INDEX,
        DATE_LAST_UPDATED,
        INSTITUTION_ID,
        INSTITUTION_NAME,
        ITEM_ID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_ASSET_REPORT_ITEMS
    LIMIT 1
),

oscilar_sample AS (
    SELECT 
        'OSCILAR_EXTRACTED' as source,
        pb.record_create_datetime::STRING AS RECORD_CREATE_DATETIME,
        pb.asset_report_id AS ASSET_REPORT_ID,
        pb.application_id AS LEAD_GUID,
        pb.application_id AS LEAD_ID,
        pb.application_id AS MEMBER_ID,
        pb.plaid_token_id AS PLAID_TOKEN_ID,
        NULL AS SCHEMA_VERSION,
        pb.date_generated AS ASSET_REPORT_TIMESTAMP,
        NULL AS PREV_ASSET_REPORT_ID,
        pb.client_report_id AS CLIENT_REPORT_ID,
        pb.date_generated AS DATE_GENERATED,
        pb.days_requested AS DAYS_REQUESTED,
        items.index::STRING AS ITEM_INDEX,
        items.value:date_last_updated::STRING AS DATE_LAST_UPDATED,
        items.value:institution_id::STRING AS INSTITUTION_ID,
        items.value:institution_name::STRING AS INSTITUTION_NAME,
        items.value:item_id::STRING AS ITEM_ID
FROM (
    SELECT 
        CURRENT_TIMESTAMP AS record_create_datetime,
        DATA:data:input:payload:applicationId::VARCHAR AS application_id,
        integration.value:response:asset_report_id::STRING AS asset_report_id,
        integration.value:response:asset_report_token::STRING AS plaid_token_id,
        integration.value:response:client_report_id::STRING AS client_report_id,
        integration.value:response:date_generated::STRING AS date_generated,
        integration.value:response:days_requested::STRING AS days_requested,
        integration.value:response:items AS items_array
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
    LATERAL FLATTEN(input => DATA:data:integrations) integration
    WHERE integration.value:name::STRING = 'Plaid_Assets'
        AND integration.value:response:items IS NOT NULL
    LIMIT 1
) pb,
LATERAL FLATTEN(input => pb.items_array) items
    LIMIT 1
)

SELECT * FROM historical_sample
UNION ALL  
SELECT * FROM oscilar_sample;