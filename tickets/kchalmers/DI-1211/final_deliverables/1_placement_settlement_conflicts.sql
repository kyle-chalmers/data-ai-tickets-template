/*
================================================================================
DI-1211: Placement Data Quality Analysis - Bounce and Resurgent (Simplified)
================================================================================

BUSINESS CONTEXT:
Identify charged-off loans marked with Bounce or Resurgent placement status
that show evidence of active settlement arrangements or post-chargeoff payments.

================================================================================
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

SELECT
    vl.LOAN_ID,
    vl.LEGACY_LOAN_ID,
    vl.LEAD_GUID,
    lcs.PLACEMENT_STATUS,
    vl.CHARGE_OFF_DATE AS CHARGEOFF_DATE,
    vl.PRINCIPAL_BALANCE_AT_CHARGE_OFF AS CHARGEOFF_PRINCIPAL_AMOUNT,
    COALESCE(lds.SETTLEMENTSTATUS, lds.CURRENT_STATUS, 'None') AS SETTLEMENT_STATUS,
    lds.SETTLEMENT_ACCEPTED_DATE,
    lds.SETTLEMENT_COMPLETION_DATE,
    lds.SETTLEMENT_AMOUNT,
    lds.SETTLEMENT_AMOUNT_PAID

FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN vl

INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT lcs
    ON vl.LOAN_ID = lcs.LOAN_ID

LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT lds
    ON vl.LOAN_ID = lds.LOAN_ID

WHERE vl.CHARGE_OFF_DATE IS NOT NULL
    AND lcs.PLACEMENT_STATUS IN ('Bounce', 'Resurgent')
    AND (
        lds.SETTLEMENTSTATUS IN ('Active', 'Complete')
        OR lds.CURRENT_STATUS IN ('Active', 'Complete')
    )

ORDER BY
    lcs.PLACEMENT_STATUS,
    vl.CHARGE_OFF_DATE DESC;
