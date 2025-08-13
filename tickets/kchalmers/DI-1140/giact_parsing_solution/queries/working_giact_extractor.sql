-- =====================================================================
-- Working GIACT 5.8 Data Extractor - Ready to Use
-- =====================================================================
-- Purpose: Extract GIACT data with fraud analysis
-- Usage: Modify parameters below, then run script
-- =====================================================================

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- =====================================================================
-- CONFIGURATION SECTION - MODIFY THESE VALUES AS NEEDED
-- =====================================================================

SELECT 
    -- Basic identifiers
    DATA:data:input:payload:applicationId::VARCHAR as application_id,
    DATA:data:input:payload:borrowerId::VARCHAR as borrower_id,
    DATA:data:input:oscilar:timestamp::TIMESTAMP as oscilar_timestamp,
    
    -- Customer information
    DATA:data:input:payload:firstName::VARCHAR as first_name,
    DATA:data:input:payload:lastName::VARCHAR as last_name,
    DATA:data:input:payload:ssn::VARCHAR as ssn,
    DATA:data:input:payload:city::VARCHAR as city,
    DATA:data:input:payload:state::VARCHAR as state,
    DATA:data:input:payload:postalCode::VARCHAR as postal_code,
    DATA:data:input:payload:street::VARCHAR as street,
    
    -- GIACT request parameters
    giact_integration.value:parameters:Check:AccountNumber::VARCHAR as account_number,
    giact_integration.value:parameters:Check:RoutingNumber::VARCHAR as routing_number,
    giact_integration.value:parameters:Customer:FirstName::VARCHAR as giact_first_name,
    giact_integration.value:parameters:Customer:LastName::VARCHAR as giact_last_name,
    giact_integration.value:parameters:Customer:TaxID::VARCHAR as giact_tax_id,
    giact_integration.value:parameters:GAuthenticateEnabled::BOOLEAN as auth_enabled,
    giact_integration.value:parameters:GVerifyEnabled::BOOLEAN as verify_enabled,
    
    -- GIACT response results
    giact_integration.value:response:BankName::VARCHAR as bank_name,
    giact_integration.value:response:BankAccountType::VARCHAR as account_type,
    giact_integration.value:response:AccountAdded::VARCHAR as account_age_description,
    giact_integration.value:response:AccountAddedDate::TIMESTAMP as account_opened_date,
    giact_integration.value:response:VerificationResponse::INTEGER as verification_code,
    giact_integration.value:response:CustomerResponseCode::INTEGER as customer_code,
    giact_integration.value:response:AccountResponseCode::INTEGER as account_response_code,
    giact_integration.value:response:ErrorMessage::VARCHAR as error_message,
    giact_integration.value:response:CreatedDate::TIMESTAMP as giact_created_date,
    giact_integration.value:response:ItemReferenceId::BIGINT as item_reference_id,
    
    -- Derived analysis fields
    CASE 
        WHEN giact_integration.value:response:AccountAddedDate::TIMESTAMP IS NOT NULL
        THEN DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE())
        ELSE NULL
    END as days_since_account_opened,
    
    -- Risk assessment based on investigation criteria
    CASE 
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE '%BMO%'
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
             AND DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE()) <= 30
        THEN 'HIGH RISK'
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE '%BMO%'
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'  
        THEN 'MEDIUM RISK'
        WHEN giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
        THEN 'LOW-MEDIUM RISK'
        ELSE 'LOW RISK'
    END as risk_assessment,
    
    -- Verification status interpretation
    CASE 
        WHEN giact_integration.value:response:VerificationResponse::INTEGER = 1 THEN 'Account Verified'
        WHEN giact_integration.value:response:VerificationResponse::INTEGER = 2 THEN 'Account Verified with Conditions'
        WHEN giact_integration.value:response:VerificationResponse::INTEGER = 3 THEN 'Account Not Verified'
        WHEN giact_integration.value:response:VerificationResponse::INTEGER = 4 THEN 'Account Closed'
        WHEN giact_integration.value:response:VerificationResponse::INTEGER = 5 THEN 'Account Not Found'
        WHEN giact_integration.value:response:VerificationResponse::INTEGER = 6 THEN 'Unable to Verify'
        ELSE 'Unknown (' || giact_integration.value:response:VerificationResponse::INTEGER::VARCHAR || ')'
    END as verification_status,
    
    -- Customer verification interpretation
    CASE 
        WHEN giact_integration.value:response:CustomerResponseCode::INTEGER = 1 THEN 'Customer Verified'
        WHEN giact_integration.value:response:CustomerResponseCode::INTEGER = 2 THEN 'Customer Verified with Conditions'
        WHEN giact_integration.value:response:CustomerResponseCode::INTEGER = 3 THEN 'Customer Not Verified'
        WHEN giact_integration.value:response:CustomerResponseCode::INTEGER = 4 THEN 'Customer Deceased'
        WHEN giact_integration.value:response:CustomerResponseCode::INTEGER = 18 THEN 'Insufficient Information'
        ELSE 'Other (' || giact_integration.value:response:CustomerResponseCode::INTEGER::VARCHAR || ')'
    END as customer_status

FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
LATERAL FLATTEN(input => DATA:data:integrations) giact_integration
WHERE 
    -- Filter for GIACT 5.8 integrations only
    giact_integration.value:name::VARCHAR = 'giact_5_8'
    
    -- ===================================================================
    -- MODIFY THESE FILTERS FOR YOUR INVESTIGATION:
    -- ===================================================================
    
    -- Filter for specific routing number (comment out line below for all routing numbers)
    AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
    
    -- Filter for specific bank (comment out line below for all banks)
    AND UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE '%BMO%'
    
    -- Filter for recent accounts only (comment out line below for all dates)
    -- AND DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE()) <= 45
    
    -- Filter for specific applications (uncomment and modify line below for specific apps)
    -- AND DATA:data:input:payload:applicationId::VARCHAR IN ('2901849', '2847525', '2831679')
    
    -- Filter by date range (uncomment and modify lines below for date filtering)
    -- AND giact_integration.value:response:AccountAddedDate::TIMESTAMP >= '2024-01-01'
    -- AND giact_integration.value:response:AccountAddedDate::TIMESTAMP <= CURRENT_DATE()

ORDER BY 
    -- Order by risk level (highest risk first), then by account opening date
    CASE 
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE '%BMO%'
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
             AND DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE()) <= 30
        THEN 1  -- HIGH RISK first
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE '%BMO%'
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
        THEN 2  -- MEDIUM RISK second  
        WHEN giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
        THEN 3  -- LOW-MEDIUM RISK third
        ELSE 4  -- LOW RISK last
    END,
    giact_integration.value:response:AccountAddedDate DESC NULLS LAST;

-- =====================================================================
-- CUSTOMIZATION INSTRUCTIONS:
-- =====================================================================
-- 1. To change routing number: modify '071025661' in the filter
-- 2. To change bank: modify '%BMO%' in the filter  
-- 3. To change recent days threshold: modify the number 30 in risk_assessment
-- 4. To focus on specific applications: uncomment and modify the application filter
-- 5. To add date range: uncomment and modify the date filters
-- 6. To include all records: comment out filters using -- at start of line
-- =====================================================================