# KAN-13: Arizona Climate Data Collection

## Overview
Automated Databricks job that collects monthly climate data for Arizona's top 10 cities using the Open-Meteo Archive API. Data is stored in a Delta table for analysis.

## API: Open-Meteo Archive
- **Endpoint:** `https://archive-api.open-meteo.com/v1/archive`
- **No API key required** — zero maintenance for automated jobs
- **No rate limit concerns** for monthly pulls
- **80+ years** of historical data available

## Cities Covered
Phoenix, Tucson, Mesa, Chandler, Scottsdale, Glendale, Tempe, Peoria, Flagstaff, Yuma

## Schedule
- **Cron:** `0 0 6 3 * ?` — 6:00 AM on the 3rd of every month
- **Timezone:** America/Phoenix (no DST)
- Collects previous month's data

## Delta Table
- **Location:** `default.arizona_climate_data`
- **Partitioned by:** `year`, `month`
- **Mode:** Append

## Metrics Collected
| Metric | Source | Aggregation |
|--------|--------|-------------|
| avg_temp_max_f | temperature_2m_max | Monthly average, converted to Fahrenheit |
| avg_temp_min_f | temperature_2m_min | Monthly average, converted to Fahrenheit |
| avg_temp_mean_f | temperature_2m_mean | Monthly average, converted to Fahrenheit |
| total_precipitation_in | precipitation_sum | Monthly total, converted to inches |
| avg_humidity_pct | relative_humidity_2m_mean | Monthly average |
| max_wind_speed_mph | wind_speed_10m_max | Monthly maximum, converted to mph |

## Deployment
```bash
# Upload notebook
databricks workspace import /Users/kylechalmers@kclabs.ai/arizona_climate_data_collection \
  --file arizona_climate_data_collection.py --language PYTHON --format SOURCE --overwrite

# Test run
databricks jobs submit --json @test_job_config.json

# Create scheduled job
databricks jobs create --json @job_config.json
```

## Files
| File | Purpose |
|------|---------|
| `arizona_climate_data_collection.py` | Databricks notebook — fetches and stores climate data |
| `job_config.json` | Scheduled job config (monthly) |
| `test_job_config.json` | One-time test run config |
