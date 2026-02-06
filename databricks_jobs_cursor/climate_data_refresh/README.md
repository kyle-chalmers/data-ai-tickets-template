# Arizona Climate Data Refresh (KAN-12)

Scheduled Databricks job that pulls **previous month's** daily weather for Arizona cities from the Open-Meteo Historical Weather API and writes to DBFS.

## API

- **Open-Meteo Historical Weather API** – no API key, daily variables: `temperature_2m_max`, `temperature_2m_min`, `precipitation_sum`.
- **Why 3rd of the month:** Data availability (IFS ~2-day, ERA5 ~5-day delay) so the full previous month is available.

## Arizona cities (lat, lon)

| City       | Lat    | Lon     |
|-----------|--------|---------|
| Phoenix   | 33.45  | -112.07 |
| Tucson   | 32.22  | -110.97 |
| Flagstaff| 35.20  | -111.65 |
| Mesa     | 33.42  | -111.83 |
| Scottsdale| 33.49  | -111.93 |

## Schedule

- **Cron:** `0 0 0 3 * ?` (00:00 on the 3rd of every month).
- **Timezone:** America/Phoenix.

## Output

- **Table:** `climate_demo_cursor.default.arizona_weather_monthly` (Unity Catalog).
- **One-time catalog setup:** If the catalog does not exist, run the `create_catalog` notebook once (it runs `CREATE CATALOG IF NOT EXISTS climate_demo_cursor` and `CREATE SCHEMA IF NOT EXISTS climate_demo_cursor.default` from inside the workspace so default storage is used). Import `create_catalog.py` to the workspace, then: `databricks jobs submit --json @submit_create_catalog.json` (or run the notebook manually).
- **Columns:** city, latitude, longitude, date, temperature_2m_max, temperature_2m_min, precipitation_sum, data_month. Partition: data_month.

## Deploy (Databricks CLI)

1. Get workspace username: `databricks current-user me --output json | jq -r '.userName'`
2. Import notebook:  
   `databricks workspace import /Users/<USERNAME>/climate_data_refresh --file databricks_jobs_cursor/climate_data_refresh/climate_refresh.py --language PYTHON --format SOURCE --overwrite`
3. Update `job_config.json`: set `notebook_path` to `/Users/<USERNAME>/climate_data_refresh`.
4. Create job: `databricks jobs create --json @databricks_jobs_cursor/climate_data_refresh/job_config.json` (add `--profile bidev` if needed).

## Manual test (API)

```bash
curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-31&daily=temperature_2m_max,temperature_2m_min&timezone=America/Phoenix" | jq '.daily'
```

## Run job manually

```bash
databricks jobs run-now <JOB_ID>
```
