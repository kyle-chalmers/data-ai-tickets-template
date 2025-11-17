# Customer Analysis Workflow

Basic Databricks job example demonstrating customer purchase pattern analysis.

## Files

- **`customer_analysis.py`** - PySpark notebook analyzing customer orders
- **`job_config.json`** - Databricks job configuration

## What This Example Does

Analyzes customer purchase patterns from the TPC-H sample dataset:
- Joins `orders` and `customer` tables
- Aggregates total orders, total spent, and average order value per customer
- Groups by customer key, name, and market segment
- Displays top 20 customers by total spend

## Usage

See the [main README](../README.md) for complete workflow instructions (Workflows 1-4).

### Quick Start

```bash
# Get current user
CURRENT_USER=$(databricks current-user me --output json | jq -r '.userName')

# Upload notebook
databricks workspace import \
  /Users/$CURRENT_USER/customer_analysis \
  --file customer_analysis.py \
  --language PYTHON \
  --format SOURCE \
  --overwrite

# Create job (update email in job_config.json first)
JOB_ID=$(databricks jobs create --json @job_config.json --output json | jq -r '.job_id')

# Run job
databricks jobs run-now $JOB_ID
```

## Key Learning Points

- PySpark notebook structure with MAGIC commands
- Explicit join conditions when column names differ
- Serverless job configuration (no cluster needed)
- Basic aggregation and grouping patterns
