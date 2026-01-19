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

## Demo Dataset

### IMF Global Surface Temperature Data
- **S3 Location:** `s3://kclabs-athena-demo-2026/climate-data/`
- **Database:** `climate_demo`
- **Table:** `global_temperature` (200+ countries/regions)
- Real climate data: annual mean surface temperature change (degrees Celsius) relative to 1951-1980 baseline, by country, from 1961-2024

| Column | What it means |
|--------|---------------|
| `Country` | Country or region name |
| `ISO2`, `ISO3` | Country codes (e.g., US, USA) |
| `Indicator` | Description of the measurement |
| `Unit` | Degree Celsius |
| `Source` | FAO/IMF attribution |
| `Y1961` - `Y2024` | Temperature change for each year |

**Sample Data File:** `sample_data/global_surface_temperature.csv` - IMF climate indicators extracted from FAO data.

**Data Source:**
- International Monetary Fund (IMF) Climate Change Indicators
- Original data: Food and Agriculture Organization of the United Nations (FAO)
- License: CC BY-NC-SA 3.0 IGO

### Full Demo Prompt

Use this prompt to demonstrate Claude's end-to-end AWS capabilities:

```
Upload the sample data file at sample_data/global_surface_temperature.csv to S3.

Create this bucket if it doesn't exist:
- kclabs-athena-demo-2026
and then place the csv inside a folder called climate-data inside of it.

Then:
1. Create the necessary Athena infrastructure to query this data
2. Write a query to pivot the dataset so years become rows ordered by highest temperature change descending
3. Save the pivoted results as a CSV in final_deliverables/pivoted_temperature_data.csv

Finally, query Athena to find the 5 years with the largest mean temperature change for the United States and tell me the results.
```

This prompt demonstrates:
- **S3 Operations**: Bucket creation, file upload, path organization
- **Athena Infrastructure**: Database/table creation with proper schema
- **SQL Analysis**: Complex pivot query with ordering
- **Data Export**: Saving query results locally
- **Business Intelligence**: Extracting specific insights from the data

---

## S3 Operations

### Listing Buckets and Objects

```bash
# List all buckets
aws s3 ls

# List bucket contents
aws s3 ls s3://kclabs-athena-demo-2026/

# List with details
aws s3 ls s3://kclabs-athena-demo-2026/ --human-readable --summarize
```

The `--human-readable` flag shows file sizes in MB and GB instead of bytes. The `--summarize` flag gives you totals.

### Uploading Files

```bash
# Upload a single file
aws s3 cp global_surface_temperature.csv s3://kclabs-athena-demo-2026/climate-data/

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
aws s3 cp s3://kclabs-athena-demo-2026/climate-data/global_surface_temperature.csv ./
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
  --query-string "SELECT Country, ISO3, Y2024 FROM climate_demo.global_temperature WHERE Y2024 IS NOT NULL ORDER BY Y2024 DESC LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=climate_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2026/
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
aws s3 cp global_surface_temperature.csv s3://kclabs-athena-demo-2026/climate-data/
aws s3 ls s3://kclabs-athena-demo-2026/climate-data/
```

### Step 2: Create Database and Table

```sql
-- Create database
CREATE DATABASE IF NOT EXISTS climate_demo;

-- Create external table for wide-format temperature data
CREATE EXTERNAL TABLE climate_demo.global_temperature (
    ObjectId INT,
    Country STRING,
    ISO2 STRING,
    ISO3 STRING,
    Indicator STRING,
    Unit STRING,
    Source STRING,
    CTS_Code STRING,
    CTS_Name STRING,
    CTS_Full_Descriptor STRING,
    Y1961 DOUBLE, Y1962 DOUBLE, Y1963 DOUBLE, Y1964 DOUBLE, Y1965 DOUBLE,
    Y1966 DOUBLE, Y1967 DOUBLE, Y1968 DOUBLE, Y1969 DOUBLE, Y1970 DOUBLE,
    Y1971 DOUBLE, Y1972 DOUBLE, Y1973 DOUBLE, Y1974 DOUBLE, Y1975 DOUBLE,
    Y1976 DOUBLE, Y1977 DOUBLE, Y1978 DOUBLE, Y1979 DOUBLE, Y1980 DOUBLE,
    Y1981 DOUBLE, Y1982 DOUBLE, Y1983 DOUBLE, Y1984 DOUBLE, Y1985 DOUBLE,
    Y1986 DOUBLE, Y1987 DOUBLE, Y1988 DOUBLE, Y1989 DOUBLE, Y1990 DOUBLE,
    Y1991 DOUBLE, Y1992 DOUBLE, Y1993 DOUBLE, Y1994 DOUBLE, Y1995 DOUBLE,
    Y1996 DOUBLE, Y1997 DOUBLE, Y1998 DOUBLE, Y1999 DOUBLE, Y2000 DOUBLE,
    Y2001 DOUBLE, Y2002 DOUBLE, Y2003 DOUBLE, Y2004 DOUBLE, Y2005 DOUBLE,
    Y2006 DOUBLE, Y2007 DOUBLE, Y2008 DOUBLE, Y2009 DOUBLE, Y2010 DOUBLE,
    Y2011 DOUBLE, Y2012 DOUBLE, Y2013 DOUBLE, Y2014 DOUBLE, Y2015 DOUBLE,
    Y2016 DOUBLE, Y2017 DOUBLE, Y2018 DOUBLE, Y2019 DOUBLE, Y2020 DOUBLE,
    Y2021 DOUBLE, Y2022 DOUBLE, Y2023 DOUBLE, Y2024 DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2026/climate-data/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

The table is just a pointer - Athena reads directly from S3. No data copying, no ETL pipeline.

### Step 3: Run Analysis Queries

```sql
-- Top 10 countries with highest 2024 temperature change
SELECT Country, ISO3, Y2024 as temp_change_2024
FROM climate_demo.global_temperature
WHERE Y2024 IS NOT NULL AND ISO3 IS NOT NULL
ORDER BY Y2024 DESC
LIMIT 10;

-- Temperature trend for USA over decades
SELECT Country, Y1970, Y1980, Y1990, Y2000, Y2010, Y2020, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 = 'USA';

-- Compare recent years across major economies
SELECT Country, ISO3, Y2020, Y2021, Y2022, Y2023, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 IN ('USA', 'CHN', 'DEU', 'JPN', 'GBR', 'FRA')
ORDER BY Y2024 DESC;
```

### Step 4: Export Results

Every Athena query automatically saves results to your designated S3 bucket.

```bash
aws s3 cp s3://kclabs-athena-results-2026/{query-id}.csv ./results.csv
cat ./results.csv
```

### Step 5: Cleanup

```sql
DROP TABLE IF EXISTS climate_demo.global_temperature;
DROP DATABASE IF EXISTS climate_demo;
```

```bash
aws s3 rm s3://kclabs-athena-demo-2026/climate-data/ --recursive
```

Tables are just pointers, but the S3 data persists until you delete it.

---

## Claude Code Integration Examples

**S3 Exploration:**
- "List all buckets and show me what's in the demo bucket"
- "Upload the temperature CSV to S3 and tell me the object URL"
- "Find all CSV files in the climate-data folder"

**Athena Queries:**
- "Query the temperature table for the top 10 countries with highest warming in 2024"
- "Show me the schema for the global_temperature table"
- "Compare temperature trends for USA, China, and Germany from 1990 to 2024"

**Workflow Automation:**
- "Create an Athena table for the CSV I just uploaded"
- "Generate a report of temperature change by continent"
- "Clean up the test database and data"

### The Real Workflow

Instead of typing CLI commands, tell Claude: "Find the countries with the most temperature change in 2024 and compare their warming trends over the past 50 years."

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
│   └── global_surface_temperature.csv   # IMF temperature data (200+ countries)
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
