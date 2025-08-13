/* 
Deploy script for VW_OSCILAR_PLAID_ASSET_REPORT_TRANSACTIONS
DI-1143: GIACT 5.8 Parser - Plaid Asset Report Transaction Details View
*/

DECLARE
    -- prod databases
    v_de_db varchar default 'ARCA';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN

-- FRESHSNOW section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_OSCILAR_PLAID_ASSET_REPORT_TRANSACTIONS COPY GRANTS AS 
            -- VW_PLAID_ASSET_REPORT_ITEMS_ACCOUNTS_TRANSACTIONS Recreation Query using MVW
            -- This query flattens individual Plaid transactions to match the historical structure
            -- Source: ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS

            WITH oscilar_base AS (
                SELECT 
                    -- Core MVW metadata
                    APPLICATION_ID as application_id,
                    BORROWER_ID as borrower_id,
                    DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,
                    
                    -- Extract Plaid Assets response using dynamic parsing
                    integration.value:response AS plaid_assets_response
                    
                FROM ' || v_de_db || '.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS,
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
                WHERE account.value:transactions IS NOT NULL
                  AND ARRAY_SIZE(account.value:transactions) > 0
            ),

            transactions_flattened AS (
                SELECT 
                    af.*,
                    transaction.index AS transaction_index,
                    transaction.value AS transaction_data
                FROM accounts_flattened af,
                LATERAL FLATTEN(input => af.account_data:transactions) transaction
            )

            SELECT 
                -- Fields from VW_PLAID_ASSET_REPORT_USER (for linking)
                oscilar_timestamp AS Record_Create_Datetime,
                plaid_assets_response:asset_report_id::varchar AS Asset_Report_Id,
                application_id,  -- Keep as-is from JSON extraction
                borrower_id,     -- Keep as-is from JSON extraction
                
                -- Transaction detail fields matching target DDL structure
                account_data:account_id::varchar AS account_id,
                transaction_data:account_owner::varchar AS account_owner,
                transaction_data:amount::varchar AS transaction_amount,
                CASE 
                    WHEN transaction_data:category IS NOT NULL AND transaction_data:category != \'[]\'
                    THEN transaction_data:category
                    ELSE NULL
                END AS transaction_category,
                transaction_data:category_id::varchar AS transaction_category_id,
                transaction_data:credit_category::varchar AS credit_category,
                transaction_data:date::varchar AS transaction_date,
                transaction_data:date_transacted::varchar AS date_transacted,
                transaction_data:iso_currency_code::varchar AS transaction_iso_currency_code,
                transaction_data:location AS transaction_location,
                transaction_data:location:address::varchar AS location_address,
                transaction_data:location:city::varchar AS location_city,
                transaction_data:location:country::varchar AS location_country,
                transaction_data:location:lat::varchar AS location_lat,
                transaction_data:location:lon::varchar AS location_lon,
                transaction_data:location:postal_code::varchar AS location_postal_code,
                transaction_data:location:region::varchar AS location_region,
                transaction_data:location:store_number::varchar AS location_store_number,
                transaction_data:name::varchar AS transaction_name,
                transaction_data:original_description::varchar AS transaction_original_description,
                transaction_data:payment_meta AS transaction_payment_metadata,
                transaction_data:payment_meta:by_order_of::varchar AS transaction_by_order_of,
                transaction_data:payment_meta:payee::varchar AS transaction_payee,
                transaction_data:payment_meta:payer::varchar AS transaction_payer,
                transaction_data:payment_meta:payment_method::varchar AS transaction_payment_method,
                transaction_data:payment_meta:payment_processor::varchar AS transaction_payment_processor,
                transaction_data:payment_meta:ppd_id::varchar AS transaction_ppd_id,
                transaction_data:payment_meta:reason::varchar AS transaction_reason,
                transaction_data:payment_meta:reference_number::varchar AS transaction_reference_number,
                transaction_data:pending::varchar AS transaction_pending,
                transaction_data:pending_transaction_id::varchar AS pending_transaction_id,
                transaction_data:transaction_id::varchar AS transaction_id,
                transaction_data:transaction_type::varchar AS transaction_type,
                transaction_data:unofficial_currency_code::varchar AS transaction_unofficial_currency_code,
                
                -- Additional transaction fields
                transaction_data:merchant_name::varchar AS merchant_name,
                transaction_data:check_number::varchar AS check_number

            FROM transactions_flattened
    ');

-- BRIDGE section    
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_OSCILAR_PLAID_ASSET_REPORT_TRANSACTIONS COPY GRANTS AS 
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_OSCILAR_PLAID_ASSET_REPORT_TRANSACTIONS
    ');
   
END;