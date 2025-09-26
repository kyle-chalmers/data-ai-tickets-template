/*
DI-1141: Sale Files for Bounce - Q2 2025 Sale
OPTIMIZED Main debt sale population query - LOAN LEVEL REPORT

OPTIMIZATIONS MADE:
1. Moved main WHERE filters to top of query to reduce data volume early
2. Pre-filtered loan tape to Q2 2025 charged off loans only
3. Eliminated redundant CTEs and complex calculations in intermediate steps
4. Simplified JOIN strategy by filtering base dataset first
5. Reduced column selection in intermediate CTEs
6. Optimized window functions with better partitioning
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Q2 2025 chargeoff date range variables
SET start_chargeoffdate = '2025-04-01';
SET end_chargeoffdate = '2025-06-30';

CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE AS
WITH base_charged_off_loans AS (
    -- OPTIMIZATION: Pre-filter to Q2 2025 charged off loans only to reduce all downstream processing
    SELECT A.*
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY A
    WHERE 1=1
        -- Apply all main filters up front
        AND DATE_TRUNC('month',A.ASOFDATE) = DATE_TRUNC('month',DATEADD('month',-1,current_date))
        AND A.STATUS = 'Charge off'
        AND DATE_TRUNC('month',A.CHARGEOFFDATE) >= DATE_TRUNC('month',DATE($start_chargeoffdate))
        AND DATE_TRUNC('month',A.CHARGEOFFDATE) <= DATE_TRUNC('month',DATE($end_chargeoffdate))
        AND A.RECOVERIESPAIDTODATE < A.PRINCIPALBALANCEATCHARGEOFF -- Exclude fully recovered
)
,loan_settings_filtered AS (
    -- OPTIMIZATION: Only get settings for our target population
    SELECT lclsc.*, vl.member_id
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT lclsc
    INNER JOIN base_charged_off_loans bcol
        ON upper(bcol.PAYOFFUID) = upper(lclsc.lead_guid)
    LEFT JOIN business_intelligence.analytics.vw_loan vl
        ON lower(vl.lead_guid) = lower(lclsc.lead_guid)
)
,bankruptcy_data_filtered AS (
    -- OPTIMIZATION: Pre-filter bankruptcy data to target population only
    SELECT bdsl.*
    FROM development._tin.bankruptcy_debt_suspend_lookup bdsl
    INNER JOIN base_charged_off_loans bcol
        ON upper(bcol.PAYOFFUID) = upper(bdsl.payoffuid)
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY bdsl.PAYOFFUID 
        ORDER BY bdsl.FILE_DATE DESC NULLS LAST, 
                 bdsl.POC_DEADLINE_DATE DESC NULLS LAST, 
                 bdsl.POC_COMPLETED_DATE DESC NULLS LAST
    ) = 1
)
,fraud_data_filtered AS (
    -- OPTIMIZATION: Pre-filter fraud data to target population
    SELECT fsdl.*
    FROM development._tin.fraud_scra_decease_lookup fsdl
    INNER JOIN base_charged_off_loans bcol
        ON upper(bcol.PAYOFFUID) = upper(fsdl.payoffuid)
)
,delinquency_dates AS (
    -- OPTIMIZATION: Only calculate delinquency dates for target loans
    SELECT 
        MLTDH.PAYOFFUID,
        MIN(MLTDH.ASOFDATE) AS DATEOFFIRSTDELINQUENCY,
        MAX(CASE WHEN MLTDH.DAYSPASTDUE = 30 THEN MLTDH.ASOFDATE END) AS MOST_RECENT_DELINQUENCY_DATE
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY MLTDH
    INNER JOIN base_charged_off_loans bcol
        ON MLTDH.PAYOFFUID = bcol.PAYOFFUID
    WHERE MLTDH.DAYSPASTDUE >= 30
    GROUP BY MLTDH.PAYOFFUID
)
,payment_history AS (
    -- OPTIMIZATION: Pre-filter payment transactions to target loans only
    SELECT
        LOWER(bcol.PAYOFFUID) AS PAYOFFUID,
        SUM(CASE 
            WHEN pt.IS_SETTLED AND NOT pt.is_REVERSED AND NOT pt.is_REJECTED 
            THEN pt.TRANSACTION_AMOUNT ELSE 0 
        END) as TOTALPAYMENTTRANSACTIONSAMOUNT,
        COUNT(CASE 
            WHEN pt.IS_SETTLED AND NOT pt.is_REVERSED AND NOT pt.is_REJECTED 
            THEN 1 
        END) as NUMBEROFPAYMENTTRANSACTIONS,
        COUNT(CASE WHEN pt.is_REVERSED OR pt.is_rejected THEN 1 END) as NUMBEROFPAYMENTSREVERSEDORREJECTED,
        SUM(CASE 
            WHEN pt.IS_SETTLED AND NOT pt.is_REVERSED AND NOT pt.is_REJECTED
                 AND pt.TRANSACTION_DATE >= COALESCE(bd.POC_COMPLETED_DATE, '2099-01-01'::DATE)
            THEN pt.TRANSACTION_AMOUNT ELSE 0 
        END) AS PAYMENTSAMOUNTAFTERPOCCOMPLETEDDATE,
        COUNT(CASE 
            WHEN pt.IS_SETTLED AND NOT pt.is_REVERSED AND NOT pt.is_REJECTED
                 AND pt.TRANSACTION_DATE >= COALESCE(bd.POC_COMPLETED_DATE, '2099-01-01'::DATE)
            THEN 1 
        END) AS PAYMENTSAFTERPOCCOMPLETEDDATE
    FROM base_charged_off_loans bcol
    INNER JOIN loan_settings_filtered lsf
        ON bcol.PAYOFFUID = LOWER(lsf.LEAD_GUID)
    LEFT JOIN bankruptcy_data_filtered bd
        ON LOWER(lsf.LEAD_GUID) = bd.payoffuid
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION pt
        ON pt.LOAN_ID::text = lsf.LOAN_ID::text
    GROUP BY bcol.PAYOFFUID
)
,bankruptcy_principal_remaining AS (
    -- OPTIMIZATION: Only calculate for loans with bankruptcy data
    SELECT 
        bcol.PAYOFFUID,
        bd.FILE_DATE AS BANKRUPTCYFILEDATE,
        CASE 
            WHEN bcol.CHARGEOFFDATE IS NULL THEN bcol.REMAININGPRINCIPAL
            ELSE bcol.PRINCIPALBALANCEATCHARGEOFF - COALESCE(bcol.RECOVERIESPAIDTODATE, 0)
        END AS PRINCIPALREMAININGATFILING
    FROM base_charged_off_loans bcol
    INNER JOIN bankruptcy_data_filtered bd
        ON bcol.PAYOFFUID = LOWER(bd.payoffuid)
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY tdh
        ON bcol.PAYOFFUID = tdh.PAYOFFUID 
        AND tdh.ASOFDATE <= bd.FILE_DATE
    WHERE bd.FILE_DATE IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY bcol.PAYOFFUID 
        ORDER BY tdh.ASOFDATE DESC
    ) = 1
)
,settlement_setup_portfolio AS (
    -- OPTIMIZATION: Pre-filter settlement setup portfolio to target loans only  
    SELECT lpsp.LOAN_ID, TRUE AS SETTLEMENT_SETUP_PORTFOLIO, lpsp.CREATED AS SETTLEMENT_SETUP_PORTFOLIO_CREATED_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
    INNER JOIN business_intelligence.analytics.vw_loan vl
        ON lpsp.LOAN_ID = vl.LOAN_ID
    INNER JOIN base_charged_off_loans bcol
        ON UPPER(vl.LEGACY_LOAN_ID) = UPPER(bcol.LOANID)
    WHERE lpsp.PORTFOLIO_CATEGORY = 'Settlement' AND lpsp.PORTFOLIO_NAME = 'Settlement Setup'
)
,settlement_successful_portfolio AS (
    -- OPTIMIZATION: Pre-filter settlement successful portfolio to target loans only
    SELECT lpsp.LOAN_ID, TRUE AS SETTLEMENT_SUCCESSFUL_PORTFOLIO, lpsp.CREATED AS SETTLEMENT_SUCCESSFUL_PORTFOLIO_CREATED_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
    INNER JOIN business_intelligence.analytics.vw_loan vl
        ON lpsp.LOAN_ID = vl.LOAN_ID
    INNER JOIN base_charged_off_loans bcol
        ON UPPER(vl.LEGACY_LOAN_ID) = UPPER(bcol.LOANID)
    WHERE lpsp.PORTFOLIO_CATEGORY = 'Settlement' AND lpsp.PORTFOLIO_NAME = 'Settlement Successful'
)
,settled_in_full_sub_status AS (
    -- OPTIMIZATION: Pre-filter settled in full status to target loans only
    SELECT lsac.LOAN_ID, TRUE AS SETTLED_IN_FULL_STATUS_IND, lsac.DATE AS SETTLED_IN_FULL_STATUS_DATE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT lsac
    INNER JOIN business_intelligence.analytics.vw_loan vl
        ON lsac.LOAN_ID::VARCHAR = vl.LOAN_ID::VARCHAR
    INNER JOIN base_charged_off_loans bcol
        ON UPPER(vl.LEGACY_LOAN_ID) = UPPER(bcol.LOANID)
    WHERE lsac.LOAN_SUB_STATUS_TEXT = 'Closed - Settled in Full'
        AND lsac.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    QUALIFY ROW_NUMBER() OVER (PARTITION BY lsac.LOAN_ID ORDER BY lsac.DATE) = 1
)
-- Final optimized query with pre-filtered data
SELECT
    m_pii.first_name as FIRSTNAME,
    m_pii.last_name as LASTNAME,
    m_pii.SSN,
    m_pii.ADDRESS_1 as STREETADDRESS1,
    m_pii.ADDRESS_2 as STREETADDRESS2,
    m_pii.CITY,
    m_pii.STATE,
    m_pii.ZIP_CODE as ZIPCODE,
    m_pii.DATE_OF_BIRTH,
    m_pii.EMAIL,
    m_pii.PHONE_NUMBER as PHONENUMBER,
    A.PORTFOLIONAME,
    A.LOANID,
    (A.PRINCIPALBALANCEATCHARGEOFF + A.INTERESTBALANCEATCHARGEOFF
     - A.RECOVERIESPAIDTODATE - COALESCE(B.CHARGED_OFF_PRINCIPAL_ADJUSTMENT, 0) 
     - COALESCE(A.TOTALPRINCIPALWAIVED, 0)) AS UNPAIDBALANCEDUE,
    A.CHARGEOFFDATE,
    A.PRINCIPALBALANCEATCHARGEOFF,
    A.RECOVERIESPAIDTODATE,
    A.INTERESTBALANCEATCHARGEOFF,
    B.CHARGED_OFF_PRINCIPAL_ADJUSTMENT,
    A.INTERESTPAIDTODATE,
    A.PRINCIPALPAIDTODATE,
    A.LASTPAYMENTDATE,
    A.LASTPAYMENTAMOUNT,
    COALESCE(DD.DATEOFFIRSTDELINQUENCY, DATEADD(DAY, -90, A.CHARGEOFFDATE)) AS DATEOFFIRSTDELINQUENCY,
    COALESCE(DD.MOST_RECENT_DELINQUENCY_DATE, DATEADD(DAY, -90, A.CHARGEOFFDATE)) AS DATEOFMOSTRECENTDELINQUENCY,
    B.BANKRUPTCY_STATUS,
    B.CASE_NUMBER,
    B.CHAPTER AS BANKRUPTCYCHAPTER,
    COALESCE(B.ATTORNEY_NAME, B.FIRM_NAME,
        CASE WHEN B.CHAPTER IS NOT NULL OR B.FILE_DATE IS NOT NULL 
                  OR B.CASE_NUMBER IS NOT NULL OR B.BANKRUPTCY_STATUS IS NOT NULL
             THEN m_pii.first_name || ' ' || m_pii.last_name 
        END) AS NAMEOFFILINGPARTY,
    B.FILE_DATE AS BANKRUPTCYFILEDATE,
    CASE WHEN B.CHAPTER IS NOT NULL OR B.FILE_DATE IS NOT NULL 
              OR B.CASE_NUMBER IS NOT NULL OR B.BANKRUPTCY_STATUS IS NOT NULL
         THEN m_pii.FIRST_NAME || ' ' || m_pii.LAST_NAME 
    END AS BANKRUPTCYDEBTOR,
    BPR.PRINCIPALREMAININGATFILING,
    PH.PAYMENTSAMOUNTAFTERPOCCOMPLETEDDATE,
    PH.PAYMENTSAFTERPOCCOMPLETEDDATE,
    B.POC_REQUIRED,
    B.POC_DEADLINE_DATE,
    B.POC_COMPLETED_DATE,
    B.DISCHARGE_DATE,
    A.REASONFORDELINQUENCY AS CHARGEOFFREASON,
    B.SUSPEND_PHONE,
    B.SUSPEND_TEXT,
    B.SUSPEND_EMAIL,
    B.SUSPEND_LETTER,
    -- Core loan details
    A.ORIGINATIONDATE,
    A.INDIRECT_PURCHASEDATE,
    A.MATURITYDATE,
    A.LOANAMOUNT,
    A.TERM,
    A.INTERESTRATE,
    A.APR,
    A.EMPLOYMENTSTATUS,
    A.HOUSINGINFORMATION,
    A.ANNUALINCOME,
    A.BUREAUFICOSCORE,
    A.NDI,
    A.DTI,
    A.APPMOSSINCEDEROGPUBREC,
    A.FIRSTSCHEDULEDPAYMENTDATE,
    A.PAYMENTFREQUENCY,
    A.PAYMENTANNIVERSARYDATE,
    A.REGULARPAYMENTAMOUNT,
    A.TOTALPRINCIPALWAIVED,
    A.SECONDARY_BUYER,
    A.SECONDARY_SELLER,
    A.SECONDARY_PURCHASEDATE,
    A.SECONDARY_SOLDDATE,
    A.MLAFLAG,
    A.REFRESHEDFICOSCORE,
    A.REFRESHEDFICOSCOREDATE,
    A.CURRENTMATURITYDATE,
    A.LASTCOLLECTIONSCONTACTDATE,
    A.REASONFORDELINQUENCY,
    A.MODFLAG,
    A.PREVIOUSMODIFICATION,
    A.MODREQUESTDATE,
    A.STATUSPRIORTOMODIFICATION,
    A.LOANBALANCEATMODIFICATION,
    A.MODREASON,
    A.MODTYPE,
    A.MODSTARTDATE,
    A.MODENDDATE,
    A.MODPROCESSINGDATE,
    A.MODMATURITYDATE,
    A.MODINTERESTRATE,
    A.MODPAYMENTAMOUNT,
    A.NUMBERPAYMENTSDEFERRED,
    A.PAYMENTFORBEARANCEAMOUNT,
    A.BALLOONPAYMENT,
    A.MODTERMEXTENSION,
    A.SCRASTARTDATE,
    A.SCRAENDDATE,
    A.CPDFLAG,
    A.CPDPROCESSINGDATE,
    A.CPDANNIVERSARYDAY,
    A.INSURANCEFLAG,
    A.INSURANCESTARTDATE,
    A.INSURANCEENDDATE,
    A.LOAN_INTENT,
    -- Flags and indicators
    COALESCE(FD.IS_DECEASED, FALSE) AS DECEASED_INDICATOR,
    COALESCE(FD.is_fraud, FALSE) AS FRAUD_INDICATOR,
    CASE 
        WHEN A.SCRAFLAG = 'Y' THEN 'Y'
        WHEN FD.is_scra = TRUE THEN 'Y'
        ELSE 'N'
    END as SCRAFLAG,
    B.PLACEMENT_STATUS AS LOAN_CURRENT_PLACEMENT,
    CASE WHEN A.LASTPAYMENTDATE IS NULL THEN TRUE ELSE FALSE END AS FIRST_PAYMENT_DEFAULT_INDICATOR,
    B.DEBT_SETTLEMENT_STATUS,
    B.DEBT_SETTLEMENT_START AS DEBT_SETTLEMENT_START_DATE,
    B.APPROVED_SETTLEMENT_AMOUNT,
    B.DEBT_SETTLEMENT_PAYMENT_TERMS,
    B.DEBT_SETTLEMENT_PAYMENTS_EXPECTED,
    B.EXPECTED_PAYMENT_AMOUNT,
    B.DEBT_SETTLEMENT_COMPANY,
    B.DEBT_SETTLEMENT_CONTACTED_BY,
    B.CEASE_AND_DESIST,
    -- Additional fields for compatibility  
    vl.loan_closed_date,
    lower(vl.lead_guid) as lead_guid,
    vl.loan_id as LP_loan_ID,
    -- Settlement tracking fields from DI-928 enhancements
    SSP.SETTLEMENT_SETUP_PORTFOLIO,
    SSP.SETTLEMENT_SETUP_PORTFOLIO_CREATED_DATE
FROM base_charged_off_loans A
INNER JOIN loan_settings_filtered LSF
    ON A.PAYOFFUID = LOWER(LSF.LEAD_GUID)
LEFT JOIN bankruptcy_data_filtered B
    ON A.PAYOFFUID = B.payoffuid  
LEFT JOIN fraud_data_filtered FD
    ON A.PAYOFFUID = FD.payoffuid
LEFT JOIN (
    SELECT *
    FROM business_intelligence.analytics_pii.vw_member_pii
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY member_id 
        ORDER BY MEMBER_PII_END_DATE DESC NULLS FIRST
    ) = 1
) m_pii ON LSF.member_id = m_pii.member_id
LEFT JOIN delinquency_dates DD
    ON A.PAYOFFUID = DD.PAYOFFUID
LEFT JOIN payment_history PH
    ON A.PAYOFFUID = PH.PAYOFFUID
LEFT JOIN bankruptcy_principal_remaining BPR
    ON A.PAYOFFUID = BPR.PAYOFFUID
LEFT JOIN business_intelligence.analytics.vw_loan vl
    ON upper(A.LOANID) = upper(vl.legacy_loan_id)
LEFT JOIN settlement_setup_portfolio SSP
    ON vl.LOAN_ID::VARCHAR = SSP.LOAN_ID::VARCHAR
LEFT JOIN settlement_successful_portfolio SSUP
    ON vl.LOAN_ID::VARCHAR = SSUP.LOAN_ID::VARCHAR
LEFT JOIN settled_in_full_sub_status SIFS
    ON vl.LOAN_ID::VARCHAR = SIFS.LOAN_ID::VARCHAR
WHERE 1=1
    -- Additional business rule filters
    AND (B.DEBT_SETTLEMENT_STATUS NOT IN ('Active','Complete')
         OR (B.DEBT_SETTLEMENT_STATUS IS NULL AND B.DEBT_SETTLEMENT_START IS NULL))
    AND (B.PLACEMENT_STATUS NOT IN ('Resurgent', 'ARS', 'Remitter',
                                    'First Tech Credit Union', 'Jefferson Capital','Bounce')
         OR B.PLACEMENT_STATUS IS NULL)
    AND COALESCE(FD.is_fraud, FALSE) = FALSE -- Exclude Fraud
    -- DI-928 Additional settlement exclusions
    AND SSUP.SETTLEMENT_SUCCESSFUL_PORTFOLIO IS NULL -- Exclude Settlement Successful portfolios
    AND SIFS.SETTLED_IN_FULL_STATUS_IND IS NULL -- Exclude Settled in Full status
ORDER BY A.CHARGEOFFDATE DESC;

-- ===========================
-- VALIDATION QUERIES
-- ===========================

SELECT * FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE;

-- QC: Check for duplicates
SELECT COUNT(*) AS ROW_COUNT, LOANID
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE
GROUP BY LOANID
HAVING COUNT(*) > 1
ORDER BY 1 DESC;

-- QC: Count summary 
SELECT 
    COUNT(*) AS ROW_COUNT,
    COUNT(DISTINCT LOANID) AS DISTINCT_LOANID_COUNT,
    COUNT(DISTINCT lead_guid) AS DISTINCT_LEAD_GUID_COUNT,
    MIN(CHARGEOFFDATE) as min_chargeoff_date,
    MAX(CHARGEOFFDATE) as max_chargeoff_date
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE;