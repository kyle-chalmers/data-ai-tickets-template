-- DI-926: Validation Queries for LoanPro App System Notes Views
-- Compare new architecture against original stored procedure results

-- 1. Record Count Comparison
SELECT 'Original Table' as source, COUNT(*) as record_count
FROM business_intelligence.cron_store.system_note_entity
UNION ALL
SELECT 'New FRESHSNOW View' as source, COUNT(*) as record_count  
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
UNION ALL
SELECT 'New BRIDGE View' as source, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
UNION ALL
SELECT 'New ANALYTICS View' as source, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES;

-- 2. Date Range Comparison
SELECT 
    'Original' as source,
    MIN(created_ts) as min_date,
    MAX(created_ts) as max_date,
    COUNT(*) as total_records
FROM business_intelligence.cron_store.system_note_entity
UNION ALL
SELECT 
    'New Views' as source,
    MIN(created_ts) as min_date,
    MAX(created_ts) as max_date,
    COUNT(*) as total_records
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES;

-- 3. Sample Data Comparison (first 10 records)
SELECT 
    app_id,
    created_ts,
    note_category_detail,
    note_new_value,
    note_old_value,
    'Original' as source
FROM business_intelligence.cron_store.system_note_entity 
ORDER BY created_ts DESC
LIMIT 10

UNION ALL

SELECT 
    app_id,
    created_ts,
    note_category_detail,
    note_new_value,
    note_old_value,
    'New Views' as source
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
ORDER BY created_ts DESC
LIMIT 10;

-- 4. Note Category Distribution Comparison
SELECT 
    note_category_detail,
    COUNT(*) as record_count,
    'Original' as source
FROM business_intelligence.cron_store.system_note_entity
GROUP BY note_category_detail
ORDER BY record_count DESC

UNION ALL

SELECT 
    note_category_detail,
    COUNT(*) as record_count,
    'New Views' as source  
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
GROUP BY note_category_detail
ORDER BY record_count DESC;

-- 5. Performance Test (execution time comparison)
SELECT 
    COUNT(*) as record_count,
    COUNT(DISTINCT app_id) as unique_apps,
    COUNT(DISTINCT note_category_detail) as unique_categories,
    'Original Table' as source
FROM business_intelligence.cron_store.system_note_entity
WHERE created_ts >= DATEADD(day, -30, CURRENT_DATE())

UNION ALL

SELECT 
    COUNT(*) as record_count,
    COUNT(DISTINCT app_id) as unique_apps,
    COUNT(DISTINCT note_category_detail) as unique_categories,
    'New ANALYTICS View' as source
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD(day, -30, CURRENT_DATE());

-- 6. Business Logic Validation - Status Changes
SELECT 
    'Status Changes - Original' as source,
    COUNT(CASE WHEN loan_status_new != loan_status_old THEN 1 END) as status_changes,
    COUNT(*) as total_records
FROM business_intelligence.cron_store.system_note_entity
WHERE note_category_detail LIKE '%Status%'

UNION ALL

SELECT 
    'Status Changes - New Views' as source,
    COUNT(CASE WHEN loan_status_changed_flag = 1 THEN 1 END) as status_changes,
    COUNT(*) as total_records
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE note_category_detail LIKE '%Status%';

-- 7. Data Quality Check - Null Values
SELECT 
    'Original' as source,
    COUNT(CASE WHEN app_id IS NULL THEN 1 END) as null_app_ids,
    COUNT(CASE WHEN created_ts IS NULL THEN 1 END) as null_created_ts,
    COUNT(CASE WHEN note_category_detail IS NULL THEN 1 END) as null_categories
FROM business_intelligence.cron_store.system_note_entity

UNION ALL

SELECT 
    'New Views' as source,
    COUNT(CASE WHEN app_id IS NULL THEN 1 END) as null_app_ids,
    COUNT(CASE WHEN created_ts IS NULL THEN 1 END) as null_created_ts,
    COUNT(CASE WHEN note_category_detail IS NULL THEN 1 END) as null_categories
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES;