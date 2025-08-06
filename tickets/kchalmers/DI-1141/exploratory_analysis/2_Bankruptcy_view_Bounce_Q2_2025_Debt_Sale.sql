/*
DI-1141: Sale Files for Bounce - Q2 2025 Sale
Supporting lookup view for bankruptcy and debt settlement information
Adapted from DI-932 (Q1 2025) for Q2 2025 date range

Q2 2025 Criteria:
- Chargeoff dates: 4/1/2025 - 6/30/2025
- Data as of: 7/31/2025
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

CREATE OR REPLACE TABLE DEVELOPMENT._TIN.BANKRUPTCY_DEBT_SUSPEND_LOOKUP AS
WITH cte_BUREAU_RESPONSE_HEADER AS (
        SELECT
            lower(PAYOFF_UID) AS PAYOFFUID
            , CREATED_AT
            , UPDATED_AT
            , REQUEST_GUID
            , INTENT
        from
            BUSINESS_INTELLIGENCE.ANALYTICS.VW_BUREAU_RESPONSES_HEADER_CURRENT
        WHERE INTENT = 'refresh'
        QUALIFY ROW_NUMBER() OVER (PARTITION BY lower(PAYOFF_UID) ORDER BY CREATED_AT DESC, UPDATED_AT DESC) = 1
)
,cte_PUBLIC_RECORD AS (SELECT LOWER(A.PAYOFF_UID) AS PAYOFFUID
                            , A.REQUEST_ID AS REQUEST_GUID
                            , A.UPDATED_AT
                            , A.CREATED_AT
                            , A.IS_LATEST_FILED AS IS_LATEST
                            , A.ATTORNEY
                            , A.DATE_FILED AS DATEFILED
                            , A.DATE_PAID AS DATEPAID
                            , A.DOCKET_NUMBER AS DOCKETNUMBER
                            , A.SOURCE_TYPE
                            , A.TYPE
                            , CASE
        -- Bankruptcy Matters
                                  WHEN TYPE = '1D' THEN 'Ch 11 bankruptcy dismissed/closed'
                                  WHEN TYPE = '1F' THEN 'Chapter 11 bankruptcy filing'
                                  WHEN TYPE = '1V' THEN 'Chapter 11 bankruptcy voluntary dismissal'
                                  WHEN TYPE = '1X' THEN 'Chapter 11 bankruptcy discharged'
                                  WHEN TYPE = '2D' THEN 'Ch 12 bankruptcy dismissed/closed'
                                  WHEN TYPE = '2F' THEN 'Chapter 12 bankruptcy filing'
                                  WHEN TYPE = '2V' THEN 'Chapter 12 bankruptcy voluntary dismissal'
                                  WHEN TYPE = '2X' THEN 'Chapter 12 bankruptcy discharged'
                                  WHEN TYPE = '3D' THEN 'Ch 13 bankruptcy dismissed/closed'
                                  WHEN TYPE = '3F' THEN 'Chapter 13 bankruptcy filing'
                                  WHEN TYPE = '3V' THEN 'Chapter 13 bankruptcy voluntary dismissal'
                                  WHEN TYPE = '3X' THEN 'Chapter 13 bankruptcy discharged'
                                  WHEN TYPE = '7D' THEN 'Ch 7 bankruptcy dismissed/closed'
                                  WHEN TYPE = '7F' THEN 'Chapter 7 bankruptcy filing'
                                  WHEN TYPE = '7V' THEN 'Chapter 7 bankruptcy voluntary dismissal'
                                  WHEN TYPE = '7X' THEN 'Chapter 7 bankruptcy discharged'
                                  WHEN TYPE = 'CB' THEN 'Civil judgment in bankruptcy'
                                  WHEN TYPE = 'TB' THEN 'Tax lien included in bankruptcy'
        -- Liens
                                  WHEN TYPE = 'FT' THEN 'Federal tax lien'
                                  WHEN TYPE = 'HA' THEN 'Homeowner association assessment lien'
                                  WHEN TYPE = 'HF' THEN 'Hospital lien satisfied'
                                  WHEN TYPE = 'HL' THEN 'Hospital lien'
                                  WHEN TYPE = 'JL' THEN 'Judicial lien'
                                  WHEN TYPE = 'LR' THEN 'A lien attached to real property'
                                  WHEN TYPE = 'ML' THEN 'Mechanics lien'
                                  WHEN TYPE = 'PG' THEN 'Paving assessment lien'
                                  WHEN TYPE = 'PQ' THEN 'Paving assessment lien satisfied'
                                  WHEN TYPE = 'PT' THEN 'Puerto Rico tax lien'
                                  WHEN TYPE = 'RL' THEN 'Release of tax lien'
                                  WHEN TYPE = 'RM' THEN 'Release of mechanic lien'
                                  WHEN TYPE = 'RS' THEN 'Real estate attachment satisfied'
                                  WHEN TYPE = 'SL' THEN 'State tax lien'
                                  WHEN TYPE = 'TL' THEN 'Tax lien'
                                  WHEN TYPE = 'TX' THEN 'Tax lien revived'
                                  WHEN TYPE = 'WS' THEN 'Water and sewer lien'
        -- Judgments/Judicial
                                  WHEN TYPE = 'JM' THEN 'Judgment dismissed'
                                  WHEN TYPE = 'PC' THEN 'Paid civil judgment'
                                  WHEN TYPE = 'PF' THEN 'Paid federal tax lien'
                                  WHEN TYPE = 'PL' THEN 'Paid tax lien'
                                  WHEN TYPE = 'PV' THEN 'Judgment paid, vacated'
                                  WHEN TYPE = 'CJ' THEN 'Civil judgment'
        -- Other
                                  WHEN TYPE = 'AM' THEN 'Attachment'
                                  WHEN TYPE = 'CS' THEN 'Civil suit filed'
                                  WHEN TYPE = 'CP' THEN 'Child support'
                                  WHEN TYPE = 'DF' THEN 'Dismissed foreclosure'
                                  WHEN TYPE = 'DS' THEN 'Dismissal of court suit'
                                  WHEN TYPE = 'FC' THEN 'Foreclosure'
                                  WHEN TYPE = 'FD' THEN 'Forcible detainer'
                                  WHEN TYPE = 'FF' THEN 'Forcible detainer dismissed'
                                  WHEN TYPE = 'GN' THEN 'Garnishment'
                                  WHEN TYPE = 'SF' THEN 'Satisfied foreclosure'
                                  WHEN TYPE = 'TC' THEN 'Trusteeship canceled'
                                  WHEN TYPE = 'TP' THEN 'Trusteeship paid/state amortization satisfied'
                                  WHEN TYPE = 'TR' THEN 'Trusteeship paid/state amortization'
                                  ELSE 'Unknown'
        END                                       AS TYPE_DECODED
        from BUSINESS_INTELLIGENCE.BRIDGE.VW_BUREAU_RESPONSE_PUBLIC_RECORD A
                       WHERE IS_LATEST = TRUE)
-- the fields B.PAYOFF_UID, B.REQUEST_GUID, B.UPDATED_AT, B.CREATED_AT produce the same info as the ones below
,cte_bureau_bankruptcy AS (
    SELECT A.PAYOFFUID,
    A.REQUEST_GUID,
    A.UPDATED_AT,
    A.CREATED_AT,
    B.IS_LATEST,
    B.ATTORNEY AS ATTORNEY_NAME,
    B.DATEFILED AS FILE_DATE,
    B.DATEPAID,
    B.DOCKETNUMBER AS CASE_NUMBER,
    B.SOURCE_TYPE,
    B.TYPE,
    B.TYPE_DECODED,
    A.INTENT,
    REGEXP_REPLACE(B.TYPE_DECODED, '[^0-9]', '') AS CHAPTER,
    CASE
       WHEN CONTAINS(B.TYPE_DECODED, 'discharged') THEN 'Discharge'
       WHEN CONTAINS(B.TYPE_DECODED, 'dismissed') OR CONTAINS(B.TYPE_DECODED, 'dismissal') THEN 'Dismiss'
       WHEN CONTAINS(B.TYPE_DECODED, 'filing') THEN 'Active'
       ELSE NULL
       END                                      AS BANKRUPTCY_STATUS,
    IFF(CONTAINS(B.TYPE_DECODED, 'discharged'),b.DATEPAID,NULL) AS DISCHARGE_DATE
FROM
    cte_BUREAU_RESPONSE_HEADER A
    INNER JOIN cte_PUBLIC_RECORD B ON A.REQUEST_GUID = B.REQUEST_GUID
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN C
        ON lower(A.PAYOFFUID) = lower(C.LEAD_GUID)
WHERE
    UPPER(B.TYPE_DECODED) LIKE '%BANKRUPTCY%'
    AND B.DATEFILED >= C.ORIGINATION_DATE
-- TAKING THE LATEST BANKRUPTCY DATE
QUALIFY
    ROW_NUMBER() OVER (PARTITION BY A.PAYOFFUID ORDER BY B.DATEFILED DESC, B.DATEPAID DESC, A.UPDATED_AT DESC, A.CREATED_AT DESC) = 1
ORDER BY
    B.PAYOFFUID
    , B.DATEFILED DESC
    , B.CREATED_AT DESC
)
,cte_current_loan_columns AS (
    SELECT
        lclsc.loan_id::TEXT AS loan_id
        ,lower(lclsc.lead_guid) as PAYOFFUID
        ,vl.legacy_loan_id
        ,vl.member_id

    ------------ bankruptcy -----------------------------------
        ,  lclsc.BANKRUPTCY_STATUS                  -- Bankruptcy Status
        , coalesce(lclsc.BANKRUPTCY_CASE_NUMBER, brc.CASE_NUMBER) as CASE_NUMBER               -- #16 Case Number
        
        ,  coalesce(  lclsc.BANKRUPTCY_CHAPTER, clac.CHAPTER,  right(brc.CHAPTER,1) ) AS CHAPTER
        
        ,    coalesce(lclsc.ATTORNEY_NAME, clac.ATTORNEY_NAME) AS   ATTORNEY_NAME
        
        ,  coalesce(lclsc.FIRM_NAME, clac.FIRM_NAME)  AS FIRM_NAME
        
        , coalesce(lclsc.BANKRUPTCY_FILING_DATE, clac.FILE_DATE) AS   FILE_DATE                 -- #20 BKY Filing Date
        
        ,  coalesce(lclsc.PROOFOFCLAIMREQUIRED, clac.POC_REQUIRED) AS POC_REQUIRED                  -- #24 Proof of Claim Filed Date
        
        , coalesce(clac.POC_DEADLINE_DATE, brc.PROOF_OF_CLAIM_DEADLINE_DATE) AS POC_DEADLINE_DATE                 -- #24 Proof of Claim Filed Date
        
        , clac.POC_COMPLETED_DATE AS POC_COMPLETED_DATE
        
        ,  coalesce(lclsc.DISCHARGE_DATE, clac.DISCHARGE_DATE) AS DISCHARGE_DATE                     -- #26 Discharge Date

 ---------------- debt settlement --------------------------
        
        , lclsc.SETTLEMENTSTATUS AS DEBT_SETTLEMENT_STATUS
        
        , lclsc.SETTLEMENTSTARTDATE AS DEBT_SETTLEMENT_START
        
        , lclsc.SETTLEMENTAGREEMENTAMOUNT as APPROVED_SETTLEMENT_AMOUNT
        
        , lclsc.DEBTSETTLEMENTPAYMENTTERMS as DEBT_SETTLEMENT_PAYMENT_TERMS
        
        , lclsc.NUMBEROFDEBTSETTLEMENTPAYMENTSEXPECTED as DEBT_SETTLEMENT_PAYMENTS_EXPECTED
        
        , ZEROIFNULL(lclsc.SETTLEMENTAGREEMENTAMOUNT)/IFF(lclsc.NUMBEROFDEBTSETTLEMENTPAYMENTSEXPECTED=0,NULL,lclsc.NUMBEROFDEBTSETTLEMENTPAYMENTSEXPECTED) AS EXPECTED_PAYMENT_AMOUNT
        
        , lclsc.SETTLEMENTCOMPANY as DEBT_SETTLEMENT_COMPANY
        
        , lclsc.DSCCONTACT as DEBT_SETTLEMENT_CONTACTED_BY

        --- contact rules
        
        ,   lcr.SUPPRESS_PHONE as SUSPEND_PHONE
        , lcr.suppress_text  as SUSPEND_TEXT
        , lcr.suppress_email as SUSPEND_EMAIL
        , lcr.suppress_letter  as  SUSPEND_LETTER
        ,lcr.CEASE_AND_DESIST
        
        ,lclsc.PLACEMENT_STATUS AS PLACEMENT_STATUS
        
        ,  clac.CHARGED_OFF_PRINCIPAL_ADJUSTMENT     -- #8 Breakdown of interest, fees, payments and adjustments/credits or balance calculation --- only exists in CLS

    FROM
        BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT lclsc
        left join business_intelligence.analytics.vw_loan vl
            on lower(vl.lead_guid) = lower(lclsc.lead_guid)
        left join BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_LOAN_ACCOUNT_CURRENT clac
            ON lower(lclsc.lead_guid) = lower(clac.lead_guid)
        left join BUSINESS_INTELLIGENCE.BRIDGE.VW_BANKRUPTCY_ENTITY_CURRENT brc
            ON lclsc.LOAN_ID::VARCHAR = brc.loan_id::VARCHAR
        LEFT JOIN  BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES lcr
            ON lclsc.LOAN_ID::VARCHAR = lcr.LOAN_ID::VARCHAR
            AND lcr.CONTACT_RULE_END_DATE IS NULL
)
, cte_coalesce_all_bankruptcy as (
select
    lbc.loan_id
    ,lower(lbc.payoffuid) as payoffuid
    ,lbc.legacy_loan_id
    ,lbc.member_id
    ,iff(coalesce(lbc.BANKRUPTCY_STATUS, fbbc.BANKRUPTCY_STATUS) = 'Remove Bankruptcy', 'Discharge', coalesce(lbc.BANKRUPTCY_STATUS, fbbc.BANKRUPTCY_STATUS)) as BANKRUPTCY_STATUS
    ,coalesce(lbc.CASE_NUMBER, fbbc.CASE_NUMBER) as CASE_NUMBER
    ,coalesce(lbc.CHAPTER, fbbc.CHAPTER) as CHAPTER
    ,coalesce(lbc.ATTORNEY_NAME, fbbc.ATTORNEY_NAME) as ATTORNEY_NAME
    ,lbc.FIRM_NAME
    ,coalesce(lbc.FILE_DATE, fbbc.FILE_DATE) as FILE_DATE
    ,coalesce(lbc.DISCHARGE_DATE, fbbc.DISCHARGE_DATE) as DISCHARGE_DATE
    ,lbc.POC_REQUIRED
    ,lbc.POC_DEADLINE_DATE
    ,lbc.POC_COMPLETED_DATE
    ,lbc.DEBT_SETTLEMENT_STATUS
    ,lbc.DEBT_SETTLEMENT_START
    ,lbc.APPROVED_SETTLEMENT_AMOUNT
    ,lbc.DEBT_SETTLEMENT_PAYMENT_TERMS
    ,lbc.DEBT_SETTLEMENT_PAYMENTS_EXPECTED
    ,lbc.EXPECTED_PAYMENT_AMOUNT
    ,lbc.DEBT_SETTLEMENT_COMPANY
    ,lbc.DEBT_SETTLEMENT_CONTACTED_BY
    ,lbc.SUSPEND_PHONE
    ,lbc.SUSPEND_TEXT
    ,lbc.SUSPEND_EMAIL
    ,lbc.SUSPEND_LETTER
    ,lbc.CEASE_AND_DESIST
    ,lbc.PLACEMENT_STATUS
    ,lbc.CHARGED_OFF_PRINCIPAL_ADJUSTMENT

from
    cte_current_loan_columns lbc
    left join cte_bureau_bankruptcy fbbc
        on lbc.PAYOFFUID = fbbc.PAYOFFUID)
select DISTINCT *
from cte_coalesce_all_bankruptcy;

-- Validation query
SELECT * FROM DEVELOPMENT._TIN.BANKRUPTCY_DEBT_SUSPEND_LOOKUP
ORDER BY PAYOFFUID
LIMIT 100;

-- QC: Count records and check key fields
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN BANKRUPTCY_STATUS IS NOT NULL THEN 1 END) as bankruptcy_records,
    COUNT(CASE WHEN DEBT_SETTLEMENT_STATUS IS NOT NULL THEN 1 END) as debt_settlement_records,
    COUNT(CASE WHEN PLACEMENT_STATUS IS NOT NULL THEN 1 END) as placement_records
FROM DEVELOPMENT._TIN.BANKRUPTCY_DEBT_SUSPEND_LOOKUP;