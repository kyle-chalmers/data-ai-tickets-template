-- =============================================================================
-- DI-1302: Mississippi State Regulatory Exam Request
-- =============================================================================
-- Purpose: Extract comprehensive loan data for Mississippi regulatory exam
--
-- Business Requirements:
-- Provide complete list of loans where applicant lived in Mississippi and
-- originated between October 1, 2023 – September 30, 2025
--
-- Required Fields:
-- - LOANID, FIRST_NAME, LAST_NAME
-- - ADDRESS_1, ADDRESS_2, CITY, STATE, ZIP_CODE
-- - ORIGINATIONDATE, STATUS, LASTPAYMENTDATE
-- - ORIGINATIONFEE, LOANAMOUNT, TERM, INTERESTRATE
--
-- Data Source: MVW_LOAN_TAPE (authoritative historical loan data)
-- Output: Single Excel spreadsheet with all required fields
-- =============================================================================

-- =============================================================================
-- PARAMETERS
-- =============================================================================
SET START_DATE = '2023-10-01';        -- October 1, 2023
SET END_DATE = '2025-09-30';          -- September 30, 2025
SET STATE_FILTER = 'MS';              -- Mississippi state filter

-- =============================================================================
-- MAIN QUERY: Mississippi Loans with Complete Borrower Information
-- =============================================================================
-- Purpose: Extract all MS loans with borrower PII for regulatory submission
-- Business Context: State regulatory exam requires comprehensive loan details
-- Filter Logic:
--   - Native MS residents (APPLICANTRESIDENCESTATE = 'MS')
--   - Origination date between Oct 1, 2023 and Sep 30, 2025
--   - Include all required regulatory fields
-- Join Strategy: Loan Tape → VW_LOAN → Member PII for borrower information
-- Expected Result: 181 Mississippi loans
-- =============================================================================

SELECT
    -- Loan Identification
    A.LOANID,

    -- Borrower Name Information
    B.FIRST_NAME,
    B.LAST_NAME,

    -- Borrower Address Information
    B.ADDRESS_1,
    B.ADDRESS_2,
    B.CITY,
    B.STATE,
    B.ZIP_CODE,

    -- Loan Details
    A.ORIGINATIONDATE,
    A.STATUS,
    A.LASTPAYMENTDATE,
    A.ORIGINATIONFEE,
    A.LOANAMOUNT,
    A.TERM,
    A.INTERESTRATE

FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE A

-- Join to VW_LOAN to link loan tape PAYOFFUID to MEMBER_ID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN C
    ON A.PAYOFFUID = C.LEAD_GUID

-- Join to Member PII for borrower name and address at origination
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII B
    ON B.MEMBER_ID = C.MEMBER_ID
    AND B.MEMBER_PII_END_DATE IS NULL  -- Active PII record

WHERE
    -- Filter for Mississippi native residents
    UPPER(A.APPLICANTRESIDENCESTATE) = $STATE_FILTER

    -- Filter for date range: Oct 1, 2023 - Sep 30, 2025
    AND A.ORIGINATIONDATE BETWEEN $START_DATE AND $END_DATE

ORDER BY
    A.ORIGINATIONDATE ASC,
    A.LOANID ASC;

-- =============================================================================
-- EXECUTION NOTES:
-- =============================================================================
-- 1. Run query and export results as CSV with --format csv
-- 2. Convert CSV to Excel format for regulatory submission
-- 3. MVW_LOAN_TAPE is unique by LOANID (no deduplication needed)
-- 4. Interest rates in decimal format (0.1560 = 15.60%)
-- 5. Status field provides human-readable loan status
-- 6. MEMBER_PII_END_DATE IS NULL ensures current/active PII records
-- 7. Some loans may have NULL PII if borrower data not available
-- 8. System column names used (no descriptive aliases)
-- =============================================================================
