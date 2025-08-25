-- DI-926: Testing Framework for Original Procedure Optimization
-- Compares Original vs Optimized vs New Architecture

-- =============================================================================
-- 1. BASELINE ESTABLISHMENT
-- =============================================================================

-- 1A: Current production table baseline (before optimization)
SELECT 
    'Original Production Table' as source,
    COUNT(*) as total_records,
    COUNT(DISTINCT app_id) as unique_apps,
    MIN(created_ts) as earliest_record,
    MAX(created_ts) as latest_record,
    COUNT(CASE WHEN note_title_detail IS NOT NULL THEN 1 END) as categorized_records,
    ROUND(AVG(LENGTH(note_data)), 2) as avg_note_data_length
FROM BUSINESS_INTELLIGENCE.BRIDGE.APP_SYSTEM_NOTE_ENTITY;

-- =============================================================================
-- 2. PERFORMANCE TESTING SETUP
-- =============================================================================

-- 2A: Create test sample for consistent comparison (recent 30 days)
CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.TEST_SAMPLE_SYSTEM_NOTES AS
SELECT *
FROM RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY 
WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
  AND REFERENCE_TYPE IN ('Entity.LoanSettings')
  AND CREATED >= DATEADD(day, -30, CURRENT_DATE())
  AND DELETED = 0
  AND IS_HARD_DELETED = FALSE
LIMIT 100000;  -- 100K record test sample

-- 2B: Validate test sample
SELECT 
    'Test Sample Created' as status,
    COUNT(*) as sample_records,
    COUNT(DISTINCT ENTITY_ID) as unique_entities,
    MIN(CREATED) as sample_start,
    MAX(CREATED) as sample_end
FROM DEVELOPMENT.FRESHSNOW.TEST_SAMPLE_SYSTEM_NOTES;

-- =============================================================================
-- 3. EXECUTION TIME COMPARISON
-- =============================================================================

-- 3A: Time the original procedure logic (on test sample)
SET start_time = (SELECT CURRENT_TIMESTAMP());

CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST AS
WITH initial_pull AS (
    SELECT A.ENTITY_ID,
        A.NOTE_TITLE,
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(A.NOTE_DATA), '[]'), 'null'), '') AS json_values,
        COALESCE(
            REGEXP_SUBSTR(A.NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1),
            CASE
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"loanSubStatusId" IS NOT NULL
                 AND TRY_PARSE_JSON(A.NOTE_DATA):"loanStatusId" IS NOT NULL THEN 'Loan Status - Loan Sub Status'
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"loanSubStatusId" IS NOT NULL THEN 'Loan Sub Status'
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"sourceCompany" IS NOT NULL THEN 'Source Company'
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"agent" IS NOT NULL THEN 'Agent'
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"PortfoliosAdded" IS NOT NULL THEN 'Portfolios Added'
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"PortfoliosRemoved" IS NOT NULL THEN 'Portfolios Removed'
                WHEN TRY_PARSE_JSON(A.NOTE_DATA):"applyDefaultFieldMap" IS NOT NULL THEN 'Apply Default Field Map'
            END
        ) AS NOTE_TITLE_DETAIL,
        convert_timezone('UTC','America/Los_Angeles',A.CREATED) as created_ts,
        A.NOTE_DATA,
        A.DELETED,
        A.IS_HARD_DELETED
    FROM DEVELOPMENT.FRESHSNOW.TEST_SAMPLE_SYSTEM_NOTES A
)
SELECT 
    ENTITY_ID as app_id,
    created_ts,
    NOTE_TITLE_DETAIL as note_title_detail,
    NOTE_TITLE as note_title,
    NOTE_DATA as note_data,
    DELETED as deleted,
    IS_HARD_DELETED as is_hard_deleted
FROM initial_pull;

SELECT 
    'Original Logic Performance' as test_type,
    DATEDIFF('second', $start_time, CURRENT_TIMESTAMP()) as execution_seconds,
    COUNT(*) as records_processed
FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST;

-- 3B: Time the optimized logic (on same test sample)
SET start_time_opt = (SELECT CURRENT_TIMESTAMP());

CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST AS
WITH initial_pull AS (
    SELECT 
        A.ENTITY_ID as app_id,
        convert_timezone('UTC','America/Los_Angeles',A.CREATED) as created_ts,
        A.NOTE_TITLE,
        A.NOTE_DATA,
        A.DELETED,
        A.IS_HARD_DELETED,
        -- Parse JSON once per record
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(A.NOTE_DATA), '[]'), 'null'), '') AS json_values
    FROM DEVELOPMENT.FRESHSNOW.TEST_SAMPLE_SYSTEM_NOTES A
),
categorized AS (
    SELECT *,
        -- Use pre-parsed JSON
        COALESCE(
            REGEXP_SUBSTR(NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1),
            CASE
                WHEN json_values:"loanSubStatusId" IS NOT NULL
                 AND json_values:"loanStatusId" IS NOT NULL THEN 'Loan Status - Loan Sub Status'
                WHEN json_values:"loanSubStatusId" IS NOT NULL THEN 'Loan Sub Status'
                WHEN json_values:"sourceCompany" IS NOT NULL THEN 'Source Company'
                WHEN json_values:"agent" IS NOT NULL THEN 'Agent'
                WHEN json_values:"PortfoliosAdded" IS NOT NULL THEN 'Portfolios Added'
                WHEN json_values:"PortfoliosRemoved" IS NOT NULL THEN 'Portfolios Removed'
                WHEN json_values:"applyDefaultFieldMap" IS NOT NULL THEN 'Apply Default Field Map'
            END
        ) AS note_title_detail
    FROM initial_pull
)
SELECT 
    app_id,
    created_ts,
    note_title_detail,
    note_title,
    note_data,
    deleted,
    is_hard_deleted
FROM categorized;

SELECT 
    'Optimized Logic Performance' as test_type,
    DATEDIFF('second', $start_time_opt, CURRENT_TIMESTAMP()) as execution_seconds,
    COUNT(*) as records_processed
FROM DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST;

-- 3C: Time the new architecture (on same test sample)
SET start_time_new = (SELECT CURRENT_TIMESTAMP());

CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST AS
SELECT 
    app_id,
    created_ts,
    note_category as note_title_detail,
    note_title,
    note_data,
    deleted,
    is_hard_deleted
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE app_id IN (SELECT ENTITY_ID FROM DEVELOPMENT.FRESHSNOW.TEST_SAMPLE_SYSTEM_NOTES);

SELECT 
    'New Architecture Performance' as test_type,
    DATEDIFF('second', $start_time_new, CURRENT_TIMESTAMP()) as execution_seconds,
    COUNT(*) as records_processed
FROM DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST;

-- =============================================================================
-- 4. RESULT ACCURACY COMPARISON
-- =============================================================================

-- 4A: Record count comparison across all three approaches
SELECT 
    'Record Count Validation' as test_name,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST) as original_count,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST) as optimized_count,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST) as new_arch_count,
    ABS((SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST) - 
        (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST)) as orig_vs_opt_diff,
    ABS((SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST) - 
        (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST)) as orig_vs_new_diff;

-- 4B: Category distribution comparison
SELECT 
    'Category Distribution Test' as test_name,
    COALESCE(o.note_title_detail, 'NULL_CATEGORY') as category,
    COUNT(o.*) as original_count,
    COUNT(opt.*) as optimized_count,
    COUNT(n.*) as new_arch_count
FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST o
FULL OUTER JOIN DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST opt 
    ON o.app_id = opt.app_id AND o.created_ts = opt.created_ts
FULL OUTER JOIN DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST n 
    ON COALESCE(o.app_id, opt.app_id) = n.app_id 
    AND COALESCE(o.created_ts, opt.created_ts) = n.created_ts
GROUP BY COALESCE(o.note_title_detail, opt.note_title_detail, n.note_title_detail)
HAVING COUNT(o.*) != COUNT(opt.*) OR COUNT(o.*) != COUNT(n.*) OR COUNT(opt.*) != COUNT(n.*)
ORDER BY original_count DESC;

-- 4C: Sample data validation - spot check specific records
WITH sample_records AS (
    SELECT app_id, created_ts 
    FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST 
    ORDER BY RANDOM() 
    LIMIT 10
)
SELECT 
    s.app_id,
    s.created_ts,
    o.note_title_detail as original_category,
    opt.note_title_detail as optimized_category,
    n.note_title_detail as new_arch_category,
    CASE 
        WHEN o.note_title_detail = opt.note_title_detail AND o.note_title_detail = n.note_title_detail 
        THEN 'MATCH' 
        ELSE 'MISMATCH' 
    END as validation_result
FROM sample_records s
LEFT JOIN DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST o 
    ON s.app_id = o.app_id AND s.created_ts = o.created_ts
LEFT JOIN DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST opt 
    ON s.app_id = opt.app_id AND s.created_ts = opt.created_ts
LEFT JOIN DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST n 
    ON s.app_id = n.app_id AND s.created_ts = n.created_ts;

-- =============================================================================
-- 5. BUSINESS LOGIC VALIDATION
-- =============================================================================

-- 5A: JSON parsing accuracy test
SELECT 
    'JSON Parsing Validation' as test_name,
    COUNT(CASE WHEN o.note_data = opt.note_data AND o.note_data = n.note_data THEN 1 END) as matching_note_data,
    COUNT(CASE WHEN o.note_title_detail != opt.note_title_detail THEN 1 END) as orig_vs_opt_category_diff,
    COUNT(CASE WHEN o.note_title_detail != n.note_title_detail THEN 1 END) as orig_vs_new_category_diff,
    COUNT(*) as total_compared
FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST o
INNER JOIN DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST opt 
    ON o.app_id = opt.app_id AND o.created_ts = opt.created_ts
INNER JOIN DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST n 
    ON o.app_id = n.app_id AND o.created_ts = n.created_ts;

-- 5B: Edge case handling validation
SELECT 
    'Edge Case Validation' as test_name,
    COUNT(CASE WHEN o.note_title_detail IS NULL AND opt.note_title_detail IS NULL THEN 1 END) as both_null_category,
    COUNT(CASE WHEN o.note_title_detail IS NULL AND opt.note_title_detail IS NOT NULL THEN 1 END) as opt_improvement,
    COUNT(CASE WHEN o.note_title_detail IS NOT NULL AND opt.note_title_detail IS NULL THEN 1 END) as opt_regression,
    COUNT(CASE WHEN LENGTH(o.note_data) > 10000 THEN 1 END) as large_json_records
FROM DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST o
LEFT JOIN DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST opt 
    ON o.app_id = opt.app_id AND o.created_ts = opt.created_ts;

-- =============================================================================
-- 6. PERFORMANCE SUMMARY REPORT
-- =============================================================================

-- 6A: Execution time summary
SELECT 
    'Performance Summary' as report_type,
    'Original logic processed 100K records' as original_performance,
    'Optimized logic processed 100K records' as optimized_performance,
    'New architecture processed 100K records' as new_arch_performance,
    '% improvement with optimization' as optimization_benefit,
    '% improvement with new architecture' as architecture_benefit;

-- =============================================================================
-- 7. CLEANUP TEST TABLES
-- =============================================================================

-- Uncomment to clean up test tables after validation
/*
DROP TABLE IF EXISTS DEVELOPMENT.FRESHSNOW.TEST_SAMPLE_SYSTEM_NOTES;
DROP TABLE IF EXISTS DEVELOPMENT.FRESHSNOW.ORIGINAL_LOGIC_TEST;
DROP TABLE IF EXISTS DEVELOPMENT.FRESHSNOW.OPTIMIZED_LOGIC_TEST;  
DROP TABLE IF EXISTS DEVELOPMENT.FRESHSNOW.NEW_ARCH_TEST;
*/