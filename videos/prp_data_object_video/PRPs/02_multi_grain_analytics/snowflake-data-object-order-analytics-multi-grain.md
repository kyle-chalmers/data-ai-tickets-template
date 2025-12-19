# PRP: Multi-Grain Order Analytics Dynamic Table

## Table of Contents

- [Executive Summary](#executive-summary)
- [Business Requirements](#business-requirements)
- [Technical Specifications](#technical-specifications)
- [Database Schema Analysis](#database-schema-analysis)
- [Data Relationships and Join Validation](#data-relationships-and-join-validation)
- [Implementation Blueprint](#implementation-blueprint)
- [Multi-Grain Architecture Pattern](#multi-grain-architecture-pattern)
- [Dynamic Table DDL](#dynamic-table-ddl)
- [Quality Control Validation Plan](#quality-control-validation-plan)
- [Production Deployment](#production-deployment)
- [Confidence Assessment](#confidence-assessment)

---

## Executive Summary

**Object Name:** `DT_ORDER_ANALYTICS_MULTI_GRAIN`
**Object Type:** DYNAMIC_TABLE
**Operation:** CREATE_NEW
**Scope:** SINGLE_OBJECT
**Target Schema:** `ANALYTICS.DEVELOPMENT` (development), `ANALYTICS.PRODUCTION` (production)
**Expected Ticket Folder:** `tickets/kylechalmers/[TICKET-ID]/`

**Purpose:** Create a comprehensive analytics dynamic table that enables analysis at multiple aggregation levels without requiring users to write complex SQL. The table maintains line-item grain (finest level) while enriching each row with order-level, customer-level, and regional-level aggregations.

**Key Challenge:** Implementing a multi-grain pattern that joins 600M+ line items with pre-aggregated metrics at coarser grains without causing fan-out issues.

---

## Business Requirements

### Primary Use Cases
1. **Analysts** need line-item detail while seeing order and customer context in the same row
2. **Regional managers** want individual transactions with performance rankings to compare customers
3. **Finance** needs transaction-level data with roll-up metrics for reconciliation

### Key Metrics/KPIs

| Level | Metrics |
|-------|---------|
| **Line-Item** | L_QUANTITY, L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS |
| **Order** | ORDER_TOTAL, ORDER_LINE_COUNT, ORDER_AVG_LINE_VALUE |
| **Customer** | CUSTOMER_LIFETIME_VALUE, CUSTOMER_TOTAL_ORDERS, CUSTOMER_AVG_ORDER_VALUE, CUSTOMER_RANK_IN_REGION |
| **Regional** | CUSTOMER_PCT_OF_REGIONAL_REVENUE |

### Business Rules (Confirmed)
- **Regional Revenue %**: Customer lifetime value divided by total regional revenue
- **Fulfilled Orders Only**: Only orders with `O_ORDERSTATUS = 'F'` included in customer/regional metrics
- **Code Values**: Keep raw codes (R, A, N, F, O, P) without business-friendly labels
- **Part/Supplier Details**: Include P_BRAND, P_TYPE, P_CONTAINER, and supplier nation

### Performance Requirements
- **Dynamic Table Lag:** 1 hour (`TARGET_LAG = '1 hour'`)
- **Warehouse:** `COMPUTE_EXTRA_SMALL` (X-Small)
- **Data Retention:** All historical orders

---

## Technical Specifications

### Source Tables

| Table | Database.Schema | Row Count | Purpose |
|-------|-----------------|-----------|---------|
| LINEITEM | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 600,037,902 | Primary grain - individual line items |
| ORDERS | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 150,000,000 | Order header and status |
| CUSTOMER | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 15,000,000 | Customer dimension |
| NATION | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 25 | Nation reference |
| REGION | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 5 | Region reference |
| PART | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 20,000,000 | Part details |
| SUPPLIER | SNOWFLAKE_SAMPLE_DATA.TPCH_SF100 | 1,000,000 | Supplier details |

### Table Structures

**LINEITEM (Primary Grain)**
```
L_ORDERKEY      NUMBER(38,0)   -- FK to ORDERS
L_PARTKEY       NUMBER(38,0)   -- FK to PART
L_SUPPKEY       NUMBER(38,0)   -- FK to SUPPLIER
L_LINENUMBER    NUMBER(38,0)   -- Line sequence within order
L_QUANTITY      NUMBER(12,2)   -- Quantity ordered
L_EXTENDEDPRICE NUMBER(12,2)   -- Extended price
L_DISCOUNT      NUMBER(12,2)   -- Discount percentage
L_TAX           NUMBER(12,2)   -- Tax percentage
L_RETURNFLAG    VARCHAR(1)     -- R=Returned, A=Accepted, N=None
L_LINESTATUS    VARCHAR(1)     -- F=Fulfilled, O=Open
L_SHIPDATE      DATE           -- Ship date
L_COMMITDATE    DATE           -- Commit date
L_RECEIPTDATE   DATE           -- Receipt date
L_SHIPINSTRUCT  VARCHAR(25)    -- Shipping instructions
L_SHIPMODE      VARCHAR(10)    -- Shipping mode
L_COMMENT       VARCHAR(44)    -- Comment
```

**ORDERS**
```
O_ORDERKEY      NUMBER(38,0)   -- PK
O_CUSTKEY       NUMBER(38,0)   -- FK to CUSTOMER
O_ORDERSTATUS   VARCHAR(1)     -- O=Open, F=Fulfilled, P=Pending
O_TOTALPRICE    NUMBER(12,2)   -- Order total price
O_ORDERDATE     DATE           -- Order date
O_ORDERPRIORITY VARCHAR(15)    -- Priority level
O_CLERK         VARCHAR(15)    -- Clerk ID
O_SHIPPRIORITY  NUMBER(38,0)   -- Shipping priority
O_COMMENT       VARCHAR(79)    -- Comment
```

**CUSTOMER**
```
C_CUSTKEY       NUMBER(38,0)   -- PK
C_NAME          VARCHAR(25)    -- Customer name
C_ADDRESS       VARCHAR(40)    -- Address
C_NATIONKEY     NUMBER(38,0)   -- FK to NATION
C_PHONE         VARCHAR(15)    -- Phone
C_ACCTBAL       NUMBER(12,2)   -- Account balance
C_MKTSEGMENT    VARCHAR(10)    -- Market segment (BUILDING, FURNITURE, HOUSEHOLD, MACHINERY, AUTOMOBILE)
C_COMMENT       VARCHAR(117)   -- Comment
```

**NATION**
```
N_NATIONKEY     NUMBER(38,0)   -- PK
N_NAME          VARCHAR(25)    -- Nation name (25 nations)
N_REGIONKEY     NUMBER(38,0)   -- FK to REGION
N_COMMENT       VARCHAR(152)   -- Comment
```

**REGION**
```
R_REGIONKEY     NUMBER(38,0)   -- PK
R_NAME          VARCHAR(25)    -- Region name (AFRICA, AMERICA, ASIA, EUROPE, MIDDLE EAST)
R_COMMENT       VARCHAR(152)   -- Comment
```

**PART**
```
P_PARTKEY       NUMBER(38,0)   -- PK
P_NAME          VARCHAR(55)    -- Part name
P_MFGR          VARCHAR(25)    -- Manufacturer
P_BRAND         VARCHAR(10)    -- Brand
P_TYPE          VARCHAR(25)    -- Type
P_SIZE          NUMBER(38,0)   -- Size
P_CONTAINER     VARCHAR(10)    -- Container type
P_RETAILPRICE   NUMBER(12,2)   -- Retail price
P_COMMENT       VARCHAR(23)    -- Comment
```

**SUPPLIER**
```
S_SUPPKEY       NUMBER(38,0)   -- PK
S_NAME          VARCHAR(25)    -- Supplier name
S_ADDRESS       VARCHAR(40)    -- Address
S_NATIONKEY     NUMBER(38,0)   -- FK to NATION
S_PHONE         VARCHAR(15)    -- Phone
S_ACCTBAL       NUMBER(12,2)   -- Account balance
S_COMMENT       VARCHAR(101)   -- Comment
```

---

## Data Relationships and Join Validation

### Relationship Diagram
```
LINEITEM (600M) ──┬── many:1 ──► ORDERS (150M) ──── many:1 ──► CUSTOMER (15M)
                  │                                              │
                  │                                              ▼
                  │                                         NATION (25)
                  │                                              │
                  │                                              ▼
                  │                                         REGION (5)
                  │
                  ├── many:1 ──► PART (20M)
                  │
                  └── many:1 ──► SUPPLIER (1M) ──── many:1 ──► NATION (25)
```

### Join Integrity Validation Results
All joins validated with **zero orphan records**:

| Join | Orphan Count |
|------|--------------|
| LINEITEM → ORDERS | 0 |
| ORDERS → CUSTOMER | 0 |
| CUSTOMER → NATION | 0 |
| NATION → REGION | 0 |
| LINEITEM → PART | 0 |
| LINEITEM → SUPPLIER | 0 |

### Grain Analysis
- **Lines per Order:** Min=1, Max=7, Avg=4, Median=4
- **Orders per Customer:** Min=1, Max=44, Avg=15, Median=14
- **Expected Output Rows:** ~600M (same as LINEITEM base grain)

---

## Implementation Blueprint

### Architecture Strategy

The multi-grain pattern uses **pre-aggregated CTEs** joined back to the base grain to avoid fan-out:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MULTI-GRAIN ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CTE 1: order_metrics          CTE 2: customer_metrics                      │
│  ┌──────────────────┐          ┌──────────────────────┐                     │
│  │ Grain: ORDER     │          │ Grain: CUSTOMER      │                     │
│  │ - ORDER_TOTAL    │          │ - LIFETIME_VALUE     │                     │
│  │ - LINE_COUNT     │          │ - TOTAL_ORDERS       │                     │
│  │ - AVG_LINE_VALUE │          │ - AVG_ORDER_VALUE    │                     │
│  └────────┬─────────┘          └──────────┬───────────┘                     │
│           │                               │                                  │
│           │     CTE 3: regional_metrics   │                                  │
│           │     ┌─────────────────────┐   │                                  │
│           │     │ Grain: REGION       │   │                                  │
│           │     │ - TOTAL_REVENUE     │   │                                  │
│           │     └──────────┬──────────┘   │                                  │
│           │                │              │                                  │
│           │     CTE 4: customer_rankings  │                                  │
│           │     ┌─────────────────────┐   │                                  │
│           │     │ Grain: CUSTOMER     │   │                                  │
│           │     │ - RANK_IN_REGION    │   │                                  │
│           │     │ - PCT_OF_REGIONAL   │   │                                  │
│           │     └──────────┬──────────┘   │                                  │
│           │                │              │                                  │
│           ▼                ▼              ▼                                  │
│  ┌───────────────────────────────────────────────────────────────────┐      │
│  │                    FINAL SELECT                                    │      │
│  │  Base: LINEITEM (600M rows) joined to all CTEs                    │      │
│  │  Output: Line-item grain with all aggregated metrics              │      │
│  └───────────────────────────────────────────────────────────────────┘      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Critical Implementation Notes

1. **Pre-aggregate before joining**: Calculate order/customer/regional metrics in CTEs BEFORE joining to line items
2. **Filter fulfilled orders**: Apply `O_ORDERSTATUS = 'F'` filter in customer and regional metrics CTEs
3. **Use INNER JOINs for metrics**: Ensures only line items with fulfilled orders appear in output
4. **Window functions in CTE**: Calculate RANK() and PCT in a dedicated CTE, not in final SELECT
5. **Customer metrics repeated at line-item grain**: Customer-level metrics (LTV, rank, regional %) appear on every line item for that customer. Analysts must use `COUNT(DISTINCT C_CUSTKEY)` or filter to one row per customer when aggregating these values

### Expected Output Columns

| Column | Source | Description |
|--------|--------|-------------|
| **Line-Item Level** |||
| L_ORDERKEY | LINEITEM | Order key (PK part 1) |
| L_LINENUMBER | LINEITEM | Line number (PK part 2) |
| L_PARTKEY | LINEITEM | Part key |
| L_SUPPKEY | LINEITEM | Supplier key |
| L_QUANTITY | LINEITEM | Quantity |
| L_EXTENDEDPRICE | LINEITEM | Extended price |
| L_DISCOUNT | LINEITEM | Discount |
| L_TAX | LINEITEM | Tax |
| L_RETURNFLAG | LINEITEM | Return flag (R/A/N) |
| L_LINESTATUS | LINEITEM | Line status (F/O) |
| L_SHIPDATE | LINEITEM | Ship date |
| L_COMMITDATE | LINEITEM | Commit date |
| L_RECEIPTDATE | LINEITEM | Receipt date |
| L_SHIPINSTRUCT | LINEITEM | Ship instructions |
| L_SHIPMODE | LINEITEM | Ship mode |
| **Part Details** |||
| PART_NAME | PART | Part name |
| PART_BRAND | PART | Part brand |
| PART_TYPE | PART | Part type |
| PART_CONTAINER | PART | Part container |
| **Supplier Details** |||
| SUPPLIER_NAME | SUPPLIER | Supplier name |
| SUPPLIER_NATION | NATION (via SUPPLIER) | Supplier's nation |
| **Order Level** |||
| O_ORDERDATE | ORDERS | Order date |
| O_ORDERSTATUS | ORDERS | Order status (O/F/P) |
| O_ORDERPRIORITY | ORDERS | Order priority |
| ORDER_TOTAL | Calculated | Sum of line extended prices for order |
| ORDER_LINE_COUNT | Calculated | Count of lines in order |
| ORDER_AVG_LINE_VALUE | Calculated | ORDER_TOTAL / ORDER_LINE_COUNT |
| **Customer Level** |||
| C_CUSTKEY | CUSTOMER | Customer key |
| CUSTOMER_NAME | CUSTOMER | Customer name |
| CUSTOMER_SEGMENT | CUSTOMER | Market segment |
| CUSTOMER_LIFETIME_VALUE | Calculated | Sum of all fulfilled order totals |
| CUSTOMER_TOTAL_ORDERS | Calculated | Count of fulfilled orders |
| CUSTOMER_AVG_ORDER_VALUE | Calculated | LTV / Total Orders |
| **Geographic** |||
| NATION_NAME | NATION | Customer's nation |
| REGION_NAME | REGION | Customer's region |
| **Regional Rankings** |||
| CUSTOMER_RANK_IN_REGION | Calculated | Rank by LTV within region |
| CUSTOMER_PCT_OF_REGIONAL_REVENUE | Calculated | Customer LTV / Regional Total Revenue |

---

## Multi-Grain Architecture Pattern

### CTE Structure

```sql
-- CTE 1: Order-level metrics (pre-aggregated)
WITH order_metrics AS (
    SELECT
        L_ORDERKEY,
        SUM(L_EXTENDEDPRICE) AS ORDER_TOTAL,
        COUNT(*) AS ORDER_LINE_COUNT,
        AVG(L_EXTENDEDPRICE) AS ORDER_AVG_LINE_VALUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM
    GROUP BY L_ORDERKEY
),

-- CTE 2: Customer-level metrics (fulfilled orders only)
customer_metrics AS (
    SELECT
        o.O_CUSTKEY,
        SUM(o.O_TOTALPRICE) AS CUSTOMER_LIFETIME_VALUE,
        COUNT(DISTINCT o.O_ORDERKEY) AS CUSTOMER_TOTAL_ORDERS,
        AVG(o.O_TOTALPRICE) AS CUSTOMER_AVG_ORDER_VALUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    WHERE o.O_ORDERSTATUS = 'F'  -- Fulfilled orders only
    GROUP BY o.O_CUSTKEY
),

-- CTE 3: Regional totals (for percentage calculation)
regional_totals AS (
    SELECT
        r.R_REGIONKEY,
        r.R_NAME AS REGION_NAME,
        SUM(o.O_TOTALPRICE) AS REGIONAL_TOTAL_REVENUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
    WHERE o.O_ORDERSTATUS = 'F'  -- Fulfilled orders only
    GROUP BY r.R_REGIONKEY, r.R_NAME
),

-- CTE 4: Customer rankings within region
customer_rankings AS (
    SELECT
        c.C_CUSTKEY,
        n.N_REGIONKEY,
        cm.CUSTOMER_LIFETIME_VALUE,
        rt.REGIONAL_TOTAL_REVENUE,
        RANK() OVER (PARTITION BY n.N_REGIONKEY ORDER BY cm.CUSTOMER_LIFETIME_VALUE DESC) AS CUSTOMER_RANK_IN_REGION,
        ROUND(cm.CUSTOMER_LIFETIME_VALUE / rt.REGIONAL_TOTAL_REVENUE * 100, 6) AS CUSTOMER_PCT_OF_REGIONAL_REVENUE
    FROM customer_metrics cm
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON cm.O_CUSTKEY = c.C_CUSTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN regional_totals rt ON n.N_REGIONKEY = rt.R_REGIONKEY
)

-- Final SELECT joins all grains
SELECT ...
```

---

## Dynamic Table DDL

### Development Environment

```sql
-- ============================================================================
-- DYNAMIC TABLE: DT_ORDER_ANALYTICS_MULTI_GRAIN
-- Purpose: Multi-grain analytics combining line-item detail with aggregations
-- Target Schema: ANALYTICS.DEVELOPMENT
-- Warehouse: COMPUTE_EXTRA_SMALL
-- Refresh Lag: 1 hour
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
    TARGET_LAG = '1 hour'
    WAREHOUSE = COMPUTE_EXTRA_SMALL
    AS

-- CTE 1: Order-level metrics
WITH order_metrics AS (
    SELECT
        L_ORDERKEY,
        SUM(L_EXTENDEDPRICE) AS ORDER_TOTAL,
        COUNT(*) AS ORDER_LINE_COUNT,
        AVG(L_EXTENDEDPRICE) AS ORDER_AVG_LINE_VALUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM
    GROUP BY L_ORDERKEY
),

-- CTE 2: Customer-level metrics (fulfilled orders only)
customer_metrics AS (
    SELECT
        o.O_CUSTKEY,
        SUM(o.O_TOTALPRICE) AS CUSTOMER_LIFETIME_VALUE,
        COUNT(DISTINCT o.O_ORDERKEY) AS CUSTOMER_TOTAL_ORDERS,
        AVG(o.O_TOTALPRICE) AS CUSTOMER_AVG_ORDER_VALUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    WHERE o.O_ORDERSTATUS = 'F'
    GROUP BY o.O_CUSTKEY
),

-- CTE 3: Regional totals for percentage calculation
regional_totals AS (
    SELECT
        r.R_REGIONKEY,
        r.R_NAME AS REGION_NAME,
        SUM(o.O_TOTALPRICE) AS REGIONAL_TOTAL_REVENUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
    WHERE o.O_ORDERSTATUS = 'F'
    GROUP BY r.R_REGIONKEY, r.R_NAME
),

-- CTE 4: Customer rankings within region
customer_rankings AS (
    SELECT
        c.C_CUSTKEY,
        n.N_REGIONKEY,
        cm.CUSTOMER_LIFETIME_VALUE,
        rt.REGIONAL_TOTAL_REVENUE,
        RANK() OVER (PARTITION BY n.N_REGIONKEY ORDER BY cm.CUSTOMER_LIFETIME_VALUE DESC) AS CUSTOMER_RANK_IN_REGION,
        ROUND(cm.CUSTOMER_LIFETIME_VALUE / NULLIF(rt.REGIONAL_TOTAL_REVENUE, 0) * 100, 6) AS CUSTOMER_PCT_OF_REGIONAL_REVENUE
    FROM customer_metrics cm
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON cm.O_CUSTKEY = c.C_CUSTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN regional_totals rt ON n.N_REGIONKEY = rt.R_REGIONKEY
)

-- Final SELECT: Line-item grain with all aggregated metrics
SELECT
    -- Line-Item Level (Primary Grain)
    l.L_ORDERKEY,
    l.L_LINENUMBER,
    l.L_PARTKEY,
    l.L_SUPPKEY,
    l.L_QUANTITY,
    l.L_EXTENDEDPRICE,
    l.L_DISCOUNT,
    l.L_TAX,
    l.L_RETURNFLAG,
    l.L_LINESTATUS,
    l.L_SHIPDATE,
    l.L_COMMITDATE,
    l.L_RECEIPTDATE,
    l.L_SHIPINSTRUCT,
    l.L_SHIPMODE,

    -- Part Details
    p.P_NAME AS PART_NAME,
    p.P_BRAND AS PART_BRAND,
    p.P_TYPE AS PART_TYPE,
    p.P_CONTAINER AS PART_CONTAINER,

    -- Supplier Details
    s.S_NAME AS SUPPLIER_NAME,
    sn.N_NAME AS SUPPLIER_NATION,

    -- Order Level
    o.O_ORDERDATE,
    o.O_ORDERSTATUS,
    o.O_ORDERPRIORITY,
    om.ORDER_TOTAL,
    om.ORDER_LINE_COUNT,
    om.ORDER_AVG_LINE_VALUE,

    -- Customer Level
    c.C_CUSTKEY,
    c.C_NAME AS CUSTOMER_NAME,
    c.C_MKTSEGMENT AS CUSTOMER_SEGMENT,
    cm.CUSTOMER_LIFETIME_VALUE,
    cm.CUSTOMER_TOTAL_ORDERS,
    cm.CUSTOMER_AVG_ORDER_VALUE,

    -- Geographic
    n.N_NAME AS NATION_NAME,
    r.R_NAME AS REGION_NAME,

    -- Regional Rankings
    cr.CUSTOMER_RANK_IN_REGION,
    cr.CUSTOMER_PCT_OF_REGIONAL_REVENUE

FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l

-- Order join
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    ON l.L_ORDERKEY = o.O_ORDERKEY

-- Customer geography chain
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c
    ON o.O_CUSTKEY = c.C_CUSTKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n
    ON c.C_NATIONKEY = n.N_NATIONKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION r
    ON n.N_REGIONKEY = r.R_REGIONKEY

-- Part and Supplier
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.PART p
    ON l.L_PARTKEY = p.P_PARTKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.SUPPLIER s
    ON l.L_SUPPKEY = s.S_SUPPKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION sn
    ON s.S_NATIONKEY = sn.N_NATIONKEY

-- Pre-aggregated metrics
INNER JOIN order_metrics om
    ON l.L_ORDERKEY = om.L_ORDERKEY
INNER JOIN customer_metrics cm
    ON o.O_CUSTKEY = cm.O_CUSTKEY
INNER JOIN customer_rankings cr
    ON c.C_CUSTKEY = cr.C_CUSTKEY

-- Filter to fulfilled orders only (consistent with metrics)
WHERE o.O_ORDERSTATUS = 'F';

-- Add comment
COMMENT ON DYNAMIC TABLE ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN IS
'Multi-grain order analytics: Line-item detail enriched with order, customer, and regional aggregations. Fulfilled orders only. Refresh lag: 1 hour.';
```

---

## Quality Control Validation Plan

### Single QC Validation File Structure

Create `final_deliverables/qc_validation.sql` with all tests:

```sql
-- ============================================================================
-- QC VALIDATION: DT_ORDER_ANALYTICS_MULTI_GRAIN
-- Run all tests sequentially after dynamic table creation
-- ============================================================================

-- 1.1: Verify dynamic table exists
DESCRIBE DYNAMIC TABLE ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN;

-- 1.2: Check dynamic table properties
SHOW DYNAMIC TABLES LIKE 'DT_ORDER_ANALYTICS_MULTI_GRAIN' IN SCHEMA ANALYTICS.DEVELOPMENT;

-- 2.1: Record count validation
SELECT 'Total Records' AS test_name, COUNT(*) AS record_count
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN;

-- 2.2: Compare to source (fulfilled orders only)
SELECT 'Source LINEITEM (Fulfilled Orders)' AS test_name, COUNT(*) AS record_count
FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON l.L_ORDERKEY = o.O_ORDERKEY
WHERE o.O_ORDERSTATUS = 'F';

-- 3.1: Primary key uniqueness (L_ORDERKEY + L_LINENUMBER)
SELECT 'Duplicate Check' AS test_name, COUNT(*) AS duplicate_count
FROM (
    SELECT L_ORDERKEY, L_LINENUMBER, COUNT(*) AS cnt
    FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
    GROUP BY L_ORDERKEY, L_LINENUMBER
    HAVING COUNT(*) > 1
);

-- 4.1: Null check on critical columns
SELECT
    'Null Check' AS test_name,
    SUM(CASE WHEN L_ORDERKEY IS NULL THEN 1 ELSE 0 END) AS null_orderkey,
    SUM(CASE WHEN L_LINENUMBER IS NULL THEN 1 ELSE 0 END) AS null_linenumber,
    SUM(CASE WHEN C_CUSTKEY IS NULL THEN 1 ELSE 0 END) AS null_custkey,
    SUM(CASE WHEN CUSTOMER_LIFETIME_VALUE IS NULL THEN 1 ELSE 0 END) AS null_ltv,
    SUM(CASE WHEN CUSTOMER_RANK_IN_REGION IS NULL THEN 1 ELSE 0 END) AS null_rank
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN;

-- 5.1: Order-level metrics validation (spot check)
WITH sample_order AS (
    SELECT L_ORDERKEY FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN LIMIT 1
),
dt_values AS (
    SELECT DISTINCT L_ORDERKEY, ORDER_TOTAL, ORDER_LINE_COUNT
    FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
    WHERE L_ORDERKEY = (SELECT L_ORDERKEY FROM sample_order)
),
calc_values AS (
    SELECT L_ORDERKEY, SUM(L_EXTENDEDPRICE) AS calc_total, COUNT(*) AS calc_count
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM
    WHERE L_ORDERKEY = (SELECT L_ORDERKEY FROM sample_order)
    GROUP BY L_ORDERKEY
)
SELECT
    'Order Metrics Validation' AS test_name,
    dt.L_ORDERKEY,
    dt.ORDER_TOTAL AS dt_total,
    cv.calc_total,
    dt.ORDER_LINE_COUNT AS dt_count,
    cv.calc_count,
    CASE WHEN dt.ORDER_TOTAL = cv.calc_total AND dt.ORDER_LINE_COUNT = cv.calc_count
         THEN 'PASS' ELSE 'FAIL' END AS result
FROM dt_values dt
JOIN calc_values cv ON dt.L_ORDERKEY = cv.L_ORDERKEY;

-- 5.2: Customer-level metrics validation (spot check)
WITH sample_customer AS (
    SELECT C_CUSTKEY FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN LIMIT 1
),
dt_values AS (
    SELECT DISTINCT C_CUSTKEY, CUSTOMER_LIFETIME_VALUE, CUSTOMER_TOTAL_ORDERS
    FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
    WHERE C_CUSTKEY = (SELECT C_CUSTKEY FROM sample_customer)
),
calc_values AS (
    SELECT O_CUSTKEY, SUM(O_TOTALPRICE) AS calc_ltv, COUNT(DISTINCT O_ORDERKEY) AS calc_orders
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS
    WHERE O_CUSTKEY = (SELECT C_CUSTKEY FROM sample_customer)
    AND O_ORDERSTATUS = 'F'
    GROUP BY O_CUSTKEY
)
SELECT
    'Customer Metrics Validation' AS test_name,
    dt.C_CUSTKEY,
    dt.CUSTOMER_LIFETIME_VALUE AS dt_ltv,
    cv.calc_ltv,
    dt.CUSTOMER_TOTAL_ORDERS AS dt_orders,
    cv.calc_orders,
    CASE WHEN dt.CUSTOMER_LIFETIME_VALUE = cv.calc_ltv AND dt.CUSTOMER_TOTAL_ORDERS = cv.calc_orders
         THEN 'PASS' ELSE 'FAIL' END AS result
FROM dt_values dt
JOIN calc_values cv ON dt.C_CUSTKEY = cv.O_CUSTKEY;

-- 6.1: Regional ranking validation
SELECT
    'Regional Ranking Check' AS test_name,
    REGION_NAME,
    COUNT(DISTINCT C_CUSTKEY) AS customers_in_region,
    MIN(CUSTOMER_RANK_IN_REGION) AS min_rank,
    MAX(CUSTOMER_RANK_IN_REGION) AS max_rank
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
GROUP BY REGION_NAME
ORDER BY REGION_NAME;

-- 6.2: Regional percentage sum validation (should be ~100% per region when summed by distinct customers)
SELECT
    'Regional PCT Sum Check' AS test_name,
    REGION_NAME,
    ROUND(SUM(DISTINCT CUSTOMER_PCT_OF_REGIONAL_REVENUE), 2) AS total_pct
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
GROUP BY REGION_NAME
ORDER BY REGION_NAME;

-- 7.1: Data distribution by region
SELECT
    'Distribution by Region' AS test_name,
    REGION_NAME,
    COUNT(*) AS line_items,
    COUNT(DISTINCT C_CUSTKEY) AS unique_customers,
    COUNT(DISTINCT L_ORDERKEY) AS unique_orders
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
GROUP BY REGION_NAME
ORDER BY REGION_NAME;

-- 7.2: Order status verification (should only have 'F')
SELECT
    'Order Status Check' AS test_name,
    O_ORDERSTATUS,
    COUNT(*) AS record_count
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
GROUP BY O_ORDERSTATUS;

-- 8.1: Sample output inspection
SELECT *
FROM ANALYTICS.DEVELOPMENT.DT_ORDER_ANALYTICS_MULTI_GRAIN
LIMIT 10;
```

---

## Production Deployment

### Production DDL

After QC validation passes, deploy to production:

```sql
-- ============================================================================
-- PRODUCTION DEPLOYMENT: DT_ORDER_ANALYTICS_MULTI_GRAIN
-- Execute only after development QC validation passes
-- ============================================================================

CREATE OR REPLACE DYNAMIC TABLE ANALYTICS.PRODUCTION.DT_ORDER_ANALYTICS_MULTI_GRAIN
    TARGET_LAG = '1 hour'
    WAREHOUSE = COMPUTE_EXTRA_SMALL
    COPY GRANTS
    AS

-- [Same query as development - copy from above]
-- CTE 1: Order-level metrics
WITH order_metrics AS (
    SELECT
        L_ORDERKEY,
        SUM(L_EXTENDEDPRICE) AS ORDER_TOTAL,
        COUNT(*) AS ORDER_LINE_COUNT,
        AVG(L_EXTENDEDPRICE) AS ORDER_AVG_LINE_VALUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM
    GROUP BY L_ORDERKEY
),

customer_metrics AS (
    SELECT
        o.O_CUSTKEY,
        SUM(o.O_TOTALPRICE) AS CUSTOMER_LIFETIME_VALUE,
        COUNT(DISTINCT o.O_ORDERKEY) AS CUSTOMER_TOTAL_ORDERS,
        AVG(o.O_TOTALPRICE) AS CUSTOMER_AVG_ORDER_VALUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    WHERE o.O_ORDERSTATUS = 'F'
    GROUP BY o.O_CUSTKEY
),

regional_totals AS (
    SELECT
        r.R_REGIONKEY,
        r.R_NAME AS REGION_NAME,
        SUM(o.O_TOTALPRICE) AS REGIONAL_TOTAL_REVENUE
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
    WHERE o.O_ORDERSTATUS = 'F'
    GROUP BY r.R_REGIONKEY, r.R_NAME
),

customer_rankings AS (
    SELECT
        c.C_CUSTKEY,
        n.N_REGIONKEY,
        cm.CUSTOMER_LIFETIME_VALUE,
        rt.REGIONAL_TOTAL_REVENUE,
        RANK() OVER (PARTITION BY n.N_REGIONKEY ORDER BY cm.CUSTOMER_LIFETIME_VALUE DESC) AS CUSTOMER_RANK_IN_REGION,
        ROUND(cm.CUSTOMER_LIFETIME_VALUE / NULLIF(rt.REGIONAL_TOTAL_REVENUE, 0) * 100, 6) AS CUSTOMER_PCT_OF_REGIONAL_REVENUE
    FROM customer_metrics cm
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON cm.O_CUSTKEY = c.C_CUSTKEY
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
    JOIN regional_totals rt ON n.N_REGIONKEY = rt.R_REGIONKEY
)

SELECT
    l.L_ORDERKEY,
    l.L_LINENUMBER,
    l.L_PARTKEY,
    l.L_SUPPKEY,
    l.L_QUANTITY,
    l.L_EXTENDEDPRICE,
    l.L_DISCOUNT,
    l.L_TAX,
    l.L_RETURNFLAG,
    l.L_LINESTATUS,
    l.L_SHIPDATE,
    l.L_COMMITDATE,
    l.L_RECEIPTDATE,
    l.L_SHIPINSTRUCT,
    l.L_SHIPMODE,
    p.P_NAME AS PART_NAME,
    p.P_BRAND AS PART_BRAND,
    p.P_TYPE AS PART_TYPE,
    p.P_CONTAINER AS PART_CONTAINER,
    s.S_NAME AS SUPPLIER_NAME,
    sn.N_NAME AS SUPPLIER_NATION,
    o.O_ORDERDATE,
    o.O_ORDERSTATUS,
    o.O_ORDERPRIORITY,
    om.ORDER_TOTAL,
    om.ORDER_LINE_COUNT,
    om.ORDER_AVG_LINE_VALUE,
    c.C_CUSTKEY,
    c.C_NAME AS CUSTOMER_NAME,
    c.C_MKTSEGMENT AS CUSTOMER_SEGMENT,
    cm.CUSTOMER_LIFETIME_VALUE,
    cm.CUSTOMER_TOTAL_ORDERS,
    cm.CUSTOMER_AVG_ORDER_VALUE,
    n.N_NAME AS NATION_NAME,
    r.R_NAME AS REGION_NAME,
    cr.CUSTOMER_RANK_IN_REGION,
    cr.CUSTOMER_PCT_OF_REGIONAL_REVENUE

FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o ON l.L_ORDERKEY = o.O_ORDERKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER c ON o.O_CUSTKEY = c.C_CUSTKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.PART p ON l.L_PARTKEY = p.P_PARTKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.SUPPLIER s ON l.L_SUPPKEY = s.S_SUPPKEY
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION sn ON s.S_NATIONKEY = sn.N_NATIONKEY
INNER JOIN order_metrics om ON l.L_ORDERKEY = om.L_ORDERKEY
INNER JOIN customer_metrics cm ON o.O_CUSTKEY = cm.O_CUSTKEY
INNER JOIN customer_rankings cr ON c.C_CUSTKEY = cr.C_CUSTKEY
WHERE o.O_ORDERSTATUS = 'F';

COMMENT ON DYNAMIC TABLE ANALYTICS.PRODUCTION.DT_ORDER_ANALYTICS_MULTI_GRAIN IS
'Multi-grain order analytics: Line-item detail enriched with order, customer, and regional aggregations. Fulfilled orders only. Refresh lag: 1 hour.';
```

---

## Confidence Assessment

**Score: 8/10**

### Strengths
- Complete database schema analysis with all 7 source tables documented
- All join relationships validated with zero orphan records
- Clear multi-grain architecture pattern with pre-aggregated CTEs
- Comprehensive QC validation plan in single file
- Business rules confirmed and documented (fulfilled orders only, regional % calculation)
- Performance considerations addressed (smallest warehouse, pre-aggregation strategy)

### Potential Risks
- **Performance**: 600M+ row dynamic table with complex window functions may have extended initial refresh time
- **Warehouse Size**: X-Small warehouse may be slow for initial creation; consider temporarily using larger warehouse for creation only
- **Regional Percentage**: Summing percentages across all line items for a customer will exceed 100% due to grain repetition - documented in QC as expected behavior

### Recommendations for Implementation
1. **Independent Validation**: Before following this PRP, implementer should run sample queries to validate understanding
2. **Monitor Initial Refresh**: First refresh may take significant time; monitor and adjust warehouse if needed
3. **Test Window Functions**: Run the customer_rankings CTE independently to validate performance before full dynamic table creation

---

## Implementation Checklist

- [ ] Read and understand full PRP before starting
- [ ] Run independent exploratory queries to validate source data
- [ ] Create dynamic table in ANALYTICS.DEVELOPMENT
- [ ] Execute all QC validation queries
- [ ] Review sample output for business accuracy
- [ ] Present results to user for review
- [ ] Deploy to ANALYTICS.PRODUCTION after approval
- [ ] Document any deviations from PRP in ticket CLAUDE.md
