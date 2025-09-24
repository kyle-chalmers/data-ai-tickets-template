-- QC Test 4: VW_APPL_HISTORY Downstream Compatibility Validation
-- ==============================================================
--
-- Purpose: Validate that BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
--          can replace ARCA.FRESHSNOW.VW_APPL_HISTORY as the base for downstream
--          views like VW_APPL_STATUS_HISTORY
--
-- Key Requirements:
-- - Column mapping: APP_ID (new) → ENTITY_ID (current)
-- - Filter compatibility: NOTE_TITLE_DETAIL patterns
-- - Status transition logic preservation
--
-- Date Range: All data <= TEST_DATE_CUTOFF
-- ==============================================================

-- Test parameters
SET TEST_DATE_CUTOFF = '2025-09-22';

-- Test 4.1: Create Test Version of VW_APPL_STATUS_HISTORY Using LOANPRO_APP_SYSTEM_NOTES
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST(
    APPLICATION_STATUS_HISTORY_ID,
    APPLICATION_ID,
    OLD_STATUS_VALUE,
    NEW_STATUS_VALUE,
    OLD_STATUS_BEGIN_DATETIME,
    NEW_STATUS_BEGIN_DATETIME,
    TIME_SPENT_IN_OLD_STATUS,
    TERMINAL_STATUS,
    IS_LATEST_STATUS,
    IS_DELETED,
    LAST_MODIFIED_BY
) AS
WITH APPL_HISTORY AS (
    SELECT
        APP_ID AS APPLICATION_ID,  -- Key mapping change: APP_ID → APPLICATION_ID
        NOTE_OLD_VALUE AS OLDVALUE,
        NOTE_NEW_VALUE AS NEWVALUE,
        CREATED_TS AS CREATED,
        NOTE_TITLE_DETAIL,
        DELETED,
        NULL AS CREATE_USER,  -- Not available in new table
        ROW_NUMBER() OVER (
            PARTITION BY APP_ID, NOTE_OLD_VALUE, NOTE_NEW_VALUE
            ORDER BY CREATED_TS ASC
        ) AS rnk,
        LAG(CREATED_TS) OVER (
            PARTITION BY APP_ID
            ORDER BY CREATED_TS ASC
        ) AS PREV_CHANGE,
        LAG(CREATED_TS) OVER (
            PARTITION BY APP_ID
            ORDER BY CREATED_TS ASC,
                CASE
                    WHEN NOTE_OLD_VALUE IN ('Started', 'Affiliate Started') THEN 1
                    WHEN NOTE_OLD_VALUE IN ('Declined', 'Fraud Rejected', 'ICS', 'Applied',
                                      'Affiliate Landed', 'Offers Decision Requested', 'Offers Decision Received') THEN 2
                    ELSE 3
                END ASC
        ) AS SORTED_PREV_CHANGE
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
    WHERE UPPER(NOTE_TITLE_DETAIL) IN ('LOAN SUB STATUS', 'LOAN STATUS - LOAN SUB STATUS')
        AND CREATED_TS <= $TEST_DATE_CUTOFF
)
, INITIAL_PULL AS (
    SELECT
        APPLICATION_ID,
        OLDVALUE,
        NEWVALUE,
        CREATED,
        COALESCE(PREV_CHANGE, CREATED) AS PREV_CHANGE,
        NOTE_TITLE_DETAIL,
        DELETED,
        CREATE_USER
    FROM APPL_HISTORY
    WHERE OLDVALUE <> NEWVALUE
    QUALIFY rnk = 1

    UNION ALL

    SELECT
        APPLICATION_ID,
        NULL AS OLDVALUE,
        OLDVALUE AS NEWVALUE,
        CREATED AS NEXT_CHANGE,
        SORTED_PREV_CHANGE AS PREV_CHANGE,
        NOTE_TITLE_DETAIL,
        DELETED,
        CREATE_USER
    FROM APPL_HISTORY
    WHERE PREV_CHANGE IS NULL
)
, TIME_DIFFERENCE AS (
    SELECT
        APPLICATION_ID,
        OLDVALUE,
        NEWVALUE,
        PREV_CHANGE,
        CREATED,
        NOTE_TITLE_DETAIL,
        DELETED,
        CREATE_USER,
        TIMESTAMPDIFF(SECOND, PREV_CHANGE, CREATED) / 3600 AS TIME_DIFFERENCE,
        ROW_NUMBER() OVER (
            PARTITION BY APPLICATION_ID
            ORDER BY CREATED DESC
        ) AS last_row
    FROM INITIAL_PULL
)
SELECT DISTINCT
    UUID_STRING() AS APPLICATION_STATUS_HISTORY_ID,
    APPLICATION_ID,
    OLDVALUE AS OLD_STATUS_VALUE,
    NEWVALUE AS NEW_STATUS_VALUE,
    PREV_CHANGE AS OLD_STATUS_BEGIN_DATETIME,
    CREATED AS NEW_STATUS_BEGIN_DATETIME,
    TIME_DIFFERENCE AS TIME_SPENT_IN_OLD_STATUS,
    CASE
        WHEN UPPER(NEWVALUE) IN ('EXPIRED', 'DECLINED', 'WITHDRAWN', 'ORIGINATED', 'FUNDED',
                                 'FRAUD REJECTED', 'PARTNER REJECTED') THEN TRUE
        ELSE FALSE
    END AS TERMINAL_STATUS,
    CASE WHEN last_row = 1 THEN TRUE ELSE FALSE END AS IS_LATEST_STATUS,
    DELETED != 0 AS IS_DELETED,
    CREATE_USER AS LAST_MODIFIED_BY
FROM TIME_DIFFERENCE
ORDER BY CREATED ASC;

-- Test 4.2: Record Count Comparison Between Current and Test Views
SELECT 'Record Count Comparison' as test_name,
       'Current VW_APPL_STATUS_HISTORY' as source,
       COUNT(*) as record_count,
       COUNT(DISTINCT APPLICATION_ID) as unique_applications,
       MIN(NEW_STATUS_BEGIN_DATETIME) as min_date,
       MAX(NEW_STATUS_BEGIN_DATETIME) as max_date
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF

UNION ALL

SELECT 'Record Count Comparison' as test_name,
       'Test VW_APPL_STATUS_HISTORY' as source,
       COUNT(*) as record_count,
       COUNT(DISTINCT APPLICATION_ID) as unique_applications,
       MIN(NEW_STATUS_BEGIN_DATETIME) as min_date,
       MAX(NEW_STATUS_BEGIN_DATETIME) as max_date
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF

ORDER BY test_name, source;

-- Test 4.3: Status Value Distribution Comparison
SELECT 'Status Distribution' as test_name,
       'Current View' as source,
       NEW_STATUS_VALUE,
       COUNT(*) as count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
GROUP BY NEW_STATUS_VALUE

UNION ALL

SELECT 'Status Distribution' as test_name,
       'Test View' as source,
       NEW_STATUS_VALUE,
       COUNT(*) as count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
GROUP BY NEW_STATUS_VALUE

ORDER BY test_name, source, count DESC
LIMIT 20;

-- Test 4.4: Terminal Status Logic Validation
SELECT 'Terminal Status Logic' as test_name,
       'Current View' as source,
       TERMINAL_STATUS,
       COUNT(*) as count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
GROUP BY TERMINAL_STATUS

UNION ALL

SELECT 'Terminal Status Logic' as test_name,
       'Test View' as source,
       TERMINAL_STATUS,
       COUNT(*) as count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
GROUP BY TERMINAL_STATUS

ORDER BY test_name, source, TERMINAL_STATUS;

-- Test 4.5: Application ID Overlap Analysis
WITH current_apps AS (
    SELECT DISTINCT APPLICATION_ID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
    WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
),
test_apps AS (
    SELECT DISTINCT APPLICATION_ID
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
    WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
)
SELECT
    'Application ID Overlap' as test_name,
    'Apps in Current Only' as category,
    COUNT(*) as count
FROM current_apps c
LEFT JOIN test_apps t ON c.APPLICATION_ID = t.APPLICATION_ID
WHERE t.APPLICATION_ID IS NULL

UNION ALL

SELECT
    'Application ID Overlap' as test_name,
    'Apps in Test Only' as category,
    COUNT(*) as count
FROM test_apps t
LEFT JOIN current_apps c ON t.APPLICATION_ID = c.APPLICATION_ID
WHERE c.APPLICATION_ID IS NULL

UNION ALL

SELECT
    'Application ID Overlap' as test_name,
    'Apps in Both' as category,
    COUNT(*) as count
FROM current_apps c
INNER JOIN test_apps t ON c.APPLICATION_ID = t.APPLICATION_ID

ORDER BY test_name, category;

-- Test 4.6: Sample Status Transitions Comparison
WITH sample_apps AS (
    SELECT DISTINCT APPLICATION_ID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
    WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
    ORDER BY APPLICATION_ID
    LIMIT 5
),
current_sample AS (
    SELECT
        s.APPLICATION_ID,
        h.OLD_STATUS_VALUE,
        h.NEW_STATUS_VALUE,
        h.NEW_STATUS_BEGIN_DATETIME,
        h.TIME_SPENT_IN_OLD_STATUS,
        h.TERMINAL_STATUS,
        'Current View' as source
    FROM sample_apps s
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY h
        ON s.APPLICATION_ID = h.APPLICATION_ID
    WHERE h.NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
),
test_sample AS (
    SELECT
        s.APPLICATION_ID,
        h.OLD_STATUS_VALUE,
        h.NEW_STATUS_VALUE,
        h.NEW_STATUS_BEGIN_DATETIME,
        h.TIME_SPENT_IN_OLD_STATUS,
        h.TERMINAL_STATUS,
        'Test View' as source
    FROM sample_apps s
    JOIN BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST h
        ON s.APPLICATION_ID = h.APPLICATION_ID
    WHERE h.NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
)
SELECT
    'Status Transition Sample' as test_name,
    source,
    APPLICATION_ID,
    OLD_STATUS_VALUE,
    NEW_STATUS_VALUE,
    NEW_STATUS_BEGIN_DATETIME,
    TIME_SPENT_IN_OLD_STATUS,
    TERMINAL_STATUS
FROM current_sample

UNION ALL

SELECT
    'Status Transition Sample' as test_name,
    source,
    APPLICATION_ID,
    OLD_STATUS_VALUE,
    NEW_STATUS_VALUE,
    NEW_STATUS_BEGIN_DATETIME,
    TIME_SPENT_IN_OLD_STATUS,
    TERMINAL_STATUS
FROM test_sample

ORDER BY test_name, source, APPLICATION_ID, NEW_STATUS_BEGIN_DATETIME;

-- Test 4.7: Filter Compatibility Test
SELECT 'Filter Compatibility' as test_name,
       'Base LOANPRO_APP_SYSTEM_NOTES' as source,
       'Records matching STATUS filters' as filter_type,
       COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
WHERE UPPER(NOTE_TITLE_DETAIL) IN ('LOAN SUB STATUS', 'LOAN STATUS - LOAN SUB STATUS')
    AND CREATED_TS <= $TEST_DATE_CUTOFF

UNION ALL

SELECT 'Filter Compatibility' as test_name,
       'Base ARCA.FRESHSNOW.VW_APPL_HISTORY' as source,
       'Records matching STATUS filters' as filter_type,
       COUNT(*) as record_count
FROM ARCA.FRESHSNOW.VW_APPL_HISTORY
WHERE UPPER(NOTE_TITLE_DETAIL) IN ('LOAN SUB STATUS', 'LOAN STATUS - LOAN SUB STATUS')
    AND CREATED <= $TEST_DATE_CUTOFF

ORDER BY test_name, source;

-- Test 4.8: Time Calculation Validation
WITH time_validation AS (
    SELECT
        APPLICATION_ID,
        AVG(TIME_SPENT_IN_OLD_STATUS) as avg_time_current,
        COUNT(*) as transition_count_current
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
    WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
        AND TIME_SPENT_IN_OLD_STATUS IS NOT NULL
        AND TIME_SPENT_IN_OLD_STATUS > 0
    GROUP BY APPLICATION_ID
    HAVING COUNT(*) >= 2
    ORDER BY APPLICATION_ID
    LIMIT 10
)
SELECT
    'Time Calculation Validation' as test_name,
    'Current vs Test View Accuracy' as validation_type,
    tv.APPLICATION_ID,
    tv.avg_time_current,
    tv.transition_count_current,
    AVG(h.TIME_SPENT_IN_OLD_STATUS) as avg_time_test,
    COUNT(h.*) as transition_count_test,
    ABS(tv.avg_time_current - AVG(h.TIME_SPENT_IN_OLD_STATUS)) as time_difference
FROM time_validation tv
JOIN BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST h
    ON tv.APPLICATION_ID = h.APPLICATION_ID
WHERE h.NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF
    AND h.TIME_SPENT_IN_OLD_STATUS IS NOT NULL
    AND h.TIME_SPENT_IN_OLD_STATUS > 0
GROUP BY tv.APPLICATION_ID, tv.avg_time_current, tv.transition_count_current
ORDER BY time_difference DESC;

-- Test 4.9: Overall Compatibility Assessment
WITH compatibility_metrics AS (
    SELECT
        (SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
         WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF) as current_count,
        (SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
         WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF) as test_count,
        (SELECT COUNT(DISTINCT APPLICATION_ID) FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_STATUS_HISTORY
         WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF) as current_apps,
        (SELECT COUNT(DISTINCT APPLICATION_ID) FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
         WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF) as test_apps
)
SELECT
    'QC Test 4 Summary' as test_name,
    'VW_APPL_HISTORY Downstream Compatibility' as description,
    current_count,
    test_count,
    current_apps,
    test_apps,
    CASE
        WHEN test_count > 0 THEN 'VIEW CREATED SUCCESSFULLY'
        ELSE 'VIEW CREATION FAILED'
    END as view_creation_result,
    CASE
        WHEN ABS(current_count - test_count) / GREATEST(current_count, 1) < 0.05
        THEN 'COMPATIBLE - Less than 5% difference'
        WHEN ABS(current_count - test_count) / GREATEST(current_count, 1) < 0.20
        THEN 'MOSTLY COMPATIBLE - Less than 20% difference'
        ELSE 'NEEDS INVESTIGATION - Significant differences'
    END as compatibility_assessment,
    ROUND(ABS(current_count - test_count) * 100.0 / GREATEST(current_count, 1), 2) as percentage_difference,
    CURRENT_TIMESTAMP() as test_completed_at
FROM compatibility_metrics;

-- Test 4.10: Column Mapping Validation
SELECT 'Column Mapping Validation' as test_name,
       'APP_ID to APPLICATION_ID mapping' as mapping_type,
       COUNT(DISTINCT APPLICATION_ID) as unique_applications,
       MIN(APPLICATION_ID) as min_app_id,
       MAX(APPLICATION_ID) as max_app_id,
       CASE
           WHEN COUNT(DISTINCT APPLICATION_ID) > 0 THEN 'MAPPING SUCCESSFUL'
           ELSE 'MAPPING FAILED'
       END as mapping_result
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST
WHERE NEW_STATUS_BEGIN_DATETIME <= $TEST_DATE_CUTOFF;

-- Clean up test view
-- DROP VIEW IF EXISTS BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_APPL_STATUS_HISTORY_TEST;