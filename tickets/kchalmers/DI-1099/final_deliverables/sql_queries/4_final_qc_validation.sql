-- DI-1099: Final QC Validation for Goodbye Letter Lists
-- SQL-based validation of record counts and data quality

-- QC Summary for both complete and Theorem-only lists
WITH complete_list_qc AS (
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT la.LEGACY_LOAN_ID) as unique_loans,
        COUNT(CASE WHEN cust.CUSTOMER_ID IS NOT NULL THEN 1 END) as records_with_sfmc,
        COUNT(CASE WHEN ci.email IS NOT NULL THEN 1 END) as records_with_email,
        COUNT(DISTINCT A.PORTFOLIONAME) as portfolio_count
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
theorem_only_qc AS (
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT la.LEGACY_LOAN_ID) as unique_loans,
        COUNT(CASE WHEN cust.CUSTOMER_ID IS NOT NULL THEN 1 END) as records_with_sfmc,
        COUNT(CASE WHEN ci.email IS NOT NULL THEN 1 END) as records_with_email,
        COUNT(DISTINCT A.PORTFOLIONAME) as portfolio_count
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
),
portfolio_breakdown AS (
    SELECT 
        A.PORTFOLIONAME,
        COUNT(*) as loan_count,
        CASE WHEN A.PORTFOLIONAME LIKE '%Theorem%' THEN 'THEOREM' ELSE 'NON-THEOREM' END as portfolio_type
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
    INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE A
        ON C.LOANID = A.LOANID
    GROUP BY A.PORTFOLIONAME
)

-- Final QC Results
SELECT 
    'COMPLETE LIST QC' as list_type,
    total_records,
    unique_loans,
    records_with_sfmc,
    records_with_email,
    portfolio_count,
    ROUND(records_with_sfmc * 100.0 / total_records, 2) as sfmc_coverage_pct,
    ROUND(records_with_email * 100.0 / total_records, 2) as email_coverage_pct
FROM complete_list_qc

UNION ALL

SELECT 
    'THEOREM ONLY QC' as list_type,
    total_records,
    unique_loans,
    records_with_sfmc,
    records_with_email,
    portfolio_count,
    ROUND(records_with_sfmc * 100.0 / total_records, 2) as sfmc_coverage_pct,
    ROUND(records_with_email * 100.0 / total_records, 2) as email_coverage_pct
FROM theorem_only_qc

UNION ALL

-- Portfolio type summary
SELECT 
    CONCAT('PORTFOLIO TYPE: ', portfolio_type) as list_type,
    SUM(loan_count)::VARCHAR as total_records,
    COUNT(DISTINCT PORTFOLIONAME)::VARCHAR as unique_loans,
    NULL as records_with_sfmc,
    NULL as records_with_email,
    NULL as portfolio_count,
    NULL as sfmc_coverage_pct,
    NULL as email_coverage_pct
FROM portfolio_breakdown
GROUP BY portfolio_type

ORDER BY list_type;
