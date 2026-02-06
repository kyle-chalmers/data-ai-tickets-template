# Databricks notebook source
# MAGIC %md
# MAGIC # Arizona Climate Data Refresh
# MAGIC Fetches previous month's daily weather for Arizona cities from Open-Meteo and writes to DBFS.

# COMMAND ----------

import urllib.request
import json
import time
from datetime import datetime, timedelta
from typing import List, Tuple

# COMMAND ----------

# Arizona cities: (name, lat, lon)
ARIZONA_CITIES: List[Tuple[str, float, float]] = [
    ("Phoenix", 33.45, -112.07),
    ("Tucson", 32.22, -110.97),
    ("Flagstaff", 35.20, -111.65),
    ("Mesa", 33.42, -111.83),
    ("Scottsdale", 33.49, -111.93),
]

BASE_URL = "https://archive-api.open-meteo.com/v1/archive"
DAILY_VARS = "temperature_2m_max,temperature_2m_min,precipitation_sum"
# Unity Catalog table (avoids disabled DBFS root).
OUTPUT_TABLE = "climate_demo_cursor.default.arizona_weather_monthly"
MAX_RETRIES = 3
RETRY_DELAY_SEC = 2

# COMMAND ----------

def previous_month_range():
    """Return (start_date, end_date) for previous month in YYYY-MM-DD."""
    today = datetime.now()
    first_this_month = today.replace(day=1)
    last_prev = first_this_month - timedelta(days=1)
    first_prev = last_prev.replace(day=1)
    return first_prev.strftime("%Y-%m-%d"), last_prev.strftime("%Y-%m-%d")

# COMMAND ----------

def fetch_city_month(city: str, lat: float, lon: float, start: str, end: str) -> dict:
    """Fetch daily archive for one city. Retries on 5xx/429."""
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start,
        "end_date": end,
        "daily": DAILY_VARS,
        "timezone": "America/Phoenix",
    }
    q = "&".join(f"{k}={v}" for k, v in params.items())
    url = f"{BASE_URL}?{q}"
    for attempt in range(MAX_RETRIES):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "ArizonaClimateJob/1.0"})
            with urllib.request.urlopen(req, timeout=30) as resp:
                return json.loads(resp.read().decode())
        except Exception as e:
            if getattr(e, "code", None) in (429, 500, 502, 503) and attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY_SEC * (attempt + 1))
                continue
            raise

# COMMAND ----------

start_date, end_date = previous_month_range()
print(f"Fetching previous month: {start_date} to {end_date}")

# COMMAND ----------

rows = []
for city, lat, lon in ARIZONA_CITIES:
    data = fetch_city_month(city, lat, lon, start_date, end_date)
    daily = data.get("daily", {})
    times = daily.get("time", [])
    tmax = daily.get("temperature_2m_max", [])
    tmin = daily.get("temperature_2m_min", [])
    precip = daily.get("precipitation_sum", [])
    for i, t in enumerate(times):
        rows.append({
            "city": city,
            "latitude": lat,
            "longitude": lon,
            "date": t,
            "temperature_2m_max": tmax[i] if i < len(tmax) else None,
            "temperature_2m_min": tmin[i] if i < len(tmin) else None,
            "precipitation_sum": precip[i] if i < len(precip) else None,
            "data_month": start_date[:7],
        })
    time.sleep(0.5)  # be polite to the API

# COMMAND ----------

if not rows:
    raise RuntimeError("No data fetched for any city")

df = spark.createDataFrame(rows)
# Write to Unity Catalog table (public DBFS root disabled on many workspaces).
# Delete this month first so re-runs replace rather than duplicate; then append.
data_month_val = start_date[:7]
from pyspark.sql.utils import AnalysisException
try:
    spark.sql(f"DELETE FROM {OUTPUT_TABLE} WHERE data_month = '{data_month_val}'")
except AnalysisException:
    pass  # table may not exist on first run
df.write.format("delta").mode("append").option("overwriteSchema", "true").partitionBy("data_month").saveAsTable(OUTPUT_TABLE)
print(f"Wrote {len(rows)} rows to table {OUTPUT_TABLE}")

# COMMAND ----------

# QC: record count for this month
cnt = spark.sql(f"SELECT COUNT(*) AS n FROM {OUTPUT_TABLE} WHERE data_month = '{start_date[:7]}'").collect()[0]["n"]
assert cnt == len(rows), f"Record count mismatch: wrote {len(rows)}, read back {cnt}"
print(f"QC passed: {cnt} records")
