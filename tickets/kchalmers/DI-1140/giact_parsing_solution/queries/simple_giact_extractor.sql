-- =====================================================================
-- Simple GIACT 5.8 Data Extractor
-- =====================================================================
-- Purpose: Quick and easy GIACT data extraction with customizable filters
-- Usage: Modify the parameters below, then run the script
-- =====================================================================

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- =====================================================================
-- CONFIGURATION PARAMETERS - MODIFY THESE AS NEEDED
-- =====================================================================
-- Change these values based on your investigation needs:

-- Routing number to investigate (set to NULL to include all)
DECLARE routing_number_filter VARCHAR DEFAULT '071025661';

-- Bank name pattern to search for (use % for wildcards, NULL for all banks)  
DECLARE bank_name_pattern VARCHAR DEFAULT '%BMO%';

-- How many days back to consider "recent" account opening
DECLARE recent_days_threshold INTEGER DEFAULT 30;

-- Date range for investigation (set to NULL to include all dates)
DECLARE start_date DATE DEFAULT '2024-01-01';
DECLARE end_date DATE DEFAULT CURRENT_DATE();

-- Application IDs to focus on (leave as empty string to include all)
-- Format: 'app1', 'app2', 'app3' or leave as '' for all
DECLARE specific_applications VARCHAR DEFAULT '';

BEGIN

-- =====================================================================
-- MAIN GIACT DATA EXTRACTION
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
    
    -- GIACT request parameters
    giact_integration.value:parameters:Check:AccountNumber::VARCHAR as account_number,
    giact_integration.value:parameters:Check:RoutingNumber::VARCHAR as routing_number,
    giact_integration.value:parameters:Customer:FirstName::VARCHAR as giact_first_name,
    giact_integration.value:parameters:Customer:LastName::VARCHAR as giact_last_name,
    giact_integration.value:parameters:Customer:TaxID::VARCHAR as giact_tax_id,
    
    -- GIACT response results
    giact_integration.value:response:BankName::VARCHAR as bank_name,
    giact_integration.value:response:BankAccountType::VARCHAR as account_type,
    giact_integration.value:response:AccountAdded::VARCHAR as account_age_description,
    giact_integration.value:response:AccountAddedDate::TIMESTAMP as account_opened_date,
    giact_integration.value:response:VerificationResponse::INTEGER as verification_code,
    giact_integration.value:response:CustomerResponseCode::INTEGER as customer_code,
    giact_integration.value:response:ErrorMessage::VARCHAR as error_message,
    
    -- Derived analysis fields
    CASE 
        WHEN giact_integration.value:response:AccountAddedDate::TIMESTAMP IS NOT NULL
        THEN DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE())
        ELSE NULL
    END as days_since_account_opened,
    
    CASE 
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE NVL(routing_number_filter, '%')
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = NVL(routing_number_filter, giact_integration.value:parameters:Check:RoutingNumber::VARCHAR)
             AND DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE()) <= recent_days_threshold
        THEN 'HIGH RISK'
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE NVL(bank_name_pattern, '%')
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = NVL(routing_number_filter, giact_integration.value:parameters:Check:RoutingNumber::VARCHAR)  
        THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END as risk_assessment

FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
LATERAL FLATTEN(input => DATA:data:integrations) giact_integration
WHERE 
    -- Filter for GIACT 5.8 integrations
    giact_integration.value:name::VARCHAR = 'giact_5_8'
    
    -- Apply routing number filter if specified
    AND (routing_number_filter IS NULL OR giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = routing_number_filter)
    
    -- Apply bank name filter if specified  
    AND (bank_name_pattern IS NULL OR UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE UPPER(bank_name_pattern))
    
    -- Apply date range filter if specified
    AND (start_date IS NULL OR giact_integration.value:response:AccountAddedDate::TIMESTAMP >= start_date)
    AND (end_date IS NULL OR giact_integration.value:response:AccountAddedDate::TIMESTAMP <= end_date)
    
    -- Apply specific application filter if specified
    AND (specific_applications = '' OR DATA:data:input:payload:applicationId::VARCHAR IN (SELECT TRIM(VALUE) FROM TABLE(SPLIT_TO_TABLE(specific_applications, ','))))

ORDER BY 
    CASE 
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE NVL(bank_name_pattern, '%')
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = NVL(routing_number_filter, giact_integration.value:parameters:Check:RoutingNumber::VARCHAR)
             AND DATEDIFF(DAY, giact_integration.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE()) <= recent_days_threshold
        THEN 1  -- HIGH RISK first
        WHEN UPPER(giact_integration.value:response:BankName::VARCHAR) LIKE NVL(bank_name_pattern, '%')
             AND giact_integration.value:parameters:Check:RoutingNumber::VARCHAR = NVL(routing_number_filter, giact_integration.value:parameters:Check:RoutingNumber::VARCHAR)
        THEN 2  -- MEDIUM RISK second  
        ELSE 3  -- LOW RISK last
    END,
    giact_integration.value:response:AccountAddedDate DESC NULLS LAST;

END;