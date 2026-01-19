# Example Workflow: Renewable Energy Data Analysis

This workflow demonstrates an end-to-end data analysis using S3 and Athena.

Matches the Practical Workflow Demo in `final_deliverables/script_outline.md`.

---

## Scenario

You have renewable energy projection data in CSV format that needs to be:
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

Use the renewable energy catalog from the California Wildfire Projections dataset:

```bash
# Download from public S3 bucket
aws s3 cp --no-sign-request s3://wfclimres/era/era-ren-collection.csv ./era-ren-collection.csv

# Or use the local sample data
cp ../sample_data/era-ren-collection.csv ./
```

**Sample Data Structure:**
```
installation,source_id,experiment_id,path
pv_distributed,ERA5,reanalysis,s3://wfclimres/era/...
pv_utility,CNRM-ESM2-1,historical,s3://wfclimres/...
wind,EC-Earth3,ssp370,s3://wfclimres/...
```

---

## Step 2: Upload to S3

```bash
# Upload file
aws s3 cp era-ren-collection.csv s3://kclabs-athena-demo-2025/renewable-energy/era-ren-collection.csv

# Verify upload
aws s3 ls s3://kclabs-athena-demo-2025/renewable-energy/
```

**Expected output:**
```
2024-01-25 10:30:00      12345 era-ren-collection.csv
```

---

## Step 3: Create Athena Database and Table

### Create Database

Run in Athena Console or via CLI:

```sql
CREATE DATABASE IF NOT EXISTS renewable_demo;
```

### Create External Table

```sql
CREATE EXTERNAL TABLE renewable_demo.energy_catalog (
  installation STRING,
  source_id STRING,
  experiment_id STRING,
  path STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2025/renewable-energy/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

> **Note:** The table is just metadata - a schema definition pointing to S3. Athena reads directly from the files. Table metadata is automatically stored in the AWS Glue Data Catalog.

### CLI Alternative

```bash
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS renewable_demo" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```

---

## Step 4: Run Analysis Queries

### Business Question: How many projections exist by energy type and scenario?

```sql
SELECT
  installation,
  experiment_id,
  COUNT(*) as projection_count
FROM renewable_demo.energy_catalog
GROUP BY installation, experiment_id
ORDER BY projection_count DESC;
```

**Expected Results:**
```
installation     experiment_id    projection_count
pv_utility       ssp370          72
pv_distributed   ssp370          72
wind             ssp370          72
...
```

### CLI Execution

```bash
# Start query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT installation, experiment_id, COUNT(*) as projection_count FROM renewable_demo.energy_catalog GROUP BY installation, experiment_id ORDER BY projection_count DESC" \
  --work-group "primary" \
  --query-execution-context Database=renewable_demo \
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
DROP TABLE IF EXISTS renewable_demo.energy_catalog;
DROP DATABASE IF EXISTS renewable_demo;
```

```bash
# Remove S3 data
aws s3 rm s3://kclabs-athena-demo-2025/renewable-energy/ --recursive

# Clean local files
rm -f era-ren-collection.csv results.csv
```

**Important:** Tables are just pointers - the S3 data persists until you explicitly delete it.

---

## Claude Code Integration

Instead of running these commands manually, ask Claude:

**Data Upload:**
```
"Upload era-ren-collection.csv to S3 in the renewable-energy folder"
```

**Table Creation:**
```
"Create an Athena table for the CSV I just uploaded. The columns are:
installation, source_id, experiment_id, path"
```

**Analysis:**
```
"Query the energy catalog table to show projection counts by installation type and scenario"
```

**Export:**
```
"Export the query results to a local CSV file"
```

**Cleanup:**
```
"Clean up the renewable_demo database and remove the S3 test data"
```

---

## Key Takeaways

1. **External Tables** - Athena tables are just metadata pointing to S3; no data copying
2. **Pay Per Query** - Cost is ~$5 per TB scanned (our demo: negligible)
3. **Results in S3** - Every query saves output to your results bucket
4. **Standard SQL** - Use familiar SQL syntax against files in S3
5. **No ETL Required** - Query data directly where it lives
