/*
================================================================================
SIMM Character Filtering Bug - Validation and Testing Queries
================================================================================

PURPOSE: Provide queries to validate the fix and test the corrected logic
USAGE: Run these queries before and after implementing the fix to verify results
*/

-- ========================================
-- PRE-FIX VALIDATION: Identify Affected Accounts
-- ========================================

-- 1. Find SIMM accounts that are currently excluded from Call List "Charge off"
SELECT
    'SIMM Charge-off Accounts Missing from Call List' as issue_description,
    COUNT(*) as affected_account_count,
    ROUND(AVG(REMAININGPRINCIPAL + ACCRUEDINTEREST), 2) as avg_balance
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE CHARGEOFFDATE IS NOT NULL
  AND substring(PAYOFFUID, 16, 1) IN ('8', '9', 'a', 'b', 'c', 'd', 'e', 'f')  -- SIMM accounts
  AND ASOFDATE = (SELECT MAX(ASOFDATE) FROM DATA_STORE.MVW_LOAN_TAPE)
  -- These accounts should be in Call List "Charge off" but are excluded by current logic;

-- 2. Find SIMM accounts missing payment reminders (current accounts with upcoming due dates)
SELECT
    'SIMM Accounts Missing Payment Reminders' as issue_description,
    COUNT(*) as affected_account_count,
    COUNT(CASE WHEN DAYSPASTDUE = 0 THEN 1 END) as current_accounts,
    COUNT(CASE WHEN DAYSPASTDUE < 0 THEN 1 END) as accounts_with_future_due_dates
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE STATUS = 'Current'
  AND DAYSPASTDUE <= 2  -- Payment reminder eligible
  AND substring(PAYOFFUID, 16, 1) IN ('8', '9', 'a', 'b', 'c', 'd', 'e', 'f')  -- SIMM accounts
  AND ASOFDATE = (SELECT MAX(ASOFDATE) FROM DATA_STORE.MVW_LOAN_TAPE);

-- 3. Verify current DPD 3-119 allocation is working (should show 50/50 split)
SELECT
    CASE
        WHEN substring(PAYOFFUID, 16, 1) IN ('0','1','2','3','4','5','6','7') THEN 'HAPPY_MONEY'
        WHEN substring(PAYOFFUID, 16, 1) IN ('8','9','a','b','c','d','e','f') THEN 'SIMM'
        ELSE 'OTHER'
    END as allocation_partner,
    COUNT(*) as account_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE DAYSPASTDUE BETWEEN 3 AND 119
  AND not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  AND ASOFDATE = (SELECT MAX(ASOFDATE) FROM DATA_STORE.MVW_LOAN_TAPE)
GROUP BY 1
ORDER BY 2 DESC;

-- ========================================
-- POST-FIX VALIDATION: Test the Corrected Logic
-- ========================================

-- 4. Test new Call List logic (simulate the fix)
WITH CORRECTED_CALL_LIST AS (
    SELECT
        PAYOFFUID,
        case
            when CHARGEOFFDATE is not null then 'Charge off'
            when PORTFOLIONAME = 'Payoff FBO Blue Federal Credit Union' and DAYSPASTDUE < 90 then 'Blue'
            when PORTFOLIONAME in ('Payoff FBO USAlliance Federal Credit Union',
                                   'Payoff FBO Michigan State University Federal Credit Union') and
                 DAYSPASTDUE < 90
                then 'Due Diligence DPD3-89'
            when DAYSPASTDUE <= 14 then 'DPD3-14'
            when DAYSPASTDUE <= 29 then 'DPD15-29'
            when DAYSPASTDUE <= 59 then 'DPD30-59'
            when DAYSPASTDUE <= 89 then 'DPD60-89'
            when DAYSPASTDUE > 89 then 'DPD90+'
            else 'Exclude'
        end as LIST_NAME,
        DAYSPASTDUE,
        STATUS,
        substring(PAYOFFUID, 16, 1) as character_position
    FROM DATA_STORE.MVW_LOAN_TAPE
    WHERE not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold'))
      AND ASOFDATE = (SELECT MAX(ASOFDATE) FROM DATA_STORE.MVW_LOAN_TAPE)
      -- NEW CORRECTED LOGIC:
      AND (
        (DAYSPASTDUE between 3 and 119 and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7'))
        OR
        (DAYSPASTDUE not between 3 and 119)
      )
)
SELECT
    LIST_NAME,
    COUNT(*) as total_accounts,
    COUNT(CASE WHEN character_position IN ('0','1','2','3','4','5','6','7') THEN 1 END) as happy_money_accounts,
    COUNT(CASE WHEN character_position IN ('8','9','a','b','c','d','e','f') THEN 1 END) as simm_accounts,
    ROUND(COUNT(CASE WHEN character_position IN ('8','9','a','b','c','d','e','f') THEN 1 END) * 100.0 / COUNT(*), 1) as simm_percentage
FROM CORRECTED_CALL_LIST
WHERE LIST_NAME <> 'Exclude'
GROUP BY LIST_NAME
ORDER BY total_accounts DESC;

-- 5. Test new SMS logic (simulate the fix)
WITH CORRECTED_SMS AS (
    SELECT
        PAYOFFUID,
        case
            when DAYSPASTDUE <= -1 then 'Payment Reminder'
            when DAYSPASTDUE = 0 then 'Due Date'
            when DAYSPASTDUE = 3 then 'DPD3'
            when DAYSPASTDUE = 6 then 'DPD6'
            when DAYSPASTDUE = 8 then 'DPD8'
            when DAYSPASTDUE = 11 then 'DPD11'
            when DAYSPASTDUE = 15 then 'DPD15'
            when DAYSPASTDUE = 17 then 'DPD17'
            when DAYSPASTDUE = 21 then 'DPD21'
            when DAYSPASTDUE = 23 then 'DPD23'
            when DAYSPASTDUE = 25 then 'DPD25'
            when DAYSPASTDUE = 28 then 'DPD28'
            when DAYSPASTDUE = 33 then 'DPD33'
            when DAYSPASTDUE = 38 then 'DPD38'
            when DAYSPASTDUE = 44 then 'DPD44'
            else 'Exclude'
        end as LIST_NAME,
        DAYSPASTDUE,
        STATUS,
        substring(PAYOFFUID, 16, 1) as character_position
    FROM DATA_STORE.MVW_LOAN_TAPE
    WHERE STATUS <> 'Charge off'
      AND ASOFDATE = (SELECT MAX(ASOFDATE) FROM DATA_STORE.MVW_LOAN_TAPE)
      -- NEW CORRECTED LOGIC:
      AND (
        (DAYSPASTDUE between 3 and 119 and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7'))
        OR
        (DAYSPASTDUE not between 3 and 119)
      )
)
SELECT
    LIST_NAME,
    COUNT(*) as total_accounts,
    COUNT(CASE WHEN character_position IN ('0','1','2','3','4','5','6','7') THEN 1 END) as happy_money_accounts,
    COUNT(CASE WHEN character_position IN ('8','9','a','b','c','d','e','f') THEN 1 END) as simm_accounts,
    ROUND(COUNT(CASE WHEN character_position IN ('8','9','a','b','c','d','e','f') THEN 1 END) * 100.0 / COUNT(*), 1) as simm_percentage
FROM CORRECTED_SMS
WHERE LIST_NAME <> 'Exclude'
GROUP BY LIST_NAME
ORDER BY
    CASE LIST_NAME
        WHEN 'Payment Reminder' THEN 1
        WHEN 'Due Date' THEN 2
        ELSE 3
    END,
    total_accounts DESC;

-- ========================================
-- POST-IMPLEMENTATION VALIDATION
-- ========================================

-- 6. Monitor campaign volume changes after fix implementation
SELECT
    'Call List Volume Comparison' as metric_type,
    COUNT(*) as current_volume
FROM CRON_STORE.RPT_OUTBOUND_LISTS
WHERE SET_NAME = 'Call List'
  AND LOAD_DATE = CURRENT_DATE
  AND SUPPRESSION_FLAG = false;

SELECT
    'SMS Volume Comparison' as metric_type,
    COUNT(*) as current_volume
FROM CRON_STORE.RPT_OUTBOUND_LISTS
WHERE SET_NAME = 'SMS'
  AND LOAD_DATE = CURRENT_DATE
  AND SUPPRESSION_FLAG = false;

-- 7. Verify SIMM DPD 3-119 allocation still works correctly (should remain ~50/50)
SELECT
    'DPD 3-119 Allocation Check' as validation_type,
    CASE
        WHEN substring(PAYOFFUID, 16, 1) IN ('0','1','2','3','4','5','6','7') THEN 'HAPPY_MONEY'
        WHEN substring(PAYOFFUID, 16, 1) IN ('8','9','a','b','c','d','e','f') THEN 'SIMM'
        ELSE 'OTHER'
    END as allocation_partner,
    COUNT(*) as account_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) as percentage
FROM CRON_STORE.RPT_OUTBOUND_LISTS
WHERE SET_NAME IN ('Call List', 'SMS', 'Remitter')
  AND LIST_NAME NOT IN ('Charge off', 'Payment Reminder', 'Due Date')  -- DPD 3-119 campaigns only
  AND LOAD_DATE = CURRENT_DATE
  AND SUPPRESSION_FLAG = false
GROUP BY 2
ORDER BY account_count DESC;

-- 8. Spot check: Verify specific SIMM accounts now appear in charge-off campaigns
SELECT
    'SIMM Charge-off Inclusion Check' as validation_type,
    OL.SET_NAME,
    OL.LIST_NAME,
    COUNT(*) as simm_accounts_included
FROM CRON_STORE.RPT_OUTBOUND_LISTS OL
WHERE OL.LIST_NAME = 'Charge off'
  AND substring(OL.PAYOFFUID, 16, 1) IN ('8','9','a','b','c','d','e','f')
  AND OL.LOAD_DATE = CURRENT_DATE
  AND OL.SUPPRESSION_FLAG = false
GROUP BY OL.SET_NAME, OL.LIST_NAME
ORDER BY simm_accounts_included DESC;

-- ========================================
-- BUSINESS IMPACT MEASUREMENT
-- ========================================

-- 9. Calculate potential recovery impact
SELECT
    'Potential Recovery Impact' as metric,
    COUNT(*) as newly_included_accounts,
    ROUND(SUM(LT.REMAININGPRINCIPAL + LT.ACCRUEDINTEREST), 2) as total_balance_exposure,
    ROUND(AVG(LT.REMAININGPRINCIPAL + LT.ACCRUEDINTEREST), 2) as avg_balance_per_account,
    ROUND(COUNT(*) * 0.15, 0) as estimated_recovery_accounts,  -- Assume 15% recovery rate
    ROUND(SUM(LT.REMAININGPRINCIPAL + LT.ACCRUEDINTEREST) * 0.15, 2) as estimated_recovery_amount
FROM CRON_STORE.RPT_OUTBOUND_LISTS OL
INNER JOIN DATA_STORE.MVW_LOAN_TAPE LT ON OL.PAYOFFUID = LT.PAYOFFUID
WHERE OL.LIST_NAME = 'Charge off'
  AND substring(OL.PAYOFFUID, 16, 1) IN ('8','9','a','b','c','d','e','f')
  AND OL.LOAD_DATE = CURRENT_DATE
  AND LT.ASOFDATE = CURRENT_DATE
  AND OL.SUPPRESSION_FLAG = false;