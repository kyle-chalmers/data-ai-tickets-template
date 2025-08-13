-- =====================================================================
-- DI-1140: Comprehensive GIACT 5.8 Data Parser
-- =====================================================================
-- Purpose: Extract and analyze GIACT banking verification data from 
--          DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
-- 
-- This script provides complete GIACT data extraction capabilities:
-- 1. Basic GIACT data extraction
-- 2. Fraud investigation analysis  
-- 3. Summary statistics
-- 4. Flexible filtering options
-- =====================================================================

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- Set parameters for fraud investigation
SET routing_number_filter = '071025661';
SET bank_name_pattern = '%BMO%';
SET recent_account_threshold = 30;
SET extended_search_threshold = 45;

-- =====================================================================
-- SECTION 1: COMPREHENSIVE GIACT DATA EXTRACTION
-- =====================================================================

-- Extract all GIACT 5.8 integration data with comprehensive fields
CREATE OR REPLACE TEMPORARY TABLE giact_extraction_base AS
SELECT 
    -- Application and customer identifiers
    DATA:data:input:payload:applicationId::VARCHAR as application_id,
    DATA:data:input:payload:borrowerId::VARCHAR as borrower_id,
    DATA:data:input:oscilar:timestamp::TIMESTAMP as oscilar_timestamp,
    DATA:data:input:oscilar:request_id::VARCHAR as oscilar_request_id,
    
    -- Customer information from payload
    DATA:data:input:payload:firstName::VARCHAR as payload_first_name,
    DATA:data:input:payload:lastName::VARCHAR as payload_last_name,
    DATA:data:input:payload:ssn::VARCHAR as payload_ssn,
    DATA:data:input:payload:city::VARCHAR as city,
    DATA:data:input:payload:state::VARCHAR as state,
    DATA:data:input:payload:postalCode::VARCHAR as postal_code,
    DATA:data:input:payload:street::VARCHAR as street,
    DATA:data:input:payload:ficoScore::INTEGER as fico_score,
    DATA:data:input:payload:annualIncome::INTEGER as annual_income,
    
    -- GIACT Integration metadata
    giact_integration.value:name::VARCHAR as integration_name,
    giact_integration.value:cache_used::BOOLEAN as cache_used,
    
    -- GIACT Parameters (request data sent to GIACT)
    giact_integration.value:parameters:Check:AccountNumber::VARCHAR as giact_account_number,
    giact_integration.value:parameters:Check:RoutingNumber::VARCHAR as giact_routing_number,
    giact_integration.value:parameters:Customer:FirstName::VARCHAR as giact_customer_first_name,
    giact_integration.value:parameters:Customer:LastName::VARCHAR as giact_customer_last_name,
    giact_integration.value:parameters:Customer:TaxID::VARCHAR as giact_customer_tax_id,
    giact_integration.value:parameters:GAuthenticateEnabled::BOOLEAN as giact_authenticate_enabled,
    giact_integration.value:parameters:GVerifyEnabled::BOOLEAN as giact_verify_enabled,
    giact_integration.value:parameters:UniqueId::VARCHAR as giact_unique_id,
    
    -- GIACT Response Data (verification results from GIACT)
    giact_integration.value:response:AccountAdded::VARCHAR as account_added_description,
    giact_integration.value:response:AccountAddedDate::TIMESTAMP as account_added_date,
    giact_integration.value:response:AccountClosed::VARCHAR as account_closed_description,
    giact_integration.value:response:AccountClosedDate::TIMESTAMP as account_closed_date,
    giact_integration.value:response:AccountLastUpdated::VARCHAR as account_last_updated_description,
    giact_integration.value:response:AccountLastUpdatedDate::TIMESTAMP as account_last_updated_date,
    giact_integration.value:response:AccountResponseCode::INTEGER as account_response_code,
    giact_integration.value:response:BankAccountType::VARCHAR as bank_account_type,
    giact_integration.value:response:BankName::VARCHAR as bank_name,
    giact_integration.value:response:ConsumerAlertMessages::VARCHAR as consumer_alert_messages,
    giact_integration.value:response:CreatedDate::TIMESTAMP as giact_created_date,
    giact_integration.value:response:CustomerResponseCode::INTEGER as customer_response_code,
    giact_integration.value:response:ErrorMessage::VARCHAR as error_message,
    giact_integration.value:response:ItemReferenceId::BIGINT as item_reference_id,
    giact_integration.value:response:VerificationResponse::INTEGER as verification_response,
    giact_integration.value:response:FundsConfirmationResult::VARCHAR as funds_confirmation_result,
    giact_integration.value:response:OfacListPotentialMatches::VARCHAR as ofac_potential_matches

FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
LATERAL FLATTEN(input => DATA:data:integrations) giact_integration
WHERE 
    -- Filter for giact_5_8 integrations only
    giact_integration.value:name::VARCHAR = 'giact_5_8';

-- =====================================================================
-- SECTION 2: ENHANCED DATA WITH DERIVED FIELDS
-- =====================================================================

CREATE OR REPLACE TEMPORARY TABLE giact_enhanced AS
SELECT 
    *,
    
    -- Derived fraud investigation fields
    CASE 
        WHEN UPPER(bank_name) LIKE $bank_name_pattern THEN 'YES'
        ELSE 'NO'
    END as is_target_bank,
    
    CASE 
        WHEN giact_routing_number = $routing_number_filter THEN 'YES'
        ELSE 'NO'
    END as is_target_routing_number,
    
    CASE 
        WHEN account_added_date IS NOT NULL
        THEN DATEDIFF(DAY, account_added_date, CURRENT_DATE())
        ELSE NULL
    END as days_since_account_opened,
    
    CASE 
        WHEN account_added_date IS NOT NULL
             AND DATEDIFF(DAY, account_added_date, CURRENT_DATE()) <= $recent_account_threshold
        THEN 'YES'
        ELSE 'NO'
    END as opened_within_threshold,
    
    -- Comprehensive fraud risk scoring
    CASE 
        WHEN UPPER(bank_name) LIKE $bank_name_pattern
             AND giact_routing_number = $routing_number_filter
             AND account_added_date IS NOT NULL
             AND DATEDIFF(DAY, account_added_date, CURRENT_DATE()) <= $recent_account_threshold
        THEN 'HIGH RISK'
        WHEN UPPER(bank_name) LIKE $bank_name_pattern
             AND giact_routing_number = $routing_number_filter
        THEN 'MEDIUM RISK'
        WHEN giact_routing_number = $routing_number_filter
        THEN 'LOW-MEDIUM RISK'
        ELSE 'LOW RISK'
    END as fraud_risk_level,
    
    -- Account verification status interpretation
    CASE 
        WHEN verification_response = 1 THEN 'Account Verified'
        WHEN verification_response = 2 THEN 'Account Verified with Conditions'
        WHEN verification_response = 3 THEN 'Account Not Verified'
        WHEN verification_response = 4 THEN 'Account Closed'
        WHEN verification_response = 5 THEN 'Account Not Found'
        WHEN verification_response = 6 THEN 'Unable to Verify'
        ELSE 'Unknown (' || verification_response::VARCHAR || ')'
    END as verification_status_description,
    
    -- Customer response code interpretation
    CASE 
        WHEN customer_response_code = 1 THEN 'Customer Verified'
        WHEN customer_response_code = 2 THEN 'Customer Verified with Conditions'
        WHEN customer_response_code = 3 THEN 'Customer Not Verified'
        WHEN customer_response_code = 4 THEN 'Customer Deceased'
        WHEN customer_response_code = 18 THEN 'Insufficient Information'
        ELSE 'Other (' || customer_response_code::VARCHAR || ')'
    END as customer_status_description

FROM giact_extraction_base;

-- =====================================================================
-- SECTION 3: MAIN QUERY RESULTS
-- =====================================================================

-- Display comprehensive results with all GIACT data
SELECT 
    '=== GIACT 5.8 DATA EXTRACTION RESULTS ===' as section,
    '' as application_id,
    '' as customer_name,
    '' as fraud_risk_level,
    '' as bank_details,
    '' as account_status
    
UNION ALL

-- Header row
SELECT 
    'DATA',
    'APP_ID',
    'CUSTOMER',
    'RISK_LEVEL',
    'BANK_DETAILS',
    'ACCOUNT_STATUS'

UNION ALL

-- Data rows
SELECT 
    'DATA' as section,
    application_id,
    payload_first_name || ' ' || payload_last_name as customer_name,
    fraud_risk_level,
    bank_name || ' (' || giact_routing_number || ')' as bank_details,
    verification_status_description as account_status
FROM giact_enhanced
WHERE fraud_risk_level IN ('HIGH RISK', 'MEDIUM RISK', 'LOW-MEDIUM RISK')
ORDER BY 
    CASE 
        WHEN fraud_risk_level = 'HIGH RISK' THEN 1
        WHEN fraud_risk_level = 'MEDIUM RISK' THEN 2
        WHEN fraud_risk_level = 'LOW-MEDIUM RISK' THEN 3
        ELSE 4
    END,
    account_added_date DESC;

-- =====================================================================
-- SECTION 4: FRAUD INVESTIGATION SUMMARY
-- =====================================================================

SELECT 
    '=== FRAUD INVESTIGATION SUMMARY ===' as metric,
    '' as value,
    '' as description
    
UNION ALL

SELECT 
    'Total GIACT Records:',
    COUNT(*)::VARCHAR,
    'Total applications with GIACT 5.8 data'
FROM giact_enhanced

UNION ALL

SELECT 
    'Target Routing Number (' || $routing_number_filter || '):',
    COUNT(CASE WHEN is_target_routing_number = 'YES' THEN 1 END)::VARCHAR,
    'Applications using target routing number'
FROM giact_enhanced

UNION ALL

SELECT 
    'Target Bank (' || REPLACE($bank_name_pattern, '%', '') || '):',
    COUNT(CASE WHEN is_target_bank = 'YES' THEN 1 END)::VARCHAR,
    'Applications at target bank'
FROM giact_enhanced

UNION ALL

SELECT 
    'HIGH RISK:',
    COUNT(CASE WHEN fraud_risk_level = 'HIGH RISK' THEN 1 END)::VARCHAR,
    'Target bank + routing + recent account'
FROM giact_enhanced

UNION ALL

SELECT 
    'MEDIUM RISK:',
    COUNT(CASE WHEN fraud_risk_level = 'MEDIUM RISK' THEN 1 END)::VARCHAR,
    'Target bank + routing + older account'
FROM giact_enhanced

UNION ALL

SELECT 
    'Recent Accounts (' || $recent_account_threshold || ' days):',
    COUNT(CASE WHEN opened_within_threshold = 'YES' THEN 1 END)::VARCHAR,
    'Accounts opened within threshold'
FROM giact_enhanced
WHERE account_added_date IS NOT NULL

UNION ALL

SELECT 
    'Date Range:',
    COALESCE(MIN(account_added_date)::VARCHAR, 'N/A') || ' to ' || COALESCE(MAX(account_added_date)::VARCHAR, 'N/A'),
    'Account opening date range'
FROM giact_enhanced
WHERE account_added_date IS NOT NULL;

-- =====================================================================
-- SECTION 5: DETAILED HIGH/MEDIUM RISK ACCOUNTS
-- =====================================================================

SELECT 
    '=== HIGH & MEDIUM RISK ACCOUNT DETAILS ===' as detail_type,
    '' as application_id,
    '' as customer_info,
    '' as account_info,
    '' as risk_factors,
    '' as verification_status
    
UNION ALL

-- Header
SELECT 
    'DETAILS',
    'APP_ID',
    'CUSTOMER_INFO',
    'ACCOUNT_INFO', 
    'RISK_FACTORS',
    'VERIFICATION_STATUS'

UNION ALL

-- High and Medium risk details
SELECT 
    'DETAILS',
    application_id,
    payload_first_name || ' ' || payload_last_name || ' (' || payload_ssn || ')' as customer_info,
    giact_account_number || ' @ ' || bank_name as account_info,
    fraud_risk_level || ' - ' || days_since_account_opened::VARCHAR || ' days old' as risk_factors,
    verification_status_description as verification_status
FROM giact_enhanced
WHERE fraud_risk_level IN ('HIGH RISK', 'MEDIUM RISK')
ORDER BY 
    CASE 
        WHEN fraud_risk_level = 'HIGH RISK' THEN 1
        ELSE 2
    END,
    account_added_date DESC;

-- =====================================================================
-- SECTION 6: EXPORT COMPLETE DATASET
-- =====================================================================

-- Complete dataset for export (uncomment the line below to save to file)
-- This would be run separately: snow sql -q "SELECT * FROM giact_enhanced ORDER BY fraud_risk_level, account_added_date DESC" --format csv > giact_complete_data.csv

SELECT 
    '=== COMPLETE DATASET AVAILABLE ===' as note,
    'Run: SELECT * FROM giact_enhanced ORDER BY fraud_risk_level, account_added_date DESC' as query_to_export,
    'Contains all ' || COUNT(*)::VARCHAR || ' GIACT records with enhanced fraud analysis' as description
FROM giact_enhanced;

-- =====================================================================
-- SCRIPT COMPLETE
-- =====================================================================