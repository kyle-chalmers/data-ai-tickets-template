/* 
Deploy script for VW_OSCILAR_PLAID_ASSET_REPORT_ITEMS
DI-1143: GIACT 5.8 Parser - Plaid Asset Report Items View
*/

DECLARE
    -- prod databases
    v_de_db varchar default 'ARCA';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN

-- FRESHSNOW section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_OSCILAR_PLAID_ASSET_REPORT_ITEMS COPY GRANTS AS 
            -- Extract Plaid Asset Report Items data from MVW
            -- Recreating structure similar to BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_ASSET_REPORT_ITEMS
            -- Source: ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS

            WITH plaid_asset_data AS (
                SELECT 
                    APPLICATION_ID as application_id,
                    BORROWER_ID as borrower_id,
                    DATA:data:input:oscilar:timestamp::TIMESTAMP AS record_create_timestamp,
                    integration.value as plaid_integration
                FROM ' || v_de_db || '.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS,
                LATERAL FLATTEN(input => DATA:data:integrations) integration
                WHERE 
                    integration.value:response:items IS NOT NULL
            ),

            plaid_assets_base AS (
                SELECT 
                    record_create_timestamp,
                    application_id,
                    borrower_id,
                    -- Map Plaid Assets response data from integrations array
                    plaid_integration:response:asset_report_id::STRING AS asset_report_id,
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
                    pb.application_id,  -- Keep as-is from JSON extraction
                    pb.borrower_id,     -- Keep as-is from JSON extraction
                    pb.date_generated AS asset_report_timestamp,
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
                record_create_timestamp AS Record_Create_Datetime,
                asset_report_id AS Asset_Report_Id,
                application_id,  -- Keep as-is from JSON extraction
                borrower_id,     -- Keep as-is from JSON extraction
                asset_report_timestamp,
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
    ');

-- BRIDGE section    
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_OSCILAR_PLAID_ASSET_REPORT_ITEMS COPY GRANTS AS 
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_OSCILAR_PLAID_ASSET_REPORT_ITEMS
    ');
   
END;