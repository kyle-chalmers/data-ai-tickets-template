-- ANALYTICS Layer View: LoanPro Application System Notes - Business Ready
-- Purpose: Business-ready data optimized for reporting and analysis

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES AS
SELECT
    app_id,
    created_ts,
    created_ts::date as created_date,
    lastupdated_ts,
    
    -- Loan status information
    loan_status_new,
    loan_status_old,
    case when loan_status_new != loan_status_old then 1 else 0 end as loan_status_changed_flag,
    
    -- Note change information
    note_new_value,
    note_old_value,
    case when note_new_value is not null and note_old_value is not null 
         and note_new_value != note_old_value then 1 else 0 end as value_changed_flag,
    
    -- Categorization for business analysis
    note_category_detail,
    case when note_category_detail like '%Status%' then 'Status Change'
         when note_category_detail like '%Portfolio%' then 'Portfolio Management'
         when note_category_detail = 'Agent' then 'Agent Assignment'
         when note_category_detail = 'Source Company' then 'Source Management'
         else 'Other' end as change_type_category,
    
    -- Time-based fields for analysis
    EXTRACT(HOUR FROM created_ts) as created_hour,
    EXTRACT(DAYOFWEEK FROM created_ts) as created_day_of_week,
    DATE_TRUNC('week', created_ts::date) as created_week,
    DATE_TRUNC('month', created_ts::date) as created_month,
    
    -- Flags for common business queries
    case when note_category_detail like '%Loan Sub Status%' then 1 else 0 end as is_sub_status_change,
    case when note_category_detail like '%Portfolio%' then 1 else 0 end as is_portfolio_change,
    case when note_category_detail = 'Agent' then 1 else 0 end as is_agent_change,
    case when note_category_detail = 'Source Company' then 1 else 0 end as is_source_company_change,
    
    -- Original fields for detailed analysis
    note_title,
    deleted,
    is_hard_deleted,
    
    -- Raw IDs for joins with other tables
    loan_status_new_id,
    loan_status_old_id
    
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE deleted = 0 
    AND is_hard_deleted = FALSE;