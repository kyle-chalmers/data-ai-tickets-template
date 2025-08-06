-- DI-1143: Filter Redundancy Analysis
-- Testing if the three-part filter is truly necessary or if we can simplify

-- ============================================================================
-- TEST 1: Count with each individual filter
-- ============================================================================

-- A) Only string contains check
SELECT 'String Contains Only' AS filter_type, COUNT(*) AS record_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE CONTAINS(DATA::string, 'plaidAccessToken');

-- B) Only NOT NULL check  
SELECT 'NOT NULL Only' AS filter_type, COUNT(*) AS record_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:input:payload:plaidAccessTokens IS NOT NULL;

-- C) Only array size check (this will error if field doesn't exist)
SELECT 'Array Size Only (with NULL safety)' AS filter_type, COUNT(*) AS record_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
  AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0;

-- D) Current triple filter (baseline)
SELECT 'Current Triple Filter' AS filter_type, COUNT(*) AS record_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE CONTAINS(DATA::string, 'plaidAccessToken')
  AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
  AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0;

-- ============================================================================
-- TEST 2: What does each filter exclude?
-- ============================================================================

-- Find records that have the string but NULL array
SELECT 'Has String but NULL Array' AS exclusion_type, COUNT(*) AS excluded_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE CONTAINS(DATA::string, 'plaidAccessToken')
  AND DATA:data:input:payload:plaidAccessTokens IS NULL;

-- Find records that have NOT NULL array but size = 0
SELECT 'NOT NULL but Empty Array' AS exclusion_type, COUNT(*) AS excluded_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
  AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) = 0;

-- Find records that pass NOT NULL + size > 0 but fail string contains
SELECT 'Array Valid but No String Match' AS exclusion_type, COUNT(*) AS excluded_count
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
  AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0
  AND NOT CONTAINS(DATA::string, 'plaidAccessToken');

-- ============================================================================
-- TEST 3: Performance comparison
-- ============================================================================

-- Test execution time for each approach (run individually)
/*
-- Option A: Just NOT NULL + Array Size
SELECT COUNT(*) 
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
  AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0;

-- Option B: Current triple filter  
SELECT COUNT(*) 
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE CONTAINS(DATA::string, 'plaidAccessToken')
  AND DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
  AND ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) > 0;
*/

-- ============================================================================
-- TEST 4: Sample data inspection
-- ============================================================================

-- Look at a few records that might differ between approaches
SELECT 
    'Sample Records Analysis' AS analysis_type,
    DATA:data:input:payload:plaidAccessTokens,
    CONTAINS(DATA::string, 'plaidAccessToken') AS has_string,
    DATA:data:input:payload:plaidAccessTokens IS NOT NULL AS is_not_null,
    CASE 
        WHEN DATA:data:input:payload:plaidAccessTokens IS NOT NULL 
        THEN ARRAY_SIZE(DATA:data:input:payload:plaidAccessTokens) 
        ELSE NULL 
    END AS array_size
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE CONTAINS(DATA::string, 'plaidAccessToken')
   OR DATA:data:input:payload:plaidAccessTokens IS NOT NULL
LIMIT 10;