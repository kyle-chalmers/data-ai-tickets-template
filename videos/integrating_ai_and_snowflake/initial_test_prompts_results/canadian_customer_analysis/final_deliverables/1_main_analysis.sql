-- US CUSTOMER PURCHASE ANALYSIS
-- Analysis Period: December 2002 (most recent complete calendar month in sample data)
-- Data Source: SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL
--
-- Business Question:
-- 1. How many customers are from the United States?
-- 2. How many bought something in the last month (December 2002)?
-- 3. What was the average transaction price?
-- 4. What was the total amount?
--
-- Methodology:
-- - Identified US customers using C_BIRTH_COUNTRY = 'UNITED STATES'
-- - Combined all sales channels (STORE, WEB, CATALOG)
-- - Grouped by order/ticket number to calculate per-transaction totals
-- - Filtered for December 2002 (last complete month in data: 2002-12-01 to 2002-12-31)

WITH us_customers AS (
    -- Identify all US customers (297,366 total)
    SELECT C_CUSTOMER_SK
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER
    WHERE C_BIRTH_COUNTRY = 'UNITED STATES'
),

december_2002_dates AS (
    -- Get date keys for December 2002 (31 days)
    SELECT D_DATE_SK
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
    WHERE D_YEAR = 2002 AND D_MOY = 12
),

all_sales AS (
    -- STORE SALES
    SELECT
        'STORE' as sales_channel,
        ss.SS_CUSTOMER_SK as customer_sk,
        ss.SS_TICKET_NUMBER as order_number,
        ss.SS_NET_PAID_INC_TAX as transaction_amount
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
    INNER JOIN december_2002_dates d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
    INNER JOIN us_customers uc ON ss.SS_CUSTOMER_SK = uc.C_CUSTOMER_SK

    UNION ALL

    -- WEB SALES
    SELECT
        'WEB' as sales_channel,
        ws.WS_BILL_CUSTOMER_SK as customer_sk,
        ws.WS_ORDER_NUMBER as order_number,
        ws.WS_NET_PAID_INC_TAX as transaction_amount
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SALES ws
    INNER JOIN december_2002_dates d ON ws.WS_SOLD_DATE_SK = d.D_DATE_SK
    INNER JOIN us_customers uc ON ws.WS_BILL_CUSTOMER_SK = uc.C_CUSTOMER_SK

    UNION ALL

    -- CATALOG SALES
    SELECT
        'CATALOG' as sales_channel,
        cs.CS_BILL_CUSTOMER_SK as customer_sk,
        cs.CS_ORDER_NUMBER as order_number,
        cs.CS_NET_PAID_INC_TAX as transaction_amount
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_SALES cs
    INNER JOIN december_2002_dates d ON cs.CS_SOLD_DATE_SK = d.D_DATE_SK
    INNER JOIN us_customers uc ON cs.CS_BILL_CUSTOMER_SK = uc.C_CUSTOMER_SK
),

order_totals AS (
    -- Group by order/ticket to get per-transaction totals
    -- Each order can have multiple line items that need to be summed
    SELECT
        sales_channel,
        customer_sk,
        order_number,
        SUM(transaction_amount) as order_total
    FROM all_sales
    GROUP BY sales_channel, customer_sk, order_number
),

us_metrics AS (
    -- Calculate final metrics
    SELECT
        (SELECT COUNT(*) FROM us_customers) as total_us_customers,
        COUNT(DISTINCT customer_sk) as us_customers_with_purchases,
        COUNT(*) as total_transactions,
        AVG(order_total) as avg_transaction_price,
        SUM(order_total) as total_amount
    FROM order_totals
)

-- Final Results
SELECT
    total_us_customers,
    us_customers_with_purchases,
    total_transactions,
    ROUND(avg_transaction_price, 2) as avg_transaction_price,
    ROUND(total_amount, 2) as total_amount
FROM us_metrics;
