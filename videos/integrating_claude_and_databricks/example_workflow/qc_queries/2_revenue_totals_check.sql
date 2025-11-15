-- Revenue Totals Check
-- Purpose: Verify revenue calculations match source data

WITH source_revenue AS (
    SELECT
        SUM(order_amount) as total_revenue,
        COUNT(DISTINCT customer_id) as customer_count,
        COUNT(DISTINCT order_id) as order_count
    FROM main.analytics.customer_orders
    WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
),
analysis_revenue AS (
    SELECT
        SUM(total_revenue) as total_revenue,
        COUNT(DISTINCT customer_id) as customer_count,
        SUM(total_orders) as order_count
    FROM (
        SELECT
            customer_id,
            SUM(order_amount) as total_revenue,
            COUNT(DISTINCT order_id) as total_orders
        FROM main.analytics.customer_orders
        WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
        GROUP BY customer_id
    )
)
SELECT
    'Source' as source_type,
    ROUND(s.total_revenue, 2) as total_revenue,
    s.customer_count,
    s.order_count
FROM source_revenue s

UNION ALL

SELECT
    'Analysis' as source_type,
    ROUND(a.total_revenue, 2) as total_revenue,
    a.customer_count,
    a.order_count
FROM analysis_revenue a;

-- Expected: Both rows should have identical values
-- If different, investigate data transformation logic
