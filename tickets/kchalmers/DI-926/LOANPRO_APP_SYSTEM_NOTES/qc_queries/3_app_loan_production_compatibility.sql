-- QC Test 3: APP_LOAN_PRODUCTION Compatibility Validation
-- ========================================================
--
-- Purpose: Validate that BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
--          can replace app_system_note_entity in the APP_LOAN_PRODUCTION procedure
--
-- Test Approach:
-- 1. Validate column structure and data availability
-- 2. Test core procedure logic compatibility
-- 3. Compare data volumes and business logic alignment
-- 4. Assess overall procedure compatibility
--
-- Date Range: All data <= TEST_DATE_CUTOFF
-- No Sampling: Full dataset comparison
-- ========================================================

-- Test parameters
SET TEST_DATE_CUTOFF = '2025-09-22';

-- Test 3.1: Core Data Structure Compatibility
SELECT 'Column Compatibility Check' as test_name,
       'Required columns exist' as validation,
       result,
       columns_found
FROM (
    SELECT
        CASE
            WHEN success_count = 15 THEN 'PASS'
            ELSE 'FAIL - Missing: ' || (15 - success_count)::VARCHAR || ' columns'
        END as result,
        success_count as columns_found
    FROM (
        SELECT
            -- Count successful column accesses (will fail if column doesn't exist)
            (CASE WHEN TRY_TO_NUMBER(IFNULL(APP_ID, '0')) IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN TRY_TO_NUMBER(IFNULL(RECORD_ID, '0')) IS NOT NULL THEN 1 ELSE 0 END +
             CASE WHEN (CREATED_TS IS NOT NULL OR CREATED_TS IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (LASTUPDATED_TS IS NOT NULL OR LASTUPDATED_TS IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (NOTE_NEW_VALUE IS NOT NULL OR NOTE_NEW_VALUE IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (NOTE_TITLE_DETAIL IS NOT NULL OR NOTE_TITLE_DETAIL IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (IS_HARD_DELETED IS NOT NULL OR IS_HARD_DELETED IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (PORTFOLIOS_ADDED_CATEGORY IS NOT NULL OR PORTFOLIOS_ADDED_CATEGORY IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (PORTFOLIOS_ADDED_LABEL IS NOT NULL OR PORTFOLIOS_ADDED_LABEL IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (NOTE_OLD_VALUE IS NOT NULL OR NOTE_OLD_VALUE IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (NOTE_TITLE IS NOT NULL OR NOTE_TITLE IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (LOAN_STATUS_NEW IS NOT NULL OR LOAN_STATUS_NEW IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (LOAN_STATUS_OLD IS NOT NULL OR LOAN_STATUS_OLD IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (NOTE_NEW_VALUE_LABEL IS NOT NULL OR NOTE_NEW_VALUE_LABEL IS NULL) THEN 1 ELSE 0 END +
             CASE WHEN (NOTE_OLD_VALUE_LABEL IS NOT NULL OR NOTE_OLD_VALUE_LABEL IS NULL) THEN 1 ELSE 0 END) as success_count
        FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
        LIMIT 1
    )
);

-- ====================================
-- Test 3.2: Key Data Volume Comparison
WITH dev_stats AS (
    SELECT
        COUNT(*) as total_records,
        COUNT(DISTINCT app_id) as unique_apps,
        MIN(created_ts) as min_date,
        MAX(created_ts) as max_date,
        COUNT(CASE WHEN note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status') THEN 1 END) as status_records,
        COUNT(CASE WHEN note_new_value IN ('Started','Affiliate Started') THEN 1 END) as start_records
    FROM business_intelligence_dev.bridge.loanpro_app_system_notes
    WHERE created_ts <= $TEST_DATE_CUTOFF
        AND note_new_value IS NOT NULL
        AND is_hard_deleted = false
),
prod_stats AS (
    SELECT
        COUNT(*) as total_records,
        COUNT(DISTINCT app_id) as unique_apps,
        MIN(created_ts) as min_date,
        MAX(created_ts) as max_date,
        COUNT(CASE WHEN note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status') THEN 1 END) as status_records,
        COUNT(CASE WHEN note_new_value IN ('Started','Affiliate Started') THEN 1 END) as start_records
    FROM business_intelligence.bridge.app_system_note_entity
    WHERE created_ts <= $TEST_DATE_CUTOFF
        AND note_new_value IS NOT NULL
        AND is_hard_deleted = false
)
SELECT
    'Data Volume Comparison' as test_name,
    'Development' as source,
    d.total_records,
    d.unique_apps,
    d.status_records,
    d.start_records,
    d.min_date,
    d.max_date
FROM dev_stats d

UNION ALL

SELECT
    'Data Volume Comparison' as test_name,
    'Production' as source,
    p.total_records,
    p.unique_apps,
    p.status_records,
    p.start_records,
    p.min_date,
    p.max_date
FROM prod_stats p

ORDER BY test_name, source;

-- Test 3.3: Application Start Logic Validation
WITH dev_starts AS (
    SELECT
        app_id,
        created_ts,
        note_new_value,
        ROW_NUMBER() OVER (PARTITION BY app_id ORDER BY created_ts, lastupdated_ts, record_id) as row_num
    FROM business_intelligence_dev.bridge.loanpro_app_system_notes
    WHERE note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
        AND note_new_value IS NOT NULL
        AND is_hard_deleted = false
        AND created_ts <= '2025-09-18'
        AND note_new_value IN ('Started','Affiliate Started')
),
prod_starts AS (
    SELECT
        app_id,
        created_ts,
        note_new_value,
        ROW_NUMBER() OVER (PARTITION BY app_id ORDER BY created_ts, lastupdated_ts, record_id) as row_num
    FROM business_intelligence.bridge.app_system_note_entity
    WHERE note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
        AND note_new_value IS NOT NULL
        AND is_hard_deleted = false
        AND created_ts <= '2025-09-18'
        AND note_new_value IN ('Started','Affiliate Started')
)
SELECT
    'Start Logic Comparison' as test_name,
    'Development' as source,
    note_new_value,
    COUNT(*) as first_start_count
FROM dev_starts
WHERE row_num = 1
GROUP BY note_new_value

UNION ALL

SELECT
    'Start Logic Comparison' as test_name,
    'Production' as source,
    note_new_value,
    COUNT(*) as first_start_count
FROM prod_starts
WHERE row_num = 1
GROUP BY note_new_value

ORDER BY test_name, source, note_new_value;

-- Test 3.4: Note Title Detail Distribution
SELECT
    'Note Title Detail Distribution' as test_name,
    'Development' as source,
    note_title_detail,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY 'Development'), 2) as percentage
FROM business_intelligence_dev.bridge.loanpro_app_system_notes
WHERE created_ts <= $TEST_DATE_CUTOFF
    AND note_new_value IS NOT NULL
    AND is_hard_deleted = false
    AND note_title_detail IS NOT NULL
GROUP BY note_title_detail

UNION ALL

SELECT
    'Note Title Detail Distribution' as test_name,
    'Production' as source,
    note_title_detail,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY 'Production'), 2) as percentage
FROM business_intelligence.bridge.app_system_note_entity
WHERE created_ts <= $TEST_DATE_CUTOFF
    AND note_new_value IS NOT NULL
    AND is_hard_deleted = false
    AND note_title_detail IS NOT NULL
GROUP BY note_title_detail

ORDER BY test_name, source, count DESC
LIMIT 20;

-- Test 3.5: Sample Record Comparison
WITH dev_sample AS (
    SELECT
        app_id,
        record_id,
        created_ts,
        note_title_detail,
        note_new_value,
        is_hard_deleted,
        'Development' as source
    FROM business_intelligence_dev.bridge.loanpro_app_system_notes
    WHERE created_ts <= $TEST_DATE_CUTOFF
        AND note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
        AND note_new_value IN ('Started','Affiliate Started')
    ORDER BY app_id, created_ts
    LIMIT 5
),
prod_sample AS (
    SELECT
        app_id,
        record_id,
        created_ts,
        note_title_detail,
        note_new_value,
        is_hard_deleted,
        'Production' as source
    FROM business_intelligence.bridge.app_system_note_entity
    WHERE created_ts <= $TEST_DATE_CUTOFF
        AND note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
        AND note_new_value IN ('Started','Affiliate Started')
    ORDER BY app_id, created_ts
    LIMIT 5
)
SELECT
    'Sample Record Comparison' as test_name,
    source,
    app_id,
    record_id,
    created_ts,
    note_title_detail,
    note_new_value,
    is_hard_deleted
FROM dev_sample

UNION ALL

SELECT
    'Sample Record Comparison' as test_name,
    source,
    app_id,
    record_id,
    created_ts,
    note_title_detail,
    note_new_value,
    is_hard_deleted
FROM prod_sample

ORDER BY test_name, source, app_id, created_ts;

-- Test 3.6: Portfolio and Fraud Detection Compatibility
SELECT
    'Portfolio Fields Check' as test_name,
    'Development has portfolio fields' as validation,
    COUNT(CASE WHEN portfolios_added_category IS NOT NULL THEN 1 END) as records_with_portfolio_category,
    COUNT(CASE WHEN portfolios_added_label IS NOT NULL THEN 1 END) as records_with_portfolio_label,
    COUNT(CASE WHEN portfolios_added_category = 'Fraud' THEN 1 END) as fraud_category_records
FROM business_intelligence_dev.bridge.loanpro_app_system_notes
WHERE created_ts <= $TEST_DATE_CUTOFF

UNION ALL

SELECT
    'Portfolio Fields Check' as test_name,
    'Production has portfolio fields' as validation,
    COUNT(CASE WHEN portfolios_added_category IS NOT NULL THEN 1 END) as records_with_portfolio_category,
    COUNT(CASE WHEN portfolios_added_label IS NOT NULL THEN 1 END) as records_with_portfolio_label,
    COUNT(CASE WHEN portfolios_added_category = 'Fraud' THEN 1 END) as fraud_category_records
FROM business_intelligence.bridge.app_system_note_entity
WHERE created_ts <= $TEST_DATE_CUTOFF

ORDER BY test_name, validation;

-- Test 3.7: Procedure Core Logic Compatibility Test
WITH procedure_core_test AS (
    -- Test app_loan_prod_starts logic (first step of procedure)
    SELECT
        app_id,
        created_ts,
        note_new_value,
        ROW_NUMBER() OVER (PARTITION BY app_id ORDER BY created_ts, lastupdated_ts, record_id) as row_asc
    FROM business_intelligence_dev.bridge.loanpro_app_system_notes
    WHERE note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
        AND note_new_value IS NOT NULL
        AND is_hard_deleted = false
        AND created_ts <= '2025-09-18'
        AND note_new_value IN ('Started','Affiliate Started')
),
start_summary AS (
    SELECT
        note_new_value,
        COUNT(*) as first_start_count
    FROM procedure_core_test
    WHERE row_asc = 1
    GROUP BY note_new_value
)
SELECT
    'Procedure Core Logic Test' as test_name,
    'Start Status Distribution' as logic_component,
    note_new_value,
    first_start_count,
    CASE
        WHEN first_start_count > 0 THEN 'PASS'
        ELSE 'FAIL'
    END as test_result
FROM start_summary

UNION ALL

-- Test note processing patterns used throughout procedure
SELECT
    'Procedure Core Logic Test' as test_name,
    'Note Processing Fields' as logic_component,
    'Portfolio Processing' as note_new_value,
    COUNT(CASE WHEN portfolios_added_category IS NOT NULL THEN 1 END) as first_start_count,
    CASE
        WHEN COUNT(CASE WHEN portfolios_added_category IS NOT NULL THEN 1 END) > 0 THEN 'PASS'
        ELSE 'FAIL'
    END as test_result
FROM business_intelligence_dev.bridge.loanpro_app_system_notes
WHERE created_ts <= $TEST_DATE_CUTOFF

ORDER BY test_name, logic_component, note_new_value;

-- Test 3.8: Overall Compatibility Assessment
WITH compatibility_check AS (
    SELECT
        CASE
            WHEN (
                SELECT COUNT(*) FROM business_intelligence_dev.bridge.loanpro_app_system_notes
                WHERE created_ts <= $TEST_DATE_CUTOFF
                    AND note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
                    AND note_new_value IS NOT NULL
                    AND is_hard_deleted = false
            ) > 5000000 THEN 'PASS'
            ELSE 'FAIL'
        END as data_availability,
        CASE
            WHEN (
                SELECT COUNT(*) FROM information_schema.columns
                WHERE table_schema = 'BUSINESS_INTELLIGENCE_DEV'
                AND table_name = 'LOANPRO_APP_SYSTEM_NOTES'
                AND column_name IN ('APP_ID', 'NOTE_NEW_VALUE', 'NOTE_TITLE_DETAIL', 'IS_HARD_DELETED')
            ) = 4 THEN 'PASS'
            ELSE 'FAIL'
        END as required_columns,
        CASE
            WHEN (
                SELECT COUNT(DISTINCT app_id) FROM business_intelligence_dev.bridge.loanpro_app_system_notes
                WHERE created_ts <= $TEST_DATE_CUTOFF
            ) > 3000000 THEN 'PASS'
            ELSE 'FAIL'
        END as app_id_populated,
        CASE
            WHEN (
                SELECT COUNT(*) FROM business_intelligence_dev.bridge.loanpro_app_system_notes
                WHERE created_ts <= $TEST_DATE_CUTOFF
                    AND note_new_value IN ('Started','Affiliate Started')
                    AND note_title_detail IN ('Loan Status - Loan Sub Status','Loan Sub Status')
            ) > 1000000 THEN 'PASS'
            ELSE 'FAIL'
        END as start_logic_data
)
SELECT
    'QC Test 3 Summary' as test_name,
    'APP_LOAN_PRODUCTION Compatibility Assessment' as description,
    data_availability,
    required_columns,
    app_id_populated,
    start_logic_data,
    CASE
        WHEN data_availability = 'PASS' AND required_columns = 'PASS'
             AND app_id_populated = 'PASS' AND start_logic_data = 'PASS'
        THEN 'COMPATIBLE - Procedure can use LOANPRO_APP_SYSTEM_NOTES'
        ELSE 'INCOMPATIBLE - Issues found'
    END as overall_result,
    CURRENT_TIMESTAMP() as test_completed_at
FROM compatibility_check;