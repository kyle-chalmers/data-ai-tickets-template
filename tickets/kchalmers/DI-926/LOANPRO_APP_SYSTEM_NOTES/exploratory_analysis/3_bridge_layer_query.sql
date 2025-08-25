-- BRIDGE Layer: System note data with lookup enrichments
-- Adds reference table lookups for human-readable values

WITH freshsnow_data AS (
    SELECT 
        entity_id as app_id,
        convert_timezone('UTC','America/Los_Angeles',created) as created_ts,
        convert_timezone('UTC','America/Los_Angeles',lastupdated) as lastupdated_ts,
        
        -- Loan Status ID extraction
        case when note_title = 'Loan settings were created' then parse_json(note_data):"loanStatusId"::STRING 
             else parse_json(note_data):"loanStatusId":"newValue"::STRING 
             end as loan_status_new_id,
        case when note_title = 'Loan settings were created' then parse_json(note_data):"loanStatusId"::STRING 
             else parse_json(note_data):"loanStatusId":"oldValue"::STRING 
             end as loan_status_old_id,
             
        -- New Value extraction (complex nested JSON parsing)
        case when note_title = 'Loan settings were created' then parse_json(note_data):"loanSubStatusId"::STRING 
             when parse_json(note_data):"loanSubStatusId"::STRING is not null then parse_json(note_data):"loanSubStatusId":"newValue"::STRING
             when parse_json(note_data):"agent"::STRING is not null then parse_json(note_data):"agent":"newValue"::string
             when parse_json(note_data):"sourceCompany"::STRING is not null then parse_json(note_data):"sourceCompany":"newValue"::string
             when parse_json(note_data):"PortfoliosAdded"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosAdded":"newValue")[0],'"',''))::string
             when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosRemoved":"newValue")[0],'"',''))::string
             when note_data like '%applyDefaultFieldMap%' then parse_json(note_data):"applyDefaultFieldMap":"newValue"::STRING 
             else parse_json(note_data):"customFieldValue":"newValue"::STRING 
             end as note_new_value,
             
        -- Old Value extraction (complex nested JSON parsing)
        case when note_title = 'Loan settings were created' then parse_json(note_data):"loanSubStatusId"::STRING 
             when parse_json(note_data):"loanSubStatusId"::STRING is not null then parse_json(note_data):"loanSubStatusId":"oldValue"::STRING
             when parse_json(note_data):"agent"::STRING is not null then parse_json(note_data):"agent":"oldValue"::string
             when parse_json(note_data):"sourceCompany"::STRING is not null then parse_json(note_data):"sourceCompany":"oldValue"::string
             when parse_json(note_data):"PortfoliosAdded"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosAdded":"oldValue")[0],'"',''))::string
             when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosRemoved":"oldValue")[0],'"',''))::string
             when note_data like '%applyDefaultFieldMap%' then parse_json(note_data):"applyDefaultFieldMap":"oldValue"::STRING 
             else parse_json(note_data):"customFieldValue":"oldValue"::STRING     
             end as note_old_value,
             
        -- Note title categorization
        case when REGEXP_SUBSTR(note_title, '\\((.*?)\\)', 1, 1, 'e', 1) is null then 
                  case when TRY_PARSE_JSON(note_data) is null then null								
                      else 
                          case when parse_json(note_data):"loanStatusId"::STRING is not null then 'Loan Status - Loan Sub Status'
                               when parse_json(note_data):"loanSubStatusId"::STRING is not null then 'Loan Sub Status'
                               when parse_json(note_data):"sourceCompany"::STRING is not null then 'Source Company'
                               when parse_json(note_data):"agent"::STRING is not null then 'Agent'
                               when parse_json(note_data):"PortfoliosAdded"::STRING is not null then 'Portfolios Added'
                               when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then 'Portfolios Removed'
                               when parse_json(note_data):"applyDefaultFieldMap"::STRING is not null then 'Apply Default Field Map'
                               when parse_json(note_data):"followUpDate"::STRING is not null then 'FollowUp Date'
                               when parse_json(note_data):"eBilling"::STRING is not null then 'eBilling'
                               when parse_json(note_data):"creditBureau"::STRING is not null then 'Credit Bureau'
                               when parse_json(note_data):"autopayEnabled"::STRING is not null then 'Autopay Enabled'
                          end
                  end
            else REGEXP_SUBSTR(NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1)  
            end as note_title_detail,
            
        note_title,
        note_data,
        deleted,
        is_hard_deleted
        
    FROM raw_data_store.loanpro.system_note_entity
    WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA()  -- LoanPro application schema filter                                                           
        AND reference_type IN ('Entity.LoanSettings') 
        AND deleted = 0  -- Only active records
        AND is_hard_deleted = FALSE
)

SELECT
    a.app_id,
    a.created_ts,
    a.lastupdated_ts,
    
    -- Loan status lookups
    d.loan_status as loan_status_new,
    e.loan_status as loan_status_old,
    d.deleted_status as deleted_loan_status_new,
    e.deleted_status as deleted_loan_status_old,

    -- Processed new values with lookups
    case when a.note_new_value in ('[]','','null') then null 
         when a.note_title_detail like '%Loan Sub Status%' then b.loan_sub_status
         when a.note_title_detail = 'Source Company' then f.company_name
         when a.note_title_detail = 'tier' then 
                 case when left(a.note_new_value,1) = 't' then right(a.note_new_value,1) else a.note_new_value end 
         when a.note_title_detail = 'Offer Decision Status' then 
                 case when a.note_new_value = '1' then 'Approve'
                      when a.note_new_value = '2' then 'Decline'
                      when a.note_new_value = '3' then 'Retry System Failure'
                      when a.note_new_value = '4' then 'Credit Freeze'
                      when a.note_new_value = '5' then 'Conditional Approval'
                      end
         when a.note_title_detail in ('Portfolios Added','Portfolios Removed') then g.portfolio_title
         else a.note_new_value end as note_new_value,
         
    -- Processed old values with lookups
    case when a.note_old_value in ('[]','','null') then null 
         when a.note_title = 'Loan settings were created' then null
         when a.note_old_value = 'Expired' then null
         when a.note_title_detail like '%Loan Sub Status%' then c.loan_sub_status
         when a.note_title_detail = 'Source Company' then f.company_name
         when a.note_title_detail = 'tier' then 
                 case when left(a.note_old_value,1) = 't' then right(a.note_old_value,1) else a.note_old_value end
         else a.note_old_value end as note_old_value,
         
    b.deleted_sub_status as deleted_sub_status_new,
    c.deleted_sub_status as deleted_sub_status_old,
    
    -- Enhanced note title with portfolio category
    case when a.note_title_detail in ('Portfolios Added','Portfolios Removed') 
         then a.note_title_detail||' - '||g.portfolio_category 
         else a.note_title_detail end as note_title_detail,
         
    a.note_title,
    a.note_data,
    a.deleted,
    a.is_hard_deleted

FROM freshsnow_data a

-- Loan Sub Status lookups (new values)
LEFT JOIN (
    select distinct 
        title as loan_sub_status,
        id::varchar(10) as id,
        deleted as deleted_sub_status
    from raw_data_store.loanpro.loan_sub_status_entity
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) b ON a.note_new_value = b.id
   AND a.note_title_detail like '%Loan Sub Status%'

-- Loan Sub Status lookups (old values)  
LEFT JOIN (
    select distinct 
        title as loan_sub_status,
        id::varchar(10) as id,
        deleted as deleted_sub_status
    from raw_data_store.loanpro.loan_sub_status_entity
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) c ON a.note_old_value = c.id
   AND a.note_title_detail like '%Loan Sub Status%'

-- Loan Status lookups (new values)
LEFT JOIN (
    select distinct 
        title as loan_status,
        id::varchar(10) as id,
        deleted as deleted_status
    from raw_data_store.loanpro.loan_status_entity 
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) d ON a.loan_status_new_id = d.id
   AND a.note_title_detail = 'Loan Status - Loan Sub Status'

-- Loan Status lookups (old values)
LEFT JOIN (
    select distinct 
        title as loan_status,
        id::varchar(10) as id,
        deleted as deleted_status
    from raw_data_store.loanpro.loan_status_entity 
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) e ON a.loan_status_old_id = e.id
   AND a.note_title_detail = 'Loan Status - Loan Sub Status'

-- Source Company lookups
LEFT JOIN (
    select distinct 
        company_name,
        id::varchar(10) as id,
        deleted as deleted_company
    from raw_data_store.loanpro.source_company_entity
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) f ON a.note_new_value = f.id
   AND a.note_title_detail = 'Source Company'

-- Portfolio lookups
LEFT JOIN (
    select 
        a.id as portfolio_id,
        trim(a.title)::varchar(255) as portfolio_title,
        trim(b.title)::varchar(255) as portfolio_category
    from business_intelligence.bridge.vw_portfolio_entity_current a
    left join business_intelligence.bridge.vw_portfolio_category_entity_current b
      on a.category_id = b.id
      and b.schema_name = '5203309_P'
    where a.schema_name = '5203309_P' 
) g ON try_to_number(a.note_new_value) = g.portfolio_id
   AND a.note_title_detail in ('Portfolios Added','Portfolios Removed')