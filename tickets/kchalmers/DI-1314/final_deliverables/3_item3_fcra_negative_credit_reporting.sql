-- DI-1314: Item 3 - FCRA Negative Credit Reporting (First 30-Day Delinquency)
-- CRB Q3 2025 Compliance Testing
-- Scope: October 1, 2024 - August 31, 2025
--
-- Required Fields:
-- - Loan Number
-- - Borrower Name
-- - Date of first late payment
-- - How many days past due borrower became
--
-- Data Sources:
-- - BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY (daily loan snapshots)
-- - BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII (borrower names)
-- - BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN (loan-member linkage)
--
-- Business Logic:
-- - "First late payment" = first date EVER that loan reached DAYSPASTDUE >= 30
-- - CRITICAL: Must verify this first-ever 30+ DPD date falls within scope period
-- - Loans that reached 30+ DPD before Oct 1, 2024 are EXCLUDED (not first during scope)
-- - Use ASOFDATE from daily history to identify exact date loan became 30+ days delinquent
--
-- Date: 2025-10-16
-- Author: Kyle Chalmers
-- Modified: Changed delinquency threshold from DAYSPASTDUE > 0 to DAYSPASTDUE >= 30
-- Modified: Added logic to ensure first-ever 30+ DPD date is within scope (not just first within scope)

-- ============================================================================
-- PARAMETERS
-- ============================================================================

-- Date range for FCRA negative reporting
SET START_DATE = '2024-10-01';
SET END_DATE = '2025-08-31';
use warehouse BUSINESS_INTELLIGENCE_LARGE;

-- ============================================================================
-- MAIN QUERY
-- ============================================================================

WITH first_ever_delinquency AS (
    -- Find the first date EVER each CRB loan became 30+ days delinquent (no date restriction)
    -- This ensures we identify true "first time" 30+ DPD, not just first within scope
    SELECT
        LOANID,
        PAYOFFUID,
        MIN(ASOFDATE) as FIRST_EVER_LATE_DATE,
        MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE,
        MIN_BY(LASTPAYMENTDATE, ASOFDATE) as LAST_PAYMENT_DATE_AT_FIRST_LATE,
        PORTFOLIOID,
        PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE >= 30  -- Only include dates when loan was 30+ days delinquent
    GROUP BY LOANID, PAYOFFUID, PORTFOLIOID, PORTFOLIONAME
),

first_delinquency AS (
    -- Filter to only loans where first-ever 30+ DPD date falls within scope period
    SELECT *
    FROM first_ever_delinquency
    WHERE FIRST_EVER_LATE_DATE BETWEEN $START_DATE AND $END_DATE
),

borrower_names AS (
    -- Get borrower names for CRB loans
    SELECT
        vl.LEAD_GUID,
        vl.MEMBER_ID,
        pii.FIRST_NAME,
        pii.LAST_NAME,
        pii.FIRST_NAME || ' ' || pii.LAST_NAME as BORROWER_NAME
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII pii
        ON vl.MEMBER_ID = pii.MEMBER_ID
        AND pii.MEMBER_PII_END_DATE IS NULL  -- Current PII only
)

-- Final output: First 30-day delinquencies for CRB loans in scope period
SELECT
    fd.LOANID as LOAN_NUMBER,
    bn.BORROWER_NAME,
    fd.FIRST_EVER_LATE_DATE as DATE_OF_FIRST_DELINQUENCY_FOLLOWING_FAILURE_TO_PAY,
    fd.DAYS_PAST_DUE_AT_FIRST_LATE as DAYS_PAST_DUE,
    fd.PORTFOLIOID,
    fd.PORTFOLIONAME

FROM first_delinquency fd
LEFT JOIN borrower_names bn
    ON fd.PAYOFFUID = bn.LEAD_GUID
ORDER BY fd.FIRST_EVER_LATE_DATE DESC, fd.LOANID;

-- ============================================================================
-- QUALITY CONTROL NOTES
-- ============================================================================
--
-- Data Quality Considerations:
-- 1. Using MVW_LOAN_TAPE_DAILY_HISTORY ensures accurate "first late date" tracking
-- 2. DAYSPASTDUE >= 30 is the definition of "30-day delinquency" (serious delinquency)
-- 3. MIN(ASOFDATE) with no date filter finds the first-EVER date a loan became 30+ days late
-- 4. Then filters to only loans where this first-ever date falls within scope period
-- 5. MIN_BY aggregates capture the DAYSPASTDUE value on that specific first date
-- 6. A loan could become current and late again - this captures only the FIRST EVER 30+ day delinquency
-- 7. Excludes loans that had already been 30+ DPD before October 1, 2024
--
-- Expected Result Validation:
-- - All records should have PORTFOLIOID IN ('32', '34', '54', '56')
-- - FIRST_EVER_LATE_DATE should be between 2024-10-01 and 2025-08-31
-- - DAYSPASTDUE should be >= 30
-- - Each LOANID should appear only once (first-ever 30-day delinquency only)
-- - NO loans should have been 30+ DPD before the scope period start date
--
-- ============================================================================
