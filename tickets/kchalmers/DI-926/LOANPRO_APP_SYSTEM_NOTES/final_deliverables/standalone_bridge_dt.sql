-- DI-926: Standalone BRIDGE Dynamic Table Script for LOANPRO_APP_SYSTEM_NOTES
-- This script creates the BRIDGE dynamic table independently without the stored procedure wrapper
-- Use this for standalone dynamic table creation or testing

-- Drop existing table if it exists
DROP dynamic TABLE IF EXISTS BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES;
use role BUSINESS_INTELLIGENCE_PII;
ALTER DYNAMIC TABLE BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES REFRESH;
CREATE OR REPLACE DYNAMIC TABLE BUSINESS_INTELLIGENCE_DEV.BRIDGE.LOANPRO_APP_SYSTEM_NOTES
TARGET_LAG = DOWNSTREAM
refresh_mode = AUTO
WAREHOUSE = BUSINESS_INTELLIGENCE
INITIALIZE = ON_SCHEDULE
AS
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

        -- Single JSON parse with variable reuse (APPL_HISTORY pattern)
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(a.note_data), '[]'), 'null'), '') AS json_values,

        -- Loan Status extraction (COMMENTED OUT - NOT NEEDED)
        /*case when a.note_title = 'Loan settings were created' then json_values:"loanStatusId"::STRING
             else json_values:"loanStatusId":"newValue"::STRING
             end as loan_status_new_id,
        case when a.note_title = 'Loan settings were created' then json_values:"loanStatusId"::STRING
             else json_values:"loanStatusId":"oldValue"::STRING
             end as loan_status_old_id,*/

        -- Note categorization using pre-parsed JSON
        case when REGEXP_SUBSTR(a.note_title, '\\((.*?)\\)', 1, 1, 'e', 1) is null then
                  case when json_values is null then null
                      else
                          case when json_values:"loanStatusId"::STRING is not null then 'Loan Status - Loan Sub Status'
                               when json_values:"loanSubStatusId"::STRING is not null then 'Loan Sub Status'
                               when json_values:"sourceCompany"::STRING is not null then 'Source Company'
                               when json_values:"agent"::STRING is not null then 'Agent'
                               when json_values:"PortfoliosAdded"::STRING is not null then 'Portfolios Added'
                               when json_values:"PortfoliosRemoved"::STRING is not null then 'Portfolios Removed'
                               when json_values:"applyDefaultFieldMap"::STRING is not null then 'Apply Default Field Map'
                               when json_values:"followUpDate"::STRING is not null then 'FollowUp Date'
                               when json_values:"eBilling"::STRING is not null then 'eBilling'
                               when json_values:"creditBureau"::STRING is not null then 'Credit Bureau'
                               when json_values:"autopayEnabled"::STRING is not null then 'Autopay Enabled'
                          end
                  end
            else REGEXP_SUBSTR(a.NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1)
            end as note_title_detail,

        -- Value extraction using pre-parsed JSON
        case when a.note_title = 'Loan settings were created' then json_values:"loanSubStatusId"::STRING
             when json_values:"loanSubStatusId"::STRING is not null then json_values:"loanSubStatusId":"newValue"::STRING
             when json_values:"agent"::STRING is not null then json_values:"agent":"newValue"::string
             when json_values:"sourceCompany"::STRING is not null then json_values:"sourceCompany":"newValue"::string
             when json_values:"PortfoliosAdded"::STRING is not null then
                  trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string
             when json_values:"PortfoliosRemoved"::STRING is not null then
                  trim(replace(object_keys(json_values:"PortfoliosRemoved":"newValue")[0],'"',''))::string
             when a.note_data like '%applyDefaultFieldMap%' then NULLIF(json_values:"applyDefaultFieldMap":"newValue"::STRING, '[]')
             else NULLIF(json_values:"customFieldValue":"newValue"::STRING, 'null')
             end as note_new_value_raw,

        case when a.note_title = 'Loan settings were created' then json_values:"loanSubStatusId"::STRING
             when json_values:"loanSubStatusId"::STRING is not null then json_values:"loanSubStatusId":"oldValue"::STRING
             when json_values:"agent"::STRING is not null then json_values:"agent":"oldValue"::string
             when json_values:"sourceCompany"::STRING is not null then json_values:"sourceCompany":"oldValue"::string
             when json_values:"PortfoliosAdded"::STRING is not null then
                  trim(replace(object_keys(json_values:"PortfoliosAdded":"oldValue")[0],'"',''))::string
             when a.note_data like '%applyDefaultFieldMap%' then NULLIF(json_values:"applyDefaultFieldMap":"oldValue"::STRING, '[]')
             else NULLIF(json_values:"customFieldValue":"oldValue"::STRING, 'null')
             end as note_old_value_raw,

        -- Portfolio tracking
        trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string as portfolios_added,
        trim(replace(object_keys(json_values:"PortfoliosRemoved":"newValue")[0],'"',''))::string as portfolios_removed

    FROM ARCA.FRESHSNOW.VW_SYSTEM_NOTE_ENTITY a
    WHERE a.reference_type IN ('Entity.LoanSettings')
        AND a.deleted = 0
        AND a.is_hard_deleted = FALSE
        AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
        AND TRY_PARSE_JSON(a.note_data) IS NOT NULL
),
sub_status_entity AS (
    SELECT ID, TITLE
    FROM ARCA.FRESHSNOW.LOAN_SUB_STATUS_ENTITY_CURRENT
    WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
),
source_company AS (
    SELECT ID, COMPANY_NAME
    FROM ARCA.FRESHSNOW.VW_SOURCE_COMPANY_ENTITY_CURRENT
    WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
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
custom_field_labels AS (
    SELECT CUSTOM_FIELD_NAME, CUSTOM_FIELD_VALUE_ID, CUSTOM_FIELD_VALUE_LABEL
    FROM ARCA.FRESHSNOW.VW_CUSTOM_FIELD_LABELS
    WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
),
final_data AS (
    SELECT
        a.*,
        /*d.title as loan_status_new,
        e.title as loan_status_old,*/

        CASE WHEN a.note_title_detail = 'tier'
            THEN IFF(left(a.note_new_value_raw, 1) = 't', right(a.note_new_value_raw, 1), a.note_new_value_raw)
            WHEN a.note_title_detail like '%Loan Sub Status%' THEN b.title
            WHEN a.note_title_detail = 'Source Company' THEN sc.company_name
            WHEN a.note_title_detail = 'Portfolios Added' THEN pe.title
            WHEN a.note_title_detail = 'Portfolios Removed' THEN pe_removed.title
            ELSE NULLIF(TRIM(a.note_new_value_raw),'')
        END AS note_new_value_extracted,

        CASE WHEN a.note_title_detail = 'tier'
            THEN IFF(left(a.note_old_value_raw, 1) = 't', right(a.note_old_value_raw, 1), a.note_old_value_raw)
            WHEN a.note_title_detail like '%Loan Sub Status%' THEN c.title
            WHEN a.note_title_detail = 'Source Company' THEN sc2.company_name
            WHEN a.note_title_detail = 'Portfolios Added' THEN pe2.title
            ELSE NULLIF(TRIM(a.note_old_value_raw),'')
        END AS note_old_value_extracted,

        pe.portfolio_category as portfolios_added_category,
        pe.title as portfolios_added_label,
        pe_removed.portfolio_category as portfolios_removed_category,
        pe_removed.title as portfolios_removed_label

    FROM initial_pull a
    LEFT JOIN sub_status_entity b ON a.note_new_value_raw = b.id::STRING AND a.note_title_detail like '%Loan Sub Status%'
    LEFT JOIN sub_status_entity c ON a.note_old_value_raw = c.id::STRING AND a.note_title_detail like '%Loan Sub Status%'
    /*LEFT JOIN sub_status_entity d ON a.loan_status_new_id = d.id::STRING
    LEFT JOIN sub_status_entity e ON a.loan_status_old_id = e.id::STRING*/
    LEFT JOIN source_company sc ON a.note_new_value_raw = sc.id::STRING AND a.note_title_detail = 'Source Company'
    LEFT JOIN source_company sc2 ON a.note_old_value_raw = sc2.id::STRING AND a.note_title_detail = 'Source Company'
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
    COALESCE(cf1.custom_field_value_label, note_new_value_extracted) as note_new_value_label,
    note_old_value_extracted as note_old_value,
    COALESCE(cf2.custom_field_value_label, note_old_value_extracted) as note_old_value_label,
    note_title_detail,
    note_title,
    note_data,
    deleted,
    is_hard_deleted,
    portfolios_added,
    portfolios_added_category,
    portfolios_added_label,
    portfolios_removed,
    portfolios_removed_category,
    portfolios_removed_label

FROM final_data
LEFT JOIN custom_field_labels cf1 ON note_title_detail = cf1.custom_field_name AND note_new_value_extracted = cf1.custom_field_value_id
LEFT JOIN custom_field_labels cf2 ON note_title_detail = cf2.custom_field_name AND note_old_value_extracted = cf2.custom_field_value_id
ORDER BY record_id DESC;