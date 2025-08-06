/*
DI-1141: Sale Files for Bounce - Q2 2025 Sale
Supporting lookup view for fraud, SCRA, and deceased indicators
Adapted from DI-932 (Q1 2025) for Q2 2025 date range

Q2 2025 Criteria:
- Chargeoff dates: 4/1/2025 - 6/30/2025
- Data as of: 7/31/2025
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

CREATE OR REPLACE TABLE DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP AS
WITH cte_port_category
    AS ( --- this is conservative because it doesn't filter out the specific portfolio_name -- different grain
        SELECT vl.lead_guid

             , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.created END)                                 as Fraud_date
             , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'SCRA' THEN lpsp.created END)                                  as SCRA_date
             , MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Deceased' THEN lpsp.created END)                              as Deceased_date

             , iff(MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.created END) is not null, TRUE,
                   null)                                                                                              as IS_Fraud
             , iff(MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'SCRA' THEN lpsp.created END) is not null, TRUE,
                   null)                                                                                              as IS_SCRA
             , iff(MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Deceased' THEN lpsp.created END) is not null, TRUE,
                   null)                                                                                              as IS_Deceased
        FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
                 join business_intelligence.analytics.vw_loan vl on lpsp.loan_id = vl.loan_id
        WHERE PORTFOLIO_CATEGORY IN ('Deceased', 'Fraud', 'SCRA')
        GROUP BY lpsp.LOAN_ID, vl.lead_guid, vl.legacy_loan_id)
   , cte_DECEASED AS (SELECT lower(PAYOFF_UID)        as lead_guid
                           , MIN(TO_DATE(CREATED_AT)) AS FIRST_REPORTED_DECEASED_DATE
                           , TRUE                     as IS_Deceased
                      FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_BUREAU_RESPONSES_SCORE_CURRENT brsc
                      WHERE NOSCOREREASON = 'subjectDeceased'
                      GROUP BY PAYOFF_UID)
   , cte_FRAUD AS ( -- keep this as we still need cls data
    SELECT a_tags.HK_H_APPL
         , a_tags.APPLICATION_TAG
         , lower(app.payoff_uid)   as lead_guid
         , max(a_tags.createddate) as CLS_Confirmed_Fraud
         , TRUE                    as IS_FRAUD
    from business_intelligence.data_store.vw_application app
             left join business_intelligence.data_store.vw_appl_tags a_tags on app.hk_h_appl = a_tags.hk_h_appl
    WHERE a_tags.application_tag = 'Confirmed Fraud'
      AND a_tags.softdelete = 'False'
    GROUP BY a_tags.HK_H_APPL, a_tags.APPLICATION_TAG, app.payoff_uid)
   , cte_SCRA_INTEREST_RATE_START AS (SELECT lower(LEAD_GUID) as LEAD_GUID
                                           , LOAN_INTEREST_RATE_LAST
                                           , LOAN_STATUS
                                           , LOAN_CONTRACTUAL_INTEREST_RATE
                                      -- ,*
                                      FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_LOAN_ACCOUNT_CURRENT
                                      WHERE LOAN_INTEREST_RATE_LAST = 6
                                        AND LOAN_STATUS = 'Closed- Written Off')
   , cte_SCRA_INTEREST_RATE_FINAL AS (select LOWER(vl.LEAD_GUID) AS lead_guid
                                           , vln.NOTE_BODY
                                           , c.* exclude lead_guid
                                           , TRUE                AS IS_SCRA
                                      from business_intelligence.analytics.vw_loan_notes vln
                                               INNER JOIN business_intelligence.analytics.vw_loan vl
                                                          ON vl.loan_id::TEXT = vln.loan_id::TEXT
                                               INNER JOIN cte_SCRA_INTEREST_RATE_START C
                                                          ON LOWER(C.LEAD_GUID) = LOWER(vl.LEAD_GUID)
                                      WHERE UPPER(vln.NOTE_BODY) LIKE '%SCRA%'
                                         OR UPPER(vln.NOTE_TITLE) LIKE '%SCRA%'
                                      QUALIFY
                                          ROW_NUMBER() OVER (PARTITION BY vl.lead_guid ORDER BY vln.CREATED_DATETIME_UTC DESC) =
                                          1)
   , cte_coalesce as (
    select lower(vl.lead_guid)                                      as payoffuid
         , vl.loan_id
         , vl.legacy_loan_id

         , ifnull(coalesce(cpc.is_deceased, cd.is_deceased), FALSE) as IS_DECEASED
         , ifnull(coalesce(cpc.is_fraud, cf.is_fraud), FALSE)       as is_fraud
         , ifnull(coalesce(cpc.is_scra, csirf.is_scra), FALSE)      as IS_SCRA

    from business_intelligence.analytics.vw_loan vl
             left join cte_port_category cpc on lower(vl.lead_guid) = lower(cpc.lead_guid)
             left join cte_deceased cd on lower(vl.lead_guid) = lower(cd.lead_guid)
             left join cte_FRAUD cf on lower(vl.lead_guid) = lower(cf.lead_guid)
             left join cte_SCRA_INTEREST_RATE_FINAL csirf on lower(vl.lead_guid) = lower(csirf.lead_guid))
select *
from cte_coalesce;

-- Validation query
SELECT * FROM DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP;

-- QC: Count records and check indicators
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN IS_DECEASED THEN 1 END) as deceased_count,
    COUNT(CASE WHEN IS_FRAUD THEN 1 END) as fraud_count,
    COUNT(CASE WHEN IS_SCRA THEN 1 END) as scra_count
FROM DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP;