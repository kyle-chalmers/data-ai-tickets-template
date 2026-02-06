# Databricks notebook source
# MAGIC %md
# MAGIC # Arizona Climate Data Collection
# MAGIC
# MAGIC Collects monthly climate data for Arizona's top 10 cities from the Open-Meteo Archive API.
# MAGIC Aggregates daily observations into monthly statistics and appends to a Delta table.
# MAGIC
# MAGIC **Schedule:** 3rd of every month at 6:00 AM Phoenix time
# MAGIC
# MAGIC **API:** Open-Meteo Archive (no API key required)

# COMMAND ----------

import requests
import json
import time
from datetime import datetime, date
from dateutil.relativedelta import relativedelta
from pyspark.sql.types import StructType, StructField, StringType, FloatType, IntegerType, TimestampType

# COMMAND ----------

# MAGIC %md
# MAGIC ## Configuration

# COMMAND ----------

# Arizona top 10 cities by population with coordinates
ARIZONA_CITIES = [
    {"city": "Phoenix",     "lat": 33.4484, "lon": -112.0740},
    {"city": "Tucson",      "lat": 32.2226, "lon": -110.9747},
    {"city": "Mesa",        "lat": 33.4152, "lon": -111.8315},
    {"city": "Chandler",    "lat": 33.3062, "lon": -111.8413},
    {"city": "Scottsdale",  "lat": 33.4942, "lon": -111.9261},
    {"city": "Glendale",    "lat": 33.5387, "lon": -112.1860},
    {"city": "Tempe",       "lat": 33.4255, "lon": -111.9400},
    {"city": "Peoria",      "lat": 33.5806, "lon": -112.2374},
    {"city": "Flagstaff",   "lat": 35.1983, "lon": -111.6513},
    {"city": "Yuma",        "lat": 32.6927, "lon": -114.6277},
]

API_BASE_URL = "https://archive-api.open-meteo.com/v1/archive"
DAILY_VARIABLES = "temperature_2m_max,temperature_2m_min,temperature_2m_mean,precipitation_sum,relative_humidity_2m_mean,wind_speed_10m_max"
DELTA_TABLE = "climate_demo_claude.default.monthly_arizona_weather"
MAX_RETRIES = 3
RETRY_DELAY_SECONDS = 5

# COMMAND ----------

# MAGIC %md
# MAGIC ## Calculate Date Range (Previous Month)

# COMMAND ----------

today = date.today()
first_of_current_month = today.replace(day=1)
last_of_previous_month = first_of_current_month - relativedelta(days=1)
first_of_previous_month = last_of_previous_month.replace(day=1)

target_year = first_of_previous_month.year
target_month = first_of_previous_month.month
start_date = first_of_previous_month.strftime("%Y-%m-%d")
end_date = last_of_previous_month.strftime("%Y-%m-%d")

print(f"Collecting data for: {start_date} to {end_date}")
print(f"Year: {target_year}, Month: {target_month}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Fetch and Aggregate Climate Data

# COMMAND ----------

def celsius_to_fahrenheit(c):
    """Convert Celsius to Fahrenheit."""
    return round((c * 9/5) + 32, 1) if c is not None else None

def kmh_to_mph(kmh):
    """Convert km/h to mph."""
    return round(kmh * 0.621371, 1) if kmh is not None else None

def mm_to_inches(mm):
    """Convert millimeters to inches."""
    return round(mm * 0.0393701, 2) if mm is not None else None

def fetch_city_data(city_info, start_date, end_date):
    """Fetch daily climate data from Open-Meteo and aggregate to monthly stats."""
    params = {
        "latitude": city_info["lat"],
        "longitude": city_info["lon"],
        "start_date": start_date,
        "end_date": end_date,
        "daily": DAILY_VARIABLES,
        "temperature_unit": "celsius",
        "wind_speed_unit": "kmh",
        "precipitation_unit": "mm",
        "timezone": "America/Phoenix",
    }

    for attempt in range(MAX_RETRIES):
        try:
            response = requests.get(API_BASE_URL, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()

            daily = data.get("daily", {})
            if not daily or not daily.get("time"):
                print(f"  WARNING: No daily data returned for {city_info['city']}")
                return None

            num_days = len(daily["time"])

            # Aggregate daily values to monthly stats
            def safe_avg(values):
                valid = [v for v in values if v is not None]
                return sum(valid) / len(valid) if valid else None

            def safe_sum(values):
                valid = [v for v in values if v is not None]
                return sum(valid) if valid else None

            def safe_max(values):
                valid = [v for v in values if v is not None]
                return max(valid) if valid else None

            return {
                "city": city_info["city"],
                "state": "AZ",
                "latitude": city_info["lat"],
                "longitude": city_info["lon"],
                "year": target_year,
                "month": target_month,
                "days_in_sample": num_days,
                "avg_temp_max_f": celsius_to_fahrenheit(safe_avg(daily.get("temperature_2m_max", []))),
                "avg_temp_min_f": celsius_to_fahrenheit(safe_avg(daily.get("temperature_2m_min", []))),
                "avg_temp_mean_f": celsius_to_fahrenheit(safe_avg(daily.get("temperature_2m_mean", []))),
                "total_precipitation_in": mm_to_inches(safe_sum(daily.get("precipitation_sum", []))),
                "avg_humidity_pct": round(safe_avg(daily.get("relative_humidity_2m_mean", [])), 1) if safe_avg(daily.get("relative_humidity_2m_mean", [])) else None,
                "max_wind_speed_mph": kmh_to_mph(safe_max(daily.get("wind_speed_10m_max", []))),
                "collection_timestamp": datetime.utcnow(),
            }

        except requests.exceptions.RequestException as e:
            print(f"  Attempt {attempt + 1}/{MAX_RETRIES} failed for {city_info['city']}: {e}")
            if attempt < MAX_RETRIES - 1:
                time.sleep(RETRY_DELAY_SECONDS)
            else:
                print(f"  ERROR: All retries exhausted for {city_info['city']}")
                return None

# COMMAND ----------

# Fetch data for all cities
results = []
for city_info in ARIZONA_CITIES:
    print(f"Fetching data for {city_info['city']}...")
    record = fetch_city_data(city_info, start_date, end_date)
    if record:
        results.append(record)
        print(f"  OK: {city_info['city']} — avg temp {record['avg_temp_mean_f']}°F, precip {record['total_precipitation_in']}in")
    time.sleep(0.5)  # Brief pause between requests

print(f"\nSuccessfully collected data for {len(results)}/{len(ARIZONA_CITIES)} cities")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Write to Delta Table

# COMMAND ----------

schema = StructType([
    StructField("city", StringType(), False),
    StructField("state", StringType(), False),
    StructField("latitude", FloatType(), False),
    StructField("longitude", FloatType(), False),
    StructField("year", IntegerType(), False),
    StructField("month", IntegerType(), False),
    StructField("days_in_sample", IntegerType(), False),
    StructField("avg_temp_max_f", FloatType(), True),
    StructField("avg_temp_min_f", FloatType(), True),
    StructField("avg_temp_mean_f", FloatType(), True),
    StructField("total_precipitation_in", FloatType(), True),
    StructField("avg_humidity_pct", FloatType(), True),
    StructField("max_wind_speed_mph", FloatType(), True),
    StructField("collection_timestamp", TimestampType(), False),
])

df = spark.createDataFrame(results, schema=schema)

df.write.format("delta") \
    .mode("append") \
    .partitionBy("year", "month") \
    .saveAsTable(DELTA_TABLE)

print(f"Written {df.count()} records to {DELTA_TABLE}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Results Summary

# COMMAND ----------

display(df.orderBy("city"))

# COMMAND ----------

# Verify data in table
total_records = spark.table(DELTA_TABLE).count()
months_covered = spark.table(DELTA_TABLE).select("year", "month").distinct().count()
print(f"Total records in {DELTA_TABLE}: {total_records}")
print(f"Months of data collected: {months_covered}")
