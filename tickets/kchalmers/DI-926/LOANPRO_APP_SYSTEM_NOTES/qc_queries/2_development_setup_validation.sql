-- DI-926: Development Setup Validation
-- Quick validation queries to ensure development objects are working
-- Run these first before running the full QC suite

-- Step 1: Verify development objects exist
SELECT 'FRESHSNOW_VIEW_EXISTS' as check_type, COUNT(*) as exists_check
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'FRESHSNOW' 
  AND TABLE_NAME = 'VW_LOANPRO_APP_SYSTEM_NOTES'
  AND TABLE_CATALOG = 'DEVELOPMENT';

SELECT 'FRESHSNOW_TABLE_EXISTS' as check_type, COUNT(*) as exists_check  
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'FRESHSNOW' 
  AND TABLE_NAME = 'LOANPRO_APP_SYSTEM_NOTES'
  AND TABLE_CATALOG = 'DEVELOPMENT';

-- Step 2: Test basic functionality with small sample
SELECT 'BASIC_FUNCTIONALITY' as check_type,
       COUNT(*) as record_count,
       COUNT(DISTINCT APP_ID) as unique_apps,
       MAX(CREATED_TS) as latest_record,
       MIN(CREATED_TS) as earliest_record
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES 
LIMIT 1000;

-- Step 3: Test BRIDGE view
SELECT 'BRIDGE_VIEW_TEST' as check_type,
       COUNT(*) as record_count,
       COUNT(DISTINCT NOTE_TITLE_DETAIL) as categories
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
LIMIT 1000;

-- Step 4: Test ANALYTICS view  
SELECT 'ANALYTICS_VIEW_TEST' as check_type,
       COUNT(*) as record_count,
       COUNT(DISTINCT CHANGE_TYPE_CATEGORY) as change_categories,
       SUM(LOAN_STATUS_CHANGED_FLAG) as status_changes,
       SUM(IS_PORTFOLIO_CHANGE) as portfolio_changes
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
LIMIT 1000;

-- Step 5: Sample data review
SELECT TOP 10
       RECORD_ID,
       APP_ID, 
       CREATED_TS,
       NOTE_TITLE_DETAIL,
       NOTE_NEW_VALUE,
       NOTE_OLD_VALUE,
       LOAN_STATUS_NEW,
       LOAN_STATUS_OLD
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
ORDER BY CREATED_TS DESC;