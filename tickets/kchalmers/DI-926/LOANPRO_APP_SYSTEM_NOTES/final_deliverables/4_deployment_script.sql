-- DI-926: Deploy LoanPro App System Notes Views
-- Replaces BUSINESS_INTELLIGENCE.CRON_STORE.LOANPRO_APP_SYSTEM_NOTES procedure
-- Follows 5-layer architecture: FRESHSNOW → BRIDGE → ANALYTICS

DECLARE
    -- Development databases (default)
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    v_rds_db varchar default 'DEVELOPMENT';
    
    -- Production databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    -- v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN
    -- FRESHSNOW Layer: Raw data extraction and JSON parsing
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES(
            APP_ID,
            CREATED_TS,
            LASTUPDATED_TS,
            LOAN_STATUS_NEW_ID,
            LOAN_STATUS_OLD_ID,
            NOTE_NEW_VALUE_RAW,
            NOTE_OLD_VALUE_RAW,
            NOTE_CATEGORY,
            NOTE_TITLE,
            NOTE_DATA,
            DELETED,
            IS_HARD_DELETED
        ) COPY GRANTS AS 
        SELECT 
            entity_id as app_id,
            convert_timezone(''UTC'',''America/Los_Angeles'',created) as created_ts,
            convert_timezone(''UTC'',''America/Los_Angeles'',lastupdated) as lastupdated_ts,
            
            -- Loan Status ID extraction for status change tracking
            case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanStatusId""::STRING 
                 else parse_json(note_data):""loanStatusId"":""newValue""::STRING 
                 end as loan_status_new_id,
            case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanStatusId""::STRING 
                 else parse_json(note_data):""loanStatusId"":""oldValue""::STRING 
                 end as loan_status_old_id,
                 
            -- New Value extraction from nested JSON structures
            case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanSubStatusId""::STRING 
                 when parse_json(note_data):""loanSubStatusId""::STRING is not null then parse_json(note_data):""loanSubStatusId"":""newValue""::STRING
                 when parse_json(note_data):""agent""::STRING is not null then parse_json(note_data):""agent"":""newValue""::string
                 when parse_json(note_data):""sourceCompany""::STRING is not null then parse_json(note_data):""sourceCompany"":""newValue""::string
                 when parse_json(note_data):""PortfoliosAdded""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosAdded"":""newValue"")[0],''"'',''''))::string
                 when parse_json(note_data):""PortfoliosRemoved""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosRemoved"":""newValue"")[0],''"'',''''))::string
                 when note_data like ''%applyDefaultFieldMap%'' then parse_json(note_data):""applyDefaultFieldMap"":""newValue""::STRING 
                 else parse_json(note_data):""customFieldValue"":""newValue""::STRING 
                 end as note_new_value_raw,
                 
            -- Old Value extraction from nested JSON structures
            case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanSubStatusId""::STRING 
                 when parse_json(note_data):""loanSubStatusId""::STRING is not null then parse_json(note_data):""loanSubStatusId"":""oldValue""::STRING
                 when parse_json(note_data):""agent""::STRING is not null then parse_json(note_data):""agent"":""oldValue""::string
                 when parse_json(note_data):""sourceCompany""::STRING is not null then parse_json(note_data):""sourceCompany"":""oldValue""::string
                 when parse_json(note_data):""PortfoliosAdded""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosAdded"":""oldValue"")[0],''"'',''''))::string
                 when parse_json(note_data):""PortfoliosRemoved""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosRemoved"":""oldValue"")[0],''"'',''''))::string
                 when note_data like ''%applyDefaultFieldMap%'' then parse_json(note_data):""applyDefaultFieldMap"":""oldValue""::STRING 
                 else parse_json(note_data):""customFieldValue"":""oldValue""::STRING     
                 end as note_old_value_raw,
                 
            -- Categorize note types based on JSON structure
            case when REGEXP_SUBSTR(note_title, ''\\\\((.*?)\\\\)'', 1, 1, ''e'', 1) is null then 
                      case when TRY_PARSE_JSON(note_data) is null then null								
                          else 
                              case when parse_json(note_data):""loanStatusId""::STRING is not null then ''Loan Status - Loan Sub Status''
                                   when parse_json(note_data):""loanSubStatusId""::STRING is not null then ''Loan Sub Status''
                                   when parse_json(note_data):""sourceCompany""::STRING is not null then ''Source Company''
                                   when parse_json(note_data):""agent""::STRING is not null then ''Agent''
                                   when parse_json(note_data):""PortfoliosAdded""::STRING is not null then ''Portfolios Added''
                                   when parse_json(note_data):""PortfoliosRemoved""::STRING is not null then ''Portfolios Removed''
                                   when parse_json(note_data):""applyDefaultFieldMap""::STRING is not null then ''Apply Default Field Map''
                                   when parse_json(note_data):""followUpDate""::STRING is not null then ''FollowUp Date''
                                   when parse_json(note_data):""eBilling""::STRING is not null then ''eBilling''
                                   when parse_json(note_data):""creditBureau""::STRING is not null then ''Credit Bureau''
                                   when parse_json(note_data):""autopayEnabled""::STRING is not null then ''Autopay Enabled''
                              end
                      end
                else REGEXP_SUBSTR(NOTE_TITLE, ''\\\\((.*?)\\\\)'', 1, 1, ''e'', 1)  
                end as note_category,
                
            note_title,
            note_data,
            deleted,
            is_hard_deleted
            
        FROM raw_data_store.loanpro.system_note_entity
        WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA()
            AND reference_type IN (''Entity.LoanSettings'') 
            AND deleted = 0
            AND is_hard_deleted = FALSE
    ');

    -- BRIDGE Layer: Add reference lookups
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES(
            APP_ID,
            CREATED_TS,
            LASTUPDATED_TS,
            LOAN_STATUS_NEW,
            LOAN_STATUS_OLD,
            DELETED_LOAN_STATUS_NEW,
            DELETED_LOAN_STATUS_OLD,
            NOTE_NEW_VALUE,
            NOTE_OLD_VALUE,
            DELETED_SUB_STATUS_NEW,
            DELETED_SUB_STATUS_OLD,
            NOTE_CATEGORY_DETAIL,
            NOTE_TITLE,
            NOTE_DATA,
            DELETED,
            IS_HARD_DELETED,
            NOTE_NEW_VALUE_RAW,
            NOTE_OLD_VALUE_RAW,
            LOAN_STATUS_NEW_ID,
            LOAN_STATUS_OLD_ID
        ) COPY GRANTS AS 
        SELECT
            APP_ID, CREATED_TS, LASTUPDATED_TS, LOAN_STATUS_NEW_ID, LOAN_STATUS_OLD_ID,
            NOTE_NEW_VALUE_RAW, NOTE_OLD_VALUE_RAW, NOTE_CATEGORY, NOTE_TITLE, NOTE_DATA,
            DELETED, IS_HARD_DELETED,
            NULL as LOAN_STATUS_NEW, NULL as LOAN_STATUS_OLD,
            NULL as DELETED_LOAN_STATUS_NEW, NULL as DELETED_LOAN_STATUS_OLD,
            NOTE_NEW_VALUE_RAW as NOTE_NEW_VALUE, NOTE_OLD_VALUE_RAW as NOTE_OLD_VALUE,
            NULL as DELETED_SUB_STATUS_NEW, NULL as DELETED_SUB_STATUS_OLD,
            NOTE_CATEGORY as NOTE_CATEGORY_DETAIL
        FROM ' || v_de_db ||'.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
    ');
    
    -- ANALYTICS Layer: Business-ready data
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES(
            APP_ID,
            CREATED_TS,
            CREATED_DATE,
            LASTUPDATED_TS,
            LOAN_STATUS_NEW,
            LOAN_STATUS_OLD,
            LOAN_STATUS_CHANGED_FLAG,
            NOTE_NEW_VALUE,
            NOTE_OLD_VALUE,
            VALUE_CHANGED_FLAG,
            NOTE_CATEGORY_DETAIL,
            CHANGE_TYPE_CATEGORY,
            CREATED_HOUR,
            CREATED_DAY_OF_WEEK,
            CREATED_WEEK,
            CREATED_MONTH,
            IS_SUB_STATUS_CHANGE,
            IS_PORTFOLIO_CHANGE,
            IS_AGENT_CHANGE,
            IS_SOURCE_COMPANY_CHANGE,
            NOTE_TITLE,
            DELETED,
            IS_HARD_DELETED,
            LOAN_STATUS_NEW_ID,
            LOAN_STATUS_OLD_ID
        ) COPY GRANTS AS 
        SELECT
            APP_ID, CREATED_TS, CREATED_TS::date as CREATED_DATE, LASTUPDATED_TS,
            LOAN_STATUS_NEW, LOAN_STATUS_OLD,
            case when LOAN_STATUS_NEW != LOAN_STATUS_OLD then 1 else 0 end as LOAN_STATUS_CHANGED_FLAG,
            NOTE_NEW_VALUE, NOTE_OLD_VALUE,
            case when NOTE_NEW_VALUE is not null and NOTE_OLD_VALUE is not null 
                 and NOTE_NEW_VALUE != NOTE_OLD_VALUE then 1 else 0 end as VALUE_CHANGED_FLAG,
            NOTE_CATEGORY_DETAIL,
            case when NOTE_CATEGORY_DETAIL like ''%Status%'' then ''Status Change''
                 when NOTE_CATEGORY_DETAIL like ''%Portfolio%'' then ''Portfolio Management''
                 when NOTE_CATEGORY_DETAIL = ''Agent'' then ''Agent Assignment''
                 when NOTE_CATEGORY_DETAIL = ''Source Company'' then ''Source Management''
                 else ''Other'' end as CHANGE_TYPE_CATEGORY,
            EXTRACT(HOUR FROM CREATED_TS) as CREATED_HOUR,
            EXTRACT(DAYOFWEEK FROM CREATED_TS) as CREATED_DAY_OF_WEEK,
            DATE_TRUNC(''week'', CREATED_TS::date) as CREATED_WEEK,
            DATE_TRUNC(''month'', CREATED_TS::date) as CREATED_MONTH,
            case when NOTE_CATEGORY_DETAIL like ''%Loan Sub Status%'' then 1 else 0 end as IS_SUB_STATUS_CHANGE,
            case when NOTE_CATEGORY_DETAIL like ''%Portfolio%'' then 1 else 0 end as IS_PORTFOLIO_CHANGE,
            case when NOTE_CATEGORY_DETAIL = ''Agent'' then 1 else 0 end as IS_AGENT_CHANGE,
            case when NOTE_CATEGORY_DETAIL = ''Source Company'' then 1 else 0 end as IS_SOURCE_COMPANY_CHANGE,
            NOTE_TITLE, DELETED, IS_HARD_DELETED, LOAN_STATUS_NEW_ID, LOAN_STATUS_OLD_ID
        FROM ' || v_bi_db ||'.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
    ');
    
    RETURN 'DI-926: LoanPro App System Notes views deployed successfully across FRESHSNOW → BRIDGE → ANALYTICS layers.';
END;