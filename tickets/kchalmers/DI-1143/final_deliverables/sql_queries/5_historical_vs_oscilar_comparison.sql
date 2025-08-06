-- DI-1143: Comparison Between Historical and Oscilar Account Data
-- This query demonstrates structural differences and field availability

-- =============================================================================
-- Field Availability Comparison Matrix
-- =============================================================================

SELECT 'FIELD AVAILABILITY COMPARISON' AS comparison_type;

WITH field_comparison AS (
    SELECT 
        'RECORD_CREATE_DATETIME' AS field_name,
        '✅ Available' AS historical_vw_plaid_transaction_account,
        '✅ Available (oscilar timestamp)' AS oscilar_vw_oscilar_plaid_account,
        'Timestamp mapping - equivalent functionality' AS notes
        
    UNION ALL SELECT 'LEAD_GUID', '✅ Available', '✅ Available (applicationId)', 'Entity identifier mapping'
    UNION ALL SELECT 'LEAD_ID', '✅ Available', '❌ Missing', 'Not present in Oscilar data'
    UNION ALL SELECT 'MEMBER_ID', '✅ Available', '✅ Available (borrowerId)', 'User identifier mapping'
    UNION ALL SELECT 'PLAID_REQUEST_ID', '✅ Available', '✅ Available (oscilar requestId)', 'Request tracking'
    UNION ALL SELECT 'TOTAL_TRANSACTIONS', '✅ Available', '❌ Missing - NO TRANSACTION DATA', '🚨 CRITICAL LIMITATION'
    UNION ALL SELECT 'SCHEMA_VERSION', '✅ Available', '✅ Available (oscilar_v1)', 'Version tracking'
    UNION ALL SELECT 'PLAID_CREATE_DATE', '✅ Available', '✅ Available (oscilar timestamp)', 'Date mapping'
    UNION ALL SELECT 'ACCOUNT_INDEX', '✅ Available', '✅ Available', 'Account array position'
    UNION ALL SELECT 'ACCOUNT_ID', '✅ Available', '✅ Available (when Plaid linked)', 'Plaid account identifier'
    UNION ALL SELECT 'ACCOUNT_MASK', '✅ Available', '✅ Available (derived)', 'Masked account number'
    UNION ALL SELECT 'ACCOUNT_NAME', '✅ Available', '✅ Available (from GIACT)', 'Institution name'
    UNION ALL SELECT 'ACCOUNT_OFFICIAL_NAME', '✅ Available', '✅ Available (from GIACT)', 'Institution official name'
    UNION ALL SELECT 'ACCOUNT_SUBTYPE', '✅ Available', '✅ Available (from GIACT)', 'Account classification'
    UNION ALL SELECT 'ACCOUNT_TYPE', '✅ Available', '✅ Available (assumed depository)', 'Account type'
    UNION ALL SELECT 'ACCOUNT_VERIFICATION_STATUS', '✅ Available', '✅ Available (from GIACT)', 'Verification status'
    UNION ALL SELECT 'ACCOUNT_BALANCE_AVAILABLE', '✅ Available', '❌ Missing', '🚨 CRITICAL for Prism requirements'
    UNION ALL SELECT 'ACCOUNT_BALANCE_CURRENT', '✅ Available', '❌ Missing', '🚨 CRITICAL for Prism requirements'
    UNION ALL SELECT 'ACCOUNT_BALANCE_ISO_CURRENCY_CODE', '✅ Available', '❌ Missing (assumed USD)', 'Currency information'
    UNION ALL SELECT 'ACCOUNT_BALANCE_LIMIT', '✅ Available', '❌ Missing', 'Credit limits not available'
    UNION ALL SELECT 'ACCOUNT_BALANCE_UNOFFICIAL_CURRENCY_CODE', '✅ Available', '❌ Missing', 'Alternative currency codes'
)
SELECT * FROM field_comparison
ORDER BY 
    CASE 
        WHEN notes LIKE '%CRITICAL%' THEN 1
        WHEN oscilar_vw_oscilar_plaid_account LIKE '%Missing%' THEN 2
        ELSE 3
    END,
    field_name;

-- =============================================================================
-- Sample Data Structure Comparison
-- =============================================================================

SELECT 'HISTORICAL DATA SAMPLE' AS data_source;
SELECT 
    RECORD_CREATE_DATETIME,
    LEAD_GUID,
    ACCOUNT_ID,
    ACCOUNT_NAME,
    ACCOUNT_SUBTYPE,
    ACCOUNT_BALANCE_CURRENT,
    ACCOUNT_VERIFICATION_STATUS
FROM BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_TRANSACTION_ACCOUNT
ORDER BY RECORD_CREATE_DATETIME DESC
LIMIT 3;

SELECT 'OSCILAR ALIGNED DATA SAMPLE' AS data_source;
SELECT 
    RECORD_CREATE_DATETIME,
    LEAD_GUID,
    ACCOUNT_ID,
    ACCOUNT_NAME,
    ACCOUNT_SUBTYPE,
    ACCOUNT_BALANCE_CURRENT,  -- This will be NULL
    ACCOUNT_VERIFICATION_STATUS
FROM DATA_STORE.VW_OSCILAR_PLAID_ACCOUNT
ORDER BY RECORD_CREATE_DATETIME DESC
LIMIT 3;

-- =============================================================================
-- Critical Gaps Analysis for Prism Requirements
-- =============================================================================

SELECT 'PRISM REQUIREMENTS GAP ANALYSIS' AS analysis_type;

WITH prism_requirements AS (
    SELECT 
        'Entity ID' AS prism_field,
        'LEAD_GUID' AS historical_source,
        'LEAD_GUID (applicationId)' AS oscilar_source,
        '✅ Available' AS status,
        'Complete mapping available' AS impact
        
    UNION ALL SELECT 'Account ID', 'ACCOUNT_ID', 'ACCOUNT_ID (when linked)', '⚠️ Partial', 'Only when Plaid linking succeeds'
    UNION ALL SELECT 'Account Type', 'ACCOUNT_SUBTYPE', 'ACCOUNT_SUBTYPE (from GIACT)', '✅ Available', 'Via GIACT integration'
    UNION ALL SELECT 'Account Balance', 'ACCOUNT_BALANCE_CURRENT', 'NULL', '❌ Missing', '🚨 CRITICAL: Cannot provide balance data'
    UNION ALL SELECT 'Balance Date', 'PLAID_CREATE_DATE', 'NULL', '❌ Missing', '🚨 CRITICAL: No balance timestamps'
    UNION ALL SELECT 'Institution ID', 'ACCOUNT_NAME', 'ACCOUNT_NAME (from GIACT)', '✅ Available', 'Institution names available'
    
    -- Transaction-level requirements (all missing)
    UNION ALL SELECT 'Transaction ID', 'VW_PLAID_TRANSACTION_DETAIL', 'NULL', '❌ Missing', '🚨 CRITICAL: No transaction data'
    UNION ALL SELECT 'Transaction Amount', 'VW_PLAID_TRANSACTION_DETAIL', 'NULL', '❌ Missing', '🚨 CRITICAL: No transaction data'
    UNION ALL SELECT 'Transaction Date', 'VW_PLAID_TRANSACTION_DETAIL', 'NULL', '❌ Missing', '🚨 CRITICAL: No transaction data'
    UNION ALL SELECT 'Transaction Description', 'VW_PLAID_TRANSACTION_DETAIL', 'NULL', '❌ Missing', '🚨 CRITICAL: No transaction data'
    UNION ALL SELECT 'Transaction MCC', 'VW_PLAID_TRANSACTION_DETAIL', 'NULL', '❌ Missing', '🚨 CRITICAL: No transaction data'
    UNION ALL SELECT 'Transaction Merchant Name', 'VW_PLAID_TRANSACTION_DETAIL', 'NULL', '❌ Missing', '🚨 CRITICAL: No transaction data'
)
SELECT * FROM prism_requirements
ORDER BY 
    CASE 
        WHEN impact LIKE '%CRITICAL%' THEN 1
        WHEN status = '❌ Missing' THEN 2
        WHEN status = '⚠️ Partial' THEN 3
        ELSE 4
    END,
    prism_field;

-- =============================================================================
-- Business Impact Summary
-- =============================================================================

SELECT 'BUSINESS IMPACT ASSESSMENT' AS summary_type;

SELECT 
    '✅ ACHIEVABLE WITH OSCILAR DATA' AS capability_category,
    'Account-level verification and institution identification' AS business_function,
    'Entity linking, institution names, account types, verification status' AS available_data,
    'Suitable for account verification workflows' AS use_cases
    
UNION ALL

SELECT 
    '❌ NOT ACHIEVABLE WITH OSCILAR DATA' AS capability_category,
    'Transaction analysis and balance reporting' AS business_function,
    'Transaction details, amounts, dates, balances, spending patterns' AS missing_data,
    'Financial analysis, spending categorization, balance monitoring' AS blocked_use_cases
    
UNION ALL
    
SELECT 
    '⚠️ PARTIALLY ACHIEVABLE' AS capability_category,
    'Prism vendor data delivery' AS business_function,
    'Account-level requirements only (not transaction-level)' AS limitation,
    'Reduced scope Prism integration possible' AS modified_approach;