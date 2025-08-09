-- Extract Plaid Asset Report Items data from Oscilar JSON payloads
-- Recreating structure similar to BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_ASSET_REPORT_ITEMS
-- Author: Claude Code Assistant
-- Date: 2025-08-08

WITH plaid_asset_data AS (
    SELECT 
        DATA:data:input:payload:applicationId::VARCHAR as application_id,
        DATA:data:input:payload:borrowerId::VARCHAR as borrower_id,
        DATA:data:input:oscilar:timestamp::TIMESTAMP AS record_create_timestamp,
        --DATA:data:input:oscilar:request_id::VARCHAR as lead_guid,  -- leadGuid from request_id
        integration.value as plaid_integration
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
    LATERAL FLATTEN(input => DATA:data:integrations) integration
    WHERE 
        -- Apply filter early for performance (test applications)
        DATA:data:input:payload:applicationId::VARCHAR IN ('2278944', '2159240', '2064942', '2038415', '1914384')
        AND integration.value:name::STRING = 'Plaid_Assets'
        AND integration.value:response:items IS NOT NULL
),

plaid_assets_base AS (
    SELECT 
        record_create_timestamp,
        application_id,
        borrower_id,
        -- Map Plaid Assets response data from integrations array
        plaid_integration:response:asset_report_id::STRING AS asset_report_id,
        plaid_integration:parameters:access_tokens[0]::STRING AS plaid_token_id,
        plaid_integration:response:client_report_id::STRING AS client_report_id,
        plaid_integration:response:date_generated::STRING AS date_generated,
        plaid_integration:response:days_requested::STRING AS days_requested,
        -- Extract items array for flattening
        plaid_integration:response:items AS items_array
    FROM plaid_asset_data
),

-- Flatten the items array to match the target view structure  
plaid_assets_items AS (
    SELECT 
        pb.record_create_timestamp,
        pb.asset_report_id,
        pb.application_id AS application_id, -- Using application_id as lead identifier
        --pb.application_id AS lead_id,   -- Using application_id as lead identifier  
        pb.borrower_id AS customer_id, -- Using application_id as member identifier
        pb.plaid_token_id,
        NULL AS schema_version, -- Not present in Oscilar structure
        pb.date_generated AS asset_report_timestamp,
        NULL AS prev_asset_report_id, -- Not present in Oscilar structure
        -- Report level fields
        pb.client_report_id,
        pb.date_generated,
        pb.days_requested,
        -- Item-level data from flattened items array
        items.index AS item_index,
        items.value AS items,
        items.value:date_last_updated::STRING AS date_last_updated,
        items.value:institution_id::STRING AS institution_id,
        items.value:institution_name::STRING AS institution_name,
        items.value:item_id::STRING AS item_id
    FROM plaid_assets_base pb,
    LATERAL FLATTEN(input => pb.items_array) items
)

SELECT 
    record_create_timestamp,
    asset_report_id,
    application_id,
    customer_id,
    plaid_token_id,
    schema_version,
    asset_report_timestamp,
    prev_asset_report_id,
    client_report_id,
    date_generated,
    days_requested,
    item_index,
    items,
    date_last_updated,
    institution_id,
    institution_name,
    item_id
FROM plaid_assets_items
ORDER BY lead_guid, item_index;