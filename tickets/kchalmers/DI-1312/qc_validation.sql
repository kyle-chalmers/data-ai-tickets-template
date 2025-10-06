/*
DI-1312: VW_LOAN_FRAUD - Comprehensive Quality Control Validation
Validating the ACTUAL development object: BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD

Expected Results:
- Total loans: ~509
- Zero duplicate LOAN_IDs
- All 3 data sources represented
- Conservative fraud classification working correctly
- Data quality flags identifying inconsistencies
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

SELECT * FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

-- ============================================================================
-- TEST 1: ROW COUNT VALIDATION
-- ============================================================================

--1.1: Total fraud loans (Expected: ~509)
SELECT
    'Test 1.1: Total Fraud Loans' as test_name,
    COUNT(*) as actual_count,
    506 as expected_count,
    CASE WHEN COUNT(*) BETWEEN 500 AND 520 THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--1.2: Source count validation
SELECT
    'Test 1.2: Source Validation' as test_name,
    SUM(CASE WHEN HAS_CUSTOM_FIELDS THEN 1 ELSE 0 END) as custom_fields_count,
    SUM(CASE WHEN HAS_FRAUD_PORTFOLIO THEN 1 ELSE 0 END) as portfolio_count,
    SUM(CASE WHEN HAS_FRAUD_SUB_STATUS THEN 1 ELSE 0 END) as sub_status_count,
    'Expected: ~414, ~361, ~20' as expected_values
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

-- ============================================================================
-- TEST 2: DUPLICATE DETECTION (CRITICAL)
-- ============================================================================

--2.1: Check for duplicate LOAN_IDs (Expected: 0 rows)
SELECT
    'Test 2.1: Duplicate LOAN_IDs' as test_name,
    LOAN_ID,
    COUNT(*) as duplicate_count,
    CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY LOAN_ID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

--2.2: Unique constraint validation (Expected: Equal counts)
SELECT
    'Test 2.2: Unique Constraint' as test_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT LOAN_ID) as distinct_loans,
    CASE WHEN COUNT(*) = COUNT(DISTINCT LOAN_ID) THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

-- ============================================================================
-- TEST 3: DATA SOURCE DISTRIBUTION
-- ============================================================================

--3.1: Data source count distribution
SELECT
    'Test 3.1: Data Source Distribution' as test_name,
    DATA_SOURCE_COUNT,
    DATA_COMPLETENESS_FLAG,
    COUNT(*) as loan_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY DATA_SOURCE_COUNT, DATA_COMPLETENESS_FLAG
ORDER BY DATA_SOURCE_COUNT DESC;

--3.2: Source combination breakdown
SELECT
    'Test 3.2: Source Combinations' as test_name,
    DATA_SOURCE_LIST,
    COUNT(*) as loan_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY DATA_SOURCE_LIST
ORDER BY loan_count DESC;

-- ============================================================================
-- TEST 4: FRAUD STATUS DISTRIBUTION
-- ============================================================================

--4.1: Fraud status breakdown
SELECT
    'Test 4.1: Fraud Status Distribution' as test_name,
    FRAUD_STATUS,
    COUNT(*) as loan_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY FRAUD_STATUS
ORDER BY loan_count DESC;

--4.2: Active fraud flag distribution
SELECT
    'Test 4.2: Active Fraud Distribution' as test_name,
    IS_ACTIVE_FRAUD,
    FRAUD_STATUS,
    COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY IS_ACTIVE_FRAUD, FRAUD_STATUS
ORDER BY IS_ACTIVE_FRAUD DESC, loan_count DESC;

--4.3: Conservative classification validation (Any confirmed source should = CONFIRMED)
SELECT
    'Test 4.3: Conservative Classification Check' as test_name,
    COUNT(*) as potential_issues,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE (FRAUD_INVESTIGATION_RESULTS = 'Confirmed' OR FRAUD_PORTFOLIOS LIKE '%Confirmed%' OR LOAN_SUB_STATUS_ID = 61)
  AND FRAUD_STATUS != 'CONFIRMED'
  AND FRAUD_STATUS != 'MIXED';

-- ============================================================================
-- TEST 5: DATA QUALITY ASSESSMENT
-- ============================================================================

--5.1: Quality flag distribution
SELECT
    'Test 5.1: Data Quality Distribution' as test_name,
    DATA_QUALITY_FLAG,
    COUNT(*) as loan_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
GROUP BY DATA_QUALITY_FLAG
ORDER BY loan_count DESC;

--5.2: Inconsistent fraud classifications (Sample of MIXED status)
SELECT
    'Test 5.2: Inconsistent Classifications' as test_name,
    LOAN_ID,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    CURRENT_SUB_STATUS,
    FRAUD_STATUS,
    DATA_QUALITY_FLAG
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE DATA_QUALITY_FLAG = 'INCONSISTENT'
LIMIT 10;

-- ============================================================================
-- TEST 6: DATE FIELD VALIDATION
-- ============================================================================

--6.1: Earliest fraud date calculation summary
SELECT
    'Test 6.1: Date Field Summary' as test_name,
    COUNT(*) as total_loans,
    COUNT(EARLIEST_FRAUD_DATE) as has_earliest_date,
    MIN(EARLIEST_FRAUD_DATE) as oldest_fraud_date,
    MAX(EARLIEST_FRAUD_DATE) as newest_fraud_date,
    ROUND(100.0 * COUNT(EARLIEST_FRAUD_DATE) / COUNT(*), 2) as percentage_with_date
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--6.2: Date field population counts
SELECT
    'Test 6.2: Date Field Population' as test_name,
    COUNT(FRAUD_NOTIFICATION_RECEIVED) as has_notification_date,
    COUNT(FRAUD_CONFIRMED_DATE) as has_confirmed_date,
    COUNT(FIRST_PARTY_FRAUD_CONFIRMED_DATE) as has_first_party_date,
    COUNT(IDENTITY_THEFT_FRAUD_CONFIRMED_DATE) as has_identity_theft_date,
    COUNT(FRAUD_PENDING_INVESTIGATION_DATE) as has_pending_date,
    COUNT(FRAUD_DECLINED_DATE) as has_declined_date,
    COUNT(EARLIEST_FRAUD_DATE) as has_earliest_date
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--6.3: Verify EARLIEST_FRAUD_DATE logic (Sample validation)
SELECT
    'Test 6.3: Earliest Date Logic Validation' as test_name,
    LOAN_ID,
    FRAUD_NOTIFICATION_RECEIVED,
    FRAUD_CONFIRMED_DATE,
    FIRST_PARTY_FRAUD_CONFIRMED_DATE,
    IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
    FRAUD_PENDING_INVESTIGATION_DATE,
    FRAUD_DECLINED_DATE,
    EARLIEST_FRAUD_DATE,
    LEAST(
        FRAUD_NOTIFICATION_RECEIVED,
        FRAUD_CONFIRMED_DATE,
        FIRST_PARTY_FRAUD_CONFIRMED_DATE,
        IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
        FRAUD_PENDING_INVESTIGATION_DATE,
        FRAUD_DECLINED_DATE
    ) as expected_earliest_date,
    CASE WHEN EARLIEST_FRAUD_DATE = expected_earliest_date THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE EARLIEST_FRAUD_DATE IS NOT NULL
LIMIT 10;

-- ============================================================================
-- TEST 7: PORTFOLIO AGGREGATION
-- ============================================================================

--7.1: Multiple portfolio validation
SELECT
    'Test 7.1: Multiple Portfolios' as test_name,
    LOAN_ID,
    FRAUD_PORTFOLIO_COUNT,
    FRAUD_PORTFOLIOS
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_PORTFOLIO_COUNT > 1
ORDER BY FRAUD_PORTFOLIO_COUNT DESC
LIMIT 10;

--7.2: Portfolio count distribution
SELECT
    'Test 7.2: Portfolio Count Distribution' as test_name,
    FRAUD_PORTFOLIO_COUNT,
    COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_PORTFOLIO_COUNT IS NOT NULL
GROUP BY FRAUD_PORTFOLIO_COUNT
ORDER BY FRAUD_PORTFOLIO_COUNT DESC;

-- ============================================================================
-- TEST 8: REFERENTIAL INTEGRITY
-- ============================================================================

--8.1: Verify all loans have LOAN_ID (Expected: 0 nulls)
SELECT
    'Test 8.1: LOAN_ID Integrity' as test_name,
    COUNT(*) as null_loan_id_count,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE LOAN_ID IS NULL;

--8.2: LEAD_GUID population
SELECT
    'Test 8.2: LEAD_GUID Population' as test_name,
    COUNT(*) as total_loans,
    COUNT(LEAD_GUID) as has_lead_guid,
    ROUND(100.0 * COUNT(LEAD_GUID) / COUNT(*), 2) as percentage_with_lead_guid
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

-- ============================================================================
-- TEST 9: NULL HANDLING IN CALCULATED FIELDS
-- ============================================================================

--9.1: Boolean flag NULL check (Expected: All 0)
SELECT
    'Test 9.1: Boolean Flag NULL Check' as test_name,
    COUNT(CASE WHEN IS_ACTIVE_FRAUD IS NULL THEN 1 END) as null_active_flag,
    COUNT(CASE WHEN IS_CONFIRMED_FRAUD IS NULL THEN 1 END) as null_confirmed_flag,
    COUNT(CASE WHEN HAS_CUSTOM_FIELDS IS NULL THEN 1 END) as null_custom_fields_flag,
    COUNT(CASE WHEN HAS_FRAUD_PORTFOLIO IS NULL THEN 1 END) as null_portfolio_flag,
    COUNT(CASE WHEN HAS_FRAUD_SUB_STATUS IS NULL THEN 1 END) as null_substatus_flag,
    CASE WHEN COUNT(CASE WHEN IS_ACTIVE_FRAUD IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN IS_CONFIRMED_FRAUD IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN HAS_CUSTOM_FIELDS IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN HAS_FRAUD_PORTFOLIO IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN HAS_FRAUD_SUB_STATUS IS NULL THEN 1 END) = 0
    THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

--9.2: Calculated field NULL check (Expected: All 0)
SELECT
    'Test 9.2: Calculated Field NULL Check' as test_name,
    COUNT(CASE WHEN FRAUD_STATUS IS NULL THEN 1 END) as null_fraud_status,
    COUNT(CASE WHEN DATA_COMPLETENESS_FLAG IS NULL THEN 1 END) as null_completeness_flag,
    COUNT(CASE WHEN DATA_SOURCE_LIST IS NULL THEN 1 END) as null_source_list,
    COUNT(CASE WHEN DATA_SOURCE_COUNT IS NULL THEN 1 END) as null_source_count,
    CASE WHEN COUNT(CASE WHEN FRAUD_STATUS IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN DATA_COMPLETENESS_FLAG IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN DATA_SOURCE_LIST IS NULL THEN 1 END) = 0
         AND COUNT(CASE WHEN DATA_SOURCE_COUNT IS NULL THEN 1 END) = 0
    THEN 'PASS' ELSE 'FAIL' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;

-- ============================================================================
-- TEST 10: DATA COMPLETENESS ANALYSIS
-- ============================================================================

--10.1: Loans with all three data sources (Expected: ~20 loans)
SELECT
    'Test 10.1: Complete Data Sources' as test_name,
    COUNT(*) as loans_with_all_sources,
    CASE WHEN COUNT(*) BETWEEN 15 AND 25 THEN 'PASS' ELSE 'REVIEW' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE DATA_SOURCE_COUNT = 3;

--10.2: Single source loans analysis
SELECT
    'Test 10.2: Single Source Analysis' as test_name,
    CASE
        WHEN HAS_CUSTOM_FIELDS THEN 'CUSTOM_FIELDS_ONLY'
        WHEN HAS_FRAUD_PORTFOLIO THEN 'PORTFOLIO_ONLY'
        WHEN HAS_FRAUD_SUB_STATUS THEN 'SUB_STATUS_ONLY'
        ELSE 'UNKNOWN'
    END as single_source,
    COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE DATA_SOURCE_COUNT = 1
GROUP BY single_source
ORDER BY loan_count DESC;

-- ============================================================================
-- TEST 11: BUSINESS LOGIC VALIDATION
-- ============================================================================

--11.1: Confirmed fraud should have IS_CONFIRMED_FRAUD = TRUE
SELECT
    'Test 11.1: Confirmed Status Flag Consistency' as test_name,
    COUNT(*) as potential_issues,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'CONFIRMED'
  AND IS_CONFIRMED_FRAUD = FALSE;

--11.2: Declined fraud should have IS_DECLINED_FRAUD = TRUE
SELECT
    'Test 11.2: Declined Status Flag Consistency' as test_name,
    COUNT(*) as potential_issues,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'DECLINED'
  AND IS_DECLINED_FRAUD = FALSE;

--11.3: Under investigation should have IS_UNDER_INVESTIGATION = TRUE
SELECT
    'Test 11.3: Under Investigation Flag Consistency' as test_name,
    COUNT(*) as potential_issues,
    CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END as result
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'UNDER_INVESTIGATION'
  AND IS_UNDER_INVESTIGATION = FALSE;

-- ============================================================================
-- TEST 12: SAMPLE DATA REVIEW
-- ============================================================================

--12.1: Sample confirmed fraud loans
SELECT
    'Test 12.1: Sample Confirmed Fraud' as test_name,
    LOAN_ID,
    FRAUD_STATUS,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    CURRENT_SUB_STATUS,
    IS_CONFIRMED_FRAUD,
    IS_ACTIVE_FRAUD,
    DATA_SOURCE_COUNT
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'CONFIRMED'
LIMIT 5;

--12.2: Sample declined fraud loans
SELECT
    'Test 12.2: Sample Declined Fraud' as test_name,
    LOAN_ID,
    FRAUD_STATUS,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    IS_DECLINED_FRAUD,
    IS_ACTIVE_FRAUD,
    DATA_SOURCE_COUNT
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'DECLINED'
LIMIT 5;

--12.3: Sample UNKNOWN status loans (needs review)
SELECT
    'Test 12.3: Sample Unknown Status Loans' as test_name,
    LOAN_ID,
    FRAUD_STATUS,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    FRAUD_CONFIRMED_DATE,
    DATA_SOURCE_COUNT,
    DATA_QUALITY_FLAG
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'UNKNOWN'
LIMIT 5;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

SELECT '============================================' as summary_report;
SELECT 'DI-1312 VW_LOAN_FRAUD QC VALIDATION COMPLETE' as summary_report;
SELECT '============================================' as summary_report;
SELECT CONCAT('Total Fraud Loans: ', COUNT(*)) as summary_report
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD;
SELECT CONCAT('Expected: ~509 loans') as summary_report;
SELECT '============================================' as summary_report;
