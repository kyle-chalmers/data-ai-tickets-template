/*
================================================================================
DI-1211: Placement Data Quality Analysis - Bounce and Resurgent
================================================================================

BUSINESS CONTEXT:
Identify charged-off loans incorrectly marked with Bounce or Resurgent placement
status that show evidence of:
1. Active or completed settlement arrangements
2. Post-chargeoff payments received
3. Future scheduled payments

These discrepancies indicate data quality issues in LoanPro settings that don't
reflect true account status.

OUTPUT FIELDS:
- Loan identifiers (LOAN_ID, LEGACY_LOAN_ID, LEAD_GUID)
- Placement Status (Bounce/Resurgent)
- Chargeoff details (date, principal amount)
- Payment activity (total post-chargeoff, current balance)
- AutoPay status
- Future scheduled payments indicator
- Settlement status

================================================================================
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE;

-- Output to table for easy export
CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE_DEV.CRON_STORE.DI_1211_PLACEMENT_DATA_QUALITY AS

WITH cte_post_chargeoff_payments AS (
    -- Calculate total payments received after chargeoff date
    SELECT
        pt.LOAN_ID,
        SUM(CASE
            WHEN pt.IS_SETTLED = TRUE
                AND pt.IS_REVERSED <> TRUE
                AND pt.IS_REJECTED <> TRUE
                AND pt.TRANSACTION_DATE > vl.CHARGEOFF_DATE
            THEN pt.TRANSACTION_AMOUNT
            ELSE 0
        END) AS TOTAL_POST_CHARGEOFF_PAYMENTS,
        COUNT(CASE
            WHEN pt.IS_SETTLED = TRUE
                AND pt.IS_REVERSED <> TRUE
                AND pt.IS_REJECTED <> TRUE
                AND pt.TRANSACTION_DATE > vl.CHARGEOFF_DATE
            THEN 1
        END) AS POST_CHARGEOFF_PAYMENT_COUNT
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION pt
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON pt.LOAN_ID::TEXT = vl.LOAN_ID::TEXT
    WHERE vl.LOAN_STATUS_TEXT = 'Charge off'
        AND vl.CHARGEOFF_DATE IS NOT NULL
    GROUP BY pt.LOAN_ID
),

cte_future_scheduled_payments AS (
    -- Check for future scheduled payments
    SELECT
        ps.LOAN_ID,
        COUNT(*) AS FUTURE_SCHEDULED_PAYMENT_COUNT,
        MIN(ps.EXPECTED_PAYMENT_DATE) AS NEXT_SCHEDULED_PAYMENT_DATE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_PAYMENT_SCHEDULE_ENTITY_CURRENT ps
    WHERE ps.EXPECTED_PAYMENT_DATE > CURRENT_DATE()
        AND ps.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    GROUP BY ps.LOAN_ID
)

-- Main query
SELECT
    vl.LOAN_ID,
    vl.LEGACY_LOAN_ID,
    vl.LEAD_GUID,
    lcs.PLACEMENT_STATUS,
    vl.CHARGEOFF_DATE,
    vl.PRINCIPAL_BALANCE_AT_CHARGEOFF AS CHARGEOFF_PRINCIPAL_AMOUNT,
    COALESCE(pcp.TOTAL_POST_CHARGEOFF_PAYMENTS, 0) AS TOTAL_PAYMENTS_POST_CHARGEOFF,
    pcp.POST_CHARGEOFF_PAYMENT_COUNT,
    vl.PRINCIPAL_BALANCE AS CURRENT_PRINCIPAL_BALANCE,
    IFF(vl.AUTOPAY_ENABLED = TRUE, 'Y', 'N') AS AUTOPAY_STATUS,
    IFF(fsp.FUTURE_SCHEDULED_PAYMENT_COUNT > 0, 'Y', 'N') AS FUTURE_SCHEDULED_PAYMENTS,
    fsp.NEXT_SCHEDULED_PAYMENT_DATE,
    COALESCE(lds.SETTLEMENTSTATUS, lds.CURRENT_STATUS, 'None') AS SETTLEMENT_STATUS,
    lds.SETTLEMENT_ACCEPTED_DATE,
    lds.SETTLEMENT_COMPLETION_DATE,
    lds.SETTLEMENT_AMOUNT,
    lds.SETTLEMENT_AMOUNT_PAID,
    vl.LOAN_STATUS_TEXT,
    vl.LOAN_SUB_STATUS_TEXT

FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl

INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT lcs
    ON vl.LOAN_ID::TEXT = lcs.LOAN_ID::TEXT
    AND lcs.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()

LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT lds
    ON vl.LOAN_ID::TEXT = lds.LOAN_ID::TEXT

LEFT JOIN cte_post_chargeoff_payments pcp
    ON vl.LOAN_ID::TEXT = pcp.LOAN_ID::TEXT

LEFT JOIN cte_future_scheduled_payments fsp
    ON vl.LOAN_ID::TEXT = fsp.LOAN_ID::TEXT

WHERE 1=1
    AND vl.LOAN_STATUS_TEXT = 'Charge off'
    AND lcs.PLACEMENT_STATUS IN ('Bounce', 'Resurgent')
    AND (
        -- Has post-chargeoff payments
        pcp.TOTAL_POST_CHARGEOFF_PAYMENTS > 0
        -- OR has active/completed settlement
        OR lds.SETTLEMENTSTATUS IN ('Active', 'Complete')
        OR lds.CURRENT_STATUS IN ('Active', 'Complete')
        -- OR has future scheduled payments
        OR fsp.FUTURE_SCHEDULED_PAYMENT_COUNT > 0
        -- OR has AutoPay enabled
        OR vl.AUTOPAY_ENABLED = TRUE
    )

ORDER BY
    lcs.PLACEMENT_STATUS,
    pcp.TOTAL_POST_CHARGEOFF_PAYMENTS DESC,
    vl.CHARGEOFF_DATE DESC;

-- Export results
SELECT * FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.DI_1211_PLACEMENT_DATA_QUALITY;
