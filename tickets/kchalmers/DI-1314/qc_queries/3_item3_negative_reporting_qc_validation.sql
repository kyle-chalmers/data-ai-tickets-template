-- DI-1314: Item 3 - FCRA Negative Credit Reporting QC Validation
-- Testing Query: 3_item3_fcra_negative_credit_reporting.sql
-- Date: 2025-10-16
-- Author: Kyle Chalmers
--
-- QC Purpose: Validate data quality for first 30-day delinquency analysis
-- Modified: Updated for DAYSPASTDUE >= 30 threshold

-- ============================================================================
-- PARAMETERS
-- ============================================================================

SET START_DATE = '2024-10-01';
SET END_DATE = '2025-08-31';

-- ============================================================================
-- QC TEST 0: CRITICAL - Verify No Prior 30+ DPD Before Scope Period
-- ============================================================================
-- Expected: Zero loans should have been 30+ DPD before 2024-10-01
-- This validates the core business logic: only loans with FIRST-EVER 30+ DPD in scope

WITH first_ever_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_EVER_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
    GROUP BY LOANID
),
loans_in_scope AS (
    SELECT LOANID
    FROM first_ever_delinquency
    WHERE FIRST_EVER_LATE_DATE BETWEEN $START_DATE AND $END_DATE
),
loans_with_prior_delinquency AS (
    SELECT
        lis.LOANID,
        fed.FIRST_EVER_LATE_DATE
    FROM loans_in_scope lis
    INNER JOIN first_ever_delinquency fed
        ON lis.LOANID = fed.LOANID
    WHERE fed.FIRST_EVER_LATE_DATE < $START_DATE
)
SELECT
    'CRITICAL - Prior 30+ DPD Check' as CHECK_TYPE,
    COUNT(*) as LOANS_WITH_PRIOR_30DPD,
    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS - No loans had prior 30+ DPD before scope period'
        ELSE 'FAIL - Loans found with 30+ DPD before Oct 1, 2024'
    END as QC_RESULT
FROM loans_with_prior_delinquency;

-- ============================================================================
-- QC TEST 1: Record Count and Uniqueness
-- ============================================================================
-- Expected: Each loan should appear exactly once (first 30-day delinquency only)

SELECT
    'Total Records' as CHECK_TYPE,
    COUNT(*) as RECORD_COUNT,
    COUNT(DISTINCT LOANID) as UNIQUE_LOANS,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT LOANID)
        THEN 'PASS - No duplicate loans'
        ELSE 'FAIL - Duplicate loans found'
    END as QC_RESULT
FROM (
    SELECT LOANID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID
);

-- ============================================================================
-- QC TEST 2: CRB Portfolio Filter Validation
-- ============================================================================
-- Expected: All records should have PORTFOLIOID IN ('32', '34', '54', '56')

SELECT
    'CRB Portfolio Filter' as CHECK_TYPE,
    PORTFOLIOID,
    PORTFOLIONAME,
    COUNT(*) as LOAN_COUNT
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE DAYSPASTDUE >= 30
  AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
GROUP BY PORTFOLIOID, PORTFOLIONAME
ORDER BY PORTFOLIOID;

-- ============================================================================
-- QC TEST 3: Date Range Validation
-- ============================================================================
-- Expected: All FIRST_LATE_DATE values should be between 2024-10-01 and 2025-08-31

WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID
)
SELECT
    'Date Range Validation' as CHECK_TYPE,
    MIN(FIRST_LATE_DATE) as EARLIEST_FIRST_LATE_DATE,
    MAX(FIRST_LATE_DATE) as LATEST_FIRST_LATE_DATE,
    CASE
        WHEN MIN(FIRST_LATE_DATE) >= $START_DATE
         AND MAX(FIRST_LATE_DATE) <= $END_DATE
        THEN 'PASS - All dates within range'
        ELSE 'FAIL - Dates outside range found'
    END as QC_RESULT
FROM first_delinquency;

-- ============================================================================
-- QC TEST 4: Days Past Due Threshold Validation
-- ============================================================================
-- Expected: All DAYS_PAST_DUE values should be >= 30

WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_LATE_DATE,
        MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID
)
SELECT
    'Days Past Due Validation' as CHECK_TYPE,
    MIN(DAYS_PAST_DUE_AT_FIRST_LATE) as MIN_DPD,
    MAX(DAYS_PAST_DUE_AT_FIRST_LATE) as MAX_DPD,
    AVG(DAYS_PAST_DUE_AT_FIRST_LATE) as AVG_DPD,
    CASE
        WHEN MIN(DAYS_PAST_DUE_AT_FIRST_LATE) >= 30
        THEN 'PASS - All loans >= 30 DPD'
        ELSE 'FAIL - Loans < 30 DPD found'
    END as QC_RESULT
FROM first_delinquency;

-- ============================================================================
-- QC TEST 5: Days Past Due Distribution
-- ============================================================================
-- Purpose: Understand distribution of delinquency severity at first 30-day late

WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID
)
SELECT
    'DPD Distribution' as CHECK_TYPE,
    CASE
        WHEN DAYS_PAST_DUE_AT_FIRST_LATE BETWEEN 30 AND 59 THEN '30-59 Days'
        WHEN DAYS_PAST_DUE_AT_FIRST_LATE BETWEEN 60 AND 89 THEN '60-89 Days'
        WHEN DAYS_PAST_DUE_AT_FIRST_LATE BETWEEN 90 AND 119 THEN '90-119 Days'
        WHEN DAYS_PAST_DUE_AT_FIRST_LATE >= 120 THEN '120+ Days'
    END as DPD_BUCKET,
    COUNT(*) as LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as PERCENTAGE
FROM first_delinquency
GROUP BY DPD_BUCKET
ORDER BY DPD_BUCKET;

-- ============================================================================
-- QC TEST 6: Borrower Name Matching Rate
-- ============================================================================
-- Expected: High percentage of loans should match to borrower names

WITH first_delinquency AS (
    SELECT
        LOANID,
        PAYOFFUID,
        MIN(ASOFDATE) as FIRST_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID, PAYOFFUID
),
borrower_names AS (
    SELECT
        vl.LEAD_GUID,
        vl.MEMBER_ID,
        pii.FIRST_NAME || ' ' || pii.LAST_NAME as BORROWER_NAME
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII pii
        ON vl.MEMBER_ID = pii.MEMBER_ID
        AND pii.MEMBER_PII_END_DATE IS NULL
)
SELECT
    'Borrower Name Match Rate' as CHECK_TYPE,
    COUNT(DISTINCT fd.LOANID) as TOTAL_LOANS,
    COUNT(DISTINCT CASE WHEN bn.BORROWER_NAME IS NOT NULL THEN fd.LOANID END) as LOANS_WITH_NAMES,
    COUNT(DISTINCT CASE WHEN bn.BORROWER_NAME IS NULL THEN fd.LOANID END) as LOANS_WITHOUT_NAMES,
    ROUND(COUNT(DISTINCT CASE WHEN bn.BORROWER_NAME IS NOT NULL THEN fd.LOANID END) * 100.0 /
          COUNT(DISTINCT fd.LOANID), 2) as MATCH_RATE_PERCENTAGE
FROM first_delinquency fd
LEFT JOIN borrower_names bn
    ON fd.PAYOFFUID = bn.LEAD_GUID;

-- ============================================================================
-- QC TEST 7: CRA Reporting Status Distribution
-- ============================================================================
-- Purpose: Understand distribution of reporting status (Yes/No/Pending)

WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID
),
credit_bureau_exports AS (
    SELECT
        DATE(TIME_COMPLETED) as EXPORT_DATE
    FROM RAW_DATA_STORE.LOANPRO.CREDIT_REPORT_HISTORY
    WHERE ENTITY_TYPE = 'Entity.Loan'
      AND TIME_COMPLETED IS NOT NULL
),
next_export_after_late AS (
    SELECT
        fd.LOANID,
        fd.FIRST_LATE_DATE,
        MIN(cbe.EXPORT_DATE) as NEXT_EXPORT_DATE
    FROM first_delinquency fd
    LEFT JOIN credit_bureau_exports cbe
        ON cbe.EXPORT_DATE >= fd.FIRST_LATE_DATE
    GROUP BY fd.LOANID, fd.FIRST_LATE_DATE
)
SELECT
    'CRA Reporting Status' as CHECK_TYPE,
    CASE
        WHEN NEXT_EXPORT_DATE IS NOT NULL AND NEXT_EXPORT_DATE <= CURRENT_DATE()
        THEN 'Yes'
        WHEN NEXT_EXPORT_DATE IS NOT NULL AND NEXT_EXPORT_DATE > CURRENT_DATE()
        THEN 'Pending'
        ELSE 'No'
    END as REPORTED_STATUS,
    COUNT(*) as LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as PERCENTAGE
FROM next_export_after_late
GROUP BY REPORTED_STATUS
ORDER BY REPORTED_STATUS;

-- ============================================================================
-- QC TEST 8: First Late Date Distribution by Month
-- ============================================================================
-- Purpose: Understand temporal distribution of first 30-day delinquencies

WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID
)
SELECT
    'Monthly Distribution' as CHECK_TYPE,
    TO_CHAR(FIRST_LATE_DATE, 'YYYY-MM') as MONTH,
    COUNT(*) as LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as PERCENTAGE
FROM first_delinquency
GROUP BY MONTH
ORDER BY MONTH;

-- ============================================================================
-- QC TEST 9: Portfolio Distribution
-- ============================================================================
-- Purpose: Understand which CRB portfolios have the most 30-day delinquencies

WITH first_delinquency AS (
    SELECT
        LOANID,
        PORTFOLIOID,
        PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID, PORTFOLIOID, PORTFOLIONAME
)
SELECT
    'Portfolio Distribution' as CHECK_TYPE,
    PORTFOLIOID,
    PORTFOLIONAME,
    COUNT(*) as LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as PERCENTAGE
FROM first_delinquency
GROUP BY PORTFOLIOID, PORTFOLIONAME
ORDER BY PORTFOLIOID;

-- ============================================================================
-- SUMMARY QC REPORT
-- ============================================================================
-- Combine key validation results into single view

SELECT 'QC VALIDATION SUMMARY - Item 3: FCRA Negative Credit Reporting (30-Day Threshold)' as REPORT_TITLE;
