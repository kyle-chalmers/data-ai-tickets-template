/*
DI-1179: Quality Control Queries for Fraud-Only Analytics View
Validates completeness, accuracy, and performance of the new fraud view
FRAUD DETECTION ONLY (no deceased/SCRA validation)
Run these queries after deployment to ensure proper functionality
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- =========================================================================
-- QC 1: Basic Row Count and Coverage Validation
-- =========================================================================
SELECT 
    'Fraud Analytics View - Basic Stats' as validation_check,
    COUNT(*) as total_fraud_records,
    COUNT(DISTINCT LEAD_GUID) as unique_lead_guids,
    COUNT(DISTINCT LOAN_ID) as unique_loan_ids,
    COUNT(CASE WHEN IS_FRAUD_ANY THEN 1 END) as fraud_any_count
FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS;

-- =========================================================================
-- QC 2: Data Source Breakdown - Validate all fraud sources are represented
-- =========================================================================
SELECT 
    'Fraud Data Source Validation' as validation_check,
    COUNT(CASE WHEN IS_FRAUD_PORTFOLIO THEN 1 END) as fraud_portfolio_count,
    COUNT(CASE WHEN IS_FRAUD_INVESTIGATION_LMS THEN 1 END) as fraud_lms_investigation_count,
    COUNT(CASE WHEN IS_FRAUD_INVESTIGATION_LOS THEN 1 END) as fraud_los_investigation_count,
    COUNT(CASE WHEN IS_FRAUD_APPLICATION_TAG THEN 1 END) as fraud_application_tag_count,
    COUNT(CASE WHEN IS_FRAUD_STATUS_TEXT THEN 1 END) as fraud_status_text_count
FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS;

-- =========================================================================
-- QC 3: Compare against DI-1141 fraud portfolio logic (FRAUD ONLY)
-- =========================================================================
WITH legacy_fraud_detection AS (
    -- Replicate DI-1141 fraud portfolio detection logic for comparison
    SELECT DISTINCT 
        LOWER(vl.lead_guid) as lead_guid,
        MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN TRUE ELSE FALSE END) as legacy_fraud_portfolio
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
        ON vl.loan_id = lpsp.loan_id
        AND lpsp.PORTFOLIO_CATEGORY = 'Fraud'
    GROUP BY LOWER(vl.lead_guid)
),
new_fraud_detection AS (
    SELECT 
        LOWER(LEAD_GUID) as lead_guid,
        IS_FRAUD_PORTFOLIO as new_fraud_portfolio
    FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS
)
SELECT 
    'Fraud Portfolio Logic Comparison' as validation_check,
    COUNT(*) as total_comparisons,
    COUNT(CASE WHEN lfd.legacy_fraud_portfolio = nfd.new_fraud_portfolio THEN 1 END) as fraud_portfolio_matches,
    COUNT(CASE WHEN lfd.legacy_fraud_portfolio != nfd.new_fraud_portfolio THEN 1 END) as fraud_portfolio_mismatches
FROM legacy_fraud_detection lfd
FULL OUTER JOIN new_fraud_detection nfd ON lfd.lead_guid = nfd.lead_guid;

-- =========================================================================
-- QC 4: Performance Test - Query Response Time
-- =========================================================================
SELECT 
    'Performance Test' as validation_check,
    CURRENT_TIMESTAMP() as query_start_time;

-- Simple fraud lookup (should be sub-second)
SELECT COUNT(*) as simple_fraud_count
FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE IS_FRAUD_ANY = TRUE;

SELECT 
    'Performance Test Complete' as validation_check,
    CURRENT_TIMESTAMP() as query_end_time;

-- =========================================================================
-- QC 5: Data Quality Checks
-- =========================================================================
SELECT 
    'Fraud Data Quality Issues' as validation_check,
    COUNT(CASE WHEN LEAD_GUID IS NULL THEN 1 END) as null_lead_guid_count,
    COUNT(CASE WHEN LOAN_ID IS NULL THEN 1 END) as null_loan_id_count,
    COUNT(CASE WHEN IS_FRAUD_ANY = FALSE THEN 1 END) as records_with_no_fraud_indicators,
    COUNT(CASE WHEN FRAUD_DETECTION_METHODS_COUNT > 5 THEN 1 END) as excessive_method_counts,
    COUNT(CASE WHEN FRAUD_FIRST_DETECTED_DATE > CURRENT_DATE() THEN 1 END) as future_dates
FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS;

-- =========================================================================
-- QC 6: Sample Records Review
-- =========================================================================
SELECT 
    'Sample Records - Multi-Source Fraud Detection' as validation_check,
    LOAN_ID,
    LEGACY_LOAN_ID,
    IS_FRAUD_ANY,
    FRAUD_DETECTION_METHODS_COUNT,
    FRAUD_SOURCES_LIST,
    FRAUD_PORTFOLIO_NAMES
FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE FRAUD_DETECTION_METHODS_COUNT >= 2
ORDER BY FRAUD_DETECTION_METHODS_COUNT DESC
LIMIT 10;

-- =========================================================================
-- QC 7: Cross-Layer Validation (FRESHSNOW → BRIDGE → ANALYTICS)
-- =========================================================================
WITH layer_counts AS (
    SELECT 'FRESHSNOW' as layer, COUNT(*) as record_count
    FROM DEVELOPMENT.FRESHSNOW.VW_FRAUD_COMPREHENSIVE_ANALYTICS
    
    UNION ALL
    
    SELECT 'BRIDGE' as layer, COUNT(*) as record_count  
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_FRAUD_COMPREHENSIVE_ANALYTICS
    
    UNION ALL
    
    SELECT 'ANALYTICS' as layer, COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS
)
SELECT 
    'Cross-Layer Record Count Validation' as validation_check,
    layer,
    record_count,
    LAG(record_count) OVER (ORDER BY layer) as previous_layer_count,
    CASE WHEN record_count = LAG(record_count) OVER (ORDER BY layer) 
         THEN 'PASS' ELSE 'FAIL' END as validation_status
FROM layer_counts
ORDER BY layer;