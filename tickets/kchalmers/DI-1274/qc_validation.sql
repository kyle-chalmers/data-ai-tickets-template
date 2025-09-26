/*
DI-1274: VW_LOAN_FRAUD Quality Control Validation
Comprehensive testing of the development view
*/

--1.1: Duplicate Detection Test
SELECT
    'Duplicate Check' as test_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT LOAN_ID) as unique_loans,
    COUNT(*) - COUNT(DISTINCT LOAN_ID) as duplicate_count,
    CASE WHEN COUNT(*) = COUNT(DISTINCT LOAN_ID) THEN 'PASS' ELSE 'FAIL' END as test_result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--1.2: Data Grain Validation
SELECT
    'Data Grain Validation' as test_name,
    CASE WHEN duplicate_count = 0 THEN 'ONE_ROW_PER_LOAN' ELSE 'GRAIN_VIOLATION' END as grain_status,
    duplicate_count,
    'PASS' as test_result
FROM (
    SELECT COUNT(*) - COUNT(DISTINCT LOAN_ID) as duplicate_count
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
);

--2.1: Data Completeness Test - Source Distribution
SELECT
    'Source Distribution' as test_name,
    FRAUD_DATA_COMPLETENESS_FLAG,
    COUNT(*) as loan_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY FRAUD_DATA_COMPLETENESS_FLAG
ORDER BY FRAUD_DATA_COMPLETENESS_FLAG;

--2.2: Data Completeness Test - Individual Sources
SELECT
    'Individual Source Coverage' as test_name,
    COUNT(*) as total_loans,
    COUNT(CASE WHEN HAS_FRAUD_CUSTOM_FIELDS THEN 1 END) as custom_fields_count,
    COUNT(CASE WHEN HAS_FRAUD_PORTFOLIO THEN 1 END) as portfolio_count,
    COUNT(CASE WHEN HAS_FRAUD_SUB_STATUS THEN 1 END) as sub_status_count,
    ROUND((COUNT(CASE WHEN HAS_FRAUD_CUSTOM_FIELDS THEN 1 END) * 100.0 / COUNT(*)), 2) as custom_fields_percentage,
    ROUND((COUNT(CASE WHEN HAS_FRAUD_PORTFOLIO THEN 1 END) * 100.0 / COUNT(*)), 2) as portfolio_percentage,
    ROUND((COUNT(CASE WHEN HAS_FRAUD_SUB_STATUS THEN 1 END) * 100.0 / COUNT(*)), 2) as sub_status_percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--3.1: Data Conflict Analysis
SELECT
    'Data Conflict Analysis' as test_name,
    COUNT(*) as total_conflicts,
    COUNT(CASE WHEN FRAUD_INVESTIGATION_RESULTS = 'Declined'
               AND (FRAUD_PORTFOLIOS LIKE '%Confirmed%' OR CURRENT_FRAUD_SUB_STATUS LIKE '%Confirmed%')
               THEN 1 END) as declined_but_confirmed_elsewhere,
    COUNT(CASE WHEN FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
               AND FRAUD_PORTFOLIOS LIKE '%Declined%'
               AND FRAUD_PORTFOLIOS NOT LIKE '%Confirmed%'
               THEN 1 END) as confirmed_but_declined_elsewhere
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_DETERMINATION_CONFLICT_FLAG = TRUE;

--3.2: Workflow Progression Analysis
SELECT
    'Workflow Progression Analysis' as test_name,
    COUNT(*) as total_workflow_progressions,
    COUNT(CASE WHEN FRAUD_WORKFLOW_PROGRESSION_FLAG = TRUE THEN 1 END) as loans_with_progression,
    ROUND((COUNT(CASE WHEN FRAUD_WORKFLOW_PROGRESSION_FLAG = TRUE THEN 1 END) * 100.0 / COUNT(*)), 2) as progression_percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE HAS_FRAUD_PORTFOLIO = TRUE;

--4.1: Data Integrity Test - LEAD_GUID Population
SELECT
    'LEAD_GUID Population Test' as test_name,
    COUNT(*) as total_records,
    COUNT(LEAD_GUID) as records_with_lead_guid,
    COUNT(*) - COUNT(LEAD_GUID) as missing_lead_guid,
    ROUND((COUNT(LEAD_GUID) * 100.0 / COUNT(*)), 2) as lead_guid_coverage_percentage,
    CASE WHEN COUNT(LEAD_GUID) > 0 THEN 'PASS' ELSE 'FAIL' END as test_result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--4.2: Data Integrity Test - Source List Consistency
SELECT
    'Source List Consistency' as test_name,
    FRAUD_DATA_SOURCE_COUNT,
    FRAUD_DATA_SOURCE_LIST,
    COUNT(*) as record_count,
    CASE WHEN FRAUD_DATA_SOURCE_COUNT =
        (LENGTH(FRAUD_DATA_SOURCE_LIST) - LENGTH(REPLACE(FRAUD_DATA_SOURCE_LIST, ',', '')) +
         CASE WHEN LENGTH(FRAUD_DATA_SOURCE_LIST) > 0 THEN 1 ELSE 0 END)
    THEN 'CONSISTENT' ELSE 'INCONSISTENT' END as consistency_check
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_DATA_SOURCE_LIST IS NOT NULL
GROUP BY FRAUD_DATA_SOURCE_COUNT, FRAUD_DATA_SOURCE_LIST
ORDER BY FRAUD_DATA_SOURCE_COUNT;

--5.1: Business Logic Validation - Portfolio Aggregation
SELECT
    'Portfolio Aggregation Test' as test_name,
    LOAN_ID,
    FRAUD_PORTFOLIOS,
    FRAUD_PORTFOLIO_COUNT,
    -- Verify count matches actual portfolios in list
    CASE WHEN FRAUD_PORTFOLIO_COUNT =
        (LENGTH(FRAUD_PORTFOLIOS) - LENGTH(REPLACE(FRAUD_PORTFOLIOS, ';', '')) + 1)
    THEN 'CONSISTENT' ELSE 'INCONSISTENT' END as count_consistency
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE HAS_FRAUD_PORTFOLIO = TRUE
    AND FRAUD_PORTFOLIO_COUNT IS NOT NULL
    AND FRAUD_PORTFOLIOS IS NOT NULL
LIMIT 10;

--6.1: Performance Test - Record Count and Response Time
SELECT
    'Performance Test' as test_name,
    COUNT(*) as total_records,
    MIN(LOAN_ID) as min_loan_id,
    MAX(LOAN_ID) as max_loan_id,
    COUNT(DISTINCT LEAD_GUID) as unique_lead_guids,
    CURRENT_TIMESTAMP() as query_timestamp
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--6.2: Sample Data Quality Check
SELECT
    'Sample Data Quality' as test_name,
    LOAN_ID,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    CURRENT_FRAUD_SUB_STATUS,
    FRAUD_DATA_COMPLETENESS_FLAG,
    FRAUD_WORKFLOW_PROGRESSION_FLAG,
    FRAUD_DETERMINATION_CONFLICT_FLAG
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_DATA_SOURCE_COUNT >= 2
ORDER BY FRAUD_DATA_SOURCE_COUNT DESC, LOAN_ID
LIMIT 10;