/*
DI-1141: Sale Files for Bounce - Q2 2025 Sale
OPTIMIZED Supporting lookup view for fraud, SCRA, and deceased indicators
Optimizations made:
1. Pre-filter joins with WHERE conditions
2. Use INNER JOIN where appropriate instead of LEFT JOIN
3. Add explicit column selection to reduce data movement
4. Optimize window function partitioning
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

CREATE OR REPLACE TABLE DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP AS
WITH cte_charged_off_loans AS (
    -- Pre-filter to only charged off loans in Q2 2025 to reduce data volume early
    SELECT DISTINCT PAYOFFUID 
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE STATUS = 'Charge off'
      AND DATE_TRUNC('month',CHARGEOFFDATE) >= '2025-04-01'
      AND DATE_TRUNC('month',CHARGEOFFDATE) <= '2025-06-30'
      AND DATE_TRUNC('month',ASOFDATE) = DATE_TRUNC('month',DATEADD('month',-1,current_date))
)
,cte_port_category AS (
    -- Only process portfolios for loans in our target population
    SELECT vl.lead_guid
         , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.created END) as Fraud_date
         , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'SCRA' THEN lpsp.created END) as SCRA_date
         , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Deceased' THEN lpsp.created END) as Deceased_date
         , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN TRUE END) as IS_Fraud
         , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'SCRA' THEN TRUE END) as IS_SCRA
         , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Deceased' THEN TRUE END) as IS_Deceased
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
    INNER JOIN business_intelligence.analytics.vw_loan vl 
        ON lpsp.loan_id = vl.loan_id
    INNER JOIN cte_charged_off_loans col 
        ON LOWER(vl.lead_guid) = LOWER(col.PAYOFFUID)
    WHERE lpsp.PORTFOLIO_CATEGORY IN ('Deceased', 'Fraud', 'SCRA') AND PORTFOLIO_NAME NOT IN ('SCRA - Declined')
    GROUP BY lpsp.LOAN_ID, vl.lead_guid, vl.legacy_loan_id
)
,cte_DECEASED AS (
    -- Only check bureau responses for our target population
    SELECT lower(brsc.PAYOFF_UID) as lead_guid
         , MIN(TO_DATE(brsc.CREATED_AT)) AS FIRST_REPORTED_DECEASED_DATE
         , TRUE as IS_Deceased
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_BUREAU_RESPONSES_SCORE_CURRENT brsc
    INNER JOIN cte_charged_off_loans col 
        ON LOWER(brsc.PAYOFF_UID) = LOWER(col.PAYOFFUID)
    WHERE brsc.NOSCOREREASON = 'subjectDeceased'
    GROUP BY brsc.PAYOFF_UID
)
,cte_FRAUD AS (
    -- Pre-filter applications to reduce join overhead
    SELECT lower(app.payoff_uid) as lead_guid
         , max(a_tags.createddate) as CLS_Confirmed_Fraud
         , TRUE as IS_FRAUD
    FROM business_intelligence.data_store.vw_application app
    INNER JOIN cte_charged_off_loans col 
        ON LOWER(app.payoff_uid) = LOWER(col.PAYOFFUID)
    INNER JOIN business_intelligence.data_store.vw_appl_tags a_tags 
        ON app.hk_h_appl = a_tags.hk_h_appl
        AND a_tags.application_tag = 'Confirmed Fraud'
        AND a_tags.softdelete = 'False'
    GROUP BY app.payoff_uid
)
,cte_SCRA_INTEREST_RATE_START AS (
    -- Pre-filter CLS accounts to target population
    SELECT lower(clac.LEAD_GUID) as LEAD_GUID
         , clac.LOAN_INTEREST_RATE_LAST
         , clac.LOAN_STATUS
         , clac.LOAN_CONTRACTUAL_INTEREST_RATE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_LOAN_ACCOUNT_CURRENT clac
    INNER JOIN cte_charged_off_loans col 
        ON LOWER(clac.LEAD_GUID) = LOWER(col.PAYOFFUID)
    WHERE clac.LOAN_INTEREST_RATE_LAST = 6
      AND clac.LOAN_STATUS = 'Closed- Written Off'
)
,cte_SCRA_INTEREST_RATE_FINAL AS (
    -- Optimize SCRA note search with better filtering
    SELECT LOWER(vl.LEAD_GUID) AS lead_guid
         , vln.NOTE_BODY
         , c.LOAN_INTEREST_RATE_LAST
         , c.LOAN_STATUS  
         , c.LOAN_CONTRACTUAL_INTEREST_RATE
         , TRUE AS IS_SCRA
    FROM business_intelligence.analytics.vw_loan_notes vln
    INNER JOIN business_intelligence.analytics.vw_loan vl
        ON vl.loan_id::TEXT = vln.loan_id::TEXT
    INNER JOIN cte_SCRA_INTEREST_RATE_START C
        ON LOWER(C.LEAD_GUID) = LOWER(vl.LEAD_GUID)
    WHERE (UPPER(vln.NOTE_BODY) LIKE '%SCRA%' OR UPPER(vln.NOTE_TITLE) LIKE '%SCRA%')
    QUALIFY ROW_NUMBER() OVER (PARTITION BY vl.lead_guid ORDER BY vln.CREATED_DATETIME_UTC DESC) = 1
)
-- Final result with optimized joins
SELECT lower(vl.lead_guid) as payoffuid
     , vl.loan_id
     , vl.legacy_loan_id
     , COALESCE(cpc.is_deceased, cd.is_deceased, FALSE) as IS_DECEASED
     , COALESCE(cpc.is_fraud, cf.is_fraud, FALSE) as is_fraud
     , COALESCE(cpc.is_scra, csirf.is_scra, FALSE) as IS_SCRA
FROM business_intelligence.analytics.vw_loan vl
INNER JOIN cte_charged_off_loans col 
    ON LOWER(vl.lead_guid) = LOWER(col.PAYOFFUID)
LEFT JOIN cte_port_category cpc 
    ON lower(vl.lead_guid) = lower(cpc.lead_guid)
LEFT JOIN cte_deceased cd 
    ON lower(vl.lead_guid) = lower(cd.lead_guid)
LEFT JOIN cte_FRAUD cf 
    ON lower(vl.lead_guid) = lower(cf.lead_guid)
LEFT JOIN cte_SCRA_INTEREST_RATE_FINAL csirf 
    ON lower(vl.lead_guid) = lower(csirf.lead_guid);

-- Validation query
SELECT * FROM DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP;

-- QC: Count records and check indicators
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN IS_DECEASED THEN 1 END) as deceased_count,
    COUNT(CASE WHEN IS_FRAUD THEN 1 END) as fraud_count,
    COUNT(CASE WHEN IS_SCRA THEN 1 END) as scra_count
FROM DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP;

select count(*), PORTFOLIO_CATEGORY, PORTFOLIO_NAME from BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
group by PORTFOLIO_CATEGORY, PORTFOLIO_NAME