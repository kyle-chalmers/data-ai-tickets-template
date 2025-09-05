-- DI-926: Production vs Development QC Comparison Queries
-- Compare BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY vs DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES
-- Exclude records from today onward (using CREATED_TS)

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- 1. Overall Record Count Comparison (excluding today onward)
SELECT 
    'Production (BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY)' as source,
    COUNT(*) as total_records,
    MIN(CREATED_TS) as earliest_date,
    MAX(CREATED_TS) as latest_date,
    COUNT(DISTINCT APP_ID) as unique_app_ids
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
WHERE CREATED_TS < CURRENT_DATE()
UNION ALL
SELECT 
    'Development (DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES)' as source,
    COUNT(*) as total_records,
    MIN(CREATED_TS) as earliest_date,
    MAX(CREATED_TS) as latest_date,
    COUNT(DISTINCT APP_ID) as unique_app_ids
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
WHERE CREATED_TS < CURRENT_DATE()
ORDER BY source;

-- 2. Record ID Overlap Analysis
WITH prod_records AS (
    SELECT RECORD_ID, APP_ID, CREATED_TS, NOTE_TITLE_DETAIL
    FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
    WHERE CREATED_TS < CURRENT_DATE()
),
dev_records AS (
    SELECT RECORD_ID, APP_ID, CREATED_TS, NOTE_TITLE_DETAIL
    FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
    WHERE CREATED_TS < CURRENT_DATE()
)
SELECT 
    'Records in Production Only' as comparison_type,
    COUNT(*) as record_count
FROM prod_records p
LEFT JOIN dev_records d ON p.RECORD_ID = d.RECORD_ID
WHERE d.RECORD_ID IS NULL

UNION ALL

SELECT 
    'Records in Development Only' as comparison_type,
    COUNT(*) as record_count
FROM dev_records d
LEFT JOIN prod_records p ON d.RECORD_ID = p.RECORD_ID
WHERE p.RECORD_ID IS NULL

UNION ALL

SELECT 
    'Records in Both Systems' as comparison_type,
    COUNT(*) as record_count
FROM prod_records p
INNER JOIN dev_records d ON p.RECORD_ID = d.RECORD_ID

ORDER BY comparison_type;

-- 3. Count Comparison by APP_ID (Top 20 APP_IDs by volume)
WITH prod_counts AS (
    SELECT 
        APP_ID,
        COUNT(*) as prod_count,
        MIN(CREATED_TS) as prod_min_date,
        MAX(CREATED_TS) as prod_max_date
    FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
    WHERE CREATED_TS < CURRENT_DATE()
    GROUP BY APP_ID
),
dev_counts AS (
    SELECT 
        APP_ID,
        COUNT(*) as dev_count,
        MIN(CREATED_TS) as dev_min_date,
        MAX(CREATED_TS) as dev_max_date
    FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
    WHERE CREATED_TS < CURRENT_DATE()
    GROUP BY APP_ID
),
combined_counts AS (
    SELECT 
        COALESCE(p.APP_ID, d.APP_ID) as APP_ID,
        COALESCE(p.prod_count, 0) as production_count,
        COALESCE(d.dev_count, 0) as development_count,
        (COALESCE(d.dev_count, 0) - COALESCE(p.prod_count, 0)) as count_difference,
        CASE 
            WHEN p.prod_count IS NULL THEN 'Dev Only'
            WHEN d.dev_count IS NULL THEN 'Prod Only'
            WHEN p.prod_count = d.dev_count THEN 'Match'
            ELSE 'Mismatch'
        END as comparison_status,
        p.prod_min_date,
        p.prod_max_date,
        d.dev_min_date,
        d.dev_max_date
    FROM prod_counts p
    FULL OUTER JOIN dev_counts d ON p.APP_ID = d.APP_ID
)
SELECT *
FROM combined_counts
WHERE comparison_status != 'Match' OR production_count > 100  -- Focus on mismatches and high-volume apps
ORDER BY ABS(count_difference) DESC, production_count DESC
LIMIT 20;

-- 4. Detailed Differences Sample (Records that exist in both but may have different values)
WITH prod_sample AS (
    SELECT 
        RECORD_ID, 
        APP_ID, 
        CREATED_TS,
        NOTE_TITLE_DETAIL as prod_note_title_detail,
        LOAN_STATUS_NEW as prod_loan_status_new,
        LOAN_STATUS_OLD as prod_loan_status_old,
        NOTE_NEW_VALUE as prod_note_new_value,
        NOTE_OLD_VALUE as prod_note_old_value
    FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
    WHERE CREATED_TS < CURRENT_DATE()
),
dev_sample AS (
    SELECT 
        RECORD_ID, 
        APP_ID, 
        CREATED_TS,
        NOTE_TITLE_DETAIL as dev_note_title_detail,
        LOAN_STATUS_NEW as dev_loan_status_new,
        LOAN_STATUS_OLD as dev_loan_status_old,
        NOTE_NEW_VALUE as dev_note_new_value,
        NOTE_OLD_VALUE as dev_note_old_value
    FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
    WHERE CREATED_TS < CURRENT_DATE()
)
SELECT 
    p.RECORD_ID,
    p.APP_ID,
    p.CREATED_TS,
    -- Flag differences
    CASE WHEN p.prod_note_title_detail != d.dev_note_title_detail THEN 'DIFF' ELSE 'MATCH' END as note_title_detail_comparison,
    CASE WHEN p.prod_loan_status_new != d.dev_loan_status_new THEN 'DIFF' ELSE 'MATCH' END as loan_status_new_comparison,
    CASE WHEN p.prod_note_new_value != d.dev_note_new_value THEN 'DIFF' ELSE 'MATCH' END as note_new_value_comparison,
    -- Show actual values for comparison
    p.prod_note_title_detail,
    d.dev_note_title_detail,
    p.prod_loan_status_new,
    d.dev_loan_status_new,
    p.prod_note_new_value,
    d.dev_note_new_value
FROM prod_sample p
INNER JOIN dev_sample d ON p.RECORD_ID = d.RECORD_ID
WHERE (
    p.prod_note_title_detail != d.dev_note_title_detail OR
    p.prod_loan_status_new != d.dev_loan_status_new OR 
    p.prod_note_new_value != d.dev_note_new_value
)
ORDER BY p.CREATED_TS DESC
LIMIT 100;

-- 5. Category Distribution Comparison
WITH prod_categories AS (
    SELECT 
        NOTE_TITLE_DETAIL as category,
        COUNT(*) as prod_count,
        COUNT(DISTINCT APP_ID) as prod_unique_apps
    FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
    WHERE CREATED_TS < CURRENT_DATE()
    GROUP BY NOTE_TITLE_DETAIL
),
dev_categories AS (
    SELECT 
        NOTE_TITLE_DETAIL as category,
        COUNT(*) as dev_count,
        COUNT(DISTINCT APP_ID) as dev_unique_apps
    FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
    WHERE CREATED_TS < CURRENT_DATE()
    GROUP BY NOTE_TITLE_DETAIL
)
SELECT 
    COALESCE(p.category, d.category) as category,
    COALESCE(p.prod_count, 0) as production_count,
    COALESCE(d.dev_count, 0) as development_count,
    (COALESCE(d.dev_count, 0) - COALESCE(p.prod_count, 0)) as count_difference,
    COALESCE(p.prod_unique_apps, 0) as prod_unique_apps,
    COALESCE(d.dev_unique_apps, 0) as dev_unique_apps,
    CASE 
        WHEN p.prod_count IS NULL THEN 'Dev Only'
        WHEN d.dev_count IS NULL THEN 'Prod Only'
        WHEN p.prod_count = d.dev_count THEN 'Match'
        ELSE 'Mismatch'
    END as comparison_status
FROM prod_categories p
FULL OUTER JOIN dev_categories d ON p.category = d.category
ORDER BY ABS(COALESCE(d.dev_count, 0) - COALESCE(p.prod_count, 0)) DESC;

-- 6. Date Range Coverage Comparison
SELECT 
    DATE_TRUNC('month', CREATED_TS) as month_year,
    COUNT(*) as production_records
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
WHERE CREATED_TS < CURRENT_DATE()
GROUP BY DATE_TRUNC('month', CREATED_TS)

UNION ALL

SELECT 
    DATE_TRUNC('month', CREATED_TS) as month_year,
    COUNT(*) * -1 as development_records  -- Negative for visual distinction
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
WHERE CREATED_TS < CURRENT_DATE()
GROUP BY DATE_TRUNC('month', CREATED_TS)

ORDER BY month_year DESC
LIMIT 24;  -- Last 24 months

-- 7. Data Quality Check - NULL Values Comparison
SELECT 
    'Production NULL Analysis' as source,
    COUNT(*) as total_records,
    SUM(CASE WHEN APP_ID IS NULL THEN 1 ELSE 0 END) as null_app_id,
    SUM(CASE WHEN NOTE_TITLE_DETAIL IS NULL THEN 1 ELSE 0 END) as null_note_title_detail,
    SUM(CASE WHEN LOAN_STATUS_NEW IS NULL THEN 1 ELSE 0 END) as null_loan_status_new,
    SUM(CASE WHEN NOTE_NEW_VALUE IS NULL THEN 1 ELSE 0 END) as null_note_new_value
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY 
WHERE CREATED_TS < CURRENT_DATE()

UNION ALL

SELECT 
    'Development NULL Analysis' as source,
    COUNT(*) as total_records,
    SUM(CASE WHEN APP_ID IS NULL THEN 1 ELSE 0 END) as null_app_id,
    SUM(CASE WHEN NOTE_TITLE_DETAIL IS NULL THEN 1 ELSE 0 END) as null_note_title_detail,
    SUM(CASE WHEN LOAN_STATUS_NEW IS NULL THEN 1 ELSE 0 END) as null_loan_status_new,
    SUM(CASE WHEN NOTE_NEW_VALUE IS NULL THEN 1 ELSE 0 END) as null_note_new_value
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES 
WHERE CREATED_TS < CURRENT_DATE();