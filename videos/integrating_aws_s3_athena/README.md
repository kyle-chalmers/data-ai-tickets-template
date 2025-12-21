# AWS S3 + Athena Integration with Claude Code

> **YouTube:** [Coming Soon]

Complete guide for integrating AWS S3 and Athena with Claude Code using the AWS CLI.

---

## Video Goals

Enable Claude to:
1. **Access S3 data** - List buckets, explore objects, upload/download files
2. **Query with Athena** - Run SQL queries on S3 data lakes, manage databases and tables
3. **Build analysis workflows** - End-to-end data exploration and reporting

---

## The Value Proposition

Many data teams store raw data in S3 and query it with Athena. This video shows how Claude Code can:
- **Explore data lakes** without leaving the terminal
- **Run ad-hoc Athena queries** conversationally
- **Automate data workflows** (upload → catalog → query → export)
- **Reduce context switching** between AWS Console and analysis tools

---

## What We'll Cover

### Section 1: Setup and Configuration
- AWS CLI installation and configuration
- IAM permissions for S3 and Athena
- Credential management best practices
- Claude Code settings.json for AWS

### Section 2: S3 Operations
- Listing and exploring buckets
- Uploading and downloading files
- Working with partitioned data
- Common patterns for data lakes

### Section 3: Athena Queries
- Running SQL queries from CLI
- Managing databases and tables
- Query result handling
- Cost optimization tips

### Section 4: Practical Workflow
- End-to-end example: CSV → S3 → Athena → Analysis
- Building reusable query patterns
- Integration with existing data workflows

---

## CLI Capabilities

| Feature | Support |
|---------|---------|
| S3 Bucket Operations | Full (list, cp, sync, rm) |
| S3 Object Management | Full (upload, download, presign) |
| Athena Queries | Full (start-query, get-results) |
| Glue Catalog | Full (databases, tables, partitions) |
| Query History | Full (list-query-executions) |
| Cost Control | Workgroups, query limits |

---

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI v2 installed and configured
- S3 bucket(s) with data to query
- Athena workgroup configured

---

## Quick Start

```bash
# Install AWS CLI (macOS)
brew install awscli

# Configure credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region, Output format

# Verify setup
aws sts get-caller-identity
aws s3 ls
```

Full setup guide: [instructions/AWS_CLI_SETUP.md](./instructions/AWS_CLI_SETUP.md)

---

## Common Commands

### S3 Operations
```bash
# List buckets
aws s3 ls

# List objects in bucket
aws s3 ls s3://bucket-name/prefix/

# Copy file to S3
aws s3 cp local-file.csv s3://bucket-name/data/

# Download from S3
aws s3 cp s3://bucket-name/data/file.csv ./local-file.csv

# Sync directory
aws s3 sync ./local-dir s3://bucket-name/prefix/
```

### Athena Queries
```bash
# Start a query
aws athena start-query-execution \
  --query-string "SELECT * FROM database.table LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=my_database

# Get query status
aws athena get-query-execution --query-execution-id <ID>

# Get query results
aws athena get-query-results --query-execution-id <ID>
```

### Glue Catalog
```bash
# List databases
aws glue get-databases

# List tables in database
aws glue get-tables --database-name my_database

# Get table schema
aws glue get-table --database-name my_database --name my_table
```

---

## Claude Code Integration Examples

**S3 Exploration:**
- "List all buckets and show me what's in the data-lake bucket"
- "Upload this CSV to S3 and tell me the object URL"
- "Find all parquet files modified in the last week"

**Athena Queries:**
- "Query the sales table for Q4 2024 totals by region"
- "Show me the schema for the customer_events table"
- "Run this query and save results to a local CSV"

**Workflow Automation:**
- "Create an Athena table for the new CSV I uploaded"
- "Partition the events table by date and region"
- "Generate a report of query costs this month"

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

## Files in This Project

```
videos/integrating_aws_s3_athena/
├── README.md                    # This file
├── CLAUDE.md                    # AWS CLI reference for Claude
├── instructions/
│   └── AWS_CLI_SETUP.md         # Detailed setup guide
└── example_workflow/
    └── README.md                # Step-by-step example
```

---

## Resources

**Official Documentation:**
- AWS CLI: https://docs.aws.amazon.com/cli/
- S3 Commands: https://docs.aws.amazon.com/cli/latest/reference/s3/
- Athena CLI: https://docs.aws.amazon.com/cli/latest/reference/athena/
- Glue CLI: https://docs.aws.amazon.com/cli/latest/reference/glue/

**Getting Help:**
- `aws help`
- `aws s3 help`
- `aws athena help`
