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

Many data teams store raw data in S3 and query it with Athena. The real power here isn't just running AWS commands from your terminal - it's that **Claude does the work for you**:

- **Delegation, not automation** - Describe what you want in plain English
- **Claude handles the complexity** - Searching S3 and querying Athena for you
- **You just QC the results** - Your job is quality control
- **No more context switching** - Stay in your terminal, skip the AWS Console entirely

---

## What We'll Cover

### Section 1: Setup and Configuration
- AWS CLI installation and configuration
- IAM permissions for S3 and Athena (least privilege)
- Credential management best practices
- Verifying setup: `aws sts get-caller-identity`

### Section 2: S3 Operations
- Listing and exploring buckets: `aws s3 ls`
- Uploading and downloading files: `aws s3 cp`
- Syncing directories: `aws s3 sync`
- Working with partitioned data lake structures

### Section 3: Athena Queries
- Running SQL queries from CLI: `aws athena start-query-execution`
- Managing databases and tables
- Query result handling: `aws athena get-query-results`
- Cost optimization tips (workgroups, query limits)

### Section 4: Practical Workflow Demo
Complete end-to-end workflow: **CSV -> S3 -> Athena Table -> Query -> Export**

1. Upload sample data to S3
2. Create database and external table in Athena
3. Run analysis query
4. Export results to S3/local
5. Cleanup

---

## Demo Datasets

### Primary: California Wildfire Projections
- **S3 Location:** `s3://wfclimres/` (public dataset, us-west-2)
- **Database:** `wildfire_demo`
- **Table:** `renewable_energy_catalog` (216 rows)
- Real climate research data for exploration

### Workflow Demo: Sample Sales Data
- **S3 Location:** `s3://kclabs-athena-demo-2025/sales-demo/`
- **Database:** `sales_demo`
- **Table:** `sales` (10 rows)
- Simple CSV for end-to-end demonstration

---

## CLI Capabilities

| Feature | Support |
|---------|---------|
| S3 Bucket Operations | Full (list, cp, sync, rm) |
| S3 Object Management | Full (upload, download, presign) |
| Athena Queries | Full (start-query, get-results) |
| Query History | Full (list-query-executions) |
| Cost Control | Workgroups, query limits |

> **Note:** Athena automatically stores table metadata in the AWS Glue Data Catalog. No separate Glue configuration needed for basic workflows.

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
aws s3 ls s3://kclabs-athena-demo-2025/

# Copy file to S3
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/

# Download from S3
aws s3 cp s3://kclabs-athena-demo-2025/sales-demo/sample_sales.csv ./

# Sync directory
aws s3 sync ./local-dir s3://kclabs-athena-demo-2025/data/
```

### Athena Queries
```bash
# Start a query
aws athena start-query-execution \
  --query-string "SELECT * FROM sales_demo.sales LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=sales_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/

# Get query status
aws athena get-query-execution --query-execution-id <ID>

# Get query results
aws athena get-query-results --query-execution-id <ID>
```

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
