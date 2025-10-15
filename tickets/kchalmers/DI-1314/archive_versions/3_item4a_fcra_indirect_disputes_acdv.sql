-- DI-1314: Item 4.A - FCRA Indirect Credit Disputes (ACDV)
-- CRB Q3 2025 Compliance Testing
-- Scope: October 1, 2024 - August 31, 2025
--
-- Required Fields:
-- - Loan Number
-- - Borrower Name
-- - Receipt Date of Dispute
-- - Source of Dispute
-- - Resolution Date of Dispute
-- - ACDV Control# (Automated Consumer Dispute Verification)
--
-- Data Sources:
-- - BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV (ACDV disputes from credit bureaus)
-- - BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE (CRB portfolio filter)
--
-- Business Logic:
-- - "Indirect disputes" = disputes received from credit bureaus (via ACDV process)
-- - ORIGINATOR field identifies source bureau (EFX, EXP, TUN, INN)
-- - DATERECEIVED and DATERESPONDED are stored as VARCHAR - need TO_DATE conversion
-- - Filter to CRB portfolios only using ACCOUNTNUMBER → LOANID join
--
-- Date: 2025-10-14
-- Author: Kyle Chalmers

-- ============================================================================
-- PARAMETERS
-- ============================================================================

-- Date range for FCRA disputes
SET START_DATE = '2024-10-01';
SET END_DATE = '2025-08-31';

-- ============================================================================
-- MAIN QUERY
-- ============================================================================

WITH crb_loans AS (
    -- Get all CRB loans for portfolio filtering
    SELECT DISTINCT
        mlt.LOANID,
        mlt.PORTFOLIOID,
        mlt.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE mlt
    WHERE mlt.PORTFOLIOID IN ('32', '34', '54', '56')
),

acdv_disputes AS (
    -- Get ACDV disputes in scope period with date conversions
    SELECT
        ACCOUNTNUMBER as LOAN_NUMBER,
        CONSUMERFIRSTNAME,
        MIDDLENAME,
        LASTNAME,

        -- Convert VARCHAR dates to proper DATE type
        TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD') as RECEIPT_DATE,
        TRY_TO_DATE(DATERESPONDED, 'YYYY-MM-DD') as RESOLUTION_DATE,
        TRY_TO_DATE(RESPONSEDUEDATE, 'YYYY-MM-DD') as RESPONSE_DUE_DATE,

        ORIGINATOR as SOURCE_BUREAU_CODE,
        ACDVCONTROLNUMBER as ACDV_CONTROL_NUMBER,
        DISPUTECODE,
        RESPONSECODE,
        DATAFURNISHER,
        QUEUENAME,
        USERID

    FROM BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV
    WHERE TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD') BETWEEN $START_DATE AND $END_DATE
      AND ACCOUNTNUMBER IS NOT NULL
      AND TRIM(ACCOUNTNUMBER) != ''
)

-- Final output: ACDV disputes for CRB loans in scope period
SELECT
    ad.LOAN_NUMBER,

    -- Construct borrower name (handle NULL middle name)
    CASE
        WHEN ad.MIDDLENAME IS NOT NULL AND TRIM(ad.MIDDLENAME) != ''
        THEN ad.CONSUMERFIRSTNAME || ' ' || ad.MIDDLENAME || ' ' || ad.LASTNAME
        ELSE ad.CONSUMERFIRSTNAME || ' ' || ad.LASTNAME
    END as BORROWER_NAME,

    ad.RECEIPT_DATE as RECEIPT_DATE_OF_DISPUTE,

    -- Map bureau codes to full names
    CASE ad.SOURCE_BUREAU_CODE
        WHEN 'EFX' THEN 'Equifax'
        WHEN 'EXP' THEN 'Experian'
        WHEN 'TUN' THEN 'TransUnion'
        WHEN 'INN' THEN 'Innovis'
        ELSE ad.SOURCE_BUREAU_CODE
    END as SOURCE_OF_DISPUTE,

    ad.RESOLUTION_DATE as RESOLUTION_DATE_OF_DISPUTE,
    ad.ACDV_CONTROL_NUMBER,

    -- Additional context fields
    ad.RESPONSE_DUE_DATE,
    ad.DISPUTECODE,
    ad.RESPONSECODE,
    ad.DATAFURNISHER,
    cl.PORTFOLIOID,
    cl.PORTFOLIONAME

FROM acdv_disputes ad
INNER JOIN crb_loans cl
    ON ad.LOAN_NUMBER = cl.LOANID
ORDER BY ad.RECEIPT_DATE DESC, ad.LOAN_NUMBER;

-- ============================================================================
-- QUALITY CONTROL NOTES
-- ============================================================================
--
-- Data Quality Considerations:
-- 1. Dates are stored as VARCHAR in RPT_EOSCAR_ACDV - using TRY_TO_DATE for safe conversion
-- 2. ACCOUNTNUMBER in ACDV table matches LOANID in MVW_LOAN_TAPE
-- 3. ORIGINATOR field contains bureau abbreviations (EFX, EXP, TUN, INN)
-- 4. Some disputes may not have DATERESPONDED (resolution pending) → NULL values expected
-- 5. Middle name handling: Some borrowers have NULL or empty middle names
-- 6. DISPUTECODE and RESPONSECODE are numeric codes (bureau-specific meanings)
--
-- ACDV Process Context:
-- - ACDV = Automated Consumer Dispute Verification
-- - Used by credit bureaus to communicate disputes to data furnishers
-- - "Indirect" because dispute comes from bureau (consumer → bureau → Happy Money)
-- - ACDV Control Number is bureau-assigned unique identifier
--
-- Expected Result Validation:
-- - All records should have PORTFOLIOID IN ('32', '34', '54', '56')
-- - RECEIPT_DATE should be between 2024-10-01 and 2025-08-31
-- - SOURCE_OF_DISPUTE should be Equifax, Experian, TransUnion, or Innovis
-- - ACDV_CONTROL_NUMBER should be unique per dispute
-- - Some RESOLUTION_DATE values may be NULL (disputes still open)
--
-- ============================================================================
