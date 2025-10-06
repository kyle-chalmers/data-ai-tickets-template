/*
================================================================================
DI-1320: Unauthorized ACH Transactions from Autopay Not Disabling at Charge-Off
Simplified Query Design
================================================================================

BUSINESS PROBLEM:
When a loan charges off, autopay should automatically turn off. If it doesn't,
we may be making unauthorized ACH attempts or collecting unauthorized payments.

WHAT WE'RE LOOKING FOR:
1. Charged-off loans with autopay still active
2. Whether unauthorized ACH attempts were made (and if they succeeded or failed)
3. Which collection agency the loan was placed with

FUNCTIONAL CLASSIFICATION:
- AUTOPAY_ACTIVE_NO_PAYMENTS: Autopay on, but no payments attempted/collected after charge-off
- AUTOPAY_ACTIVE_FAILED_ATTEMPTS: Autopay on, attempted payments but all failed (NSF/reversed)
- AUTOPAY_ACTIVE_PAYMENTS_COLLECTED: Autopay on, successfully collected unauthorized payments

DATA SOURCES:
- DATA_STORE.MVW_LOAN_TAPE: Charge-off dates, placement info, recovery amounts
- VW_LOAN_PAYMENT_MODE: Current autopay status
- VW_LP_PAYMENT_TRANSACTION: Payment attempts after charge-off (successful vs failed)

KEY LOGIC:
- Successful payment = IS_ACTIVE = 1 AND IS_REVERSED = 0
- Failed payment = IS_REVERSED = 1 OR IS_REJECTED = 1
- Placement status tells us which collection agency has the loan
================================================================================
*/

-- ============================================================================
-- BASE TABLE: All charged-off loans from current loan tape
-- ============================================================================
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
WITH charged_off_loans AS (
    SELECT
        LOANID,
        STATUS,
        CHARGEOFFDATE,
        PRINCIPALBALANCEATCHARGEOFF,
        PLACEMENT_STATUS,
        PLACEMENT_STATUS_STARTDATE,
        RECOVERIESPAIDTODATE,
        LASTPAYMENTDATE,
        LASTPAYMENTAMOUNT
    FROM DATA_STORE.MVW_LOAN_TAPE
    WHERE CHARGEOFFDATE IS NOT NULL  -- Must be charged off
),

-- ============================================================================
-- Get loan identifiers (LOAN_ID, LEAD_GUID)
-- ============================================================================
loan_identifiers AS (
    SELECT
        CAST(LOAN_ID AS VARCHAR) AS LOAN_ID,
        LEGACY_LOAN_ID,
        LEAD_GUID
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN
),

-- ============================================================================
-- Check current autopay status
-- ============================================================================
autopay_status AS (
    SELECT
        CAST(LOAN_ID AS VARCHAR) AS LOAN_ID,
        PAYMENT_MODE,
        PAYMENT_MODE_START_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PAYMENT_MODE
    WHERE PAYMENT_MODE_END_DATE IS NULL  -- Current payment mode
        AND PAYMENT_MODE = 'Auto Payer'  -- Only loans with autopay currently on
),

-- ============================================================================
-- Get LoanPro current status
-- ============================================================================
loan_current_status AS (
    SELECT
        A.LOAN_ID::VARCHAR AS LOAN_ID,
        B.TITLE AS LP_CURRENT_STATUS,
        A.LOAN_SUB_STATUS_ID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT A
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT B
        ON A.LOAN_SUB_STATUS_ID = B.ID
        AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    WHERE A.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
        AND A.DELETED = 0
),

-- ============================================================================
-- Get debt settlement information
-- ============================================================================
debt_settlement AS (
    SELECT
        LOAN_ID,
        SETTLEMENTSTATUS,
        SETTLEMENT_PORTFOLIOS,
        DATA_SOURCE_LIST AS DEBT_SETTLEMENT_DATA_SOURCE_LIST,
        SETTLEMENT_START_DATE,
        SETTLEMENT_COMPLETION_DATE,
        CASE
            WHEN LOAN_ID IS NOT NULL THEN 'Y'
            ELSE 'N'
        END AS HAS_DEBT_SETTLEMENT_DATA
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
),

-- ============================================================================
-- Step 3: Get payments attempted AFTER charge-off
-- ============================================================================
post_chargeoff_payments AS (
    SELECT
        CAST(PT.LOAN_ID AS VARCHAR) AS LOAN_ID,
        COUNT(PT.PAYMENT_ID) AS TOTAL_PAYMENT_ATTEMPTS,
        COUNT(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 1
            THEN PT.PAYMENT_ID
        END) AS ACTIVE_SETTLED_PAYMENT_COUNT,
        SUM(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 1
            THEN PT.PAYMENT_AMOUNT
            ELSE 0
        END) AS ACTIVE_SETTLED_PAYMENT_AMOUNT,
        COUNT(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 0
            THEN PT.PAYMENT_ID
            ELSE 0
        END) AS ACTIVE_NOT_SETTLED_PAYMENT_COUNT,
        SUM(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 0
            THEN PT.PAYMENT_AMOUNT
            ELSE 0
        END) AS ACTIVE_NOT_SETTLED_PAYMENT_AMOUNT,
        COUNT(CASE
            WHEN PT.IS_REVERSED = 1 OR PT.IS_REJECTED = 1
            THEN PT.PAYMENT_ID
        END) AS FAILED_PAYMENT_COUNT,
        SUM(CASE
            WHEN PT.IS_REVERSED = 1 OR PT.IS_REJECTED = 1
            THEN PT.PAYMENT_AMOUNT
            ELSE 0
        END) AS FAILED_PAYMENT_AMOUNT,
        MIN(PT.APPLY_DATE) AS FIRST_PAYMENT_ATTEMPT_DATE,
        MAX(PT.APPLY_DATE) AS LAST_PAYMENT_ATTEMPT_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION PT
    INNER JOIN charged_off_loans COL
        ON PT.LOANID = COL.LOANID
    WHERE PT.APPLY_DATE > COL.CHARGEOFFDATE
    AND PT.IS_WAIVER = 0
    GROUP BY PT.LOAN_ID
),
    post_lp_chargeoff_payments AS (
    SELECT
        CAST(PT.LOAN_ID AS VARCHAR) AS LOAN_ID,

        -- Count all payment attempts
        COUNT(PT.PAYMENT_ID) AS TOTAL_LP_PAYMENT_ATTEMPTS,

        -- Successful payments (active and not reversed)
        COUNT(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 1
            THEN PT.PAYMENT_ID
        END) AS ACTIVE_SETTLED_LP_PAYMENT_COUNT,

        SUM(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 1
            THEN PT.PAYMENT_AMOUNT
            ELSE 0
        END) AS ACTIVE_SETTLED_LP_PAYMENT_AMOUNT,
        COUNT(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 0
            THEN PT.PAYMENT_ID
            ELSE 0
        END) AS ACTIVE_NOT_SETTLED_LP_PAYMENT_COUNT,
        SUM(CASE
            WHEN PT.IS_ACTIVE = 1 AND PT.IS_REVERSED = 0 AND PT.IS_SETTLED = 0
            THEN PT.PAYMENT_AMOUNT
            ELSE 0
        END) AS ACTIVE_NOT_SETTLED_LP_PAYMENT_AMOUNT,

        -- Failed/reversed payments
        COUNT(CASE
            WHEN PT.IS_REVERSED = 1 OR PT.IS_REJECTED = 1
            THEN PT.PAYMENT_ID
        END) AS FAILED_LP_PAYMENT_COUNT,

        SUM(CASE
            WHEN PT.IS_REVERSED = 1 OR PT.IS_REJECTED = 1
            THEN PT.PAYMENT_AMOUNT
            ELSE 0
        END) AS FAILED_LP_PAYMENT_AMOUNT,

        -- Payment dates
        MIN(PT.APPLY_DATE) AS FIRST_LP_PAYMENT_ATTEMPT_DATE,
        MAX(PT.APPLY_DATE) AS LAST_LP_PAYMENT_ATTEMPT_DATE

    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION PT
    INNER JOIN charged_off_loans COL
        ON PT.LOANID = COL.LOANID
    WHERE PT.APPLY_DATE > COL.CHARGEOFFDATE  -- Only payments AFTER charge-off
    AND CLS_TRANSACTION_DATE IS NULL
    AND PT.IS_WAIVER = 0
    GROUP BY PT.LOAN_ID
),

-- ============================================================================
-- FINAL RESULTS: Start from charged-off loans as base
-- ============================================================================
final_results AS (
    SELECT
        -- Loan identifiers
        LI.LOAN_ID,
        COL.LOANID AS LEGACY_LOAN_ID,
        LI.LEAD_GUID,

        -- Charge-off information
        COL.CHARGEOFFDATE,
        COL.PRINCIPALBALANCEATCHARGEOFF,

        -- Placement information
        COL.PLACEMENT_STATUS,
        COL.PLACEMENT_STATUS_STARTDATE,

        -- Autopay information
        AP.PAYMENT_MODE,
        AP.PAYMENT_MODE_START_DATE,
        CASE
            WHEN AP.PAYMENT_MODE IS NOT NULL THEN 'Y'
            ELSE 'N'
        END AS CURRENTLY_HAS_AUTOPAY,
        CASE
            WHEN AP.PAYMENT_MODE_START_DATE <= COL.CHARGEOFFDATE
            THEN 'Y'  -- Autopay was on BEFORE charge-off (should have been turned off)
            WHEN AP.PAYMENT_MODE_START_DATE > COL.CHARGEOFFDATE
            THEN 'N'  -- Autopay turned on AFTER charge-off (unusual)
            ELSE NULL
        END AS AUTOPAY_WAS_ON_BEFORE_CHARGEOFF,

        -- Payment attempt information (LP-only payments)
        COALESCE(PCP.TOTAL_LP_PAYMENT_ATTEMPTS, 0) AS TOTAL_LP_PAYMENT_ATTEMPTS,
        COALESCE(PCP.ACTIVE_SETTLED_LP_PAYMENT_COUNT, 0) AS ACTIVE_SETTLED_LP_PAYMENTS,
        COALESCE(PCP.ACTIVE_SETTLED_LP_PAYMENT_AMOUNT, 0) AS ACTIVE_SETTLED_LP_PAYMENT_AMOUNT,
        COALESCE(PCP.ACTIVE_NOT_SETTLED_LP_PAYMENT_COUNT, 0) AS ACTIVE_NOT_SETTLED_LP_PAYMENTS,
        COALESCE(PCP.ACTIVE_NOT_SETTLED_LP_PAYMENT_AMOUNT, 0) AS ACTIVE_NOT_SETTLED_LP_PAYMENT_AMOUNT,
        COALESCE(PCP.FAILED_LP_PAYMENT_COUNT, 0) AS FAILED_LP_PAYMENTS,
        COALESCE(PCP.FAILED_LP_PAYMENT_AMOUNT, 0) AS FAILED_LP_PAYMENT_AMOUNT,
        PCP.FIRST_LP_PAYMENT_ATTEMPT_DATE,
        PCP.LAST_LP_PAYMENT_ATTEMPT_DATE,

        -- LoanPro current status
        LCS.LP_CURRENT_STATUS,

        -- Debt settlement information
        DS.SETTLEMENTSTATUS,
        DS.SETTLEMENT_PORTFOLIOS,
        DS.DEBT_SETTLEMENT_DATA_SOURCE_LIST,
        COALESCE(DS.HAS_DEBT_SETTLEMENT_DATA, 'N') AS HAS_DEBT_SETTLEMENT_DATA,

        -- Recovery tracking
        COL.RECOVERIESPAIDTODATE,
        COL.LASTPAYMENTDATE,
        COL.LASTPAYMENTAMOUNT,

        -- Payment timing analysis
        CASE
            WHEN AP.PAYMENT_MODE_START_DATE IS NULL THEN NULL
            WHEN PCP.FIRST_LP_PAYMENT_ATTEMPT_DATE IS NULL THEN NULL
            WHEN PCP.FIRST_LP_PAYMENT_ATTEMPT_DATE > AP.PAYMENT_MODE_START_DATE THEN 'Y'
            ELSE 'N'
        END AS LP_PAYMENTS_AFTER_AUTOPAY_START,

        -- Latest LP payment after placement date
        CASE
            WHEN COL.PLACEMENT_STATUS_STARTDATE IS NULL THEN NULL
            WHEN PCP.LAST_LP_PAYMENT_ATTEMPT_DATE IS NULL THEN NULL
            WHEN PCP.LAST_LP_PAYMENT_ATTEMPT_DATE > COL.PLACEMENT_STATUS_STARTDATE THEN 'Y'
            ELSE 'N'
        END AS LATEST_LP_PAYMENT_AFTER_PLACEMENT,

        -- Recovery reconciliation (compare to ACTIVE_SETTLED payments only)
       CASE
            WHEN COALESCE(COL.RECOVERIESPAIDTODATE, 0) = 0
                 AND COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_AMOUNT, 0) = 0 THEN 'MATCH'
            WHEN ABS(COALESCE(COL.RECOVERIESPAIDTODATE, 0) - COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_AMOUNT, 0)) < 0.01 THEN 'MATCH'
            WHEN COALESCE(COL.RECOVERIESPAIDTODATE, 0) > COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_AMOUNT, 0) THEN 'TAPE_HIGHER'
            WHEN COALESCE(COL.RECOVERIESPAIDTODATE, 0) < COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_AMOUNT, 0) THEN 'PAYMENTS_HIGHER'
            ELSE 'UNKNOWN'
        END AS RECOVERY_RECONCILIATION_FLAG,

        COALESCE(COL.RECOVERIESPAIDTODATE, 0) - COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_AMOUNT, 0) AS RECOVERY_AMOUNT_DIFFERENCE,

        -- FUNCTIONAL CLASSIFICATION
        CASE
            WHEN AP.PAYMENT_MODE IS NULL
            THEN 'NO_AUTOPAY_CURRENTLY'

            WHEN COALESCE(PCPCLS.TOTAL_PAYMENT_ATTEMPTS, 0) = 0
            THEN 'AUTOPAY_ACTIVE_NO_PAYMENTS'
            WHEN COALESCE(PCP.TOTAL_LP_PAYMENT_ATTEMPTS, 0) = 0
            THEN 'AUTOPAY_ACTIVE_NO_PAYMENTS_IN_LOANPRO'
            -- Settled payments collected
            WHEN COALESCE(PCP.ACTIVE_SETTLED_LP_PAYMENT_COUNT, 0) > 0
            THEN 'AUTOPAY_ACTIVE_PAYMENTS_COLLECTED_IN_LOANPRO'
            WHEN COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_COUNT, 0) > 0
                AND COALESCE(PCP.ACTIVE_SETTLED_LP_PAYMENT_COUNT, 0) = 0
            THEN 'AUTOPAY_ACTIVE_WITH_PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO'
            -- Failed attempts only (no settled)
            WHEN COALESCE(PCP.ACTIVE_SETTLED_LP_PAYMENT_COUNT, 0) = 0
                 AND COALESCE(PCP.FAILED_LP_PAYMENT_COUNT, 0) > 0
            THEN 'AUTOPAY_ACTIVE_FAILED_ATTEMPTS_IN_LOANPRO'
            WHEN COALESCE(PCPCLS.ACTIVE_SETTLED_PAYMENT_COUNT, 0) = 0
                 AND COALESCE(PCP.FAILED_LP_PAYMENT_COUNT, 0) = 0
                 AND COALESCE(PCPCLS.FAILED_PAYMENT_COUNT, 0) > 0
            THEN 'AUTOPAY_ACTIVE_FAILED_ATTEMPTS_PRIOR_TO_LOANPRO'
            -- Active but not settled payments (pending settlement)
            WHEN COALESCE(PCP.ACTIVE_NOT_SETTLED_LP_PAYMENT_COUNT, 0) > 0
            THEN 'AUTOPAY_ACTIVE_PAYMENTS_NOT_YET_SETTLED'

            ELSE 'UNKNOWN'
        END AS IMPACT_CATEGORY

    FROM charged_off_loans COL

    INNER JOIN loan_identifiers LI
        ON COL.LOANID = LI.LEGACY_LOAN_ID

    LEFT JOIN autopay_status AP
        ON LI.LOAN_ID = AP.LOAN_ID

    LEFT JOIN post_lp_chargeoff_payments PCP
        ON LI.LOAN_ID = PCP.LOAN_ID

    LEFT JOIN post_chargeoff_payments PCPCLS
        ON LI.LOAN_ID = PCPCLS.LOAN_ID

    LEFT JOIN loan_current_status LCS
        ON LI.LOAN_ID = LCS.LOAN_ID

    LEFT JOIN debt_settlement DS
        ON LI.LOAN_ID = DS.LOAN_ID
)

-- ============================================================================
-- FINAL OUTPUT: All charged-off loans with autopay and settlement details
-- ============================================================================
SELECT
    -- Identifiers
    LOAN_ID,
    LEGACY_LOAN_ID,
    LEAD_GUID,

    -- What happened?
    IMPACT_CATEGORY,
    CURRENTLY_HAS_AUTOPAY,

    -- Charge-off details
    CHARGEOFFDATE,
    PRINCIPALBALANCEATCHARGEOFF,

    -- Where is the loan now?
    PLACEMENT_STATUS,
    PLACEMENT_STATUS_STARTDATE,

    -- LoanPro current status
    LP_CURRENT_STATUS,

    -- Debt settlement details (for filtering in CSV)
    HAS_DEBT_SETTLEMENT_DATA,
    SETTLEMENTSTATUS,
    SETTLEMENT_PORTFOLIOS,
    DEBT_SETTLEMENT_DATA_SOURCE_LIST,

    -- Autopay details
    PAYMENT_MODE,
    PAYMENT_MODE_START_DATE,
    AUTOPAY_WAS_ON_BEFORE_CHARGEOFF,

    -- Payment summary (LP-only payments, excludes CLS)
    TOTAL_LP_PAYMENT_ATTEMPTS,
    ACTIVE_SETTLED_LP_PAYMENTS,
    ACTIVE_SETTLED_LP_PAYMENT_AMOUNT,
    ACTIVE_NOT_SETTLED_LP_PAYMENTS,
    ACTIVE_NOT_SETTLED_LP_PAYMENT_AMOUNT,
    FAILED_LP_PAYMENTS,
    FAILED_LP_PAYMENT_AMOUNT,
    FIRST_LP_PAYMENT_ATTEMPT_DATE,
    LAST_LP_PAYMENT_ATTEMPT_DATE,

    -- Recovery tracking
    RECOVERIESPAIDTODATE,

    -- Payment timing and reconciliation
    LP_PAYMENTS_AFTER_AUTOPAY_START,
    LATEST_LP_PAYMENT_AFTER_PLACEMENT,
    RECOVERY_RECONCILIATION_FLAG,
    RECOVERY_AMOUNT_DIFFERENCE

FROM final_results

-- Filter to only loans with autopay currently active
WHERE CURRENTLY_HAS_AUTOPAY = 'Y'
--place for example loan_ids
--AND LOAN_ID IN ('68155')
ORDER BY
    -- Put debt settlement loans at the bottom
    HAS_DEBT_SETTLEMENT_DATA,
    --LP_PAYMENTS_AFTER_AUTOPAY_START DESC,
    -- Show most severe cases first
    CASE IMPACT_CATEGORY
        WHEN 'AUTOPAY_ACTIVE_PAYMENTS_COLLECTED_IN_LOANPRO' THEN 1
        WHEN 'AUTOPAY_ACTIVE_FAILED_ATTEMPTS_IN_LOANPRO' THEN 2
        WHEN 'AUTOPAY_ACTIVE_WITH_PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO' THEN 3
        WHEN 'AUTOPAY_ACTIVE_FAILED_ATTEMPTS_PRIOR_TO_LOANPRO' THEN 4
        WHEN 'AUTOPAY_ACTIVE_PAYMENTS_NOT_YET_SETTLED' THEN 5
        WHEN 'AUTOPAY_ACTIVE_NO_PAYMENTS' THEN 6
        ELSE 7
    END,
    ACTIVE_SETTLED_LP_PAYMENT_AMOUNT DESC,
    CHARGEOFFDATE DESC;


/*
================================================================================
QUERY EXPLANATION IN SIMPLE TERMS:
================================================================================

1. Find all charged-off loans (from loan tape)
2. Check which ones currently have autopay turned on (payment mode table)
3. For those loans, look for any payment attempts AFTER the charge-off date
4. Classify each loan into one of three categories:

   a) AUTOPAY_ACTIVE_NO_PAYMENTS
      - Autopay is on, but no payment attempts made yet
      - Potential risk, but no impact yet

   b) AUTOPAY_ACTIVE_FAILED_ATTEMPTS
      - Autopay is on, attempted to collect, but all payments failed (NSF/reversed)
      - Unauthorized attempts were made, but no money was collected
      - Customer may have been charged NSF fees by their bank

   c) AUTOPAY_ACTIVE_PAYMENTS_COLLECTED
      - Autopay is on, and we successfully collected unauthorized payments
      - Most severe - actual unauthorized money collected after charge-off

KEY FIELDS TO UNDERSTAND:

- IS_REVERSED = 1: Payment was collected but later reversed (failed)
- IS_REJECTED = 1: Payment was rejected (NSF, insufficient funds)
- IS_ACTIVE = 1 AND IS_REVERSED = 0: Payment was successful and still active

- PLACEMENT_STATUS: Which collection agency has the loan
  (Bounce, First Tech FCU, Resurgent, etc.)

- Settlement placements are EXCLUDED because those may have authorized payment plans

================================================================================
*/
