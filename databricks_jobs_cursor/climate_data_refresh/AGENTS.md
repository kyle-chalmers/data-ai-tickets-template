# AGENTS.md – Arizona Climate Data Refresh (KAN-12)

Context for AI agents working on this job or similar Databricks/Unity Catalog climate pipelines.

## Purpose

- **Job:** Fetches **previous calendar month** daily weather for five Arizona cities from Open-Meteo Historical Weather API; writes to Unity Catalog table `climate_demo_cursor.default.arizona_weather_monthly`.
- **Schedule:** 3rd of each month, 00:00 America/Phoenix (Quartz: `0 0 0 3 * ?`). Running on the 3rd ensures the prior month is fully available (API data latency).
- **Jira:** KAN-12. Job display name in Databricks: `KAN-## Arizona Climate Data Collection` (use ticket key).

## File Roles

| File | Role |
|------|------|
| `climate_refresh.py` | Main job notebook: compute previous month, call API per city, delete-then-append to Delta table, QC count. |
| `create_catalog.py` | One-time setup notebook: `CREATE CATALOG IF NOT EXISTS climate_demo_cursor` and `CREATE SCHEMA IF NOT EXISTS climate_demo_cursor.default`. Run once per workspace if catalog does not exist. |
| `job_config.json` | Databricks job definition: notebook_task, schedule, timeout 3600s, max_concurrent_runs 1. Update `notebook_path` to `/Users/<workspace_username>/climate_data_refresh` before deploy. |
| `README.md` | Human-facing docs: API, cities, schedule, output, deploy steps. |

## Data Source and Output

- **API:** `https://archive-api.open-meteo.com/v1/archive` – no API key. Daily variables: `temperature_2m_max`, `temperature_2m_min`, `precipitation_sum`. Timezone `America/Phoenix`.
- **Cities:** Phoenix, Tucson, Flagstaff, Mesa, Scottsdale (lat/lon in `climate_refresh.py`).
- **Output table:** `climate_demo_cursor.default.arizona_weather_monthly`. Columns: city, latitude, longitude, date, temperature_2m_max, temperature_2m_min, precipitation_sum, data_month. Partition: `data_month`.

## Implementation Details (for agents)

1. **Do not write to DBFS root** (e.g. `dbfs:/jobs/...`). This workspace has public DBFS root disabled; use a Unity Catalog table only.
2. **Do not use `spark.databricks.delta.partitionOverwriteMode`** – it is not available in this environment (CONFIG_NOT_AVAILABLE). Use delete-then-append instead: `DELETE FROM table WHERE data_month = '<YYYY-MM>'` (in try/except for first run when table may not exist), then `df.write.format("delta").mode("append").partitionBy("data_month").saveAsTable(...)`.
3. **Catalog creation:** The CLI cannot create a catalog with “Default Storage” in this account; the UI can. To create from code, run `create_catalog.py` as a notebook inside the workspace (e.g. `databricks jobs submit` with a one-off task). The notebook runs `CREATE CATALOG IF NOT EXISTS climate_demo_cursor` and `CREATE SCHEMA IF NOT EXISTS climate_demo_cursor.default` so the metastore default storage is used.
4. **Re-runs:** Same month is replaced by deleting that month’s partition then appending; no dynamic partition overwrite config required.
5. **Dependencies:** Standard library only (`urllib.request`, `json`, `time`, `datetime`); Spark session for DataFrame and SQL. No extra pip packages.

## Deploy and Run (CLI)

- **Workspace username:** `databricks current-user me --output json | jq -r '.userName'`.
- **Import main notebook:** `databricks workspace import /Users/<USER>/climate_data_refresh --file databricks_jobs_cursor/climate_data_refresh/climate_refresh.py --language PYTHON --format SOURCE --overwrite`.
- **Create catalog (once):** Import `create_catalog.py` to workspace, then submit one-off: `databricks jobs submit --json @submit_create_catalog.json` (JSON must reference notebook path `/Users/<USER>/create_catalog`, source WORKSPACE).
- **Create job:** `databricks jobs create --json @databricks_jobs_cursor/climate_data_refresh/job_config.json`. Use `--profile <dev_profile>` if configured.
- **Run now:** `databricks jobs run-now <JOB_ID>`.
- **Check run:** `databricks jobs get-run <RUN_ID> --output json | jq '.state'`. Poll until `life_cycle_state` is TERMINATED; check `result_state` for SUCCESS/FAILED.
- **List tables:** `databricks tables list climate_demo_cursor default`.

## Common Errors and Fixes

| Error | Cause | Fix |
|------|--------|-----|
| `SCHEMA_NOT_FOUND] ... climate_demo_cursor.default` | Catalog or schema missing | Run `create_catalog.py` once (notebook in workspace, then submit or run manually). |
| `Public DBFS root is disabled` | Writing to dbfs:/ path | Write only to a Unity Catalog table (e.g. `climate_demo_cursor.default.arizona_weather_monthly`). |
| `Configuration spark.databricks.delta.partitionOverwriteMode is not available` | Unsupported in this runtime | Use DELETE for the target month then append; do not set that config. |
| Job config “notebook_path” wrong | User-specific path | Set to `/Users/<workspace_username>/climate_data_refresh` (from `databricks current-user me`). |

## Adding Cities or Changing Output

- **Cities:** Edit `ARIZONA_CITIES` in `climate_refresh.py` (name, lat, lon).
- **Output table:** Change `OUTPUT_TABLE` in `climate_refresh.py`; ensure the target catalog/schema exist (create via UI or a setup notebook similar to `create_catalog.py`).
- **Schedule:** Edit `job_config.json` `schedule.quartz_cron_expression` and `timezone_id`; update job via API/CLI if already created.
