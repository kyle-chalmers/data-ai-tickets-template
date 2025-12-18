# PRP: Customer Order Summary View

## Table of Contents

- [Executive Summary](#executive-summary)
- [Business Context](#business-context)
- [Source Database Objects](#source-database-objects)
- [Data Relationships & Join Validation](#data-relationships--join-validation)
- [Output Specification](#output-specification)
- [Implementation Blueprint](#implementation-blueprint)
- [Quality Control Validation](#quality-control-validation)
- [Deployment](#deployment)
- [Expected Ticket Folder Structure](#expected-ticket-folder-structure)
- [Assumptions & Decisions](#assumptions--decisions)
- [Confidence Assessment](#confidence-assessment)
- [References](#references)

---

## Executive Summary

| Attribute | Value |
|-----------|-------|
| **Object Name** | `VW_CUSTOMER_ORDER_SUMMARY` |
| **Object Type** | VIEW |
| **Operation** | CREATE_NEW |
| **Scope** | SINGLE_OBJECT |
| **Target Schema** | `ANALYTICS.DEVELOPMENT` |
| **Expected Row Count** | ~9,999,832 (customers with orders only) |
| **Data Grain** | One row per customer |

## Business Context

### Purpose
Create a customer-level summary of order activity to enable:
- Customer segmentation analysis by market segment
- Regional performance comparisons across geographies
- Revenue concentration analysis for finance reporting

### Primary Use Cases
1. **Marketing Team**: Identify high-value customers by market segment
2. **Regional Managers**: Compare customer order patterns across geographies
3. **Finance**: Customer revenue distribution for reporting

### Stakeholders
- Video demonstration audience (demonstration object)

---

## Source Database Objects

### Table: CUSTOMER
**Location**: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER`
**Row Count**: 15,000,000

```
Column          | Type          | Nullable | Description
----------------|---------------|----------|------------
C_CUSTKEY       | NUMBER(38,0)  | NO       | Primary key
C_NAME          | VARCHAR(25)   | NO       | Customer name (format: Customer#XXXXXXXXX)
C_ADDRESS       | VARCHAR(40)   | NO       | Address
C_NATIONKEY     | NUMBER(38,0)  | NO       | FK to NATION
C_PHONE         | VARCHAR(15)   | NO       | Phone number
C_ACCTBAL       | NUMBER(12,2)  | NO       | Account balance
C_MKTSEGMENT    | VARCHAR(10)   | YES      | Market segment
C_COMMENT       | VARCHAR(117)  | YES      | Comment
```

**Sample Data**:
```
C_CUSTKEY | C_NAME              | C_NATIONKEY | C_ACCTBAL | C_MKTSEGMENT
----------|---------------------|-------------|-----------|-------------
5200001   | Customer#005200001  | 5           | 6597.07   | MACHINERY
5200002   | Customer#005200002  | 6           | 5907.90   | FURNITURE
5200003   | Customer#005200003  | 14          | 6155.64   | HOUSEHOLD
```

**Distinct Market Segments** (5 values):
- AUTOMOBILE
- BUILDING
- FURNITURE
- HOUSEHOLD
- MACHINERY

### Table: ORDERS
**Location**: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS`
**Row Count**: 150,000,000

```
Column          | Type          | Nullable | Description
----------------|---------------|----------|------------
O_ORDERKEY      | NUMBER(38,0)  | NO       | Primary key
O_CUSTKEY       | NUMBER(38,0)  | NO       | FK to CUSTOMER
O_ORDERSTATUS   | VARCHAR(1)    | NO       | Order status (F/O/P)
O_TOTALPRICE    | NUMBER(12,2)  | NO       | Order total price
O_ORDERDATE     | DATE          | NO       | Order date
O_ORDERPRIORITY | VARCHAR(15)   | NO       | Priority
O_CLERK         | VARCHAR(15)   | NO       | Clerk
O_SHIPPRIORITY  | NUMBER(38,0)  | NO       | Ship priority
O_COMMENT       | VARCHAR(79)   | NO       | Comment
```

**Sample Data**:
```
O_ORDERKEY | O_CUSTKEY | O_ORDERSTATUS | O_TOTALPRICE | O_ORDERDATE
-----------|-----------|---------------|--------------|------------
33338469   | 9145955   | F             | 103134.13    | 1992-01-13
32147872   | 8994326   | F             | 12923.92     | 1992-01-13
```

**Date Range**: 1992-01-01 to 1998-08-02 (7 years)

### Table: LINEITEM
**Location**: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM`
**Row Count**: 600,037,902

```
Column          | Type          | Nullable | Description
----------------|---------------|----------|------------
L_ORDERKEY      | NUMBER(38,0)  | NO       | FK to ORDERS
L_PARTKEY       | NUMBER(38,0)  | NO       | Part key
L_SUPPKEY       | NUMBER(38,0)  | NO       | Supplier key
L_LINENUMBER    | NUMBER(38,0)  | NO       | Line number
L_QUANTITY      | NUMBER(12,2)  | NO       | Quantity
L_EXTENDEDPRICE | NUMBER(12,2)  | NO       | Extended price
L_DISCOUNT      | NUMBER(12,2)  | NO       | Discount (0.00-0.10)
L_TAX           | NUMBER(12,2)  | NO       | Tax
L_RETURNFLAG    | VARCHAR(1)    | NO       | Return flag
L_LINESTATUS    | VARCHAR(1)    | NO       | Line status
L_SHIPDATE      | DATE          | NO       | Ship date
L_COMMITDATE    | DATE          | NO       | Commit date
L_RECEIPTDATE   | DATE          | NO       | Receipt date
L_SHIPINSTRUCT  | VARCHAR(25)   | NO       | Ship instructions
L_SHIPMODE      | VARCHAR(10)   | NO       | Ship mode
L_COMMENT       | VARCHAR(44)   | NO       | Comment
```

### Table: NATION
**Location**: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION`
**Row Count**: 25

```
Column      | Type          | Nullable | Description
------------|---------------|----------|------------
N_NATIONKEY | NUMBER(38,0)  | NO       | Primary key
N_NAME      | VARCHAR(25)   | NO       | Nation name
N_REGIONKEY | NUMBER(38,0)  | NO       | FK to REGION
N_COMMENT   | VARCHAR(152)  | YES      | Comment
```

### Table: REGION
**Location**: `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION`
**Row Count**: 5

```
Column      | Type          | Nullable | Description
------------|---------------|----------|------------
R_REGIONKEY | NUMBER(38,0)  | NO       | Primary key
R_NAME      | VARCHAR(25)   | NO       | Region name
R_COMMENT   | VARCHAR(152)  | YES      | Comment
```

**Complete Nation-Region Mapping**:
```
Region       | Nations
-------------|------------------------------------------
AFRICA       | ALGERIA, ETHIOPIA, KENYA, MOROCCO, MOZAMBIQUE
AMERICA      | ARGENTINA, BRAZIL, CANADA, PERU, UNITED STATES
ASIA         | CHINA, INDIA, INDONESIA, JAPAN, VIETNAM
EUROPE       | FRANCE, GERMANY, ROMANIA, RUSSIA, UNITED KINGDOM
MIDDLE EAST  | EGYPT, IRAN, IRAQ, JORDAN, SAUDI ARABIA
```

---

## Data Relationships & Join Validation

### Entity Relationship Diagram
```
REGION (5 rows)
    |
    | R_REGIONKEY = N_REGIONKEY
    v
NATION (25 rows)
    |
    | N_NATIONKEY = C_NATIONKEY
    v
CUSTOMER (15M rows)
    |
    | C_CUSTKEY = O_CUSTKEY [INNER JOIN - filters to ~10M]
    v
ORDERS (150M rows)
    |
    | O_ORDERKEY = L_ORDERKEY
    v
LINEITEM (600M rows)
```

### Join Integrity Validation Results
| Check | Result | Notes |
|-------|--------|-------|
| Customers without orders | 5,000,168 | Will be excluded (INNER JOIN) |
| Orders without lineitems | 0 | All orders have line items |
| Distinct customers with orders | 9,999,832 | Expected output row count |
| Nations without region | 0 | Complete reference integrity |

### Customer Order Distribution
| Order Bucket | Customer Count |
|--------------|----------------|
| 0 orders | 5,000,168 (excluded) |
| 1-5 orders | 302,603 |
| 6-10 orders | 2,658,972 |
| 11-20 orders | 4,828,713 |
| 21+ orders | 2,209,544 |

---

## Output Specification

### Target Columns
| Column | Data Type | Source | Description |
|--------|-----------|--------|-------------|
| C_CUSTKEY | NUMBER(38,0) | CUSTOMER.C_CUSTKEY | Customer identifier (PK) |
| C_NAME | VARCHAR(25) | CUSTOMER.C_NAME | Customer name |
| C_MKTSEGMENT | VARCHAR(10) | CUSTOMER.C_MKTSEGMENT | Market segment |
| C_ACCTBAL | NUMBER(12,2) | CUSTOMER.C_ACCTBAL | Account balance |
| NATION_NAME | VARCHAR(25) | NATION.N_NAME | Customer nation |
| REGION_NAME | VARCHAR(25) | REGION.R_NAME | Customer region |
| TOTAL_ORDERS | NUMBER | COUNT(DISTINCT O_ORDERKEY) | Total order count |
| TOTAL_REVENUE | NUMBER(18,2) | SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) | Net revenue |
| AVG_ORDER_VALUE | NUMBER(18,2) | TOTAL_REVENUE / TOTAL_ORDERS | Average order value |
| FIRST_ORDER_DATE | DATE | MIN(O_ORDERDATE) | First order date |
| LAST_ORDER_DATE | DATE | MAX(O_ORDERDATE) | Most recent order |

### Business Logic
1. **Customer Scope**: Only customers with at least one order (INNER JOIN)
2. **Revenue Calculation**: `L_EXTENDEDPRICE * (1 - L_DISCOUNT)` (net of discount, excludes tax)
3. **Aggregation Level**: Customer grain - aggregate all orders and line items per customer
4. **Geographic Enrichment**: Join to NATION and REGION for geographic dimensions

---

## Implementation Blueprint

### Development Environment
- **Development Schema**: `ANALYTICS.DEVELOPMENT`
- **Development Object**: `ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY`

### SQL Implementation

```sql
CREATE OR REPLACE VIEW ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY AS
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
*/
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
```

---

## Quality Control Validation

### Single QC Validation File: `qc_validation.sql`

All validation tests should be consolidated into a single file with the following structure:

```sql
/*
    QC VALIDATION: VW_CUSTOMER_ORDER_SUMMARY
    Run all tests sequentially and verify results
*/

-- Use appropriate warehouse for performance
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

--1.1: Record Count Validation
-- Expected: ~9,999,832 rows (customers with orders)
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
-- Expected: 5 segments with roughly even distribution
SELECT 'Market Segment Distribution' AS test_name,
       C_MKTSEGMENT,
       COUNT(*) AS customer_count,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
GROUP BY C_MKTSEGMENT
ORDER BY C_MKTSEGMENT;

--2.2: Region Distribution
-- Expected: 5 regions
SELECT 'Region Distribution' AS test_name,
       REGION_NAME,
       COUNT(*) AS customer_count,
       SUM(TOTAL_REVENUE) AS total_revenue
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
GROUP BY REGION_NAME
ORDER BY REGION_NAME;

--3.1: Revenue Calculation Validation (Sample Check)
-- Compare view revenue against source calculation
WITH source_calc AS (
    SELECT
        o.O_CUSTKEY,
        SUM(l.L_EXTENDEDPRICE * (1 - l.L_DISCOUNT)) AS source_revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS o
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM l ON o.O_ORDERKEY = l.L_ORDERKEY
    WHERE o.O_CUSTKEY IN (SELECT C_CUSTKEY FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY LIMIT 100)
    GROUP BY o.O_CUSTKEY
)
SELECT 'Revenue Validation' AS test_name,
       COUNT(*) AS sample_size,
       SUM(CASE WHEN ABS(v.TOTAL_REVENUE - s.source_revenue) < 0.01 THEN 1 ELSE 0 END) AS matching,
       CASE WHEN SUM(CASE WHEN ABS(v.TOTAL_REVENUE - s.source_revenue) < 0.01 THEN 1 ELSE 0 END) = COUNT(*)
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY v
JOIN source_calc s ON v.C_CUSTKEY = s.O_CUSTKEY;

--3.2: Order Count Validation (Sample Check)
WITH source_orders AS (
    SELECT O_CUSTKEY, COUNT(DISTINCT O_ORDERKEY) AS order_count
    FROM SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS
    WHERE O_CUSTKEY IN (SELECT C_CUSTKEY FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY LIMIT 100)
    GROUP BY O_CUSTKEY
)
SELECT 'Order Count Validation' AS test_name,
       COUNT(*) AS sample_size,
       SUM(CASE WHEN v.TOTAL_ORDERS = s.order_count THEN 1 ELSE 0 END) AS matching,
       CASE WHEN SUM(CASE WHEN v.TOTAL_ORDERS = s.order_count THEN 1 ELSE 0 END) = COUNT(*)
            THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY v
JOIN source_orders s ON v.C_CUSTKEY = s.O_CUSTKEY;

--4.1: Date Range Validation
SELECT 'Date Range' AS test_name,
       MIN(FIRST_ORDER_DATE) AS min_first_order,
       MAX(LAST_ORDER_DATE) AS max_last_order,
       '1992-01-01' AS expected_min,
       '1998-08-02' AS expected_max
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY;

--4.2: Business Logic - No Zero Orders
SELECT 'No Zero Orders' AS test_name,
       COUNT(*) AS zero_order_customers,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
WHERE TOTAL_ORDERS = 0 OR TOTAL_ORDERS IS NULL;

--4.3: AVG_ORDER_VALUE Calculation Check
SELECT 'AVG Calculation' AS test_name,
       COUNT(*) AS mismatches,
       CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
WHERE ABS(AVG_ORDER_VALUE - ROUND(TOTAL_REVENUE / TOTAL_ORDERS, 2)) > 0.01;

--5.1: Performance Baseline
-- Record query execution time for monitoring
SELECT 'Performance Sample' AS test_name,
       COUNT(*) AS rows_scanned,
       SUM(TOTAL_REVENUE) AS total_revenue_check
FROM ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY
WHERE REGION_NAME = 'AMERICA';
```

---

## Deployment

### Development Deployment
```sql
-- Create view in development schema
USE ROLE <your_role>;
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE DATABASE ANALYTICS;
USE SCHEMA DEVELOPMENT;

-- Execute CREATE VIEW statement from Implementation Blueprint
-- Run QC validation file
-- Review results before production deployment
```

### Production Deployment Template
```sql
-- Production deployment (requires explicit approval)
-- Only execute after QC validation passes

CREATE OR REPLACE VIEW ANALYTICS.PRODUCTION.VW_CUSTOMER_ORDER_SUMMARY
COPY GRANTS
AS
-- [Same SELECT statement as development view]
;

-- Post-deployment validation
SELECT COUNT(*) FROM ANALYTICS.PRODUCTION.VW_CUSTOMER_ORDER_SUMMARY;
```

---

## Expected Ticket Folder Structure

```
tickets/[username]/[TICKET-ID]/
├── README.md                           # Business context and assumptions
├── CLAUDE.md                           # Technical context for future sessions
├── final_deliverables/
│   ├── 1_vw_customer_order_summary.sql # Main view DDL
│   └── qc_validation.sql               # All QC tests
└── [jira_comment].txt                  # Final ticket comment
```

---

## Assumptions & Decisions

| # | Assumption | Decision | Rationale |
|---|------------|----------|-----------|
| 1 | Customer scope | INNER JOIN only | Exclude 5M customers without orders per user confirmation |
| 2 | Revenue formula | `L_EXTENDEDPRICE * (1 - L_DISCOUNT)` | Standard TPC-H net revenue, excludes tax per user confirmation |
| 3 | Account balance | Include C_ACCTBAL | Added per user request for credit analysis capability |
| 4 | Date filtering | No filter (all historical) | Per INITIAL.md requirement |
| 5 | Data quality | No special handling | TPC-H is synthetic, clean dataset |

---

## Confidence Assessment

**Score: 10/10**

**Rationale**:
- Complete source table documentation with DDL and sample data
- All join relationships validated with actual query results
- Business logic confirmed through user clarification questions
- Revenue calculation formula verified against source data
- Expected row counts validated (9,999,832)
- Comprehensive QC validation plan with executable queries
- Clear deployment path from development to production
- Production schema `ANALYTICS.PRODUCTION` confirmed to exist

---

## References

- [TPC-H Documentation](https://docs.snowflake.com/en/user-guide/sample-data-tpch)
- [Snowflake Sample Data](https://docs.snowflake.com/en/user-guide/sample-data)
