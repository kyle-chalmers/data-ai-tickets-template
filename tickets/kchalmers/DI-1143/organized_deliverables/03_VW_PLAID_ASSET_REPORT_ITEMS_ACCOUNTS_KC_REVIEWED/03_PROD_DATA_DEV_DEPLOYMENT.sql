/* 
Production Data to Development Deployment Script for VW_OSCILAR_PLAID_ASSET_REPORT_ACCOUNTS
DI-1143: GIACT 5.8 Parser - Uses PROD data source, deploys to DEV environments
Source: ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS (PRODUCTION)
Target: DEVELOPMENT.FRESHSNOW and BUSINESS_INTELLIGENCE_DEV.BRIDGE
*/

DECLARE
    -- Using production data source
    v_source_db varchar default 'ARCA';
    
    -- Deploying to development environments
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';

BEGIN

-- FRESHSNOW section (Development database with Production data)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_OSCILAR_PLAID_ASSET_REPORT_ACCOUNTS COPY GRANTS AS 
            -- VW_OSCILAR_PLAID_ACCOUNT Alignment Query using MVW
            -- This query transforms data to match historical VW_PLAID_TRANSACTION_ACCOUNT structure
            -- Source: ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS (PRODUCTION DATA)

            WITH oscilar_base AS (
                SELECT 
                    -- Core MVW metadata
                    APPLICATION_ID as application_id,
                    BORROWER_ID as borrower_id,
                    DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
                    
                    -- Extract both response and full integration object for parameters access
                    integration.value:response AS plaid_assets_response,
                    integration.value AS plaid_integration
                    
                FROM ' || v_source_db || '.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS,
                LATERAL FLATTEN(input => DATA:data:integrations) integration
                WHERE 
                    -- Only records with successful Plaid Assets responses
                    integration.value:response:items IS NOT NULL
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
                application_id,  -- Keep as-is from JSON extraction
                borrower_id,     -- Keep as-is from JSON extraction
                
                -- Report metadata
                plaid_assets_response:date_generated::varchar AS asset_report_timestamp,
                plaid_assets_response:client_report_id::varchar AS client_report_id,
                plaid_assets_response:date_generated::varchar AS date_generated,
                plaid_assets_response:days_requested::varchar AS days_requested,
                
                -- Item-level fields
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
                account_data:ownership_type::varchar AS ownership_type,
                account_data:subtype::varchar AS account_subtype,
                account_data:transactions AS account_transactions,
                account_data:type::varchar AS account_type,
                
                -- Account balances (matching target DDL field names)
                account_data:balances:available::varchar AS account_balances_available,
                account_data:balances:current::float AS account_balances_current,
                account_data:balances:iso_currency_code::varchar AS account_balances_iso_currency_code,
                account_data:balances:limit::varchar AS account_balances_limit,
                account_data:balances:margin_loan_amount::varchar AS account_balances_margin_loan_amount,
                account_data:balances:unofficial_currency_code::varchar AS account_balances_unofficial_currency_code,
                
                -- Account owners
                account_data:owners AS account_owners

            FROM accounts_flattened

            -- Quality filters
            WHERE account_data IS NOT NULL  -- Ensure we have account data
              AND account_data:account_id IS NOT NULL  -- Must have Plaid account ID
    ');

-- BRIDGE section (Development BI with reference to Development Freshsnow)   
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_OSCILAR_PLAID_ASSET_REPORT_ACCOUNTS COPY GRANTS AS 
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_OSCILAR_PLAID_ASSET_REPORT_ACCOUNTS
    ');
   
END;