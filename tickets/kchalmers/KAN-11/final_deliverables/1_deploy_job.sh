#!/bin/bash
# KAN-11: Deploy Arizona Climate Data Collection Job
# Source code: databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/
# Workspace: https://dbc-9fd4b6c0-3c0e.cloud.databricks.com
# Target table: climate_demo_claude.default.monthly_arizona_weather

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SOURCE_DIR="$REPO_ROOT/databricks_jobs_claude/KAN-13 Arizona Climate Data Collection"
NOTEBOOK_PATH="/Users/kylechalmers@kclabs.ai/arizona_climate_data_collection"
PROFILE="DEFAULT"

echo "=== KAN-11: Deploy Arizona Climate Data Collection ==="
echo ""

# Step 0: Verify Databricks CLI auth
echo "Step 0: Verifying Databricks CLI authentication..."
if ! databricks workspace list / --profile "$PROFILE" > /dev/null 2>&1; then
    echo "ERROR: Databricks CLI auth expired. Run:"
    echo "  databricks auth login --profile DEFAULT"
    exit 1
fi
echo "  Auth OK"

# Step 1: Upload notebook
echo ""
echo "Step 1: Importing notebook to workspace..."
databricks workspace import "$NOTEBOOK_PATH" \
  --file "$SOURCE_DIR/arizona_climate_data_collection.py" \
  --language PYTHON --format SOURCE --overwrite \
  --profile "$PROFILE"
echo "  Notebook imported to $NOTEBOOK_PATH"

# Step 2: Test run
echo ""
echo "Step 2: Submitting test run..."
RUN_OUTPUT=$(databricks jobs submit --json @"$SOURCE_DIR/test_job_config.json" --profile "$PROFILE")
RUN_ID=$(echo "$RUN_OUTPUT" | jq -r '.run_id')
echo "  Test run submitted: run_id=$RUN_ID"
echo "  Monitor in Databricks UI or run:"
echo "    databricks runs get --run-id $RUN_ID --profile $PROFILE"

# Step 3: Create scheduled job
echo ""
echo "Step 3: Creating scheduled job..."
JOB_OUTPUT=$(databricks jobs create --json @"$SOURCE_DIR/job_config.json" --profile "$PROFILE")
JOB_ID=$(echo "$JOB_OUTPUT" | jq -r '.job_id')
echo "  Scheduled job created: job_id=$JOB_ID"
echo "  Schedule: 6 AM on 3rd of each month (America/Phoenix)"

echo ""
echo "=== Deployment complete ==="
echo "Job ID: $JOB_ID"
echo "Manual run: databricks jobs run-now $JOB_ID --profile $PROFILE"
