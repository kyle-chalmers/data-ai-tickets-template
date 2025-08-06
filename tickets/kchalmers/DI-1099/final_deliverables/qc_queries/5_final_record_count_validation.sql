-- DI-1099: Final Record Count Validation - SQL-Based QC
-- Validates the exact record counts for both goodbye letter files generated

-- Record count validation for both complete and Theorem-only goodbye letter lists
WITH source_table_count AS (
    SELECT COUNT(*) as selected_table_count
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED
),
complete_goodbye_count AS (
    SELECT 
        COUNT(*) as complete_list_count,
        COUNT(DISTINCT la.LEGACY_LOAN_ID) as unique_loans_complete,
        COUNT(CASE WHEN cust.CUSTOMER_ID IS NOT NULL THEN 1 END) as sfmc_records_complete
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
        ON LA.LEGACY_LOAN_ID = C.LOANID
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
        ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
        AND ci.MEMBER_PII_END_DATE IS NULL
    LEFT JOIN business_intelligence.bridge.vw_los_custom_loan_settings_current los
        ON los.APPLICATION_GUID = la.LEAD_GUID
    INNER JOIN business_intelligence.bridge.VW_LOAN_CUSTOMER_CURRENT cust
        ON los.loan_id = cust.loan_id 
        AND cust.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LOS_SCHEMA()
    INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE A
        ON C.LOANID = A.LOANID
),
theorem_only_count AS (
    SELECT 
        COUNT(*) as theorem_only_count,
        COUNT(DISTINCT la.LEGACY_LOAN_ID) as unique_loans_theorem,
        COUNT(CASE WHEN cust.CUSTOMER_ID IS NOT NULL THEN 1 END) as sfmc_records_theorem
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
        ON LA.LEGACY_LOAN_ID = C.LOANID
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
        ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
        AND ci.MEMBER_PII_END_DATE IS NULL
    LEFT JOIN business_intelligence.bridge.vw_los_custom_loan_settings_current los
        ON los.APPLICATION_GUID = la.LEAD_GUID
    INNER JOIN business_intelligence.bridge.VW_LOAN_CUSTOMER_CURRENT cust
        ON los.loan_id = cust.loan_id 
        AND cust.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LOS_SCHEMA()
    INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE A
        ON C.LOANID = A.LOANID
    WHERE A.PORTFOLIONAME LIKE '%Theorem%'
)

-- Final validation results
SELECT 
    'SOURCE TABLE' as validation_type,
    selected_table_count as record_count,
    selected_table_count as unique_count,
    NULL as sfmc_count,
    '100.00' as coverage_pct
FROM source_table_count

UNION ALL

SELECT 
    'COMPLETE GOODBYE LIST' as validation_type,
    complete_list_count as record_count,
    unique_loans_complete as unique_count,
    sfmc_records_complete as sfmc_count,
    ROUND(sfmc_records_complete * 100.0 / complete_list_count, 2)::VARCHAR as coverage_pct
FROM complete_goodbye_count

UNION ALL

SELECT 
    'THEOREM ONLY LIST' as validation_type,
    theorem_only_count as record_count,
    unique_loans_theorem as unique_count,
    sfmc_records_theorem as sfmc_count,
    ROUND(sfmc_records_theorem * 100.0 / theorem_only_count, 2)::VARCHAR as coverage_pct
FROM theorem_only_count

UNION ALL

-- Coverage analysis
SELECT 
    'THEOREM COVERAGE' as validation_type,
    theorem_only_count as record_count,
    complete_list_count as unique_count,
    (complete_list_count - theorem_only_count) as sfmc_count,
    ROUND(theorem_only_count * 100.0 / complete_list_count, 2)::VARCHAR as coverage_pct
FROM complete_goodbye_count, theorem_only_count;