-- ticket-1: PortfolioInvestor (PortfolioInvestor) Credit Reporting and Placement Upload List for Loan Sale
-- Based on DI-972 template pattern - adapted for PortfolioInvestor sale data
-- Source: PORTFOLIO_INVESTOR_DEBT_SALE_Q1_2025_SALE_SELECTED (2,179 loans)
-- Template Reference: https://drive.google.com/open?id=1l246hBCC5RxEPCcr4ZxvUO1-9SJLZj_g&usp=drive_fs

SET START_DATE = '2025-07-31'; -- PortfolioInvestor sale date from DI-1099

-- =============================================================================
-- BULK UPLOAD PLACEMENT FILE - PORTFOLIO_INVESTOR SALE
-- Purpose: Upload placement status to loan_management_system for sold loans
-- Output Format: SYSTEM_LOAN_ID, loanid, SETTINGS_ID, Placement_Status, StartDate, EndDate
-- =============================================================================

-- Bulk_Upload_Placement_File_PortfolioInvestor_2025_SALE
SELECT 
    LOAN_ID as SYSTEM_LOAN_ID,
    UPPER(LEGACY_LOAN_ID) as loanid,
    B.SETTINGS_ID,
    'DebtBuyer' as Placement_Status,  -- Updated to reflect DebtBuyer placement (sale destination)
    $START_DATE as Placement_Status_StartDate,
    NULL as Placement_Status_EndDate
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.PORTFOLIO_INVESTOR_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
    ON A.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT B
    ON A.LOAN_ID::STRING = B.ID::STRING 
    AND B.SCHEMA_NAME = ARCA.CONFIG.loan_management_system_SCHEMA()
WHERE C.PORTFOLIONAME ILIKE '%PortfolioInvestor%'  -- Filter to only PortfolioInvestor portfolio loans
ORDER BY UPPER(LEGACY_LOAN_ID);

-- =============================================================================
-- CREDIT REPORTING FILE - PORTFOLIO_INVESTOR SALE  
-- Purpose: Credit reporting data for sold loans
-- Output Format: loan_id, first_name, last_name, PLACEMENT_STATUS_STARTDATE
-- =============================================================================

-- Credit_Reporting_File_PortfolioInvestor_2025_SALE
SELECT 
    UPPER(la.LEGACY_LOAN_ID) as loan_id,
    UPPER(ci.FIRST_NAME) as first_name,
    UPPER(ci.LAST_NAME) as last_name,
    $START_DATE as PLACEMENT_STATUS_STARTDATE
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.PORTFOLIO_INVESTOR_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
    ON LA.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
    ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
    AND ci.MEMBER_PII_END_DATE IS NULL
WHERE C.PORTFOLIONAME ILIKE '%PortfolioInvestor%'  -- Filter to only PortfolioInvestor portfolio loans
ORDER BY UPPER(la.LEGACY_LOAN_ID);

-- =============================================================================
-- QUALITY CONTROL VALIDATION
-- =============================================================================

-- QC: Record counts and data completeness validation
SELECT 
    'ticket-1 QC Summary' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT C.LOANID) as unique_loans,
    COUNT(CASE WHEN la.LOAN_ID IS NOT NULL THEN 1 END) as loans_with_loan_id,
    COUNT(CASE WHEN B.SETTINGS_ID IS NOT NULL THEN 1 END) as loans_with_settings_id,
    COUNT(CASE WHEN ci.FIRST_NAME IS NOT NULL THEN 1 END) as loans_with_first_name,
    COUNT(CASE WHEN ci.LAST_NAME IS NOT NULL THEN 1 END) as loans_with_last_name
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.PORTFOLIO_INVESTOR_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
    ON LA.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT B
    ON LA.LOAN_ID::STRING = B.ID::STRING 
    AND B.SCHEMA_NAME = ARCA.CONFIG.loan_management_system_SCHEMA()
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
    ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
    AND ci.MEMBER_PII_END_DATE IS NULL
WHERE C.PORTFOLIONAME ILIKE '%PortfolioInvestor%';  -- Filter to only PortfolioInvestor portfolio loans