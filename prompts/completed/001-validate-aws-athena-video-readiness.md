<objective>
Perform comprehensive pre-recording validation of the AWS S3 + Athena integration video project.

This video teaches viewers how to integrate AWS S3 and Athena with Claude Code. Before recording, we must verify:
1. All AWS resources exist and are accessible
2. Documentation is complete and accurate
3. All commands in the guides work as documented
4. The practical workflow demonstration runs end-to-end

The goal is to catch any issues BEFORE recording to avoid re-shoots.
</objective>

<context>
Project location: `./videos/integrating_aws_s3_athena/`

AWS Account: 987540640696 (kclabsai)
IAM User: kylechalmers-cli
Region: us-west-2

Expected S3 Buckets:
- `kclabs-athena-demo-2025` (demo data storage)
- `kclabs-athena-results-2025` (Athena query results)

Expected Athena Resources:
- Database: `wildfire_demo`
- Table: `renewable_energy_catalog`

Key files to validate:
- README.md (main project documentation)
- CLAUDE.md (AWS CLI reference)
- instructions/AWS_CLI_SETUP.md
- instructions/IAM_PERMISSIONS_SETUP.md
- example_workflow/README.md
- sample_data/README.md
- final_deliverables/script_outline.md

Google Drive Script (manual review):
- `/Users/kylechalmers/Library/CloudStorage/GoogleDrive-kylechalmers@kclabs.ai/Shared drives/KC AI Labs/YouTube/Full Length Video/1 Scripts/DRAFT AWS S3 Athena Integration Script Outline.docx`
- Note: This .docx file cannot be read programmatically. User should manually verify it aligns with the repo content.
</context>

<validation_phases>

<phase_1_aws_identity_and_access>
## Phase 1: AWS Identity and Access Verification

Run these commands to verify basic AWS setup:

```bash
# 1. Verify AWS identity
aws sts get-caller-identity

# 2. Verify region is us-west-2
aws configure get region
```

**Expected results:**
- Account: 987540640696
- User: kylechalmers-cli
- Region: us-west-2

If any of these fail, document the issue and stop further testing.
</phase_1_aws_identity_and_access>

<phase_2_s3_bucket_validation>
## Phase 2: S3 Bucket Validation

```bash
# 1. List all buckets - verify both demo buckets exist
aws s3 ls | grep kclabs

# 2. Verify demo bucket has data
aws s3 ls s3://kclabs-athena-demo-2025/ --human-readable --summarize

# 3. Verify results bucket exists and is accessible
aws s3 ls s3://kclabs-athena-results-2025/ --human-readable --summarize

# 4. Verify access to public wildfire dataset
aws s3 ls s3://wfclimres/ --region us-west-2 | head -5
```

**Expected results:**
- Both `kclabs-athena-demo-2025` and `kclabs-athena-results-2025` buckets exist
- Demo bucket contains wildfire data (e.g., `wildfire-data/` folder)
- Public dataset `s3://wfclimres/` is accessible
</phase_2_s3_bucket_validation>

<phase_3_athena_validation>
## Phase 3: Athena Database and Table Validation

```bash
# 1. List databases - verify wildfire_demo exists
aws glue get-databases | jq -r '.DatabaseList[].Name' | grep wildfire

# 2. List tables in wildfire_demo
aws glue get-tables --database-name wildfire_demo | jq -r '.TableList[].Name'

# 3. Get table schema for renewable_energy_catalog
aws glue get-table --database-name wildfire_demo --name renewable_energy_catalog | jq '.Table.StorageDescriptor.Columns'

# 4. Run test query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT COUNT(*) as row_count FROM wildfire_demo.renewable_energy_catalog" \
  --query-execution-context Database=wildfire_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/ \
  --output text --query 'QueryExecutionId')
echo "Query ID: $QUERY_ID"

# 5. Wait and get results
sleep 5
aws athena get-query-results --query-execution-id $QUERY_ID | jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @tsv'
```

**Expected results:**
- Database `wildfire_demo` exists
- Table `renewable_energy_catalog` exists with expected columns
- Query returns row count (should be ~200 rows based on documentation)
</phase_3_athena_validation>

<phase_4_documentation_link_validation>
## Phase 4: Documentation Link Validation

Check all external URLs in the documentation files are valid:

Files to check:
- `./videos/integrating_aws_s3_athena/README.md`
- `./videos/integrating_aws_s3_athena/instructions/AWS_CLI_SETUP.md`
- `./videos/integrating_aws_s3_athena/instructions/IAM_PERMISSIONS_SETUP.md`
- `./videos/integrating_aws_s3_athena/sample_data/README.md`

Extract all URLs and validate them using WebFetch or curl. Key URLs to verify:
- AWS documentation links
- AWS Marketplace listing for wildfire dataset
- Cal-Adapt resources
- Homebrew formula page
</phase_4_documentation_link_validation>

<phase_5_workflow_demonstration>
## Phase 5: Full Workflow Demonstration Test

Run the complete workflow from `example_workflow/README.md`:

### Step 5.1: Create Sample Data
```bash
cd ./videos/integrating_aws_s3_athena/example_workflow

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

### Step 5.2: Upload to S3
```bash
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/workflow-test/sample_sales.csv
aws s3 ls s3://kclabs-athena-demo-2025/workflow-test/
```

### Step 5.3: Create Database and Table
```bash
# Create database
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS workflow_test" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/

sleep 3

# Create table
aws athena start-query-execution \
  --query-string "
    CREATE EXTERNAL TABLE IF NOT EXISTS workflow_test.sales (
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
    LOCATION 's3://kclabs-athena-demo-2025/workflow-test/'
    TBLPROPERTIES ('skip.header.line.count'='1')
  " \
  --work-group "primary" \
  --query-execution-context Database=workflow_test \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```

### Step 5.4: Run Analysis Query
```bash
sleep 5

QUERY_ID=$(aws athena start-query-execution \
  --query-string "
    SELECT
      region,
      COUNT(*) as order_count,
      SUM(quantity) as total_units,
      ROUND(SUM(quantity * unit_price), 2) as total_revenue
    FROM workflow_test.sales
    GROUP BY region
    ORDER BY total_revenue DESC
  " \
  --work-group "primary" \
  --query-execution-context Database=workflow_test \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/ \
  --output text --query 'QueryExecutionId')

echo "Query ID: $QUERY_ID"
sleep 5
aws athena get-query-results --query-execution-id $QUERY_ID | jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @tsv'
```

### Step 5.5: Export Results
```bash
aws s3 cp s3://kclabs-athena-results-2025/${QUERY_ID}.csv ./query_results.csv
cat ./query_results.csv
```

### Step 5.6: Cleanup Test Resources
```bash
# Remove test data
aws s3 rm s3://kclabs-athena-demo-2025/workflow-test/ --recursive

# Drop test table and database
aws athena start-query-execution \
  --query-string "DROP TABLE IF EXISTS workflow_test.sales" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/

sleep 3

aws athena start-query-execution \
  --query-string "DROP DATABASE IF EXISTS workflow_test" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/

# Clean local files
rm -f sample_sales.csv query_results.csv
```
</phase_5_workflow_demonstration>

</validation_phases>

<output>
Create a validation report at:
`./videos/integrating_aws_s3_athena/VALIDATION_REPORT.md`

The report should include:

```markdown
# AWS S3 + Athena Video - Pre-Recording Validation Report

**Validation Date:** [date]
**Overall Status:** [PASS/FAIL/PARTIAL]

## Summary

| Phase | Status | Notes |
|-------|--------|-------|
| 1. AWS Identity | ✓/✗ | [brief note] |
| 2. S3 Buckets | ✓/✗ | [brief note] |
| 3. Athena Resources | ✓/✗ | [brief note] |
| 4. Documentation Links | ✓/✗ | [X of Y links valid] |
| 5. Workflow Demo | ✓/✗ | [brief note] |

## Phase Details

### Phase 1: AWS Identity
[detailed results]

### Phase 2: S3 Buckets
[detailed results]

### Phase 3: Athena Resources
[detailed results]

### Phase 4: Documentation Links
[list of checked URLs with status]

### Phase 5: Workflow Demo
[step-by-step results]

## Issues Found
[list any problems discovered]

## Recommendations
[any suggested fixes or improvements before recording]

## Ready to Record?
[YES/NO with reasoning]
```
</output>

<verification>
Before marking complete, verify:
1. All 5 phases executed without critical errors
2. Validation report created and saved
3. Any test resources created during Phase 5 have been cleaned up
4. Report clearly states whether the video is ready to record
</verification>

<success_criteria>
- AWS identity verified (correct account, user, region)
- Both S3 buckets exist and are accessible
- Athena database and table exist and are queryable
- At least 80% of documentation links are valid
- Full workflow (CSV → S3 → Athena → Export) completes successfully
- Cleanup of test resources completed
- Validation report created with clear PASS/FAIL status
</success_criteria>
