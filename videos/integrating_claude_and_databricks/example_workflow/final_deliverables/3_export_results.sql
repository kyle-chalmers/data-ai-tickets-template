-- Export Customer Segmentation Results
-- Purpose: Final query optimized for CSV export

WITH customer_metrics AS (
    SELECT
        customer_id,
        region,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(order_amount) as total_revenue,
        AVG(order_amount) as avg_order_value,
        MAX(order_date) as last_order_date,
        DATEDIFF(CURRENT_DATE(), MAX(order_date)) as days_since_last_order
    FROM main.analytics.customer_orders
    WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
    GROUP BY customer_id, region
)
SELECT
    customer_id,
    region,
    total_orders,
    ROUND(total_revenue, 2) as total_revenue,
    ROUND(avg_order_value, 2) as avg_order_value,
    last_order_date,
    days_since_last_order,
    CASE
        WHEN total_revenue >= 10000 THEN 'High Value'
        WHEN total_revenue >= 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END as value_segment,
    CASE
        WHEN days_since_last_order <= 30 THEN 'Active'
        WHEN days_since_last_order <= 90 THEN 'At Risk'
        ELSE 'Churned'
    END as activity_segment
FROM customer_metrics
ORDER BY total_revenue DESC;
