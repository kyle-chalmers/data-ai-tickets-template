# US Customer Purchase Analysis

## Business Question

Analyze US customers from the SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL database:
1. How many customers are from the United States?
2. How many bought something in the last month?
3. What was the average transaction price?
4. What was the total sales amount?

## Key Findings

### Summary Metrics
- **Total US Customers**: 297,366
- **Customers with Purchases (Dec 2002)**: 267,821 (90.1%)
- **Total Transactions**: 712,831
- **Average Transaction Price**: $21,567.78
- **Total Sales Amount**: $15,374,183,702.33

### Sales Channel Breakdown (December 2002)
| Channel | Orders | Customers | Total Sales |
|---------|--------|-----------|-------------|
| STORE   | 372,645 | 203,164 | $7,411,104,846.97 |
| CATALOG | 247,462 | 169,349 | $5,288,716,569.87 |
| WEB     | 92,724  | 79,898  | $2,674,362,285.49 |
| **TOTAL** | **712,831** | **267,821** | **$15,374,183,702.33** |

## Methodology

### Data Sources
- **Database**: SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL
- **Tables Used**:
  - CUSTOMER (customer demographics)
  - CUSTOMER_ADDRESS (address information)
  - STORE_SALES, WEB_SALES, CATALOG_SALES (transaction data)
  - DATE_DIM (date dimension)

### Analysis Period
- **Data Date Range**: 1998-01-02 to 2003-01-02
- **Analysis Period**: December 2002 (most recent complete calendar month)
  - Start Date: 2002-12-01
  - End Date: 2002-12-31
  - Days: 31

### Customer Identification
- Used `C_BIRTH_COUNTRY = 'UNITED STATES'` from CUSTOMER table
- Note: CUSTOMER_ADDRESS table only contains US addresses in this sample dataset

### Transaction Aggregation
- Combined all three sales channels (STORE, WEB, CATALOG)
- Grouped by order/ticket number to calculate per-transaction totals
- Each order can contain multiple line items that are summed together
- Used `NET_PAID_INC_TAX` field for transaction amounts (includes tax)

## Assumptions

1. **Country Definition**: Used birth country (`C_BIRTH_COUNTRY`) to identify US customers
2. **Last Month Definition**: Most recent complete calendar month (December 2002) based on available data
3. **Transaction Price**: Calculated as sum of all line items per order/ticket, then averaged across all orders
4. **Sales Channels**: Combined STORE, WEB, and CATALOG sales for complete picture
5. **Amount Field**: Used `NET_PAID_INC_TAX` which represents the final amount paid including tax

## Quality Control

All QC checks passed successfully:

1. **Customer Count Validation**: Confirmed 297,366 US customers
2. **Date Range Validation**: Verified December 2002 has correct 31-day range
3. **Sales Channel Breakdown**: Validated individual channel totals sum to overall total
4. **Transaction Count**: Confirmed 712,831 distinct orders across all channels

See `qc_queries/` folder for detailed validation queries.

## File Organization

### final_deliverables/
1. `1_main_analysis.sql` - Primary analysis query with full documentation
2. `2_analysis_results.csv` - Summary metrics output
3. `3_sales_channel_breakdown.csv` - Breakdown by sales channel

### qc_queries/
1. `1_customer_count_validation.sql` - Validates US customer count
2. `2_date_range_validation.sql` - Verifies December 2002 date range
3. `3_sales_channel_breakdown.sql` - Channel-level sales validation
4. `4_total_transaction_count.sql` - Confirms total transaction count

## How to Run

### Main Analysis
```bash
snow sql -q "$(cat final_deliverables/1_main_analysis.sql)" --format csv
```

### Quality Control Queries
```bash
# Run all QC queries
for file in qc_queries/*.sql; do
    echo "Running: $file"
    snow sql -q "$(cat $file)" --format csv
done
```

## Technical Notes

- All queries use INNER JOINs to ensure only valid transactions are included
- CTEs are used for clarity and modularity
- Transaction amounts are rounded to 2 decimal places for readability
- Date filtering uses surrogate keys (D_DATE_SK) for optimal performance
- Customer identification differs by sales channel:
  - STORE_SALES: SS_CUSTOMER_SK
  - WEB_SALES: WS_BILL_CUSTOMER_SK
  - CATALOG_SALES: CS_BILL_CUSTOMER_SK

## Data Quality Observations

1. High purchase rate: 90.1% of US customers made at least one purchase in December 2002
2. Store sales dominate: 52.3% of total orders, 48.2% of total revenue
3. Multi-channel engagement: Some customers shop across multiple channels
4. Sample dataset limitation: Only US addresses available in CUSTOMER_ADDRESS table
