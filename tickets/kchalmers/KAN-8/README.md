# KAN-8: Customer Order Summary View

**Ticket**: [KAN-8](https://kclabs.atlassian.net/browse/KAN-8)
**Status**: Done

## Overview

A customer-level summary view aggregating order activity from the TPC-H dataset. Enables customer segmentation, regional analysis, and revenue reporting.

## Object Details

| Attribute | Value |
|-----------|-------|
| View Name | `VW_CUSTOMER_ORDER_SUMMARY` |
| Development | `ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY` |
| Production | `ANALYTICS.PRODUCTION.VW_CUSTOMER_ORDER_SUMMARY` |
| Row Count | 9,999,832 |
| Data Grain | One row per customer |

## Business Use Cases

- **Marketing**: Identify high-value customers by market segment
- **Regional Managers**: Compare customer order patterns across geographies
- **Finance**: Customer revenue distribution for reporting

## Output Columns

| Column | Description |
|--------|-------------|
| C_CUSTKEY | Customer identifier |
| C_NAME | Customer name |
| C_MKTSEGMENT | Market segment (5 values) |
| C_ACCTBAL | Account balance |
| NATION_NAME | Customer nation (25 values) |
| REGION_NAME | Customer region (5 values) |
| TOTAL_ORDERS | Count of orders |
| TOTAL_REVENUE | Net revenue |
| AVG_ORDER_VALUE | Average revenue per order |
| FIRST_ORDER_DATE | First order date |
| LAST_ORDER_DATE | Most recent order date |

## QC Validation Results

| Test | Status |
|------|--------|
| Record Count (9,999,832) | PASS |
| Duplicate Check | PASS |
| Null Check | PASS |
| Date Range (1992-2018) | PASS |
| No Zero Orders | PASS |
| AVG Calculation | PASS |

## Key Assumptions

1. **Customer Scope**: Only includes customers with at least one order (excludes 5M customers without orders)
2. **Revenue Formula**: `L_EXTENDEDPRICE * (1 - L_DISCOUNT)` - net of discount, excludes tax
3. **Time Period**: All historical orders (no date filtering)

## Files

| File | Purpose |
|------|---------|
| `final_deliverables/1_vw_customer_order_summary.sql` | Development view DDL |
| `final_deliverables/2_production_deploy.sql` | Production deployment script |
| `qc_validation.sql` | QC validation queries |
| `source_materials/snowflake-data-object-customer-order-summary.md` | Full PRP document |

## Data Sources

- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.CUSTOMER` (15M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.ORDERS` (150M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.LINEITEM` (600M rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.NATION` (25 rows)
- `SNOWFLAKE_SAMPLE_DATA.TPCH_SF100.REGION` (5 rows)
