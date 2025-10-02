/*******************************************************************************
DI-1246: Simplified Quality Control Validation
Purpose: Key quality checks for 1099-C review dataset
Created: 2025-10-02
*******************************************************************************/

-- Parameters
SET start_recovery_date = '2025-01-01';

WITH main_query_results AS (
    WITH latest_loan_tape AS (
        SELECT
            LOANID,
            PAYOFFUID AS LEAD_GUID,
            STATUS,
            CHARGEOFFDATE,
            PRINCIPALBALANCEATCHARGEOFF,
            LASTPAYMENTDATE,
            RECOVERYPAYMENTAMOUNT,
            PLACEMENT_STATUS,
            PLACEMENT_STATUS_STARTDATE
        FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
        WHERE ASOFDATE = (SELECT MAX(ASOFDATE) FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE)
    ),
    charged_off_loans AS (
        SELECT *
        FROM latest_loan_tape
        WHERE STATUS = 'Charge off'
          AND LASTPAYMENTDATE >= $start_recovery_date
    ),
    settled_in_full_loans AS (
        SELECT ds.LOAN_ID, ds.LEAD_GUID, ds.CURRENT_STATUS, ds.SETTLEMENTSTATUS,
               ds.SETTLEMENTAGREEMENTAMOUNT, ds.SETTLEMENT_COMPLETION_DATE
        FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT ds
        WHERE ds.CURRENT_STATUS = 'Closed - Settled in Full'
    ),
    bankruptcy_exclusions AS (
        SELECT DISTINCT vb.LOAN_ID, vl.LEAD_GUID
        FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
        INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON CAST(vb.LOAN_ID AS VARCHAR) = CAST(vl.LOAN_ID AS VARCHAR)
        WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y' AND vb.ACTIVE = 1
    ),
    combined_population AS (
        SELECT
            CAST(col.LOANID AS VARCHAR) AS LOAN_ID,
            col.CHARGEOFFDATE AS CHARGE_OFF_DATE,
            col.PRINCIPALBALANCEATCHARGEOFF AS CHARGE_OFF_PRINCIPAL,
            CAST(NULL AS VARCHAR) AS SETTLEMENT_AMOUNT,
            CAST(NULL AS VARCHAR) AS SETTLEMENT_STATUS,
            CAST(NULL AS DATE) AS SETTLEMENT_COMPLETION_DATE,
            col.LASTPAYMENTDATE AS LAST_PAYMENT_DATE,
            col.RECOVERYPAYMENTAMOUNT AS TOTAL_RECOVERY_AMOUNT,
            col.PLACEMENT_STATUS,
            col.PLACEMENT_STATUS_STARTDATE AS PLACEMENT_STATUS_START_DATE,
            'Charge Off' AS POPULATION_SOURCE,
            col.LEAD_GUID
        FROM charged_off_loans col
        LEFT JOIN bankruptcy_exclusions be ON LOWER(col.LEAD_GUID) = LOWER(be.LEAD_GUID)
        WHERE be.LEAD_GUID IS NULL

        UNION ALL

        SELECT
            CAST(sifl.LOAN_ID AS VARCHAR) AS LOAN_ID,
            lt.CHARGEOFFDATE AS CHARGE_OFF_DATE,
            lt.PRINCIPALBALANCEATCHARGEOFF AS CHARGE_OFF_PRINCIPAL,
            CAST(sifl.SETTLEMENTAGREEMENTAMOUNT AS VARCHAR) AS SETTLEMENT_AMOUNT,
            sifl.SETTLEMENTSTATUS AS SETTLEMENT_STATUS,
            sifl.SETTLEMENT_COMPLETION_DATE AS SETTLEMENT_COMPLETION_DATE,
            lt.LASTPAYMENTDATE AS LAST_PAYMENT_DATE,
            lt.RECOVERYPAYMENTAMOUNT AS TOTAL_RECOVERY_AMOUNT,
            lt.PLACEMENT_STATUS AS PLACEMENT_STATUS,
            lt.PLACEMENT_STATUS_STARTDATE AS PLACEMENT_STATUS_START_DATE,
            'Settled in Full' AS POPULATION_SOURCE,
            sifl.LEAD_GUID
        FROM settled_in_full_loans sifl
        INNER JOIN latest_loan_tape lt ON LOWER(sifl.LEAD_GUID) = LOWER(lt.LEAD_GUID)
        LEFT JOIN bankruptcy_exclusions be ON LOWER(sifl.LEAD_GUID) = LOWER(be.LEAD_GUID)
        WHERE be.LEAD_GUID IS NULL
          AND lt.LASTPAYMENTDATE >= $start_recovery_date
    )
    SELECT * FROM combined_population
)

-- QC Test Results
SELECT 'Test 1: Total Record Count' AS test_name, COUNT(*) AS result FROM main_query_results
UNION ALL
SELECT 'Test 2: Distinct Loan IDs' AS test_name, COUNT(DISTINCT LOAN_ID) AS result FROM main_query_results
UNION ALL
SELECT 'Test 3: Duplicate Loan IDs' AS test_name, COUNT(*) - COUNT(DISTINCT LOAN_ID) AS result FROM main_query_results
UNION ALL
SELECT 'Test 4: Charge Off Population' AS test_name, COUNT(*) AS result FROM main_query_results WHERE POPULATION_SOURCE = 'Charge Off'
UNION ALL
SELECT 'Test 5: Settled in Full Population' AS test_name, COUNT(*) AS result FROM main_query_results WHERE POPULATION_SOURCE = 'Settled in Full'
UNION ALL
SELECT 'Test 6: Records with Last Payment < 2025-01-01 (should be 0)' AS test_name, COUNT(*) AS result FROM main_query_results WHERE LAST_PAYMENT_DATE < '2025-01-01'
UNION ALL
SELECT 'Test 7: Null Last Payment Dates (should be 0)' AS test_name, COUNT(*) AS result FROM main_query_results WHERE LAST_PAYMENT_DATE IS NULL
UNION ALL
SELECT 'Test 8: Min Last Payment Date (as YYYYMMDD)' AS test_name, TO_NUMBER(TO_CHAR(MIN(LAST_PAYMENT_DATE), 'YYYYMMDD')) AS result FROM main_query_results
UNION ALL
SELECT 'Test 9: Max Last Payment Date (as YYYYMMDD)' AS test_name, TO_NUMBER(TO_CHAR(MAX(LAST_PAYMENT_DATE), 'YYYYMMDD')) AS result FROM main_query_results
UNION ALL
SELECT 'Test 10: Placement Status Summary - Placed HM' AS test_name, COUNT(*) AS result FROM main_query_results WHERE PLACEMENT_STATUS = 'Placed - HM'
UNION ALL
SELECT 'Test 11: Placement Status Summary - Placed Bounce' AS test_name, COUNT(*) AS result FROM main_query_results WHERE PLACEMENT_STATUS = 'Placed - Bounce'
UNION ALL
SELECT 'Test 12: Placement Status Summary - Other' AS test_name, COUNT(*) AS result FROM main_query_results WHERE PLACEMENT_STATUS NOT IN ('Placed - HM', 'Placed - Bounce')
ORDER BY test_name;
