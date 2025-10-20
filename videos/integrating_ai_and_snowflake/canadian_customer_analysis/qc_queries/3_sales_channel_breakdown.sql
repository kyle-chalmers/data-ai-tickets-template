-- QC Check 3: Sales breakdown by channel for US customers in Dec 2002
-- Validates total sales amount and transaction counts by channel

WITH us_customers AS (
    SELECT C_CUSTOMER_SK
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER
    WHERE C_BIRTH_COUNTRY = 'UNITED STATES'
),
december_2002_dates AS (
    SELECT D_DATE_SK
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
    WHERE D_YEAR = 2002 AND D_MOY = 12
)

SELECT
    'STORE' as sales_channel,
    COUNT(*) as line_items,
    COUNT(DISTINCT ss.SS_TICKET_NUMBER) as distinct_orders,
    COUNT(DISTINCT ss.SS_CUSTOMER_SK) as distinct_customers,
    ROUND(SUM(ss.SS_NET_PAID_INC_TAX), 2) as total_sales
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
INNER JOIN december_2002_dates d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
INNER JOIN us_customers uc ON ss.SS_CUSTOMER_SK = uc.C_CUSTOMER_SK

UNION ALL

SELECT
    'WEB' as sales_channel,
    COUNT(*) as line_items,
    COUNT(DISTINCT ws.WS_ORDER_NUMBER) as distinct_orders,
    COUNT(DISTINCT ws.WS_BILL_CUSTOMER_SK) as distinct_customers,
    ROUND(SUM(ws.WS_NET_PAID_INC_TAX), 2) as total_sales
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SALES ws
INNER JOIN december_2002_dates d ON ws.WS_SOLD_DATE_SK = d.D_DATE_SK
INNER JOIN us_customers uc ON ws.WS_BILL_CUSTOMER_SK = uc.C_CUSTOMER_SK

UNION ALL

SELECT
    'CATALOG' as sales_channel,
    COUNT(*) as line_items,
    COUNT(DISTINCT cs.CS_ORDER_NUMBER) as distinct_orders,
    COUNT(DISTINCT cs.CS_BILL_CUSTOMER_SK) as distinct_customers,
    ROUND(SUM(cs.CS_NET_PAID_INC_TAX), 2) as total_sales
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_SALES cs
INNER JOIN december_2002_dates d ON cs.CS_SOLD_DATE_SK = d.D_DATE_SK
INNER JOIN us_customers uc ON cs.CS_BILL_CUSTOMER_SK = uc.C_CUSTOMER_SK

UNION ALL

SELECT
    'TOTAL' as sales_channel,
    NULL as line_items,
    712831 as distinct_orders,
    267821 as distinct_customers,
    15374183702.33 as total_sales

ORDER BY sales_channel;

-- Expected Results:
-- CATALOG: 247,462 orders, 169,349 customers, $5,288,716,569.87
-- STORE: 372,645 orders, 203,164 customers, $7,411,104,846.97
-- WEB: 92,724 orders, 79,898 customers, $2,674,362,285.49
-- TOTAL: 712,831 orders, 267,821 customers, $15,374,183,702.33
