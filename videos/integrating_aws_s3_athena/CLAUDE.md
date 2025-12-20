# AWS CLI Reference for S3 and Athena

Quick reference for AWS CLI syntax and common patterns for data lake operations.

---

## Current Project Setup

**AWS Account:** 987540640696 (kclabsai)
**IAM User:** kylechalmers-cli
**Region:** us-west-2

### S3 Buckets Created

| Bucket | Purpose |
|--------|---------|
| `kclabs-athena-demo-2025` | Demo data storage |
| `kclabs-athena-results-2025` | Athena query results |

### Athena Resources

| Resource | Name |
|----------|------|
| **Database** | `wildfire_demo` |
| **Table** | `renewable_energy_catalog` |

### Sample Data Source

**California Wildfire Projections Dataset**
- **S3 Location:** `s3://wfclimres/`
- **Region:** us-west-2
- **Provider:** Cal-Adapt / Eagle Rock Analytics
- **AWS Marketplace:** https://aws.amazon.com/marketplace/pp/prodview-ynmdoogdmotne

### Test Query

```bash
# Query the renewable energy catalog
aws athena start-query-execution \
  --query-string "SELECT installation, source_id, experiment_id, COUNT(*) as count FROM wildfire_demo.renewable_energy_catalog GROUP BY installation, source_id, experiment_id ORDER BY count DESC LIMIT 10" \
  --query-execution-context Database=wildfire_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/

# Get results (replace QUERY_ID)
aws athena get-query-results --query-execution-id QUERY_ID | jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @tsv'
```

---

## Authentication Setup

### Configure with Access Keys

```bash
aws configure
# Prompts for:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., us-east-1)
# - Default output format (json recommended)
```

### Named Profiles (Multiple Accounts)

```bash
aws configure --profile production
aws configure --profile development

# Use profile
aws s3 ls --profile production
```

### Config Files

**~/.aws/credentials:**
```ini
[default]
aws_access_key_id = AKIAIOSFODNN7EXAMPLE
aws_secret_access_key = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[production]
aws_access_key_id = AKIAI44QH8DHBEXAMPLE
aws_secret_access_key = je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```

**~/.aws/config:**
```ini
[default]
region = us-east-1
output = json

[profile production]
region = us-west-2
output = json
```

### Verify Setup

```bash
aws sts get-caller-identity
```

---

## S3 Operations

### List Operations

```bash
# List all buckets
aws s3 ls

# List bucket contents
aws s3 ls s3://bucket-name/

# List with details (size, date)
aws s3 ls s3://bucket-name/ --human-readable --summarize

# List recursively
aws s3 ls s3://bucket-name/prefix/ --recursive
```

### Copy Operations

```bash
# Upload file
aws s3 cp local-file.csv s3://bucket-name/data/

# Download file
aws s3 cp s3://bucket-name/data/file.csv ./local-file.csv

# Copy between buckets
aws s3 cp s3://source-bucket/file.csv s3://dest-bucket/file.csv

# Copy directory recursively
aws s3 cp ./local-dir s3://bucket-name/prefix/ --recursive
```

### Sync Operations

```bash
# Sync local to S3
aws s3 sync ./local-dir s3://bucket-name/prefix/

# Sync S3 to local
aws s3 sync s3://bucket-name/prefix/ ./local-dir

# Sync with delete (mirror)
aws s3 sync ./local-dir s3://bucket-name/prefix/ --delete

# Sync only certain files
aws s3 sync ./local-dir s3://bucket-name/prefix/ --exclude "*" --include "*.csv"
```

### Other S3 Operations

```bash
# Remove file
aws s3 rm s3://bucket-name/file.csv

# Remove directory
aws s3 rm s3://bucket-name/prefix/ --recursive

# Move file
aws s3 mv s3://bucket-name/old-path/file.csv s3://bucket-name/new-path/

# Generate presigned URL (temporary access)
aws s3 presign s3://bucket-name/file.csv --expires-in 3600

# Get object metadata
aws s3api head-object --bucket bucket-name --key path/to/file.csv
```

---

## Athena Queries

### Running Queries

```bash
# Start query execution
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT * FROM my_database.my_table LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=my_database \
  --result-configuration OutputLocation=s3://my-bucket/athena-results/ \
  --output text --query 'QueryExecutionId')

echo "Query ID: $QUERY_ID"
```

### Check Query Status

```bash
# Get execution status
aws athena get-query-execution --query-execution-id $QUERY_ID

# Extract just the state
aws athena get-query-execution \
  --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Status.State' \
  --output text
```

### Get Query Results

```bash
# Get results (JSON)
aws athena get-query-results --query-execution-id $QUERY_ID

# Get results as table
aws athena get-query-results \
  --query-execution-id $QUERY_ID \
  --output table
```

### Wait for Query Completion

```bash
# Poll until complete
while true; do
  STATE=$(aws athena get-query-execution \
    --query-execution-id $QUERY_ID \
    --query 'QueryExecution.Status.State' \
    --output text)
  echo "Status: $STATE"
  if [[ "$STATE" == "SUCCEEDED" || "$STATE" == "FAILED" || "$STATE" == "CANCELLED" ]]; then
    break
  fi
  sleep 2
done
```

### Query History

```bash
# List recent query executions
aws athena list-query-executions --work-group primary --max-results 10

# Get details for multiple queries
aws athena batch-get-query-execution \
  --query-execution-ids id1 id2 id3
```

---

## Glue Catalog (Metadata)

### Databases

```bash
# List all databases
aws glue get-databases

# Get specific database
aws glue get-database --name my_database

# Create database
aws glue create-database --database-input '{
  "Name": "my_database",
  "Description": "My data lake database"
}'
```

### Tables

```bash
# List tables in database
aws glue get-tables --database-name my_database

# Get table schema
aws glue get-table --database-name my_database --name my_table

# Get just column info
aws glue get-table \
  --database-name my_database \
  --name my_table \
  --query 'Table.StorageDescriptor.Columns'
```

### Partitions

```bash
# List partitions
aws glue get-partitions --database-name my_database --table-name my_table

# Add partition
aws glue create-partition \
  --database-name my_database \
  --table-name my_table \
  --partition-input '{...}'

# Repair partitions (via Athena)
aws athena start-query-execution \
  --query-string "MSCK REPAIR TABLE my_database.my_table" \
  --work-group "primary"
```

---

## Common Patterns

### Upload CSV and Create Table

```bash
# 1. Upload data
aws s3 cp data.csv s3://my-bucket/data/my_table/data.csv

# 2. Create external table (via Athena)
aws athena start-query-execution \
  --query-string "
    CREATE EXTERNAL TABLE my_database.my_table (
      id INT,
      name STRING,
      value DOUBLE
    )
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION 's3://my-bucket/data/my_table/'
    TBLPROPERTIES ('skip.header.line.count'='1')
  " \
  --work-group "primary" \
  --query-execution-context Database=my_database
```

### Query and Save Results Locally

```bash
# Run query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT * FROM my_table WHERE date = '2024-01-01'" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://my-bucket/results/ \
  --output text --query 'QueryExecutionId')

# Wait for completion
aws athena get-query-execution --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Status.State'

# Download results
aws s3 cp s3://my-bucket/results/${QUERY_ID}.csv ./results.csv
```

### Extract with jq

```bash
# Get bucket names
aws s3api list-buckets | jq -r '.Buckets[].Name'

# Get table names from Glue
aws glue get-tables --database-name my_db | jq -r '.TableList[].Name'

# Parse Athena results
aws athena get-query-results --query-execution-id $QUERY_ID | \
  jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @csv'
```

---

## Workgroups and Cost Control

### Workgroup Operations

```bash
# List workgroups
aws athena list-work-groups

# Get workgroup details
aws athena get-work-group --work-group primary

# Create workgroup with query limit
aws athena create-work-group \
  --name "limited_queries" \
  --configuration '{
    "EnforceWorkGroupConfiguration": true,
    "BytesScannedCutoffPerQuery": 10737418240
  }'
```

### Query Cost Estimation

```bash
# Get data scanned for a query
aws athena get-query-execution \
  --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Statistics.DataScannedInBytes'

# Athena pricing: ~$5 per TB scanned
```

---

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `AccessDenied` | Missing S3/Athena permissions | Check IAM policy |
| `InvalidRequestException` | Malformed query | Check SQL syntax |
| `OutputLocation not set` | No results bucket configured | Add `--result-configuration` |
| `Table not found` | Wrong database context | Specify `--query-execution-context` |
| `SerDe error` | Data format mismatch | Check table definition vs data |

---

## Best Practices

1. **Always use `--output json`** for programmatic parsing
2. **Set default region** to avoid specifying every time
3. **Use named profiles** for multiple AWS accounts
4. **Store query IDs** for result retrieval: `QUERY_ID=$(...)`
5. **Use workgroups** to control costs and organize queries
6. **Partition data** by date/category for faster, cheaper queries
7. **Use Parquet/ORC** instead of CSV for better performance

---

## Quick Reference

```bash
# S3
aws s3 ls
aws s3 cp file.csv s3://bucket/path/
aws s3 sync ./local s3://bucket/prefix/

# Athena
aws athena start-query-execution --query-string "SQL" --work-group primary
aws athena get-query-execution --query-execution-id ID
aws athena get-query-results --query-execution-id ID

# Glue Catalog
aws glue get-databases
aws glue get-tables --database-name DB
aws glue get-table --database-name DB --name TABLE

# Identity
aws sts get-caller-identity
```

---

## Resources

- [AWS CLI S3 Reference](https://docs.aws.amazon.com/cli/latest/reference/s3/)
- [AWS CLI Athena Reference](https://docs.aws.amazon.com/cli/latest/reference/athena/)
- [AWS CLI Glue Reference](https://docs.aws.amazon.com/cli/latest/reference/glue/)
- [Athena SQL Reference](https://docs.aws.amazon.com/athena/latest/ug/ddl-sql-reference.html)
