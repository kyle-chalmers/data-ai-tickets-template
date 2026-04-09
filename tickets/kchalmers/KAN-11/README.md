# KAN-11: Deploy Automated Arizona Climate Data Collection Job

**Jira:** [KAN-11](https://kclabs.atlassian.net/browse/KAN-11)
**Status:** Done
**Date:** 2026-04-08

## Objective

Deploy the monthly Databricks job built in KAN-13 to collect weather data for Arizona cities using the Open-Meteo API. Job runs on the 3rd of each month at 6 AM Phoenix time.

## Summary

Deployment ticket for the KAN-13 Arizona Climate Data Collection job. The notebook and job configs already exist in `databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/`. This ticket provides the deployment runbook, verification scripts, and documentation.

## Deliverables

| File | Description |
|------|-------------|
| `final_deliverables/1_deploy_job.sh` | Deployment script: auth check, notebook import, test run, job creation |
| `final_deliverables/2_verify_deployment.sh` | Post-deployment verification: notebook, job schedule, table checks |
| `ticket_comment.txt` | Final Jira comment |

## Source Code (KAN-13)

| File | Purpose |
|------|---------|
| `databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/arizona_climate_data_collection.py` | Databricks notebook |
| `databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/job_config.json` | Scheduled job config (monthly) |
| `databricks_jobs_claude/KAN-13 Arizona Climate Data Collection/test_job_config.json` | One-time test run config |

## Job Details

- **Workspace:** https://dbc-9fd4b6c0-3c0e.cloud.databricks.com
- **Notebook:** `/Users/kylechalmers@kclabs.ai/arizona_climate_data_collection`
- **Schedule:** `0 0 6 3 * ?` (6 AM, 3rd of month, America/Phoenix)
- **Table:** `climate_demo_claude.default.monthly_arizona_weather`
- **Compute:** Serverless (trial workspace, no new_cluster block)
- **Cities:** Phoenix, Tucson, Mesa, Chandler, Scottsdale, Glendale, Tempe, Peoria, Flagstaff, Yuma

## Assumptions

1. **Databricks CLI auth:** User must run `databricks auth login --profile DEFAULT` before deployment. Auth token expires periodically.
2. **Catalog exists:** `climate_demo_claude` catalog and `default` schema must already exist. Catalog creation requires Databricks UI (REST API blocks CREATE CATALOG with Default Storage on trial workspaces).
3. **Serverless compute:** Trial workspace uses serverless. Job configs intentionally omit `new_cluster`.
4. **No duplicate job check:** Deploy script creates a new job each time. If redeploying, delete the old job first to avoid duplicates.

## Manual Run

```bash
databricks jobs run-now <JOB_ID> --profile DEFAULT
```
