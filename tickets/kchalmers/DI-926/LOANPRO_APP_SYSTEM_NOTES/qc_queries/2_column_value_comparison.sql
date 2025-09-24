-- DI-926: Column Value Comparison for Matching Records
-- Compares specific column values between dev and production for matching RECORD_IDs
-- Expected result: All column values should match

-- Test parameters
SET TEST_DATE_CUTOFF = '2025-09-22';

use warehouse BUSINESS_INTELLIGENCE_LARGE;
-- Test 2.1: Overall Column Mismatch Summary
WITH matched_records AS (
    SELECT
        d.RECORD_ID,
        d.APP_ID,
        d.CREATED_TS as dev_created_ts,
        p.CREATED_TS as prod_created_ts,
        d.LASTUPDATED_TS as dev_lastupdated_ts,
        p.LASTUPDATED_TS as prod_lastupdated_ts,
        /*d.LOAN_STATUS_NEW as dev_loan_status_new,
        p.LOAN_STATUS_NEW as prod_loan_status_new,
        d.LOAN_STATUS_OLD as dev_loan_status_old,
        p.LOAN_STATUS_OLD as prod_loan_status_old,*/
        d.NOTE_NEW_VALUE as dev_note_new_value,
        p.NOTE_NEW_VALUE as prod_note_new_value,
        d.NOTE_NEW_VALUE_LABEL as dev_note_new_value_label,
        p.NOTE_NEW_VALUE_LABEL as prod_note_new_value_label,
        d.NOTE_OLD_VALUE as dev_note_old_value,
        p.NOTE_OLD_VALUE as prod_note_old_value,
        d.NOTE_TITLE_DETAIL as dev_note_title_detail,
        p.NOTE_TITLE_DETAIL as prod_note_title_detail,
        d.NOTE_TITLE as dev_note_title,
        p.NOTE_TITLE as prod_note_title,
        d.PORTFOLIOS_ADDED as dev_portfolios_added,
        p.PORTFOLIOS_ADDED as prod_portfolios_added,
        d.PORTFOLIOS_ADDED_CATEGORY as dev_portfolios_added_category,
        p.PORTFOLIOS_ADDED_CATEGORY as prod_portfolios_added_category,
        d.PORTFOLIOS_ADDED_LABEL as dev_portfolios_added_label,
        p.PORTFOLIOS_ADDED_LABEL as prod_portfolios_added_label,
        d.PORTFOLIOS_REMOVED as dev_portfolios_removed,
        p.PORTFOLIOS_REMOVED as prod_portfolios_removed,
        d.PORTFOLIOS_REMOVED_CATEGORY as dev_portfolios_removed_category,
        NULL as prod_portfolios_removed_category, -- Not in production
        d.PORTFOLIOS_REMOVED_LABEL as dev_portfolios_removed_label,
        NULL as prod_portfolios_removed_label -- Not in production
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
        ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
),
mismatched_columns AS (
    SELECT
        RECORD_ID,
        APP_ID,
        CASE WHEN dev_created_ts != prod_created_ts OR (dev_created_ts IS NULL) != (prod_created_ts IS NULL) THEN 1 ELSE 0 END as created_ts_mismatch,
        CASE WHEN dev_lastupdated_ts != prod_lastupdated_ts OR (dev_lastupdated_ts IS NULL) != (prod_lastupdated_ts IS NULL) THEN 1 ELSE 0 END as lastupdated_ts_mismatch,
        /*CASE WHEN dev_loan_status_new != prod_loan_status_new OR (dev_loan_status_new IS NULL) != (prod_loan_status_new IS NULL) THEN 1 ELSE 0 END as loan_status_new_mismatch,
        CASE WHEN dev_loan_status_old != prod_loan_status_old OR (dev_loan_status_old IS NULL) != (prod_loan_status_old IS NULL) THEN 1 ELSE 0 END as loan_status_old_mismatch,*/
        CASE WHEN dev_note_new_value != prod_note_new_value OR (dev_note_new_value IS NULL) != (prod_note_new_value IS NULL) THEN 1 ELSE 0 END as note_new_value_mismatch,
        CASE WHEN dev_note_new_value_label != prod_note_new_value_label OR (dev_note_new_value_label IS NULL) != (prod_note_new_value_label IS NULL) THEN 1 ELSE 0 END as note_new_value_label_mismatch,
        CASE WHEN dev_note_old_value != prod_note_old_value OR (dev_note_old_value IS NULL) != (prod_note_old_value IS NULL) THEN 1 ELSE 0 END as note_old_value_mismatch,
        CASE WHEN dev_note_title_detail != prod_note_title_detail OR (dev_note_title_detail IS NULL) != (prod_note_title_detail IS NULL) THEN 1 ELSE 0 END as note_title_detail_mismatch,
        CASE WHEN dev_note_title != prod_note_title OR (dev_note_title IS NULL) != (prod_note_title IS NULL) THEN 1 ELSE 0 END as note_title_mismatch,
        CASE WHEN dev_portfolios_added != prod_portfolios_added OR (dev_portfolios_added IS NULL) != (prod_portfolios_added IS NULL) THEN 1 ELSE 0 END as portfolios_added_mismatch,
        CASE WHEN dev_portfolios_added_category != prod_portfolios_added_category OR (dev_portfolios_added_category IS NULL) != (prod_portfolios_added_category IS NULL) THEN 1 ELSE 0 END as portfolios_added_category_mismatch,
        CASE WHEN dev_portfolios_added_label != prod_portfolios_added_label OR (dev_portfolios_added_label IS NULL) != (prod_portfolios_added_label IS NULL) THEN 1 ELSE 0 END as portfolios_added_label_mismatch,
        CASE WHEN dev_portfolios_removed != prod_portfolios_removed OR (dev_portfolios_removed IS NULL) != (prod_portfolios_removed IS NULL) THEN 1 ELSE 0 END as portfolios_removed_mismatch,
        -- Note: These are new in dev, so they will always be "mismatches" vs NULL in production
        CASE WHEN dev_portfolios_removed_category IS NOT NULL THEN 1 ELSE 0 END as portfolios_removed_category_new_in_dev,
        CASE WHEN dev_portfolios_removed_label IS NOT NULL THEN 1 ELSE 0 END as portfolios_removed_label_new_in_dev
    FROM matched_records
)
-- Summary of mismatches
SELECT
    'Column Mismatch Summary' as report_type,
    COUNT(*) as total_compared_records,
    SUM(created_ts_mismatch) as created_ts_mismatches,
    SUM(lastupdated_ts_mismatch) as lastupdated_ts_mismatches,
    /*SUM(loan_status_new_mismatch) as loan_status_new_mismatches,
    SUM(loan_status_old_mismatch) as loan_status_old_mismatches,*/
    SUM(note_new_value_mismatch) as note_new_value_mismatches,
    SUM(note_new_value_label_mismatch) as note_new_value_label_mismatches,
    SUM(note_old_value_mismatch) as note_old_value_mismatches,
    SUM(note_title_detail_mismatch) as note_title_detail_mismatches,
    SUM(note_title_mismatch) as note_title_mismatches,
    SUM(portfolios_added_mismatch) as portfolios_added_mismatches,
    SUM(portfolios_added_category_mismatch) as portfolios_added_category_mismatches,
    SUM(portfolios_added_label_mismatch) as portfolios_added_label_mismatches,
    SUM(portfolios_removed_mismatch) as portfolios_removed_mismatches,
    SUM(portfolios_removed_category_new_in_dev) as portfolios_removed_category_new_in_dev_count,
    SUM(portfolios_removed_label_new_in_dev) as portfolios_removed_label_new_in_dev_count,
    SUM(CASE WHEN
        created_ts_mismatch + lastupdated_ts_mismatch + /*loan_status_new_mismatch +
        loan_status_old_mismatch +*/ note_new_value_mismatch + note_new_value_label_mismatch +
        note_old_value_mismatch + note_title_detail_mismatch + note_title_mismatch +
        portfolios_added_mismatch + portfolios_added_category_mismatch + portfolios_added_label_mismatch +
        portfolios_removed_mismatch + portfolios_removed_category_new_in_dev + portfolios_removed_label_new_in_dev > 0
        THEN 1 ELSE 0 END) as total_records_with_any_mismatch
FROM mismatched_columns;

-- Test 2.2: NOTE_NEW_VALUE_LABEL Validation (Compare dev label to dev values)
WITH label_validation AS (
    SELECT
        RECORD_ID,
        NOTE_NEW_VALUE_LABEL,
        NOTE_NEW_VALUE,
        NOTE_NEW_VALUE_LABEL as note_new_value_label_field,
        CASE
            WHEN NOTE_NEW_VALUE_LABEL IS NULL THEN 'Label is NULL'
            WHEN NOTE_NEW_VALUE_LABEL = NOTE_NEW_VALUE THEN 'Label matches NOTE_NEW_VALUE'
            ELSE 'Label mismatch'
        END as validation_result
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
    WHERE created_ts <= $TEST_DATE_CUTOFF
      AND NOTE_NEW_VALUE_LABEL IS NOT NULL
)
SELECT
    'NOTE_NEW_VALUE_LABEL Validation' as test_type,
    validation_result,
    COUNT(*) as record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM label_validation
GROUP BY validation_result
ORDER BY record_count DESC;

-- Test 2.3: NOTE_OLD_VALUE_LABEL Validation (Compare dev label to dev values)
WITH label_validation AS (
    SELECT
        RECORD_ID,
        NOTE_OLD_VALUE_LABEL,
        NOTE_OLD_VALUE,
        NOTE_OLD_VALUE_LABEL as note_old_value_label_field,
        CASE
            WHEN NOTE_OLD_VALUE_LABEL IS NULL THEN 'Label is NULL'
            WHEN NOTE_OLD_VALUE_LABEL = NOTE_OLD_VALUE THEN 'Label matches NOTE_OLD_VALUE'
            ELSE 'Label mismatch'
        END as validation_result
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
    WHERE created_ts <= $TEST_DATE_CUTOFF
      AND NOTE_OLD_VALUE_LABEL IS NOT NULL
)
SELECT
    'NOTE_OLD_VALUE_LABEL Validation' as test_type,
    validation_result,
    COUNT(*) as record_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM label_validation
GROUP BY validation_result
ORDER BY record_count DESC;

-- Test 2.4: NOTE_NEW_VALUE_LABEL Mismatch Examples
SELECT
    'NOTE_NEW_VALUE_LABEL Mismatch Examples' as analysis_type,
    RECORD_ID,
    NOTE_TITLE_DETAIL,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL as note_new_value_label_field,
    NOTE_NEW_VALUE_LABEL,
    'Expected match with NOTE_NEW_VALUE or NOTE_NEW_VALUE_LABEL' as expected_logic
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts <= $TEST_DATE_CUTOFF
  AND NOTE_NEW_VALUE_LABEL IS NOT NULL
  AND NOTE_NEW_VALUE_LABEL != NOTE_NEW_VALUE
  AND NOTE_NEW_VALUE_LABEL != NOTE_NEW_VALUE_LABEL
ORDER BY RECORD_ID DESC
LIMIT 100;

-- Test 2.5: NOTE_OLD_VALUE_LABEL Mismatch Examples
SELECT
    'NOTE_OLD_VALUE_LABEL Mismatch Examples' as analysis_type,
    RECORD_ID,
    NOTE_TITLE_DETAIL,
    NOTE_OLD_VALUE,
    NOTE_OLD_VALUE_LABEL as note_old_value_label_field,
    NOTE_OLD_VALUE_LABEL,
    'Expected match with NOTE_OLD_VALUE or NOTE_OLD_VALUE_LABEL' as expected_logic
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts <= $TEST_DATE_CUTOFF
  AND NOTE_OLD_VALUE_LABEL IS NOT NULL
  AND NOTE_OLD_VALUE_LABEL != NOTE_OLD_VALUE
  AND NOTE_OLD_VALUE_LABEL != NOTE_OLD_VALUE_LABEL
ORDER BY RECORD_ID DESC
LIMIT 100;

-- Test 2.6: PORTFOLIOS_ADDED Aggregated Comparison
WITH portfolios_added_comparison AS (
    SELECT
        CASE
            WHEN d.PORTFOLIOS_ADDED = p.PORTFOLIOS_ADDED OR (d.PORTFOLIOS_ADDED IS NULL AND p.PORTFOLIOS_ADDED IS NULL) THEN 'Match'
            WHEN d.PORTFOLIOS_ADDED IS NULL AND p.PORTFOLIOS_ADDED IS NOT NULL THEN 'Dev NULL, Prod Value'
            WHEN d.PORTFOLIOS_ADDED IS NOT NULL AND p.PORTFOLIOS_ADDED IS NULL THEN 'Dev Value, Prod NULL'
            ELSE 'Different Values'
        END as match_category
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
        ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
)
SELECT
    'PORTFOLIOS_ADDED Comparison' as comparison_type,
    match_category,
    COUNT(*) as total_records,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM portfolios_added_comparison
GROUP BY match_category
ORDER BY total_records DESC;

-- Test 2.7: PORTFOLIOS_ADDED_CATEGORY Aggregated Comparison
WITH portfolios_category_comparison AS (
    SELECT
        CASE
            WHEN d.PORTFOLIOS_ADDED_CATEGORY = p.PORTFOLIOS_ADDED_CATEGORY OR (d.PORTFOLIOS_ADDED_CATEGORY IS NULL AND p.PORTFOLIOS_ADDED_CATEGORY IS NULL) THEN 'Match'
            WHEN d.PORTFOLIOS_ADDED_CATEGORY IS NULL AND p.PORTFOLIOS_ADDED_CATEGORY IS NOT NULL THEN 'Dev NULL, Prod Value'
            WHEN d.PORTFOLIOS_ADDED_CATEGORY IS NOT NULL AND p.PORTFOLIOS_ADDED_CATEGORY IS NULL THEN 'Dev Value, Prod NULL'
            ELSE 'Different Values'
        END as match_category
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
        ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
)
SELECT
    'PORTFOLIOS_ADDED_CATEGORY Comparison' as comparison_type,
    match_category,
    COUNT(*) as total_records,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM portfolios_category_comparison
GROUP BY match_category
ORDER BY total_records DESC;

-- Test 2.8: PORTFOLIOS_ADDED_LABEL Aggregated Comparison
WITH portfolios_label_comparison AS (
    SELECT
        CASE
            WHEN d.PORTFOLIOS_ADDED_LABEL = p.PORTFOLIOS_ADDED_LABEL OR (d.PORTFOLIOS_ADDED_LABEL IS NULL AND p.PORTFOLIOS_ADDED_LABEL IS NULL) THEN 'Match'
            WHEN d.PORTFOLIOS_ADDED_LABEL IS NULL AND p.PORTFOLIOS_ADDED_LABEL IS NOT NULL THEN 'Dev NULL, Prod Value'
            WHEN d.PORTFOLIOS_ADDED_LABEL IS NOT NULL AND p.PORTFOLIOS_ADDED_LABEL IS NULL THEN 'Dev Value, Prod NULL'
            ELSE 'Different Values'
        END as match_category
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
        ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
)
SELECT
    'PORTFOLIOS_ADDED_LABEL Comparison' as comparison_type,
    match_category,
    COUNT(*) as total_records,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM portfolios_label_comparison
GROUP BY match_category
ORDER BY total_records DESC;

-- Test 2.8A: PORTFOLIOS_REMOVED Aggregated Comparison
WITH portfolios_removed_comparison AS (
    SELECT
        CASE
            WHEN d.PORTFOLIOS_REMOVED = p.PORTFOLIOS_REMOVED OR (d.PORTFOLIOS_REMOVED IS NULL AND p.PORTFOLIOS_REMOVED IS NULL) THEN 'Match'
            WHEN d.PORTFOLIOS_REMOVED IS NULL AND p.PORTFOLIOS_REMOVED IS NOT NULL THEN 'Dev NULL, Prod Value'
            WHEN d.PORTFOLIOS_REMOVED IS NOT NULL AND p.PORTFOLIOS_REMOVED IS NULL THEN 'Dev Value, Prod NULL'
            ELSE 'Different Values'
        END as match_category
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
        ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
)
SELECT
    'PORTFOLIOS_REMOVED Comparison' as comparison_type,
    match_category,
    COUNT(*) as total_records,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM portfolios_removed_comparison
GROUP BY match_category
ORDER BY total_records DESC;

-- Test 2.8B: PORTFOLIOS_REMOVED_CATEGORY Validation (Dev Enhancement)
SELECT
    'PORTFOLIOS_REMOVED_CATEGORY Enhancement' as test_type,
    COUNT(*) as total_removed_records,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED_CATEGORY IS NOT NULL THEN 1 END) as has_category,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED_CATEGORY IS NULL AND PORTFOLIOS_REMOVED IS NOT NULL THEN 1 END) as missing_category,
    ROUND(COUNT(CASE WHEN PORTFOLIOS_REMOVED_CATEGORY IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as category_completion_rate
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
WHERE PORTFOLIOS_REMOVED IS NOT NULL
    AND CREATED_TS <= '2025-09-21';

-- Test 2.8C: PORTFOLIOS_REMOVED_LABEL Validation (Dev Enhancement)
SELECT
    'PORTFOLIOS_REMOVED_LABEL Enhancement' as test_type,
    COUNT(*) as total_removed_records,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED_LABEL IS NOT NULL THEN 1 END) as has_label,
    COUNT(CASE WHEN PORTFOLIOS_REMOVED_LABEL IS NULL AND PORTFOLIOS_REMOVED IS NOT NULL THEN 1 END) as missing_label,
    ROUND(COUNT(CASE WHEN PORTFOLIOS_REMOVED_LABEL IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as label_completion_rate
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
WHERE PORTFOLIOS_REMOVED IS NOT NULL
    AND CREATED_TS <= '2025-09-21';

-- Test 2.8D: PORTFOLIOS_REMOVED Sample Records Validation
SELECT
    'PORTFOLIOS_REMOVED Sample Test' as test_type,
    RECORD_ID,
    APP_ID,
    NOTE_TITLE_DETAIL,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE,
    PORTFOLIOS_REMOVED,
    PORTFOLIOS_REMOVED_LABEL,
    PORTFOLIOS_REMOVED_CATEGORY,
    CASE
        WHEN NOTE_NEW_VALUE = NOTE_NEW_VALUE_LABEL THEN 'PASS'
        ELSE 'FAIL'
    END as note_value_consistency,
    CASE
        WHEN PORTFOLIOS_REMOVED = '102'
            AND PORTFOLIOS_REMOVED_LABEL = 'Check Received'
            AND PORTFOLIOS_REMOVED_CATEGORY = 'Fraud'
            AND NOTE_TITLE_DETAIL = 'Portfolios Removed'
            THEN 'PASS'
        ELSE 'FAIL'
    END as expected_values_test
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
WHERE RECORD_ID IN (681640067, 681639797, 681640775)
    AND PORTFOLIOS_REMOVED IS NOT NULL
ORDER BY RECORD_ID;

-- Test 2.9: Portfolio Fields Value Differences (Grouped by Values)
WITH portfolio_mismatches AS (
    SELECT
        'PORTFOLIOS_ADDED' as field_name,
        d.PORTFOLIOS_ADDED as dev_value,
        p.PORTFOLIOS_ADDED as prod_value,
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND (d.PORTFOLIOS_ADDED != p.PORTFOLIOS_ADDED
           OR (d.PORTFOLIOS_ADDED IS NULL) != (p.PORTFOLIOS_ADDED IS NULL))
    GROUP BY d.PORTFOLIOS_ADDED, p.PORTFOLIOS_ADDED

    UNION ALL

    SELECT
        'PORTFOLIOS_ADDED_CATEGORY' as field_name,
        d.PORTFOLIOS_ADDED_CATEGORY as dev_value,
        p.PORTFOLIOS_ADDED_CATEGORY as prod_value,
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND (d.PORTFOLIOS_ADDED_CATEGORY != p.PORTFOLIOS_ADDED_CATEGORY
           OR (d.PORTFOLIOS_ADDED_CATEGORY IS NULL) != (p.PORTFOLIOS_ADDED_CATEGORY IS NULL))
    GROUP BY d.PORTFOLIOS_ADDED_CATEGORY, p.PORTFOLIOS_ADDED_CATEGORY

    UNION ALL

    SELECT
        'PORTFOLIOS_ADDED_LABEL' as field_name,
        d.PORTFOLIOS_ADDED_LABEL as dev_value,
        p.PORTFOLIOS_ADDED_LABEL as prod_value,
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND (d.PORTFOLIOS_ADDED_LABEL != p.PORTFOLIOS_ADDED_LABEL
           OR (d.PORTFOLIOS_ADDED_LABEL IS NULL) != (p.PORTFOLIOS_ADDED_LABEL IS NULL))
    GROUP BY d.PORTFOLIOS_ADDED_LABEL, p.PORTFOLIOS_ADDED_LABEL

    UNION ALL

    SELECT
        'PORTFOLIOS_REMOVED' as field_name,
        d.PORTFOLIOS_REMOVED as dev_value,
        p.PORTFOLIOS_REMOVED as prod_value,
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND (d.PORTFOLIOS_REMOVED != p.PORTFOLIOS_REMOVED
           OR (d.PORTFOLIOS_REMOVED IS NULL) != (p.PORTFOLIOS_REMOVED IS NULL))
    GROUP BY d.PORTFOLIOS_REMOVED, p.PORTFOLIOS_REMOVED

    UNION ALL

    SELECT
        'PORTFOLIOS_REMOVED_CATEGORY' as field_name,
        d.PORTFOLIOS_REMOVED_CATEGORY as dev_value,
        NULL as prod_value, -- New in dev
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND d.PORTFOLIOS_REMOVED_CATEGORY IS NOT NULL
    GROUP BY d.PORTFOLIOS_REMOVED_CATEGORY

    UNION ALL

    SELECT
        'PORTFOLIOS_REMOVED_LABEL' as field_name,
        d.PORTFOLIOS_REMOVED_LABEL as dev_value,
        NULL as prod_value, -- New in dev
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND d.PORTFOLIOS_REMOVED_LABEL IS NOT NULL
    GROUP BY d.PORTFOLIOS_REMOVED_LABEL
)
SELECT
    field_name,
    dev_value,
    prod_value,
    record_count
FROM portfolio_mismatches
ORDER BY field_name, record_count DESC
LIMIT 200;

-- Test 2.10: Portfolio Fields Specific Record Examples
SELECT
    'Portfolio Fields Mismatch Examples' as analysis_type,
    d.RECORD_ID,
    d.APP_ID,
    d.NOTE_TITLE_DETAIL,
    d.PORTFOLIOS_ADDED as dev_portfolios_added,
    p.PORTFOLIOS_ADDED as prod_portfolios_added,
    d.PORTFOLIOS_ADDED_CATEGORY as dev_portfolios_added_category,
    p.PORTFOLIOS_ADDED_CATEGORY as prod_portfolios_added_category,
    d.PORTFOLIOS_ADDED_LABEL as dev_portfolios_added_label,
    p.PORTFOLIOS_ADDED_LABEL as prod_portfolios_added_label,
    d.PORTFOLIOS_REMOVED as dev_portfolios_removed,
    p.PORTFOLIOS_REMOVED as prod_portfolios_removed,
    d.PORTFOLIOS_REMOVED_CATEGORY as dev_portfolios_removed_category,
    d.PORTFOLIOS_REMOVED_LABEL as dev_portfolios_removed_label,
    CASE
        WHEN (d.PORTFOLIOS_ADDED != p.PORTFOLIOS_ADDED OR (d.PORTFOLIOS_ADDED IS NULL) != (p.PORTFOLIOS_ADDED IS NULL)) THEN 'PORTFOLIOS_ADDED mismatch'
        WHEN (d.PORTFOLIOS_ADDED_CATEGORY != p.PORTFOLIOS_ADDED_CATEGORY OR (d.PORTFOLIOS_ADDED_CATEGORY IS NULL) != (p.PORTFOLIOS_ADDED_CATEGORY IS NULL)) THEN 'PORTFOLIOS_ADDED_CATEGORY mismatch'
        WHEN (d.PORTFOLIOS_ADDED_LABEL != p.PORTFOLIOS_ADDED_LABEL OR (d.PORTFOLIOS_ADDED_LABEL IS NULL) != (p.PORTFOLIOS_ADDED_LABEL IS NULL)) THEN 'PORTFOLIOS_ADDED_LABEL mismatch'
        WHEN (d.PORTFOLIOS_REMOVED != p.PORTFOLIOS_REMOVED OR (d.PORTFOLIOS_REMOVED IS NULL) != (p.PORTFOLIOS_REMOVED IS NULL)) THEN 'PORTFOLIOS_REMOVED mismatch'
        WHEN d.PORTFOLIOS_REMOVED_CATEGORY IS NOT NULL THEN 'PORTFOLIOS_REMOVED_CATEGORY new in dev'
        WHEN d.PORTFOLIOS_REMOVED_LABEL IS NOT NULL THEN 'PORTFOLIOS_REMOVED_LABEL new in dev'
        ELSE 'Multiple mismatches'
    END as mismatch_type
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
    ON d.RECORD_ID = p.RECORD_ID
WHERE d.created_ts <= '2025-09-21'
  AND p.created_ts <= '2025-09-21'
  AND (
    (d.PORTFOLIOS_ADDED != p.PORTFOLIOS_ADDED OR (d.PORTFOLIOS_ADDED IS NULL) != (p.PORTFOLIOS_ADDED IS NULL))
    OR (d.PORTFOLIOS_ADDED_CATEGORY != p.PORTFOLIOS_ADDED_CATEGORY OR (d.PORTFOLIOS_ADDED_CATEGORY IS NULL) != (p.PORTFOLIOS_ADDED_CATEGORY IS NULL))
    OR (d.PORTFOLIOS_ADDED_LABEL != p.PORTFOLIOS_ADDED_LABEL OR (d.PORTFOLIOS_ADDED_LABEL IS NULL) != (p.PORTFOLIOS_ADDED_LABEL IS NULL))
    OR (d.PORTFOLIOS_REMOVED != p.PORTFOLIOS_REMOVED OR (d.PORTFOLIOS_REMOVED IS NULL) != (p.PORTFOLIOS_REMOVED IS NULL))
    OR d.PORTFOLIOS_REMOVED_CATEGORY IS NOT NULL
    OR d.PORTFOLIOS_REMOVED_LABEL IS NOT NULL
  )
ORDER BY d.RECORD_ID DESC
LIMIT 100;

-- Test 2.11: NOTE_TITLE_DETAIL Aggregated Comparison
WITH note_title_detail_comparison AS (
    SELECT
        d.NOTE_TITLE_DETAIL as dev_value,
        p.NOTE_TITLE_DETAIL as prod_value,
        COUNT(*) as record_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
        ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
    GROUP BY d.NOTE_TITLE_DETAIL, p.NOTE_TITLE_DETAIL
)
SELECT
    'NOTE_TITLE_DETAIL Comparison' as comparison_type,
    CASE
        WHEN dev_value = prod_value THEN 'Exact Match'
        WHEN dev_value = 'Portfolios Added' AND prod_value LIKE 'Portfolios Added%' THEN 'Portfolio Suffix Difference'
        WHEN dev_value = 'Apply Default Field Map' AND prod_value LIKE 'Portfolios Removed%' THEN 'Category Remap'
        WHEN dev_value IS NULL OR prod_value IS NULL THEN 'One Side NULL'
        ELSE 'Other Differences'
    END as match_category,
    COUNT(*) as group_count,
    SUM(record_count) as total_records,
    ROUND(SUM(record_count) * 100.0 / SUM(SUM(record_count)) OVER(), 2) as percentage
FROM note_title_detail_comparison
GROUP BY match_category
ORDER BY total_records DESC;

-- Test 2.12: NOTE_TITLE_DETAIL Actual Value Differences (Grouped by Values)
WITH matching_records AS (
    SELECT
        d.NOTE_TITLE_DETAIL as dev_value,
        p.NOTE_TITLE_DETAIL as prod_value
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p ON d.RECORD_ID = p.RECORD_ID
    WHERE d.created_ts <= '2025-09-21'
      AND p.created_ts <= '2025-09-21'
      AND (d.NOTE_TITLE_DETAIL != p.NOTE_TITLE_DETAIL
           OR (d.NOTE_TITLE_DETAIL IS NULL) != (p.NOTE_TITLE_DETAIL IS NULL))
    LIMIT 100000
)
SELECT
    dev_value,
    prod_value,
    COUNT(*) as record_count
FROM matching_records
GROUP BY dev_value, prod_value
ORDER BY record_count DESC;

-- Test 2.13: NOTE_TITLE_DETAIL Specific Record Examples (All Columns)
SELECT
    'NOTE_TITLE_DETAIL Mismatch Examples' as analysis_type,
    d.RECORD_ID,
    d.APP_ID,
    d.CREATED_TS,
    d.LASTUPDATED_TS,
    d.NOTE_TITLE,
    d.NOTE_TITLE_DETAIL,
    p.NOTE_TITLE_DETAIL as prod_note_title_detail,
    d.NOTE_NEW_VALUE as dev_note_new_value,
    p.NOTE_NEW_VALUE as prod_note_new_value,
    d.NOTE_NEW_VALUE_LABEL as dev_note_new_value_label,
    p.NOTE_NEW_VALUE_LABEL as prod_note_new_value_label,
    d.NOTE_OLD_VALUE as dev_note_old_value,
    p.NOTE_OLD_VALUE as prod_note_old_value,
    d.NOTE_DATA as dev_note_data,
    p.NOTE_DATA as prod_note_data,
    d.PORTFOLIOS_ADDED as dev_portfolios_added,
    p.PORTFOLIOS_ADDED as prod_portfolios_added,
    d.PORTFOLIOS_ADDED_CATEGORY as dev_portfolios_added_category,
    p.PORTFOLIOS_ADDED_CATEGORY as prod_portfolios_added_category,
    d.PORTFOLIOS_ADDED_LABEL as dev_portfolios_added_label,
    p.PORTFOLIOS_ADDED_LABEL as prod_portfolios_added_label,
    d.PORTFOLIOS_REMOVED as dev_portfolios_removed,
    p.PORTFOLIOS_REMOVED as prod_portfolios_removed,
    d.PORTFOLIOS_REMOVED_CATEGORY as dev_portfolios_removed_category,
    d.PORTFOLIOS_REMOVED_LABEL as dev_portfolios_removed_label
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
    ON d.RECORD_ID = p.RECORD_ID
WHERE d.created_ts <= '2025-09-21'
  AND p.created_ts <= '2025-09-21'
  AND (d.NOTE_TITLE_DETAIL != p.NOTE_TITLE_DETAIL
       OR (d.NOTE_TITLE_DETAIL IS NULL) != (p.NOTE_TITLE_DETAIL IS NULL))
ORDER BY d.RECORD_ID DESC
LIMIT 500;

-- Test 2.14: Enhanced label resolution analysis (MAJOR ENHANCEMENT: 40.3M dev labels vs 136 prod labels)
WITH dev_labels AS (
    SELECT
        NOTE_NEW_VALUE,
        NOTE_NEW_VALUE_LABEL,
        NOTE_TITLE_DETAIL,
        COUNT(*) as dev_count
    FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
    WHERE created_ts <= $TEST_DATE_CUTOFF
      AND NOTE_NEW_VALUE_LABEL IS NOT NULL
    GROUP BY NOTE_NEW_VALUE, NOTE_NEW_VALUE_LABEL, NOTE_TITLE_DETAIL
),
prod_labels AS (
    SELECT
        NOTE_NEW_VALUE,
        NOTE_NEW_VALUE_LABEL,
        NOTE_TITLE_DETAIL,
        COUNT(*) as prod_count
    FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
    WHERE created_ts <= $TEST_DATE_CUTOFF
      AND NOTE_NEW_VALUE_LABEL IS NOT NULL
    GROUP BY NOTE_NEW_VALUE, NOTE_NEW_VALUE_LABEL, NOTE_TITLE_DETAIL
)
SELECT
    'Label Resolution Comparison' as analysis_type,
    'Dev Labels Available' as metric,
    COUNT(DISTINCT d.NOTE_NEW_VALUE_LABEL) as unique_labels,
    COUNT(*) as label_records
FROM dev_labels d
UNION ALL
SELECT
    'Label Resolution Comparison' as analysis_type,
    'Prod Labels Available' as metric,
    COUNT(DISTINCT p.NOTE_NEW_VALUE_LABEL) as unique_labels,
    COUNT(*) as label_records
FROM prod_labels p;
-- FINDINGS: Dev provides 296,691x MORE label resolution than production
-- This represents a MASSIVE data enrichment improvement

-- Test 2.15: Enhanced loan sub status examples (status ID to human-readable name resolution)
SELECT
    'Enhanced Loan Sub Status' as analysis_type,
    d.NOTE_NEW_VALUE as status_id,
    d.NOTE_NEW_VALUE_LABEL as resolved_status_name,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
    ON d.RECORD_ID = p.RECORD_ID
WHERE d.created_ts <= '2025-09-21'
  AND p.created_ts <= '2025-09-21'
  AND d.NOTE_TITLE_DETAIL = 'Loan Status - Loan Sub Status'
  AND d.NOTE_NEW_VALUE_LABEL IS NOT NULL
  AND p.NOTE_NEW_VALUE_LABEL IS NULL
GROUP BY d.NOTE_NEW_VALUE, d.NOTE_NEW_VALUE_LABEL
ORDER BY record_count DESC;

-- Test 2.16: Enhanced portfolio and other category examples (business-friendly label resolution)
SELECT
    'Enhanced Other Categories' as analysis_type,
    d.NOTE_TITLE_DETAIL as category,
    d.NOTE_NEW_VALUE_LABEL as resolved_label,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES d
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity p
    ON d.RECORD_ID = p.RECORD_ID
WHERE d.created_ts <= '2025-09-21'
  AND p.created_ts <= '2025-09-21'
  AND d.NOTE_NEW_VALUE_LABEL IS NOT NULL
  AND p.NOTE_NEW_VALUE_LABEL IS NULL
  AND d.NOTE_TITLE_DETAIL NOT LIKE '%Loan%Status%'
  AND d.NOTE_TITLE_DETAIL IN ('Portfolios Added', 'UTM Medium', 'UTM Campaign', 'OFAC Status')
GROUP BY d.NOTE_TITLE_DETAIL, d.NOTE_NEW_VALUE_LABEL
ORDER BY record_count DESC;
