# Data Object Request: Multi-Grain Order Analytics

## Request Type
- **Operation:** CREATE_NEW
- **Scope:** SINGLE_OBJECT

## Object Definition
- **Primary Object Name:** DT_ORDER_ANALYTICS_MULTI_GRAIN
- **Object Type:** DYNAMIC_TABLE
- **Target Schema Layer:** ANALYTICS (or equivalent for sample data)

## Data Grain & Aggregation
- **Grain:** MIXED - One row per LINE ITEM, but enriched with multiple aggregation levels:
  - Line-item level detail (finest grain)
  - Order-level aggregations (order totals, item counts)
  - Customer-level metrics (customer lifetime value, order frequency)
  - Regional rankings (how customer compares to region)
- **Time Period:** All historical orders
- **Key Dimensions:** L_ORDERKEY, L_LINENUMBER (primary grain), with customer and regional context

## Business Context
**Business Purpose:** Create a comprehensive analytics table that enables analysis at multiple levels without requiring users to write complex SQL. This pattern mirrors real-world scenarios where analysts need to see detail while also having aggregated context available.

**Primary Use Cases:**
- Analysts need line-item detail while seeing order and customer context
- Regional managers want to see individual transactions with performance rankings
- Finance needs transaction-level data with roll-up metrics for reconciliation

**Key Metrics/KPIs:**
- Line-item level: Extended price, discount, quantity, tax
- Order level: Order total, line count, average line value
- Customer level: Lifetime value, total orders, average order value, customer rank in region
- Regional level: Region totals, customer's percentage of regional revenue

## Data Sources
**New/Target Sources:**
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM` - Primary grain table (600M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS` - Order context (150M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER` - Customer dimension (15M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION` - Nation reference (25 rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION` - Region reference (5 rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.PART` - Part details (20M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.SUPPLIER` - Supplier details (1M rows)

**Expected Relationships:**
- LINEITEM.L_ORDERKEY → ORDERS.O_ORDERKEY (many:1)
- ORDERS.O_CUSTKEY → CUSTOMER.C_CUSTKEY (many:1)
- CUSTOMER.C_NATIONKEY → NATION.N_NATIONKEY (many:1)
- NATION.N_REGIONKEY → REGION.R_REGIONKEY (many:1)
- LINEITEM.L_PARTKEY → PART.P_PARTKEY (many:1)
- LINEITEM.L_SUPPKEY → SUPPLIER.S_SUPPKEY (many:1)

**Data Quality Considerations:**
- Joining multiple grains creates opportunities for fan-out issues
- Window functions at different partition levels must be carefully implemented
- Performance will be critical given the 600M+ row base table

**Data Structure:**
- JOIN pattern with multiple CTE-based aggregation layers
- Similar pattern to `CAST_VOTING_RECORD.ANALYTICS.VW_FINAL_TABLEAU_REPORT` which combines:
  - Base grain CTE (individual marks/line items)
  - Aggregation CTE (ballot-level/order-level summaries)
  - Ranking CTE (precinct-level/regional rankings)
  - Final SELECT joining all grains

**Column Values:**
- Part names and types contain descriptive text
- Return flags (R, A, N) may need business-friendly labels
- Line status codes should be documented

## Requirements
- **Performance:** As fast as possible - dynamic table should handle refresh efficiently
- **Refresh Pattern:** On-demand with reasonable lag setting (e.g., 1 hour)
- **Data Retention:** All time

## Ticket Information
- **Existing Jira Ticket:** CREATE_NEW (for demonstration purposes)
- **Stakeholders:** Video demonstration audience

## Additional Context
This is an advanced demonstration showing how the PRP workflow handles complex, multi-grain analytics scenarios. The goal is to demonstrate that AI can navigate the complexity that typically challenges data engineers.

**Pattern Reference:** `CAST_VOTING_RECORD.ANALYTICS.VW_FINAL_TABLEAU_REPORT`

This view demonstrates the pattern we want to replicate:
1. Base CTE with finest grain (individual votes/line items)
2. Aggregation CTEs at coarser grains (ballot totals/order totals)
3. Ranking CTEs with window functions (precinct rankings/regional rankings)
4. Final SELECT joining all levels together

**Expected Output Columns:**

*Line-Item Level (Primary Grain):*
- L_ORDERKEY, L_LINENUMBER
- L_QUANTITY, L_EXTENDEDPRICE, L_DISCOUNT, L_TAX
- L_RETURNFLAG, L_LINESTATUS
- L_SHIPDATE, L_RECEIPTDATE
- PART_NAME, SUPPLIER_NAME

*Order Level (Aggregated):*
- ORDER_TOTAL
- ORDER_LINE_COUNT
- ORDER_AVG_LINE_VALUE

*Customer Level (Aggregated):*
- CUSTOMER_NAME, CUSTOMER_SEGMENT
- CUSTOMER_LIFETIME_VALUE
- CUSTOMER_TOTAL_ORDERS
- CUSTOMER_AVG_ORDER_VALUE

*Regional Level (Rankings):*
- NATION_NAME, REGION_NAME
- CUSTOMER_RANK_IN_REGION (by lifetime value)
- CUSTOMER_PCT_OF_REGIONAL_REVENUE

**Complexity Challenges:**
1. **Grain Mixing:** Joining line-item detail with customer aggregations without causing fan-out
2. **Window Functions:** Computing rankings at regional level while preserving line-item grain
3. **Performance:** Efficient execution despite 600M+ base rows
4. **Readability:** Maintaining clear, documented SQL despite complexity
