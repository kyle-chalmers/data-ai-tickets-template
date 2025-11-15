-- Record Count Validation
-- Purpose: Ensure no data loss in transformations

-- Source data counts
SELECT 'Source Customer Orders' as check_name, COUNT(*) as record_count
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)

UNION ALL

-- Distinct customers in analysis
SELECT 'Distinct Customers', COUNT(DISTINCT customer_id)
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)

UNION ALL

-- Distinct orders in analysis
SELECT 'Distinct Orders', COUNT(DISTINCT order_id)
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)

UNION ALL

-- Orders with valid amounts
SELECT 'Valid Order Amounts', COUNT(*)
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
  AND order_amount > 0

UNION ALL

-- Records with null customer_id (data quality issue)
SELECT 'Null Customer IDs', COUNT(*)
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
  AND customer_id IS NULL;
