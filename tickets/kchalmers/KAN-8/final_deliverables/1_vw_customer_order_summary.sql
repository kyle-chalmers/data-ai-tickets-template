/*
    VW_CUSTOMER_ORDER_SUMMARY

    Purpose: Customer-level order activity summary for segmentation,
             regional analysis, and revenue reporting.

    Grain: One row per customer (customers with orders only)
    Source: SNOWFLAKE_SAMPLE_DATA.TPCH_SF100
    Expected Rows: ~9,999,832

    Business Logic:
    - Excludes customers with no orders (INNER JOIN)
    - Revenue = L_EXTENDEDPRICE * (1 - L_DISCOUNT) (net of discount)
    - Aggregates all historical orders per customer

    Output Columns:
    - C_CUSTKEY: Customer identifier (primary key)
    - C_NAME: Customer name
    - C_MKTSEGMENT: Market segment (AUTOMOBILE, BUILDING, FURNITURE, HOUSEHOLD, MACHINERY)
    - C_ACCTBAL: Account balance
    - NATION_NAME: Customer nation
    - REGION_NAME: Customer region (AFRICA, AMERICA, ASIA, EUROPE, MIDDLE EAST)
    - TOTAL_ORDERS: Count of orders
    - TOTAL_REVENUE: Net revenue (extended price minus discount)
    - AVG_ORDER_VALUE: Average revenue per order
    - FIRST_ORDER_DATE: Date of first order
    - LAST_ORDER_DATE: Date of most recent order
*/

CREATE OR REPLACE VIEW ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY AS
WITH customer_orders AS (
    SELECT
        o.O_CUSTKEY,
        o.O_ORDERKEY,
        o.O_ORDERDATE,
        SUM(l.L_EXTENDEDPRICE * (1 - l.L_DISCOUNT)) AS order_revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
        ON o.O_ORDERKEY = l.L_ORDERKEY
    GROUP BY o.O_CUSTKEY, o.O_ORDERKEY, o.O_ORDERDATE
),

customer_metrics AS (
    SELECT
        O_CUSTKEY,
        COUNT(DISTINCT O_ORDERKEY) AS total_orders,
        SUM(order_revenue) AS total_revenue,
        MIN(O_ORDERDATE) AS first_order_date,
        MAX(O_ORDERDATE) AS last_order_date
    FROM customer_orders
    GROUP BY O_CUSTKEY
)

SELECT
    c.C_CUSTKEY,
    c.C_NAME,
    c.C_MKTSEGMENT,
    c.C_ACCTBAL,
    n.N_NAME AS NATION_NAME,
    r.R_NAME AS REGION_NAME,
    cm.total_orders AS TOTAL_ORDERS,
    cm.total_revenue AS TOTAL_REVENUE,
    ROUND(cm.total_revenue / cm.total_orders, 2) AS AVG_ORDER_VALUE,
    cm.first_order_date AS FIRST_ORDER_DATE,
    cm.last_order_date AS LAST_ORDER_DATE
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c
INNER JOIN customer_metrics cm
    ON c.C_CUSTKEY = cm.O_CUSTKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n
    ON c.C_NATIONKEY = n.N_NATIONKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION r
    ON n.N_REGIONKEY = r.R_REGIONKEY;
