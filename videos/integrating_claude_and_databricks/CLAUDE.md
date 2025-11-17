# Databricks CLI Reference

Quick reference for Databricks CLI syntax and common patterns.

---

## Critical Syntax Rules

### Positional Arguments (NOT Flags)

❌ WRONG: `databricks schemas list --catalog-name samples`
✅ CORRECT: `databricks schemas list samples`

❌ WRONG: `databricks jobs get --job-id 123`
✅ CORRECT: `databricks jobs get 123`

### JSON Files

Use `@` prefix: `databricks jobs create --json @config.json`

---

## Unity Catalog

```bash
# List catalogs, schemas, tables
databricks catalogs list
databricks schemas list <CATALOG>
databricks tables list <CATALOG> <SCHEMA>
databricks tables get <CATALOG.SCHEMA.TABLE> --output json
```

---

## Workspace

```bash
# Get current user
databricks current-user me --output json | jq -r '.userName'

# Notebook operations
databricks workspace list /Users/<USER>/
databricks workspace import /Users/<USER>/name --file local.py --language PYTHON --format SOURCE --overwrite
databricks workspace export /Users/<USER>/name --format SOURCE
databricks workspace delete /Users/<USER>/name
```

---

## Jobs

### Create Job

```bash
databricks jobs create --json @config.json --output json
```

**Serverless Job Config Template:**
```json
{
  "name": "Job Name",
  "tasks": [{
    "task_key": "task_name",
    "notebook_task": {
      "notebook_path": "/Users/EMAIL/notebook",
      "source": "WORKSPACE"
    },
    "timeout_seconds": 3600
  }],
  "schedule": {
    "quartz_cron_expression": "0 0 8 * * ?",
    "timezone_id": "America/Los_Angeles"
  },
  "max_concurrent_runs": 1,
  "email_notifications": {
    "on_failure": ["email@example.com"]
  }
}
```

**Note:** Trial workspaces use serverless - do NOT include `new_cluster`.

### Run and Monitor

```bash
# Run job
databricks jobs run-now <JOB_ID> --output json

# Get run status
databricks jobs get-run <RUN_ID> --output json | jq '.state'

# Monitor until complete
while true; do
  STATE=$(databricks jobs get-run $RUN_ID --output json | jq -r '.state.life_cycle_state')
  echo "Status: $STATE"
  [[ "$STATE" == "TERMINATED" ]] && break
  sleep 10
done

# Get task output (multi-task jobs)
databricks jobs get-run <RUN_ID> --output json | jq '.tasks[] | {task_key, run_id}'
databricks jobs get-run-output <TASK_RUN_ID>
```

### Test Notebooks (One-Time Runs)

```bash
databricks jobs submit --json @test_config.json --output json
```

### Manage Jobs

```bash
databricks jobs list
databricks jobs get <JOB_ID>
databricks jobs list-runs --job-id <JOB_ID> --limit 5
databricks jobs delete <JOB_ID>
```

---

## Clusters & Warehouses

```bash
databricks clusters list
databricks clusters get <CLUSTER_ID>
databricks clusters start <CLUSTER_ID>

databricks warehouses list
databricks warehouses start <WAREHOUSE_ID>
```

---

## Common Patterns

### Update Config with Current User

```bash
CURRENT_USER=$(databricks current-user me --output json | jq -r '.userName')

cat config.json | jq --arg user "$CURRENT_USER" \
  '.tasks[0].notebook_task.notebook_path = "/Users/\($user)/notebook"' \
  > config_updated.json
```

### Extract Fields with jq

```bash
databricks jobs get <JOB_ID> --output json | jq '{job_id, name: .settings.name, creator: .creator_user_name}'
```

---

## Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `accepts 1 arg(s), received 2` | Using flags instead of positional args | Use `databricks schemas list samples` not `--catalog-name` |
| `unknown flag: --json-file` | Wrong flag name | Use `--json @file.json` |
| `Only serverless compute supported` | Trial workspace limitation | Remove `new_cluster` from config |
| `parse error near '('` | Complex shell nesting | Break into simpler commands |

---

## PySpark Notebook Gotchas

### Join Syntax

❌ WRONG: `df1.join(df2, "column")` - fails if column names differ
✅ CORRECT: `df1.join(df2, df1.col1 == df2.col2)`

**TPCH Table Columns:**
- `orders`: o_custkey, o_orderkey, o_orderdate, o_totalprice
- `customer`: c_custkey, c_name, c_mktsegment

---

## Best Practices

1. Use `--output json` for programmatic parsing
2. Store IDs in variables: `JOB_ID=$(... | jq -r '.job_id')`
3. Test notebooks with `submit` before creating jobs
4. Always use `--overwrite` when updating notebooks
5. Use `--profile` for multiple workspaces

---

## Quick Reference

```bash
# Unity Catalog
databricks catalogs list
databricks schemas list <CATALOG>
databricks tables list <CATALOG> <SCHEMA>

# Workspace
databricks current-user me
databricks workspace import /Users/<USER>/name --file local.py --language PYTHON --format SOURCE --overwrite

# Jobs
databricks jobs create --json @config.json
databricks jobs run-now <JOB_ID>
databricks jobs get-run <RUN_ID>
databricks jobs submit --json @test.json  # One-time test run
databricks jobs delete <JOB_ID>
```

**Resources:** [Official Docs](https://docs.databricks.com/dev-tools/cli/) | [Example Workflows](./example_workflow/README.md)
