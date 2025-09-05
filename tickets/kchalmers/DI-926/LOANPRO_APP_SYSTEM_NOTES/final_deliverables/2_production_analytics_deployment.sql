-- DI-926: ANALYTICS Layer Production Deployment
-- Deploy ANALYTICS view with business enhancements using template format
-- Architecture: BRIDGE view → ANALYTICS view

DECLARE
    -- dev databases (for testing)
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    
    -- prod databases (uncomment for production deployment)
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE';

BEGIN

-- ANALYTICS LAYER: Business enhancements with time dimensions and change flags
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES(
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
            IS_SUB_STATUS_CHANGE,
            IS_PORTFOLIO_CHANGE,
            IS_AGENT_CHANGE,
            IS_SOURCE_COMPANY_CHANGE,
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
                case when NOTE_TITLE_DETAIL like ''%Status%'' then ''Status Change''
                     when NOTE_TITLE_DETAIL like ''%Portfolio%'' then ''Portfolio Management''
                     when NOTE_TITLE_DETAIL = ''Agent'' then ''Agent Assignment''
                     when NOTE_TITLE_DETAIL = ''Source Company'' then ''Source Management''
                     else ''Other'' end as CHANGE_TYPE_CATEGORY,
                EXTRACT(HOUR FROM CREATED_TS) as CREATED_HOUR,
                EXTRACT(DAYOFWEEK FROM CREATED_TS) as CREATED_DAY_OF_WEEK,
                DATE_TRUNC(''week'', CREATED_TS::date) as CREATED_WEEK,
                DATE_TRUNC(''month'', CREATED_TS::date) as CREATED_MONTH,
                case when NOTE_TITLE_DETAIL like ''%Loan Sub Status%'' then 1 else 0 end as IS_SUB_STATUS_CHANGE,
                case when NOTE_TITLE_DETAIL like ''%Portfolio%'' then 1 else 0 end as IS_PORTFOLIO_CHANGE,
                case when NOTE_TITLE_DETAIL = ''Agent'' then 1 else 0 end as IS_AGENT_CHANGE,
                case when NOTE_TITLE_DETAIL = ''Source Company'' then 1 else 0 end as IS_SOURCE_COMPANY_CHANGE,
                NOTE_TITLE, 
                DELETED, 
                IS_HARD_DELETED,
                PORTFOLIOS_ADDED,
                PORTFOLIOS_ADDED_CATEGORY,
                PORTFOLIOS_ADDED_LABEL
            FROM ' || v_bi_db || '.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
    ');

END;

-- Architecture Notes:
-- 1. ANALYTICS View: Business enhancements only (time dimensions, flags, analytical calculations)
-- 2. Source: BRIDGE layer provides clean, transformed data as foundation
-- 3. Enhancements: Time dimensions (hour, day of week, week, month), change flags, categorization
-- 4. Deployment: Uncomment production variables for production deployment
-- 5. Testing: Use development variables for testing before production deployment