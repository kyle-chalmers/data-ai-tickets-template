/*
DI-1253: Insert Missing LP Transaction
Script to insert the missing LP payment transaction (ID: 2883224) into the UPDATE table

Missing Transaction Details:
- TRANSACTION_ID: 2883224
- LOANID: P13CB8C80E087
- LOAN_TRANSACTION_DATE: 2025-03-03
- This is an LP payment that was filtered out during the UPDATE table creation
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Insert the missing LP payment transaction
INSERT INTO BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS_UPDATE (
    TRANSACTION_ID,
    PAYOFFUID,
    LOANID,
    LOAN_TRANSACTION_DATE,
    EFFECTIVE_DATE,
    LOAN_TRANSACTION_TYPE,
    DESCRIPTION,
    LOAN_TRANSACTION_AMOUNT,
    PAYMENT_FLAG,
    LOAN_PRINCIPAL,
    LOAN_INTEREST,
    STARTING_BALANCE,
    ENDING_BALANCE,
    POSTCHARGEOFFEVENT,
    CHARGEOFFEVENTIND,
    LOAN_REVERSED,
    LOAN_REJECTED,
    LOAN_CLEARED,
    LOAN_CURRENT_PLACEMENT,
    PLACEMENT_STATUS_STARTDATE,
    LASTPAYMENTDATE,
    CHARGEOFFDATE,
    PORTFOLIONAME,
    UNPAIDBALANCEDUE,
    SOURCE,
    CLS_TRANSACTION_DATE,
    LP_APPLY_DATE
)
VALUES (
    '2883224',                                          -- TRANSACTION_ID
    '6977c56d-6c11-400e-84f0-13cb8c80e087',            -- PAYOFFUID
    'P13CB8C80E087',                                    -- LOANID
    '2025-03-03'::DATE,                                 -- LOAN_TRANSACTION_DATE
    '2025-03-04'::TIMESTAMP_NTZ,                        -- EFFECTIVE_DATE
    'Payment',                                          -- LOAN_TRANSACTION_TYPE
    'Regular : ',                                       -- DESCRIPTION
    480.31,                                             -- LOAN_TRANSACTION_AMOUNT
    TRUE,                                               -- PAYMENT_FLAG
    0.0,                                                -- LOAN_PRINCIPAL
    480.31,                                             -- LOAN_INTEREST
    11511.88,                                           -- STARTING_BALANCE
    11511.88,                                           -- ENDING_BALANCE
    TRUE,                                               -- POSTCHARGEOFFEVENT
    FALSE,                                              -- CHARGEOFFEVENTIND
    TRUE,                                               -- LOAN_REVERSED
    FALSE,                                              -- LOAN_REJECTED
    FALSE,                                              -- LOAN_CLEARED
    'Placed - First Tech Credit Union',                -- LOAN_CURRENT_PLACEMENT
    '2025-03-03'::DATE,                                 -- PLACEMENT_STATUS_STARTDATE
    '2024-08-05'::DATE,                                 -- LASTPAYMENTDATE
    '2025-01-02'::DATE,                                 -- CHARGEOFFDATE
    'Payoff FBO First Technology Credit Union',        -- PORTFOLIONAME
    12235.16,                                           -- UNPAIDBALANCEDUE
    'LP',                                               -- SOURCE
    NULL,                                               -- CLS_TRANSACTION_DATE
    '2025-03-04'::DATE                                  -- LP_APPLY_DATE
);

-- ===========================
-- VALIDATION QUERIES
-- ===========================

-- 1. Verify the transaction was inserted
SELECT
    'Transaction Inserted' as STATUS,
    COUNT(*) as COUNT
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS_UPDATE
WHERE TRANSACTION_ID = '2883224' AND LOANID = 'P13CB8C80E087';

-- 2. Compare record counts after insert
SELECT
    'ORIGINAL' as TABLE_NAME,
    COUNT(*) as TOTAL_RECORDS,
    COUNT(DISTINCT LOANID) as DISTINCT_LOANS
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS

UNION ALL

SELECT
    'UPDATE_AFTER_INSERT' as TABLE_NAME,
    COUNT(*) as TOTAL_RECORDS,
    COUNT(DISTINCT LOANID) as DISTINCT_LOANS
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS_UPDATE;

-- 3. Verify both tables now have the same transactions
SELECT
    CASE
        WHEN orig_count = upd_count THEN 'MATCH'
        ELSE 'MISMATCH'
    END as STATUS,
    orig_count as ORIGINAL_COUNT,
    upd_count as UPDATE_COUNT,
    orig_count - upd_count as DIFFERENCE
FROM (
    SELECT
        (SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS) as orig_count,
        (SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS_UPDATE) as upd_count
);
