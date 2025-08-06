-- Performance test for both views
-- Testing with minimal data retrieval

-- Test 1: Can we get even 1 row from FRESHSNOW?
SELECT 'FRESHSNOW Test' as TEST_NAME, COUNT(*) as ROW_COUNT
FROM (
    SELECT 1 
    FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION_DETAIL 
    LIMIT 1
) t

UNION ALL

-- Test 2: Can we get even 1 row from DATA_STORE?
SELECT 'DATA_STORE Test' as TEST_NAME, COUNT(*) as ROW_COUNT
FROM (
    SELECT 1 
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_TRANSACTION_DETAIL 
    LIMIT 1
) t;