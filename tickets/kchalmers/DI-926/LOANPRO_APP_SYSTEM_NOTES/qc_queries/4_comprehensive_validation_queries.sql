-- DI-926: Development Validation Queries for LoanPro App System Notes Views
-- Compare new development architecture against original stored procedure results
-- Modified for development environment performance
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
-- 1. Record Count Comparison (with limits for performance)
SELECT 'Production Table' as source, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)  -- Last 7 days only
UNION ALL
SELECT 'Dev FRESHSNOW View' as source, COUNT(*) as record_count  
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
UNION ALL
SELECT 'Dev BRIDGE View' as source, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES  
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
UNION ALL
SELECT 'Dev ANALYTICS View' as source, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE);

-- 2. Date Range and Coverage Comparison
SELECT 
    'Production' as source,
    MIN(created_ts) as min_date,
    MAX(created_ts) as max_date,
    COUNT(*) as total_records,
    COUNT(DISTINCT APP_ID) as unique_apps
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
UNION ALL
SELECT 
    'Development' as source,
    MIN(created_ts) as min_date,
    MAX(created_ts) as max_date,
    COUNT(*) as total_records,
    COUNT(DISTINCT APP_ID) as unique_apps
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE);

-- 3. Category Distribution Comparison
SELECT 
    'Production' as source,
    note_category as category,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
GROUP BY note_category
ORDER BY record_count DESC
LIMIT 20

UNION ALL

SELECT 
    'Development' as source,
    note_title_detail as category,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
GROUP BY note_title_detail
ORDER BY record_count DESC
LIMIT 20;

-- 4. Sample Data Comparison - Recent Records
SELECT 
    'Production' as source,
    record_id,
    app_id,
    created_ts,
    note_category,
    note_new_value,
    note_old_value
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
ORDER BY created_ts DESC
LIMIT 10

UNION ALL

SELECT 
    'Development' as source,
    record_id,
    app_id,
    created_ts,
    note_title_detail as note_category,
    note_new_value,
    note_old_value
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)  
ORDER BY created_ts DESC
LIMIT 10;

-- 5. Analytics Features Validation
SELECT 
    'Analytics Features' as check_type,
    COUNT(*) as total_records,
    SUM(LOAN_STATUS_CHANGED_FLAG) as status_changes,
    SUM(VALUE_CHANGED_FLAG) as value_changes, 
    SUM(IS_SUB_STATUS_CHANGE) as sub_status_changes,
    SUM(IS_PORTFOLIO_CHANGE) as portfolio_changes,
    SUM(IS_AGENT_CHANGE) as agent_changes,
    COUNT(DISTINCT CHANGE_TYPE_CATEGORY) as change_categories
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE);

-- 6. Performance Test - Simple Count Query
SELECT 
    'Performance Test' as test_type,
    COUNT(*) as records_processed,
    'SUCCESS' as status
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('day', -365, CURRENT_DATE)
LIMIT 50000;