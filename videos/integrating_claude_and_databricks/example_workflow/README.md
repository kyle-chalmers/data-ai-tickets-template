# Databricks CLI Example Workflows

Four practical workflows demonstrating Databricks CLI integration with Claude Code, plus an advanced troubleshooting workflow.

## Repository Structure

```
example_workflow/
├── README.md                           # This file - workflow documentation
├── customer_analysis/                  # Original customer analysis example
│   ├── customer_analysis.py           # PySpark notebook
│   └── job_config.json                # Job configuration
└── product_sales/                      # Product sales analysis with troubleshooting
    ├── README.md                      # Step-by-step troubleshooting guide
    ├── product_sales_analysis.py      # Working PySpark notebook
    ├── product_sales_job_config.json  # Working job configuration
    ├── test_product_sales_config.json # One-time test run config
    ├── failing_job_config.json        # Intentionally failing configuration
    ├── fixed_job_config.json          # Corrected configuration
    └── update_job_config.json         # Job update payload
```

## Workflows

1. [Workflow 1: Explore Unity Catalog](#workflow-1-explore-unity-catalog) - List catalogs, schemas, and tables
2. [Workflow 2: Create Databricks Notebook](#workflow-2-create-databricks-notebook) - Upload Python notebook to workspace
3. [Workflow 3: Turn Notebook into Job](#workflow-3-turn-notebook-into-job) - Create scheduled job from notebook
4. [Workflow 4: Run Job and Monitor Success](#workflow-4-run-job-and-monitor-success) - Execute and monitor job
5. [Workflow 5: Troubleshooting Failed Jobs](#workflow-5-troubleshooting-failed-jobs) - Debug and fix job failures

---

## Workflow 1: Explore Unity Catalog

Explore the Unity Catalog structure including catalogs, schemas, and tables.

### Commands

```bash
# List all catalogs
databricks catalogs list

# List schemas in samples catalog
databricks schemas list samples

# List tables in a specific schema
databricks tables list samples tpch

# Get details about a specific table
databricks tables get samples.tpch.orders --output json | jq '{
  name: .name,
  catalog_name: .catalog_name,
  schema_name: .schema_name,
  table_type: .table_type,
  data_source_format: .data_source_format
}'
```

### Verification

```bash
# Verify catalogs exist
databricks catalogs list | grep -q "samples" && echo "✓ Found samples catalog"

# Verify schemas exist
databricks schemas list samples | grep -q "tpch" && echo "✓ Found tpch schema"

# Verify tables exist
databricks tables list samples tpch | grep -q "orders" && echo "✓ Found orders table"
```

---

## Workflow 2: Create Databricks Notebook

Create and upload a Python notebook to Databricks workspace.

### Create Notebook File

```python
# File: customer_analysis/customer_analysis.py

# Databricks notebook source
# MAGIC %md
# MAGIC # Customer Analysis
# MAGIC
# MAGIC Analyze customer purchase patterns

# COMMAND ----------

# Import libraries
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, count, avg

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load Data

# COMMAND ----------

# Read customer orders
df_orders = spark.table("samples.tpch.orders")
df_customer = spark.table("samples.tpch.customer")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Analysis

# COMMAND ----------

# Join and aggregate
# NOTE: Use explicit join condition when column names differ between tables
customer_stats = (
    df_orders
    .join(df_customer, df_orders.o_custkey == df_customer.c_custkey)
    .groupBy("c_custkey", "c_name", "c_mktsegment")
    .agg(
        count("o_orderkey").alias("total_orders"),
        sum("o_totalprice").alias("total_spent"),
        avg("o_totalprice").alias("avg_order_value")
    )
    .orderBy(col("total_spent").desc())
)

# Display results
display(customer_stats.limit(20))
```

### Upload to Databricks

```bash
# Get current user
CURRENT_USER=$(databricks current-user me --output json | jq -r '.userName')

# Upload notebook to workspace
databricks workspace import \
  /Users/$CURRENT_USER/customer_analysis \
  --file customer_analysis.py \
  --language PYTHON \
  --format SOURCE \
  --overwrite
```

### Verification

```bash
# List workspace to confirm upload
databricks workspace list /Users/$CURRENT_USER/ | grep customer_analysis && echo "✓ Notebook uploaded"

# Export to verify content
databricks workspace export /Users/$CURRENT_USER/customer_analysis --format SOURCE | head -10
```

### Run Notebook

Once uploaded, you can run the notebook using one-time execution:

```bash
# Create one-time run configuration
cat > run_notebook.json << EOF
{
  "run_name": "Customer Analysis Test",
  "tasks": [{
    "task_key": "run_notebook",
    "notebook_task": {
      "notebook_path": "/Users/$CURRENT_USER/customer_analysis",
      "source": "WORKSPACE"
    },
    "timeout_seconds": 600
  }]
}
EOF

# Submit and run
databricks jobs submit --json @run_notebook.json --output json
```

**To view results:**
- Open the `run_page_url` from the output in your browser
- Or create a scheduled job (see Workflow 3)

---

## Workflow 3: Turn Notebook into Job

Create a Databricks job that runs the notebook on a schedule.

**Best Practice:** Test notebooks with one-time runs before creating jobs. See [Databricks CLI Reference](../CLAUDE.md#test-notebooks-one-time-runs) for details.

### Create Job Configuration

**Note:** Trial workspaces only support serverless compute, so we don't need to specify cluster configuration.

```json
{
  "name": "Customer Analysis Job",
  "tasks": [
    {
      "task_key": "customer_analysis_task",
      "notebook_task": {
        "notebook_path": "/Users/YOUR_EMAIL/customer_analysis",
        "source": "WORKSPACE"
      },
      "timeout_seconds": 3600
    }
  ],
  "schedule": {
    "quartz_cron_expression": "0 0 8 * * ?",
    "timezone_id": "America/Los_Angeles"
  },
  "max_concurrent_runs": 1,
  "email_notifications": {
    "on_failure": ["your.email@company.com"]
  }
}
```

Update `customer_analysis/job_config.json` with your email/notebook path, then create:

```bash
# Edit customer_analysis/job_config.json to replace YOUR_EMAIL with your actual email
# Then create the job
JOB_ID=$(databricks jobs create --json @customer_analysis/job_config.json --output json | jq -r '.job_id')

echo "Created job with ID: $JOB_ID"
```

### Verification

```bash
# View job details
databricks jobs get $JOB_ID

# List all jobs to find it
databricks jobs list --output json | jq '.jobs[] | select(.settings.name == "Customer Analysis Job")'
```

---

## Workflow 4: Run Job and Monitor Success

Execute the job and monitor its progress to completion.

### Run Job

```bash
# Run job now (using job ID from Workflow 3)
RUN_ID=$(databricks jobs run-now $JOB_ID --output json | jq -r '.run_id')

echo "Started job run: $RUN_ID"
```

### Monitor Progress

```bash
# Check run status
databricks runs get $RUN_ID --output json | jq '{
  run_id: .run_id,
  state: .state.life_cycle_state,
  result: .state.result_state,
  start_time: .start_time
}'

# Monitor in real-time (poll every 10 seconds)
while true; do
  STATE=$(databricks runs get $RUN_ID --output json | jq -r '.state.life_cycle_state')
  RESULT=$(databricks runs get $RUN_ID --output json | jq -r '.state.result_state // "RUNNING"')

  echo "Status: $STATE | Result: $RESULT"

  if [[ "$STATE" == "TERMINATED" ]]; then
    echo "Job completed with result: $RESULT"
    break
  fi

  sleep 10
done
```

### View Results and Logs

```bash
# Get run output (after completion)
databricks runs get-output $RUN_ID

# View run page URL
echo "View run at: $(databricks runs get $RUN_ID --output json | jq -r '.run_page_url')"

# List recent runs for this job
databricks jobs list-runs $JOB_ID --limit 5 --output json | jq '.runs[] | {
  run_id: .run_id,
  start_time: .start_time,
  state: .state.life_cycle_state,
  result: .state.result_state
}'
```

### Verification Checklist

- [ ] Job run started successfully (RUN_ID obtained)
- [ ] Job progressed through states: PENDING → RUNNING → TERMINATED
- [ ] Final result state is SUCCESS
- [ ] Run page URL accessible in Databricks UI
- [ ] Job output available via get-output command

---

## Workflow 5: Troubleshooting Failed Jobs

Learn how to debug and fix Databricks job failures through a practical example.

**See detailed step-by-step guide:** [`product_sales/README.md`](./product_sales/README.md)

### Overview

This workflow demonstrates:
1. Creating a job with an intentional configuration error
2. Running the job and capturing the failure
3. Investigating error details using CLI commands
4. Diagnosing the root cause
5. Fixing the configuration
6. Verifying successful execution

### Quick Example

```bash
# Navigate to product_sales folder
cd product_sales/

# 1. Create job with intentional error (references non-existent notebook)
JOB_ID=$(databricks jobs create --json @failing_job_config.json --output json | jq -r '.job_id')
echo "Created job: $JOB_ID"

# 2. Run job and observe failure
databricks jobs run-now $JOB_ID --output json
# Error: RESOURCE_NOT_FOUND - notebook doesn't exist

# 3. Investigate error
databricks jobs list-runs --job-id $JOB_ID --limit 1 --output json | \
  jq '.[] | {state, error: .status.termination_details}'

# 4. List available notebooks to find correct path
databricks workspace list /Users/$(databricks current-user me --output json | jq -r '.userName')/ | \
  grep product_sales

# 5. Fix configuration (update notebook path)
databricks jobs update --json @update_job_config.json

# 6. Verify fix
databricks jobs get $JOB_ID --output json | \
  jq '{job_id, name: .settings.name, notebook_path: .settings.tasks[0].notebook_task.notebook_path}'

# 7. Run successfully
databricks jobs run-now $JOB_ID --output json
# Result: SUCCESS ✅
```

### Key Troubleshooting Commands

| Command | Purpose |
|---------|---------|
| `databricks jobs list-runs --job-id <ID>` | Get run history and error details |
| `databricks jobs get-run <RUN_ID>` | Get detailed run information |
| `databricks workspace list <PATH>` | Verify resource existence |
| `databricks jobs get <JOB_ID>` | Inspect current job configuration |
| `databricks jobs update --json @config.json` | Fix job configuration |

### Error Types Covered

- **RESOURCE_NOT_FOUND** - Invalid notebook/file paths
- **CLIENT_ERROR** - Configuration issues
- **INTERNAL_ERROR** - Execution failures

For complete troubleshooting methodology and detailed examples, see the [full troubleshooting guide](./product_sales/README.md).

---

## Complete End-to-End Test

Run all workflows in sequence:

```bash
# Workflow 1: Explore Unity Catalog
echo "=== Workflow 1: Exploring Unity Catalog ==="
databricks catalogs list
databricks schemas list samples
databricks tables list samples tpch

# Workflow 2: Create Notebook
echo "=== Workflow 2: Creating Notebook ==="
CURRENT_USER=$(databricks current-user me --output json | jq -r '.userName')
databricks workspace import \
  /Users/$CURRENT_USER/customer_analysis \
  --file customer_analysis/customer_analysis.py \
  --language PYTHON \
  --format SOURCE \
  --overwrite

# Workflow 3: Create Job
echo "=== Workflow 3: Creating Job ==="
# (Update customer_analysis/job_config.json with your email first)
JOB_ID=$(databricks jobs create --json @customer_analysis/job_config.json --output json | jq -r '.job_id')
echo "Job ID: $JOB_ID"

# Workflow 4: Run and Monitor
echo "=== Workflow 4: Running Job ==="
RUN_ID=$(databricks jobs run-now $JOB_ID --output json | jq -r '.run_id')
echo "Run ID: $RUN_ID"

# Monitor
echo "Monitoring run (press Ctrl+C to stop monitoring)..."
while true; do
  STATE=$(databricks runs get $RUN_ID --output json | jq -r '.state.life_cycle_state')
  RESULT=$(databricks runs get $RUN_ID --output json | jq -r '.state.result_state // "RUNNING"')
  echo "$(date '+%H:%M:%S') - State: $STATE | Result: $RESULT"

  if [[ "$STATE" == "TERMINATED" ]]; then
    echo "✓ Job completed: $RESULT"
    break
  fi
  sleep 10
done

echo "=== All Workflows Complete ==="
```

---

## Cleanup

Remove test resources after completing workflows:

```bash
# Delete job
databricks jobs delete $JOB_ID

# Delete notebook
databricks workspace delete /Users/$CURRENT_USER/customer_analysis

# Confirm deletion
echo "Cleanup complete"
```

---

## Prerequisites

- Databricks CLI installed and configured
- Access to `samples.tpch` database (default in Databricks workspaces)
- `jq` installed for JSON processing: `brew install jq`

## Notes

- **Trial workspaces use serverless compute** - No need to specify cluster configuration
- Update email addresses in job_config.json for notifications
- Schedule can be modified in job_config.json (cron format)
- All commands use default profile; add `--profile <name>` as needed
- For production workspaces with cluster creation permissions, you can add `new_cluster` configuration to the job config
