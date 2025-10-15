-- DI-1314: FCRA Negative Credit Reporting (Item 3 / Ref 6.A)
-- Prototype Query: First Late Payment Tracking for CRB Originations
-- Date Range: October 1, 2024 - August 31, 2025
-- Date: 2025-10-14

-- =============================================================================
-- BUSINESS REQUIREMENT
-- =============================================================================
-- List of all customers who had their first late payment during 10/1/24 - 8/31/25
-- Required Fields:
--   - Loan Number
--   - Borrower Name
--   - Date of first late payment
--   - How many days past due borrower became
--   - If borrower was reported late to CRA

-- =============================================================================
-- APPROACH
-- =============================================================================
-- 1. Use MVW_LOAN_TAPE_DAILY_HISTORY to find first date DAYSPASTDUE > 0
-- 2. Filter to CRB portfolios (32, 34, 54, 56)
-- 3. Filter to first late payment occurring in date range
-- 4. Join to VW_MEMBER_PII for borrower name
-- 5. TODO: Find credit bureau reporting table to determine if reported to CRA

-- =============================================================================
-- STEP 1: IDENTIFY FIRST LATE PAYMENT FOR EACH LOAN
-- =============================================================================

-- Test query: Find when loans first went past due
WITH first_delinquency AS (
    SELECT
        LOANID,
        PAYOFFUID,
        PORTFOLIOID,
        PORTFOLIONAME,
        MIN(ASOFDATE) as FIRST_LATE_DATE,
        MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE,
        MIN_BY(STATUS, ASOFDATE) as STATUS_AT_FIRST_LATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')  -- CRB originations only
        AND DAYSPASTDUE > 0  -- Loan became delinquent
        AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'  -- First late in this period
    GROUP BY LOANID, PAYOFFUID, PORTFOLIOID, PORTFOLIONAME
),

-- =============================================================================
-- STEP 2: GET BORROWER PII
-- =============================================================================

loan_with_pii AS (
    SELECT
        fd.LOANID,
        fd.PAYOFFUID,
        fd.PORTFOLIOID,
        fd.PORTFOLIONAME,
        fd.FIRST_LATE_DATE,
        fd.DAYS_PAST_DUE_AT_FIRST_LATE,
        fd.STATUS_AT_FIRST_LATE,
        pii.FIRST_NAME,
        pii.LAST_NAME,
        pii.FIRST_NAME || ' ' || pii.LAST_NAME as BORROWER_NAME
    FROM first_delinquency fd
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON fd.PAYOFFUID = vl.LEAD_GUID
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII pii
        ON pii.MEMBER_PII_END_DATE IS NULL
        AND pii.MEMBER_ID = vl.MEMBER_ID
)

-- =============================================================================
-- STEP 3: PRELIMINARY OUTPUT (WITHOUT CRA REPORTING STATUS)
-- =============================================================================

SELECT
    LOANID as "Loan Number",
    BORROWER_NAME as "Borrower Name",
    FIRST_LATE_DATE as "Date of First Late Payment",
    DAYS_PAST_DUE_AT_FIRST_LATE as "Days Past Due at First Late",
    'TBD - Need CRA Reporting Table' as "Reported to CRA",
    -- Additional context fields
    PORTFOLIOID,
    PORTFOLIONAME,
    STATUS_AT_FIRST_LATE
FROM loan_with_pii
ORDER BY FIRST_LATE_DATE, LOANID;

-- =============================================================================
-- VALIDATION QUERIES
-- =============================================================================

-- Count of loans with first late payment in scope
WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
        AND DAYSPASTDUE > 0
        AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'
    GROUP BY LOANID
)
SELECT COUNT(DISTINCT LOANID) as TOTAL_LOANS_WITH_FIRST_LATE
FROM first_delinquency;

-- Distribution by portfolio
WITH first_delinquency AS (
    SELECT
        LOANID,
        PORTFOLIOID,
        PORTFOLIONAME,
        MIN(ASOFDATE) as FIRST_LATE_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
        AND DAYSPASTDUE > 0
        AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'
    GROUP BY LOANID, PORTFOLIOID, PORTFOLIONAME
)
SELECT
    PORTFOLIOID,
    PORTFOLIONAME,
    COUNT(DISTINCT LOANID) as LOAN_COUNT,
    MIN(FIRST_LATE_DATE) as EARLIEST_FIRST_LATE,
    MAX(FIRST_LATE_DATE) as LATEST_FIRST_LATE
FROM first_delinquency
GROUP BY PORTFOLIOID, PORTFOLIONAME
ORDER BY PORTFOLIOID;

-- Distribution by days past due at first late
WITH first_delinquency AS (
    SELECT
        LOANID,
        MIN(ASOFDATE) as FIRST_LATE_DATE,
        MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
        AND DAYSPASTDUE > 0
        AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'
    GROUP BY LOANID
)
SELECT
    DAYS_PAST_DUE,
    COUNT(DISTINCT LOANID) as LOAN_COUNT
FROM first_delinquency
GROUP BY DAYS_PAST_DUE
ORDER BY DAYS_PAST_DUE;

-- =============================================================================
-- NOTES & ASSUMPTIONS
-- =============================================================================
--
-- 1. "First Late Payment" = First date DAYSPASTDUE > 0 in the date range
-- 2. Using MIN_BY to get the DAYSPASTDUE value at that first late date
-- 3. CRB Filter: PORTFOLIOID IN ('32', '34', '54', '56')
-- 4. Need to find credit bureau reporting table for "Reported to CRA" field
-- 5. Assumption: DAYSPASTDUE represents number of days payment is overdue
--
-- QUESTIONS TO ANSWER:
-- - Where is credit bureau reporting/submission tracked?
-- - What constitutes "reported to CRA"? (submission file, reporting date, etc.)
-- - Are there different reporting thresholds (30/60/90 days)?
--
