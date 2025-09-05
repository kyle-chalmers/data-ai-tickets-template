-- DI-926: Simple Development Validation
-- Basic validation for the simplified development setup

-- Step 1: Verify all objects exist and have data
SELECT 'FRESHSNOW_TABLE' as object_type, COUNT(*) as record_count
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES
UNION ALL
SELECT 'FRESHSNOW_VIEW' as object_type, COUNT(*) as record_count
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES_SIMPLE
UNION ALL
SELECT 'BRIDGE_VIEW' as object_type, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
UNION ALL
SELECT 'ANALYTICS_VIEW' as object_type, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Step 2: Test basic data integrity
SELECT 
    'DATA_INTEGRITY' as test_type,
    COUNT(*) as total_records,
    COUNT(DISTINCT RECORD_ID) as unique_records,
    COUNT(DISTINCT APP_ID) as unique_apps,
    MAX(CREATED_TS) as latest_record
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Step 3: Test analytics features
SELECT 
    'ANALYTICS_FEATURES' as test_type,
    COUNT(*) as total_records,
    SUM(IS_STATUS_CHANGE) as status_changes,
    SUM(IS_PORTFOLIO_CHANGE) as portfolio_changes,
    SUM(IS_AGENT_CHANGE) as agent_changes,
    COUNT(DISTINCT NOTE_CATEGORY) as categories
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Step 4: Sample data review
SELECT TOP 5
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    NOTE_CATEGORY,
    NOTE_TITLE,
    IS_STATUS_CHANGE,
    IS_PORTFOLIO_CHANGE
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
ORDER BY CREATED_TS DESC;