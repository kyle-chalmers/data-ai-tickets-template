-- Customer Segmentation Analysis
-- Purpose: Identify high-value customer segments and purchasing patterns

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
),
customer_segments AS (
    SELECT
        *,
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
)
SELECT
    value_segment,
    activity_segment,
    region,
    COUNT(*) as customer_count,
    SUM(total_revenue) as segment_revenue,
    ROUND(AVG(total_orders), 2) as avg_orders_per_customer,
    ROUND(AVG(avg_order_value), 2) as avg_order_value,
    ROUND(SUM(total_revenue) / SUM(total_orders), 2) as segment_avg_order_value
FROM customer_segments
GROUP BY value_segment, activity_segment, region
ORDER BY segment_revenue DESC;
