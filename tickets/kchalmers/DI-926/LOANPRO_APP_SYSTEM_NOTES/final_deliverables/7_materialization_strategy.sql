-- DI-926: Materialization Strategy for LOANPRO_APP_SYSTEM_NOTES
-- Following VW_APP_OFFERS → APP_OFFERS pattern (View → Table materialization)

-- =============================================================================
-- PHASE 1: DEPLOY VIEWS IN 5-LAYER ARCHITECTURE
-- =============================================================================

-- 1A: Deploy FRESHSNOW View (Raw data processing)
CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES AS
SELECT 
    entity_id as app_id,
    convert_timezone('UTC','America/Los_Angeles',created) as created_ts,
    convert_timezone('UTC','America/Los_Angeles',lastupdated) as lastupdated_ts,
    
    -- Loan Status ID extraction for status change tracking
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanStatusId"::STRING 
         else parse_json(note_data):"loanStatusId":"newValue"::STRING 
         end as loan_status_new_id,
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanStatusId"::STRING 
         else parse_json(note_data):"loanStatusId":"oldValue"::STRING 
         end as loan_status_old_id,
         
    -- New Value extraction from nested JSON structures
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanSubStatusId"::STRING 
         when parse_json(note_data):"loanSubStatusId"::STRING is not null then parse_json(note_data):"loanSubStatusId":"newValue"::STRING
         when parse_json(note_data):"agent"::STRING is not null then parse_json(note_data):"agent":"newValue"::string
         when parse_json(note_data):"sourceCompany"::STRING is not null then parse_json(note_data):"sourceCompany":"newValue"::string
         when parse_json(note_data):"PortfoliosAdded"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosAdded":"newValue")[0],'"',''))::string
         when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosRemoved":"newValue")[0],'"',''))::string
         when note_data like '%applyDefaultFieldMap%' then parse_json(note_data):"applyDefaultFieldMap":"newValue"::STRING 
         else parse_json(note_data):"customFieldValue":"newValue"::STRING 
         end as note_new_value_raw,
         
    -- Old Value extraction from nested JSON structures
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanSubStatusId"::STRING 
         when parse_json(note_data):"loanSubStatusId"::STRING is not null then parse_json(note_data):"loanSubStatusId":"oldValue"::STRING
         when parse_json(note_data):"agent"::STRING is not null then parse_json(note_data):"agent":"oldValue"::string
         when parse_json(note_data):"sourceCompany"::STRING is not null then parse_json(note_data):"sourceCompany":"oldValue"::string
         when parse_json(note_data):"PortfoliosAdded"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosAdded":"oldValue")[0],'"',''))::string
         when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosRemoved":"oldValue")[0],'"',''))::string
         when note_data like '%applyDefaultFieldMap%' then parse_json(note_data):"applyDefaultFieldMap":"oldValue"::STRING 
         else parse_json(note_data):"customFieldValue":"oldValue"::STRING     
         end as note_old_value_raw,
         
    -- Categorize note types based on JSON structure
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
        end as note_category,
        
    note_title,
    note_data,
    deleted,
    is_hard_deleted
    
FROM raw_data_store.loanpro.system_note_entity
WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA()  -- LoanPro application schema filter                                                           
    AND reference_type IN ('Entity.LoanSettings') 
    AND deleted = 0  -- Only active records
    AND is_hard_deleted = FALSE;

-- 1B: Deploy BRIDGE View (Reference lookups) - Simplified for materialization
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES AS
SELECT
    app_id,
    created_ts,
    lastupdated_ts,
    loan_status_new_id,
    loan_status_old_id,
    note_new_value_raw,
    note_old_value_raw, 
    note_category,
    note_title,
    note_data,
    deleted,
    is_hard_deleted,
    
    -- Placeholder for future reference lookups
    NULL as loan_status_new,
    NULL as loan_status_old,
    note_new_value_raw as note_new_value,
    note_old_value_raw as note_old_value,
    note_category as note_category_detail
    
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;

-- 1C: Deploy ANALYTICS View (Business ready)
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES AS
SELECT
    app_id,
    created_ts,
    created_ts::date as created_date,
    lastupdated_ts,
    note_new_value,
    note_old_value,
    case when note_new_value is not null and note_old_value is not null 
         and note_new_value != note_old_value then 1 else 0 end as value_changed_flag,
    note_category_detail,
    case when note_category_detail like '%Status%' then 'Status Change'
         when note_category_detail like '%Portfolio%' then 'Portfolio Management'
         when note_category_detail = 'Agent' then 'Agent Assignment'
         when note_category_detail = 'Source Company' then 'Source Management'
         else 'Other' end as change_type_category,
    EXTRACT(HOUR FROM created_ts) as created_hour,
    EXTRACT(DAYOFWEEK FROM created_ts) as created_day_of_week,
    DATE_TRUNC('week', created_ts::date) as created_week,
    DATE_TRUNC('month', created_ts::date) as created_month,
    case when note_category_detail like '%Loan Sub Status%' then 1 else 0 end as is_sub_status_change,
    case when note_category_detail like '%Portfolio%' then 1 else 0 end as is_portfolio_change,
    case when note_category_detail = 'Agent' then 1 else 0 end as is_agent_change,
    case when note_category_detail = 'Source Company' then 1 else 0 end as is_source_company_change,
    note_title,
    deleted,
    is_hard_deleted
    
FROM BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE deleted = 0 
    AND is_hard_deleted = FALSE;

-- =============================================================================
-- PHASE 2: MATERIALIZE FRESHSNOW TABLE (Following VW_APP_OFFERS → APP_OFFERS Pattern)
-- =============================================================================

-- 2A: Create materialized table from view
CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES COPY GRANTS AS
SELECT * FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;

-- 2B: Validate materialized table creation
SELECT 
    'Materialization Success' as status,
    COUNT(*) as total_records,
    COUNT(DISTINCT app_id) as unique_applications,
    MIN(created_ts) as earliest_record,
    MAX(created_ts) as latest_record,
    COUNT(CASE WHEN note_category IS NOT NULL THEN 1 END) as categorized_records
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;

-- 2C: Create indexes for performance
CREATE INDEX IF NOT EXISTS IDX_LOANPRO_APP_SYSTEM_NOTES_APP_ID 
ON DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES(app_id);

CREATE INDEX IF NOT EXISTS IDX_LOANPRO_APP_SYSTEM_NOTES_CREATED_TS 
ON DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES(created_ts);

CREATE INDEX IF NOT EXISTS IDX_LOANPRO_APP_SYSTEM_NOTES_NOTE_CATEGORY 
ON DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES(note_category);

-- =============================================================================
-- PHASE 3: UPDATE BRIDGE/ANALYTICS TO REFERENCE MATERIALIZED TABLE
-- =============================================================================

-- 3A: Update BRIDGE layer to use materialized table instead of view
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES AS
SELECT
    app_id,
    created_ts,
    lastupdated_ts,
    loan_status_new_id,
    loan_status_old_id,
    note_new_value_raw,
    note_old_value_raw, 
    note_category,
    note_title,
    note_data,
    deleted,
    is_hard_deleted,
    
    -- Future enhancement: Add reference lookups here
    NULL as loan_status_new,
    NULL as loan_status_old,
    note_new_value_raw as note_new_value,
    note_old_value_raw as note_old_value,
    note_category as note_category_detail
    
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;  -- Now references materialized table

-- 3B: ANALYTICS layer automatically benefits from materialized table performance

-- =============================================================================
-- PHASE 4: REFRESH STRATEGY (REPLACING STORED PROCEDURE SCHEDULE)
-- =============================================================================

-- 4A: Refresh materialized table (replaces stored procedure execution)
-- This can be scheduled via Snowflake tasks or external orchestration
CREATE OR REPLACE TABLE DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES COPY GRANTS AS
SELECT * FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;

-- 4B: Incremental refresh option (for large datasets)
-- Option 1: Replace entire table (simple, consistent)
-- Option 2: Merge incremental changes (complex, efficient for large datasets)

-- Example incremental refresh pattern:
/*
MERGE INTO DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES AS target
USING (
    SELECT * FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES 
    WHERE created_ts >= DATEADD(day, -1, CURRENT_TIMESTAMP())
) AS source
ON target.app_id = source.app_id 
   AND target.created_ts = source.created_ts
   AND target.note_title = source.note_title
WHEN MATCHED THEN UPDATE SET
    lastupdated_ts = source.lastupdated_ts,
    deleted = source.deleted,
    is_hard_deleted = source.is_hard_deleted
WHEN NOT MATCHED THEN INSERT
    (app_id, created_ts, lastupdated_ts, loan_status_new_id, loan_status_old_id, 
     note_new_value_raw, note_old_value_raw, note_category, note_title, note_data, 
     deleted, is_hard_deleted)
VALUES 
    (source.app_id, source.created_ts, source.lastupdated_ts, source.loan_status_new_id, 
     source.loan_status_old_id, source.note_new_value_raw, source.note_old_value_raw, 
     source.note_category, source.note_title, source.note_data, source.deleted, source.is_hard_deleted);
*/

-- =============================================================================
-- PHASE 5: VALIDATION AND MONITORING
-- =============================================================================

-- 5A: Validate refresh success
SELECT 
    'Refresh Validation' as check_type,
    COUNT(*) as current_records,
    MAX(created_ts) as latest_record_timestamp,
    DATEDIFF('minute', MAX(created_ts), CURRENT_TIMESTAMP()) as minutes_behind_source
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;

-- 5B: Compare with source view to ensure consistency
SELECT 
    'Consistency Check' as check_type,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES) as view_records,
    (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES) as table_records,
    ABS((SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES) - 
        (SELECT COUNT(*) FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES)) as record_difference;

-- =============================================================================
-- CLEANUP AND MAINTENANCE
-- =============================================================================

-- Drop the view after materialized table is stable and tested
-- DROP VIEW IF EXISTS DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Monitor table size and performance
SELECT 
    'Table Monitoring' as metric_type,
    COUNT(*) as total_rows,
    ROUND(SUM(LENGTH(note_data))/1024/1024, 2) as data_size_mb,
    COUNT(DISTINCT app_id) as unique_applications,
    COUNT(DISTINCT DATE(created_ts)) as days_of_data
FROM DEVELOPMENT.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES;