# KAN-12: Automated Arizona Climate Data Collection

**Jira:** [KAN-12](https://kclabs.atlassian.net/browse/KAN-12)  
**Status:** Done

## Summary

Databricks job that fetches previous month's daily weather for Arizona cities (Phoenix, Tucson, Flagstaff, Mesa, Scottsdale) from Open-Meteo and writes to `climate_demo_cursor.default.arizona_weather_monthly`. Runs on the 3rd of each month (America/Phoenix).

## Deliverables

- **Job code:** `databricks_jobs_cursor/climate_data_refresh/` (climate_refresh.py, create_catalog.py, job_config.json, README.md, AGENTS.md)
- **Job in Databricks:** KAN-12 Arizona Climate Data Collection (ID 51661983899231)
- **Output table:** climate_demo_cursor.default.arizona_weather_monthly
- **Final comment:** `ticket_comment.txt`

## Manual run

```bash
databricks jobs run-now 51661983899231
```
