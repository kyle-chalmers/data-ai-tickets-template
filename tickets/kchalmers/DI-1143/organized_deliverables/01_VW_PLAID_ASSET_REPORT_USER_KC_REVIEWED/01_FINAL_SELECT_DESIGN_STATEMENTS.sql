-- VW_OSCILAR_PLAID_ASSET_REPORT_USERS Recreation Query using MVW
-- Extracts Plaid Asset Report metadata from MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS
-- Source: ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS

WITH plaid_asset_data AS (
    SELECT 
        APPLICATION_ID as application_id,
        BORROWER_ID as borrower_id,
        DATA:data:input:oscilar:timestamp::TIMESTAMP AS record_create_timestamp,
        integration.value as plaid_integration
    FROM ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS,
    LATERAL FLATTEN(input => DATA:data:integrations) integration
    WHERE 
        -- Apply filter early for performance
        APPLICATION_ID IN ('2278944', '2159240', '2064942', '2038415', '1914384')
)

SELECT 
    -- Standard tracking columns (from input.oscilar.timestamp)
    record_create_timestamp AS Record_Create_Datetime,
    
    -- Asset Report identification
    plaid_integration:response:asset_report_id::STRING AS Asset_Report_Id,
    
    -- Lead identification - keeping original JSON field names with dots
    application_id,  -- Keep as-is from JSON extraction
    borrower_id,     -- Keep as-is from JSON extraction
    
    -- Access tokens from parameters (only in this view)
    plaid_integration:parameters:access_tokens[0]::STRING AS Plaid_Token_Id,
    
    -- Timestamp information  
    plaid_integration:response:date_generated::STRING AS asset_report_timestamp,
    
    -- Report level information
    plaid_integration:response:client_report_id::STRING AS client_report_id,
    plaid_integration:response:date_generated::STRING AS date_generated,
    plaid_integration:parameters:days_requested::STRING AS days_requested,
    
    -- User details from response (if available)
    plaid_integration:response:user:email::STRING AS user_email,
    plaid_integration:response:user:first_name::STRING AS user_first_name,
    plaid_integration:response:user:last_name::STRING AS user_last_name,
    plaid_integration:response:user:middle_name::STRING AS user_middle_name,
    plaid_integration:response:user:phone_number::STRING AS user_phone_number,
    plaid_integration:response:user:ssn::STRING AS user_ssn

FROM plaid_asset_data;