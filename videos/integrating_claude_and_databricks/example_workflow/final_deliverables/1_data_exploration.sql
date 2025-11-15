-- Data Exploration Query
-- Purpose: Understand data structure and quality in Unity Catalog

-- Check customer distribution by region
SELECT
    region,
    COUNT(DISTINCT customer_id) as customer_count,
    COUNT(DISTINCT order_id) as order_count,
    SUM(order_amount) as total_revenue
FROM main.analytics.customer_orders
GROUP BY region
ORDER BY customer_count DESC;

-- Check date range of data
SELECT
    MIN(order_date) as earliest_order,
    MAX(order_date) as latest_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) as days_of_data,
    COUNT(DISTINCT order_date) as unique_dates
FROM main.analytics.customer_orders;

-- Sample data review
SELECT *
FROM main.analytics.customer_orders
LIMIT 10;

-- Check for data quality issues
SELECT
    'Null Customer IDs' as issue,
    COUNT(*) as count
FROM main.analytics.customer_orders
WHERE customer_id IS NULL

UNION ALL

SELECT
    'Null Order Amounts',
    COUNT(*)
FROM main.analytics.customer_orders
WHERE order_amount IS NULL

UNION ALL

SELECT
    'Negative Order Amounts',
    COUNT(*)
FROM main.analytics.customer_orders
WHERE order_amount < 0;
