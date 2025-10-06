/*
================================================================================
DI-1254: BK Sale Evaluation for Resurgent - Transaction File
================================================================================

BUSINESS CONTEXT:
Generate transaction history for loans in the BK sale evaluation population.
Includes payments, other transactions (chargeoffs, rate changes), and adjustments.

PREREQUISITES:
Must run 1_bk_debt_sale_population.sql first to create the base population table.

TRANSACTION TYPES:
1. Payment Transactions - All payment activity
2. Loan Other Transactions - Chargeoffs, rate changes, waivers, etc.
3. Adjustments - Charged-off principal adjustments

================================================================================
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS AS

-- ============================================================================
-- Payment Transactions
-- ============================================================================
WITH cte_payment_transactions AS (
    SELECT
        pt.PAYMENT_ID::VARCHAR AS TRANSACTION_ID,
        LOWER(pop.LEAD_GUID) AS PAYOFFUID,
        pop.LOANID,
        pt.TRANSACTION_DATE AS LOAN_TRANSACTION_DATE,
        pt.APPLY_DATE AS POSTED_DATE,
        'Payment' AS LOAN_TRANSACTION_TYPE,
        CONCAT(
            pt.PAYMENT_TYPE,
            ' - Amount: $', pt.TRANSACTION_AMOUNT,
            ' (Principal: $', pt.PRINCIPAL_AMOUNT,
            ', Interest: $', pt.INTEREST_AMOUNT, ')'
        ) AS DESCRIPTION,
        pt.TRANSACTION_AMOUNT AS LOAN_TRANSACTION_AMOUNT,
        TRUE AS PAYMENT_FLAG,
        pt.PRINCIPAL_AMOUNT AS LOAN_PRINCIPAL,
        pt.INTEREST_AMOUNT AS LOAN_INTEREST,
        pt.BEFORE_PRINCIPAL_BALANCE AS STARTING_BALANCE,
        pt.AFTER_PRINCIPAL_BALANCE AS ENDING_BALANCE,
        IFF(pt.TRANSACTION_DATE > pop.CHARGEOFFDATE, TRUE, FALSE) AS POSTCHARGEOFFEVENT,
        FALSE AS CHARGEOFFEVENTIND,
        pt.IS_REVERSED AS LOAN_REVERSED,
        pt.IS_REJECTED AS LOAN_REJECTED,
        pt.IS_SETTLED AS LOAN_CLEARED

    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025 pop
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION pt
        ON pop.LP_LOAN_ID::TEXT = pt.LOAN_ID::TEXT
),

-- ============================================================================
-- Loan Other Transactions (Chargeoffs, Rate Changes, etc.)
-- ============================================================================
cte_other_transactions AS (
    SELECT
        lot.ID::VARCHAR AS TRANSACTION_ID,
        LOWER(pop.LEAD_GUID) AS PAYOFFUID,
        pop.LOANID,
        DATE(SPLIT_PART(lot.LOAN__TXN_DATE__C, ' ', 1)) AS LOAN_TRANSACTION_DATE,
        DATE(SPLIT_PART(lot.LOAN__TXN_DATE__C, ' ', 1)) AS POSTED_DATE,
        lot.LOAN__TRANSACTION_TYPE__C AS LOAN_TRANSACTION_TYPE,

        -- Detailed descriptions by transaction type
        CASE lot.LOAN__TRANSACTION_TYPE__C
            WHEN 'Charge Off' THEN
                CONCAT('Charge off with principal of $', lot.LOAN__CHARGED_OFF_PRINCIPAL__C,
                       ' and interest of $', lot.LOAN__CHARGED_OFF_INTEREST__C)
            WHEN 'Charge Off Reversal' THEN
                CONCAT('Charge off reversal - Principal: $', lot.LOAN__CHARGED_OFF_PRINCIPAL__C,
                       ', Interest: $', lot.LOAN__CHARGED_OFF_INTEREST__C)
            WHEN 'Interest Waive' THEN
                CONCAT('Waived interest of $', lot.LOAN__WAIVED_INTEREST__C)
            WHEN 'Rate Change' THEN
                CONCAT('Rate change to ', lot.LOAN__NEW_INTEREST_RATE__C, '%')
            WHEN 'Reschedule' THEN
                CONCAT('Reschedule: ', lot.LOAN__DESCRIPTION__C)
            WHEN 'Cancel One Time ACH' THEN
                CONCAT('Cancel One Time ACH for $', lot.LOAN__PAYMENT_AMOUNT__C,
                       ' for debit date ', SPLIT_PART(lot.LOAN__OT_ACH_DEBIT_DATE__C, ' ', 1))
            ELSE lot.LOAN__TRANSACTION_TYPE__C
        END AS DESCRIPTION,

        lot.LOAN__TXN_AMT__C AS LOAN_TRANSACTION_AMOUNT,
        FALSE AS PAYMENT_FLAG,
        NULL AS LOAN_PRINCIPAL,
        NULL AS LOAN_INTEREST,
        lot.LOAN__LOAN_AMOUNT__C AS STARTING_BALANCE,
        lot.LOAN__PRINCIPAL_REMAINING__C AS ENDING_BALANCE,
        IFF(DATE(SPLIT_PART(lot.LOAN__TXN_DATE__C, ' ', 1)) >= pop.CHARGEOFFDATE, TRUE, FALSE) AS POSTCHARGEOFFEVENT,
        IFF(lot.LOAN__TRANSACTION_TYPE__C = 'Charge Off', TRUE, FALSE) AS CHARGEOFFEVENTIND,
        lot.LOAN__REVERSED__C AS LOAN_REVERSED,
        lot.LOAN__REJECTED__C AS LOAN_REJECTED,
        CASE
            WHEN lot.LOAN__REVERSED__C OR lot.LOAN__REJECTED__C THEN FALSE
            ELSE TRUE
        END AS LOAN_CLEARED

    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025 pop
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON pop.LP_LOAN_ID::TEXT = vl.LOAN_ID::TEXT
    INNER JOIN RAW_DATA_STORE.LOANPRO.LOAN_OTHER_TRANSACTION lot
        ON vl.LOAN_ID::TEXT = lot.LOAN__LOAN_ACCOUNT__C::TEXT
    WHERE lot.ISDELETED <> TRUE
    QUALIFY ROW_NUMBER() OVER (PARTITION BY lot.NAME ORDER BY lot.DSS_LOAD_DATE DESC) = 1
)

-- ============================================================================
-- Combine All Transactions
-- ============================================================================
SELECT DISTINCT
    t.*,
    pop.LOAN_CURRENT_PLACEMENT,
    pop.BANKRUPTCY_STATUS,
    pop.BANKRUPTCYCHAPTER,
    pop.DISCHARGE_DATE,
    pop.SCRAFLAG,
    pop.DECEASED_INDICATOR,
    pop.FRAUD_INDICATOR,
    pop.PORTFOLIONAME,
    pop.UNPAIDBALANCEDUE,
    pop.CHARGEOFFDATE

FROM (
    SELECT * FROM cte_payment_transactions
    UNION ALL
    SELECT * FROM cte_other_transactions
) t

INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025 pop
    ON t.LOANID = pop.LOANID

ORDER BY
    t.PAYOFFUID,
    t.LOAN_TRANSACTION_DATE,
    t.POSTED_DATE;

-- ============================================================================
-- Query Results
-- ============================================================================
SELECT * FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS;
