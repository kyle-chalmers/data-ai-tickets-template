-- QC Validation for Enhanced VW_LOAN_DEBT_SETTLEMENT (DI-1235)
-- Comprehensive testing of ACTIONS source integration and backward compatibility
-- Target: BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT

-- ============================================================================
-- 1. RECORD COUNT VALIDATION
-- ============================================================================

--1.1: Production Baseline Count
SELECT 'Production Baseline' as test_name,
       COUNT(*) as loan_count,
       14183 as expected_count,
       CASE WHEN COUNT(*) = 14183 THEN 'PASS' ELSE 'REVIEW' END as status
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

--1.2: Development Enhanced Count
SELECT 'Development Enhanced' as test_name,
       COUNT(*) as loan_count,
       'Expected ~14,180-15,000' as expected_range,
       CASE WHEN COUNT(*) BETWEEN 14180 AND 15000 THEN 'PASS' ELSE 'FAIL' END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

--1.3: New Loans Added (From ACTIONS source)
SELECT 'New Loans from ACTIONS' as test_name,
       COUNT(DISTINCT dev.LOAN_ID) as new_loan_count,
       'Expected ~0-900' as expected_range
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT dev
WHERE dev.LOAN_ID NOT IN (SELECT LOAN_ID FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT);

-- ============================================================================
-- 2. DUPLICATE DETECTION (CRITICAL)
-- ============================================================================

--2.1: Duplicate Loan Check in Development View
SELECT 'Duplicate Loan Check' as test_name,
       COUNT(*) as duplicate_count,
       0 as expected_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'CRITICAL_FAIL' END as status
FROM (
    SELECT LOAN_ID, COUNT(*) as cnt
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
    GROUP BY LOAN_ID
    HAVING COUNT(*) > 1
);

--2.2: Sample Duplicates (if any exist)
SELECT 'Sample Duplicate Records' as test_name,
       LOAN_ID,
       COUNT(*) as occurrence_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
GROUP BY LOAN_ID
HAVING COUNT(*) > 1
LIMIT 10;

-- ============================================================================
-- 3. ACTIONS SOURCE VALIDATION
-- ============================================================================

--3.1: ACTIONS Source Record Count
SELECT 'ACTIONS Source Loans' as test_name,
       COUNT(*) as loan_count_with_actions,
       876 as expected_from_source,
       CASE WHEN COUNT(*) BETWEEN 870 AND 880 THEN 'PASS' ELSE 'REVIEW' END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE;

--3.2: ACTIONS Field Population Check
SELECT 'ACTIONS Fields Populated' as test_name,
       COUNT(*) as total_action_loans,
       SUM(CASE WHEN EARLIEST_SETTLEMENT_ACTION_DATE IS NOT NULL THEN 1 ELSE 0 END) as has_earliest_date,
       SUM(CASE WHEN LATEST_SETTLEMENT_ACTION_DATE IS NOT NULL THEN 1 ELSE 0 END) as has_latest_date,
       SUM(CASE WHEN SETTLEMENT_ACTION_COUNT IS NOT NULL THEN 1 ELSE 0 END) as has_count,
       SUM(CASE WHEN LATEST_SETTLEMENT_ACTION_AGENT IS NOT NULL THEN 1 ELSE 0 END) as has_agent,
       SUM(CASE WHEN LATEST_SETTLEMENT_ACTION_NOTE IS NOT NULL THEN 1 ELSE 0 END) as has_note,
       CASE
           WHEN SUM(CASE WHEN EARLIEST_SETTLEMENT_ACTION_DATE IS NOT NULL THEN 1 ELSE 0 END) = COUNT(*)
           AND SUM(CASE WHEN LATEST_SETTLEMENT_ACTION_DATE IS NOT NULL THEN 1 ELSE 0 END) = COUNT(*)
           AND SUM(CASE WHEN SETTLEMENT_ACTION_COUNT IS NOT NULL THEN 1 ELSE 0 END) = COUNT(*)
           THEN 'PASS'
           ELSE 'FAIL'
       END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE;

--3.3: ACTIONS Date Logic Validation (earliest <= latest)
SELECT 'ACTIONS Date Logic' as test_name,
       COUNT(*) as total_action_loans,
       SUM(CASE WHEN EARLIEST_SETTLEMENT_ACTION_DATE <= LATEST_SETTLEMENT_ACTION_DATE THEN 1 ELSE 0 END) as valid_date_logic,
       SUM(CASE WHEN EARLIEST_SETTLEMENT_ACTION_DATE > LATEST_SETTLEMENT_ACTION_DATE THEN 1 ELSE 0 END) as invalid_date_logic,
       CASE
           WHEN SUM(CASE WHEN EARLIEST_SETTLEMENT_ACTION_DATE > LATEST_SETTLEMENT_ACTION_DATE THEN 1 ELSE 0 END) = 0
           THEN 'PASS'
           ELSE 'FAIL'
       END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE;

--3.4: ACTIONS Multi-Action Loan Analysis
SELECT 'Multi-Action Loans' as test_name,
       COUNT(*) as loans_with_multiple_actions,
       'Expected ~45 loans' as expected_range
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE SETTLEMENT_ACTION_COUNT > 1;

-- ============================================================================
-- 4. DATA SOURCE TRACKING VALIDATION
-- ============================================================================

--4.1: DATA_SOURCE_COUNT Range Validation
SELECT 'DATA_SOURCE_COUNT Range' as test_name,
       MIN(DATA_SOURCE_COUNT) as min_count,
       MAX(DATA_SOURCE_COUNT) as max_count,
       1 as expected_min,
       5 as expected_max,
       CASE
           WHEN MIN(DATA_SOURCE_COUNT) >= 1 AND MAX(DATA_SOURCE_COUNT) <= 5
           THEN 'PASS'
           ELSE 'FAIL'
       END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

--4.2: DATA_SOURCE_COUNT Distribution
SELECT 'Source Count Distribution' as test_name,
       DATA_SOURCE_COUNT,
       COUNT(*) as loan_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
GROUP BY DATA_SOURCE_COUNT
ORDER BY DATA_SOURCE_COUNT;

--4.3: DATA_COMPLETENESS_FLAG Distribution
SELECT 'Completeness Flag Distribution' as test_name,
       DATA_COMPLETENESS_FLAG,
       COUNT(*) as loan_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
GROUP BY DATA_COMPLETENESS_FLAG
ORDER BY DATA_COMPLETENESS_FLAG;

--4.4: DATA_SOURCE_LIST Includes ACTIONS
SELECT 'ACTIONS in DATA_SOURCE_LIST' as test_name,
       COUNT(*) as loans_with_actions_flag,
       SUM(CASE WHEN DATA_SOURCE_LIST LIKE '%ACTIONS%' THEN 1 ELSE 0 END) as loans_with_actions_in_list,
       CASE
           WHEN COUNT(*) = SUM(CASE WHEN DATA_SOURCE_LIST LIKE '%ACTIONS%' THEN 1 ELSE 0 END)
           THEN 'PASS'
           ELSE 'FAIL'
       END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE;

--4.5: HAS_SETTLEMENT_ACTION Flag Accuracy
SELECT 'HAS_SETTLEMENT_ACTION Accuracy' as test_name,
       SUM(CASE WHEN HAS_SETTLEMENT_ACTION = TRUE
                AND (EARLIEST_SETTLEMENT_ACTION_DATE IS NOT NULL
                     OR LATEST_SETTLEMENT_ACTION_DATE IS NOT NULL
                     OR SETTLEMENT_ACTION_COUNT IS NOT NULL)
           THEN 1 ELSE 0 END) as correct_true_flags,
       SUM(CASE WHEN HAS_SETTLEMENT_ACTION = FALSE
                AND EARLIEST_SETTLEMENT_ACTION_DATE IS NULL
                AND LATEST_SETTLEMENT_ACTION_DATE IS NULL
                AND SETTLEMENT_ACTION_COUNT IS NULL
           THEN 1 ELSE 0 END) as correct_false_flags,
       SUM(CASE WHEN HAS_SETTLEMENT_ACTION = TRUE THEN 1 ELSE 0 END) as total_true_flags,
       SUM(CASE WHEN HAS_SETTLEMENT_ACTION = FALSE THEN 1 ELSE 0 END) as total_false_flags,
       CASE
           WHEN SUM(CASE WHEN HAS_SETTLEMENT_ACTION = TRUE THEN 1 ELSE 0 END) =
                SUM(CASE WHEN HAS_SETTLEMENT_ACTION = TRUE
                         AND (EARLIEST_SETTLEMENT_ACTION_DATE IS NOT NULL) THEN 1 ELSE 0 END)
           THEN 'PASS'
           ELSE 'FAIL'
       END as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

-- ============================================================================
-- 5. BACKWARD COMPATIBILITY VALIDATION
-- ============================================================================

--5.1: Column Count Comparison
SELECT 'Column Count Check' as test_name,
       (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'ANALYTICS'
        AND TABLE_NAME = 'VW_LOAN_DEBT_SETTLEMENT'
        AND TABLE_CATALOG = 'BUSINESS_INTELLIGENCE') as prod_columns,
       (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'ANALYTICS'
        AND TABLE_NAME = 'VW_LOAN_DEBT_SETTLEMENT'
        AND TABLE_CATALOG = 'BUSINESS_INTELLIGENCE_DEV') as dev_columns,
       'Dev should have 5-6 more columns' as expected;

--5.2: Sample Existing Column Value Comparison
SELECT 'Existing Columns Match' as test_name,
       COUNT(*) as total_compared,
       SUM(CASE WHEN prod.LOAN_ID = dev.LOAN_ID
                AND COALESCE(prod.SETTLEMENTSTATUS, 'NULL') = COALESCE(dev.SETTLEMENTSTATUS, 'NULL')
                AND COALESCE(prod.SETTLEMENT_AMOUNT, -999) = COALESCE(dev.SETTLEMENT_AMOUNT, -999)
                AND COALESCE(prod.SETTLEMENT_COMPANY, 'NULL') = COALESCE(dev.SETTLEMENT_COMPANY, 'NULL')
           THEN 1 ELSE 0 END) as matching_records,
       CASE
           WHEN COUNT(*) = SUM(CASE WHEN prod.LOAN_ID = dev.LOAN_ID
                                    AND COALESCE(prod.SETTLEMENTSTATUS, 'NULL') = COALESCE(dev.SETTLEMENTSTATUS, 'NULL')
                                THEN 1 ELSE 0 END)
           THEN 'PASS'
           ELSE 'REVIEW'
       END as status
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT prod
INNER JOIN BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT dev
    ON prod.LOAN_ID = dev.LOAN_ID
LIMIT 1000;

--5.3: Existing Source Flags Unchanged
SELECT 'Existing Source Flags' as test_name,
       COUNT(*) as total_compared,
       SUM(CASE WHEN prod.HAS_CUSTOM_FIELDS = dev.HAS_CUSTOM_FIELDS
                AND prod.HAS_SETTLEMENT_PORTFOLIO = dev.HAS_SETTLEMENT_PORTFOLIO
                AND prod.HAS_SETTLEMENT_DOCUMENT = dev.HAS_SETTLEMENT_DOCUMENT
                AND prod.HAS_SETTLEMENT_SUB_STATUS = dev.HAS_SETTLEMENT_SUB_STATUS
           THEN 1 ELSE 0 END) as matching_flags,
       CASE
           WHEN COUNT(*) = SUM(CASE WHEN prod.HAS_CUSTOM_FIELDS = dev.HAS_CUSTOM_FIELDS THEN 1 ELSE 0 END)
           THEN 'PASS'
           ELSE 'FAIL'
       END as status
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT prod
INNER JOIN BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT dev
    ON prod.LOAN_ID = dev.LOAN_ID
LIMIT 1000;

-- ============================================================================
-- 6. DATA INTEGRITY VALIDATION
-- ============================================================================

--6.1: LEAD_GUID Population
SELECT 'LEAD_GUID Population' as test_name,
       COUNT(*) as total_loans,
       SUM(CASE WHEN LEAD_GUID IS NOT NULL THEN 1 ELSE 0 END) as has_lead_guid,
       SUM(CASE WHEN LEAD_GUID IS NULL THEN 1 ELSE 0 END) as missing_lead_guid,
       ROUND(SUM(CASE WHEN LEAD_GUID IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as percentage_populated
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

--6.2: Key Settlement Fields NULL Analysis
SELECT 'NULL Field Analysis' as test_name,
       COUNT(*) as total_loans,
       SUM(CASE WHEN SETTLEMENTSTATUS IS NULL THEN 1 ELSE 0 END) as null_status,
       SUM(CASE WHEN SETTLEMENT_AMOUNT IS NULL THEN 1 ELSE 0 END) as null_amount,
       SUM(CASE WHEN SETTLEMENT_COMPANY IS NULL THEN 1 ELSE 0 END) as null_company,
       SUM(CASE WHEN CURRENT_STATUS IS NULL THEN 1 ELSE 0 END) as null_current_status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

--6.3: Loans With ACTIONS But No Custom Fields
SELECT 'ACTIONS-Only Loans' as test_name,
       COUNT(*) as loan_count,
       'Loans with settlement actions but no custom fields data' as description
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE
  AND HAS_CUSTOM_FIELDS = FALSE;

-- ============================================================================
-- 7. JOIN INTEGRITY TESTING
-- ============================================================================

--7.1: ACTIONS Source Join Integrity
SELECT 'ACTIONS Join Integrity' as test_name,
       src.unique_action_loans,
       view.loans_with_action_flag,
       CASE WHEN src.unique_action_loans = view.loans_with_action_flag THEN 'PASS' ELSE 'REVIEW' END as status
FROM (
    SELECT COUNT(DISTINCT LOAN_ID) as unique_action_loans
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS
    WHERE RESULT_TEXT = 'Settlement Payment Plan Set up'
) src
CROSS JOIN (
    SELECT COUNT(*) as loans_with_action_flag
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
    WHERE HAS_SETTLEMENT_ACTION = TRUE
) view;

--7.2: Unmatched ACTIONS Loans
SELECT 'Unmatched ACTIONS Loans' as test_name,
       COUNT(*) as unmatched_count,
       0 as expected_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'REVIEW' END as status
FROM (
    SELECT DISTINCT LOAN_ID
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS
    WHERE RESULT_TEXT = 'Settlement Payment Plan Set up'
) actions
WHERE actions.LOAN_ID::VARCHAR NOT IN (
    SELECT LOAN_ID
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
    WHERE HAS_SETTLEMENT_ACTION = TRUE
);

-- ============================================================================
-- 8. PERFORMANCE VALIDATION
-- ============================================================================

--8.1: Sample Query Performance Test
SELECT 'Sample Query Test' as test_name,
       COUNT(*) as result_count,
       MAX(SETTLEMENT_ACTION_COUNT) as max_action_count,
       'Query should return quickly' as performance_note
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE
  AND DATA_SOURCE_COUNT >= 2;

-- ============================================================================
-- 9. SAMPLE DATA REVIEW
-- ============================================================================

--9.1: Sample Records with ACTIONS Data
SELECT 'Sample ACTIONS Records' as test_name,
       LOAN_ID,
       SETTLEMENTSTATUS,
       SETTLEMENT_ACTION_COUNT,
       EARLIEST_SETTLEMENT_ACTION_DATE,
       LATEST_SETTLEMENT_ACTION_DATE,
       LATEST_SETTLEMENT_ACTION_AGENT,
       LEFT(LATEST_SETTLEMENT_ACTION_NOTE, 100) as note_preview,
       DATA_SOURCE_COUNT,
       DATA_SOURCE_LIST
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE
ORDER BY SETTLEMENT_ACTION_COUNT DESC, LATEST_SETTLEMENT_ACTION_DATE DESC
LIMIT 10;

--9.2: Sample Records with Multiple Data Sources Including ACTIONS
SELECT 'Multi-Source with ACTIONS' as test_name,
       LOAN_ID,
       DATA_SOURCE_COUNT,
       DATA_SOURCE_LIST,
       HAS_CUSTOM_FIELDS,
       HAS_SETTLEMENT_PORTFOLIO,
       HAS_SETTLEMENT_DOCUMENT,
       HAS_SETTLEMENT_SUB_STATUS,
       HAS_SETTLEMENT_ACTION
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
WHERE HAS_SETTLEMENT_ACTION = TRUE
  AND DATA_SOURCE_COUNT >= 3
ORDER BY DATA_SOURCE_COUNT DESC
LIMIT 10;

-- ============================================================================
-- 10. SUMMARY STATISTICS
-- ============================================================================

--10.1: Overall Summary
SELECT 'Overall Summary' as test_name,
       COUNT(DISTINCT LOAN_ID) as total_unique_loans,
       SUM(CASE WHEN HAS_CUSTOM_FIELDS = TRUE THEN 1 ELSE 0 END) as loans_with_custom_fields,
       SUM(CASE WHEN HAS_SETTLEMENT_PORTFOLIO = TRUE THEN 1 ELSE 0 END) as loans_with_portfolios,
       SUM(CASE WHEN HAS_SETTLEMENT_DOCUMENT = TRUE THEN 1 ELSE 0 END) as loans_with_documents,
       SUM(CASE WHEN HAS_SETTLEMENT_SUB_STATUS = TRUE THEN 1 ELSE 0 END) as loans_with_sub_status,
       SUM(CASE WHEN HAS_SETTLEMENT_ACTION = TRUE THEN 1 ELSE 0 END) as loans_with_actions,
       ROUND(AVG(DATA_SOURCE_COUNT), 2) as avg_source_count,
       MIN(DATA_SOURCE_COUNT) as min_sources,
       MAX(DATA_SOURCE_COUNT) as max_sources
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;
