/*******************************************************************************
DI-1246: 1099-C Data Review for Loans Settled in Full in 2025

Purpose: Generate list of loans for Collections team manual scrub in preparation
         for sending 1099-C tax forms

Data Criteria:
- Loan Status: 'Closed-Charged Off' OR 'Closed-Settled in Full'
- Exclude: Any accounts with Bankruptcy status
- Last Recovery Payment Date: On or after 1/1/2025

Requested Fields:
1.  Loan ID
2.  Charge Off Date
3.  Charge Off Principal
4.  Settlement Amount
5.  Settlement Status
6.  Settlement Completion Date
7.  Last Payment Date
8.  Total Recovery Amount Received
9.  Placement Status
10. Placement Status Start Date

Data Sources:
- BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE (recovery/payment data, placement)
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT (settlement data)
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY (bankruptcy exclusions)

Created: 2025-10-02
*******************************************************************************/

-- Parameters
SET start_recovery_date = '2025-01-01';

-- Main Query
WITH latest_loan_tape AS (
    -- Get latest loan tape data with recovery payment information
    SELECT
        LOANID,
        PAYOFFUID AS LEAD_GUID,
        STATUS,
        CHARGEOFFDATE,
        PRINCIPALBALANCEATCHARGEOFF,
        LASTPAYMENTDATE,
        RECOVERYPAYMENTAMOUNT,
        PLACEMENT_STATUS,
        PLACEMENT_STATUS_STARTDATE,
        ASOFDATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
    WHERE ASOFDATE = (SELECT MAX(ASOFDATE) FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE)
),

charged_off_loans AS (
    -- Filter to loans with Charge Off status and recovery payments in 2025
    SELECT *
    FROM latest_loan_tape
    WHERE STATUS = 'Charge off'
      AND LASTPAYMENTDATE >= $start_recovery_date
),

settled_in_full_loans AS (
    -- Get loans with Closed - Settled in Full status
    SELECT
        ds.LOAN_ID,
        ds.LEAD_GUID,
        ds.CURRENT_STATUS,
        ds.SETTLEMENTSTATUS,
        ds.SETTLEMENTAGREEMENTAMOUNT,
        ds.SETTLEMENT_COMPLETION_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT ds
    WHERE ds.CURRENT_STATUS = 'Closed - Settled in Full'
),

bankruptcy_exclusions AS (
    -- Identify loans with active bankruptcy status to exclude
    -- Using MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y' to exclude only active bankruptcies
    SELECT DISTINCT
        vb.LOAN_ID,
        vl.LEAD_GUID
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON CAST(vb.LOAN_ID AS VARCHAR) = CAST(vl.LOAN_ID AS VARCHAR)
    WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y'
      AND vb.ACTIVE = 1
),

combined_population AS (
    -- Combine charged-off loans with recovery payments
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
        'Charge Off' AS POPULATION_SOURCE
    FROM charged_off_loans col
    LEFT JOIN bankruptcy_exclusions be ON LOWER(col.LEAD_GUID) = LOWER(be.LEAD_GUID)
    WHERE be.LEAD_GUID IS NULL  -- Exclude bankruptcy accounts

    UNION ALL

    -- Add settled in full loans with recovery payments
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
        'Settled in Full' AS POPULATION_SOURCE
    FROM settled_in_full_loans sifl
    INNER JOIN latest_loan_tape lt ON LOWER(sifl.LEAD_GUID) = LOWER(lt.LEAD_GUID)
    LEFT JOIN bankruptcy_exclusions be ON LOWER(sifl.LEAD_GUID) = LOWER(be.LEAD_GUID)
    WHERE be.LEAD_GUID IS NULL  -- Exclude bankruptcy accounts
      AND lt.LASTPAYMENTDATE >= $start_recovery_date
)

-- Final Output
SELECT
    cp.LOAN_ID,
    cp.CHARGE_OFF_DATE,
    cp.CHARGE_OFF_PRINCIPAL,
    cp.SETTLEMENT_AMOUNT,
    cp.SETTLEMENT_STATUS,
    cp.SETTLEMENT_COMPLETION_DATE,
    cp.LAST_PAYMENT_DATE,
    cp.TOTAL_RECOVERY_AMOUNT,
    cp.PLACEMENT_STATUS,
    cp.PLACEMENT_STATUS_START_DATE,
    cp.POPULATION_SOURCE
FROM combined_population cp
ORDER BY cp.LAST_PAYMENT_DATE DESC, cp.LOAN_ID;
