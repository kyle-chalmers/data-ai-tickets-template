-- DI-1314: Item 3 - FCRA Negative Credit Reporting (First Late Payments)
-- CRB Q3 2025 Compliance Testing
-- Scope: October 1, 2024 - August 31, 2025
--
-- Required Fields:
-- - Loan Number
-- - Borrower Name
-- - Date of first late payment
-- - How many days past due borrower became
-- - If borrower was reported late to CRA
--
-- Data Sources:
-- - BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY (daily loan snapshots)
-- - BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII (borrower names)
-- - BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN (loan-member linkage)
-- - RAW_DATA_STORE.LOANPRO.CREDIT_REPORT_HISTORY (credit bureau export tracking)
--
-- Business Logic:
-- - "First late payment" = first date DAYSPASTDUE > 0 within scope period
-- - Use ASOFDATE from daily history to identify exact date loan became late
-- - "Reported to CRA" = inferred from credit bureau export timing
--   If first late date < next bureau export date → "Yes", else "No" or "Pending"
--
-- Date: 2025-10-14
-- Author: Kyle Chalmers

-- ============================================================================
-- PARAMETERS
-- ============================================================================

-- Date range for FCRA negative reporting
SET START_DATE = '2024-10-01';
SET END_DATE = '2025-08-31';

-- ============================================================================
-- MAIN QUERY
-- ============================================================================

WITH first_delinquency AS (
    -- Find first date each CRB loan went late (DAYSPASTDUE > 0) in scope period
    SELECT
        LOANID,
        PAYOFFUID,
        MIN(ASOFDATE) as FIRST_LATE_DATE,
        MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE,
        MIN_BY(LASTPAYMENTDATE, ASOFDATE) as LAST_PAYMENT_DATE_AT_FIRST_LATE,
        PORTFOLIOID,
        PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
      AND DAYSPASTDUE > 0  -- Only include dates when loan was delinquent
      AND ASOFDATE BETWEEN $START_DATE AND $END_DATE
    GROUP BY LOANID, PAYOFFUID, PORTFOLIOID, PORTFOLIONAME
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
),

credit_bureau_exports AS (
    -- Get credit bureau export dates to infer reporting status
    -- Using TIME_COMPLETED as the date data was furnished to bureaus
    SELECT
        DATE(TIME_COMPLETED) as EXPORT_DATE,
        FILE_NAME,
        ENTITY_TYPE
    FROM RAW_DATA_STORE.LOANPRO.CREDIT_REPORT_HISTORY
    WHERE ENTITY_TYPE = 'Entity.Loan'
      AND TIME_COMPLETED IS NOT NULL
    ORDER BY TIME_COMPLETED
),

next_export_after_late AS (
    -- For each first late date, find the next credit bureau export
    SELECT
        fd.LOANID,
        fd.FIRST_LATE_DATE,
        MIN(cbe.EXPORT_DATE) as NEXT_EXPORT_DATE,
        MIN_BY(cbe.FILE_NAME, cbe.EXPORT_DATE) as EXPORT_FILE_NAME
    FROM first_delinquency fd
    LEFT JOIN credit_bureau_exports cbe
        ON cbe.EXPORT_DATE >= fd.FIRST_LATE_DATE
    GROUP BY fd.LOANID, fd.FIRST_LATE_DATE
)

-- Final output: First late payments for CRB loans in scope period
SELECT
    fd.LOANID as LOAN_NUMBER,
    bn.BORROWER_NAME,
    fd.FIRST_LATE_DATE as DATE_OF_FIRST_LATE_PAYMENT,
    fd.DAYS_PAST_DUE_AT_FIRST_LATE as DAYS_PAST_DUE,
    fd.LAST_PAYMENT_DATE_AT_FIRST_LATE as LAST_PAYMENT_DATE_WHEN_LATE,

    -- Reported to CRA logic:
    -- If a credit bureau export occurred after the first late date → "Yes"
    -- If no export found or export is in the future → "Pending" or "No"
    CASE
        WHEN nea.NEXT_EXPORT_DATE IS NOT NULL
         AND nea.NEXT_EXPORT_DATE <= CURRENT_DATE()
        THEN 'Yes'
        WHEN nea.NEXT_EXPORT_DATE IS NOT NULL
         AND nea.NEXT_EXPORT_DATE > CURRENT_DATE()
        THEN 'Pending'
        ELSE 'No'
    END as REPORTED_LATE_TO_CRA,

    nea.NEXT_EXPORT_DATE as NEXT_BUREAU_EXPORT_DATE,
    nea.EXPORT_FILE_NAME as BUREAU_EXPORT_FILE,
    fd.PORTFOLIOID,
    fd.PORTFOLIONAME

FROM first_delinquency fd
LEFT JOIN borrower_names bn
    ON fd.PAYOFFUID = bn.LEAD_GUID
LEFT JOIN next_export_after_late nea
    ON fd.LOANID = nea.LOANID
    AND fd.FIRST_LATE_DATE = nea.FIRST_LATE_DATE
ORDER BY fd.FIRST_LATE_DATE DESC, fd.LOANID;

-- ============================================================================
-- QUALITY CONTROL NOTES
-- ============================================================================
--
-- Data Quality Considerations:
-- 1. Using MVW_LOAN_TAPE_DAILY_HISTORY ensures accurate "first late date" tracking
-- 2. DAYSPASTDUE > 0 is the definition of "late payment"
-- 3. MIN(ASOFDATE) finds the earliest date a loan became late in scope period
-- 4. MIN_BY aggregates capture the DAYSPASTDUE and LASTPAYMENTDATE values on that first late date
-- 5. A loan could become current and late again - this captures only the FIRST late date
-- 6. LASTPAYMENTDATE provides additional context for validation
--
-- Credit Bureau Reporting Logic:
-- - CREDIT_REPORT_HISTORY contains Metro2 export file metadata
-- - TIME_COMPLETED indicates when data was furnished to bureaus
-- - If first late date < next export date → loan status was likely reported
-- - This is an inference based on export timing, not a direct loan-level flag
-- - "Pending" indicates export is scheduled but not yet completed
-- - "No" indicates no export found after the late date
--
-- Expected Result Validation:
-- - All records should have PORTFOLIOID IN ('32', '34', '54', '56')
-- - FIRST_LATE_DATE should be between 2024-10-01 and 2025-08-31
-- - DAYSPASTDUE should be > 0
-- - Each LOANID should appear only once (first late payment only)
--
-- ============================================================================
