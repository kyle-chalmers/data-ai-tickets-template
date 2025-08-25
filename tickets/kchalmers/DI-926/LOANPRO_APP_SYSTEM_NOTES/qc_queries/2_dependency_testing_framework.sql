-- DI-926: Comprehensive Dependency Testing Framework
-- Testing LOANPRO_APP_SYSTEM_NOTES migration against existing APPL_HISTORY objects

-- =============================================================================
-- 1. DATA COVERAGE ANALYSIS
-- =============================================================================

-- 1A: Compare record counts between architectures
SELECT 
    'Existing ARCA.FRESHSNOW.APPL_HISTORY' as architecture,
    COUNT(*) as total_records,
    COUNT(CASE WHEN NOTE_TITLE = 'Loan settings were created' THEN 1 END) as creation_records,
    COUNT(CASE WHEN NOTE_TITLE != 'Loan settings were created' THEN 1 END) as non_creation_records,
    MIN(CREATED) as earliest_record,
    MAX(CREATED) as latest_record
FROM ARCA.FRESHSNOW.APPL_HISTORY

UNION ALL

SELECT 
    'Production BRIDGE.APP_SYSTEM_NOTE_ENTITY' as architecture,
    COUNT(*) as total_records,
    COUNT(CASE WHEN NOTE_TITLE = 'Loan settings were created' THEN 1 END) as creation_records,
    COUNT(CASE WHEN NOTE_TITLE != 'Loan settings were created' THEN 1 END) as non_creation_records,
    MIN(CREATED_TS) as earliest_record,
    MAX(CREATED_TS) as latest_record
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY

UNION ALL

SELECT 
    'New DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES' as architecture,
    COUNT(*) as total_records,
    COUNT(CASE WHEN NOTE_TITLE = 'Loan settings were created' THEN 1 END) as creation_records,
    COUNT(CASE WHEN NOTE_TITLE != 'Loan settings were created' THEN 1 END) as non_creation_records,
    MIN(CREATED_TS) as earliest_record,
    MAX(CREATED_TS) as latest_record
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;

-- 1B: Coverage Gap Analysis - Records only in one architecture
WITH existing_ids AS (
    SELECT DISTINCT APPLICATION_ID FROM ARCA.FRESHSNOW.APPL_HISTORY
),
new_ids AS (
    SELECT DISTINCT APP_ID FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES  
)
SELECT 
    'Only in Existing APPL_HISTORY' as coverage_gap,
    COUNT(*) as record_count
FROM existing_ids e
LEFT JOIN new_ids n ON e.APPLICATION_ID = n.APP_ID
WHERE n.APP_ID IS NULL

UNION ALL

SELECT 
    'Only in New Architecture' as coverage_gap,
    COUNT(*) as record_count
FROM new_ids n
LEFT JOIN existing_ids e ON n.APP_ID = e.APPLICATION_ID  
WHERE e.APPLICATION_ID IS NULL;

-- =============================================================================
-- 2. BUSINESS LOGIC VALIDATION TESTS
-- =============================================================================

-- 2A: Note Category Distribution Comparison
SELECT 
    'Existing APPL_HISTORY' as source,
    NOTE_TITLE_DETAIL,
    COUNT(*) as record_count,
    COUNT(DISTINCT APPLICATION_ID) as unique_applications
FROM ARCA.FRESHSNOW.APPL_HISTORY
WHERE NOTE_TITLE_DETAIL IS NOT NULL
GROUP BY NOTE_TITLE_DETAIL
ORDER BY record_count DESC

UNION ALL

SELECT 
    'New Architecture' as source,
    NOTE_CATEGORY,
    COUNT(*) as record_count,
    COUNT(DISTINCT APP_ID) as unique_applications  
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE NOTE_CATEGORY IS NOT NULL
GROUP BY NOTE_CATEGORY
ORDER BY record_count DESC;

-- 2B: Status Change Logic Validation
WITH existing_status_changes AS (
    SELECT 
        APPLICATION_ID,
        NOTE_TITLE_DETAIL,
        OLDVALUE_LABEL,
        NEWVALUE_LABEL,
        CREATED,
        'EXISTING' as source
    FROM ARCA.FRESHSNOW.APPL_HISTORY
    WHERE NOTE_TITLE_DETAIL IN ('Loan Status - Loan Sub Status', 'Loan Sub Status')
      AND APPLICATION_ID IN (SELECT APP_ID FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES LIMIT 1000)
),
new_status_changes AS (
    SELECT 
        APP_ID as APPLICATION_ID,
        NOTE_CATEGORY as NOTE_TITLE_DETAIL, 
        NOTE_OLD_VALUE_RAW as OLDVALUE_LABEL,
        NOTE_NEW_VALUE_RAW as NEWVALUE_LABEL,
        CREATED_TS as CREATED,
        'NEW' as source
    FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
    WHERE NOTE_CATEGORY IN ('Loan Status - Loan Sub Status', 'Loan Sub Status')
      AND APP_ID IN (SELECT APPLICATION_ID FROM ARCA.FRESHSNOW.APPL_HISTORY LIMIT 1000)
)
SELECT 
    APPLICATION_ID,
    NOTE_TITLE_DETAIL,
    COUNT(CASE WHEN source = 'EXISTING' THEN 1 END) as existing_count,
    COUNT(CASE WHEN source = 'NEW' THEN 1 END) as new_count,
    ABS(COUNT(CASE WHEN source = 'EXISTING' THEN 1 END) - COUNT(CASE WHEN source = 'NEW' THEN 1 END)) as count_difference
FROM (
    SELECT * FROM existing_status_changes
    UNION ALL  
    SELECT * FROM new_status_changes
)
GROUP BY APPLICATION_ID, NOTE_TITLE_DETAIL
HAVING count_difference > 0
ORDER BY count_difference DESC
LIMIT 20;

-- 2C: Portfolio Change Logic Validation  
SELECT 
    'Portfolio Logic Test' as test_name,
    COUNT(CASE WHEN source = 'EXISTING' AND NOTE_TITLE_DETAIL LIKE '%Portfolio%' THEN 1 END) as existing_portfolio_changes,
    COUNT(CASE WHEN source = 'NEW' AND NOTE_CATEGORY LIKE '%Portfolio%' THEN 1 END) as new_portfolio_changes,
    ABS(COUNT(CASE WHEN source = 'EXISTING' AND NOTE_TITLE_DETAIL LIKE '%Portfolio%' THEN 1 END) - 
        COUNT(CASE WHEN source = 'NEW' AND NOTE_CATEGORY LIKE '%Portfolio%' THEN 1 END)) as difference
FROM (
    SELECT APPLICATION_ID, NOTE_TITLE_DETAIL, 'EXISTING' as source FROM ARCA.FRESHSNOW.APPL_HISTORY
    UNION ALL
    SELECT APP_ID, NOTE_CATEGORY, 'NEW' as source FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
);

-- =============================================================================
-- 3. DOWNSTREAM DEPENDENCY IMPACT TESTS  
-- =============================================================================

-- 3A: BRIDGE Layer Impact Test
SELECT 
    'BRIDGE Layer Record Count' as test_name,
    COUNT(*) as current_bridge_records,
    COUNT(DISTINCT APPLICATION_ID) as unique_applications,
    COUNT(CASE WHEN OLDVALUE != NEWVALUE THEN 1 END) as actual_changes
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_HISTORY;

-- 3B: ANALYTICS Layer Impact Test  
SELECT 
    'ANALYTICS Layer Record Count' as test_name,
    COUNT(*) as current_analytics_records,
    COUNT(DISTINCT APPLICATION_ID) as unique_applications,
    COUNT(CASE WHEN SOURCE = 'LOANPRO' THEN 1 END) as loanpro_records,
    COUNT(CASE WHEN SOURCE = 'CLS' THEN 1 END) as cls_records
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_APPL_HISTORY;

-- 3C: Field Distribution in ANALYTICS Layer
SELECT 
    FIELD,
    COUNT(*) as record_count,
    COUNT(DISTINCT APPLICATION_ID) as unique_applications
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_APPL_HISTORY
WHERE SOURCE = 'LOANPRO'
GROUP BY FIELD
ORDER BY record_count DESC;

-- =============================================================================
-- 4. SCHEMA COMPATIBILITY TESTS
-- =============================================================================

-- 4A: Column Mapping Validation
SELECT 
    'Schema Compatibility Test' as test_name,
    'APPL_HISTORY has APPLICATION_ID, new arch has APP_ID' as mapping_note,
    COUNT(DISTINCT a.APPLICATION_ID) as appl_history_unique_ids,
    COUNT(DISTINCT n.APP_ID) as new_arch_unique_ids
FROM ARCA.FRESHSNOW.APPL_HISTORY a
FULL OUTER JOIN DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES n
  ON a.APPLICATION_ID = n.APP_ID
WHERE a.APPLICATION_ID IS NOT NULL OR n.APP_ID IS NOT NULL;

-- 4B: Data Type Compatibility
SELECT 
    'Data Type Analysis' as test_name,
    'Checking timestamp formats and null handling' as note,
    COUNT(CASE WHEN a.CREATED IS NULL THEN 1 END) as appl_history_null_dates,
    COUNT(CASE WHEN n.CREATED_TS IS NULL THEN 1 END) as new_arch_null_dates,
    COUNT(CASE WHEN a.NEWVALUE_LABEL IS NULL THEN 1 END) as appl_history_null_newvalue,
    COUNT(CASE WHEN n.NOTE_NEW_VALUE_RAW IS NULL THEN 1 END) as new_arch_null_newvalue
FROM ARCA.FRESHSNOW.APPL_HISTORY a
FULL OUTER JOIN DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES n
  ON a.APPLICATION_ID = n.APP_ID
  AND a.NOTE_TITLE = n.NOTE_TITLE
  AND ABS(DATEDIFF('second', a.CREATED, n.CREATED_TS)) < 5;

-- =============================================================================
-- 5. PERFORMANCE COMPARISON TESTS
-- =============================================================================

-- 5A: Query Performance Test - Simple SELECT
SELECT 
    'Performance Test - Row Sampling' as test_name,
    (SELECT COUNT(*) FROM ARCA.FRESHSNOW.APPL_HISTORY LIMIT 10000) as existing_sample_speed,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES LIMIT 10000) as new_arch_sample_speed;

-- 5B: Aggregation Performance Test
SELECT 
    'Performance Test - Aggregation' as test_name,
    'Compare aggregation speeds' as description;
    
-- Existing architecture aggregation
SELECT COUNT(*), COUNT(DISTINCT APPLICATION_ID), MAX(CREATED)
FROM ARCA.FRESHSNOW.APPL_HISTORY 
WHERE CREATED >= DATEADD(day, -30, CURRENT_DATE());

-- New architecture aggregation  
SELECT COUNT(*), COUNT(DISTINCT APP_ID), MAX(CREATED_TS)
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE CREATED_TS >= DATEADD(day, -30, CURRENT_DATE());

-- =============================================================================
-- 6. MATERIALIZATION READINESS TEST
-- =============================================================================

-- 6A: View to Table Conversion Test
CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES_TEST COPY GRANTS AS
SELECT * FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES LIMIT 1000;

-- 6B: Validate materialized table
SELECT 
    'Materialization Test' as test_name,
    COUNT(*) as materialized_records,
    COUNT(DISTINCT APP_ID) as unique_apps,
    MIN(CREATED_TS) as earliest_record,
    MAX(CREATED_TS) as latest_record
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES_TEST;

-- 6C: Clean up test table
DROP TABLE IF EXISTS DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES_TEST;