# Databricks Jobs

This folder contains Databricks job definitions and Python scripts for scheduled data pipelines.

## Available Jobs

| Job | Description | Schedule | Status |
|-----|-------------|----------|--------|
| [climate_data_refresh](./climate_data_refresh/) | Monthly Arizona weather data from Open-Meteo API | 3rd of month, 6 AM | Demo |

## Folder Structure

```
databricks_jobs/
├── README.md                    # This file
└── job_name/
    ├── README.md                # Job documentation
    ├── job_config.json          # Databricks job configuration
    └── *.py                     # Python job scripts
```

## Databricks CLI Setup

### Profile Configuration

Add to `~/.databrickscfg`:

```ini
[bidev]
host = https://your-workspace.cloud.databricks.com
token = dapi_your_token_here
```

### Verify Connection

```bash
databricks workspace list / --profile bidev
```

## Common Commands

### Deploy a Job

```bash
# Upload script to DBFS
databricks fs cp job_name/script.py dbfs:/jobs/job_name/script.py --profile bidev

# Create job
databricks jobs create --json-file job_name/job_config.json --profile bidev
```

### Run a Job

```bash
# List jobs
databricks jobs list --profile bidev

# Run by ID
databricks jobs run-now --job-id 12345 --profile bidev
```

### Monitor Runs

```bash
# List runs
databricks runs list --job-id 12345 --limit 5 --profile bidev

# Get run details
databricks runs get --run-id 67890 --profile bidev
```

## Job Development Guidelines

1. **Error Handling:** All jobs must handle API failures gracefully
2. **Validation:** Validate data before writing to Delta tables
3. **Logging:** Use Python logging for visibility in Databricks logs
4. **Idempotency:** Jobs should be safe to re-run
5. **Testing:** Include local execution mode for development
