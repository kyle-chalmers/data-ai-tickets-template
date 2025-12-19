# KAN-9: Multi-Grain Order Analytics - Technical Context

## Ticket Objective

Create a multi-grain analytics view combining TPC-H line-item detail with order, customer, and regional aggregations.

## Technical Approach

### Architecture Pattern
Used pre-aggregated CTEs joined to base grain to avoid fan-out:
1. `order_metrics` - Order-level totals from LINEITEM
2. `customer_metrics` - Customer LTV from fulfilled ORDERS only
3. `regional_totals` - Regional revenue sums
4. `customer_rankings` - RANK() and PCT calculations per region

### Key Implementation Details
- **Object Type:** VIEW (not Dynamic Table - SNOWFLAKE_SAMPLE_DATA doesn't support time travel)
- **Schema:** ANALYTICS.DEVELOPMENT
- **Base Grain:** LINEITEM (290M rows after fulfilled order filter)
- **Fulfilled Orders Only:** `O_ORDERSTATUS = 'F'` filter applied consistently

### SQL Pattern
```sql
WITH order_metrics AS (...),
     customer_metrics AS (...),  -- WHERE O_ORDERSTATUS = 'F'
     regional_totals AS (...),   -- WHERE O_ORDERSTATUS = 'F'
     customer_rankings AS (...)
SELECT ... FROM LINEITEM l
INNER JOIN order_metrics om ON ...
INNER JOIN customer_metrics cm ON ...
INNER JOIN customer_rankings cr ON ...
WHERE o.O_ORDERSTATUS = 'F'
```

## Data/Domain Insights

### TPC-H SF100 Scale
- LINEITEM: 600M rows total, 290M fulfilled
- ORDERS: 150M rows
- CUSTOMER: 15M rows
- ~4 lines per order average
- ~15 orders per customer average

### Regional Distribution
Balanced across 5 regions (~58M line items each):
- AFRICA, AMERICA, ASIA, EUROPE, MIDDLE EAST

### Grain Behavior
Customer metrics repeat on every line item. Analysts must:
- Use `COUNT(DISTINCT C_CUSTKEY)` when counting customers
- Filter to one row per customer when summing LTV or percentages

## Lessons Learned

1. **Dynamic Table Limitation:** SNOWFLAKE_SAMPLE_DATA doesn't support change tracking needed for dynamic tables. Use VIEW instead.

2. **Pre-aggregation Strategy:** Always aggregate metrics in CTEs before joining to finest grain to prevent fan-out.

3. **Consistent Filtering:** Apply business filters (like `O_ORDERSTATUS = 'F'`) in ALL relevant CTEs, not just final WHERE.

4. **Regional Percentage Validation:** Use subquery with DISTINCT customer before summing percentages to verify 100% per region.

## Relationship to Other Work

- **Related:** VW_CUSTOMER_ORDER_SUMMARY (simpler customer-grain view in same schema)
- **PRP Source:** `videos/prp_data_object_video/PRPs/02_multi_grain_analytics/`

## Repository Integration

Part of PRP workflow demonstration showing AI-assisted data object creation from requirements to deployment.
