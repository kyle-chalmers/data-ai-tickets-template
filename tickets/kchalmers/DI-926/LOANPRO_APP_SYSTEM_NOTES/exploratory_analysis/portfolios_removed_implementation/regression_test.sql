-- DI-926: Regression Test - Validate no impact on existing functionality
-- Compare key metrics between old and new implementations

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- Test 1: Record counts comparison (should be same or higher in dev)
WITH count_comparison AS (
    SELECT
        'DEV' as source,
        COUNT(*) as total_records,
        COUNT(DISTINCT RECORD_ID) as unique_record_ids,
        COUNT(DISTINCT APP_ID) as unique_app_ids
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
    WHERE CREATED_TS <= '2025-09-21'

    UNION ALL

    SELECT
        'PROD' as source,
        COUNT(*) as total_records,
        COUNT(DISTINCT RECORD_ID) as unique_record_ids,
        COUNT(DISTINCT APP_ID) as unique_app_ids
    FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
    WHERE CREATED_TS <= '2025-09-21'
)
SELECT
    source,
    total_records,
    unique_record_ids,
    unique_app_ids,
    CASE WHEN source = 'DEV' THEN
        LAG(total_records) OVER (ORDER BY source DESC) - total_records
    END as record_difference
FROM count_comparison
ORDER BY source;

-- Test 2: NOTE_TITLE_DETAIL distribution comparison
WITH dev_titles AS (
    SELECT
        NOTE_TITLE_DETAIL,
        COUNT(*) as dev_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
    WHERE CREATED_TS <= '2025-09-21'
        AND NOTE_TITLE_DETAIL IS NOT NULL
    GROUP BY NOTE_TITLE_DETAIL
),
prod_titles AS (
    SELECT
        NOTE_TITLE_DETAIL,
        COUNT(*) as prod_count
    FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
    WHERE CREATED_TS <= '2025-09-21'
        AND NOTE_TITLE_DETAIL IS NOT NULL
    GROUP BY NOTE_TITLE_DETAIL
)
SELECT
    COALESCE(d.NOTE_TITLE_DETAIL, p.NOTE_TITLE_DETAIL) as note_title_detail,
    COALESCE(d.dev_count, 0) as dev_count,
    COALESCE(p.prod_count, 0) as prod_count,
    COALESCE(d.dev_count, 0) - COALESCE(p.prod_count, 0) as count_difference,
    CASE
        WHEN p.prod_count IS NULL THEN 'NEW_IN_DEV'
        WHEN d.dev_count IS NULL THEN 'MISSING_IN_DEV'
        WHEN ABS(COALESCE(d.dev_count, 0) - COALESCE(p.prod_count, 0)) <= 100 THEN 'WITHIN_TOLERANCE'
        ELSE 'SIGNIFICANT_DIFFERENCE'
    END as status
FROM dev_titles d
FULL OUTER JOIN prod_titles p ON d.NOTE_TITLE_DETAIL = p.NOTE_TITLE_DETAIL
ORDER BY ABS(COALESCE(d.dev_count, 0) - COALESCE(p.prod_count, 0)) DESC;

-- Test 3: PORTFOLIOS_ADDED functionality regression test
WITH dev_portfolios AS (
    SELECT
        PORTFOLIOS_ADDED,
        PORTFOLIOS_ADDED_CATEGORY,
        PORTFOLIOS_ADDED_LABEL,
        COUNT(*) as dev_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
    WHERE PORTFOLIOS_ADDED IS NOT NULL
        AND CREATED_TS <= '2025-09-21'
    GROUP BY PORTFOLIOS_ADDED, PORTFOLIOS_ADDED_CATEGORY, PORTFOLIOS_ADDED_LABEL
),
prod_portfolios AS (
    SELECT
        PORTFOLIOS_ADDED,
        PORTFOLIOS_ADDED_CATEGORY,
        PORTFOLIOS_ADDED_LABEL,
        COUNT(*) as prod_count
    FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
    WHERE PORTFOLIOS_ADDED IS NOT NULL
        AND CREATED_TS <= '2025-09-21'
    GROUP BY PORTFOLIOS_ADDED, PORTFOLIOS_ADDED_CATEGORY, PORTFOLIOS_ADDED_LABEL
)
SELECT
    'PORTFOLIOS_ADDED Regression Test' as test_type,
    COUNT(*) as total_unique_combinations,
    SUM(CASE WHEN d.PORTFOLIOS_ADDED IS NOT NULL AND p.PORTFOLIOS_ADDED IS NOT NULL THEN 1 ELSE 0 END) as matching_combinations,
    SUM(CASE WHEN d.PORTFOLIOS_ADDED IS NOT NULL AND p.PORTFOLIOS_ADDED IS NULL THEN 1 ELSE 0 END) as new_in_dev,
    SUM(CASE WHEN d.PORTFOLIOS_ADDED IS NULL AND p.PORTFOLIOS_ADDED IS NOT NULL THEN 1 ELSE 0 END) as missing_in_dev
FROM dev_portfolios d
FULL OUTER JOIN prod_portfolios p
    ON d.PORTFOLIOS_ADDED = p.PORTFOLIOS_ADDED
    AND COALESCE(d.PORTFOLIOS_ADDED_CATEGORY, '') = COALESCE(p.PORTFOLIOS_ADDED_CATEGORY, '')
    AND COALESCE(d.PORTFOLIOS_ADDED_LABEL, '') = COALESCE(p.PORTFOLIOS_ADDED_LABEL, '');

-- Test 4: Sample of records with different column patterns to verify no breakage
SELECT
    'Column Pattern Test' as test_type,
    NOTE_TITLE_DETAIL,
    COUNT(*) as record_count,
    COUNT(CASE WHEN NOTE_NEW_VALUE IS NOT NULL THEN 1 END) as has_new_value,
    COUNT(CASE WHEN NOTE_NEW_VALUE_LABEL IS NOT NULL THEN 1 END) as has_new_value_label,
    COUNT(CASE WHEN NOTE_OLD_VALUE IS NOT NULL THEN 1 END) as has_old_value,
    COUNT(CASE WHEN NOTE_OLD_VALUE_LABEL IS NOT NULL THEN 1 END) as has_old_value_label,
    COUNT(CASE WHEN PORTFOLIOS_ADDED IS NOT NULL THEN 1 END) as has_portfolios_added,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED IS NOT NULL THEN 1 END) as has_portfolios_removed
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE CREATED_TS >= '2025-09-20'
GROUP BY NOTE_TITLE_DETAIL
ORDER BY record_count DESC
LIMIT 20;

-- Test 5: Verify new PORTFOLIOS_REMOVED columns work correctly
SELECT
    'PORTFOLIOS_REMOVED Validation' as test_type,
    COUNT(*) as total_removed_records,
    COUNT(DISTINCT PORTFOLIOS_REMOVED) as unique_portfolio_ids,
    COUNT(DISTINCT PORTFOLIOS_REMOVED_LABEL) as unique_portfolio_labels,
    COUNT(DISTINCT PORTFOLIOS_REMOVED_CATEGORY) as unique_portfolio_categories,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED IS NOT NULL AND PORTFOLIOS_REMOVED_LABEL IS NULL THEN 1 END) as missing_labels,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED IS NOT NULL AND PORTFOLIOS_REMOVED_CATEGORY IS NULL THEN 1 END) as missing_categories
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE PORTFOLIOS_REMOVED IS NOT NULL
    AND CREATED_TS >= '2025-09-01';