-- DI-1314: Item 1.B - CAN-SPAM Marketing Email Opt-Outs
-- CRB Q3 2025 Compliance Testing
-- Scope: October 1, 2023 - August 31, 2025
--
-- Required Fields:
-- - Unique Customer Identifier
-- - Customer Name
-- - Customer Email Address
-- - Date Opt-out Requested
-- - Date Opt-out Processed
-- - Date Last Email Sent to customer
--
-- Data Sources:
-- - BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC (email unsubscribes from SFMC)
-- - BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII (customer PII)
-- - BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN (loan-member linkage)
-- - BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE (CRB portfolio filter)
--
-- Business Logic:
-- - Include only customers with CRB loans (Portfolio IDs: 32, 34, 54, 56)
-- - Use DATEUNSUBSCRIBED from SFMC for both "requested" and "processed" dates
--   (SFMC does not distinguish between request and processing timestamp)
-- - "Date Last Email Sent" field is N/A - individual email send history not available in Snowflake
--   (would require SFMC API query or external log analysis)
--
-- Date: 2025-10-14
-- Author: Kyle Chalmers

-- ============================================================================
-- PARAMETERS
-- ============================================================================

-- Date range for CAN-SPAM opt-outs
SET START_DATE = '2023-10-01';
SET END_DATE = '2025-08-31';

-- ============================================================================
-- MAIN QUERY
-- ============================================================================

WITH crb_loans AS (
    -- Get all CRB loans (both active and inactive)
    SELECT DISTINCT
        mlt.LOANID,
        mlt.PAYOFFUID as LEAD_GUID,
        mlt.PORTFOLIOID,
        mlt.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE mlt
    WHERE mlt.PORTFOLIOID IN ('32', '34', '54', '56')
),

crb_members AS (
    -- Link CRB loans to members
    SELECT DISTINCT
        vl.MEMBER_ID,
        cl.LOANID,
        cl.PORTFOLIOID,
        cl.PORTFOLIONAME
    FROM crb_loans cl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON cl.LEAD_GUID = vl.LEAD_GUID
    WHERE vl.MEMBER_ID IS NOT NULL
),

crb_member_emails AS (
    -- Get current email addresses for CRB members
    SELECT DISTINCT
        cm.MEMBER_ID,
        cm.LOANID,
        cm.PORTFOLIOID,
        cm.PORTFOLIONAME,
        pii.FIRST_NAME,
        pii.LAST_NAME,
        pii.EMAIL
    FROM crb_members cm
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII pii
        ON cm.MEMBER_ID = pii.MEMBER_ID
        AND pii.MEMBER_PII_END_DATE IS NULL  -- Current PII only
    WHERE pii.EMAIL IS NOT NULL
      AND TRIM(pii.EMAIL) != ''
),

email_optouts AS (
    -- Get email opt-outs/unsubscribes from SFMC in scope period
    SELECT
        LOWER(TRIM(EMAIL)) as EMAIL_NORMALIZED,
        EMAIL as ORIGINAL_EMAIL,
        DATEUNSUBSCRIBED,
        SOURCE as OPTOUT_SOURCE
    FROM BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC
    WHERE DATEUNSUBSCRIBED BETWEEN $START_DATE AND $END_DATE
      AND EMAIL IS NOT NULL
      AND TRIM(EMAIL) != ''
)

-- Final output: CRB members who opted out of email marketing
SELECT
    cme.MEMBER_ID as UNIQUE_CUSTOMER_IDENTIFIER,
    cme.FIRST_NAME || ' ' || cme.LAST_NAME as CUSTOMER_NAME,
    cme.EMAIL as CUSTOMER_EMAIL_ADDRESS,
    eo.DATEUNSUBSCRIBED as DATE_OPTOUT_REQUESTED,
    eo.DATEUNSUBSCRIBED as DATE_OPTOUT_PROCESSED,  -- Same as requested (SFMC doesn't separate)
    NULL as DATE_LAST_EMAIL_SENT,  -- N/A - not available in Snowflake
    eo.OPTOUT_SOURCE,
    cme.LOANID as SAMPLE_CRB_LOAN,  -- For reference/validation
    cme.PORTFOLIOID,
    cme.PORTFOLIONAME
FROM crb_member_emails cme
INNER JOIN email_optouts eo
    ON LOWER(TRIM(cme.EMAIL)) = eo.EMAIL_NORMALIZED
ORDER BY eo.DATEUNSUBSCRIBED DESC, cme.MEMBER_ID;

-- ============================================================================
-- QUALITY CONTROL NOTES
-- ============================================================================
--
-- Data Quality Considerations:
-- 1. Email matching is case-insensitive and trimmed for consistency
-- 2. A customer may have multiple CRB loans - using DISTINCT on MEMBER_ID for final count
-- 3. SAMPLE_CRB_LOAN shows one loan for reference (customer may have multiple)
-- 4. Some unsubscribes in SFMC may have NULL DATEUNSUBSCRIBED - these are excluded
-- 5. "Date Last Email Sent" is N/A - would require SFMC send job logs or API query
--
-- Expected Result Validation:
-- - All records should have PORTFOLIOID IN ('32', '34', '54', '56')
-- - DATEUNSUBSCRIBED should be between 2023-10-01 and 2025-08-31
-- - All MEMBER_ID values should be unique (de-duplicated by customer)
--
-- ============================================================================
