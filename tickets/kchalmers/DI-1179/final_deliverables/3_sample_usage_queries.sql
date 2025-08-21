/*
DI-1179: Sample Usage Queries for Fraud-Only Analytics View
Demonstrates common fraud analysis patterns using the new centralized view
FRAUD DETECTION ONLY (no deceased/SCRA data)
Replaces complex multi-table joins with simple single-table lookups
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- =========================================================================
-- EXAMPLE 1: Debt Sale Fraud Exclusions (replaces DI-1141 pattern)
-- =========================================================================
-- Old way: Complex CTEs across multiple tables
-- New way: Simple lookup with fraud indicators only

SELECT 
    'Debt Sale Fraud Exclusions Example' as use_case,
    vl.loan_id,
    vl.legacy_loan_id,
    vl.lead_guid,
    
    -- Simple fraud exclusion logic
    CASE WHEN fca.IS_FRAUD_ANY THEN 'EXCLUDE - Fraud Detected'
         ELSE 'INCLUDE'
    END as debt_sale_status,
    
    -- Detailed exclusion reasons
    fca.FRAUD_SOURCES_LIST,
    fca.FRAUD_FIRST_DETECTED_DATE,
    fca.FRAUD_PORTFOLIO_NAMES
    
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY ltm
    ON LOWER(vl.lead_guid) = LOWER(ltm.PAYOFFUID)
    AND ltm.STATUS = 'Charge off'
    AND ltm.CHARGEOFFDATE >= '2025-04-01'  -- Q2 2025 charge-offs
    AND ltm.CHARGEOFFDATE <= '2025-06-30'
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS fca
    ON LOWER(vl.lead_guid) = LOWER(fca.LEAD_GUID)
    
WHERE fca.IS_FRAUD_ANY IS NULL OR fca.IS_FRAUD_ANY = FALSE  -- Only clean loans
ORDER BY vl.loan_id
LIMIT 100;

-- =========================================================================
-- EXAMPLE 2: Fraud Portfolio Analysis (replaces DI-934 pattern)
-- =========================================================================
-- Comprehensive fraud breakdown across all detection methods

SELECT 
    'Comprehensive Fraud Analysis' as use_case,
    
    -- Summary counts by detection method
    COUNT(*) as total_fraud_loans,
    COUNT(CASE WHEN IS_FRAUD_PORTFOLIO THEN 1 END) as portfolio_fraud_count,
    COUNT(CASE WHEN IS_FRAUD_INVESTIGATION_LMS THEN 1 END) as lms_investigation_count,
    COUNT(CASE WHEN IS_FRAUD_INVESTIGATION_LOS THEN 1 END) as los_investigation_count,
    COUNT(CASE WHEN IS_FRAUD_APPLICATION_TAG THEN 1 END) as application_tag_count,
    COUNT(CASE WHEN IS_FRAUD_STATUS_TEXT THEN 1 END) as status_text_count,
    
    -- Average detection methods per loan
    AVG(FRAUD_DETECTION_METHODS_COUNT) as avg_detection_methods,
    
    -- Most common fraud portfolio names
    LISTAGG(DISTINCT FRAUD_PORTFOLIO_NAMES, '; ') 
        WITHIN GROUP (ORDER BY FRAUD_PORTFOLIO_NAMES) as all_fraud_portfolios

FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE IS_FRAUD_ANY = TRUE;

-- =========================================================================
-- EXAMPLE 3: Fraud Investigation Analysis
-- =========================================================================
-- Compare fraud detection between LMS and LOS investigation systems

SELECT 
    'Fraud Investigation Analysis' as use_case,
    LOAN_ID,
    LEGACY_LOAN_ID,
    
    -- Investigation breakdown
    IS_FRAUD_INVESTIGATION_LMS,
    IS_FRAUD_INVESTIGATION_LOS,
    FRAUD_STATUS_LMS,
    FRAUD_STATUS_LOS,
    FRAUD_REASON_LMS,
    FRAUD_REASON_LOS,
    
    -- Combined investigation status
    CASE WHEN IS_FRAUD_INVESTIGATION_LMS AND IS_FRAUD_INVESTIGATION_LOS 
         THEN 'Confirmed in Both Systems'
         WHEN IS_FRAUD_INVESTIGATION_LMS 
         THEN 'LMS Investigation Only'
         WHEN IS_FRAUD_INVESTIGATION_LOS 
         THEN 'LOS Investigation Only'
    END as investigation_coverage

FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE IS_FRAUD_INVESTIGATION_LMS = TRUE OR IS_FRAUD_INVESTIGATION_LOS = TRUE
ORDER BY 
    CASE WHEN IS_FRAUD_INVESTIGATION_LMS AND IS_FRAUD_INVESTIGATION_LOS THEN 1
         WHEN IS_FRAUD_INVESTIGATION_LMS THEN 2
         WHEN IS_FRAUD_INVESTIGATION_LOS THEN 3
    END,
    LOAN_ID
LIMIT 50;

-- =========================================================================
-- EXAMPLE 4: High-Risk Fraud Loans (Multiple Detection Methods)
-- =========================================================================
-- Loans with fraud detected by multiple independent sources

SELECT 
    'High-Risk Multi-Source Fraud' as use_case,
    LOAN_ID,
    LEGACY_LOAN_ID,
    FRAUD_DETECTION_METHODS_COUNT,
    FRAUD_SOURCES_LIST,
    FRAUD_FIRST_DETECTED_DATE,
    
    -- Detailed breakdown
    IS_FRAUD_PORTFOLIO,
    IS_FRAUD_INVESTIGATION_LMS,
    IS_FRAUD_INVESTIGATION_LOS,
    IS_FRAUD_APPLICATION_TAG,
    IS_FRAUD_STATUS_TEXT,
    
    -- Portfolio and investigation details
    FRAUD_PORTFOLIO_NAMES,
    FRAUD_STATUS_LMS,
    FRAUD_REASON_LMS,
    FRAUD_STATUS_LOS,
    FRAUD_REASON_LOS

FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE FRAUD_DETECTION_METHODS_COUNT >= 2  -- Multiple detection methods
ORDER BY FRAUD_DETECTION_METHODS_COUNT DESC, FRAUD_FIRST_DETECTED_DATE ASC
LIMIT 25;

-- =========================================================================
-- EXAMPLE 5: Performance Comparison - Old vs New Approach
-- =========================================================================
-- Demonstrate performance improvement over ad-hoc queries

-- OLD APPROACH (commented out - would be slow)
/*
WITH complex_fraud_cte AS (
    SELECT vl.loan_id,
           -- Multiple complex joins and subqueries...
    FROM multiple_tables...
)
SELECT ... FROM complex_fraud_cte ...
*/

-- NEW APPROACH (simple and fast)
SELECT 
    'Performance Demo - Simple Fraud Lookup' as use_case,
    COUNT(*) as fraud_loan_count,
    COUNT(CASE WHEN FRAUD_DETECTION_METHODS_COUNT >= 2 THEN 1 END) as multi_source_fraud,
    COUNT(DISTINCT FRAUD_SOURCES_LIST) as unique_detection_patterns,
    MIN(FRAUD_FIRST_DETECTED_DATE) as earliest_fraud_detection,
    MAX(FRAUD_FIRST_DETECTED_DATE) as latest_fraud_detection
    
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE IS_FRAUD_ANY = TRUE;

-- =========================================================================
-- EXAMPLE 6: Current Loan Status with Fraud Overlay
-- =========================================================================
-- Join fraud view with current loan status for comprehensive analysis

SELECT 
    'Loan Status with Fraud Overlay' as use_case,
    vl.loan_id,
    vl.legacy_loan_id,
    vl.loan_status,
    vl.loan_sub_status_text,
    
    -- Fraud indicators
    fca.IS_FRAUD_ANY,
    fca.FRAUD_SOURCES_LIST,
    
    -- Risk categorization
    CASE WHEN fca.IS_FRAUD_ANY THEN 'High Risk - Fraud'
         ELSE 'Standard Risk'
    END as risk_category

FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS fca
    ON LOWER(vl.lead_guid) = LOWER(fca.LEAD_GUID)
WHERE vl.loan_status IN ('Active - Good Standing', 'Active - Bad Standing', 'Charge off')
ORDER BY 
    CASE WHEN fca.IS_FRAUD_ANY THEN 1
         ELSE 2 END,
    vl.loan_id
LIMIT 100;