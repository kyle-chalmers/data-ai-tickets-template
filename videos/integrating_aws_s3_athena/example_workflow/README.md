# Example Workflow: Sales Data Analysis

This workflow demonstrates an end-to-end data analysis using S3 and Athena with Claude Code.

---

## Scenario

You have sales data in CSV format that needs to be:
1. Uploaded to S3
2. Cataloged in Glue/Athena
3. Queried for analysis
4. Results exported locally

---

## Prerequisites

- AWS CLI configured (see [setup guide](../instructions/AWS_CLI_SETUP.md))
- S3 bucket for data: `your-data-bucket`
- S3 bucket for Athena results: `your-athena-results`
- Athena workgroup configured

---

## Step 1: Prepare Sample Data

Create sample sales data:

```bash
cat > sample_sales.csv << 'EOF'
order_id,customer_id,product_name,quantity,unit_price,order_date,region
1001,C001,Widget A,5,29.99,2024-01-15,North
1002,C002,Widget B,3,49.99,2024-01-16,South
1003,C001,Widget C,2,99.99,2024-01-17,North
1004,C003,Widget A,10,29.99,2024-01-18,East
1005,C002,Widget B,1,49.99,2024-01-19,West
1006,C004,Widget C,4,99.99,2024-01-20,South
1007,C001,Widget A,7,29.99,2024-01-21,North
1008,C005,Widget B,2,49.99,2024-01-22,East
1009,C003,Widget C,1,99.99,2024-01-23,West
1010,C004,Widget A,3,29.99,2024-01-24,South
EOF
```

---

## Step 2: Upload to S3

```bash
# Set variables
BUCKET="your-data-bucket"
PREFIX="sales_data"

# Upload file
aws s3 cp sample_sales.csv s3://${BUCKET}/${PREFIX}/sample_sales.csv

# Verify upload
aws s3 ls s3://${BUCKET}/${PREFIX}/
```

**Expected output:**
```
2024-01-25 10:30:00        456 sample_sales.csv
```

---

## Step 3: Create Athena Database and Table

### Create Database

```bash
RESULTS_BUCKET="your-athena-results"

aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS sales_analytics" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://${RESULTS_BUCKET}/
```

### Create External Table

```bash
BUCKET="your-data-bucket"
RESULTS_BUCKET="your-athena-results"

aws athena start-query-execution \
  --query-string "
    CREATE EXTERNAL TABLE IF NOT EXISTS sales_analytics.sales (
      order_id INT,
      customer_id STRING,
      product_name STRING,
      quantity INT,
      unit_price DOUBLE,
      order_date DATE,
      region STRING
    )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION 's3://${BUCKET}/sales_data/'
    TBLPROPERTIES ('skip.header.line.count'='1')
  " \
  --work-group "primary" \
  --query-execution-context Database=sales_analytics \
  --result-configuration OutputLocation=s3://${RESULTS_BUCKET}/
```

### Verify Table Creation

```bash
# List tables
aws glue get-tables --database-name sales_analytics \
  | jq -r '.TableList[].Name'

# Check schema
aws glue get-table \
  --database-name sales_analytics \
  --name sales \
  | jq '.Table.StorageDescriptor.Columns'
```

---

## Step 4: Run Analysis Queries

### Helper Function for Queries

```bash
# Function to run query and wait for results
run_athena_query() {
  local query="$1"
  local database="${2:-sales_analytics}"

  QUERY_ID=$(aws athena start-query-execution \
    --query-string "$query" \
    --work-group "primary" \
    --query-execution-context Database=$database \
    --result-configuration OutputLocation=s3://${RESULTS_BUCKET}/ \
    --output text --query 'QueryExecutionId')

  echo "Query ID: $QUERY_ID"

  # Wait for completion
  while true; do
    STATE=$(aws athena get-query-execution \
      --query-execution-id $QUERY_ID \
      --query 'QueryExecution.Status.State' \
      --output text)

    if [[ "$STATE" == "SUCCEEDED" ]]; then
      echo "Query succeeded!"
      break
    elif [[ "$STATE" == "FAILED" || "$STATE" == "CANCELLED" ]]; then
      echo "Query $STATE"
      aws athena get-query-execution \
        --query-execution-id $QUERY_ID \
        --query 'QueryExecution.Status.StateChangeReason'
      return 1
    fi
    sleep 1
  done

  # Return results
  aws athena get-query-results --query-execution-id $QUERY_ID
}
```

### Query 1: Total Sales by Region

```bash
run_athena_query "
  SELECT
    region,
    COUNT(*) as order_count,
    SUM(quantity) as total_units,
    ROUND(SUM(quantity * unit_price), 2) as total_revenue
  FROM sales
  GROUP BY region
  ORDER BY total_revenue DESC
"
```

### Query 2: Top Customers

```bash
run_athena_query "
  SELECT
    customer_id,
    COUNT(*) as order_count,
    ROUND(SUM(quantity * unit_price), 2) as total_spent
  FROM sales
  GROUP BY customer_id
  ORDER BY total_spent DESC
  LIMIT 5
"
```

### Query 3: Product Performance

```bash
run_athena_query "
  SELECT
    product_name,
    SUM(quantity) as units_sold,
    ROUND(AVG(unit_price), 2) as avg_price,
    ROUND(SUM(quantity * unit_price), 2) as revenue
  FROM sales
  GROUP BY product_name
  ORDER BY revenue DESC
"
```

---

## Step 5: Export Results

### Download Query Results

```bash
# Run a query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT * FROM sales ORDER BY order_date" \
  --work-group "primary" \
  --query-execution-context Database=sales_analytics \
  --result-configuration OutputLocation=s3://${RESULTS_BUCKET}/ \
  --output text --query 'QueryExecutionId')

# Wait for completion
sleep 5

# Download results CSV
aws s3 cp s3://${RESULTS_BUCKET}/${QUERY_ID}.csv ./query_results.csv

# View results
cat query_results.csv
```

### Export Summary Report

```bash
# Create summary query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "
    SELECT
      'Total Orders' as metric, CAST(COUNT(*) AS VARCHAR) as value FROM sales
    UNION ALL
    SELECT
      'Total Revenue', CAST(ROUND(SUM(quantity * unit_price), 2) AS VARCHAR) FROM sales
    UNION ALL
    SELECT
      'Unique Customers', CAST(COUNT(DISTINCT customer_id) AS VARCHAR) FROM sales
    UNION ALL
    SELECT
      'Avg Order Value', CAST(ROUND(AVG(quantity * unit_price), 2) AS VARCHAR) FROM sales
  " \
  --work-group "primary" \
  --query-execution-context Database=sales_analytics \
  --result-configuration OutputLocation=s3://${RESULTS_BUCKET}/ \
  --output text --query 'QueryExecutionId')

sleep 5
aws s3 cp s3://${RESULTS_BUCKET}/${QUERY_ID}.csv ./summary_report.csv
```

---

## Step 6: Cleanup (Optional)

```bash
# Remove test data from S3
aws s3 rm s3://${BUCKET}/sales_data/ --recursive

# Drop table
aws athena start-query-execution \
  --query-string "DROP TABLE IF EXISTS sales_analytics.sales" \
  --work-group "primary"

# Drop database
aws athena start-query-execution \
  --query-string "DROP DATABASE IF EXISTS sales_analytics" \
  --work-group "primary"

# Clean local files
rm -f sample_sales.csv query_results.csv summary_report.csv
```

---

## Claude Code Integration

Instead of running these commands manually, ask Claude:

**Data Upload:**
```
"Upload sample_sales.csv to S3 bucket my-data-bucket in the sales_data folder"
```

**Table Creation:**
```
"Create an Athena table for the CSV I just uploaded. The columns are:
order_id, customer_id, product_name, quantity, unit_price, order_date, region"
```

**Analysis:**
```
"Query the sales table to show total revenue by region, sorted highest to lowest"
```

**Export:**
```
"Export the full sales table to a local CSV file"
```

---

## Extending This Workflow

### Add Partitioning

For larger datasets, partition by date:

```sql
CREATE EXTERNAL TABLE sales_partitioned (
  order_id INT,
  customer_id STRING,
  product_name STRING,
  quantity INT,
  unit_price DOUBLE,
  region STRING
)
PARTITIONED BY (order_date DATE)
STORED AS PARQUET
LOCATION 's3://bucket/sales_partitioned/'
```

### Use Parquet Format

Convert CSV to Parquet for better performance:

```sql
CREATE TABLE sales_parquet
WITH (
  format = 'PARQUET',
  external_location = 's3://bucket/sales_parquet/'
) AS
SELECT * FROM sales
```

### Schedule Regular Updates

Combine with AWS Lambda or Step Functions to:
- Automatically process new files uploaded to S3
- Run daily/weekly analysis queries
- Export reports to stakeholders

---

## Files Created

After running this workflow:

```
example_workflow/
├── README.md           # This file
├── sample_sales.csv    # Sample data (created during workflow)
├── query_results.csv   # Full data export
└── summary_report.csv  # Summary metrics
```
