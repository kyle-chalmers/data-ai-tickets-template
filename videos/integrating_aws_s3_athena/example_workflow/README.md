# Example Workflow: Sales Data Analysis

This workflow demonstrates an end-to-end data analysis using S3 and Athena.

Matches the Practical Workflow Demo in `final_deliverables/script_outline.md`.

---

## Scenario

You have sales data in CSV format that needs to be:
1. Uploaded to S3
2. Cataloged in Athena (creates table pointing to S3)
3. Queried for analysis
4. Results exported locally

---

## Prerequisites

- AWS CLI configured (see [setup guide](../instructions/AWS_CLI_SETUP.md))
- S3 buckets:
  - Data: `kclabs-athena-demo-2025`
  - Results: `kclabs-athena-results-2025`
- Region: `us-west-2`

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
# Upload file
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/sample_sales.csv

# Verify upload
aws s3 ls s3://kclabs-athena-demo-2025/sales-demo/
```

**Expected output:**
```
2024-01-25 10:30:00        509 sample_sales.csv
```

---

## Step 3: Create Athena Database and Table

### Create Database

Run in Athena Console or via CLI:

```sql
CREATE DATABASE IF NOT EXISTS sales_demo;
```

### Create External Table

```sql
CREATE EXTERNAL TABLE sales_demo.sales (
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
LOCATION 's3://kclabs-athena-demo-2025/sales-demo/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

> **Note:** The table is just metadata - a schema definition pointing to S3. Athena reads directly from the files. Table metadata is automatically stored in the AWS Glue Data Catalog.

### CLI Alternative

```bash
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS sales_demo" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```

---

## Step 4: Run Analysis Queries

### Business Question: What's the total revenue by region?

```sql
SELECT
  region,
  COUNT(*) as order_count,
  SUM(quantity) as total_units,
  ROUND(SUM(quantity * unit_price), 2) as total_revenue
FROM sales_demo.sales
GROUP BY region
ORDER BY total_revenue DESC;
```

**Expected Results:**
```
region    order_count    total_units    total_revenue
South     3              10             639.90
North     3              14             559.86
East      2              12             399.88
West      2              2              149.98
```

### CLI Execution

```bash
# Start query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT region, COUNT(*) as order_count, SUM(quantity) as total_units, ROUND(SUM(quantity * unit_price), 2) as total_revenue FROM sales_demo.sales GROUP BY region ORDER BY total_revenue DESC" \
  --work-group "primary" \
  --query-execution-context Database=sales_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/ \
  --output text --query 'QueryExecutionId')

echo "Query ID: $QUERY_ID"

# Wait for completion (poll status)
aws athena get-query-execution --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Status.State' --output text

# Get results
aws athena get-query-results --query-execution-id $QUERY_ID
```

---

## Step 5: Export Results

### Download Query Results

Every Athena query automatically saves results to S3. Download the CSV:

```bash
# Download results CSV (replace QUERY_ID)
aws s3 cp s3://kclabs-athena-results-2025/${QUERY_ID}.csv ./results.csv

# View results
cat results.csv
```

---

## Step 6: Cleanup

Clean up test resources:

```sql
DROP TABLE IF EXISTS sales_demo.sales;
DROP DATABASE IF EXISTS sales_demo;
```

```bash
# Remove S3 data
aws s3 rm s3://kclabs-athena-demo-2025/sales-demo/ --recursive

# Clean local files
rm -f sample_sales.csv results.csv
```

**Important:** Tables are just pointers - the S3 data persists until you explicitly delete it.

---

## Claude Code Integration

Instead of running these commands manually, ask Claude:

**Data Upload:**
```
"Upload sample_sales.csv to S3 in the sales-demo folder"
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
"Export the query results to a local CSV file"
```

**Cleanup:**
```
"Clean up the sales_demo database and remove the S3 test data"
```

---

## Key Takeaways

1. **External Tables** - Athena tables are just metadata pointing to S3; no data copying
2. **Pay Per Query** - Cost is ~$5 per TB scanned (our demo: negligible)
3. **Results in S3** - Every query saves output to your results bucket
4. **Standard SQL** - Use familiar SQL syntax against files in S3
5. **No ETL Required** - Query data directly where it lives
