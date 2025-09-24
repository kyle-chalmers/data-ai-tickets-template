-- DI-926: LOAN_STATUS_NEW Fix Analysis
-- Issue: Development view has NULL loan_status_new while production has values
-- Root Cause: Incorrect JOIN logic in development view

-- CURRENT DEVELOPMENT VIEW LOGIC (INCORRECT):
-- LEFT JOIN sub_status_entity d ON a.loan_status_new_id = d.id::STRING
-- LEFT JOIN sub_status_entity e ON a.loan_status_old_id = e.id::STRING

-- ORIGINAL STORED PROCEDURE LOGIC (CORRECT):
-- LEFT JOIN loan_status_entity d ON a.loan_status_new_id = d.id
-- AND a.note_title_detail = 'Loan Status - Loan Sub Status'

-- PROBLEM 1: Wrong table - should be loan_status_entity, not sub_status_entity
-- PROBLEM 2: Missing filter - should only populate when note_title_detail = 'Loan Status - Loan Sub Status'

-- Test query to demonstrate the fix needed:
WITH sample_data AS (
    SELECT
        record_id,
        app_id,
        note_title_detail,
        created_ts,
        -- Extract loan_status_new_id from JSON (same as current logic)
        CASE WHEN note_title = 'Loan settings were created'
             THEN TRY_PARSE_JSON(note_data):"loanStatusId"::STRING
             ELSE TRY_PARSE_JSON(note_data):"loanStatusId":"newValue"::STRING
        END as loan_status_new_id
    FROM ARCA.FRESHSNOW.VW_SYSTEM_NOTE_ENTITY
    WHERE reference_type = 'Entity.LoanSettings'
      AND deleted = 0
      AND is_hard_deleted = FALSE
      AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
      AND created_ts <= '2025-09-21'
      AND TRY_PARSE_JSON(note_data) IS NOT NULL
    LIMIT 100000
),
-- INCORRECT LOGIC (current dev view) - joins to sub_status_entity without filter
incorrect_logic AS (
    SELECT
        s.*,
        sub.title as incorrect_loan_status_new
    FROM sample_data s
    LEFT JOIN ARCA.FRESHSNOW.LOAN_SUB_STATUS_ENTITY_CURRENT sub
        ON s.loan_status_new_id = sub.id::STRING
        AND sub.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
),
-- CORRECT LOGIC (original procedure) - joins to loan_status_entity with filter
correct_logic AS (
    SELECT
        s.*,
        ls.title as correct_loan_status_new
    FROM sample_data s
    LEFT JOIN ARCA.FRESHSNOW.LOAN_STATUS_ENTITY_CURRENT ls
        ON s.loan_status_new_id = ls.id::STRING
        AND ls.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
        AND s.note_title_detail = 'Loan Status - Loan Sub Status'  -- CRITICAL FILTER
)
-- Compare the results
SELECT
    'Comparison Results' as analysis_type,
    COUNT(*) as total_sample_records,
    COUNT(i.incorrect_loan_status_new) as incorrect_logic_populated,
    COUNT(c.correct_loan_status_new) as correct_logic_populated,
    COUNT(DISTINCT i.incorrect_loan_status_new) as incorrect_unique_values,
    COUNT(DISTINCT c.correct_loan_status_new) as correct_unique_values
FROM sample_data s
LEFT JOIN incorrect_logic i ON s.record_id = i.record_id
LEFT JOIN correct_logic c ON s.record_id = c.record_id;

-- Show specific examples of the differences
WITH sample_data AS (
    SELECT
        record_id,
        app_id,
        note_title_detail,
        created_ts,
        CASE WHEN note_title = 'Loan settings were created'
             THEN TRY_PARSE_JSON(note_data):"loanStatusId"::STRING
             ELSE TRY_PARSE_JSON(note_data):"loanStatusId":"newValue"::STRING
        END as loan_status_new_id
    FROM ARCA.FRESHSNOW.VW_SYSTEM_NOTE_ENTITY
    WHERE reference_type = 'Entity.LoanSettings'
      AND deleted = 0
      AND is_hard_deleted = FALSE
      AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
      AND created_ts <= '2025-09-21'
      AND TRY_PARSE_JSON(note_data) IS NOT NULL
    LIMIT 10000
),
-- CORRECT LOGIC demonstration
correct_logic AS (
    SELECT
        s.record_id,
        s.note_title_detail,
        s.loan_status_new_id,
        ls.title as correct_loan_status_new
    FROM sample_data s
    LEFT JOIN ARCA.FRESHSNOW.LOAN_STATUS_ENTITY_CURRENT ls
        ON s.loan_status_new_id = ls.id::STRING
        AND ls.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
        AND s.note_title_detail = 'Loan Status - Loan Sub Status'  -- CRITICAL FILTER
    WHERE s.loan_status_new_id IS NOT NULL
)
SELECT
    'Examples of Correct Logic' as analysis_type,
    record_id,
    note_title_detail,
    loan_status_new_id,
    correct_loan_status_new
FROM correct_logic
WHERE correct_loan_status_new IS NOT NULL
ORDER BY record_id DESC
LIMIT 10;