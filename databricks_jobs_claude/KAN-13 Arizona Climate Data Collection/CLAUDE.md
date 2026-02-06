# KAN-13: Arizona Climate Data Collection — Context

## Ticket Objective
Build and deploy an automated Databricks job that collects monthly Arizona climate data from the Open-Meteo Archive API for 10 cities, storing results in a Unity Catalog Delta table.

## Technical Approach
- **API:** Open-Meteo Archive (`archive-api.open-meteo.com/v1/archive`) — chosen for zero auth, no rate limit risk, and 80+ years of historical data
- **Notebook format:** Databricks notebook source with `# COMMAND ----------` separators and `# MAGIC %md` cells
- **Data flow:** API (daily, Celsius/metric) → Python aggregation (monthly, Fahrenheit/imperial) → Spark DataFrame → Delta table (append, partitioned by year/month)
- **Deployment:** `databricks workspace import` → `databricks jobs submit` (test) → `databricks jobs create` (scheduled)

## Data/Domain Insights
- Open-Meteo returns data in Celsius/km/h/mm — notebook converts to Fahrenheit/mph/inches for US audience
- API has ~5 day data lag, so scheduling on the 3rd of the month ensures full previous month availability
- Arizona (America/Phoenix) has no DST, making cron scheduling straightforward
- `dateutil.relativedelta` handles year boundaries cleanly for previous-month calculation

## Lessons Learned
- Databricks REST API blocks `CREATE CATALOG` with Default Storage — must run via notebook/SQL instead of API call
- `acli jira workitem comment` requires the subcommand `create` (not just `comment --key --body`)
- Trial Databricks workspaces use serverless compute — do NOT include `new_cluster` in job configs
- `databricks jobs submit` is for one-time test runs; `databricks jobs create` is for persistent scheduled jobs
- `notebook_output` is empty in CLI output for `get-run-output` — `display()` results only visible in Databricks UI

## Key Resources
- **Databricks Job ID:** 532675237528452
- **Unity Catalog:** `climate_demo_claude` (catalog) → `default` (schema) → `monthly_arizona_weather` (table)
- **Workspace notebook:** `/Users/kylechalmers@kclabs.ai/arizona_climate_data_collection`
- **Schedule:** `0 0 6 3 * ?` — 6 AM on 3rd of month, America/Phoenix

## Relationship to Other Tickets
- Parallel to Cursor-built version in `databricks_jobs_cursor/climate_data_refresh/` (writes to `climate_demo.monthly_arizona_weather`)
- Part of Claude Code vs Cursor video comparison (`videos/claude_code_vs_cursor/`)
- Origin: Demo 2 from AZ Emerging Tech Meetup (January 2026)

## Repository Integration
- Located in `databricks_jobs_claude/` — the Claude Code counterpart to `databricks_jobs_cursor/`
- Follows existing job config patterns from `videos/integrating_claude_and_databricks/example_workflow/`
