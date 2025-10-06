/*
================================================================================
DI-1254: BK Sale Evaluation for Resurgent - Loan Level File
================================================================================

BUSINESS CONTEXT:
Generate standard debt sale loan-level file for charged-off bankruptcy (BK) loans
being evaluated for sale to Resurgent. Excludes loans already placed with other
debt buyers and those with active/completed settlements.

EXCLUSION CRITERIA:
- Fully recovered loans (recoveries >= principal at chargeoff)
- Fraud loans (placeholder logic until DI-1312 deploys)
- Active or completed debt settlements
- Existing placements: Resurgent, Bounce, Jefferson Capital, FTFCU
- Settlement-successful portfolios/sub-statuses

DATA AS OF: Most recent monthly loan tape

FRAUD DETECTION NOTE:
This query uses inline fraud detection as a placeholder. Once DI-1312 is deployed,
replace the cte_fraud_placeholder with a simple LEFT JOIN to VW_LOAN_FRAUD.
See README.md for migration instructions.

================================================================================
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Variables
SET end_chargeoffdate = CURRENT_DATE(); -- Data as of pull date

-- Create output table
CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025 AS

-- ============================================================================
-- PLACEHOLDER: Fraud Detection Logic
-- TODO DI-1312: Replace this CTE with VW_LOAN_FRAUD once deployed
-- ============================================================================
WITH cte_fraud_placeholder AS (
    /*
    FUTURE REPLACEMENT (once DI-1312 deployed):

    SELECT
        LOAN_ID,
        LEAD_GUID,
        IS_FRAUD,
        FRAUD_PORTFOLIOS,
        DATA_SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
    */

    -- CURRENT IMPLEMENTATION: Conservative inline fraud detection
    SELECT
        vl.LOAN_ID,
        vl.LEAD_GUID,
        CASE
            -- Portfolio-based fraud detection
            WHEN MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN 1 ELSE 0 END) = 1 THEN TRUE
            -- Sub-status fraud detection
            WHEN MAX(CASE WHEN vl.LOAN_SUB_STATUS_TEXT LIKE '%Fraud%' THEN 1 ELSE 0 END) = 1 THEN TRUE
            -- CLS confirmed fraud tags (for legacy loans)
            WHEN MAX(CASE WHEN at.APPLICATION_TAG = 'Confirmed Fraud' THEN 1 ELSE 0 END) = 1 THEN TRUE
            ELSE FALSE
        END AS IS_FRAUD,
        'INLINE_PLACEHOLDER' AS DATA_SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl

    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
        ON vl.LOAN_ID::TEXT = lpsp.LOAN_ID::TEXT
        AND lpsp.PORTFOLIO_CATEGORY = 'Fraud'

    LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION va
        ON LOWER(vl.LEAD_GUID) = LOWER(va.PAYOFF_UID)

    LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_TAGS at
        ON va.HK_H_APPL = at.HK_H_APPL
        AND at.APPLICATION_TAG = 'Confirmed Fraud'
        AND at.SOFTDELETE = 'False'

    GROUP BY vl.LOAN_ID, vl.LEAD_GUID
),

-- ============================================================================
-- SCRA and Deceased Detection
-- ============================================================================
cte_scra_deceased AS (
    SELECT
        vl.LOAN_ID,
        vl.LEAD_GUID,
        -- SCRA detection
        CASE
            WHEN MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'SCRA' THEN 1 ELSE 0 END) = 1 THEN 'Y'
            WHEN MAX(CASE WHEN vln.NOTE_BODY LIKE '%SCRA%' OR vln.NOTE_TITLE LIKE '%SCRA%' THEN 1 ELSE 0 END) = 1 THEN 'Y'
            ELSE 'N'
        END AS SCRAFLAG,
        -- Deceased detection
        CASE
            WHEN MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Deceased' THEN 1 ELSE 0 END) = 1 THEN TRUE
            WHEN MAX(CASE WHEN brsc.NOSCOREREASON = 'subjectDeceased' THEN 1 ELSE 0 END) = 1 THEN TRUE
            ELSE FALSE
        END AS IS_DECEASED
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl

    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
        ON vl.LOAN_ID::TEXT = lpsp.LOAN_ID::TEXT
        AND lpsp.PORTFOLIO_CATEGORY IN ('SCRA', 'Deceased')

    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_NOTES vln
        ON vl.LOAN_ID::TEXT = vln.LOAN_ID::TEXT
        AND (UPPER(vln.NOTE_BODY) LIKE '%SCRA%' OR UPPER(vln.NOTE_TITLE) LIKE '%SCRA%')

    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_BUREAU_RESPONSES_SCORE_CURRENT brsc
        ON LOWER(vl.LEAD_GUID) = LOWER(brsc.PAYOFF_UID)
        AND brsc.NOSCOREREASON = 'subjectDeceased'

    GROUP BY vl.LOAN_ID, vl.LEAD_GUID
),

-- ============================================================================
-- Payment Transaction Metrics
-- ============================================================================
cte_payment_history AS (
    SELECT
        vl.LEAD_GUID,
        SUM(CASE
            WHEN pt.IS_SETTLED = TRUE
                AND pt.IS_REVERSED <> TRUE
                AND pt.IS_REJECTED <> TRUE
            THEN pt.TRANSACTION_AMOUNT
            ELSE 0
        END) AS TOTALPAYMENTTRANSACTIONSAMOUNT,
        SUM(CASE
            WHEN pt.IS_SETTLED = TRUE
                AND pt.IS_REVERSED <> TRUE
                AND pt.IS_REJECTED <> TRUE
            THEN 1
            ELSE 0
        END) AS NUMBEROFPAYMENTTRANSACTIONS,
        SUM(CASE
            WHEN pt.IS_REVERSED = TRUE OR pt.IS_REJECTED = TRUE
            THEN 1
            ELSE 0
        END) AS NUMBEROFPAYMENTSREVERSEDORREJECTED,
        MAX(CASE
            WHEN pt.IS_SETTLED = TRUE
                AND pt.IS_REVERSED <> TRUE
                AND pt.IS_REJECTED <> TRUE
            THEN pt.TRANSACTION_DATE
        END) AS LASTPAYMENTDATE,
        MAX(CASE
            WHEN pt.IS_SETTLED = TRUE
                AND pt.IS_REVERSED <> TRUE
                AND pt.IS_REJECTED <> TRUE
            THEN pt.TRANSACTION_AMOUNT
        END) AS LASTPAYMENTAMOUNT
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION pt
        ON vl.LOAN_ID::TEXT = pt.LOAN_ID::TEXT
    GROUP BY vl.LEAD_GUID
),

-- ============================================================================
-- Delinquency Dates
-- ============================================================================
cte_delinquency_dates AS (
    SELECT
        PAYOFFUID,
        MIN(ASOFDATE) AS DATEOFFIRSTDELINQUENCY
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE DAYSPASTDUE >= 30
    GROUP BY PAYOFFUID
),

cte_most_recent_30dpd AS (
    SELECT
        PAYOFFUID,
        MAX(ASOFDATE) AS MOST_RECENT_DELINQUENCY_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE DAYSPASTDUE = 30
    GROUP BY PAYOFFUID
),

-- ============================================================================
-- Settlement Exclusions
-- ============================================================================
cte_settlement_exclusions AS (
    SELECT
        LOAN_ID,
        SETTLEMENTSTATUS,
        SETTLEMENT_ACCEPTED_DATE,
        SETTLEMENT_COMPLETION_DATE,
        SETTLEMENT_AMOUNT
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
    WHERE SETTLEMENTSTATUS IN ('Active', 'Complete')
        OR CURRENT_STATUS IN ('Active', 'Complete')
        OR HAS_SETTLEMENT_PORTFOLIO = TRUE
),

-- ============================================================================
-- Bankruptcy Data with POC Details
-- ============================================================================
cte_bankruptcy_data AS (
    SELECT
        lb.LOAN_ID,
        lb.CASE_NUMBER,
        lb.BANKRUPTCY_CHAPTER,
        lb.PETITION_STATUS AS BANKRUPTCY_STATUS,
        lb.FILING_DATE AS FILE_DATE,
        lb.PROOF_OF_CLAIM_DEADLINE_DATE AS POC_DEADLINE_DATE,
        lb.PROOF_OF_CLAIM_FILED_DATE AS POC_COMPLETED_DATE,
        lb.PROOF_OF_CLAIM_FILED_STATUS AS POC_REQUIRED,
        lb.DISMISSED_DATE AS DISCHARGE_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY lb
    WHERE lb.MOST_RECENT_BANKRUPTCY = 'Y'
),

-- ============================================================================
-- Main Query
-- ============================================================================
cte_final AS (
SELECT
    -- PII Fields
    m_pii.FIRST_NAME AS FIRSTNAME,
    m_pii.LAST_NAME AS LASTNAME,
    m_pii.SSN,
    m_pii.ADDRESS_1 AS STREETADDRESS1,
    m_pii.ADDRESS_2 AS STREETADDRESS2,
    m_pii.CITY,
    m_pii.STATE,
    m_pii.ZIP_CODE AS ZIPCODE,
    m_pii.DATE_OF_BIRTH,
    m_pii.EMAIL,
    m_pii.PHONE_NUMBER AS PHONENUMBER,

    -- Loan Identifiers
    ltm.LOANID,
    vl.LEGACY_LOAN_ID,
    LOWER(vl.LEAD_GUID) AS LEAD_GUID,
    vl.LOAN_ID AS LP_LOAN_ID,

    -- Portfolio and Status
    ltm.PORTFOLIONAME,
    ltm.STATUS,
    vl.LOAN_SUB_STATUS_TEXT,

    -- Financial Details
    (ltm.PRINCIPALBALANCEATCHARGEOFF + ltm.INTERESTBALANCEATCHARGEOFF
        - ltm.RECOVERIESPAIDTODATE - ZEROIFNULL(ltm.TOTALPRINCIPALWAIVED)) AS UNPAIDBALANCEDUE,
    ltm.CHARGEOFFDATE,
    ltm.PRINCIPALBALANCEATCHARGEOFF,
    ltm.INTERESTBALANCEATCHARGEOFF,
    ltm.RECOVERIESPAIDTODATE,
    ltm.PRINCIPALPAIDTODATE,
    ltm.INTERESTPAIDTODATE,
    COALESCE(ph.LASTPAYMENTDATE, ltm.LASTPAYMENTDATE) AS LASTPAYMENTDATE,
    COALESCE(ph.LASTPAYMENTAMOUNT, ltm.LASTPAYMENTAMOUNT) AS LASTPAYMENTAMOUNT,

    -- Delinquency Dates
    COALESCE(dd.DATEOFFIRSTDELINQUENCY, DATEADD(DAY, -90, ltm.CHARGEOFFDATE)) AS DATEOFFIRSTDELINQUENCY,
    COALESCE(mrd.MOST_RECENT_DELINQUENCY_DATE, DATEADD(DAY, -90, ltm.CHARGEOFFDATE)) AS DATEOFRECENTDELINQUENCY,

    -- Bankruptcy Information
    bd.BANKRUPTCY_STATUS,
    bd.CASE_NUMBER,
    bd.BANKRUPTCY_CHAPTER,
    bd.FILE_DATE AS BANKRUPTCYFILEDATE,
    bd.POC_REQUIRED,
    bd.POC_DEADLINE_DATE,
    bd.POC_COMPLETED_DATE,
    bd.DISCHARGE_DATE,

    -- Loan Origination Details
    ltm.ORIGINATIONDATE,
    ltm.LOANAMOUNT,
    ltm.TERM,
    ltm.INTERESTRATE,
    ltm.APR,
    ltm.BUREAUFICOSCORE,
    ltm.EMPLOYMENTSTATUS,
    ltm.ANNUALINCOME,

    -- Flags and Indicators
    COALESCE(sd.SCRAFLAG, 'N') AS SCRAFLAG,
    COALESCE(sd.IS_DECEASED, FALSE) AS DECEASED_INDICATOR,
    COALESCE(fp.IS_FRAUD, FALSE) AS FRAUD_INDICATOR,
    lcs.PLACEMENT_STATUS AS LOAN_CURRENT_PLACEMENT,
    IFF(ltm.LASTPAYMENTDATE IS NULL, TRUE, FALSE) AS FIRST_PAYMENT_DEFAULT_INDICATOR,

    -- Contact Rules
    lcr.SUPPRESS_PHONE AS SUSPEND_PHONE,
    lcr.SUPPRESS_TEXT AS SUSPEND_TEXT,
    lcr.SUPPRESS_EMAIL AS SUSPEND_EMAIL,
    lcr.SUPPRESS_LETTER AS SUSPEND_LETTER,
    lcr.CEASE_AND_DESIST,

    -- Data Quality
    fp.DATA_SOURCE AS FRAUD_DATA_SOURCE,
    vl.LOAN_CLOSED_DATE

FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY ltm

INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    ON UPPER(ltm.LOANID) = UPPER(vl.LEGACY_LOAN_ID)

LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII m_pii
    ON vl.MEMBER_ID = m_pii.MEMBER_ID
    AND m_pii.MEMBER_PII_END_DATE IS NULL

LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT lcs
    ON vl.LOAN_ID::TEXT = lcs.LOAN_ID::TEXT
    AND lcs.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()

LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES lcr
    ON vl.LOAN_ID::TEXT = lcr.LOAN_ID::TEXT
    AND lcr.CONTACT_RULE_END_DATE IS NULL

LEFT JOIN cte_fraud_placeholder fp
    ON vl.LOAN_ID::TEXT = fp.LOAN_ID::TEXT

LEFT JOIN cte_scra_deceased sd
    ON vl.LOAN_ID::TEXT = sd.LOAN_ID::TEXT

LEFT JOIN cte_payment_history ph
    ON LOWER(vl.LEAD_GUID) = LOWER(ph.LEAD_GUID)

LEFT JOIN cte_delinquency_dates dd
    ON LOWER(vl.LEAD_GUID) = LOWER(dd.PAYOFFUID)

LEFT JOIN cte_most_recent_30dpd mrd
    ON LOWER(vl.LEAD_GUID) = LOWER(mrd.PAYOFFUID)

LEFT JOIN cte_settlement_exclusions se
    ON vl.LOAN_ID::TEXT = se.LOAN_ID::TEXT

LEFT JOIN cte_bankruptcy_data bd
    ON vl.LOAN_ID::TEXT = bd.LOAN_ID::TEXT

WHERE 1=1
    -- Most recent monthly loan tape
    AND DATE_TRUNC('month', ltm.ASOFDATE) = DATE_TRUNC('month', DATEADD('month', -1, CURRENT_DATE()))

    -- Only charged-off loans
    AND ltm.STATUS = 'Charge off'

    -- Chargeoff date filter (as of pull date)
    AND ltm.CHARGEOFFDATE <= $end_chargeoffdate

    -- Exclude fully recovered loans
    AND ltm.RECOVERIESPAIDTODATE < ltm.PRINCIPALBALANCEATCHARGEOFF

    -- Exclude fraud
    AND COALESCE(fp.IS_FRAUD, FALSE) = FALSE

    -- Exclude deceased
    AND COALESCE(sd.IS_DECEASED, FALSE) = FALSE

    -- Exclude active/complete settlements
    AND se.LOAN_ID IS NULL

    -- Exclude existing placements
    AND (lcs.PLACEMENT_STATUS NOT IN ('Resurgent', 'Bounce', 'Jefferson Capital', 'First Tech Credit Union', 'ARS', 'Remitter')
        OR lcs.PLACEMENT_STATUS IS NULL)

    -- Exclude closed loans
    AND vl.LOAN_CLOSED_DATE IS NULL
)

SELECT DISTINCT * FROM cte_final
ORDER BY CHARGEOFFDATE DESC, UNPAIDBALANCEDUE DESC;

-- ============================================================================
-- Query Results
-- ============================================================================
SELECT * FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025;
