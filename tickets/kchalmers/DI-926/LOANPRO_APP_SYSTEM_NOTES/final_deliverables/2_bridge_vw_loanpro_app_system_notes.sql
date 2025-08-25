-- BRIDGE Layer View: LoanPro Application System Notes with Lookups
-- Purpose: Add reference table lookups to provide human-readable values

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES AS
SELECT
    a.app_id,
    a.created_ts,
    a.lastupdated_ts,
    
    -- Loan status lookups with human-readable text
    d.loan_status as loan_status_new,
    e.loan_status as loan_status_old,
    d.deleted_status as deleted_loan_status_new,
    e.deleted_status as deleted_loan_status_old,

    -- Enhanced new values with reference table lookups
    case when a.note_new_value_raw in ('[]','','null') then null 
         when a.note_category like '%Loan Sub Status%' then b.loan_sub_status
         when a.note_category = 'Source Company' then f.company_name
         when a.note_category = 'tier' then 
                 case when left(a.note_new_value_raw,1) = 't' then right(a.note_new_value_raw,1) else a.note_new_value_raw end 
         when a.note_category = 'Offer Decision Status' then 
                 case when a.note_new_value_raw = '1' then 'Approve'
                      when a.note_new_value_raw = '2' then 'Decline'
                      when a.note_new_value_raw = '3' then 'Retry System Failure'
                      when a.note_new_value_raw = '4' then 'Credit Freeze'
                      when a.note_new_value_raw = '5' then 'Conditional Approval'
                      end
         when a.note_category in ('Portfolios Added','Portfolios Removed') then g.portfolio_title
         else a.note_new_value_raw end as note_new_value,
         
    -- Enhanced old values with reference table lookups
    case when a.note_old_value_raw in ('[]','','null') then null 
         when a.note_title = 'Loan settings were created' then null
         when a.note_old_value_raw = 'Expired' then null
         when a.note_category like '%Loan Sub Status%' then c.loan_sub_status
         when a.note_category = 'Source Company' then f.company_name
         when a.note_category = 'tier' then 
                 case when left(a.note_old_value_raw,1) = 't' then right(a.note_old_value_raw,1) else a.note_old_value_raw end
         else a.note_old_value_raw end as note_old_value,
         
    -- Sub-status deletion flags
    b.deleted_sub_status as deleted_sub_status_new,
    c.deleted_sub_status as deleted_sub_status_old,
    
    -- Enhanced category with portfolio information
    case when a.note_category in ('Portfolios Added','Portfolios Removed') 
         then a.note_category||' - '||g.portfolio_category 
         else a.note_category end as note_category_detail,
         
    a.note_title,
    a.note_data,
    a.deleted,
    a.is_hard_deleted,
    
    -- Raw values for debugging/validation
    a.note_new_value_raw,
    a.note_old_value_raw,
    a.loan_status_new_id,
    a.loan_status_old_id

FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES a

-- Loan Sub Status lookups (new values)
LEFT JOIN (
    select distinct 
        title as loan_sub_status,
        id::varchar(10) as id,
        deleted as deleted_sub_status
    from raw_data_store.loanpro.loan_sub_status_entity
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) b ON a.note_new_value_raw = b.id
   AND a.note_category like '%Loan Sub Status%'

-- Loan Sub Status lookups (old values)  
LEFT JOIN (
    select distinct 
        title as loan_sub_status,
        id::varchar(10) as id,
        deleted as deleted_sub_status
    from raw_data_store.loanpro.loan_sub_status_entity
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) c ON a.note_old_value_raw = c.id
   AND a.note_category like '%Loan Sub Status%'

-- Loan Status lookups (new values)
LEFT JOIN (
    select distinct 
        title as loan_status,
        id::varchar(10) as id,
        deleted as deleted_status
    from raw_data_store.loanpro.loan_status_entity 
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) d ON a.loan_status_new_id = d.id
   AND a.note_category = 'Loan Status - Loan Sub Status'

-- Loan Status lookups (old values)
LEFT JOIN (
    select distinct 
        title as loan_status,
        id::varchar(10) as id,
        deleted as deleted_status
    from raw_data_store.loanpro.loan_status_entity 
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) e ON a.loan_status_old_id = e.id
   AND a.note_category = 'Loan Status - Loan Sub Status'

-- Source Company lookups
LEFT JOIN (
    select distinct 
        company_name,
        id::varchar(10) as id,
        deleted as deleted_company
    from raw_data_store.loanpro.source_company_entity
    where schema_name = ARCA.CONFIG.LOS_SCHEMA()
) f ON a.note_new_value_raw = f.id
   AND a.note_category = 'Source Company'

-- Portfolio lookups with category information
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
) g ON try_to_number(a.note_new_value_raw) = g.portfolio_id
   AND a.note_category in ('Portfolios Added','Portfolios Removed');