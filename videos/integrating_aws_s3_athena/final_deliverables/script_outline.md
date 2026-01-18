# AWS S3 + Athena Integration - Script Outline

## HOOK

- **Option 1:** "What if you never had to open the AWS Console again to query your data lake?"

- **Option 2:** "I used to spend 15 minutes just clicking through the AWS Console to run a simple query. Now I do it in one sentence. Let me show you how."

- **Option 3:** "Your data lake is sitting there, full of insights. But if you're still clicking through S3 and Athena in the browser, you're working harder than you need to."

---

## INTRO

- The real power here isn't just running AWS commands from your terminal
- Claude can take care of searching in S3 and querying Athena for you
- You describe what you want in plain English
- Claude figures out the right S3 paths, writes the Athena queries, handles the async execution
- Your job? Just QC the results
- This is delegation, not automation

---

## DEMO DATASET

### California Wildfire & Renewable Energy Projections

We're using a real climate research dataset from the AWS Data Exchange:

- **Source:** Cal-Adapt / Eagle Rock Analytics
- **S3 Location:** `s3://wfclimres/` (public dataset, us-west-2)
- **Database:** `wildfire_demo`
- **Table:** `renewable_energy_catalog` (216 rows)

**What's in it:**
- Climate model projections for California renewable energy generation
- Solar PV (distributed and utility-scale) and wind power capacity factors
- Multiple climate scenarios: historical, reanalysis, and future projections (SSP370)
- Data from various climate models: EC-Earth3, ERA5, MIROC6, MPI-ESM1-2-HR, TaiESM1

**Sample columns:**
| Column | Description |
|--------|-------------|
| `installation` | Energy type (pv_distributed, pv_utility, wind) |
| `source_id` | Climate model used |
| `experiment_id` | Scenario (historical, reanalysis, ssp370) |
| `table_id` | Time resolution (1hr, day) |
| `variable_id` | Metric (cf = capacity factor, gen = generation) |
| `path` | S3 location of the actual data files |

This catalog points to terabytes of actual climate projection data - perfect for demonstrating how to explore and query a real data lake.

---

## AWS CONSOLE NAVIGATION

*Show viewers where these resources live in the AWS interface*

### Athena Query Editor
1. Go to: **AWS Console → Athena**
2. Left sidebar: Click **"Query editor"**
3. Select database: **`wildfire_demo`** from the dropdown
4. Tables panel: See **`renewable_energy_catalog`** listed
5. Run: `SELECT * FROM wildfire_demo.renewable_energy_catalog LIMIT 20;`

### Key Console URLs (us-west-2)
- **Athena Query Editor:** `console.aws.amazon.com/athena/home?region=us-west-2#/query-editor`
- **S3 Buckets:** `s3.console.aws.amazon.com/s3/buckets/`

### What to Show in the Interface
- Database and table structure in the left panel
- Query results displayed in a grid
- Query history and saved queries
- S3 results bucket where Athena writes output CSVs

---

## THE LESSONS AND THE VALUE

### Section 1: Setup and Configuration
- Installing AWS CLI v2 on Mac/Windows/Linux
- Running `aws configure` with access keys
- Setting up IAM permissions for S3 and Athena (least privilege)
- Verifying your setup: `aws sts get-caller-identity`
- Pro tip: Using named profiles for multiple AWS accounts

### Section 2: S3 Operations
- Listing buckets and exploring objects: `aws s3 ls`
- Uploading files to S3 in one command: `aws s3 cp`
- Syncing entire directories: `aws s3 sync`
- Working with partitioned data lake structures
- Generating presigned URLs for sharing

### Section 3: Athena Queries
- Running SQL queries from the terminal: `aws athena start-query-execution`
- Waiting for results and fetching them: `aws athena get-query-results`
- Managing databases and tables
- Cost optimization: workgroups and query limits
- Parsing results with jq

### Section 4: Practical Workflow Demo

*Complete end-to-end: CSV → S3 → Athena Table → Query → Export*

---

#### Step 1: Upload Data to S3
*Show: S3 Console + CLI*

**Sample data:** `sample_sales.csv` (10 rows of regional sales)
```
order_id,customer_id,product_name,quantity,unit_price,order_date,region
1001,C001,Widget A,5,29.99,2024-01-15,North
1002,C002,Widget B,3,49.99,2024-01-16,South
...
```

**In S3 Console:**
1. Navigate to `s3://kclabs-athena-demo-2025/`
2. Create folder: `sales-demo/`
3. Upload `sample_sales.csv`
4. Show the file listed with size and timestamp

**CLI equivalent:**
```bash
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/
aws s3 ls s3://kclabs-athena-demo-2025/sales-demo/
```

**Talking point:** "Data's in S3. Now let's make it queryable."

---

#### Step 2: Create Database and Table in Athena
*Show: Athena Query Editor*

**In Athena Console:**
1. Open Query Editor
2. Run: Create database
   ```sql
   CREATE DATABASE IF NOT EXISTS sales_demo;
   ```
3. Run: Create external table pointing to S3
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
4. Show new database/table appear in left panel
5. Click table → Preview (shows the data)

**Talking point:** "The table is just metadata - a schema definition pointing to S3. Athena reads directly from the files."

---

#### Step 3: Run Analysis Query
*Show: Query execution, results grid, cost*

**Business question:** "What's the total revenue by region?"

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

**What to point out:**
- Results grid with aggregated data
- Query execution time (bottom of screen)
- Data scanned (cost = ~$5 per TB scanned)
- Query history tab

**Talking point:** "Standard SQL, but running directly against files in S3. No data loading, no ETL pipeline - just query."

---

#### Step 4: Export Results to S3
*Show: Results bucket, download CSV*

**In S3 Console:**
1. Navigate to results bucket: `s3://kclabs-athena-results-2025/`
2. Find the query result file (named by query execution ID)
3. Show the `.csv` and `.metadata` files Athena creates
4. Download the CSV

**CLI equivalent:**
```bash
aws s3 cp s3://kclabs-athena-results-2025/{query-id}.csv ./results.csv
cat ./results.csv
```

**Talking point:** "Every Athena query automatically saves results to S3. You can grab the CSV anytime, share it, or feed it into another process."

---

#### Step 5: Cleanup (Show Good Hygiene)

```sql
DROP TABLE IF EXISTS sales_demo.sales;
DROP DATABASE IF EXISTS sales_demo;
```

```bash
aws s3 rm s3://kclabs-athena-demo-2025/sales-demo/ --recursive
```

**Talking point:** "Clean up when you're done - tables are just pointers, but the S3 data persists until you delete it."

---

## CLOSING

- Thanks so much for watching
- If this helped you work faster with S3 and Athena, drop a like and subscribe
- See you in the next one
