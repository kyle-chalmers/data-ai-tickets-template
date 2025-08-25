-- Original DDL for BUSINESS_INTELLIGENCE.CRON_STORE.LOANPRO_APP_SYSTEM_NOTES procedure
-- Retrieved: 2025-01-22

CREATE OR REPLACE PROCEDURE "LOANPRO_APP_SYSTEM_NOTES"()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN

delete from business_intelligence.cron_store.system_note_entity where created_ts::date >= (select max(created_ts::date) as max_dt from business_intelligence.cron_store.system_note_entity);

create or replace table business_intelligence.cron_store.loanpro_system_note as 
select 
entity_id as app_id
,convert_timezone(''UTC'',''America/Los_Angeles'',created) as created_ts
,convert_timezone(''UTC'',''America/Los_Angeles'',lastupdated) as lastupdated_ts
,case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanStatusId""::STRING 
        else parse_json(note_data):""loanStatusId"":""newValue""::STRING 
        end as loan_status_new_id
,case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanStatusId""::STRING 
        else parse_json(note_data):""loanStatusId"":""oldValue""::STRING 
        end as loan_status_old_id
,case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanSubStatusId""::STRING 
        when parse_json(note_data):""loanSubStatusId""::STRING is not null then parse_json(note_data):""loanSubStatusId"":""newValue""::STRING
        when parse_json(note_data):""agent""::STRING is not null then parse_json(note_data):""agent"":""newValue""::string
        when parse_json(note_data):""sourceCompany""::STRING is not null then parse_json(note_data):""sourceCompany"":""newValue""::string
        when parse_json(note_data):""PortfoliosAdded""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosAdded"":""newValue"")[0],''""'',''''))::string
        when parse_json(note_data):""PortfoliosRemoved""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosRemoved"":""newValue"")[0],''""'',''''))::string
        when note_data like ''%applyDefaultFieldMap%'' then parse_json(note_data):""applyDefaultFieldMap"":""newValue""::STRING 
        else parse_json(note_data):""customFieldValue"":""newValue""::STRING 
        end as note_new_value
,case when note_title = ''Loan settings were created'' then parse_json(note_data):""loanSubStatusId""::STRING 
        when parse_json(note_data):""loanSubStatusId""::STRING is not null then parse_json(note_data):""loanSubStatusId"":""oldValue""::STRING
        when parse_json(note_data):""agent""::STRING is not null then parse_json(note_data):""agent"":""oldValue""::string
        when parse_json(note_data):""sourceCompany""::STRING is not null then parse_json(note_data):""sourceCompany"":""oldValue""::string
        when parse_json(note_data):""PortfoliosAdded""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosAdded"":""oldValue"")[0],''""'',''''))::string
        when parse_json(note_data):""PortfoliosRemoved""::STRING is not null then trim(replace(object_keys(parse_json(note_data):""PortfoliosRemoved"":""oldValue"")[0],''""'',''''))::string
        when note_data like ''%applyDefaultFieldMap%'' then parse_json(note_data):""applyDefaultFieldMap"":""oldValue""::STRING 
        else parse_json(note_data):""customFieldValue"":""oldValue""::STRING     
        end as note_old_value
,case when REGEXP_SUBSTR(note_title, ''\\\\((.*?)\\\\)'', 1, 1, ''e'', 1) is null then 
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
      end as note_title_detail
,note_title
,note_data
,deleted
,is_hard_deleted
from raw_data_store.loanpro.system_note_entity
where schema_name = CONFIG.LOS_SCHEMA()                         --value = 5203309_P                                                                
    and reference_type in (''Entity.LoanSettings'') 
    and convert_timezone(''UTC'',''America/Los_Angeles'',created) > (select max(created_ts) as max_dt from business_intelligence.cron_store.system_note_entity)

;


insert into business_intelligence.cron_store.system_note_entity 
select
a.app_id
,a.created_ts
,a.lastupdated_ts
,d.loan_status as loan_status_new
,e.loan_status as loan_status_old
,d.deleted_status as deleted_loan_status_new
,e.deleted_status as deleted_loan_status_old

,case when a.note_new_value in (''[]'','''',''null'') then null 
        when a.note_title_detail like ''%Loan Sub Status%'' then b.loan_sub_status
        when a.note_title_detail = ''Source Company'' then f.company_name
        when a.note_title_detail = ''tier'' then 
                case when left(a.note_new_value,1) = ''t'' then right(a.note_new_value,1) else a.note_new_value end 
        when a.note_title_detail = ''Offer Decision Status'' then 
                case when a.note_new_value = ''1'' then ''Approve''
                     when a.note_new_value = ''2'' then ''Decline''
                     when a.note_new_value = ''3'' then ''Retry System Failure''
                     when a.note_new_value = ''4'' then ''Credit Freeze''
                     when a.note_new_value = ''5'' then ''Conditional Approval''
                     end
        when a.note_title_detail in (''Portfolios Added'',''Portfolios Removed'') then g.portfolio_title
        else a.note_new_value end as note_new_value
        
,case when a.note_old_value in (''[]'',''''''null'') then null 
        when a.note_title = ''Loan settings were created'' then null
        when a.note_old_value = ''Expired'' then null
        when a.note_title_detail like ''%Loan Sub Status%'' then c.loan_sub_status
        when a.note_title_detail = ''Source Company'' then f.company_name
        when a.note_title_detail = ''tier'' then 
                case when left(a.note_old_value,1) = ''t'' then right(a.note_old_value,1) else a.note_old_value end
        else a.note_old_value end as note_old_value
        
,b.deleted_sub_status as deleted_sub_status_new
,b.deleted_sub_status as deleted_sub_status_old
,case when a.note_title_detail in (''Portfolios Added'',''Portfolios Removed'') then a.note_title_detail||'' - ''||g.portfolio_category else a.note_title_detail end as note_title_detail
,a.note_title
,a.note_data
,a.deleted
,a.is_hard_deleted
from business_intelligence.cron_store.loanpro_system_note a
left join             
            (select distinct --#137 is a straight dupe
            title as loan_sub_status 
            ,id::varchar(10) as id
            ,deleted as deleted_sub_status
            from raw_data_store.loanpro.loan_sub_status_entity
            where schema_name = CONFIG.LOS_SCHEMA()
            ) b
on a.note_new_value = b.id
and a.note_title_detail like ''%Loan Sub Status%''

left join             
            (select distinct --#137 is a straight dupe
            title as loan_sub_status 
            ,id::varchar(10) as id
            ,deleted as deleted_sub_status
            from raw_data_store.loanpro.loan_sub_status_entity
            where schema_name = CONFIG.LOS_SCHEMA()
            ) c
on a.note_old_value = c.id
and a.note_title_detail like ''%Loan Sub Status%''

left join
            (select distinct 
            title as loan_status
            ,id::varchar(10) as id
            ,deleted as deleted_status
            from raw_data_store.loanpro.loan_status_entity 
            where schema_name = CONFIG.LOS_SCHEMA()
            --AND DELETED = 0
            ) d 
on a.loan_status_new_id = d.id
and a.note_title_detail = ''Loan Status - Loan Sub Status''

left join
            (select distinct 
            title as loan_status
            ,id::varchar(10) as id
            ,deleted as deleted_status
            from raw_data_store.loanpro.loan_status_entity 
            where schema_name = CONFIG.LOS_SCHEMA()
            --AND DELETED = 0
            ) e 
on a.loan_status_new_id = e.id
and a.note_title_detail = ''Loan Status - Loan Sub Status''

left join
            (select distinct 
            company_name
            ,id::varchar(10) as id
            ,deleted as deleted_company
            from raw_data_store.loanpro.source_company_entity
            where schema_name = CONFIG.LOS_SCHEMA()
            --AND DELETED = 0
            ) f
on a.note_new_value = f.id
and a.note_title_detail = ''Source Company''

left join 
            (select 
            a.id as portfolio_id
            ,trim(a.title)::varchar(255) as portfolio_title
            ,trim(b.title)::varchar(255) as portfolio_category
            from business_intelligence.bridge.vw_portfolio_entity_current a
            left join business_intelligence.bridge.vw_portfolio_category_entity_current b
            on a.category_id = b.id
                           and b.schema_name = ''5203309_P''
            where a.schema_name = ''5203309_P'' 
            ) g
on try_to_number(a.note_new_value) = g.portfolio_id
and a.note_title_detail in (''Portfolios Added'',''Portfolios Removed'')

;


RETURN ''Procedure Executed Successfully.'';
END;