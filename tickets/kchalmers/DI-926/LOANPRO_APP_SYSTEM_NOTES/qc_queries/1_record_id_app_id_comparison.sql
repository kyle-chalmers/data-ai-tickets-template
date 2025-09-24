-- DI-926: Record ID and App ID Comparison
-- Compares RECORD_ID and APP_ID between dev and production tables
-- Expected result: All records should match

-- Test parameters
SET TEST_DATE_CUTOFF = '2025-09-22';

-- Test 1.1: Count Comparison
WITH dev_counts AS (
    SELECT
        COUNT(DISTINCT RECORD_ID) as dev_record_count,
        COUNT(DISTINCT APP_ID) as dev_app_count,
        COUNT(*) as dev_total_rows
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
    WHERE created_ts <= $TEST_DATE_CUTOFF
),
prod_counts AS (
    SELECT
        COUNT(DISTINCT RECORD_ID) as prod_record_count,
        COUNT(DISTINCT APP_ID) as prod_app_count,
        COUNT(*) as prod_total_rows
    FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
    WHERE created_ts <= $TEST_DATE_CUTOFF
)
SELECT
    'Count Comparison' as check_type,
    d.dev_record_count,
    p.prod_record_count,
    d.dev_record_count - p.prod_record_count as record_id_diff,
    d.dev_app_count,
    p.prod_app_count,
    d.dev_app_count - p.prod_app_count as app_id_diff,
    d.dev_total_rows,
    p.prod_total_rows,
    d.dev_total_rows - p.prod_total_rows as total_rows_diff
FROM dev_counts d, prod_counts p;

-- Test 1.2: Record ID Mismatch Analysis
WITH dev_records AS (
    SELECT DISTINCT RECORD_ID, APP_ID
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
    WHERE created_ts <= $TEST_DATE_CUTOFF
),
prod_records AS (
    SELECT DISTINCT RECORD_ID, APP_ID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
    WHERE created_ts <= $TEST_DATE_CUTOFF
),
mismatches AS (
    -- Records in dev but not in prod
    SELECT
        'In Dev Only' as mismatch_type,
        d.RECORD_ID,
        d.APP_ID
    FROM dev_records d
    LEFT JOIN prod_records p ON d.RECORD_ID = p.RECORD_ID
    WHERE p.RECORD_ID IS NULL

    UNION ALL

    -- Records in prod but not in dev
    SELECT
        'In Prod Only' as mismatch_type,
        p.RECORD_ID,
        p.APP_ID
    FROM prod_records p
    LEFT JOIN dev_records d ON p.RECORD_ID = d.RECORD_ID
    WHERE d.RECORD_ID IS NULL

    UNION ALL

    -- Records with matching RECORD_ID but different APP_ID
    SELECT
        'Different APP_ID' as mismatch_type,
        d.RECORD_ID,
        d.APP_ID
    FROM dev_records d
    INNER JOIN prod_records p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.APP_ID != p.APP_ID
)
SELECT
    mismatch_type,
    COUNT(*) as count,
    MIN(RECORD_ID) as sample_min_record_id,
    MAX(RECORD_ID) as sample_max_record_id
FROM mismatches
GROUP BY mismatch_type
ORDER BY mismatch_type;

-- Test 1.3: Dev-Only Records Sample
SELECT
    'Dev Only - Sample' as report_type,
    d.RECORD_ID,
    d.APP_ID,
    d.CREATED_TS,
    d.NOTE_TITLE,
    d.NOTE_TITLE_DETAIL
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
    ON d.RECORD_ID = p.RECORD_ID
WHERE p.RECORD_ID IS NULL
    AND d.created_ts <= '2025-09-21'
ORDER BY d.RECORD_ID DESC
LIMIT 20;

-- Test 1.4: Different APP_ID Records Sample
SELECT
    'Different APP_ID - Sample' as report_type,
    d.RECORD_ID,
    d.APP_ID as dev_app_id,
    p.APP_ID as prod_app_id,
    d.CREATED_TS,
    d.NOTE_TITLE,
    d.NOTE_TITLE_DETAIL as dev_note_title_detail,
    p.NOTE_TITLE_DETAIL as prod_note_title_detail
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
    ON d.RECORD_ID = p.RECORD_ID
WHERE d.APP_ID != p.APP_ID
    AND d.created_ts <= '2025-09-21'
    AND p.created_ts <= '2025-09-21'
ORDER BY d.RECORD_ID DESC
LIMIT 20;

-- Test 1.5: Dev-Only Records Analysis
WITH dev_only_records AS (
    SELECT d.*
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE p.RECORD_ID IS NULL
      AND d.created_ts <= '2025-09-21'
)
SELECT
    'Dev-Only Analysis' as analysis_type,
    COUNT(*) as total_dev_only_records,
    COUNT(DISTINCT APP_ID) as unique_app_ids,
    MIN(CREATED_TS) as earliest_created,
    MAX(CREATED_TS) as latest_created,
    COUNT(DISTINCT DATE(CREATED_TS)) as unique_dates,
    COUNT(DISTINCT NOTE_TITLE) as unique_note_titles,
    COUNT(DISTINCT NOTE_TITLE_DETAIL) as unique_note_details
FROM dev_only_records;

-- Test 1.6: Time Distribution Analysis
WITH dev_only_records AS (
    SELECT d.*
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE p.RECORD_ID IS NULL
      AND d.created_ts <= '2025-09-21'
)
SELECT
    DATE(CREATED_TS) as created_date,
    HOUR(CREATED_TS) as created_hour,
    COUNT(*) as record_count,
    COUNT(DISTINCT APP_ID) as unique_apps,
    COUNT(DISTINCT NOTE_TITLE_DETAIL) as unique_note_details
FROM dev_only_records
GROUP BY DATE(CREATED_TS), HOUR(CREATED_TS)
ORDER BY created_date, created_hour;

-- Test 1.7: Note Type Distribution Analysis
WITH dev_only_records AS (
    SELECT d.*
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE p.RECORD_ID IS NULL
      AND d.created_ts <= '2025-09-21'
)
SELECT
    NOTE_TITLE_DETAIL,
    COUNT(*) as record_count,
    COUNT(DISTINCT APP_ID) as unique_apps,
    MIN(CREATED_TS) as earliest,
    MAX(CREATED_TS) as latest,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM dev_only_records
GROUP BY NOTE_TITLE_DETAIL
ORDER BY record_count DESC
LIMIT 15;