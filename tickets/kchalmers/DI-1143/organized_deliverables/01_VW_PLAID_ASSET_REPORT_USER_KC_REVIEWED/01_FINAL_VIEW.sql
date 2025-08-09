-- VW_PLAID_ASSET_REPORT_USER Recreation Query (OPTIMIZED)
-- Extracts Plaid Asset Report metadata from Oscilar verification data
-- Simplified extraction using request_id as leadGuid

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
        -- Apply filter early for performance
        DATA:data:input:payload:applicationId::VARCHAR IN ('2278944', '2159240', '2064942', '2038415', '1914384')
        AND integration.value:name::STRING = 'Plaid_Assets'
)

SELECT 
    -- Standard tracking columns (from input.oscilar.timestamp)
    record_create_timestamp AS Record_Create_Datetime,
    
    -- Asset Report identification
    plaid_integration:response:asset_report_id::STRING AS Asset_Report_Id,
    
    -- Lead identification (now extracted from Income_Verification_Model)
    --lead_guid AS Lead_Guid,
    application_id AS Lead_Id,
    borrower_id AS Customer_Id,  -- borrowerId from payload
    application_id AS Member_Id,  -- applicationId for backwards compatibility
    -- Access tokens from parameters
    plaid_integration:parameters:access_tokens[0]::STRING AS Plaid_Token_Id,
    
    -- Schema and timestamp information  
    --NULL AS schema_version,  -- Not available in Oscilar data
    plaid_integration:response:date_generated::STRING AS asset_report_timestamp,
    --NULL AS prev_asset_report_id,  -- Not visible in current data structure
    
    -- Report level information
    plaid_integration:response:client_report_id::STRING AS client_report_id,
    plaid_integration:response:date_generated::STRING AS date_generated,
    plaid_integration:parameters:days_requested::STRING AS days_requested,
    
    -- User information from parameters
    plaid_integration:parameters:client_user_id::STRING AS client_user_id,
    -- User details from response (if available)
    plaid_integration:response:user:email::STRING AS user_email,
    plaid_integration:response:user:firstName::STRING AS user_first_name,
    plaid_integration:response:user:lastName::STRING AS user_last_name,
    plaid_integration:response:user:middleName::STRING AS user_middle_name,
    plaid_integration:response:user:phoneNumber::STRING AS user_phone_number,
    plaid_integration:response:user:ssn::STRING AS user_ssn

FROM plaid_asset_data;
