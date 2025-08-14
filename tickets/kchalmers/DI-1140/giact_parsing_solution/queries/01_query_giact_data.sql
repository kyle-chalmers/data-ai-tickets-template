-- =====================================================================
-- GIACT Data Query Script
-- =====================================================================
-- Purpose: Query GIACT data directly from production source
-- Source: ARCA.FRESHSNOW.MVW_HM_Verification_Responses
-- Usage: Raw SELECT statement for GIACT data extraction
-- =====================================================================

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- =====================================================================
-- GIACT DATA EXTRACTION FROM PRODUCTION SOURCE
-- =====================================================================

SELECT 
    -- Application and customer identifiers
    vr.APPLICATION_ID,
    vr.BORROWER_ID,
    
    -- Integration metadata
    giact.value:name::VARCHAR as giact_integration_name,
    giact.value:cache_used::BOOLEAN as cache_used,
    
    -- Customer information from payload
    vr.DATA:data:input:payload:firstName::VARCHAR as payload_first_name,
    vr.DATA:data:input:payload:lastName::VARCHAR as payload_last_name,
    vr.DATA:data:input:payload:ssn::VARCHAR as payload_ssn,
    vr.DATA:data:input:payload:city::VARCHAR as city,
    vr.DATA:data:input:payload:state::VARCHAR as state,
    vr.DATA:data:input:payload:postalCode::VARCHAR as postal_code,
    vr.DATA:data:input:payload:street::VARCHAR as street,
    vr.DATA:data:input:payload:ficoScore::INTEGER as fico_score,
    vr.DATA:data:input:payload:annualIncome::INTEGER as annual_income,
    
    -- GIACT Parameters (request data sent to GIACT)
    giact.value:parameters:Check:AccountNumber::VARCHAR as giact_account_number,
    giact.value:parameters:Check:RoutingNumber::VARCHAR as giact_routing_number,
    giact.value:parameters:Customer:FirstName::VARCHAR as giact_customer_first_name,
    giact.value:parameters:Customer:LastName::VARCHAR as giact_customer_last_name,
    giact.value:parameters:Customer:TaxID::VARCHAR as giact_customer_tax_id,
    giact.value:parameters:GAuthenticateEnabled::BOOLEAN as giact_authenticate_enabled,
    giact.value:parameters:GVerifyEnabled::BOOLEAN as giact_verify_enabled,
    giact.value:parameters:UniqueId::VARCHAR as giact_unique_id,
    
    -- GIACT Response Data (verification results from GIACT)
    giact.value:response:AccountAdded::VARCHAR as account_added_description,
    giact.value:response:AccountAddedDate::TIMESTAMP as account_added_date,
    giact.value:response:AccountClosed::VARCHAR as account_closed_description,
    giact.value:response:AccountClosedDate::TIMESTAMP as account_closed_date,
    giact.value:response:AccountLastUpdated::VARCHAR as account_last_updated_description,
    giact.value:response:AccountLastUpdatedDate::TIMESTAMP as account_last_updated_date,
    giact.value:response:AccountResponseCode::INTEGER as account_response_code,
    giact.value:response:BankAccountType::VARCHAR as bank_account_type,
    giact.value:response:BankName::VARCHAR as bank_name,
    giact.value:response:ConsumerAlertMessages::VARCHAR as consumer_alert_messages,
    giact.value:response:CreatedDate::TIMESTAMP as giact_created_date,
    giact.value:response:CustomerResponseCode::INTEGER as customer_response_code,
    giact.value:response:ErrorMessage::VARCHAR as error_message,
    giact.value:response:ItemReferenceId::BIGINT as item_reference_id,
    giact.value:response:VerificationResponse::INTEGER as verification_response,
    giact.value:response:FundsConfirmationResult::VARCHAR as funds_confirmation_result,
    giact.value:response:OfacListPotentialMatches::VARCHAR as ofac_list_potential_matches,
    
    -- Additional GIACT response fields
    giact.value:response:DomainRegistry::VARCHAR as domain_registry,
    giact.value:response:EmailAddressInformationResult::VARCHAR as email_address_information_result,
    giact.value:response:GIdentifyKbaResult::VARCHAR as g_identify_kba_result,
    giact.value:response:IpAddressInformationResult::VARCHAR as ip_address_information_result,
    giact.value:response:MatchedBusinessData::VARCHAR as matched_business_data,
    giact.value:response:MatchedPersonData::VARCHAR as matched_person_data,
    giact.value:response:MobileIdentifyResult::VARCHAR as mobile_identify_result,
    giact.value:response:MobileLocationResult::VARCHAR as mobile_location_result,
    giact.value:response:MobileVerifyResult::VARCHAR as mobile_verify_result,
    giact.value:response:PhoneIntelligenceResult::VARCHAR as phone_intelligence_result,
    giact.value:response:VoidedCheckImage::VARCHAR as voided_check_image,
    
    -- Calculated fields
    CASE 
        WHEN giact.value:response:AccountAddedDate::TIMESTAMP IS NOT NULL
        THEN DATEDIFF(DAY, giact.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE())
        ELSE NULL
    END as account_age_days,
    
    -- Timestamp information
    vr.DATA:data:input:oscilar:timestamp::TIMESTAMP as oscilar_timestamp,
    vr.DATA:data:input:oscilar:request_id::VARCHAR as oscilar_request_id

FROM ARCA.FRESHSNOW.MVW_HM_Verification_Responses vr,
LATERAL FLATTEN(input => vr.DATA:data:integrations) giact
WHERE 
    -- Filter for all GIACT integrations (flexible for version changes)
    giact.value:name::VARCHAR LIKE 'giact_%';

-- =====================================================================
-- SAMPLE QUERIES AND ANALYTICS
-- =====================================================================

-- Quick summary statistics
SELECT 
    'Total GIACT Records' as metric,
    COUNT(*) as value
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA

UNION ALL

SELECT 
    'Unique Banks',
    COUNT(DISTINCT BANK_NAME)
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA

UNION ALL

SELECT 
    'Records with Account Dates',
    COUNT(CASE WHEN ACCOUNT_ADDED_DATE IS NOT NULL THEN 1 END)
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA

UNION ALL

SELECT 
    'Average Account Age (Days)',
    ROUND(AVG(ACCOUNT_AGE_DAYS), 0)
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA
WHERE ACCOUNT_AGE_DAYS IS NOT NULL;

-- Recent account analysis (last 30 days)
SELECT 
    'Recent Accounts (≤30 days)' as category,
    COUNT(*) as count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA
WHERE ACCOUNT_AGE_DAYS <= 30

UNION ALL

SELECT 
    'Older Accounts (>30 days)',
    COUNT(*)
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA
WHERE ACCOUNT_AGE_DAYS > 30;

-- Verification response code distribution
SELECT 
    VERIFICATION_RESPONSE,
    CASE 
        WHEN VERIFICATION_RESPONSE = 1 THEN 'Account Verified'
        WHEN VERIFICATION_RESPONSE = 2 THEN 'Account Verified with Conditions'
        WHEN VERIFICATION_RESPONSE = 3 THEN 'Account Not Verified'
        WHEN VERIFICATION_RESPONSE = 4 THEN 'Account Closed'
        WHEN VERIFICATION_RESPONSE = 5 THEN 'Account Not Found'
        WHEN VERIFICATION_RESPONSE = 6 THEN 'Unable to Verify'
        WHEN VERIFICATION_RESPONSE = 9 THEN 'Other Response'
        ELSE 'Unknown (' || VERIFICATION_RESPONSE::VARCHAR || ')'
    END as verification_status,
    COUNT(*) as count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA
GROUP BY VERIFICATION_RESPONSE, verification_status;

-- Top 10 banks by volume
SELECT 
    BANK_NAME,
    COUNT(*) as account_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA
WHERE BANK_NAME IS NOT NULL
GROUP BY BANK_NAME
LIMIT 10;

-- Date range analysis
SELECT 
    MIN(ACCOUNT_ADDED_DATE) as earliest_account_date,
    MAX(ACCOUNT_ADDED_DATE) as latest_account_date,
    DATEDIFF(DAY, MIN(ACCOUNT_ADDED_DATE), MAX(ACCOUNT_ADDED_DATE)) as date_range_days
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA
WHERE ACCOUNT_ADDED_DATE IS NOT NULL;

-- =====================================================================
-- EXPORT COMMANDS
-- =====================================================================

-- Export full dataset to CSV
-- snow sql -f "query_giact_data.sql" --format csv > giact_full_dataset.csv

-- Export specific fields only
-- SELECT APPLICATION_ID, BANK_NAME, GIACT_ROUTING_NUMBER, ACCOUNT_AGE_DAYS 
-- FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA;

-- =====================================================================
-- SCRIPT COMPLETE
-- =====================================================================