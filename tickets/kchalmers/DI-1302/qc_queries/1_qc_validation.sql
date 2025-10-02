-- =============================================================================
-- DI-1302: Quality Control Validation Queries
-- =============================================================================
-- Purpose: Validate data quality and completeness for Mississippi regulatory exam
-- Data Source: MVW_LOAN_TAPE + VW_MEMBER_PII
-- =============================================================================

-- =============================================================================
-- PARAMETERS (must match main query)
-- =============================================================================
SET START_DATE = '2023-10-01';
SET END_DATE = '2025-09-30';
SET STATE_FILTER = 'MS';

-- =============================================================================
-- Test 1: Record Count Validation
-- =============================================================================
-- Purpose: Verify total count of Mississippi loans in date range
-- Expected: 181 loans

SELECT
    'Test 1: Record Count' AS test_name,
    COUNT(*) AS total_records,
    CASE
        WHEN COUNT(*) = 181 THEN 'PASS'
        ELSE 'FAIL - Expected 181 records'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE;

-- =============================================================================
-- Test 2: Date Range Validation
-- =============================================================================
-- Purpose: Confirm all loans fall within required date range
-- Expected: Min date >= 2023-10-01, Max date <= 2025-09-30

SELECT
    'Test 2: Date Range' AS test_name,
    MIN(ORIGINATIONDATE) AS earliest_origination,
    MAX(ORIGINATIONDATE) AS latest_origination,
    CASE
        WHEN MIN(ORIGINATIONDATE) >= $START_DATE
         AND MAX(ORIGINATIONDATE) <= $END_DATE
        THEN 'PASS'
        ELSE 'FAIL - Dates outside range'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE;

-- =============================================================================
-- Test 3: Duplicate Loan ID Check
-- =============================================================================
-- Purpose: Verify no duplicate LOANID values in result set
-- Expected: No duplicates

SELECT
    'Test 3: Duplicate Check' AS test_name,
    COUNT(*) AS total_records,
    COUNT(DISTINCT LOANID) AS unique_loan_ids,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT LOANID) THEN 'PASS'
        ELSE 'FAIL - Duplicate LOANID found'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE;

-- =============================================================================
-- Test 4: Required Field Completeness - Loan Data
-- =============================================================================
-- Purpose: Check for NULL values in required loan fields
-- Expected: All loan fields populated (STATUS, LOANAMOUNT, etc.)

SELECT
    'Test 4: Loan Fields' AS test_name,
    COUNT(*) AS total_records,
    SUM(CASE WHEN LOANID IS NULL THEN 1 ELSE 0 END) AS null_loanid,
    SUM(CASE WHEN ORIGINATIONDATE IS NULL THEN 1 ELSE 0 END) AS null_origination_date,
    SUM(CASE WHEN STATUS IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN LOANAMOUNT IS NULL THEN 1 ELSE 0 END) AS null_loan_amount,
    SUM(CASE WHEN TERM IS NULL THEN 1 ELSE 0 END) AS null_term,
    SUM(CASE WHEN INTERESTRATE IS NULL THEN 1 ELSE 0 END) AS null_interest_rate,
    SUM(CASE WHEN ORIGINATIONFEE IS NULL THEN 1 ELSE 0 END) AS null_origination_fee,
    SUM(CASE WHEN LASTPAYMENTDATE IS NULL THEN 1 ELSE 0 END) AS null_last_payment_date,
    CASE
        WHEN SUM(CASE WHEN LOANID IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN ORIGINATIONDATE IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN STATUS IS NULL THEN 1 ELSE 0 END) = 0
         AND SUM(CASE WHEN LOANAMOUNT IS NULL THEN 1 ELSE 0 END) = 0
        THEN 'PASS'
        ELSE 'WARNING - Check null counts above'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE;

-- =============================================================================
-- Test 5: PII Data Availability
-- =============================================================================
-- Purpose: Check how many loans have matching borrower PII data
-- Expected: Most loans should have PII (names and addresses)

WITH ms_loans AS (
    SELECT PAYOFFUID, LOANID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
    WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
      AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE
),
pii_joined AS (
    SELECT
        A.*,
        C.MEMBER_ID,
        B.FIRST_NAME,
        B.LAST_NAME,
        B.ADDRESS_1,
        B.CITY,
        B.STATE,
        B.ZIP_CODE
    FROM ms_loans A
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN C
        ON A.PAYOFFUID = C.LEAD_GUID
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII B
        ON B.MEMBER_ID = C.MEMBER_ID
        AND B.MEMBER_PII_END_DATE IS NULL
)
SELECT
    'Test 5: PII Availability' AS test_name,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN MEMBER_ID IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_member_id,
    SUM(CASE WHEN FIRST_NAME IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_first_name,
    SUM(CASE WHEN LAST_NAME IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_last_name,
    SUM(CASE WHEN ADDRESS_1 IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_address,
    SUM(CASE WHEN CITY IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_city,
    SUM(CASE WHEN STATE IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_state,
    SUM(CASE WHEN ZIP_CODE IS NOT NULL THEN 1 ELSE 0 END) AS loans_with_zip,
    CASE
        WHEN SUM(CASE WHEN FIRST_NAME IS NOT NULL THEN 1 ELSE 0 END) >= 175
        THEN 'PASS - Most loans have PII'
        ELSE 'WARNING - Low PII coverage'
    END AS test_result
FROM pii_joined;

-- =============================================================================
-- Test 6: State Filter Validation
-- =============================================================================
-- Purpose: Confirm all records are Mississippi loans only
-- Expected: All records have APPLICANTRESIDENCESTATE = 'MS'

SELECT
    'Test 6: State Filter' AS test_name,
    APPLICANTRESIDENCESTATE AS state,
    COUNT(*) AS loan_count,
    CASE
        WHEN COUNT(DISTINCT APPLICANTRESIDENCESTATE) = 1
         AND MAX(UPPER(APPLICANTRESIDENCESTATE)) = $STATE_FILTER
        THEN 'PASS'
        ELSE 'FAIL - Non-MS states found'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE
GROUP BY APPLICANTRESIDENCESTATE;

-- =============================================================================
-- Test 7: Loan Status Distribution
-- =============================================================================
-- Purpose: Review distribution of loan statuses for regulatory context
-- Expected: Mix of Current, Paid in Full, Charge off, etc.

SELECT
    'Test 7: Status Distribution' AS test_name,
    STATUS,
    COUNT(*) AS loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE
GROUP BY STATUS
ORDER BY loan_count DESC;

-- =============================================================================
-- Test 8: Interest Rate Range Validation
-- =============================================================================
-- Purpose: Verify interest rates are within reasonable ranges
-- Expected: Interest rates between 5% and 30%

SELECT
    'Test 8: Interest Rate Range' AS test_name,
    MIN(INTERESTRATE * 100) AS min_interest_rate_pct,
    MAX(INTERESTRATE * 100) AS max_interest_rate_pct,
    ROUND(AVG(INTERESTRATE * 100), 2) AS avg_interest_rate_pct,
    CASE
        WHEN MIN(INTERESTRATE * 100) >= 5
         AND MAX(INTERESTRATE * 100) <= 30
        THEN 'PASS'
        ELSE 'WARNING - Check interest rate values'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE;

-- =============================================================================
-- Test 9: Loan Amount Range Validation
-- =============================================================================
-- Purpose: Review loan amount distribution
-- Expected: Loan amounts within Happy Money's typical ranges

SELECT
    'Test 9: Loan Amount Range' AS test_name,
    MIN(LOANAMOUNT) AS min_loan_amount,
    MAX(LOANAMOUNT) AS max_loan_amount,
    ROUND(AVG(LOANAMOUNT), 2) AS avg_loan_amount,
    SUM(LOANAMOUNT) AS total_loan_volume,
    CASE
        WHEN MIN(LOANAMOUNT) >= 3500
         AND MAX(LOANAMOUNT) <= 40000
        THEN 'PASS'
        ELSE 'WARNING - Check loan amounts'
    END AS test_result
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE;

-- =============================================================================
-- Test 10: Origination Date by Month
-- =============================================================================
-- Purpose: Review temporal distribution of loan originations
-- Expected: Consistent distribution across date range

SELECT
    'Test 10: Monthly Distribution' AS test_name,
    DATE_TRUNC('MONTH', ORIGINATIONDATE) AS origination_month,
    COUNT(*) AS loan_count,
    SUM(LOANAMOUNT) AS total_amount
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
  AND ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE
GROUP BY DATE_TRUNC('MONTH', ORIGINATIONDATE)
ORDER BY origination_month;

-- =============================================================================
-- EXECUTION NOTES:
-- =============================================================================
-- 1. Run each test query sequentially
-- 2. Review test_result column for PASS/FAIL/WARNING status
-- 3. Investigate any FAIL or WARNING results before finalizing deliverable
-- 4. Document any data quality issues in README.md
-- 5. Tests 7-10 are informational (no pass/fail criteria)
-- =============================================================================
