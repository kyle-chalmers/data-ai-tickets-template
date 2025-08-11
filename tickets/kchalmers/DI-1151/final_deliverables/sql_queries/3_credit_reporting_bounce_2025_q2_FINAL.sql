-- DI-1151: Credit Reporting List for Bounce 2025 Q2 Debt Sale
-- FINAL VERSION: Uses SELECTED table as base with main table join
-- Updated: Different placement dates for Theorem vs non-Theorem portfolios

SET THEOREM_START_DATE = '2025-08-11';
SET NON_THEOREM_START_DATE = '2025-08-08';

-- Credit_Reporting_File_Bounce_2025_Q2_SALE
SELECT UPPER(ds.LOANID) as loan_id,
       UPPER(ds.FIRSTNAME) as first_name,
       UPPER(ds.LASTNAME) as last_name,
       CASE 
           WHEN ds.PORTFOLIONAME IN ('Theorem Main Master Fund LP - Loan Sale', 
                                     'Theorem Prime Plus Yield Fund Master LP - Loan Sale') 
           THEN $THEOREM_START_DATE 
           ELSE $NON_THEOREM_START_DATE 
       END as PLACEMENT_STATUS_STARTDATE
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED sel
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE ds
    ON sel.LOANID = ds.LOANID;