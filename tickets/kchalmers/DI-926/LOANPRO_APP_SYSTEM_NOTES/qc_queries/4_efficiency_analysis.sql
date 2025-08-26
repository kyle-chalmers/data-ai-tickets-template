-- DI-926: Efficiency Optimization Analysis
-- Identify ways to improve column creation efficiency without losing data quality

-- =============================================================================
-- 1. JSON PARSING EFFICIENCY ANALYSIS
-- =============================================================================

-- 1A: Count JSON operations per record type
SELECT 
    'JSON Parse Operations Analysis' as analysis_type,
    note_category,
    COUNT(*) as record_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage_of_total,
    -- Estimate current JSON parses per record (our current logic does multiple parses)
    CASE 
        WHEN note_category = 'Loan Status - Loan Sub Status' THEN 8  -- Multiple status checks
        WHEN note_category = 'Loan Sub Status' THEN 6                -- Sub-status checks  
        WHEN note_category = 'Agent' THEN 4                          -- Agent checks
        WHEN note_category = 'Source Company' THEN 4                 -- Company checks
        WHEN note_category = 'Portfolios Added' THEN 6               -- Portfolio checks
        WHEN note_category = 'Portfolios Removed' THEN 6             -- Portfolio checks
        WHEN note_category = 'Apply Default Field Map' THEN 3        -- Field map checks
        ELSE 5                                                       -- Custom field checks
    END as current_parse_operations,
    1 as optimized_parse_operations  -- Single parse with stored result
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= '2025-08-20'
GROUP BY note_category
ORDER BY record_count DESC;

-- 1B: Calculate efficiency gains from single-parse optimization
WITH efficiency_analysis AS (
    SELECT 
        note_category,
        COUNT(*) as record_count,
        CASE 
            WHEN note_category = 'Loan Status - Loan Sub Status' THEN 8
            WHEN note_category = 'Loan Sub Status' THEN 6
            WHEN note_category = 'Agent' THEN 4
            WHEN note_category = 'Source Company' THEN 4
            WHEN note_category = 'Portfolios Added' THEN 6
            WHEN note_category = 'Portfolios Removed' THEN 6
            WHEN note_category = 'Apply Default Field Map' THEN 3
            ELSE 5
        END as current_parses,
        1 as optimized_parses
    FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
    WHERE created_ts >= '2025-08-20'
    GROUP BY note_category
)
SELECT 
    'Efficiency Improvement Summary' as analysis_type,
    SUM(record_count * current_parses) as total_current_parse_operations,
    SUM(record_count * optimized_parses) as total_optimized_parse_operations,
    SUM(record_count * current_parses) - SUM(record_count * optimized_parses) as operations_saved,
    ROUND((SUM(record_count * current_parses) - SUM(record_count * optimized_parses)) * 100.0 / 
          SUM(record_count * current_parses), 2) as efficiency_improvement_pct
FROM efficiency_analysis;

-- =============================================================================
-- 2. PROPOSED OPTIMIZATION: SINGLE JSON PARSE WITH CTE
-- =============================================================================

-- 2A: Optimized view design (sample implementation)
WITH optimized_sample AS (
    SELECT 
        id as record_id,
        entity_id as app_id,
        convert_timezone('UTC','America/Los_Angeles',created) as created_ts,
        note_title,
        note_data,
        deleted,
        is_hard_deleted,
        -- Single JSON parse stored in CTE
        TRY_PARSE_JSON(note_data) as parsed_json
    FROM raw_data_store.loanpro.system_note_entity
    WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA()
      AND reference_type IN ('Entity.LoanSettings') 
      AND deleted = 0
      AND is_hard_deleted = FALSE
      AND created_ts >= '2025-08-24T12:00:00'
      AND created_ts <= '2025-08-24T13:00:00'
      LIMIT 1000
),
optimized_processed AS (
    SELECT 
        *,
        -- Use pre-parsed JSON for all extractions
        CASE WHEN note_title = 'Loan settings were created' THEN parsed_json:"loanStatusId"::STRING 
             ELSE parsed_json:"loanStatusId":"newValue"::STRING 
        END as loan_status_new_id,
        
        CASE WHEN note_title = 'Loan settings were created' THEN parsed_json:"loanSubStatusId"::STRING 
             WHEN parsed_json:"loanSubStatusId" IS NOT NULL THEN parsed_json:"loanSubStatusId":"newValue"::STRING
             WHEN parsed_json:"agent" IS NOT NULL THEN parsed_json:"agent":"newValue"::STRING
             WHEN parsed_json:"sourceCompany" IS NOT NULL THEN parsed_json:"sourceCompany":"newValue"::STRING
             ELSE parsed_json:"customFieldValue":"newValue"::STRING 
        END as note_new_value_raw,
        
        -- Categorization using pre-parsed JSON
        CASE WHEN REGEXP_SUBSTR(note_title, '\\((.*?)\\)', 1, 1, 'e', 1) IS NOT NULL 
             THEN REGEXP_SUBSTR(note_title, '\\((.*?)\\)', 1, 1, 'e', 1)
             WHEN parsed_json IS NULL THEN NULL
             WHEN parsed_json:"loanStatusId" IS NOT NULL THEN 'Loan Status - Loan Sub Status'
             WHEN parsed_json:"loanSubStatusId" IS NOT NULL THEN 'Loan Sub Status'
             WHEN parsed_json:"sourceCompany" IS NOT NULL THEN 'Source Company'
             WHEN parsed_json:"agent" IS NOT NULL THEN 'Agent'
             WHEN parsed_json:"PortfoliosAdded" IS NOT NULL THEN 'Portfolios Added'
             WHEN parsed_json:"PortfoliosRemoved" IS NOT NULL THEN 'Portfolios Removed'
             WHEN parsed_json:"applyDefaultFieldMap" IS NOT NULL THEN 'Apply Default Field Map'
             ELSE 'Custom Field'
        END as note_category
    FROM optimized_sample
)
SELECT 
    'Optimized Sample Results' as analysis_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN note_category IS NOT NULL THEN 1 END) as categorized_records,
    COUNT(CASE WHEN note_new_value_raw IS NOT NULL THEN 1 END) as records_with_new_values,
    COUNT(CASE WHEN loan_status_new_id IS NOT NULL THEN 1 END) as loan_status_records
FROM optimized_processed;

-- =============================================================================
-- 3. COLUMN EFFICIENCY ANALYSIS
-- =============================================================================

-- 3A: Check which columns are actually used/populated
SELECT 
    'Column Usage Analysis' as analysis_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN loan_status_new_id IS NOT NULL THEN 1 END) as loan_status_new_populated,
    COUNT(CASE WHEN loan_status_old_id IS NOT NULL THEN 1 END) as loan_status_old_populated,
    COUNT(CASE WHEN note_new_value_raw IS NOT NULL AND note_new_value_raw != '[]' THEN 1 END) as meaningful_new_values,
    COUNT(CASE WHEN note_old_value_raw IS NOT NULL AND note_old_value_raw != '[]' THEN 1 END) as meaningful_old_values,
    COUNT(CASE WHEN note_category IS NOT NULL THEN 1 END) as categorized_records,
    -- Percentages
    ROUND(COUNT(CASE WHEN note_new_value_raw IS NOT NULL AND note_new_value_raw != '[]' THEN 1 END) * 100.0 / COUNT(*), 2) as meaningful_new_values_pct,
    ROUND(COUNT(CASE WHEN note_category IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as categorization_success_pct
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= '2025-08-20';

-- 3B: Identify most common JSON patterns for targeted optimization
SELECT 
    'JSON Pattern Optimization Targets' as analysis_type,
    note_category,
    COUNT(*) as record_count,
    -- Sample JSON structures for each category
    MAX(CASE WHEN LENGTH(note_data) < 200 THEN note_data END) as sample_json_structure,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () as percentage_of_workload
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= '2025-08-20'
  AND note_data IS NOT NULL
GROUP BY note_category
ORDER BY record_count DESC
LIMIT 10;

-- =============================================================================
-- 4. PERFORMANCE RECOMMENDATIONS
-- =============================================================================

-- 4A: Estimated query performance improvement
SELECT 
    'Performance Improvement Estimates' as analysis_type,
    '5-layer Architecture Benefits' as optimization_category,
    'Single JSON parse per record vs multiple' as improvement_description,
    '60-70% reduction in JSON parsing operations' as estimated_performance_gain,
    'Materialized table caching strategy' as additional_optimization,
    'CTE-based single-parse pattern' as recommended_implementation;

-- 4B: Resource utilization optimization
SELECT 
    'Resource Optimization Recommendations' as analysis_type,
    COUNT(*) as daily_record_volume_estimate,
    COUNT(*) * 5 as estimated_current_json_parses_per_day,  -- Average 5 parses per record
    COUNT(*) * 1 as estimated_optimized_parses_per_day,     -- Single parse per record
    COUNT(*) * 4 as daily_json_operations_saved,           -- 4 operations saved per record
    ROUND(COUNT(*) * 4 * 365 / 1000000.0, 2) as annual_millions_operations_saved
FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES
WHERE created_ts >= CURRENT_DATE - 1;  -- Yesterday's volume