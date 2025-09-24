-- DI-926: Test PortfoliosRemoved logic for sample records
-- Testing extraction and mapping of PORTFOLIOS_REMOVED data

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- Test 1: Extract and validate PortfoliosRemoved from JSON for sample records
WITH test_records AS (
    SELECT
        a.id as record_id,
        a.entity_id as app_id,
        a.note_title,
        a.note_data,
        -- Parse JSON once
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(a.note_data), '[]'), 'null'), '') AS json_values,
        -- Extract PortfoliosRemoved ID
        trim(replace(object_keys(json_values:"PortfoliosRemoved":"newValue")[0],'"',''))::string as portfolios_removed,
        -- Extract PortfoliosAdded for comparison
        trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string as portfolios_added,
        -- Determine note_title_detail
        CASE
            WHEN json_values:"PortfoliosRemoved"::STRING IS NOT NULL THEN 'Portfolios Removed'
            WHEN json_values:"PortfoliosAdded"::STRING IS NOT NULL THEN 'Portfolios Added'
            WHEN json_values:"loanStatusId"::STRING IS NOT NULL THEN 'Loan Status - Loan Sub Status'
            WHEN json_values:"loanSubStatusId"::STRING IS NOT NULL THEN 'Loan Sub Status'
            ELSE NULL
        END as note_title_detail_computed
    FROM ARCA.FRESHSNOW.VW_SYSTEM_NOTE_ENTITY a
    WHERE a.id IN (681640067, 681639797, 681640775)
        AND a.reference_type = 'Entity.LoanSettings'
        AND a.deleted = 0
        AND a.is_hard_deleted = FALSE
        AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
)
SELECT
    record_id,
    app_id,
    note_title,
    portfolios_removed,
    portfolios_added,
    note_title_detail_computed,
    json_values:"PortfoliosRemoved" as portfolios_removed_json,
    note_data
FROM test_records
ORDER BY record_id;

-- Test 2: Verify portfolio entity lookup for removed portfolios
WITH portfolio_lookups AS (
    SELECT
        A.ID::STRING AS ID,
        A.TITLE,
        B.TITLE AS PORTFOLIO_CATEGORY
    FROM ARCA.FRESHSNOW.PORTFOLIO_ENTITY_CURRENT A
    LEFT JOIN ARCA.FRESHSNOW.PORTFOLIO_CATEGORY_ENTITY_CURRENT B
        ON A.CATEGORY_ID = B.ID AND B.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE A.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
        AND A.ID IN (102) -- Portfolio ID from sample records
)
SELECT
    ID as portfolio_id,
    TITLE as portfolio_label,
    PORTFOLIO_CATEGORY as portfolio_category
FROM portfolio_lookups;

-- Test 3: Complete logic simulation for sample records
WITH initial_pull AS (
    SELECT
        a.id as record_id,
        a.entity_id as app_id,
        convert_timezone('UTC','America/Los_Angeles',a.created) as created_ts,
        convert_timezone('UTC','America/Los_Angeles',a.lastupdated) as lastupdated_ts,
        a.note_title,
        a.note_data,
        a.deleted,
        a.is_hard_deleted,

        -- Single JSON parse
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(a.note_data), '[]'), 'null'), '') AS json_values,

        -- Note categorization
        CASE
            WHEN REGEXP_SUBSTR(a.note_title, '\\((.*?)\\)', 1, 1, 'e', 1) IS NULL THEN
                CASE
                    WHEN json_values IS NULL THEN NULL
                    ELSE
                        CASE
                            WHEN json_values:"loanStatusId"::STRING IS NOT NULL THEN 'Loan Status - Loan Sub Status'
                            WHEN json_values:"loanSubStatusId"::STRING IS NOT NULL THEN 'Loan Sub Status'
                            WHEN json_values:"PortfoliosAdded"::STRING IS NOT NULL THEN 'Portfolios Added'
                            WHEN json_values:"PortfoliosRemoved"::STRING IS NOT NULL THEN 'Portfolios Removed'
                            WHEN json_values:"sourceCompany"::STRING IS NOT NULL THEN 'Source Company'
                            WHEN json_values:"agent"::STRING IS NOT NULL THEN 'Agent'
                            WHEN json_values:"applyDefaultFieldMap"::STRING IS NOT NULL THEN 'Apply Default Field Map'
                        END
                END
            ELSE REGEXP_SUBSTR(a.NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1)
        END as note_title_detail,

        -- Value extraction for new value
        CASE
            WHEN a.note_title = 'Loan settings were created' THEN json_values:"loanSubStatusId"::STRING
            WHEN json_values:"loanSubStatusId"::STRING IS NOT NULL THEN json_values:"loanSubStatusId":"newValue"::STRING
            WHEN json_values:"PortfoliosAdded"::STRING IS NOT NULL THEN
                trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string
            WHEN json_values:"PortfoliosRemoved"::STRING IS NOT NULL THEN
                trim(replace(object_keys(json_values:"PortfoliosRemoved":"newValue")[0],'"',''))::string
            WHEN json_values:"agent"::STRING IS NOT NULL THEN json_values:"agent":"newValue"::string
            WHEN json_values:"sourceCompany"::STRING IS NOT NULL THEN json_values:"sourceCompany":"newValue"::string
            WHEN a.note_data LIKE '%applyDefaultFieldMap%' THEN NULLIF(json_values:"applyDefaultFieldMap":"newValue"::STRING, '[]')
            ELSE NULLIF(json_values:"customFieldValue":"newValue"::STRING, 'null')
        END as note_new_value_raw,

        -- Value extraction for old value
        CASE
            WHEN a.note_title = 'Loan settings were created' THEN json_values:"loanSubStatusId"::STRING
            WHEN json_values:"loanSubStatusId"::STRING IS NOT NULL THEN json_values:"loanSubStatusId":"oldValue"::STRING
            WHEN json_values:"PortfoliosAdded"::STRING IS NOT NULL THEN
                trim(replace(object_keys(json_values:"PortfoliosAdded":"oldValue")[0],'"',''))::string
            -- Note: PortfoliosRemoved typically doesn't have oldValue
            WHEN json_values:"agent"::STRING IS NOT NULL THEN json_values:"agent":"oldValue"::string
            WHEN json_values:"sourceCompany"::STRING IS NOT NULL THEN json_values:"sourceCompany":"oldValue"::string
            WHEN a.note_data LIKE '%applyDefaultFieldMap%' THEN NULLIF(json_values:"applyDefaultFieldMap":"oldValue"::STRING, '[]')
            ELSE NULLIF(json_values:"customFieldValue":"oldValue"::STRING, 'null')
        END as note_old_value_raw,

        -- Portfolio tracking
        trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string as portfolios_added,
        trim(replace(object_keys(json_values:"PortfoliosRemoved":"newValue")[0],'"',''))::string as portfolios_removed

    FROM ARCA.FRESHSNOW.VW_SYSTEM_NOTE_ENTITY a
    WHERE a.id IN (681640067, 681639797, 681640775)
        AND a.reference_type = 'Entity.LoanSettings'
        AND a.deleted = 0
        AND a.is_hard_deleted = FALSE
        AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
        AND TRY_PARSE_JSON(a.note_data) IS NOT NULL
),
portfolio_entity AS (
    SELECT A.ID::STRING AS ID,
           A.TITLE,
           B.TITLE AS PORTFOLIO_CATEGORY
    FROM ARCA.FRESHSNOW.PORTFOLIO_ENTITY_CURRENT A
    LEFT JOIN ARCA.FRESHSNOW.PORTFOLIO_CATEGORY_ENTITY_CURRENT B
        ON A.CATEGORY_ID = B.ID AND B.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE A.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
),
final_data AS (
    SELECT
        a.*,

        -- Note new value extraction with portfolio lookups
        CASE
            WHEN a.note_title_detail = 'Portfolios Added' THEN pe.title
            WHEN a.note_title_detail = 'Portfolios Removed' THEN pe_removed.title
            ELSE NULLIF(TRIM(a.note_new_value_raw),'')
        END AS note_new_value_extracted,

        -- Note old value extraction
        CASE
            WHEN a.note_title_detail = 'Portfolios Added' THEN pe2.title
            ELSE NULLIF(TRIM(a.note_old_value_raw),'')
        END AS note_old_value_extracted,

        -- Portfolio added fields
        pe.portfolio_category as portfolios_added_category,
        pe.title as portfolios_added_label,

        -- Portfolio removed fields
        pe_removed.portfolio_category as portfolios_removed_category,
        pe_removed.title as portfolios_removed_label

    FROM initial_pull a
    LEFT JOIN portfolio_entity pe ON try_to_number(a.portfolios_added) = pe.id::NUMBER
    LEFT JOIN portfolio_entity pe2 ON try_to_number(a.note_old_value_raw) = pe2.id::NUMBER AND a.note_title_detail = 'Portfolios Added'
    LEFT JOIN portfolio_entity pe_removed ON try_to_number(a.portfolios_removed) = pe_removed.id::NUMBER
)
SELECT
    record_id,
    app_id,
    created_ts,
    lastupdated_ts,
    note_new_value_extracted as note_new_value,
    note_new_value_extracted as note_new_value_label, -- Should be same as note_new_value after mapping
    note_old_value_extracted as note_old_value,
    note_old_value_extracted as note_old_value_label, -- Should be same as note_old_value after mapping
    note_title_detail,
    note_title,
    portfolios_added,
    portfolios_added_category,
    portfolios_added_label,
    portfolios_removed,
    portfolios_removed_category,
    portfolios_removed_label,
    deleted,
    is_hard_deleted
FROM final_data
ORDER BY record_id;

-- Test 4: Compare with production to verify expected differences
SELECT
    'Production Data' as source,
    RECORD_ID,
    APP_ID,
    NOTE_TITLE_DETAIL,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE,
    PORTFOLIOS_ADDED,
    PORTFOLIOS_REMOVED,
    PORTFOLIOS_ADDED_CATEGORY,
    PORTFOLIOS_ADDED_LABEL
FROM BUSINESS_INTELLIGENCE.BRIDGE.app_system_note_entity
WHERE RECORD_ID IN (681640067, 681639797, 681640775)
ORDER BY RECORD_ID;