-- DI-1151: Bulk Upload List for Bounce 2025 Q2 Debt Sale  
-- FINAL VERSION: Uses SELECTED table as base with main table join
-- Updated: Different placement dates for Theorem vs non-Theorem portfolios

SET THEOREM_START_DATE = '2025-08-11';
SET NON_THEOREM_START_DATE = '2025-08-08';

-- Bulk_Upload_Placement_File_Bounce_2025_Q2_SALE
SELECT ds.LP_LOAN_ID,
       UPPER(ds.LOANID) as loanid,
       le.SETTINGS_ID,
       'Bounce' as Placement_Status,
       CASE 
           WHEN ds.PORTFOLIONAME IN ('Theorem Main Master Fund LP - Loan Sale', 
                                     'Theorem Prime Plus Yield Fund Master LP - Loan Sale') 
           THEN $THEOREM_START_DATE 
           ELSE $NON_THEOREM_START_DATE 
       END as Placement_Status_StartDate,
       NULL as Placement_Status_EndDate
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED sel
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE ds
    ON sel.LOANID = ds.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le
    ON ds.LP_LOAN_ID::STRING = le.ID::STRING 
    AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA();