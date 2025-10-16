/*
================================================================================
DI-1211: Placement Data Quality Analysis - Bounce and Resurgent (CORRECTED)
================================================================================

BUSINESS CONTEXT:
Identify charged-off loans marked with Bounce or Resurgent placement status
that show evidence of continued servicing by Happy Money through ANY of:
1. Active settlement arrangements (not fully settled)
2. Post-chargeoff payments being received
3. Active/pending autopay transactions in the system

DATA QUALITY IMPACT:
These conflicts indicate placement status may not reflect actual servicing,
potentially causing payment routing errors, customer confusion, and compliance issues.

CORRECTION NOTES:
- Removed VW_LOAN_SCHED_FCST_PAYMENTS indicator (amortization schedule projections, not actual obligations)
- Replaced VW_LOAN_PAYMENT_MODE with LOAN_AUTOPAY_ENTITY (actual pending/processing autopay)
- Added future payment transactions from VW_LP_PAYMENT_TRANSACTION (actual scheduled payments)

UPDATED: October 15, 2025 (Corrected)
================================================================================
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

WITH post_chargeoff_payments AS (
    -- Calculate post-chargeoff payment activity
    SELECT
        pt.LOAN_ID,
        UPPER(pt.LOANID) AS LOANID,
        COUNT(*) as PAYMENT_COUNT,
        SUM(pt.PAYMENT_AMOUNT) as TOTAL_AMOUNT,
        MAX(pt.TRANSACTION_DATE) as LAST_PAYMENT_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION pt
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE VL
    ON pt.TRANSACTION_DATE > vl.CHARGEOFFDATE
           AND VL.LOANID = UPPER(pt.LOANID)
        AND VL.PLACEMENT_STATUS IN ('Placed - Bounce', 'Placed - Resurgent')
    WHERE 1=1
      AND pt.TRANSACTION_DATE > vl.CHARGEOFFDATE
      AND pt.IS_SETTLED = TRUE
      AND pt.IS_WAIVER = FALSE
      AND COALESCE(pt.IS_REVERSED, FALSE) = FALSE
      AND COALESCE(pt.IS_REJECTED, FALSE) = FALSE
    GROUP BY pt.LOAN_ID, pt.LOANID),

active_pending_autopay AS (
    -- Identify loans with active/pending autopay transactions (from FRESHSNOW layer)
    -- This tracks actual pending/processing autopay, not just payment mode status
    SELECT
        ap.LOAN_ID,
        ap.TYPE as AUTOPAY_TYPE,
        MIN(ap.APPLY_DATE) as NEXT_AUTOPAY_DATE,
        MAX(ap.AMOUNT) as AUTOPAY_AMOUNT,
        COUNT(*) as AUTOPAY_COUNT
    FROM ARCA.FRESHSNOW.LOAN_AUTOPAY_ENTITY_CURRENT ap
    WHERE ap.ACTIVE = 1
      AND ap.STATUS IN ('autopay.status.pending', 'autopay.status.processing')
    GROUP BY ap.LOAN_ID, ap.TYPE
),

future_payment_transactions AS (
    -- Identify loans with future-dated payment transactions (actual scheduled payments, not projections)
    SELECT
        pt.LOAN_ID,
        COUNT(*) as PAYMENT_COUNT,
        MIN(pt.APPLY_DATE) as NEXT_PAYMENT_DATE,
        SUM(pt.PAYMENT_AMOUNT) as TOTAL_FUTURE_AMOUNT,
        LISTAGG(DISTINCT pt.PAYMENT_TYPE, '; ') as PAYMENT_TYPES
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION pt
    WHERE pt.APPLY_DATE > CURRENT_DATE()
    GROUP BY pt.LOAN_ID
)

SELECT
    -- Loan identifiers
    LCS.LOAN_ID AS LP_LOAN_ID,
    mlt.LOANID,
    mlt.PAYOFFUID,
    mlt.PLACEMENT_STATUS,
    mlt.PLACEMENT_STATUS_STARTDATE,
    mlt.CHARGEOFFDATE,
    mlt.PRINCIPALBALANCEATCHARGEOFF,
    mlt.RECOVERIESPAIDTODATE,
    -- Settlement indicators
    lds.CURRENT_STATUS AS CURRENT_LP_STATUS,
    lds.SETTLEMENTSTATUS,
    lds.SETTLEMENT_ACCEPTED_DATE,
    lds.SETTLEMENT_COMPLETION_DATE,
    lds.SETTLEMENT_AMOUNT,
    lds.SETTLEMENT_AMOUNT_PAID,
    lds.DATA_SOURCE_LIST as SETTLEMENT_DATA_SOURCE_LIST,
    -- Post-chargeoff payment indicators
    COALESCE(post_co.PAYMENT_COUNT, 0) AS POST_CHARGEOFF_PAYMENT_COUNT,
    COALESCE(post_co.TOTAL_AMOUNT, 0) AS TOTAL_POST_CHARGEOFF_PAYMENTS,
    post_co.LAST_PAYMENT_DATE AS LAST_POST_CHARGEOFF_PAYMENT_DATE,

    -- Active/pending autopay indicators
    CASE WHEN autopay.LOAN_ID IS NOT NULL THEN 'Y' ELSE 'N' END AS AUTOPAY_PENDING,
    autopay.AUTOPAY_TYPE,
    autopay.NEXT_AUTOPAY_DATE,
    COALESCE(autopay.AUTOPAY_AMOUNT, 0) AS AUTOPAY_AMOUNT,
    COALESCE(autopay.AUTOPAY_COUNT, 0) AS AUTOPAY_COUNT,

    -- Future payment transaction indicators
    COALESCE(fut_pmt.PAYMENT_COUNT, 0) AS FUTURE_PAYMENT_COUNT,
    fut_pmt.NEXT_PAYMENT_DATE AS FUTURE_PAYMENT_DATE,
    COALESCE(fut_pmt.TOTAL_FUTURE_AMOUNT, 0) AS TOTAL_FUTURE_PAYMENT_AMOUNT,
    fut_pmt.PAYMENT_TYPES AS FUTURE_PAYMENT_TYPES,

    -- Conflict flags for analysis
    CASE WHEN lds.LEAD_GUID IS NOT NULL THEN 1 ELSE 0 END AS HAS_SETTLEMENT_DATA,
    CASE WHEN autopay.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END AS HAS_ACTIVE_AUTOPAY,
    CASE WHEN fut_pmt.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END AS HAS_FUTURE_PAYMENTS,

    -- Conflict count for prioritization
    (CASE WHEN lds.LEAD_GUID IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN autopay.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
     CASE WHEN fut_pmt.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END) AS TOTAL_CONFLICT_COUNT

FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE MLT
/*INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN vl
    ON vl.LEAD_GUID = mlt.PAYOFFUID*/
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT lcs
    ON mlt.PAYOFFUID = lcs.LEAD_GUID

-- Settlement conflicts (NOT 'Closed - Settled in Full')
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT lds
    ON mlt.PAYOFFUID = lds.LEAD_GUID

-- Post-chargeoff payments
LEFT JOIN post_chargeoff_payments post_co
    ON MLT.LOANID = post_co.LOANID

-- Active/pending autopay (from LOAN_AUTOPAY_ENTITY)
LEFT JOIN active_pending_autopay autopay
    ON lcs.LOAN_ID = autopay.LOAN_ID

-- Future payment transactions (actual scheduled payments)
LEFT JOIN future_payment_transactions fut_pmt
    ON lcs.LOAN_ID = fut_pmt.LOAN_ID

WHERE mlt.CHARGEOFFDATE IS NOT NULL
  AND mlt.PLACEMENT_STATUS IN ('Placed - Bounce', 'Placed - Resurgent')
  AND mlt.RECOVERIESPAIDTODATE > 0
    /*(
      lds.LEAD_GUID IS NOT NULL         -- Has settlement conflict
      OR post_co.LOAN_ID IS NOT NULL    -- Has post-chargeoff payments
      OR autopay.LOAN_ID IS NOT NULL    -- Has active/pending autopay
      OR fut_pmt.LOAN_ID IS NOT NULL    -- Has future payment transactions
  )*/

ORDER BY
    TOTAL_CONFLICT_COUNT DESC,  -- Prioritize loans with multiple conflicts
    MLT.PLACEMENT_STATUS,
    MLT.CHARGEOFFDATE DESC;