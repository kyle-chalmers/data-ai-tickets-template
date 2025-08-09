-- QC Query 5: Compare with historical data structure
-- Purpose: Validate our extracted data matches historical patterns

-- First get a sample from historical data
SELECT 
    'HISTORICAL' as source,
    Asset_Report_Id,
    Lead_Id,
    Member_Id,
    client_user_id,
    date_generated,
    days_requested,
    user_email,
    user_first_name,
    user_last_name
FROM RAW_DATA_STORE.KAFKA.VW_PLAID_ASSET_REPORT_USER
WHERE Asset_Report_Id IS NOT NULL
LIMIT 3

UNION ALL

-- Then compare with our Oscilar extracted data structure
SELECT 
    'OSCILAR' as source,
    DATA:data:input:payload:Plaid_Assets:response:asset_report_id::STRING as Asset_Report_Id,
    DATA:data:input:payload:applicationId::VARCHAR as Lead_Id,
    DATA:data:input:payload:applicationId::VARCHAR as Member_Id,
    DATA:data:input:payload:Plaid_Assets:parameters:client_user_id::STRING as client_user_id,
    DATA:data:input:payload:Plaid_Assets:response:date_generated::STRING as date_generated,
    DATA:data:input:payload:Plaid_Assets:response:days_requested::STRING as days_requested,
    DATA:data:input:payload:Plaid_Assets:response:report:user:email::STRING as user_email,
    DATA:data:input:payload:Plaid_Assets:response:report:user:firstName::STRING as user_first_name,
    DATA:data:input:payload:Plaid_Assets:response:report:user:lastName::STRING as user_last_name
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:input:payload:applicationId::VARCHAR IN ('2278944', '2159240', '2064942', '2038415', '1914384')
    AND DATA:data:input:payload:Plaid_Assets:response:asset_report_id IS NOT NULL
ORDER BY source, Asset_Report_Id;