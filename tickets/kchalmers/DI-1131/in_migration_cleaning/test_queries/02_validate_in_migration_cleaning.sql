/***********************************************************************************************************************
DI-1131 IN-MIGRATION Email Cleaning Validation Queries
Date: 2025-08-18
Author: Kyle Chalmers

Purpose: Test queries to validate that IN-MIGRATION email cleaning works correctly
         in the updated ANALYTICS_PII views deployed to DEV

IMPORTANT: Run these queries AFTER deploying the updated views to DEV environment
***********************************************************************************************************************/

-- ===========================================================================================================
-- 1. COUNT IN-MIGRATION EMAILS: Compare production vs DEV cleaned versions
-- ===========================================================================================================

-- Production (should have IN-MIGRATION emails)
WITH prod_migration_emails AS (
    SELECT 
        'PROD_MEMBER_PII' as source,
        COUNT(*) as total_records,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_count,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE 'IN-MIGRATION-%' THEN 1 END) as in_migration_prefix_count
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII
    WHERE EMAIL IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'PROD_APPLICATION_PII' as source,
        COUNT(*) as total_records,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_count,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE 'IN-MIGRATION-%' THEN 1 END) as in_migration_prefix_count
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_APPLICATION_PII
    WHERE EMAIL IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'PROD_LEAD_PII' as source,
        COUNT(*) as total_records,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_count,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE 'IN-MIGRATION-%' THEN 1 END) as in_migration_prefix_count
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_LEAD_PII
    WHERE EMAIL IS NOT NULL
),

-- DEV cleaned versions (should have dramatically reduced IN-MIGRATION emails)
dev_cleaned_emails AS (
    SELECT 
        'DEV_MEMBER_PII_CLEANED' as source,
        COUNT(*) as total_records,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_count,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE 'IN-MIGRATION-%' THEN 1 END) as in_migration_prefix_count
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_MEMBER_PII
    WHERE EMAIL IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'DEV_APPLICATION_PII_CLEANED' as source,
        COUNT(*) as total_records,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_count,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE 'IN-MIGRATION-%' THEN 1 END) as in_migration_prefix_count
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_APPLICATION_PII
    WHERE EMAIL IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'DEV_LEAD_PII_CLEANED' as source,
        COUNT(*) as total_records,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_count,
        COUNT(CASE WHEN UPPER(EMAIL) LIKE 'IN-MIGRATION-%' THEN 1 END) as in_migration_prefix_count
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_LEAD_PII
    WHERE EMAIL IS NOT NULL
)

SELECT * FROM prod_migration_emails
UNION ALL
SELECT * FROM dev_cleaned_emails
ORDER BY source;

-- ===========================================================================================================
-- 2. SAMPLE EMAIL TRANSFORMATIONS: Show specific examples of cleaned emails
-- ===========================================================================================================

-- Member PII email cleaning examples
SELECT 
    'MEMBER_PII_COMPARISON' as table_type,
    'ORIGINAL' as version,
    EMAIL as sample_email
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII
WHERE UPPER(EMAIL) LIKE 'IN-MIGRATION-%'
LIMIT 5

UNION ALL

SELECT 
    'MEMBER_PII_COMPARISON' as table_type,
    'CLEANED' as version,
    EMAIL as sample_email
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_MEMBER_PII
WHERE MEMBER_ID IN (
    SELECT MEMBER_ID 
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII
    WHERE UPPER(EMAIL) LIKE 'IN-MIGRATION-%'
    LIMIT 5
);

-- ===========================================================================================================
-- 3. DATA INTEGRITY CHECK: Ensure record counts remain the same
-- ===========================================================================================================

SELECT 
    'RECORD_COUNT_VALIDATION' as check_type,
    'MEMBER_PII' as table_name,
    'PRODUCTION' as environment,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII

UNION ALL

SELECT 
    'RECORD_COUNT_VALIDATION' as check_type,
    'MEMBER_PII' as table_name,
    'DEV_CLEANED' as environment,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_MEMBER_PII

UNION ALL

SELECT 
    'RECORD_COUNT_VALIDATION' as check_type,
    'APPLICATION_PII' as table_name,
    'PRODUCTION' as environment,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_APPLICATION_PII

UNION ALL

SELECT 
    'RECORD_COUNT_VALIDATION' as check_type,
    'APPLICATION_PII' as table_name,
    'DEV_CLEANED' as environment,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_APPLICATION_PII

UNION ALL

SELECT 
    'RECORD_COUNT_VALIDATION' as check_type,
    'LEAD_PII' as table_name,
    'PRODUCTION' as environment,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_LEAD_PII

UNION ALL

SELECT 
    'RECORD_COUNT_VALIDATION' as check_type,
    'LEAD_PII' as table_name,
    'DEV_CLEANED' as environment,
    COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_LEAD_PII;

-- ===========================================================================================================
-- 4. END-TO-END IMPACT TEST: Test with email lookup table using cleaned views
-- ===========================================================================================================

-- Test how many IN-MIGRATION emails would be in the lookup table using cleaned DEV views
SELECT 
    'LOOKUP_TABLE_IMPACT_TEST' as test_type,
    COUNT(*) as total_records,
    COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) as in_migration_records,
    ROUND(100.0 * COUNT(CASE WHEN UPPER(EMAIL) LIKE '%IN-MIGRATION%' THEN 1 END) / NULLIF(COUNT(*), 0), 2) as in_migration_percentage
FROM (
    -- Simulate the lookup table logic using DEV cleaned views
    SELECT DISTINCT 
        UPPER(REGEXP_REPLACE(m.EMAIL, '^IN-MIGRATION-', '')) as EMAIL,
        vl.LEAD_GUID as PAYOFFUID
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_MEMBER_PII m
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON vl.MEMBER_ID = m.MEMBER_ID
    WHERE m.EMAIL IS NOT NULL
    
    UNION
    
    SELECT DISTINCT 
        UPPER(REGEXP_REPLACE(a.EMAIL, '^IN-MIGRATION-', '')) as EMAIL,
        a.LEAD_GUID as PAYOFFUID
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_APPLICATION_PII a
    WHERE a.EMAIL IS NOT NULL
    
    UNION
    
    SELECT DISTINCT 
        UPPER(REGEXP_REPLACE(l.EMAIL, '^IN-MIGRATION-', '')) as EMAIL,
        l.LEAD_GUID as PAYOFFUID
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_LEAD_PII l
    WHERE l.EMAIL IS NOT NULL
);