/*
    QC VALIDATION: VW_CUSTOMER_ORDER_SUMMARY
    Target: ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY

    Run all tests sequentially and verify results.
    All tests should show PASS status.
*/

--1.1: Record Count Validation
-- Expected: 9,999,832 rows (customers with orders)
SELECT 'Record Count' AS test_name,
       COUNT(*) AS actual_count,
       9999832 AS expected_count,
       CASE WHEN COUNT(*) BETWEEN 9900000 AND 10100000 THEN 'PASS' ELSE 'REVIEW' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY;

--1.2: Duplicate Check on Primary Key
-- Expected: 0 duplicates
SELECT 'Duplicate Check' AS test_name,
       COUNT(*) AS duplicate_count,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM (
    SELECT C_CUSTKEY, COUNT(*) AS cnt
    FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
    GROUP BY C_CUSTKEY
    HAVING COUNT(*) > 1
);

--1.3: Null Check on Required Fields
SELECT 'Null Check' AS test_name,
       SUM(CASE WHEN C_CUSTKEY IS NULL THEN 1 ELSE 0 END) AS null_custkey,
       SUM(CASE WHEN TOTAL_ORDERS IS NULL THEN 1 ELSE 0 END) AS null_orders,
       SUM(CASE WHEN TOTAL_REVENUE IS NULL THEN 1 ELSE 0 END) AS null_revenue,
       SUM(CASE WHEN NATION_NAME IS NULL THEN 1 ELSE 0 END) AS null_nation,
       SUM(CASE WHEN REGION_NAME IS NULL THEN 1 ELSE 0 END) AS null_region
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY;

--2.1: Market Segment Distribution
-- Expected: 5 segments with ~20% each
SELECT 'Market Segment' AS test_name,
       C_MKTSEGMENT,
       COUNT(*) AS customer_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
GROUP BY C_MKTSEGMENT
ORDER BY C_MKTSEGMENT;

--2.2: Region Distribution
-- Expected: 5 regions with ~20% each
SELECT 'Region' AS test_name,
       REGION_NAME,
       COUNT(*) AS customer_count,
       ROUND(SUM(TOTAL_REVENUE), 2) AS total_revenue
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
GROUP BY REGION_NAME
ORDER BY REGION_NAME;

--3.1: Date Range Validation
SELECT 'Date Range' AS test_name,
       MIN(FIRST_ORDER_DATE) AS min_first_order,
       MAX(LAST_ORDER_DATE) AS max_last_order,
       CASE WHEN MIN(FIRST_ORDER_DATE) = '1992-01-01'
             AND MAX(LAST_ORDER_DATE) = '1998-08-02' THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY;

--3.2: No Zero Orders Check
SELECT 'No Zero Orders' AS test_name,
       COUNT(*) AS zero_order_customers,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
WHERE TOTAL_ORDERS = 0 OR TOTAL_ORDERS IS NULL;

--3.3: AVG_ORDER_VALUE Calculation Check
SELECT 'AVG Calculation' AS test_name,
       COUNT(*) AS mismatches,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
WHERE ABS(AVG_ORDER_VALUE - ROUND(TOTAL_REVENUE / TOTAL_ORDERS, 2)) > 0.01;

--4.1: Sample Data Verification
SELECT 'Sample Data' AS test_name, *
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
LIMIT 5;
