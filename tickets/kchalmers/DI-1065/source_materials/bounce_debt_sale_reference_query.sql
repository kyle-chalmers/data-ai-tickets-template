/*TODO: Rewrite the query to point all data sources to combined LoanPro and CLS data (or only LoanPro if it is the only relevant data source
todo: Investigate if there is an OTHER transactions data source and adjustments data source in LoanPro that can be brought in - may need to combine CLS data and LoanPro data for this if these "other" transactions were not migrated into LoanPro
TODO: Add in the filter so only the loans that were selected in the debt sale population query are selected
*/

---- NOTE ADJUSTMENT DATEs are still being pulled from data_store.vw_loan_account
---- need to fix some TODO's in cte_all_payment_transaction
---- SWAP all DEVELOPMENT._TIN tables
use warehouse BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

create or replace table BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS AS
with cte_cls_current_pay_info as ( --- cls current payment data
    select distinct -- dupes in this set
        lower(la.lead_guid) as lead_guid
           ,LT.LASTPAYMENTDATE
           ,LT.LASTPAYMENTAMOUNT
           ,LT.ACCRUEDINTEREST
           ,LT.TERMSREMAINING
           ,LT.DAYSPASTDUE
           ,LA.LOAN_DELINQUENT_AMOUNT
           ,LT.NEXTPAYMENTDUEDATE
          ,LT.NEXTPRINCIPALAMOUNTDUE
          --- add to below cte
          ,LA.adjustment_date
           ,'CLS'
          -- select *
    from ARCA.FRESHSNOW.VW_CLS_LOAN_ACCOUNT_CURRENT as LA
             inner join ARCA.FRESHSNOW.VW_CLS_LOAN_TAPE as LT
                        on upper(LA.PAYOFF_LOAN_ID) = upper(LT.LOANID)
                            and LT.LOANSOURCE = 'CLS'
    where ifnull(LA.MIGRATED_TO_LOANPRO, false) = false),
    cte_all_payment_transaction as (  --- there are a few todo fields in lp set
    SELECT CLS.NAME::VARCHAR AS TRANSACTION_ID
        ,lower(coalesce(va.payoff_uid, vl.lead_guid)) as lead_guid
        ,cls.LOAN_TRANSACTION_DATE
        ,cls.POSTED_DATE
        ,cls.LOAN_PAYMENT_TYPE
        ,cls.LOAN_PAYMENT_APPLICATION_MODE
        ,cls.LOAN_APPLIED_SPREAD
        ,cls.LOAN_TRANSACTION_AMOUNT
        ,cls.LOAN_PRINCIPAL
        ,cls.LOAN_INTEREST
        ,cls.LOAN_BALANCE
        ,cls.LOAN_REVERSED
        ,cls.LOAN_REJECTED
        ,cls.LOAN_CLEARED
        ,UPPER(cls.LOAN_WRITE_OFF_RECOVERY_PAYMENT::TEXT) AS LOAN_WRITE_OFF_RECOVERY_PAYMENT
        ,'CLS' AS SOURCE
    FROM
        BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_PAYMENT_TRANSACTION cls
        JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_LOAN_ACCOUNT vla -- left here to get the join key
            ON cls.HK_H_LOAN_ACCOUNT = vla.HK_H_LOAN_ACCOUNT
        LEFT JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION va
            on vla.HK_H_APPL = va.HK_H_APPL
        left join business_intelligence.analytics.vw_loan vl
            on vla.name = vl.loan_id
    UNION ALL
    SELECT
        LP.PAYMENT_ID::VARCHAR AS TRANSACTION_ID,
        lower(vl.LEAD_GUID) as LEAD_GUID
        ,lp.TRANSACTION_DATE as LOAN_TRANSACTION_DATE
        ,--TO_DATE(STATUS_DATES:"SETTLED SUCCESSFULLY"::string)
            LP.APPLY_DATE AS POSTED_DATE  ---- no posted date in new view
        ,lp.PAYMENT_TYPE as LOAN_PAYMENT_TYPE
        ,'' AS LOAN_PAYMENT_APPLICATION_MODE -- TODO
        ,'' AS LOAN_APPLIED_SPREAD -- TODO
        ,lp.TRANSACTION_AMOUNT as LOAN_TRANSACTION_AMOUNT
        ,lp.PRINCIPAL_AMOUNT as LOAN_PRINCIPAL
        ,lp.INTEREST_AMOUNT as LOAN_INTEREST
        ,lp.AFTER_PRINCIPAL_BALANCE as LOAN_BALANCE
        ,lp.IS_REVERSED as LOAN_REVERSED
        ,lp.IS_REJECTED as LOAN_REJECTED
        ,lp.IS_SETTLED as LOAN_CLEARED
        ,'' AS  LOAN_WRITE_OFF_RECOVERY_PAYMENT -- TODO!!!!
        ,'LP' AS SOURCE
    FROM
        BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION lp
        join business_intelligence.analytics.vw_loan vl
            on UPPER(lp.loan_id::TEXT) = UPPER(vl.loan_id::TEXT)
    WHERE
        IS_MIGRATED = 0 -- only care about non-migrated loans in this union set; migrated on should be taken care of in top union set
)
,LOAN_OTHER_TRANSACTION AS ( -- NOT DONE -- COME BACK
    select A.ID::VARCHAR AS TRANSACTION_ID,
       LOWER(B.LEAD_GUID) AS PAYOFFUID,
       UPPER(b.PAYOFF_LOAN_ID)                     AS LOANID,
       DATE(SPLIT_PART(A.LOAN__TXN_DATE__C,' ',1)) AS LOAN_TRANSACTION_DATE,
       DATE(SPLIT_PART(A.LOAN__TXN_DATE__C,' ',1)) AS EFFECTIVE_DATE,
       LOAN__TRANSACTION_TYPE__C AS LOAN_TRANSACTION_TYPE,
    -- No need for 'Interest Accrual','Recurring ACH', 'Start Accrual', 'Stop Accrual', 'Stop Accrual Entries', 'Stop Recurring ACH'
        CASE LOAN__TRANSACTION_TYPE__C WHEN 'Reschedule' THEN CONCAT('Reschedule :',a.LOAN__DESCRIPTION__C)
            WHEN 'Charge Off' THEN
                                CONCAT('Charge off with principal of ',TO_VARCHAR(a.LOAN__CHARGED_OFF_PRINCIPAL__C),' and interest of ',TO_VARCHAR(a.LOAN__CHARGED_OFF_INTEREST__C),'.')
            WHEN 'Cancel One Time ACH' THEN
                                CONCAT('Cancel One Time ACH for ',TO_VARCHAR(a.LOAN__PAYMENT_AMOUNT__C),'for ACH Debit Date of ',TO_VARCHAR(SPLIT_PART(LOAN__OT_ACH_DEBIT_DATE__C,' ',1)))
            WHEN 'Charge Off Reversal' THEN
                                CONCAT('Charge off reversal of charged off principal of ',TO_VARCHAR(a.LOAN__CHARGED_OFF_PRINCIPAL__C),' and charged off interest of ',TO_VARCHAR(a.LOAN__CHARGED_OFF_INTEREST__C),'.')
            WHEN 'Contingency Status Change' THEN
                                CONCAT('Contingency status code change from ',a.LOAN__OLD_CONTINGENCY_STATUS__C,' to ',a.LOAN__NEW_CONTINGENCY_STATUS__C,'.')
            WHEN 'Interest Waive' THEN
                                CONCAT('Waived interest of ',TO_VARCHAR(a.LOAN__WAIVED_INTEREST__C))
            WHEN 'PayOff Quote Generation' THEN
                                CONCAT('PayOff quote generation with Pay Off Date of ',TO_VARCHAR(SPLIT_PART(a.LOAN__PAY_OFF_DATE__C,' ',1)))
            WHEN 'PrincipalAdjustment-Subtract' THEN
                                a.LOAN__DESCRIPTION__C
            WHEN 'Rate Change' THEN
                                CONCAT('Rate Change to new interest rate of ',TO_VARCHAR(a.LOAN__NEW_INTEREST_RATE__C))
            ELSE LOAN__TRANSACTION_TYPE__C
        END AS DESCRIPTION,
        a.LOAN__TXN_AMT__C as LOAN_TRANSACTION_AMOUNT,
        FALSE AS PAYMENT_FLAG,
        NULL AS LOAN_PRINCIPAL,
        NULL AS LOAN_INTEREST,
        a.LOAN__LOAN_AMOUNT__C AS STARTING_BALANCE,
        a.LOAN__PRINCIPAL_REMAINING__C AS ENDING_BALANCE,
        IFF(LOAN_TRANSACTION_DATE>=C.CHARGEOFFDATE,TRUE,FALSE) AS POSTCHARGEOFFEVENT,
        IFF(a.LOAN__TRANSACTION_TYPE__C = 'Charge Off',TRUE,FALSE) AS CHARGEOFFEVENTIND,
        a.LOAN__REVERSED__C AS LOAN_REVERSED,
        a.LOAN__REJECTED__C AS LOAN_REJECTED,
        CASE WHEN a.LOAN__REVERSED__C OR a.LOAN__REJECTED__C THEN FALSE ELSE TRUE END AS LOAN_CLEARED
     FROM
        RAW_DATA_STORE.SALESFORCE.LOAN_OTHER_TRANSACTION A
        INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_LOAN_ACCOUNT B
            ON A.LOAN__LOAN_ACCOUNT__C = B.ID
        INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE C
            ON LOWER(B.LEAD_GUID) = C.PAYOFFUID
        -- LEFT JOIN SCRA_INTEREST_RATE_FINAL M
        --     ON LOWER(B.LEAD_GUID) = M.PAYOFFUID
    WHERE 1=1
        and a.ISDELETED <> TRUE
        qualify row_number() over (partition by a.NAME order by a.DSS_LOAD_DATE desc) = 1)
,CASH_TRANSACTION AS ( -- NOT DONE -- COME BACK
------------------------- NEW -------------------------
----------  new , VW_LOAN_PAYMENT_TXN.LOAN_PAYMENT_APPLICATION_MODE and VW_LOAN_PAYMENT_TXN.LOAN_APPLIED_SPREAD, VW_LOAN_PAYMENT_TXN.LOAN_WRITE_OFF_RECOVERY_PAYMENT needs to be found.
---------- 2 columns need to be fixed in this cte, with the listed above fields to be found
    SELECT A.TRANSACTION_ID
        ,LOWER(clc.LEAD_GUID) AS PAYOFFUID
        ,clc.LOANID
        ,a.LOAN_TRANSACTION_DATE
        ,a.POSTED_DATE AS EFFECTIVE_DATE
        ,'Payment' AS LOAN_TRANSACTION_TYPE
        ,CONCAT(a.LOAN_PAYMENT_TYPE,' ',a.LOAN_PAYMENT_APPLICATION_MODE,': ',a.LOAN_APPLIED_SPREAD) as DESCRIPTION
        ,a.LOAN_TRANSACTION_AMOUNT
        ,TRUE AS PAYMENT_FLAG
        ,a.LOAN_PRINCIPAL
        ,a.LOAN_INTEREST
        ,ROUND(A.LOAN_BALANCE + A.LOAN_PRINCIPAL, 2) AS STARTING_BALANCE
        ,a.LOAN_BALANCE                              AS ENDING_BALANCE
        ,IFF(a.LOAN_WRITE_OFF_RECOVERY_PAYMENT = 'TRUE' OR a.LOAN_TRANSACTION_DATE > clc.CHARGEOFFDATE,TRUE,FALSE) AS POSTCHARGEOFFEVENT
        ,FALSE AS CHARGEOFFEVENTIND
        ,a.LOAN_REVERSED
        ,a.LOAN_REJECTED
        ,a.LOAN_CLEARED
    FROM
        BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE clc
        LEFT JOIN cte_all_payment_transaction a
            on LOWER(clc.lead_guid) = LOWER(a.lead_guid))
,ADJUSTMENTS AS ( ----- Adjustment Date is still coming from VW_LOAN_ACCOUNT; need to capture more Bankruptcy, but otherwise done
--------------- NEW -----------------------------
    SELECT b.ID::VARCHAR AS TRANSACTION_ID,
        LOWER(B.LEAD_GUID) AS PAYOFFUID,
        UPPER(b.PAYOFF_LOAN_ID) AS LOANID,
        coalesce(cls_pay.ADJUSTMENT_DATE, b.ADJUSTMENT_DATE) AS LOAN_TRANSACTION_DATE, --VW_CLS_LOAN_ACCOUNT_CURRENT	ADJUSTMENT_DATE
        coalesce(cls_pay.ADJUSTMENT_DATE, b.ADJUSTMENT_DATE)AS EFFECTIVE_DATE,  --VW_CLS_LOAN_ACCOUNT_CURRENT	ADJUSTMENT_DATE
        'Charged Off Principal Adjustment' AS LOAN_TRANSACTION_TYPE,
        CONCAT('Charged off principal adjustment on ', coalesce(cls_pay.ADJUSTMENT_DATE, b.ADJUSTMENT_DATE) ::VARCHAR,' for ',clc.CHARGED_OFF_PRINCIPAL_ADJUSTMENT::VARCHAR) as DESCRIPTION,
        clc.CHARGED_OFF_PRINCIPAL_ADJUSTMENT AS LOAN_TRANSACTION_AMOUNT,
        FALSE AS PAYMENT_FLAG,
        clc.CHARGED_OFF_PRINCIPAL_ADJUSTMENT AS LOAN_PRINCIPAL, -- clac.CHARGED_OFF_PRINCIPAL_ADJUSTMENT
        NULL AS LOAN_INTEREST,
        clc.PRINCIPALBALANCEATCHARGEOFF AS STARTING_BALANCE, --- ARCA_LOAN_BOOK	PRINCIPALBALANCEATCHARGEOFF
        clc.PRINCIPALBALANCEATCHARGEOFF - clc.CHARGED_OFF_PRINCIPAL_ADJUSTMENT AS ENDING_BALANCE,
        TRUE AS POSTCHARGEOFFEVENT,
        FALSE AS CHARGEOFFEVENTIND,
        FALSE AS LOAN_REVERSED,
        FALSE AS LOAN_REJECTED,
        TRUE AS LOAN_CLEARED
    FROM
        BUSINESS_INTELLIGENCE.DATA_STORE.VW_LOAN_ACCOUNT b -- still pulling ADJUSTMENT_DATE from here
        INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE clc
            ON LOWER(B.LEAD_GUID) = clc.LEAD_GUID
    left join cte_cls_current_pay_info cls_pay
              ON cls_pay.lead_guid = clc.LEAD_GUID
        -- LEFT JOIN SCRA_INTEREST_RATE_FINAL M
        --     ON LOWER(B.LEAD_GUID) = M.PAYOFFUID
    WHERE 1 = 1
        AND clc.CHARGED_OFF_PRINCIPAL_ADJUSTMENT IS NOT NULL)
,RECOVERIES_BEFORE_ADJUSTMENTS AS (
    select
        SUM(A.LOAN_TRANSACTION_AMOUNT) AS RECOVERIES_BEFORE_ADJUSTMENT
        , lower(A.PAYOFFUID) as  PAYOFFUID
    from
        CASH_TRANSACTION A
        INNER JOIN ADJUSTMENTS B
            ON A.PAYOFFUID = B.PAYOFFUID
            AND B.LOAN_TRANSACTION_DATE >= A.LOAN_TRANSACTION_DATE
    where
        A.POSTCHARGEOFFEVENT AND CONTAINS(A.DESCRIPTION,'Write-Off')
    GROUP BY
        A.PAYOFFUID)
,ADJUSTMENTS_WITH_BALANCES_ACCOUNTING_FOR_RECOVERIES AS (
    SELECT A.TRANSACTION_ID,
        lower(A.PAYOFFUID) as PAYOFFUID
        ,A.LOANID
        ,A.LOAN_TRANSACTION_DATE
        ,A.EFFECTIVE_DATE
        ,A.LOAN_TRANSACTION_TYPE
        ,A.DESCRIPTION
        ,A.LOAN_TRANSACTION_AMOUNT
        ,A.PAYMENT_FLAG
        ,A.LOAN_PRINCIPAL
        ,A.LOAN_INTEREST
        ,(A.STARTING_BALANCE - B.RECOVERIES_BEFORE_ADJUSTMENT) AS STARTING_BALANCE
        ,(A.ENDING_BALANCE - B.RECOVERIES_BEFORE_ADJUSTMENT) AS ENDING_BALANCE
        ,A.POSTCHARGEOFFEVENT
        ,A.CHARGEOFFEVENTIND
        ,A.LOAN_REVERSED
        ,A.LOAN_REJECTED
        ,A.LOAN_CLEARED
    FROM
        ADJUSTMENTS A
        LEFT JOIN RECOVERIES_BEFORE_ADJUSTMENTS B
            ON A.PAYOFFUID = B.PAYOFFUID
)
SELECT DISTINCT
    A.*
        ,clc.LOAN_CURRENT_PLACEMENT ---lclsc.PLACEMENT_STATUS
        ,clc.BANKRUPTCYCHAPTER
        ,clc.BANKRUPTCY_STATUS --lclsc.BANKRUPTCY_STATUS
        ,clc.DISCHARGE_DATE -- coalesce(lclsc.DISCHARGE_DATE, clac.DISCHARGE_DATE)
        ,clc.SCRAFLAG  --VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT	SCRA_FLAG
        ,clc.LASTPAYMENTDATE  --cte_loan_current
        ,clc.CHARGEOFFDATE
        ,clc.PORTFOLIONAME
        ,clc.UNPAIDBALANCEDUE -- first 3 from DATA_STORE.MVW_LOAN_TAPE_MONTHLY
        ,fsdl.is_deceased
        ,fsdl.is_fraud
      -- ,vl.loan_closed_date
FROM
    (
        SELECT * FROM LOAN_OTHER_TRANSACTION
            UNION
        SELECT * FROM CASH_TRANSACTION
            UNION
        SELECT * FROM ADJUSTMENTS_WITH_BALANCES_ACCOUNTING_FOR_RECOVERIES
    ) a
inner join BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE clc
    on clc.LOANID = a.LOANID
left join development._tin.fraud_scra_decease_lookup fsdl
    on fsdl.payoffuid = a.payoffuid
where 1=1 --vl.loan_closed_date is null
order by payoffuid, loan_transaction_date, effective_date;




-- ===========================
--THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS
SELECT *
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS;

-- ===========================
--QC_DUPE_TRANSACTION_ID_CHECK
SELECT COUNT(*) AS ROW_COUNT,
A.TRANSACTION_ID,
A.LOANID
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS A
GROUP BY ALL
HAVING ROW_COUNT > 1
ORDER BY 1 DESC;

-- ===========================
--QC_DUPE_TRANSACTION_ID_CHECK_DETAIL
WITH DUPES AS (SELECT COUNT(*) AS ROW_COUNT,
A.TRANSACTION_ID,
A.LOANID
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS A
GROUP BY ALL
HAVING ROW_COUNT > 1)
SELECT A.*
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS A
INNER JOIN DUPES B
ON A.TRANSACTION_ID = B.TRANSACTION_ID AND A.LOANID = B.LOANID
ORDER BY A.TRANSACTION_ID ;

-- ===========================
--TOTAL_COUNT_QC_CHECK
SELECT COUNT(*) AS ROW_COUNT,
COUNT(DISTINCT LOANID) AS DISTINCT_LOANID_COUNT,
COUNT(DISTINCT PAYOFFUID) AS DISTINCT_PAYOFFUID_COUNT,
COUNT(DISTINCT TRANSACTION_ID) AS DISTINCT_transaction_id_COUNT
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS;

--THEOREM_DEBT_SALE_Q1_2025_SALE
SELECT COUNT(*) AS ROW_COUNT,
COUNT(DISTINCT LOANID) AS DISTINCT_LOANID_COUNT
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE;