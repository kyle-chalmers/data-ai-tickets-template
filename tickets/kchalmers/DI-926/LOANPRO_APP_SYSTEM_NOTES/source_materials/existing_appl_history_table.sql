-- EXISTING: ARCA.FRESHSNOW.APPL_HISTORY (Dynamic Table)
-- Source: Retrieved 2025-01-22 for dependency analysis

create or replace dynamic table APPL_HISTORY(
	ID,
	APPLICATION_ID,
	NOTE_TITLE,
	NOTE_DATA,
	REFERENCE_TYPE,
	OPERATION_TYPE,
	OPERATION_SUB_TYPE,
	ROW_EVENT_TYPE,
	CREATE_USER,
	CREATE_USER_NAME,
	CREATED,
	LASTUPDATED,
	DELETED,
	IS_HARD_DELETED,
	BEFORE_VALUES,
	NEWVALUE,
	NEWVALUE_LABEL,
	OLDVALUE,
	OLDVALUE_LABEL,
	NOTE_TITLE_DETAIL
) target_lag = 'DOWNSTREAM' refresh_mode = AUTO initialize = ON_CREATE warehouse = BUSINESS_INTELLIGENCE
 as WITH initial_pull AS (
    SELECT A.ID,
        A.ENTITY_ID,
        A.NOTE_TITLE,
        -- Ensure JSON parsing does not return '[]', 'null', or empty string
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(A.NOTE_DATA), '[]'), 'null'), '') AS json_values,

        COALESCE(
            REGEXP_SUBSTR(A.NOTE_TITLE, '\((.*?)\)', 1, 1, 'e', 1),
            CASE
                WHEN json_values:"loanSubStatusId" IS NOT NULL
                 AND json_values:"loanStatusId" IS NOT NULL THEN 'Loan Status - Loan Sub Status'
                WHEN json_values:"loanSubStatusId" IS NOT NULL THEN 'Loan Sub Status'
                WHEN json_values:"sourceCompany" IS NOT NULL THEN 'Source Company'
                WHEN json_values:"agent" IS NOT NULL THEN 'Agent'
                WHEN json_values:"PortfoliosAdded" IS NOT NULL THEN 'Portfolios Added'
                WHEN json_values:"PortfoliosRemoved" IS NOT NULL THEN 'Portfolios Removed'
                WHEN json_values:"applyDefaultFieldMap" IS NOT NULL THEN 'Apply Default Field Map'
                WHEN json_values:"followUpDate" IS NOT NULL THEN 'FollowUp Date'
                WHEN json_values:"eBilling" IS NOT NULL THEN 'eBilling'
                WHEN json_values:"creditBureau" IS NOT NULL THEN 'Credit Bureau'
                WHEN json_values:"autopayEnabled" IS NOT NULL THEN 'Autopay Enabled'
            END
        ) AS NOTE_TITLE_DETAIL,
        A.REFERENCE_TYPE,
        A.OPERATION_TYPE,
        A.OPERATION_SUB_TYPE,
        A.ROW_EVENT_TYPE,
        A.CREATE_USER,
        A.CREATE_USER_NAME,
        A.CREATED,
        A.LASTUPDATED,
        A.DELETED,
        A.IS_HARD_DELETED,
        A.BEFORE_VALUES,
        A.DSS_LOAD_DATE,
        A.DSS_RECORD_SOURCE,
        ---- loan status , sub status and company values
        JSON_VALUES:loanStatusId:newValue::int AS new_loan_status,
        JSON_VALUES:loanSubStatusId:newValue::int AS new_loan_sub_status,
        JSON_VALUES:sourceCompany:newValue::int AS new_source_company,
        --- sub old values for above 3
        JSON_VALUES:loanStatusId:oldValue::int AS old_loan_status,
        JSON_VALUES:loanSubStatusId:oldValue::int AS old_loan_sub_status,
        JSON_VALUES:sourceCompany:oldValue::int AS old_source_company,

        -- loan_status , sub status string values for join condition filters
        JSON_VALUES:loanStatusId::STRING AS loan_status_string,
        JSON_VALUES:loanSubStatusId::STRING AS loan_sub_status_string,
        JSON_VALUES:sourceCompany::STRING AS source_company_string,

        --portfolios new value
        trim(replace(object_keys(JSON_VALUES:"PortfoliosAdded":"newValue")[0],'"',''))::string as new_portfolio_added,
        trim(replace(object_keys(JSON_VALUES:"PortfoliosRemoved":"newValue")[0],'"',''))::string as new_portfolio_removed,

        --portfolios old value
        trim(replace(object_keys(JSON_VALUES:"PortfoliosAdded":"oldValue")[0],'"',''))::string as old_portfolio_added,
        trim(replace(object_keys(JSON_VALUES:"PortfoliosRemoved":"oldValue")[0],'"',''))::string as old_portfolio_removed,

        -- others new values
        JSON_VALUES:customFieldValue:newValue::STRING AS new_custom_field_value,
        JSON_VALUES:CustomFieldValues:newValue::STRING AS new_custom_field_values,
        JSON_VALUES:applyDefaultFieldMap:newValue::STRING AS new_apply_default_field_map,
        JSON_VALUES:agent:newValue::STRING AS new_agent,
        JSON_VALUES:followUpDate:newValue::STRING AS new_follow_up_date,
        JSON_VALUES:eBilling:newValue::STRING AS new_e_billing,
        JSON_VALUES:creditBureau:newValue::STRING AS new_credit_bureau,
        JSON_VALUES:autopayEnabled:newValue::STRING AS new_autopay_enabled,
        JSON_VALUES:title::STRING AS new_title,

        -- others old values
        JSON_VALUES:customFieldValue:oldValue::STRING AS old_custom_field_value,
        JSON_VALUES:CustomFieldValues:oldValue::STRING AS old_custom_field_values,
        JSON_VALUES:applyDefaultFieldMap:oldValue::STRING AS old_apply_default_field_map,
        JSON_VALUES:agent:oldValue::STRING AS old_agent,
        JSON_VALUES:followUpDate:oldValue::STRING AS old_follow_up_date,
        JSON_VALUES:eBilling:oldValue::STRING AS old_e_billing,
        JSON_VALUES:creditBureau:oldValue::STRING AS old_credit_bureau,
        JSON_VALUES:autopayEnabled:oldValue::STRING AS old_autopay_enabled,
        JSON_VALUES:title::STRING AS old_title

    FROM RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY A
    WHERE A.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
      AND A.REFERENCE_TYPE IN ('Entity.LoanSettings')
      --and entity_id = 2631487
)
,sub_status_entity AS (
    SELECT DISTINCT ID, TITLE
    FROM RAW_DATA_STORE.LOANPRO.LOAN_SUB_STATUS_ENTITY
    WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA() AND DELETED = 0
)
/*,status_entity AS (
    SELECT DISTINCT ID, TITLE
    FROM RAW_DATA_STORE.LOANPRO.LOAN_STATUS_ENTITY
    WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA() AND DELETED = 0
)*/
,source_company AS (
    SELECT DISTINCT ID, COMPANY_NAME
    FROM RAW_DATA_STORE.LOANPRO.SOURCE_COMPANY_ENTITY
    WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA() AND DELETED = 0
)
,portfolio_entity as (
    SELECT DISTINCT A.ID::STRING AS ID,
                    A.TITLE,
                    B.TITLE AS PORTFOLIO_CATEGORY
    FROM ARCA.FRESHSNOW.PORTFOLIO_ENTITY_CURRENT A
    LEFT JOIN ARCA.FRESHSNOW.PORTFOLIO_CATEGORY_ENTITY_CURRENT B
    ON A.CATEGORY_ID = B.ID AND B.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE A.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA())
-- Handle both the loan status and loan sub status values
,loan_stat_and_sub_stat_data as (
select dat.*
       --ADDING IN THIS CRITERIA FOR THE LOANS THAT ARE NEWLY CREATED
     ,case when dat.NOTE_TITLE = 'Loan settings were created'
           then sub_stat_creation.title
        --BELOW IS THE ORIGINAL CODE
           when dat.NOTE_TITLE_DETAIL = 'Loan Status - Loan Sub Status' and new_sub_stat.title is not null
           then new_sub_stat.title
           /*when dat.NOTE_TITLE_DETAIL = 'Loan Status - Loan Sub Status'
           then new_stat.title*/
           else new_sub_stat.title end as newvalue_extracted
     ,case when dat.NOTE_TITLE_DETAIL = 'Loan Status - Loan Sub Status' and old_sub_stat.title is not null
           then old_sub_stat.title
           /*when dat.NOTE_TITLE_DETAIL = 'Loan Status - Loan Sub Status'
           then old_stat.title*/
           else old_sub_stat.title end as oldvalue_extracted
from initial_pull dat
/*left join status_entity new_stat
    on dat.new_loan_status = new_stat.ID --AND new_loan_status IS NOT NULL
left join status_entity old_stat
    on dat.old_loan_status  = old_stat.ID --AND old_loan_status IS NOT NULL*/
left join sub_status_entity new_sub_stat
    on new_loan_sub_status  = new_sub_stat.ID --AND new_loan_sub_status IS NOT NULL
left join sub_status_entity old_sub_stat
    on old_loan_sub_status  = old_sub_stat.ID --AND old_loan_sub_status IS NOT NULL
-- ADDED IN NEW JOINS FOR THE CREATION OF THE LOAN
left join sub_status_entity sub_stat_creation
    on dat.NOTE_TITLE = 'Loan settings were created' AND dat.loan_sub_status_string = sub_stat_creation.ID::STRING
/*left join status_entity stat_creation
    on dat.NOTE_TITLE = 'Loan settings were created' AND dat.loan_status_string = stat_creation.ID::STRING*/
where 1 = 1
-- and oldvalue <> '[]'
and dat.NOTE_TITLE_DETAIL in ('Loan Status - Loan Sub Status', 'Loan Sub Status'))
,sc_data as (
select dat.*
      ,new_sc.company_name as newvalue_extracted
      ,old_sc.company_name as oldvalue_extracted
from initial_pull dat
left join source_company new_sc
    on new_source_company  = new_sc.id --::STRING AND new_source_company IS NOT NULL
left join source_company old_sc
    on old_source_company  = old_sc.id --::STRING AND old_source_company IS NOT NULL
where 1 = 1
    and dat.NOTE_TITLE_DETAIL = 'Source Company'
)
,portfolio_data as (
select dat.ID, ENTITY_ID, NOTE_TITLE, json_values,
       dat.NOTE_TITLE_DETAIL||' - '||COALESCE(new_port_add.PORTFOLIO_CATEGORY,
new_port_rem.PORTFOLIO_CATEGORY,old_port_add.PORTFOLIO_CATEGORY,old_port_rem.PORTFOLIO_CATEGORY) AS NOTE_TITLE_DETAIL,
       REFERENCE_TYPE, OPERATION_TYPE, OPERATION_SUB_TYPE, ROW_EVENT_TYPE, CREATE_USER, CREATE_USER_NAME, CREATED, LASTUPDATED, DELETED, IS_HARD_DELETED, BEFORE_VALUES, DSS_LOAD_DATE, DSS_RECORD_SOURCE, new_loan_status, new_loan_sub_status, new_source_company, old_loan_status, old_loan_sub_status, old_source_company, loan_status_string, loan_sub_status_string, source_company_string, new_portfolio_added, new_portfolio_removed, old_portfolio_added, old_portfolio_removed, new_custom_field_value, new_custom_field_values, new_apply_default_field_map, new_agent, new_follow_up_date, new_e_billing, new_credit_bureau, new_autopay_enabled, new_title, old_custom_field_value, old_custom_field_values, old_apply_default_field_map, old_agent, old_follow_up_date, old_e_billing, old_credit_bureau, old_autopay_enabled, old_title
      ,case when dat.NOTE_TITLE_DETAIL = 'Portfolios Added'
          then new_port_add.TITLE
          when dat.NOTE_TITLE_DETAIL = 'Portfolios Removed'
          then new_port_rem.TITLE
          end as newvalue_extracted
      ,case when dat.NOTE_TITLE_DETAIL = 'Portfolios Added'
          then old_port_add.TITLE
          when dat.NOTE_TITLE_DETAIL = 'Portfolios Removed'
          then old_port_rem.TITLE
          end as oldvalue_extracted
from initial_pull dat
left join portfolio_entity new_port_add
    on new_portfolio_added = new_port_add.id
left join portfolio_entity new_port_rem
    on new_portfolio_removed = new_port_rem.id
left join portfolio_entity old_port_rem
    on old_portfolio_removed = old_port_rem.id
left join portfolio_entity old_port_add
    on old_portfolio_added = old_port_add.id
where 1 = 1
    and dat.NOTE_TITLE_DETAIL IN ('Portfolios Added','Portfolios Removed'))
,others as (
select  dat.*
       ,NULLIF(COALESCE(
                      new_custom_field_value
                    , new_custom_field_values
                    , new_apply_default_field_map
                    , new_agent
                    , new_follow_up_date
                    , new_e_billing
                    , new_credit_bureau
                    , new_autopay_enabled
                    , new_title
                    ), '[]'
                    )::STRING as newvalue_extracted
        ,NULLIF(COALESCE(
                      old_custom_field_value
                    , old_custom_field_values
                    , old_apply_default_field_map
                    , old_agent
                    , old_follow_up_date
                    , old_e_billing
                    , old_credit_bureau
                    , old_autopay_enabled
                    , old_title
                        ), '[]'
                    )::STRING as oldvalue_extracted
from initial_pull dat
where 1 = 1
and coalesce(dat.NOTE_TITLE_DETAIL,'c') not in ('Loan Status - Loan Sub Status', 'Loan Sub Status','Source Company','Portfolios Added','Portfolios Removed')
--not including loan settings created
AND dat.NOTE_TITLE NOT IN ('Loan settings were created')
)
,final as (
select '1' A, *
from loan_stat_and_sub_stat_data
-- where oldvalue <> '[]'
union all
select '2', *
from sc_data
-- where oldvalue <> '[]'
union all
select '3', *
from others
-- where oldvalue <> '[]'
union all
select '4', *
from portfolio_data
)
,custom_field_labels as (
SELECT CUSTOM_FIELD_NAME, CUSTOM_FIELD_VALUE_ID, CUSTOM_FIELD_VALUE_LABEL
FROM ARCA.FRESHSNOW.VW_CUSTOM_FIELD_LABELS
WHERE SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA())
select ID,
    ENTITY_ID AS APPLICATION_ID,
    NOTE_TITLE,
    JSON_VALUES AS NOTE_DATA,
    REFERENCE_TYPE,
    OPERATION_TYPE,
    OPERATION_SUB_TYPE,
    ROW_EVENT_TYPE,
    CREATE_USER,
    CREATE_USER_NAME,
    convert_timezone('UTC','America/Los_Angeles',CREATED) AS CREATED,
    convert_timezone('UTC','America/Los_Angeles',LASTUPDATED) AS LASTUPDATED,
    DELETED,
    IS_HARD_DELETED,
    BEFORE_VALUES,
    CASE WHEN NOTE_TITLE_DETAIL = 'tier'
        THEN IFF(left(a.newvalue_extracted, 1) = 't', right(a.newvalue_extracted, 1), a.newvalue_extracted)
        --MANY BLANK VALUES THAT ARE NULLED OUT HERE
    ELSE NULLIF(TRIM(a.newvalue_extracted),'') END AS NEWVALUE,
    COALESCE(b.CUSTOM_FIELD_VALUE_LABEL,NEWVALUE) AS NEWVALUE_LABEL,
    CASE WHEN NOTE_TITLE_DETAIL = 'tier'
        THEN IFF(left(a.oldvalue_extracted, 1) = 't', right(a.oldvalue_extracted, 1), a.oldvalue_extracted)
    ELSE NULLIF(TRIM(a.oldvalue_extracted),'') END as OLDVALUE,
    --MANY BLANK VALUES THAT ARE NULLED OUT HERE
    COALESCE(c.CUSTOM_FIELD_VALUE_LABEL,OLDVALUE) AS OLDVALUE_LABEL,
    NOTE_TITLE_DETAIL
from final a
left join custom_field_labels b
on a.NOTE_TITLE_DETAIL = b.CUSTOM_FIELD_NAME
and a.newvalue_extracted = b.CUSTOM_FIELD_VALUE_ID
left join custom_field_labels c
on a.NOTE_TITLE_DETAIL = c.CUSTOM_FIELD_NAME
and a.oldvalue_extracted = c.CUSTOM_FIELD_VALUE_ID
WHERE 1=1
ORDER BY a.ID DESC;