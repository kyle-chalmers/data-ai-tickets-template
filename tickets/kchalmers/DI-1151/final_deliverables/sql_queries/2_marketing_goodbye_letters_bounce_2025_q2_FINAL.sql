-- DI-1151: Marketing Goodbye Letters for Bounce 2025 Q2 Debt Sale
-- FINAL VERSION: Uses SELECTED table as base with main table join
-- Updated: Different sale dates for Theorem vs non-Theorem portfolios

SET THEOREM_SALE_DATE = '2025-08-11';
SET NON_THEOREM_SALE_DATE = '2025-08-08';

-- Notice_of_Servicing_Transfer_Placement_File_Bounce_2025_Q2_SALE
SELECT UPPER(ds.LOANID) as loan_id,
       LOWER(ds.LEAD_GUID) as payoffuid,
       UPPER(ds.FIRSTNAME) as first_name,
       UPPER(ds.LASTNAME) as last_name,
       ds.EMAIL,
       ds.STREETADDRESS1 as streetaddress1,
       ds.STREETADDRESS2 as streetaddress2,
       ds.CITY,
       ds.STATE,
       ds.ZIPCODE as zipcode,
       lc.CUSTOMER_ID as SFMC_SUBSCRIBER_ID,
       ds.CHARGEOFFDATE AS CHARGE_OFF_DATE,
       ds.UNPAIDBALANCEDUE AS CURRENT_BALANCE,
       ds.PRINCIPALBALANCEATCHARGEOFF + ds.INTERESTBALANCEATCHARGEOFF AS CHARGE_OFF_BALANCE,
       CASE 
           WHEN REPLACE(ds.PORTFOLIONAME, 'Payoff FBO ', '') = 'HIVE Participation' 
           THEN 'GreenState Credit Union'
           ELSE REPLACE(ds.PORTFOLIONAME, 'Payoff FBO ', '')
       END AS CU_NAME,
       CASE 
           WHEN ds.PORTFOLIONAME IN ('Theorem Main Master Fund LP - Loan Sale', 
                                     'Theorem Prime Plus Yield Fund Master LP - Loan Sale') 
           THEN $THEOREM_SALE_DATE 
           ELSE $NON_THEOREM_SALE_DATE 
       END AS SALE_DATE,
       ds.PRINCIPALBALANCEATCHARGEOFF,
       ds.INTERESTBALANCEATCHARGEOFF,
       ds.CHARGED_OFF_PRINCIPAL_ADJUSTMENT,
       ds.RECOVERIESPAIDTODATE,
       ds.TOTALPRINCIPALWAIVED
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED sel
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE ds
    ON sel.LOANID = ds.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT lc
    ON ds.LP_LOAN_ID = lc.LOAN_ID 
    AND lc.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LOS_SCHEMA();