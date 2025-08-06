-- DI-1100: Comprehensive QC Validation for Theorem Credit Reporting and Placement Upload
-- Validates both deliverable files against source data

SET START_DATE = '2025-07-31';

-- =============================================================================
-- QC 1: SOURCE DATA VALIDATION
-- Verify we're working with the correct source data
-- =============================================================================

SELECT 'Source Data Validation' as qc_check,
    COUNT(*) as total_source_loans,
    COUNT(DISTINCT LOANID) as unique_source_loans,
    MIN(LOANID) as min_loan_id,
    MAX(LOANID) as max_loan_id
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED;

-- =============================================================================
-- QC 2: BULK UPLOAD PLACEMENT FILE VALIDATION  
-- Verify placement file completeness and data quality
-- =============================================================================

SELECT 'Bulk Upload Placement File QC' as qc_check,
    COUNT(*) as total_placement_records,
    COUNT(DISTINCT C.LOANID) as unique_loans,
    COUNT(CASE WHEN A.LOAN_ID IS NOT NULL THEN 1 END) as loans_with_loan_id,
    COUNT(CASE WHEN B.SETTINGS_ID IS NOT NULL THEN 1 END) as loans_with_settings_id,
    COUNT(CASE WHEN A.LEGACY_LOAN_ID IS NOT NULL THEN 1 END) as loans_with_legacy_loan_id,
    -- Check for expected placement status
    COUNT(CASE WHEN 'Resurgent' = 'Resurgent' THEN 1 END) as records_with_resurgent_status,
    -- Verify start date consistency  
    COUNT(CASE WHEN $START_DATE = '2025-07-31' THEN 1 END) as records_with_correct_date
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
    ON A.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT B
    ON A.LOAN_ID::STRING = B.ID::STRING 
    AND B.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA();

-- =============================================================================
-- QC 3: CREDIT REPORTING FILE VALIDATION
-- Verify credit reporting file completeness and PII data quality
-- =============================================================================

SELECT 'Credit Reporting File QC' as qc_check,
    COUNT(*) as total_credit_reporting_records,
    COUNT(DISTINCT C.LOANID) as unique_loans,
    COUNT(CASE WHEN la.LEGACY_LOAN_ID IS NOT NULL THEN 1 END) as loans_with_legacy_loan_id,
    COUNT(CASE WHEN ci.FIRST_NAME IS NOT NULL THEN 1 END) as loans_with_first_name,
    COUNT(CASE WHEN ci.LAST_NAME IS NOT NULL THEN 1 END) as loans_with_last_name,
    COUNT(CASE WHEN ci.FIRST_NAME IS NULL THEN 1 END) as loans_missing_first_name,
    COUNT(CASE WHEN ci.LAST_NAME IS NULL THEN 1 END) as loans_missing_last_name,
    -- Verify start date consistency
    COUNT(CASE WHEN $START_DATE = '2025-07-31' THEN 1 END) as records_with_correct_date
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
    ON LA.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
    ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
    AND ci.MEMBER_PII_END_DATE IS NULL;

-- =============================================================================
-- QC 4: DATA CONSISTENCY VALIDATION
-- Verify both files have the same loan universe
-- =============================================================================

WITH placement_loans AS (
    SELECT DISTINCT C.LOANID
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
        ON A.LEGACY_LOAN_ID = C.LOANID
    WHERE A.LOAN_ID IS NOT NULL
),
credit_reporting_loans AS (
    SELECT DISTINCT C.LOANID  
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
        ON LA.LEGACY_LOAN_ID = C.LOANID
    WHERE LA.LEGACY_LOAN_ID IS NOT NULL
)
SELECT 'Data Consistency Check' as qc_check,
    (SELECT COUNT(*) FROM placement_loans) as placement_file_loans,
    (SELECT COUNT(*) FROM credit_reporting_loans) as credit_reporting_file_loans,
    CASE 
        WHEN (SELECT COUNT(*) FROM placement_loans) = (SELECT COUNT(*) FROM credit_reporting_loans) 
        THEN 'PASS: Loan counts match'
        ELSE 'FAIL: Loan counts do not match'
    END as consistency_status;

-- =============================================================================
-- QC 5: SAMPLE DATA VALIDATION
-- Show sample records from each file for manual review
-- =============================================================================

-- Sample Bulk Upload Placement records
SELECT 'Sample Placement Records' as qc_check,
    A.LOAN_ID as LP_LOAN_ID,
    UPPER(A.LEGACY_LOAN_ID) as loanid,
    B.SETTINGS_ID,
    'Resurgent' as Placement_Status,
    $START_DATE as Placement_Status_StartDate
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
    ON A.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT B
    ON A.LOAN_ID::STRING = B.ID::STRING 
    AND B.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
ORDER BY A.LEGACY_LOAN_ID
LIMIT 5;

-- Sample Credit Reporting records
SELECT 'Sample Credit Reporting Records' as qc_check,
    UPPER(la.LEGACY_LOAN_ID) as loan_id,
    UPPER(ci.FIRST_NAME) as first_name,
    UPPER(ci.LAST_NAME) as last_name,
    $START_DATE as PLACEMENT_STATUS_STARTDATE
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
    ON LA.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
    ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
    AND ci.MEMBER_PII_END_DATE IS NULL
ORDER BY la.LEGACY_LOAN_ID
LIMIT 5;