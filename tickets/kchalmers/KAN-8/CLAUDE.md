# Claude Context: KAN-8 - VW_CUSTOMER_ORDER_SUMMARY

**Ticket**: [KAN-8](https://kclabs.atlassian.net/browse/KAN-8)

## Object Summary

Customer-level order summary view built from TPC-H SF100 dataset. Aggregates order and line item data to provide customer metrics for segmentation and revenue analysis.

## Technical Details

### View Location
- **Development**: `ANALYTICS.DEVELOPMENT.VW_CUSTOMER_ORDER_SUMMARY`
- **Production**: `ANALYTICS.PRODUCTION.VW_CUSTOMER_ORDER_SUMMARY`

### Data Architecture
```
REGION (5) → NATION (25) → CUSTOMER (15M) → ORDERS (150M) → LINEITEM (600M)
                              ↓
                    VW_CUSTOMER_ORDER_SUMMARY (10M)
```

### Key Business Logic

1. **INNER JOIN Pattern**: Excludes 5M customers without orders
2. **Revenue Calculation**: `SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT))`
3. **Aggregation**: Customer grain with order metrics

### Query Pattern
```sql
-- Two-stage aggregation for performance
WITH customer_orders AS (
    -- First: Aggregate line items to order level
    SELECT O_CUSTKEY, O_ORDERKEY, O_ORDERDATE,
           SUM(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS order_revenue
    FROM ORDERS JOIN LINEITEM ON O_ORDERKEY = L_ORDERKEY
    GROUP BY O_CUSTKEY, O_ORDERKEY, O_ORDERDATE
),
customer_metrics AS (
    -- Second: Aggregate orders to customer level
    SELECT O_CUSTKEY,
           COUNT(DISTINCT O_ORDERKEY) AS total_orders,
           SUM(order_revenue) AS total_revenue,
           MIN(O_ORDERDATE) AS first_order_date,
           MAX(O_ORDERDATE) AS last_order_date
    FROM customer_orders
    GROUP BY O_CUSTKEY
)
-- Final: Join with customer and geography dimensions
SELECT c.*, n.N_NAME, r.R_NAME, cm.*
FROM CUSTOMER c
JOIN customer_metrics cm ON c.C_CUSTKEY = cm.O_CUSTKEY
JOIN NATION n ON c.C_NATIONKEY = n.N_NATIONKEY
JOIN REGION r ON n.N_REGIONKEY = r.R_REGIONKEY
```

## Validated Metrics

| Metric | Value |
|--------|-------|
| Total Rows | 9,999,832 |
| Market Segments | 5 (~20% each) |
| Regions | 5 (~20% each) |
| Date Range | 1992-01-01 to 1998-08-02 |
| Total Revenue | ~$21.8 trillion |

## Modification Notes

- Adding new columns: Modify both CTEs if aggregation needed
- Changing revenue formula: Update `customer_orders` CTE
- Adding date filters: Add WHERE clause to first CTE
- Performance: Consider materializing as table for heavy usage

## Related Objects

- Source: TPC-H SF100 tables in `SNOWFLAKE_SAMPLE_DATA`
- No downstream dependencies (new object)

## PRP Reference

Full PRP document: `source_materials/snowflake-data-object-customer-order-summary.md`
