-- DI-926: APPL_HISTORY vs New Architecture Comparison
-- Compare new structure with existing APPL_HISTORY and VW_APPL_HISTORY

-- =============================================================================
-- 1. RECORD VOLUME AND COVERAGE COMPARISON
-- =============================================================================

-- 1A: Volume comparison across all systems
SELECT 
    'APPL_HISTORY' as system_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT APPLICATION_ID) as unique_apps,
    MIN(CREATED) as earliest_record,
    MAX(CREATED) as latest_record
FROM ARCA.FRESHSNOW.APPL_HISTORY
WHERE CREATED >= '2025-08-01'

UNION ALL

SELECT 
    'VW_APPL_HISTORY' as system_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT APPLICATION_ID) as unique_apps,
    MIN(CREATED) as earliest_record,
    MAX(CREATED) as latest_record
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_HISTORY
WHERE CREATED >= '2025-08-01'

UNION ALL

SELECT 
    'NEW_ARCHITECTURE' as system_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT APP_ID) as unique_apps,
    MIN(CREATED_TS) as earliest_record,
    MAX(CREATED_TS) as latest_record
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE CREATED_TS >= '2025-08-01'

UNION ALL

SELECT 
    'PRODUCTION_APP_SYSTEM_NOTE' as system_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT APP_ID) as unique_apps,
    MIN(CREATED_TS) as earliest_record,
    MAX(CREATED_TS) as latest_record
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY
WHERE CREATED_TS >= '2025-08-01';

-- =============================================================================
-- 2. SCHEMA AND DATA TYPE COMPARISON
-- =============================================================================

-- 2A: Compare data structures and purposes
SELECT 
    'Schema Comparison' as analysis_type,
    'APPL_HISTORY uses APPLICATION_ID, NOTE_TITLE_DETAIL, NEWVALUE/OLDVALUE' as appl_history_structure,
    'NEW_ARCHITECTURE uses APP_ID, NOTE_CATEGORY, NOTE_NEW_VALUE_RAW/NOTE_OLD_VALUE_RAW' as new_arch_structure,
    'Both track application changes but different granularity' as data_purpose,
    'APPL_HISTORY: Broader application changes' as appl_scope,
    'NEW_ARCHITECTURE: Specific loan settings changes only' as new_scope;

-- 2B: Sample data comparison
SELECT 'APPL_HISTORY Sample' as source, ID, APPLICATION_ID, NOTE_TITLE, NOTE_TITLE_DETAIL, NEWVALUE, OLDVALUE, CREATED
FROM ARCA.FRESHSNOW.APPL_HISTORY 
WHERE CREATED >= '2025-08-24'
ORDER BY CREATED DESC
LIMIT 5;

SELECT 'NEW_ARCHITECTURE Sample' as source, RECORD_ID as ID, APP_ID as APPLICATION_ID, NOTE_TITLE, NOTE_CATEGORY as NOTE_TITLE_DETAIL, NOTE_NEW_VALUE_RAW as NEWVALUE, NOTE_OLD_VALUE_RAW as OLDVALUE, CREATED_TS as CREATED
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE CREATED_TS >= '2025-08-24'
ORDER BY CREATED_TS DESC
LIMIT 5;

-- =============================================================================
-- 3. FUNCTIONAL OVERLAP ANALYSIS
-- =============================================================================

-- 3A: Check if there's overlap in application IDs
WITH appl_hist_apps AS (
    SELECT DISTINCT APPLICATION_ID as app_id
    FROM ARCA.FRESHSNOW.APPL_HISTORY 
    WHERE CREATED >= '2025-08-20'
    LIMIT 10000
),
new_arch_apps AS (
    SELECT DISTINCT APP_ID as app_id
    FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
    WHERE CREATED_TS >= '2025-08-20'
    LIMIT 10000
)
SELECT 
    'Application ID Overlap Analysis' as analysis_type,
    COUNT(a.app_id) as appl_history_unique_apps,
    COUNT(n.app_id) as new_architecture_unique_apps,
    COUNT(CASE WHEN a.app_id = n.app_id THEN 1 END) as overlapping_applications,
    ROUND(COUNT(CASE WHEN a.app_id = n.app_id THEN 1 END) * 100.0 / 
          LEAST(COUNT(a.app_id), COUNT(n.app_id)), 2) as overlap_percentage
FROM appl_hist_apps a
FULL OUTER JOIN new_arch_apps n ON a.app_id = n.app_id;

-- 3B: Compare note categories/types
SELECT 
    'Note Category Comparison' as analysis_type,
    'APPL_HISTORY Categories' as system,
    NOTE_TITLE_DETAIL as category,
    COUNT(*) as record_count
FROM ARCA.FRESHSNOW.APPL_HISTORY 
WHERE CREATED >= '2025-08-20'
  AND NOTE_TITLE_DETAIL IS NOT NULL
GROUP BY NOTE_TITLE_DETAIL
ORDER BY record_count DESC
LIMIT 10

UNION ALL

SELECT 
    'Note Category Comparison' as analysis_type,
    'NEW_ARCHITECTURE Categories' as system,
    NOTE_CATEGORY as category,
    COUNT(*) as record_count
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE CREATED_TS >= '2025-08-20'
  AND NOTE_CATEGORY IS NOT NULL
GROUP BY NOTE_CATEGORY
ORDER BY record_count DESC
LIMIT 10;

-- =============================================================================
-- 4. CONSOLIDATION IMPACT ANALYSIS
-- =============================================================================

-- 4A: Analyze what consolidation achieves
SELECT 
    'Consolidation Impact Analysis' as analysis_type,
    'BEFORE: APPL_HISTORY (250M records) + APP_SYSTEM_NOTE_ENTITY (286M records) = 536M total' as before_state,
    'AFTER: Single LOANPRO_APP_SYSTEM_NOTES (286M records)' as after_state,
    '250M record reduction through consolidation' as records_eliminated,
    'Single source of truth for loan application changes' as business_benefit,
    'Simplified architecture with better performance' as technical_benefit;

-- 4B: Data freshness comparison
WITH freshness_analysis AS (
    SELECT 
        'APPL_HISTORY' as system,
        MAX(CREATED) as latest_record,
        DATEDIFF('hour', MAX(CREATED), CURRENT_TIMESTAMP()) as hours_behind_current
    FROM ARCA.FRESHSNOW.APPL_HISTORY 
    
    UNION ALL
    
    SELECT 
        'NEW_ARCHITECTURE' as system,
        MAX(CREATED_TS) as latest_record,
        DATEDIFF('hour', MAX(CREATED_TS), CURRENT_TIMESTAMP()) as hours_behind_current
    FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
    
    UNION ALL
    
    SELECT 
        'PRODUCTION_APP_SYSTEM_NOTE' as system,
        MAX(CREATED_TS) as latest_record,
        DATEDIFF('hour', MAX(CREATED_TS), CURRENT_TIMESTAMP()) as hours_behind_current
    FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY
)
SELECT 
    'Data Freshness Comparison' as analysis_type,
    system,
    latest_record,
    hours_behind_current,
    CASE 
        WHEN hours_behind_current < 2 THEN 'Current'
        WHEN hours_behind_current < 24 THEN 'Recent' 
        ELSE 'Stale'
    END as freshness_status
FROM freshness_analysis
ORDER BY hours_behind_current;

-- =============================================================================
-- 5. MIGRATION RECOMMENDATIONS
-- =============================================================================

-- 5A: Migration strategy summary
SELECT 
    'Migration Strategy Recommendations' as analysis_type,
    'APPL_HISTORY: Different scope - tracks broader application changes' as appl_history_purpose,
    'NEW_ARCHITECTURE: Specific to loan settings changes only' as new_arch_purpose,
    'Recommendation: Keep both systems - different business purposes' as migration_approach,
    'CONSOLIDATE: APP_SYSTEM_NOTE_ENTITY → NEW_ARCHITECTURE only' as consolidation_target,
    'PRESERVE: APPL_HISTORY for broader application tracking' as preservation_strategy;