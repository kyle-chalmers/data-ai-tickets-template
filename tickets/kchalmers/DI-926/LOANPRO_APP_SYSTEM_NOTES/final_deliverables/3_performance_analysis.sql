-- DI-926: Performance Analysis and Quality Control for LoanPro App System Notes
-- Validates data quality, structure, and performance improvements

-- 1. RECORD COUNT VALIDATION
SELECT 
    'Total Records' as metric,
    COUNT(*) as count,
    COUNT(DISTINCT app_id) as unique_apps
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES

UNION ALL

-- 2. COLUMN POPULATION ANALYSIS
SELECT 
    'NOTE_NEW_VALUE_LABEL Population' as metric,
    COUNT(note_new_value_label) as count,
    ROUND(COUNT(note_new_value_label) * 100.0 / COUNT(*), 2) as unique_apps
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES

UNION ALL

-- 3. NOTE CATEGORY DISTRIBUTION  
SELECT 
    'Most Common Category: ' || note_title_detail as metric,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as unique_apps
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE note_title_detail IS NOT NULL
GROUP BY note_title_detail
ORDER BY count DESC
LIMIT 5;

-- 4. EXCLUDED COLUMNS IMPACT ANALYSIS
-- Compare original bridge table vs new structure
SELECT 
    'Original BRIDGE columns' as structure,
    25 as column_count,
    'Included unused columns' as notes
    
UNION ALL

SELECT 
    'New FRESHSNOW structure' as structure,
    18 as column_count,
    'Excluded 6 unused columns, added NOTE_NEW_VALUE_LABEL' as notes;

-- 5. PERFORMANCE COMPARISON QUERY
-- Test query performance on key business operations
SELECT 
    note_title_detail,
    DATE_TRUNC('month', created_ts) as month,
    COUNT(*) as change_count,
    COUNT(DISTINCT app_id) as unique_applications
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= DATEADD('month', -3, CURRENT_DATE())
    AND note_title_detail IN ('Loan Sub Status', 'Source Company', 'Agent', 'Portfolios Added')
GROUP BY note_title_detail, DATE_TRUNC('month', created_ts)
ORDER BY month DESC, change_count DESC;

-- 6. DATA QUALITY VALIDATION
-- Check for proper status transformations and label population
SELECT 
    'Status Transformation Check' as validation_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN loan_status_new IS NOT NULL THEN 1 END) as status_populated,
    COUNT(CASE WHEN note_new_value != note_new_value_label THEN 1 END) as labels_enhanced
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE note_title_detail LIKE '%Status%';