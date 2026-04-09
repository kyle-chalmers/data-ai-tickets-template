# KAN-11: Deploy Arizona Climate Data Collection — Context

## Ticket Objective
Deploy the KAN-13 Arizona climate data collection job to Databricks as a scheduled monthly job.

## Technical Approach
- **Deployment model:** Shell scripts wrapping Databricks CLI commands
- **Three-step deploy:** (1) workspace import notebook, (2) submit test run, (3) create scheduled job
- **Verification:** Separate script checks notebook existence, job schedule, and table availability
- **Source code location:** `databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/`

## Data/Domain Insights
- Open-Meteo API has ~5 day data lag; scheduling on 3rd ensures full previous month data
- Arizona (America/Phoenix) has no DST, simplifying cron scheduling
- Trial Databricks workspaces use serverless compute — never include `new_cluster` in job configs
- `CREATE CATALOG` blocked via REST API with Default Storage — must use Databricks UI

## Lessons Learned
- Databricks CLI auth expires periodically; always verify auth before running deploy scripts
- `databricks jobs submit` is for one-time test runs; `databricks jobs create` for persistent scheduled jobs
- `databricks runs get-output` may show empty notebook_output — verify results in Databricks UI
- Deploy script creates a new job each run — running twice creates duplicate scheduled jobs
- Source directory contains spaces (`KAN-13 Arizona Climate Data Collection`) — must quote all path references

## Relationship to Other Tickets
- **KAN-13:** Source code for the job (Claude Code version)
- **KAN-12:** Parallel Cursor-built version in `databricks_jobs_cursor/climate_data_refresh/` targeting `climate_demo_cursor.default.arizona_weather_monthly`
- Part of Claude Code vs Cursor comparison workflow

## Repository Integration
- Ticket folder in `tickets/kchalmers/KAN-11/` — deployment documentation only
- Actual code in `databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/`
- Follows pattern from KAN-12 where ticket folder references code in `databricks_jobs_*` directory
