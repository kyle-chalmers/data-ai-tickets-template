-- DI-1143: Quality Control Queries for Transaction Data
-- Comprehensive validation of transaction views after discovering transaction data in Plaid Assets responses
--
-- BREAKTHROUGH: Transaction data IS available - validating completeness and quality

-- =============================================================================
-- QC Query 1: Transaction Data Availability Summary
-- =============================================================================
SELECT 'Transaction Data Availability Summary' AS test_category;

SELECT 
    COUNT(*) AS total_oscilar_records,
    COUNT(CASE WHEN DATA:data:integrations[3]:name::varchar = 'Plaid_Assets' THEN 1 END) AS plaid_assets_integrations,
    COUNT(CASE WHEN 
        DATA:data:integrations[3]:name::varchar = 'Plaid_Assets' 
        AND DATA:data:integrations[3]:response:items IS NOT NULL 
        AND ARRAY_SIZE(DATA:data:integrations[3]:response:items) > 0 
    THEN 1 END) AS successful_plaid_assets_responses,
    
    COUNT(CASE WHEN 
        DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
        AND GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions') IS NOT NULL
        AND ARRAY_SIZE(GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions')) > 0
    THEN 1 END) AS records_with_transaction_data,
    
    SUM(CASE WHEN 
        DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
        AND GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions') IS NOT NULL
    THEN ARRAY_SIZE(GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions'))
    ELSE 0 END) AS total_transactions_available,
    
    COUNT(CASE WHEN 
        DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
        AND GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances.current') IS NOT NULL
    THEN 1 END) AS records_with_balance_data

FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE CONTAINS(DATA::string, 'plaid');

-- =============================================================================
-- QC Query 2: Transaction Volume Analysis
-- =============================================================================
SELECT 'Transaction Volume Analysis' AS test_category;

WITH transaction_counts AS (
    SELECT 
        DATA:data:input:payload:applicationId::varchar AS application_id,
        ARRAY_SIZE(GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions')) AS transaction_count,
        GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances.current')::float AS current_balance
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
      AND GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions') IS NOT NULL
)
SELECT 
    COUNT(*) AS applications_with_transactions,
    MIN(transaction_count) AS min_transactions_per_app,
    MAX(transaction_count) AS max_transactions_per_app,
    ROUND(AVG(transaction_count), 1) AS avg_transactions_per_app,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY transaction_count) AS median_transactions_per_app,
    COUNT(CASE WHEN transaction_count = 0 THEN 1 END) AS apps_with_zero_transactions,
    COUNT(CASE WHEN transaction_count > 100 THEN 1 END) AS apps_with_100plus_transactions,
    COUNT(CASE WHEN current_balance IS NOT NULL THEN 1 END) AS apps_with_balance_data,
    ROUND(AVG(current_balance), 2) AS avg_current_balance
FROM transaction_counts;

-- =============================================================================
-- QC Query 3: Transaction Field Population Analysis
-- =============================================================================
SELECT 'Transaction Field Population Analysis' AS test_category;

WITH transaction_sample AS (
    SELECT 
        DATA:data:input:payload:applicationId::varchar AS application_id,
        transaction.value AS transaction_data
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
    LATERAL FLATTEN(input => GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions')) transaction
    WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
      AND GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions') IS NOT NULL
    LIMIT 1000  -- Sample for performance
)
SELECT 
    'transaction_id' AS field_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN transaction_data:transaction_id IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN transaction_data:transaction_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM transaction_sample

UNION ALL

SELECT 
    'amount' AS field_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN transaction_data:amount IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN transaction_data:amount IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM transaction_sample

UNION ALL

SELECT 
    'date' AS field_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN transaction_data:date IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN transaction_data:date IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM transaction_sample

UNION ALL

SELECT 
    'name' AS field_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN transaction_data:name IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN transaction_data:name IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM transaction_sample

UNION ALL

SELECT 
    'merchant_name' AS field_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN transaction_data:merchant_name IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN transaction_data:merchant_name IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM transaction_sample

UNION ALL

SELECT 
    'category' AS field_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN transaction_data:category IS NOT NULL THEN 1 END) AS populated_count,
    ROUND(COUNT(CASE WHEN transaction_data:category IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS populated_pct
FROM transaction_sample

ORDER BY field_name;

-- =============================================================================
-- QC Query 4: Critical Prism Fields Validation
-- =============================================================================
SELECT 'Critical Prism Fields Validation' AS test_category;

WITH prism_field_check AS (
    SELECT 
        DATA:data:input:payload:applicationId::varchar AS entity_id,
        account_data.value:account_id::varchar AS account_id,
        transaction.value:transaction_id::varchar AS transaction_id,
        transaction.value:amount::float AS transaction_amount,
        transaction.value:date::varchar AS transaction_date,
        transaction.value:name::varchar AS transaction_description,
        ARRAY_TO_STRING(transaction.value:category, ', ') AS transaction_category,
        transaction.value:merchant_name::varchar AS merchant_name,
        CASE 
            WHEN transaction.value:amount::float < 0 THEN 'credit'
            WHEN transaction.value:amount::float > 0 THEN 'debit'
            ELSE 'unknown'
        END AS debit_credit_indicator
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
    LATERAL FLATTEN(input => GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts')) account_data,
    LATERAL FLATTEN(input => account_data.value:transactions) transaction
    WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
    LIMIT 500  -- Sample for performance
)
SELECT 
    'Entity ID' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN entity_id IS NOT NULL THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN entity_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ Required for Prism' AS status
FROM prism_field_check

UNION ALL

SELECT 
    'Account ID' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN account_id IS NOT NULL THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN account_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ Required for Prism' AS status
FROM prism_field_check

UNION ALL

SELECT 
    'Transaction ID' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN transaction_id IS NOT NULL THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN transaction_id IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ Required for Prism' AS status
FROM prism_field_check

UNION ALL

SELECT 
    'Transaction Amount' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN transaction_amount IS NOT NULL THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN transaction_amount IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ CRITICAL for Prism' AS status
FROM prism_field_check

UNION ALL

SELECT 
    'Transaction Date' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN transaction_date IS NOT NULL THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN transaction_date IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ CRITICAL for Prism' AS status
FROM prism_field_check

UNION ALL

SELECT 
    'Transaction Description' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN transaction_description IS NOT NULL THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN transaction_description IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ Required for Prism' AS status
FROM prism_field_check

UNION ALL

SELECT 
    'Debit/Credit Indicator' AS prism_field,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN debit_credit_indicator != 'unknown' THEN 1 END) AS available_count,
    ROUND(COUNT(CASE WHEN debit_credit_indicator != 'unknown' THEN 1 END) * 100.0 / COUNT(*), 1) AS availability_pct,
    '✅ Derived field available' AS status
FROM prism_field_check

ORDER BY prism_field;

-- =============================================================================
-- QC Query 5: Balance Data Quality Assessment
-- =============================================================================
SELECT 'Balance Data Quality Assessment' AS test_category;

WITH balance_analysis AS (
    SELECT 
        DATA:data:input:payload:applicationId::varchar AS application_id,
        GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances.current')::float AS current_balance,
        GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances.available')::float AS available_balance,
        GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances.iso_currency_code')::varchar AS currency_code,
        GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances.limit')::float AS credit_limit
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
      AND GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].balances') IS NOT NULL
)
SELECT 
    COUNT(*) AS accounts_with_balance_data,
    COUNT(CASE WHEN current_balance IS NOT NULL THEN 1 END) AS accounts_with_current_balance,
    COUNT(CASE WHEN available_balance IS NOT NULL THEN 1 END) AS accounts_with_available_balance,
    COUNT(CASE WHEN currency_code = 'USD' THEN 1 END) AS usd_accounts,
    COUNT(CASE WHEN credit_limit IS NOT NULL THEN 1 END) AS accounts_with_credit_limit,
    ROUND(AVG(current_balance), 2) AS avg_current_balance,
    ROUND(MIN(current_balance), 2) AS min_current_balance,
    ROUND(MAX(current_balance), 2) AS max_current_balance,
    COUNT(CASE WHEN current_balance < 0 THEN 1 END) AS accounts_with_negative_balance
FROM balance_analysis;

-- =============================================================================
-- QC Query 6: Data Quality Issues Detection
-- =============================================================================
SELECT 'Transaction Data Quality Issues' AS test_category;

WITH transaction_quality AS (
    SELECT 
        DATA:data:input:payload:applicationId::varchar AS application_id,
        transaction.value AS transaction_data
    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
    LATERAL FLATTEN(input => GET_PATH(DATA, 'data.integrations[3].response.items[0].accounts[0].transactions')) transaction
    WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
    LIMIT 1000  -- Sample for performance
)
SELECT 
    'Missing Transaction ID' AS issue_type,
    COUNT(*) AS affected_transactions
FROM transaction_quality
WHERE transaction_data:transaction_id IS NULL

UNION ALL

SELECT 
    'Missing Amount' AS issue_type,
    COUNT(*) AS affected_transactions
FROM transaction_quality
WHERE transaction_data:amount IS NULL

UNION ALL

SELECT 
    'Missing Date' AS issue_type,
    COUNT(*) AS affected_transactions
FROM transaction_quality
WHERE transaction_data:date IS NULL

UNION ALL

SELECT 
    'Missing Description' AS issue_type,
    COUNT(*) AS affected_transactions
FROM transaction_quality
WHERE transaction_data:name IS NULL

UNION ALL

SELECT 
    'Zero Amount Transactions' AS issue_type,
    COUNT(*) AS affected_transactions
FROM transaction_quality
WHERE transaction_data:amount::float = 0.0

ORDER BY affected_transactions DESC;