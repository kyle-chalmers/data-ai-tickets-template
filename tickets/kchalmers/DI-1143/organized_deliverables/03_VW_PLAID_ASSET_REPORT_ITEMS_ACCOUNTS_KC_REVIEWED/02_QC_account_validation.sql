-- DI-1143: Quality Control Queries for VW_OSCILAR_PLAID_ACCOUNT
-- Comprehensive validation of the account alignment view

-- =============================================================================
-- QC Query 1: Basic Row Count and Structure Validation
-- =============================================================================
SELECT 'Basic Structure Validation' AS test_category;

SELECT 
    COUNT(*) AS total_account_records,
    COUNT(DISTINCT LEAD_GUID) AS unique_applications,
    COUNT(DISTINCT ACCOUNT_ID) AS unique_plaid_account_ids,
    COUNT(DISTINCT OSCILAR_RECORD_ID) AS unique_oscilar_records,
    
    -- Check data completeness
    COUNT(CASE WHEN ACCOUNT_ID IS NOT NULL THEN 1 END) AS records_with_plaid_account_id,
    COUNT(CASE WHEN ACCOUNT_NAME != 'Unknown Institution' THEN 1 END) AS records_with_institution_name,
    COUNT(CASE WHEN ACCOUNT_VERIFICATION_STATUS = 'verified' THEN 1 END) AS verified_accounts,
    
    -- Coverage percentages  
    ROUND(COUNT(CASE WHEN ACCOUNT_ID IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS plaid_account_id_coverage_pct,
    ROUND(COUNT(CASE WHEN ACCOUNT_NAME != 'Unknown Institution' THEN 1 END) * 100.0 / COUNT(*), 1) AS institution_name_coverage_pct

FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT;

-- =============================================================================
-- QC Query 2: Field Population Analysis
-- =============================================================================
SELECT 'Field Population Analysis' AS test_category;

SELECT 
    'RECORD_CREATE_DATETIME' AS field_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN RECORD_CREATE_DATETIME IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN RECORD_CREATE_DATETIME IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT

UNION ALL

SELECT 
    'LEAD_GUID' AS field_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN LEAD_GUID IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN LEAD_GUID IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT

UNION ALL

SELECT 
    'ACCOUNT_ID' AS field_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN ACCOUNT_ID IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN ACCOUNT_ID IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT

UNION ALL

SELECT 
    'ACCOUNT_NAME' AS field_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN ACCOUNT_NAME IS NOT NULL AND ACCOUNT_NAME != 'Unknown Institution' THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN ACCOUNT_NAME IS NOT NULL AND ACCOUNT_NAME != 'Unknown Institution' THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT

UNION ALL

SELECT 
    'ACCOUNT_VERIFICATION_STATUS' AS field_name,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN ACCOUNT_VERIFICATION_STATUS IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN ACCOUNT_VERIFICATION_STATUS IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT

ORDER BY field_name;

-- =============================================================================
-- QC Query 3: Account Type and Institution Analysis
-- =============================================================================
SELECT 'Account Classification Analysis' AS test_category;

-- Account subtype distribution
SELECT 
    ACCOUNT_SUBTYPE,
    COUNT(*) AS account_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
GROUP BY ACCOUNT_SUBTYPE
ORDER BY account_count DESC;

-- Verification status distribution
SELECT 'Verification Status Distribution' AS analysis_type;
SELECT 
    ACCOUNT_VERIFICATION_STATUS,
    COUNT(*) AS account_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
GROUP BY ACCOUNT_VERIFICATION_STATUS
ORDER BY account_count DESC;

-- Top institutions
SELECT 'Top 10 Financial Institutions' AS analysis_type;
SELECT 
    ACCOUNT_NAME,
    COUNT(*) AS account_count,
    COUNT(DISTINCT LEAD_GUID) AS unique_applications
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
WHERE ACCOUNT_NAME != 'Unknown Institution'
GROUP BY ACCOUNT_NAME
ORDER BY account_count DESC
LIMIT 10;

-- =============================================================================
-- QC Query 4: Data Quality Issues Detection  
-- =============================================================================
SELECT 'Data Quality Issues' AS test_category;

-- Missing critical fields
SELECT 
    'Missing LEAD_GUID' AS issue_type,
    COUNT(*) AS affected_records
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
WHERE LEAD_GUID IS NULL

UNION ALL

SELECT 
    'Missing ACCOUNT_ID (Plaid linking failed)' AS issue_type,
    COUNT(*) AS affected_records
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
WHERE ACCOUNT_ID IS NULL

UNION ALL

SELECT 
    'Unknown Institution (GIACT failed)' AS issue_type,
    COUNT(*) AS affected_records
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
WHERE ACCOUNT_NAME = 'Unknown Institution'

UNION ALL

SELECT 
    'Unverified Accounts' AS issue_type,
    COUNT(*) AS affected_records
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
WHERE ACCOUNT_VERIFICATION_STATUS = 'unverified'

ORDER BY affected_records DESC;

-- =============================================================================
-- QC Query 5: Sample Records for Manual Review
-- =============================================================================
SELECT 'Sample Records for Review' AS test_category;

SELECT 
    LEAD_GUID,
    ACCOUNT_ID,
    ACCOUNT_NAME,
    ACCOUNT_SUBTYPE,
    ACCOUNT_VERIFICATION_STATUS,
    SOURCE_ACCOUNT_NUMBER,
    SOURCE_ROUTING_NUMBER,
    PLAID_TOKEN_COUNT,
    RECORD_CREATE_DATETIME
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
WHERE ACCOUNT_ID IS NOT NULL  -- Successfully linked to Plaid
  AND ACCOUNT_NAME != 'Unknown Institution'  -- Has institution data
ORDER BY RECORD_CREATE_DATETIME DESC
LIMIT 5;

-- =============================================================================
-- QC Query 6: Comparison with Source Data Counts
-- =============================================================================
SELECT 'Source vs View Record Count Validation' AS test_category;

WITH source_counts AS (
    SELECT COUNT(*) AS source_records_with_tokens
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE CONTAINS(DATA::string, 'plaidAccessToken')
      AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
      AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0
),
view_counts AS (
    SELECT COUNT(*) AS view_total_accounts
    FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
)
SELECT 
    source_records_with_tokens,
    view_total_accounts,
    CASE 
        WHEN view_total_accounts >= source_records_with_tokens THEN '✅ Expected (accounts can exceed applications)'
        WHEN view_total_accounts < source_records_with_tokens * 0.8 THEN '❌ Significant data loss - investigate'
        ELSE '⚠️ Some data loss - review account flattening logic'
    END AS validation_result
FROM source_counts, view_counts;