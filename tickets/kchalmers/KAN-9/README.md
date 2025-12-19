# KAN-9: Multi-Grain Order Analytics View

## Summary

Created `VW_ORDER_ANALYTICS_MULTI_GRAIN` - a view that combines line-item transaction detail with order, customer, and regional aggregations in a single queryable object.

**Note:** Originally planned as a Dynamic Table, but created as a VIEW due to `SNOWFLAKE_SAMPLE_DATA` not supporting time travel/change tracking required for dynamic tables.

## Business Purpose

Enables analysts to query transaction-level data while having access to aggregated context without writing complex SQL:
- Line-item details with order totals
- Customer lifetime value and order history
- Regional rankings and revenue percentages

## Key Metrics

| Level | Metrics Available |
|-------|-------------------|
| Line Item | Quantity, price, discount, tax, ship dates |
| Order | Order total, line count, average line value |
| Customer | Lifetime value, total orders, average order value |
| Regional | Customer rank in region, % of regional revenue |

## QC Results

| Test | Result |
|------|--------|
| Record Count | 290,583,575 (matches source) |
| Duplicates | 0 |
| Order Status Filter | Only 'F' (Fulfilled) |
| Regional % Sum | 100% per region |

## Data Distribution by Region

| Region | Line Items | Customers | Orders |
|--------|------------|-----------|--------|
| AFRICA | 58.1M | 2.0M | 14.6M |
| AMERICA | 58.1M | 2.0M | 14.6M |
| ASIA | 58.1M | 2.0M | 14.6M |
| EUROPE | 58.1M | 2.0M | 14.6M |
| MIDDLE EAST | 58.2M | 2.0M | 14.6M |

## Usage Notes

**Important:** Customer-level metrics (LTV, rank, regional %) appear on every line item for that customer. When aggregating these values, use `COUNT(DISTINCT C_CUSTKEY)` or filter to one row per customer.

## Files

- `final_deliverables/1_view_creation.sql` - Development view DDL
- `final_deliverables/2_production_deploy.sql` - Production deployment template
- `qc_validation.sql` - All QC queries
