-- DI-926: Full Dataset Validation
-- Comprehensive validation queries for the complete development dataset
-- Run after full table creation is complete

-- Step 1: Basic dataset metrics
SELECT 
    'FULL_DATASET_OVERVIEW' as check_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT RECORD_ID) as unique_records,
    COUNT(DISTINCT APP_ID) as unique_applications,
    MIN(CREATED_TS) as earliest_record,
    MAX(CREATED_TS) as latest_record,
    COUNT(DISTINCT NOTE_TITLE_DETAIL) as unique_categories
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;

-- Step 2: Category distribution analysis
SELECT 
    NOTE_TITLE_DETAIL,
    COUNT(*) as record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES
GROUP BY NOTE_TITLE_DETAIL
ORDER BY record_count DESC
LIMIT 20;

-- Step 3: Data quality checks
SELECT 
    'DATA_QUALITY' as check_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN NOTE_NEW_VALUE IS NOT NULL THEN 1 END) as records_with_new_value,
    COUNT(CASE WHEN NOTE_OLD_VALUE IS NOT NULL THEN 1 END) as records_with_old_value,
    COUNT(CASE WHEN NOTE_NEW_VALUE_LABEL IS NOT NULL THEN 1 END) as records_with_new_label,
    COUNT(CASE WHEN LOAN_STATUS_NEW IS NOT NULL THEN 1 END) as records_with_status_new,
    COUNT(CASE WHEN PORTFOLIOS_ADDED IS NOT NULL THEN 1 END) as records_with_portfolio_added
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;

-- Step 4: Time distribution analysis
SELECT 
    DATE_TRUNC('month', CREATED_TS) as month,
    COUNT(*) as monthly_records
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES
GROUP BY DATE_TRUNC('month', CREATED_TS)
ORDER BY month DESC
LIMIT 12;

-- Step 5: Compare with production (if accessible)
SELECT 
    'PRODUCTION_COMPARISON' as check_type,
    (SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY WHERE created_ts >= DATEADD('day', -30, CURRENT_DATE)) as production_last_30_days,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES WHERE created_ts >= DATEADD('day', -30, CURRENT_DATE)) as development_last_30_days,
    (SELECT MAX(created_ts) FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY) as production_latest,
    (SELECT MAX(created_ts) FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES) as development_latest;

-- Step 6: Test BRIDGE view performance
SELECT 
    'BRIDGE_VIEW_TEST' as test_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT NOTE_TITLE_DETAIL) as categories,
    MAX(CREATED_TS) as latest_timestamp
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Step 7: Test ANALYTICS view features
SELECT 
    'ANALYTICS_VIEW_TEST' as test_type,
    COUNT(*) as total_records,
    SUM(CASE WHEN LOAN_STATUS_CHANGED_FLAG = 1 THEN 1 ELSE 0 END) as status_changes,
    SUM(VALUE_CHANGED_FLAG) as value_changes,
    SUM(IS_SUB_STATUS_CHANGE) as sub_status_changes,
    SUM(IS_PORTFOLIO_CHANGE) as portfolio_changes,
    SUM(IS_AGENT_CHANGE) as agent_changes,
    COUNT(DISTINCT CHANGE_TYPE_CATEGORY) as change_categories
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Step 8: Sample of recent records with full transformations
SELECT TOP 10
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    NOTE_TITLE_DETAIL,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE,
    NOTE_OLD_VALUE_LABEL,
    LOAN_STATUS_NEW,
    LOAN_STATUS_OLD,
    PORTFOLIOS_ADDED,
    PORTFOLIOS_ADDED_CATEGORY
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE NOTE_NEW_VALUE IS NOT NULL 
   OR NOTE_OLD_VALUE IS NOT NULL
ORDER BY CREATED_TS DESC;