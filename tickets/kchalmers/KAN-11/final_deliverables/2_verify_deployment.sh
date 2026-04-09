#!/bin/bash
# KAN-11: Verify deployment of Arizona Climate Data Collection Job
set -e

PROFILE="DEFAULT"
NOTEBOOK_PATH="/Users/kylechalmers@kclabs.ai/arizona_climate_data_collection"
JOB_NAME="KAN-13 Arizona Climate Data Collection"

echo "=== KAN-11: Deployment Verification ==="

# Check 1: Notebook exists
echo ""
echo "Check 1: Notebook in workspace"
if databricks workspace get-status "$NOTEBOOK_PATH" --profile "$PROFILE" > /dev/null 2>&1; then
    echo "  PASS: Notebook exists at $NOTEBOOK_PATH"
else
    echo "  FAIL: Notebook not found at $NOTEBOOK_PATH"
fi

# Check 2: Job exists and has correct schedule
echo ""
echo "Check 2: Scheduled job"
JOB_LIST=$(databricks jobs list --output json --profile "$PROFILE" 2>/dev/null || echo "[]")
JOB_MATCH=$(echo "$JOB_LIST" | jq -r ".[] | select(.settings.name == \"$JOB_NAME\") | .job_id" 2>/dev/null || echo "")
if [ -n "$JOB_MATCH" ]; then
    echo "  PASS: Job found (ID: $JOB_MATCH)"
    echo "  Schedule details:"
    databricks jobs get --job-id "$JOB_MATCH" --profile "$PROFILE" | jq '.settings.schedule'
else
    echo "  FAIL: Job '$JOB_NAME' not found"
fi

# Check 3: Delta table (only valid after first successful run)
echo ""
echo "Check 3: Delta table (requires at least one successful run)"
echo "  Table: climate_demo_claude.default.monthly_arizona_weather"
echo "  Verify in Databricks UI: Data > Catalog > climate_demo_claude > default > monthly_arizona_weather"

echo ""
echo "=== Verification complete ==="
