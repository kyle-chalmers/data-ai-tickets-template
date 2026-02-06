# Databricks Jobs

This folder contains job definitions and scripts for scheduled Databricks workloads.

## Jobs

| Job | Schedule | Description |
|-----|----------|-------------|
| [climate_data_refresh](climate_data_refresh/) | 3rd of each month, 00:00 America/Phoenix | Fetches previous month's weather for Arizona cities from Open-Meteo, writes to Delta/DBFS. |

## Usage

- Job configs are in each subfolder as `job_config.json`.
- Deploy with Databricks CLI: `databricks jobs create --json @<folder>/job_config.json`.
- Use the dev profile for deployment: `--profile bidev` (or your configured dev profile).
