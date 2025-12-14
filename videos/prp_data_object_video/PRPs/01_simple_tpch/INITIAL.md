# Data Object Request: Customer Order Summary

## Request Type
- **Operation:** CREATE_NEW
- **Scope:** SINGLE_OBJECT

## Object Definition
- **Primary Object Name:** DT_CUSTOMER_ORDER_SUMMARY
- **Object Type:** DYNAMIC_TABLE
- **Target Schema Layer:** ANALYTICS (or equivalent for sample data)

## Data Grain & Aggregation
- **Grain:** One row per customer
- **Time Period:** All historical orders (no date filter)
- **Key Dimensions:** C_CUSTKEY (customer identifier), C_MKTSEGMENT, NATION, REGION

## Business Context
**Business Purpose:** Create a customer-level summary of order activity to enable customer segmentation analysis, regional performance comparisons, and revenue concentration analysis.

**Primary Use Cases:**
- Marketing team needs to identify high-value customers by market segment
- Regional managers want to compare customer order patterns across geographies
- Finance requires customer revenue distribution for reporting

**Key Metrics/KPIs:**
- Total order count per customer
- Total revenue (sum of extended price minus discounts)
- Average order value
- First and last order dates (customer tenure)

## Data Sources
**New/Target Sources:**
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER` - Primary customer dimension (15M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS` - Order header information (150M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM` - Line item detail for revenue calculations (600M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION` - Nation reference (25 rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION` - Region reference (5 rows)

**Expected Relationships:**
- CUSTOMER.C_CUSTKEY → ORDERS.O_CUSTKEY (1:many)
- ORDERS.O_ORDERKEY → LINEITEM.L_ORDERKEY (1:many)
- CUSTOMER.C_NATIONKEY → NATION.N_NATIONKEY (many:1)
- NATION.N_REGIONKEY → REGION.R_REGIONKEY (many:1)

**Data Quality Considerations:**
- TPC-H is a clean, synthetic dataset with no data quality issues expected
- All foreign keys should have valid references
- No null values in key columns

**Data Structure:**
- JOIN pattern - enrich customer records with aggregated order metrics and geographic dimensions

**Column Values:**
- Customer names follow pattern "Customer#XXXXXXXXX" - could be retained or simplified
- Market segments are standardized codes (AUTOMOBILE, BUILDING, FURNITURE, HOUSEHOLD, MACHINERY)

## Requirements
- **Performance:** As fast as possible - this is a demonstration object
- **Refresh Pattern:** On-demand (dynamic table will auto-refresh based on lag setting)
- **Data Retention:** All time

## Ticket Information
- **Existing Jira Ticket:** CREATE_NEW (for demonstration purposes)
- **Stakeholders:** Video demonstration audience

## Additional Context
This is a demonstration data object for the PRP video tutorial. The goal is to show a clean, straightforward example of the PRP workflow using Snowflake's sample TPC-H dataset.

**TPC-H Documentation:** https://docs.snowflake.com/en/user-guide/sample-data-tpch

**Expected Output Columns:**
- C_CUSTKEY
- C_NAME
- C_MKTSEGMENT
- NATION_NAME
- REGION_NAME
- TOTAL_ORDERS
- TOTAL_REVENUE
- AVG_ORDER_VALUE
- FIRST_ORDER_DATE
- LAST_ORDER_DATE
