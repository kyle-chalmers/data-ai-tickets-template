# AWS S3 + Athena Integration with Claude Code

> **YouTube:** [Coming Soon]

Complete guide for integrating AWS S3 and Athena with Claude Code using the AWS CLI.

---

## The Value Proposition

Many data teams store raw data in S3 and query it with Athena. The real power here isn't just running AWS commands from your terminal - it's that **Claude does the work for you**:

- **Delegation to Claude** - Describe what you want in plain English
- **Claude handles the complexity** - Searching S3 and querying Athena for you
- **You just QC the results** - Your job is quality control
- **No more context switching** - Stay in your terminal, skip the AWS Console entirely

### Video Goals

Enable Claude to:
1. **Access S3 data** - List buckets, explore objects, upload/download files
2. **Query with Athena** - Run SQL queries on S3 data lakes, manage databases and tables
3. **Build analysis workflows** - End-to-end data exploration and reporting

---

## Key Terms / Glossary

| Term | Definition |
|------|------------|
| **S3 (Simple Storage Service)** | Amazon's cloud storage, or data lake - think of it as an infinitely expandable hard drive in the sky where you store files |
| **Data Lake** | A storage approach where you dump raw data first, then figure out how to use it later (opposite of traditional databases) |
| **Athena** | A query service that lets you run SQL directly on files in S3 - no database server needed |
| **External Table** | A table definition that points to files somewhere else - the data stays in S3, Athena just knows how to read it |
| **IAM (Identity and Access Management)** | AWS's permission system - controls who can do what with your cloud resources |

---

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI v2 installed and configured
- S3 bucket(s) with data to query
- Athena workgroup configured

---

## Quick Start / Setup

```bash
# Install AWS CLI (macOS)
brew install awscli

# Or download installer directly
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Configure credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Verify setup
aws sts get-caller-identity
aws s3 ls
```

### IAM Permissions

You'll need the right IAM permissions. At minimum:
- S3 read access to your data buckets
- Athena query execution access
- S3 write access to your results bucket

**Pro Tip - Named Profiles:** If you work with multiple AWS accounts:
```bash
aws configure --profile production
aws configure --profile development

# Then use: aws s3 ls --profile production
```

**Official AWS Documentation:**
- [Getting Started with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)
- [Installing the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [AWS CLI S3 Command Reference](https://docs.aws.amazon.com/cli/latest/reference/s3/)
- [AWS CLI Athena Command Reference](https://docs.aws.amazon.com/cli/latest/reference/athena/)

Full setup guide: [instructions/AWS_CLI_SETUP.md](./instructions/AWS_CLI_SETUP.md)

---

## Demo Datasets

### Primary: California Wildfire Projections
- **S3 Location:** `s3://wfclimres/` (public dataset, us-west-2)
- **Database:** `wildfire_demo`
- **Table:** `renewable_energy_catalog` (216 rows)
- Real climate research data containing climate model projections for California renewable energy generation - solar PV, wind power, capacity factors across multiple climate scenarios

| Column | What it means |
|--------|---------------|
| `installation` | Energy type (pv_distributed, pv_utility, wind) |
| `source_id` | Climate model used |
| `experiment_id` | Scenario (historical, reanalysis, ssp370) |
| `path` | S3 location of actual data files |

### Workflow Demo: Sample Sales Data
- **S3 Location:** `s3://kclabs-athena-demo-2025/sales-demo/`
- **Database:** `sales_demo`
- **Table:** `sales` (10 rows)
- Simple CSV for end-to-end demonstration

---

## S3 Operations

### Listing Buckets and Objects

```bash
# List all buckets
aws s3 ls

# List bucket contents
aws s3 ls s3://kclabs-athena-demo-2025/

# List with details
aws s3 ls s3://kclabs-athena-demo-2025/ --human-readable --summarize
```

The `--human-readable` flag shows file sizes in MB and GB instead of bytes. The `--summarize` flag gives you totals.

### Uploading Files

```bash
# Upload a single file
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/

# Upload a directory
aws s3 cp ./local-dir s3://bucket-name/prefix/ --recursive
```

The `cp` command is your workhorse for moving files between local and S3, or between buckets.

### Syncing Directories

```bash
# Sync local to S3
aws s3 sync ./local-dir s3://bucket-name/prefix/

# Sync with delete (mirror exactly)
aws s3 sync ./local-dir s3://bucket-name/prefix/ --delete

# Download from S3
aws s3 cp s3://kclabs-athena-demo-2025/sales-demo/sample_sales.csv ./
```

Sync is smart - it only uploads files that have changed. The `--delete` flag makes S3 match your local exactly.

### Presigned URLs

```bash
aws s3 presign s3://bucket-name/file.csv --expires-in 3600
```

Need to share a file temporarily without giving someone AWS access? Presigned URLs expire after the time you specify.

---

## Athena Queries

Athena queries work asynchronously - you start a query, it runs in the background, then you fetch the results.

### Starting a Query

```bash
# Start query execution
aws athena start-query-execution \
  --query-string "SELECT * FROM wildfire_demo.renewable_energy_catalog LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=wildfire_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```

This returns a Query Execution ID - think of it like a ticket number you use to check status and get results.

### Checking Status and Getting Results

```bash
# Check query status
aws athena get-query-execution --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Status.State' --output text

# Get results when complete
aws athena get-query-results --query-execution-id $QUERY_ID
```

The status will be RUNNING, SUCCEEDED, FAILED, or CANCELLED. Once it's SUCCEEDED, you can fetch the results.

### Parsing Results with jq

```bash
# Clean up the JSON output
aws athena get-query-results --query-execution-id $QUERY_ID | \
  jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @csv'
```

The raw output is verbose JSON. Use jq to extract just the data you need.

### Cost Awareness

Athena charges about $5 per terabyte scanned. Use workgroups to set query limits and avoid surprise bills.

---

## Practical Workflow Demo

Complete end-to-end workflow: **CSV -> S3 -> Athena Table -> Query -> Export**

### Step 1: Upload Data to S3

```bash
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/
aws s3 ls s3://kclabs-athena-demo-2025/sales-demo/
```

### Step 2: Create Database and Table

```sql
-- Create database
CREATE DATABASE IF NOT EXISTS sales_demo;

-- Create external table
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

The table is just a pointer - Athena reads directly from S3. No data copying, no ETL pipeline.

### Step 3: Run Analysis Query

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

### Step 4: Export Results

Every Athena query automatically saves results to your designated S3 bucket.

```bash
aws s3 cp s3://kclabs-athena-results-2025/{query-id}.csv ./results.csv
cat ./results.csv
```

### Step 5: Cleanup

```sql
DROP TABLE IF EXISTS sales_demo.sales;
DROP DATABASE IF EXISTS sales_demo;
```

```bash
aws s3 rm s3://kclabs-athena-demo-2025/sales-demo/ --recursive
```

Tables are just pointers, but the S3 data persists until you delete it.

---

## Claude Code Integration Examples

**S3 Exploration:**
- "List all buckets and show me what's in the demo bucket"
- "Upload this CSV to S3 and tell me the object URL"
- "Find all parquet files modified in the last week"

**Athena Queries:**
- "Query the sales table for totals by region"
- "Show me the schema for the renewable_energy_catalog table"
- "Run this query and save results to a local CSV"

**Workflow Automation:**
- "Create an Athena table for the CSV I just uploaded"
- "Generate a report of revenue by region"
- "Clean up the test database and data"

### The Real Workflow

Instead of typing CLI commands, tell Claude: "Find all the wind power projections in the wildfire dataset and summarize by climate model."

Claude figures out the S3 paths, writes the Athena query, handles the async execution, and presents you with results to review.

**Your job becomes quality control, not query writing.**

That's the difference between automation and delegation. Automation replaces you. Delegation frees you to focus on higher-value work.

---

## Security Best Practices

**Credential Management:**
- Use IAM roles when possible (EC2, Lambda)
- Use named profiles for multiple accounts
- Never commit credentials to version control
- Rotate access keys regularly

**Least Privilege:**
- Scope S3 permissions to specific buckets
- Limit Athena to specific workgroups
- Use resource-based policies

**Configuration Security:**
```bash
chmod 600 ~/.aws/credentials
ls -l ~/.aws/credentials  # Should show: -rw-------
```

---

## CLI Capabilities Reference

| Feature | Support |
|---------|---------|
| S3 Bucket Operations | Full (list, cp, sync, rm) |
| S3 Object Management | Full (upload, download, presign) |
| Athena Queries | Full (start-query, get-results) |
| Query History | Full (list-query-executions) |
| Cost Control | Workgroups, query limits |

> **Note:** Athena automatically stores table metadata in the AWS Glue Data Catalog. No separate Glue configuration needed for basic workflows.

---

## Files in This Project

```
videos/integrating_aws_s3_athena/
├── README.md                    # This file
├── CLAUDE.md                    # AWS CLI reference for Claude
├── final_deliverables/
│   └── script_outline.md        # Video script (source of truth)
├── instructions/
│   └── AWS_CLI_SETUP.md         # Detailed setup guide
├── sample_data/
│   └── README.md                # Dataset options and setup
└── example_workflow/
    └── README.md                # Step-by-step workflow example
```

---

## Resources

**AWS CLI Installation:**
- [AWS CLI Official Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Homebrew Formula - awscli](https://formulae.brew.sh/formula/awscli)

**Official Documentation:**
- AWS CLI: https://docs.aws.amazon.com/cli/
- S3 Commands: https://docs.aws.amazon.com/cli/latest/reference/s3/
- Athena CLI: https://docs.aws.amazon.com/cli/latest/reference/athena/

**Getting Help:**
- `aws help`
- `aws s3 help`
- `aws athena help`
