-- DI-926: Top 500 Sample Queries for ACTUAL Created LOANPRO_APP_SYSTEM_NOTES Objects
-- Generated: 2025-08-27
-- Purpose: Sample data from all objects actually created during the migration
-- Note: Corrected to reflect actual objects created (no DEVELOPMENT.FRESHSNOW views exist)

-- =====================================================
-- CORE PRODUCTION VIEWS (3-Layer Architecture)
-- =====================================================

-- 1. FRESHSNOW Layer - Core data transformation (PRODUCTION SCHEMA)
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
ORDER BY RECORD_ID DESC;

-- 2. BRIDGE Layer - Pass-through view
SELECT TOP 500 *
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
ORDER BY RECORD_ID DESC;

-- 3. ANALYTICS Layer - Business-ready with enhancements
SELECT TOP 500 *
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES
ORDER BY RECORD_ID DESC;

-- =====================================================
-- ADVANCED ARCHITECTURE ENHANCEMENT OBJECTS
-- =====================================================

-- 4. Optimized Performance View - Enhanced with category mapping
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED
ORDER BY RECORD_ID DESC;

-- 5. Materialized Table - Partitioned and clustered
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED
ORDER BY CREATED_DATE DESC, RECORD_ID DESC;

-- =====================================================
-- FOUNDATION LOOKUP TABLES
-- =====================================================

-- 6. Category Mapping - Business-driven categories (732 total)
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.NOTE_CATEGORY_MAPPING
ORDER BY CATEGORY_ID;

-- 7. Value Types - Classification system (7 types)
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.NOTE_VALUE_TYPES
ORDER BY VALUE_TYPE_ID;

-- 8. Title Patterns - Regex matching rules (3 patterns)
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.NOTE_TITLE_PATTERNS
ORDER BY PATTERN_ID;

-- 9. Refresh Log - ETL tracking table
SELECT TOP 500 *
FROM ARCA.FRESHSNOW.LOANPRO_REFRESH_LOG
ORDER BY REFRESH_START_TS DESC;

-- =====================================================
-- SUMMARY QUERIES FOR VALIDATION
-- =====================================================

-- Record count comparison across main objects
SELECT 
    'FRESHSNOW_VIEW' as object_type,
    COUNT(*) as record_count,
    MAX(CREATED_TS) as latest_record
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES

UNION ALL

SELECT 
    'BRIDGE_VIEW' as object_type,
    COUNT(*) as record_count,
    MAX(CREATED_TS) as latest_record
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES

UNION ALL

SELECT 
    'ANALYTICS_VIEW' as object_type,
    COUNT(*) as record_count,
    MAX(CREATED_TS) as latest_record
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES

UNION ALL

SELECT 
    'OPTIMIZED_VIEW' as object_type,
    COUNT(*) as record_count,
    MAX(CREATED_TS) as latest_record
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED

UNION ALL

SELECT 
    'MATERIALIZED_TABLE' as object_type,
    COUNT(*) as record_count,
    MAX(CREATED_TS) as latest_record
FROM ARCA.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED

ORDER BY object_type;

-- =====================================================
-- SAMPLE DATA BY CATEGORY TYPE
-- =====================================================

-- Top 100 records by major category types from optimized view
SELECT TOP 100 
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    NOTE_TITLE_DETAIL,
    CATEGORY_TYPE,
    NOTE_NEW_VALUE,
    NOTE_OLD_VALUE,
    IS_STATUS_CHANGE,
    IS_PORTFOLIO_CHANGE
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED
WHERE CATEGORY_TYPE = 'SYSTEM'
ORDER BY CREATED_TS DESC;

SELECT TOP 100 
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    NOTE_TITLE_DETAIL,
    CATEGORY_TYPE,
    NOTE_NEW_VALUE,
    PORTFOLIOS_ADDED_CATEGORY,
    PORTFOLIOS_ADDED_LABEL
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED
WHERE CATEGORY_TYPE = 'PORTFOLIO'
ORDER BY CREATED_TS DESC;

SELECT TOP 100 
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    NOTE_TITLE_DETAIL,
    CATEGORY_TYPE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE_LABEL
FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES_OPTIMIZED
WHERE CATEGORY_TYPE = 'CUSTOM_FIELD'
ORDER BY CREATED_TS DESC;

-- =====================================================
-- COLUMN STRUCTURE VALIDATION
-- =====================================================

-- Show column structure for each main view/table
SELECT 
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA IN ('FRESHSNOW', 'BRIDGE', 'ANALYTICS')
  AND TABLE_NAME LIKE '%LOANPRO_APP_SYSTEM_NOTES%'
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;