# TPC-DS SF10TCL Data Catalog

## Overview

This catalog documents the **SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL** schema, which is based on the TPC-DS (Transaction Processing Performance Council - Decision Support) benchmark. This schema represents a retail data warehouse with 10TB scale factor, containing retail sales data across three channels: stores, catalogs, and web.

**Schema Purpose:** Retail analytics covering sales transactions, returns, inventory, and customer demographics across multiple sales channels.

**Key Characteristics:**
- **Scale:** 10TB benchmark dataset (SF10TCL = Scale Factor 10, Thread Control Level)
- **Business Domain:** Multi-channel retail (physical stores, catalog, web)
- **Data Model:** Star schema with dimension and fact tables
- **Primary Key Integrity:** All dimension tables verified with NO duplicate keys

## Navigation

### 🚀 Quick Start
- [Essential Tables](#essential-tables) - Most commonly used tables
- [Key Identifiers](#key-identifiers) - Primary and foreign key patterns
- [Common Patterns](#common-patterns) - Frequently used SQL patterns

### 📊 Schema Structure
- [Dimension Tables](#dimension-tables) - Customer, product, date, and descriptive data
- [Fact Tables](#fact-tables) - Sales transactions, returns, and inventory
- [Mini-Dimensions](#mini-dimensions) - Supporting reference tables

### 🔧 Technical Reference
- [Join Patterns](#join-patterns) - Relationship mappings with SQL examples
- [Primary Key Analysis](#primary-key-analysis) - Key structures and duplicate checks
- [Query Patterns](#query-patterns) - Common analytical SQL templates
- [Data Quality](#data-quality-notes) - Verified integrity and known patterns

## 🚀 Quick Start Guide

### Essential Tables

**Core Sales Fact Tables:**
- `STORE_SALES` - Physical store transactions (28.8B rows) - Primary sales channel
- `CATALOG_SALES` - Catalog order transactions (14.4B rows) - Mail order channel
- `WEB_SALES` - Web order transactions (7.2B rows) - E-commerce channel

**Core Dimension Tables:**
- `DATE_DIM` - Date dimension (73,049 dates) - Time-based analysis
- `ITEM` - Product catalog (402,000 products) - Product hierarchy
- `CUSTOMER` - Customer master (65M customers) - Customer demographics
- `STORE` - Store locations (1,500 stores) - Store attributes

**Returns Analysis:**
- `STORE_RETURNS` - Store return transactions (2.9B rows)
- `CATALOG_RETURNS` - Catalog return transactions (1.4B rows)
- `WEB_RETURNS` - Web return transactions (720M rows)

### Key Identifiers

**Naming Convention:**
- `*_SK` = Surrogate Key (numeric identifier used for joins)
- `*_ID` = Business/Natural Key (actual business identifier)

**Primary Keys:**
- **Dimension Tables:** Single surrogate key column (e.g., `D_DATE_SK`, `C_CUSTOMER_SK`)
- **Fact Tables:** Composite keys combining item and transaction identifiers
  - STORE_SALES: `(SS_ITEM_SK, SS_TICKET_NUMBER)`
  - CATALOG_SALES: `(CS_ITEM_SK, CS_ORDER_NUMBER)`
  - WEB_SALES: `(WS_ITEM_SK, WS_ORDER_NUMBER)`
  - INVENTORY: `(INV_DATE_SK, INV_ITEM_SK, INV_WAREHOUSE_SK)`

**Foreign Key Pattern:**
- Fact tables contain multiple `*_SK` columns that reference dimension table primary keys
- Example: `SS_SOLD_DATE_SK` in STORE_SALES → `D_DATE_SK` in DATE_DIM

### Critical Filters

**Date Filtering Best Practices:**
```sql
-- Use date dimension for date-based filters
WHERE ss.SS_SOLD_DATE_SK = d.D_DATE_SK
  AND d.D_YEAR = 2003
  AND d.D_MOY = 12  -- Month of Year
```

**NULL Handling:**
- Many dimension foreign keys in fact tables are nullable
- Customer keys may be NULL for transactions without customer identification
- Date keys may be NULL for pending/incomplete transactions

### Common Patterns

**Sales by Channel:**
```sql
-- Store sales by date
SELECT d.D_DATE, SUM(ss.SS_NET_PAID) as total_sales
FROM STORE_SALES ss
JOIN DATE_DIM d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
WHERE d.D_YEAR = 2003
GROUP BY d.D_DATE;
```

**Customer Purchase Analysis:**
```sql
-- Customer demographics for store purchases
SELECT c.C_CUSTOMER_ID, cd.CD_GENDER, cd.CD_MARITAL_STATUS,
       SUM(ss.SS_NET_PAID) as total_spent
FROM STORE_SALES ss
JOIN CUSTOMER c ON ss.SS_CUSTOMER_SK = c.C_CUSTOMER_SK
JOIN CUSTOMER_DEMOGRAPHICS cd ON c.C_CURRENT_CDEMO_SK = cd.CD_DEMO_SK
GROUP BY c.C_CUSTOMER_ID, cd.CD_GENDER, cd.CD_MARITAL_STATUS;
```

**Return Rate Analysis:**
```sql
-- Calculate return rates by item
SELECT i.I_ITEM_ID, i.I_PRODUCT_NAME,
       COUNT(DISTINCT ss.SS_TICKET_NUMBER) as sales_count,
       COUNT(DISTINCT sr.SR_TICKET_NUMBER) as return_count,
       (COUNT(DISTINCT sr.SR_TICKET_NUMBER) * 100.0 /
        NULLIF(COUNT(DISTINCT ss.SS_TICKET_NUMBER), 0)) as return_rate_pct
FROM STORE_SALES ss
LEFT JOIN STORE_RETURNS sr ON ss.SS_ITEM_SK = sr.SR_ITEM_SK
                          AND ss.SS_TICKET_NUMBER = sr.SR_TICKET_NUMBER
JOIN ITEM i ON ss.SS_ITEM_SK = i.I_ITEM_SK
GROUP BY i.I_ITEM_ID, i.I_PRODUCT_NAME;
```

## 📊 Database Architecture

### Schema Organization

The TPC-DS schema follows a **star schema design** with:
- **Central Fact Tables:** Sales and returns transactions
- **Dimension Tables:** Descriptive attributes for analysis
- **Bridge Table:** Inventory connecting items, warehouses, and dates

### Table Categories

#### Dimension Tables (14 tables)

**Time Dimensions:**
- `DATE_DIM` - Calendar date attributes (73,049 rows)
  - Primary Key: `D_DATE_SK`
  - Attributes: Year, month, day, quarter, fiscal periods, holidays, weekends
- `TIME_DIM` - Time of day attributes (86,400 rows)
  - Primary Key: `T_TIME_SK`
  - Attributes: Hour, minute, second, AM/PM, shift, meal time

**Customer Dimensions:**
- `CUSTOMER` - Customer master data (65M rows)
  - Primary Key: `C_CUSTOMER_SK`
  - Foreign Keys: `C_CURRENT_CDEMO_SK`, `C_CURRENT_HDEMO_SK`, `C_CURRENT_ADDR_SK`
  - Attributes: Name, birth date, email, preferred customer flag
- `CUSTOMER_ADDRESS` - Customer addresses (32.5M rows)
  - Primary Key: `CA_ADDRESS_SK`
  - Attributes: Street, city, county, state, zip, country, location type
- `CUSTOMER_DEMOGRAPHICS` - Demographic attributes (1.9M rows)
  - Primary Key: `CD_DEMO_SK`
  - Attributes: Gender, marital status, education, purchase estimate, credit rating
- `HOUSEHOLD_DEMOGRAPHICS` - Household characteristics (7,200 rows)
  - Primary Key: `HD_DEMO_SK`
  - Foreign Keys: `HD_INCOME_BAND_SK`
  - Attributes: Buy potential, dependent count, vehicle count
- `INCOME_BAND` - Income ranges (20 rows)
  - Primary Key: `IB_INCOME_BAND_SK`
  - Attributes: Lower bound, upper bound

**Product Dimension:**
- `ITEM` - Product catalog (402,000 rows)
  - Primary Key: `I_ITEM_SK`
  - Attributes: Description, price, cost, brand, class, category, manufacturer

**Location Dimensions:**
- `STORE` - Physical store locations (1,500 rows)
  - Primary Key: `S_STORE_SK`
  - Attributes: Store name, employees, square footage, market, division, company
- `WAREHOUSE` - Distribution centers (25 rows)
  - Primary Key: `W_WAREHOUSE_SK`
  - Attributes: Warehouse name, square footage, address

**Transaction Support Dimensions:**
- `PROMOTION` - Marketing promotions (2,000 rows)
  - Primary Key: `P_PROMO_SK`
  - Attributes: Promotion name, channels (email, catalog, TV, etc.), cost, purpose
- `REASON` - Return reasons (70 rows)
  - Primary Key: `R_REASON_SK`
  - Attributes: Reason description
- `SHIP_MODE` - Shipping methods (20 rows)
  - Primary Key: `SM_SHIP_MODE_SK`
  - Attributes: Type, code, carrier, contract

#### Mini-Dimensions (4 tables)

**Channel-Specific Dimensions:**
- `CALL_CENTER` - Customer service centers (54 rows)
  - Primary Key: `CC_CALL_CENTER_SK`
  - Attributes: Name, class, employees, market, division, company
- `CATALOG_PAGE` - Catalog page details (40,000 rows)
  - Primary Key: `CP_CATALOG_PAGE_SK`
  - Attributes: Department, catalog number, page number, type
- `WEB_PAGE` - Website pages (4,002 rows)
  - Primary Key: `WP_WEB_PAGE_SK`
  - Attributes: URL, type, character count, link count, image count
- `WEB_SITE` - E-commerce sites (78 rows)
  - Primary Key: `WEB_SITE_SK`
  - Attributes: Site name, class, manager, market, company

#### Fact Tables (6 tables)

**Sales Transactions:**
- `STORE_SALES` - In-store purchases (28.8B rows, 1.25PB)
  - Primary Key: `(SS_ITEM_SK, SS_TICKET_NUMBER)`
  - Foreign Keys: 9 dimension references (date, time, customer, store, promo, etc.)
  - Measures: Quantity, prices, costs, discounts, taxes, net paid, net profit

- `CATALOG_SALES` - Mail order purchases (14.4B rows, 924TB)
  - Primary Key: `(CS_ITEM_SK, CS_ORDER_NUMBER)`
  - Foreign Keys: 14 dimension references (includes shipping details)
  - Measures: Quantity, prices, costs, discounts, taxes, shipping, net paid, net profit

- `WEB_SALES` - Online purchases (7.2B rows, 461TB)
  - Primary Key: `(WS_ITEM_SK, WS_ORDER_NUMBER)`
  - Foreign Keys: 14 dimension references (includes web page/site)
  - Measures: Quantity, prices, costs, discounts, taxes, shipping, net paid, net profit

**Returns Transactions:**
- `STORE_RETURNS` - In-store returns (2.9B rows, 125TB)
  - Primary Key: `(SR_ITEM_SK, SR_TICKET_NUMBER)`
  - Links to: STORE_SALES via item and ticket number
  - Measures: Return quantity, amount, tax, fees, shipping, refunds, net loss

- `CATALOG_RETURNS` - Catalog returns (1.4B rows, 83TB)
  - Primary Key: `(CR_ITEM_SK, CR_ORDER_NUMBER)`
  - Links to: CATALOG_SALES via item and order number
  - Measures: Return quantity, amount, tax, fees, shipping, refunds, net loss

- `WEB_RETURNS` - Web returns (720M rows, 39TB)
  - Primary Key: `(WR_ITEM_SK, WR_ORDER_NUMBER)`
  - Links to: WEB_SALES via item and order number
  - Measures: Return quantity, amount, tax, fees, shipping, refunds, net loss

**Inventory:**
- `INVENTORY` - Stock levels (1.3B rows, 3.7TB)
  - Primary Key: `(INV_DATE_SK, INV_ITEM_SK, INV_WAREHOUSE_SK)`
  - Measures: Quantity on hand

## 🔧 Technical Reference

### Join Patterns

#### Store Sales Analysis Joins

**Basic Sales Query:**
```sql
SELECT
    d.D_DATE,
    s.S_STORE_NAME,
    i.I_PRODUCT_NAME,
    SUM(ss.SS_QUANTITY) as units_sold,
    SUM(ss.SS_NET_PAID) as revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d
    ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON ss.SS_ITEM_SK = i.I_ITEM_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE s
    ON ss.SS_STORE_SK = s.S_STORE_SK
WHERE d.D_YEAR = 2003
GROUP BY d.D_DATE, s.S_STORE_NAME, i.I_PRODUCT_NAME;
```

**Customer Demographics Analysis:**
```sql
SELECT
    cd.CD_GENDER,
    cd.CD_MARITAL_STATUS,
    cd.CD_EDUCATION_STATUS,
    hd.HD_BUY_POTENTIAL,
    ca.CA_STATE,
    COUNT(DISTINCT c.C_CUSTOMER_SK) as customer_count,
    SUM(ss.SS_NET_PAID) as total_revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER c
    ON ss.SS_CUSTOMER_SK = c.C_CUSTOMER_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_DEMOGRAPHICS cd
    ON c.C_CURRENT_CDEMO_SK = cd.CD_DEMO_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.HOUSEHOLD_DEMOGRAPHICS hd
    ON c.C_CURRENT_HDEMO_SK = hd.HD_DEMO_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS ca
    ON c.C_CURRENT_ADDR_SK = ca.CA_ADDRESS_SK
GROUP BY cd.CD_GENDER, cd.CD_MARITAL_STATUS, cd.CD_EDUCATION_STATUS,
         hd.HD_BUY_POTENTIAL, ca.CA_STATE;
```

**Time-Based Analysis:**
```sql
SELECT
    d.D_YEAR,
    d.D_QOY as quarter,
    d.D_MOY as month,
    t.T_HOUR,
    t.T_SHIFT,
    COUNT(*) as transaction_count,
    SUM(ss.SS_NET_PAID) as revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d
    ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.TIME_DIM t
    ON ss.SS_SOLD_TIME_SK = t.T_TIME_SK
GROUP BY d.D_YEAR, d.D_QOY, d.D_MOY, t.T_HOUR, t.T_SHIFT;
```

#### Catalog Sales Joins

**Multi-Channel Catalog Sales:**
```sql
SELECT
    cc.CC_NAME as call_center,
    cp.CP_CATALOG_PAGE_NUMBER,
    sm.SM_TYPE as ship_mode,
    i.I_CATEGORY,
    SUM(cs.CS_QUANTITY) as units_sold,
    SUM(cs.CS_NET_PAID) as revenue,
    SUM(cs.CS_EXT_SHIP_COST) as shipping_cost
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_SALES cs
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CALL_CENTER cc
    ON cs.CS_CALL_CENTER_SK = cc.CC_CALL_CENTER_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_PAGE cp
    ON cs.CS_CATALOG_PAGE_SK = cp.CP_CATALOG_PAGE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.SHIP_MODE sm
    ON cs.CS_SHIP_MODE_SK = sm.SM_SHIP_MODE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON cs.CS_ITEM_SK = i.I_ITEM_SK
GROUP BY cc.CC_NAME, cp.CP_CATALOG_PAGE_NUMBER, sm.SM_TYPE, i.I_CATEGORY;
```

**Shipping Analysis:**
```sql
SELECT
    bill_addr.CA_STATE as billing_state,
    ship_addr.CA_STATE as shipping_state,
    sm.SM_CARRIER,
    w.W_WAREHOUSE_NAME,
    COUNT(*) as order_count,
    SUM(cs.CS_EXT_SHIP_COST) as total_shipping_cost
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_SALES cs
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS bill_addr
    ON cs.CS_BILL_ADDR_SK = bill_addr.CA_ADDRESS_SK
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS ship_addr
    ON cs.CS_SHIP_ADDR_SK = ship_addr.CA_ADDRESS_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.SHIP_MODE sm
    ON cs.CS_SHIP_MODE_SK = sm.SM_SHIP_MODE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WAREHOUSE w
    ON cs.CS_WAREHOUSE_SK = w.W_WAREHOUSE_SK
GROUP BY bill_addr.CA_STATE, ship_addr.CA_STATE, sm.SM_CARRIER, w.W_WAREHOUSE_NAME;
```

#### Web Sales Joins

**Web Channel Analysis:**
```sql
SELECT
    ws_site.WEB_NAME as website,
    wp.WP_TYPE as page_type,
    i.I_CATEGORY,
    p.P_PROMO_NAME,
    COUNT(*) as order_count,
    SUM(web_s.WS_NET_PAID) as revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SALES web_s
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SITE ws_site
    ON web_s.WS_WEB_SITE_SK = ws_site.WEB_SITE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_PAGE wp
    ON web_s.WS_WEB_PAGE_SK = wp.WP_WEB_PAGE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON web_s.WS_ITEM_SK = i.I_ITEM_SK
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.PROMOTION p
    ON web_s.WS_PROMO_SK = p.P_PROMO_SK
GROUP BY ws_site.WEB_NAME, wp.WP_TYPE, i.I_CATEGORY, p.P_PROMO_NAME;
```

#### Returns Analysis Joins

**Store Returns with Reasons:**
```sql
SELECT
    r.R_REASON_DESC,
    d.D_YEAR,
    i.I_CATEGORY,
    COUNT(*) as return_count,
    SUM(sr.SR_RETURN_AMT) as return_amount,
    SUM(sr.SR_NET_LOSS) as net_loss
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_RETURNS sr
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.REASON r
    ON sr.SR_REASON_SK = r.R_REASON_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d
    ON sr.SR_RETURNED_DATE_SK = d.D_DATE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON sr.SR_ITEM_SK = i.I_ITEM_SK
GROUP BY r.R_REASON_DESC, d.D_YEAR, i.I_CATEGORY;
```

**Sales to Returns Reconciliation:**
```sql
-- Match store sales with their returns
SELECT
    ss.SS_TICKET_NUMBER,
    ss.SS_ITEM_SK,
    i.I_PRODUCT_NAME,
    ss.SS_SALES_PRICE as original_price,
    sr.SR_RETURN_AMT as return_amount,
    DATEDIFF(day, d_sold.D_DATE, d_return.D_DATE) as days_to_return
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
INNER JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_RETURNS sr
    ON ss.SS_ITEM_SK = sr.SR_ITEM_SK
   AND ss.SS_TICKET_NUMBER = sr.SR_TICKET_NUMBER
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON ss.SS_ITEM_SK = i.I_ITEM_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d_sold
    ON ss.SS_SOLD_DATE_SK = d_sold.D_DATE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d_return
    ON sr.SR_RETURNED_DATE_SK = d_return.D_DATE_SK
LIMIT 1000;
```

#### Inventory Analysis Joins

**Inventory Levels by Warehouse:**
```sql
SELECT
    d.D_DATE,
    w.W_WAREHOUSE_NAME,
    i.I_CATEGORY,
    i.I_CLASS,
    SUM(inv.INV_QUANTITY_ON_HAND) as total_inventory
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.INVENTORY inv
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d
    ON inv.INV_DATE_SK = d.D_DATE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WAREHOUSE w
    ON inv.INV_WAREHOUSE_SK = w.W_WAREHOUSE_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON inv.INV_ITEM_SK = i.I_ITEM_SK
WHERE d.D_YEAR = 2003
GROUP BY d.D_DATE, w.W_WAREHOUSE_NAME, i.I_CATEGORY, i.I_CLASS;
```

### Primary Key Analysis

#### Dimension Table Primary Keys (NO DUPLICATES VERIFIED)

All dimension tables use single-column surrogate keys with verified uniqueness:

| Table | Primary Key | Total Rows | Unique Keys | Duplicates |
|-------|-------------|------------|-------------|------------|
| CALL_CENTER | CC_CALL_CENTER_SK | 54 | 54 | 0 |
| CATALOG_PAGE | CP_CATALOG_PAGE_SK | 40,000 | 40,000 | 0 |
| CUSTOMER | C_CUSTOMER_SK | 65,000,000 | 65,000,000 | 0 |
| CUSTOMER_ADDRESS | CA_ADDRESS_SK | 32,500,000 | 32,500,000 | 0 |
| CUSTOMER_DEMOGRAPHICS | CD_DEMO_SK | 1,920,800 | 1,920,800 | 0 |
| DATE_DIM | D_DATE_SK | 73,049 | 73,049 | 0 |
| HOUSEHOLD_DEMOGRAPHICS | HD_DEMO_SK | 7,200 | 7,200 | 0 |
| INCOME_BAND | IB_INCOME_BAND_SK | 20 | 20 | 0 |
| ITEM | I_ITEM_SK | 402,000 | 402,000 | 0 |
| PROMOTION | P_PROMO_SK | 2,000 | 2,000 | 0 |
| REASON | R_REASON_SK | 70 | 70 | 0 |
| SHIP_MODE | SM_SHIP_MODE_SK | 20 | 20 | 0 |
| STORE | S_STORE_SK | 1,500 | 1,500 | 0 |
| TIME_DIM | T_TIME_SK | 86,400 | 86,400 | 0 |
| WAREHOUSE | W_WAREHOUSE_SK | 25 | 25 | 0 |
| WEB_PAGE | WP_WEB_PAGE_SK | 4,002 | 4,002 | 0 |
| WEB_SITE | WEB_SITE_SK | 78 | 78 | 0 |

#### Fact Table Composite Keys

Fact tables use composite primary keys combining item and transaction identifiers:

| Table | Primary Key Columns | Row Count |
|-------|---------------------|-----------|
| STORE_SALES | (SS_ITEM_SK, SS_TICKET_NUMBER) | 28,800,239,865 |
| CATALOG_SALES | (CS_ITEM_SK, CS_ORDER_NUMBER) | 14,399,964,710 |
| WEB_SALES | (WS_ITEM_SK, WS_ORDER_NUMBER) | 7,199,963,324 |
| STORE_RETURNS | (SR_ITEM_SK, SR_TICKET_NUMBER) | 2,879,898,629 |
| CATALOG_RETURNS | (CR_ITEM_SK, CR_ORDER_NUMBER) | 1,440,033,112 |
| WEB_RETURNS | (WR_ITEM_SK, WR_ORDER_NUMBER) | 720,020,485 |
| INVENTORY | (INV_DATE_SK, INV_ITEM_SK, INV_WAREHOUSE_SK) | 1,311,525,000 |

#### Primary Key Validation Queries

**Check all dimension tables for duplicates:**
```sql
-- Comprehensive dimension table PK validation
SELECT 'CUSTOMER' as table_name, COUNT(*) as total_rows,
       COUNT(DISTINCT C_CUSTOMER_SK) as unique_keys,
       COUNT(*) - COUNT(DISTINCT C_CUSTOMER_SK) as duplicates
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER
UNION ALL
SELECT 'ITEM', COUNT(*), COUNT(DISTINCT I_ITEM_SK),
       COUNT(*) - COUNT(DISTINCT I_ITEM_SK)
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM
UNION ALL
SELECT 'DATE_DIM', COUNT(*), COUNT(DISTINCT D_DATE_SK),
       COUNT(*) - COUNT(DISTINCT D_DATE_SK)
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
UNION ALL
SELECT 'STORE', COUNT(*), COUNT(DISTINCT S_STORE_SK),
       COUNT(*) - COUNT(DISTINCT S_STORE_SK)
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE
UNION ALL
SELECT 'CUSTOMER_ADDRESS', COUNT(*), COUNT(DISTINCT CA_ADDRESS_SK),
       COUNT(*) - COUNT(DISTINCT CA_ADDRESS_SK)
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS;
```

**Check fact table composite keys (sample):**
```sql
-- Validate STORE_SALES composite key uniqueness (sample)
SELECT
    COUNT(*) as total_rows,
    COUNT(DISTINCT SS_ITEM_SK || '-' || SS_TICKET_NUMBER) as unique_composite_keys,
    COUNT(*) - COUNT(DISTINCT SS_ITEM_SK || '-' || SS_TICKET_NUMBER) as duplicates
FROM (
    SELECT SS_ITEM_SK, SS_TICKET_NUMBER
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES
    SAMPLE (1000000 ROWS)  -- Sample for performance
);
```

### Query Patterns

#### Cross-Channel Analysis

**Compare sales across all channels:**
```sql
WITH store_channel AS (
    SELECT d.D_DATE, 'Store' as channel, SUM(ss.SS_NET_PAID) as revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
    WHERE d.D_YEAR = 2003
    GROUP BY d.D_DATE
),
catalog_channel AS (
    SELECT d.D_DATE, 'Catalog' as channel, SUM(cs.CS_NET_PAID) as revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_SALES cs
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d ON cs.CS_SOLD_DATE_SK = d.D_DATE_SK
    WHERE d.D_YEAR = 2003
    GROUP BY d.D_DATE
),
web_channel AS (
    SELECT d.D_DATE, 'Web' as channel, SUM(ws.WS_NET_PAID) as revenue
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SALES ws
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d ON ws.WS_SOLD_DATE_SK = d.D_DATE_SK
    WHERE d.D_YEAR = 2003
    GROUP BY d.D_DATE
)
SELECT D_DATE, channel, revenue
FROM store_channel
UNION ALL SELECT * FROM catalog_channel
UNION ALL SELECT * FROM web_channel
ORDER BY D_DATE, channel;
```

#### Customer Lifetime Value

**Calculate customer value across all channels:**
```sql
SELECT
    c.C_CUSTOMER_ID,
    c.C_FIRST_NAME,
    c.C_LAST_NAME,
    cd.CD_GENDER,
    ca.CA_STATE,
    COALESCE(SUM(ss.SS_NET_PAID), 0) as store_revenue,
    COALESCE(SUM(cs.CS_NET_PAID), 0) as catalog_revenue,
    COALESCE(SUM(ws.WS_NET_PAID), 0) as web_revenue,
    COALESCE(SUM(ss.SS_NET_PAID), 0) +
    COALESCE(SUM(cs.CS_NET_PAID), 0) +
    COALESCE(SUM(ws.WS_NET_PAID), 0) as total_lifetime_value
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER c
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_DEMOGRAPHICS cd
    ON c.C_CURRENT_CDEMO_SK = cd.CD_DEMO_SK
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS ca
    ON c.C_CURRENT_ADDR_SK = ca.CA_ADDRESS_SK
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
    ON c.C_CUSTOMER_SK = ss.SS_CUSTOMER_SK
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_SALES cs
    ON c.C_CUSTOMER_SK = cs.CS_BILL_CUSTOMER_SK
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SALES ws
    ON c.C_CUSTOMER_SK = ws.WS_BILL_CUSTOMER_SK
GROUP BY c.C_CUSTOMER_ID, c.C_FIRST_NAME, c.C_LAST_NAME, cd.CD_GENDER, ca.CA_STATE
HAVING total_lifetime_value > 0
ORDER BY total_lifetime_value DESC
LIMIT 100;
```

#### Product Performance

**Top selling products with profitability:**
```sql
SELECT
    i.I_ITEM_ID,
    i.I_PRODUCT_NAME,
    i.I_CATEGORY,
    i.I_CLASS,
    i.I_BRAND,
    SUM(ss.SS_QUANTITY) as units_sold,
    SUM(ss.SS_EXT_SALES_PRICE) as gross_sales,
    SUM(ss.SS_EXT_WHOLESALE_COST) as total_cost,
    SUM(ss.SS_NET_PROFIT) as net_profit,
    (SUM(ss.SS_NET_PROFIT) / NULLIF(SUM(ss.SS_EXT_WHOLESALE_COST), 0)) * 100 as profit_margin_pct
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i ON ss.SS_ITEM_SK = i.I_ITEM_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
WHERE d.D_YEAR = 2003
GROUP BY i.I_ITEM_ID, i.I_PRODUCT_NAME, i.I_CATEGORY, i.I_CLASS, i.I_BRAND
ORDER BY net_profit DESC
LIMIT 100;
```

#### Seasonal Trends

**Sales patterns by season and day of week:**
```sql
SELECT
    d.D_YEAR,
    d.D_QOY as quarter,
    d.D_DAY_NAME,
    d.D_WEEKEND,
    COUNT(*) as transaction_count,
    SUM(ss.SS_QUANTITY) as total_units,
    SUM(ss.SS_NET_PAID) as total_revenue,
    AVG(ss.SS_NET_PAID) as avg_transaction_value
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
WHERE d.D_YEAR BETWEEN 2001 AND 2003
GROUP BY d.D_YEAR, d.D_QOY, d.D_DAY_NAME, d.D_WEEKEND
ORDER BY d.D_YEAR, d.D_QOY, d.D_DAY_NAME;
```

#### Promotion Effectiveness

**Analyze promotional campaign performance:**
```sql
SELECT
    p.P_PROMO_NAME,
    p.P_CHANNEL_DMAIL,
    p.P_CHANNEL_EMAIL,
    p.P_CHANNEL_CATALOG,
    p.P_CHANNEL_TV,
    p.P_PURPOSE,
    COUNT(*) as promo_transactions,
    SUM(ss.SS_QUANTITY) as units_sold,
    SUM(ss.SS_NET_PAID) as revenue,
    SUM(ss.SS_EXT_DISCOUNT_AMT) as total_discount,
    p.P_COST as promo_cost,
    SUM(ss.SS_NET_PAID) - p.P_COST as promo_profit
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.PROMOTION p ON ss.SS_PROMO_SK = p.P_PROMO_SK
JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
WHERE p.P_PROMO_SK IS NOT NULL
  AND d.D_YEAR = 2003
GROUP BY p.P_PROMO_NAME, p.P_CHANNEL_DMAIL, p.P_CHANNEL_EMAIL,
         p.P_CHANNEL_CATALOG, p.P_CHANNEL_TV, p.P_PURPOSE, p.P_COST
ORDER BY promo_profit DESC;
```

#### Inventory Turnover

**Calculate inventory turnover rates:**
```sql
WITH avg_inventory AS (
    SELECT
        inv.INV_ITEM_SK,
        AVG(inv.INV_QUANTITY_ON_HAND) as avg_qty_on_hand
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.INVENTORY inv
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d
        ON inv.INV_DATE_SK = d.D_DATE_SK
    WHERE d.D_YEAR = 2003
    GROUP BY inv.INV_ITEM_SK
),
sales_volume AS (
    SELECT
        ss.SS_ITEM_SK,
        SUM(ss.SS_QUANTITY) as units_sold
    FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
    JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM d
        ON ss.SS_SOLD_DATE_SK = d.D_DATE_SK
    WHERE d.D_YEAR = 2003
    GROUP BY ss.SS_ITEM_SK
)
SELECT
    i.I_ITEM_ID,
    i.I_PRODUCT_NAME,
    i.I_CATEGORY,
    ai.avg_qty_on_hand,
    sv.units_sold,
    (sv.units_sold / NULLIF(ai.avg_qty_on_hand, 0)) as turnover_rate
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
JOIN avg_inventory ai ON i.I_ITEM_SK = ai.INV_ITEM_SK
JOIN sales_volume sv ON i.I_ITEM_SK = sv.SS_ITEM_SK
WHERE ai.avg_qty_on_hand > 0
ORDER BY turnover_rate DESC
LIMIT 100;
```

### Data Quality Notes

#### Verified Data Integrity

**Primary Key Uniqueness:**
- ✅ All 17 dimension tables verified with NO duplicate primary keys
- ✅ Fact table composite keys designed to prevent duplicates
- ✅ Surrogate key (_SK) columns properly indexed via clustering keys

**Data Completeness:**
- **Nullable Foreign Keys:** Many dimension foreign keys in fact tables are nullable (customer, demographics, etc.)
- **Business Rule:** Transactions without customer identification have NULL customer keys
- **Date Keys:** Most transactions have valid date keys, but pending/incomplete records may have NULLs

#### Known Patterns

**Scale Factor Characteristics:**
- SF10TCL = 10TB scale factor with thread control level optimizations
- Clustering keys defined on primary date/item columns for query performance
- Data generated using TPC-DS specification v2.x

**NULL Handling Best Practices:**
```sql
-- Use COALESCE for nullable foreign keys
SELECT
    COALESCE(c.C_CUSTOMER_ID, 'UNKNOWN') as customer_id,
    SUM(ss.SS_NET_PAID) as revenue
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER c
    ON ss.SS_CUSTOMER_SK = c.C_CUSTOMER_SK
GROUP BY customer_id;
```

**Performance Considerations:**
- Use DATE_DIM filters (D_YEAR, D_MONTH_SEQ) instead of direct date calculations
- Leverage clustering keys for optimal query performance
- Consider SAMPLE clauses for exploratory analysis on large fact tables
- Use appropriate warehouse sizes (LARGE or X-LARGE) for full fact table scans

#### Business Logic Notes

**Return Matching:**
- Returns link to sales via composite key: (ITEM_SK, TICKET/ORDER_NUMBER)
- Return dates may be NULL for pending returns
- Net loss calculations include fees, shipping, and refund methods

**Multi-Customer Scenarios:**
- Catalog/Web sales have separate bill and ship customer keys
- Bill customer and ship customer may differ (gifts, corporate orders)
- Use appropriate customer key based on analysis needs

**Channel-Specific Attributes:**
- Store sales: Simple transaction model with store, customer, item
- Catalog sales: Includes catalog pages, call centers, warehouse fulfillment
- Web sales: Includes web pages, web sites, online marketing attributes

## 📋 Quality Control Queries

### Dimension Table Duplicate Check (All Tables)

```sql
-- Complete dimension table PK validation
SELECT 'CALL_CENTER' as table_name, COUNT(*) as total_rows, COUNT(DISTINCT CC_CALL_CENTER_SK) as unique_keys, COUNT(*) - COUNT(DISTINCT CC_CALL_CENTER_SK) as duplicates FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CALL_CENTER
UNION ALL SELECT 'CATALOG_PAGE', COUNT(*), COUNT(DISTINCT CP_CATALOG_PAGE_SK), COUNT(*) - COUNT(DISTINCT CP_CATALOG_PAGE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CATALOG_PAGE
UNION ALL SELECT 'CUSTOMER', COUNT(*), COUNT(DISTINCT C_CUSTOMER_SK), COUNT(*) - COUNT(DISTINCT C_CUSTOMER_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER
UNION ALL SELECT 'CUSTOMER_ADDRESS', COUNT(*), COUNT(DISTINCT CA_ADDRESS_SK), COUNT(*) - COUNT(DISTINCT CA_ADDRESS_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_ADDRESS
UNION ALL SELECT 'CUSTOMER_DEMOGRAPHICS', COUNT(*), COUNT(DISTINCT CD_DEMO_SK), COUNT(*) - COUNT(DISTINCT CD_DEMO_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER_DEMOGRAPHICS
UNION ALL SELECT 'DATE_DIM', COUNT(*), COUNT(DISTINCT D_DATE_SK), COUNT(*) - COUNT(DISTINCT D_DATE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
UNION ALL SELECT 'HOUSEHOLD_DEMOGRAPHICS', COUNT(*), COUNT(DISTINCT HD_DEMO_SK), COUNT(*) - COUNT(DISTINCT HD_DEMO_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.HOUSEHOLD_DEMOGRAPHICS
UNION ALL SELECT 'INCOME_BAND', COUNT(*), COUNT(DISTINCT IB_INCOME_BAND_SK), COUNT(*) - COUNT(DISTINCT IB_INCOME_BAND_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.INCOME_BAND
UNION ALL SELECT 'ITEM', COUNT(*), COUNT(DISTINCT I_ITEM_SK), COUNT(*) - COUNT(DISTINCT I_ITEM_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM
UNION ALL SELECT 'PROMOTION', COUNT(*), COUNT(DISTINCT P_PROMO_SK), COUNT(*) - COUNT(DISTINCT P_PROMO_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.PROMOTION
UNION ALL SELECT 'REASON', COUNT(*), COUNT(DISTINCT R_REASON_SK), COUNT(*) - COUNT(DISTINCT R_REASON_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.REASON
UNION ALL SELECT 'SHIP_MODE', COUNT(*), COUNT(DISTINCT SM_SHIP_MODE_SK), COUNT(*) - COUNT(DISTINCT SM_SHIP_MODE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.SHIP_MODE
UNION ALL SELECT 'STORE', COUNT(*), COUNT(DISTINCT S_STORE_SK), COUNT(*) - COUNT(DISTINCT S_STORE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE
UNION ALL SELECT 'TIME_DIM', COUNT(*), COUNT(DISTINCT T_TIME_SK), COUNT(*) - COUNT(DISTINCT T_TIME_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.TIME_DIM
UNION ALL SELECT 'WAREHOUSE', COUNT(*), COUNT(DISTINCT W_WAREHOUSE_SK), COUNT(*) - COUNT(DISTINCT W_WAREHOUSE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WAREHOUSE
UNION ALL SELECT 'WEB_PAGE', COUNT(*), COUNT(DISTINCT WP_WEB_PAGE_SK), COUNT(*) - COUNT(DISTINCT WP_WEB_PAGE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_PAGE
UNION ALL SELECT 'WEB_SITE', COUNT(*), COUNT(DISTINCT WEB_SITE_SK), COUNT(*) - COUNT(DISTINCT WEB_SITE_SK) FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.WEB_SITE
ORDER BY table_name;
```

**Expected Result:** All duplicates columns should show 0.

### Referential Integrity Check

```sql
-- Check for orphaned records in STORE_SALES (sample)
SELECT
    'Missing Customers' as check_type,
    COUNT(*) as orphan_count
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER c
    ON ss.SS_CUSTOMER_SK = c.C_CUSTOMER_SK
WHERE ss.SS_CUSTOMER_SK IS NOT NULL
  AND c.C_CUSTOMER_SK IS NULL
  AND ss.SS_SOLD_DATE_SK IN (
      SELECT D_DATE_SK FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
      WHERE D_YEAR = 2003 LIMIT 100
  )
UNION ALL
SELECT
    'Missing Items',
    COUNT(*)
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.STORE_SALES ss
LEFT JOIN SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.ITEM i
    ON ss.SS_ITEM_SK = i.I_ITEM_SK
WHERE ss.SS_ITEM_SK IS NOT NULL
  AND i.I_ITEM_SK IS NULL
  AND ss.SS_SOLD_DATE_SK IN (
      SELECT D_DATE_SK FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
      WHERE D_YEAR = 2003 LIMIT 100
  );
```

**Expected Result:** Orphan counts should be 0 for valid benchmark data.

---

## 📖 Additional Resources

**TPC-DS Specification:** [http://www.tpc.org/tpcds/](http://www.tpc.org/tpcds/)

**Snowflake Sample Data Documentation:** [Snowflake Sample Data Sets](https://docs.snowflake.com/en/user-guide/sample-data-tpcds.html)

**Schema Diagram:** TPC-DS standard star schema with fact-dimension relationships

---

*Data Catalog Version: 1.0*
*Last Updated: 2025-10-19*
*Schema: SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL*
