-- DI-926: Development Working Views - Updated to Match Production Architecture EXACTLY
-- FRESHSNOW View (transformations) → FRESHSNOW Table (dbt) → BRIDGE View (SELECT *) → ANALYTICS View (enhancements)
-- Updated to reflect production-ready architecture with comprehensive business logic

-- Step 1: FRESHSNOW transformation view (all business logic here) - EXACT PRODUCTION MATCH
CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES(
    RECORD_ID,
    APP_ID, 
    CREATED_TS,
    LASTUPDATED_TS,
    LOAN_STATUS_NEW,
    LOAN_STATUS_OLD,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE, 
    NOTE_OLD_VALUE_LABEL,
    NOTE_TITLE_DETAIL,
    NOTE_TITLE,
    NOTE_DATA,
    DELETED,
    IS_HARD_DELETED,
    PORTFOLIOS_ADDED,
    PORTFOLIOS_ADDED_CATEGORY,
    PORTFOLIOS_ADDED_LABEL
) COPY GRANTS AS
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
        
        -- Loan Status extraction
        case when a.note_title = 'Loan settings were created' then json_values:"loanStatusId"::STRING 
             else json_values:"loanStatusId":"newValue"::STRING 
             end as loan_status_new_id,
        case when a.note_title = 'Loan settings were created' then json_values:"loanStatusId"::STRING 
             else json_values:"loanStatusId":"oldValue"::STRING 
             end as loan_status_old_id,
             
        -- Note categorization using pre-parsed JSON
        case when REGEXP_SUBSTR(a.note_title, '\\((.*?)\\)', 1, 1, 'e', 1) is null then 
                  case when json_values is null then null				
                      else 
                          case when json_values:"loanStatusId"::STRING is not null then 'Loan Status - Loan Sub Status'
                               when json_values:"loanSubStatusId"::STRING is not null then 'Loan Sub Status'
                               when json_values:"sourceCompany"::STRING is not null then 'Source Company'
                               when json_values:"agent"::STRING is not null then 'Agent'
                               when json_values:"PortfoliosAdded"::STRING is not null then 'Portfolios Added'
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
        trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string as portfolios_added
        
    FROM RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY a
    WHERE a.schema_name = ARCA.CONFIG.LOS_SCHEMA()
        AND a.reference_type IN ('Entity.LoanSettings') 
        AND a.deleted = 0
        AND a.is_hard_deleted = FALSE
        AND TRY_PARSE_JSON(a.note_data) IS NOT NULL  -- Filter malformed JSON upfront
),
sub_status_entity AS (
    SELECT DISTINCT ID, TITLE
    FROM RAW_DATA_STORE.LOANPRO.LOAN_SUB_STATUS_ENTITY
    WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA() AND deleted = 0
),
source_company AS (
    SELECT DISTINCT ID, COMPANY_NAME
    FROM RAW_DATA_STORE.LOANPRO.SOURCE_COMPANY_ENTITY
    WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA() AND deleted = 0
),
portfolio_entity AS (
    SELECT DISTINCT A.ID::STRING AS ID,
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
-- Value transformation with lookups
final_data AS (
    SELECT 
        a.*,
        -- Status lookups
        d.title as loan_status_new,
        e.title as loan_status_old,
        
        -- Value transformation with tier handling (APPL_HISTORY pattern)
        CASE WHEN a.note_title_detail = 'tier'
            THEN IFF(left(a.note_new_value_raw, 1) = 't', right(a.note_new_value_raw, 1), a.note_new_value_raw)
            WHEN a.note_title_detail like '%Loan Sub Status%' THEN b.title
            WHEN a.note_title_detail = 'Source Company' THEN sc.company_name
            WHEN a.note_title_detail = 'Portfolios Added' THEN pe.title
            ELSE NULLIF(TRIM(a.note_new_value_raw),'') 
        END AS note_new_value_extracted,
        
        CASE WHEN a.note_title_detail = 'tier'
            THEN IFF(left(a.note_old_value_raw, 1) = 't', right(a.note_old_value_raw, 1), a.note_old_value_raw)
            WHEN a.note_title_detail like '%Loan Sub Status%' THEN c.title
            WHEN a.note_title_detail = 'Source Company' THEN sc2.company_name
            WHEN a.note_title_detail = 'Portfolios Added' THEN pe2.title
            ELSE NULLIF(TRIM(a.note_old_value_raw),'') 
        END AS note_old_value_extracted,
        
        -- Portfolio details
        pe.portfolio_category as portfolios_added_category,
        pe.title as portfolios_added_label
        
    FROM initial_pull a
    LEFT JOIN sub_status_entity b ON a.note_new_value_raw = b.id::STRING AND a.note_title_detail like '%Loan Sub Status%'
    LEFT JOIN sub_status_entity c ON a.note_old_value_raw = c.id::STRING AND a.note_title_detail like '%Loan Sub Status%'
    LEFT JOIN sub_status_entity d ON a.loan_status_new_id = d.id::STRING
    LEFT JOIN sub_status_entity e ON a.loan_status_old_id = e.id::STRING
    LEFT JOIN source_company sc ON a.note_new_value_raw = sc.id::STRING AND a.note_title_detail = 'Source Company'
    LEFT JOIN source_company sc2 ON a.note_old_value_raw = sc2.id::STRING AND a.note_title_detail = 'Source Company'
    LEFT JOIN portfolio_entity pe ON try_to_number(a.note_new_value_raw) = pe.id::NUMBER AND a.note_title_detail = 'Portfolios Added'
    LEFT JOIN portfolio_entity pe2 ON try_to_number(a.note_old_value_raw) = pe2.id::NUMBER AND a.note_title_detail = 'Portfolios Added'
)
SELECT 
    record_id,
    app_id,
    created_ts,
    lastupdated_ts,
    loan_status_new,
    loan_status_old,
    note_new_value_extracted as note_new_value,
    -- Custom field labels applied at final stage (APPL_HISTORY pattern)
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
    portfolios_added_label
    
FROM final_data
LEFT JOIN custom_field_labels cf1 ON note_title_detail = cf1.custom_field_name AND note_new_value_extracted = cf1.custom_field_value_id
LEFT JOIN custom_field_labels cf2 ON note_title_detail = cf2.custom_field_name AND note_old_value_extracted = cf2.custom_field_value_id
ORDER BY record_id DESC;

-- Step 2: BRIDGE view - Simple SELECT * from FRESHSNOW table (dbt materialized)
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES(
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    LASTUPDATED_TS,
    LOAN_STATUS_NEW,
    LOAN_STATUS_OLD,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE,
    NOTE_OLD_VALUE_LABEL,
    NOTE_TITLE_DETAIL,
    NOTE_TITLE,
    NOTE_DATA,
    DELETED,
    IS_HARD_DELETED,
    PORTFOLIOS_ADDED,
    PORTFOLIOS_ADDED_CATEGORY,
    PORTFOLIOS_ADDED_LABEL
) COPY GRANTS AS 
SELECT * FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;

-- Step 3: ANALYTICS view with business enhancements
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES(
    RECORD_ID,
    APP_ID,
    CREATED_TS,
    CREATED_DATE,
    LASTUPDATED_TS,
    LOAN_STATUS_NEW,
    LOAN_STATUS_OLD,
    LOAN_STATUS_CHANGED_FLAG,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL,
    NOTE_OLD_VALUE,
    NOTE_OLD_VALUE_LABEL,
    VALUE_CHANGED_FLAG,
    NOTE_TITLE_DETAIL,
    CHANGE_TYPE_CATEGORY,
    CREATED_HOUR,
    CREATED_DAY_OF_WEEK,
    CREATED_WEEK,
    CREATED_MONTH,
    IS_STATUS_CHANGE,
    IS_PORTFOLIO_CHANGE,
    IS_AGENT_CHANGE,
    NOTE_TITLE,
    DELETED,
    IS_HARD_DELETED,
    PORTFOLIOS_ADDED,
    PORTFOLIOS_ADDED_CATEGORY,
    PORTFOLIOS_ADDED_LABEL
) COPY GRANTS AS 
SELECT
    RECORD_ID, 
    APP_ID, 
    CREATED_TS, 
    CREATED_TS::date as CREATED_DATE, 
    LASTUPDATED_TS,
    LOAN_STATUS_NEW, 
    LOAN_STATUS_OLD,
    case when LOAN_STATUS_NEW != LOAN_STATUS_OLD then 1 else 0 end as LOAN_STATUS_CHANGED_FLAG,
    NOTE_NEW_VALUE,
    NOTE_NEW_VALUE_LABEL, 
    NOTE_OLD_VALUE,
    NOTE_OLD_VALUE_LABEL,
    case when NOTE_NEW_VALUE is not null and NOTE_OLD_VALUE is not null 
         and NOTE_NEW_VALUE != NOTE_OLD_VALUE then 1 else 0 end as VALUE_CHANGED_FLAG,
    NOTE_TITLE_DETAIL,
    case when NOTE_TITLE_DETAIL like '%Status%' then 'Status Change'
         when NOTE_TITLE_DETAIL like '%Portfolio%' then 'Portfolio Management'
         when NOTE_TITLE_DETAIL = 'Agent' then 'Agent Assignment'
         when NOTE_TITLE_DETAIL = 'Source Company' then 'Source Management'
         else 'Other' end as CHANGE_TYPE_CATEGORY,
    EXTRACT(HOUR FROM CREATED_TS) as CREATED_HOUR,
    EXTRACT(DAYOFWEEK FROM CREATED_TS) as CREATED_DAY_OF_WEEK,
    DATE_TRUNC('week', CREATED_TS::date) as CREATED_WEEK,
    DATE_TRUNC('month', CREATED_TS::date) as CREATED_MONTH,
    case when NOTE_TITLE_DETAIL like '%Loan Status%' then 1 else 0 end as IS_STATUS_CHANGE,
    case when NOTE_TITLE_DETAIL like '%Portfolio%' then 1 else 0 end as IS_PORTFOLIO_CHANGE,
    case when NOTE_TITLE_DETAIL = 'Agent' then 1 else 0 end as IS_AGENT_CHANGE,
    NOTE_TITLE, 
    DELETED, 
    IS_HARD_DELETED,
    PORTFOLIOS_ADDED,
    PORTFOLIOS_ADDED_CATEGORY,
    PORTFOLIOS_ADDED_LABEL
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Architecture Notes:
-- 1. FRESHSNOW View: Contains EXACT production transformations (JSON parsing, lookups, categorization)
-- 2. FRESHSNOW Table: Materialized by dbt job from FRESHSNOW view (external to this deployment)
-- 3. BRIDGE View: Simple pass-through SELECT * from FRESHSNOW table (corrected architecture pattern)
-- 4. ANALYTICS View: Business enhancements only (time dimensions, flags, analytical calculations)
-- 5. Data Source: RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY (production data)
-- 6. Performance: Single JSON parse optimization, timezone conversion, comprehensive reference lookups
-- 7. Business Logic: EXACT match to production including tier handling, custom field labels, portfolio lookups