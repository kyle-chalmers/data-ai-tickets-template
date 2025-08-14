-- =====================================================================
-- GIACT Data View Deployment Script
-- =====================================================================
-- Purpose: Deploy GIACT parsing view to DEVELOPMENT.FRESHSNOW
-- Data Source: ARCA.FRESHSNOW.MVW_HM_Verification_Responses (prod data)
-- Target: DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
-- =====================================================================

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- =====================================================================
-- CREATE GIACT DATA VIEW IN DEVELOPMENT
-- =====================================================================

CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA(
    -- Application and customer identifiers
    APPLICATION_ID,
    BORROWER_ID,
    GIACT_INTEGRATION_NAME,
    CACHE_USED,
    
    -- Customer information from payload
    PAYLOAD_FIRST_NAME,
    PAYLOAD_LAST_NAME,
    PAYLOAD_SSN,
    CITY,
    STATE,
    POSTAL_CODE,
    STREET,
    FICO_SCORE,
    ANNUAL_INCOME,
    
    -- GIACT Parameters (request data sent to GIACT)
    GIACT_ACCOUNT_NUMBER,
    GIACT_ROUTING_NUMBER,
    GIACT_CUSTOMER_FIRST_NAME,
    GIACT_CUSTOMER_LAST_NAME,
    GIACT_CUSTOMER_TAX_ID,
    GIACT_AUTHENTICATE_ENABLED,
    GIACT_VERIFY_ENABLED,
    GIACT_UNIQUE_ID,
    
    -- GIACT Response Data (verification results from GIACT)
    ACCOUNT_ADDED_DESCRIPTION,
    ACCOUNT_ADDED_DATE,
    ACCOUNT_CLOSED_DESCRIPTION,
    ACCOUNT_CLOSED_DATE,
    ACCOUNT_LAST_UPDATED_DESCRIPTION,
    ACCOUNT_LAST_UPDATED_DATE,
    ACCOUNT_RESPONSE_CODE,
    BANK_ACCOUNT_TYPE,
    BANK_NAME,
    CONSUMER_ALERT_MESSAGES,
    GIACT_CREATED_DATE,
    CUSTOMER_RESPONSE_CODE,
    ERROR_MESSAGE,
    ITEM_REFERENCE_ID,
    VERIFICATION_RESPONSE,
    FUNDS_CONFIRMATION_RESULT,
    OFAC_LIST_POTENTIAL_MATCHES,
    
    -- Additional GIACT response fields
    DOMAIN_REGISTRY,
    EMAIL_ADDRESS_INFORMATION_RESULT,
    G_IDENTIFY_KBA_RESULT,
    IP_ADDRESS_INFORMATION_RESULT,
    MATCHED_BUSINESS_DATA,
    MATCHED_PERSON_DATA,
    MOBILE_IDENTIFY_RESULT,
    MOBILE_LOCATION_RESULT,
    MOBILE_VERIFY_RESULT,
    PHONE_INTELLIGENCE_RESULT,
    VOIDED_CHECK_IMAGE,
    
    -- Calculated fields
    ACCOUNT_AGE_DAYS,
    
    -- Timestamp information
    OSCILAR_TIMESTAMP,
    OSCILAR_REQUEST_ID
) COPY GRANTS AS 
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
-- CREATE BRIDGE VIEW IN BUSINESS_INTELLIGENCE_DEV
-- =====================================================================

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA COPY GRANTS AS
SELECT * FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA;

-- =====================================================================
-- VERIFICATION QUERIES
-- =====================================================================

-- Check FRESHSNOW view was created successfully
SELECT 'FRESHSNOW view created successfully' as status, COUNT(*) as record_count 
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA;

-- Check BRIDGE view was created successfully
SELECT 'BRIDGE view created successfully' as status, COUNT(*) as record_count 
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_OSCILAR_GIACT_DATA;

-- Sample data verification
SELECT APPLICATION_ID, BANK_NAME, GIACT_ROUTING_NUMBER, ACCOUNT_AGE_DAYS 
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA 
LIMIT 5;

-- =====================================================================
-- DEPLOYMENT COMPLETE
-- =====================================================================