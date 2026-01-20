# Climate Data Monthly Refresh Job

Automated job that fetches monthly weather data from Open-Meteo API for Arizona cities and stores aggregated statistics in a Delta table.

## Data Source

**API:** [Open-Meteo Historical Weather API](https://open-meteo.com/en/docs/historical-weather-api)

| Attribute | Value |
|-----------|-------|
| Base URL | `https://archive-api.open-meteo.com/v1/archive` |
| Authentication | None required (free) |
| Rate Limit | 10,000 requests/day |
| Data Lag | ~5 days |
| Update Frequency | Daily |
| Historical Range | 1940 to present |

### Variables Collected

| Variable | Description | Unit |
|----------|-------------|------|
| temperature_2m_max | Daily max temperature | Celsius |
| temperature_2m_min | Daily min temperature | Celsius |
| temperature_2m_mean | Daily mean temperature | Celsius |
| precipitation_sum | Daily precipitation | mm |
| wind_speed_10m_max | Daily max wind speed | km/h |
| relative_humidity_2m_mean | Daily mean humidity | % |

## Cities Covered

10 Arizona cities: Phoenix, Tucson, Flagstaff, Mesa, Scottsdale, Tempe, Gilbert, Chandler, Yuma, Prescott

## Schedule

- **Frequency:** Monthly
- **Cron:** `0 0 6 3 * ?` (6 AM on 3rd day of month)
- **Timezone:** America/Phoenix
- **Rationale:** Run on 3rd to ensure all previous month data is available (5-day lag)

## Output

**Delta Table:** `climate_demo.monthly_arizona_weather`

| Column | Type | Description |
|--------|------|-------------|
| city | STRING | City name |
| year_month | STRING | YYYY-MM format |
| latitude | DOUBLE | City latitude |
| longitude | DOUBLE | City longitude |
| elevation_m | DOUBLE | Elevation in meters |
| days_in_month | INT | Days of data |
| temp_max_high_c | DOUBLE | Highest max temp |
| temp_max_avg_c | DOUBLE | Average max temp |
| temp_min_low_c | DOUBLE | Lowest min temp |
| temp_mean_avg_c | DOUBLE | Average mean temp |
| precipitation_total_mm | DOUBLE | Total precipitation |
| precipitation_days | INT | Days with rain |
| wind_max_kmh | DOUBLE | Max wind speed |
| humidity_avg_pct | DOUBLE | Average humidity |
| data_source | STRING | API source |
| refresh_timestamp | TIMESTAMP | Job run time |

## Deployment

### Upload Job Script

```bash
# Upload to DBFS
databricks fs cp climate_refresh.py dbfs:/jobs/climate_data_refresh/climate_refresh.py --profile bidev
```

### Create Job

```bash
# Create job from config
databricks jobs create --json-file job_config.json --profile bidev
```

### Manual Run

```bash
# Get job ID
JOB_ID=$(databricks jobs list --profile bidev | grep "Climate Data Monthly" | awk '{print $1}')

# Trigger run
databricks jobs run-now --job-id $JOB_ID --profile bidev
```

### Check Status

```bash
# List recent runs
databricks runs list --job-id $JOB_ID --limit 5 --profile bidev
```

## Error Handling

1. **API Timeout:** 30-second timeout per request, 2 retries with 60s interval
2. **Missing Data:** Logs warning, continues with available cities
3. **Validation Failure:** Job fails if <5 cities have data or data incomplete
4. **Cluster Issues:** Spot instance fallback to on-demand

## Local Testing

```bash
# Install dependencies
pip install requests python-dateutil

# Run locally (prints results, doesn't save to Delta)
python climate_refresh.py
```

## Monitoring

- Job run history: Databricks Jobs UI
- Data quality: Check `refresh_timestamp` for staleness
- Alert: Configure email notifications in job_config.json
