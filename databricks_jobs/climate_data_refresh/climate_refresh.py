"""
Climate Data Refresh Job
Fetches monthly climate data from Open-Meteo Archive API for Arizona cities.

This job:
1. Fetches historical weather data for the previous month
2. Aggregates daily data into monthly statistics
3. Saves results to a Delta table

API: Open-Meteo Archive (https://open-meteo.com/en/docs/historical-weather-api)
- Free, no authentication required
- Historical data from 1940 to 5 days ago
- Daily resolution, aggregated to monthly

Author: Created via Claude Code for AZ AI Meetup Demo
"""

import requests
import json
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Arizona cities with coordinates (latitude, longitude)
ARIZONA_CITIES = {
    "Phoenix": (33.4484, -112.0740),
    "Tucson": (32.2226, -110.9747),
    "Flagstaff": (35.1983, -111.6513),
    "Mesa": (33.4152, -111.8315),
    "Scottsdale": (33.4942, -111.9261),
    "Tempe": (33.4255, -111.9400),
    "Gilbert": (33.3528, -111.7890),
    "Chandler": (33.3062, -111.8413),
    "Yuma": (32.6927, -114.6277),
    "Prescott": (34.5400, -112.4685)
}

# Open-Meteo API configuration
API_BASE_URL = "https://archive-api.open-meteo.com/v1/archive"
DAILY_VARIABLES = [
    "temperature_2m_max",
    "temperature_2m_min",
    "temperature_2m_mean",
    "precipitation_sum",
    "wind_speed_10m_max",
    "relative_humidity_2m_mean"
]


def get_previous_month_dates():
    """Calculate the start and end dates for the previous month."""
    today = datetime.now()
    # First day of current month
    first_of_month = today.replace(day=1)
    # Last day of previous month
    last_of_prev = first_of_month - timedelta(days=1)
    # First day of previous month
    first_of_prev = last_of_prev.replace(day=1)

    return first_of_prev.strftime("%Y-%m-%d"), last_of_prev.strftime("%Y-%m-%d")


def fetch_weather_data(city: str, lat: float, lon: float, start_date: str, end_date: str) -> dict:
    """
    Fetch weather data from Open-Meteo Archive API for a specific location.

    Args:
        city: City name for logging
        lat: Latitude
        lon: Longitude
        start_date: Start date (YYYY-MM-DD)
        end_date: End date (YYYY-MM-DD)

    Returns:
        Dictionary with weather data or None if request fails
    """
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": start_date,
        "end_date": end_date,
        "daily": ",".join(DAILY_VARIABLES),
        "timezone": "America/Phoenix"
    }

    try:
        logger.info(f"Fetching data for {city} ({start_date} to {end_date})")
        response = requests.get(API_BASE_URL, params=params, timeout=30)
        response.raise_for_status()

        data = response.json()
        logger.info(f"Successfully fetched {len(data.get('daily', {}).get('time', []))} days for {city}")
        return data

    except requests.exceptions.Timeout:
        logger.error(f"Timeout fetching data for {city}")
        return None
    except requests.exceptions.HTTPError as e:
        logger.error(f"HTTP error for {city}: {e}")
        return None
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error for {city}: {e}")
        return None


def aggregate_to_monthly(city: str, raw_data: dict, year_month: str) -> dict:
    """
    Aggregate daily weather data to monthly statistics.

    Args:
        city: City name
        raw_data: Raw API response
        year_month: Month in YYYY-MM format

    Returns:
        Dictionary with monthly aggregated statistics
    """
    daily = raw_data.get("daily", {})

    # Extract daily values
    temps_max = [t for t in daily.get("temperature_2m_max", []) if t is not None]
    temps_min = [t for t in daily.get("temperature_2m_min", []) if t is not None]
    temps_mean = [t for t in daily.get("temperature_2m_mean", []) if t is not None]
    precip = [p for p in daily.get("precipitation_sum", []) if p is not None]
    wind = [w for w in daily.get("wind_speed_10m_max", []) if w is not None]
    humidity = [h for h in daily.get("relative_humidity_2m_mean", []) if h is not None]

    # Calculate monthly aggregates
    return {
        "city": city,
        "year_month": year_month,
        "latitude": raw_data.get("latitude"),
        "longitude": raw_data.get("longitude"),
        "elevation_m": raw_data.get("elevation"),
        "days_in_month": len(daily.get("time", [])),
        # Temperature statistics (Celsius)
        "temp_max_high_c": round(max(temps_max), 1) if temps_max else None,
        "temp_max_low_c": round(min(temps_max), 1) if temps_max else None,
        "temp_max_avg_c": round(sum(temps_max) / len(temps_max), 1) if temps_max else None,
        "temp_min_high_c": round(max(temps_min), 1) if temps_min else None,
        "temp_min_low_c": round(min(temps_min), 1) if temps_min else None,
        "temp_min_avg_c": round(sum(temps_min) / len(temps_min), 1) if temps_min else None,
        "temp_mean_avg_c": round(sum(temps_mean) / len(temps_mean), 1) if temps_mean else None,
        # Precipitation (mm)
        "precipitation_total_mm": round(sum(precip), 1) if precip else 0,
        "precipitation_days": len([p for p in precip if p > 0]),
        "precipitation_max_day_mm": round(max(precip), 1) if precip else 0,
        # Wind (km/h)
        "wind_max_kmh": round(max(wind), 1) if wind else None,
        "wind_avg_max_kmh": round(sum(wind) / len(wind), 1) if wind else None,
        # Humidity (%)
        "humidity_avg_pct": round(sum(humidity) / len(humidity), 1) if humidity else None,
        # Metadata
        "data_source": "Open-Meteo Archive API",
        "refresh_timestamp": datetime.now().isoformat()
    }


def validate_data(monthly_data: list) -> tuple:
    """
    Validate the collected data before saving.

    Returns:
        Tuple of (is_valid, error_messages)
    """
    errors = []

    if not monthly_data:
        errors.append("No data collected")
        return False, errors

    # Check for minimum city coverage
    cities_with_data = len([d for d in monthly_data if d.get("days_in_month", 0) > 0])
    if cities_with_data < 5:
        errors.append(f"Only {cities_with_data} cities have data, expected at least 5")

    # Check for data completeness
    for record in monthly_data:
        city = record.get("city", "Unknown")
        days = record.get("days_in_month", 0)
        if days < 28:
            errors.append(f"{city}: Only {days} days of data (expected 28-31)")
        if record.get("temp_mean_avg_c") is None:
            errors.append(f"{city}: Missing temperature data")

    return len(errors) == 0, errors


def main():
    """Main job execution function."""
    logger.info("=" * 60)
    logger.info("Climate Data Refresh Job - Starting")
    logger.info("=" * 60)

    # Calculate date range for previous month
    start_date, end_date = get_previous_month_dates()
    year_month = start_date[:7]  # YYYY-MM format

    logger.info(f"Processing month: {year_month}")
    logger.info(f"Date range: {start_date} to {end_date}")
    logger.info(f"Cities to process: {len(ARIZONA_CITIES)}")

    # Collect data for all cities
    monthly_data = []
    success_count = 0

    for city, (lat, lon) in ARIZONA_CITIES.items():
        raw_data = fetch_weather_data(city, lat, lon, start_date, end_date)

        if raw_data:
            monthly_stats = aggregate_to_monthly(city, raw_data, year_month)
            monthly_data.append(monthly_stats)
            success_count += 1
            logger.info(f"  {city}: Avg temp {monthly_stats['temp_mean_avg_c']}C, "
                       f"Precip {monthly_stats['precipitation_total_mm']}mm")
        else:
            logger.warning(f"  {city}: Failed to fetch data")

    logger.info(f"\nData collection complete: {success_count}/{len(ARIZONA_CITIES)} cities successful")

    # Validate data
    is_valid, errors = validate_data(monthly_data)

    if not is_valid:
        logger.error("Data validation failed:")
        for error in errors:
            logger.error(f"  - {error}")
        raise ValueError(f"Data validation failed with {len(errors)} errors")

    logger.info("Data validation passed")

    # In Databricks, this would save to a Delta table
    # For demo purposes, we'll print the results
    logger.info("\n" + "=" * 60)
    logger.info("Monthly Climate Summary")
    logger.info("=" * 60)

    for record in sorted(monthly_data, key=lambda x: x.get("temp_mean_avg_c", 0) or 0, reverse=True):
        logger.info(f"{record['city']:12} | "
                   f"Avg: {record['temp_mean_avg_c']:5}C | "
                   f"Max: {record['temp_max_high_c']:5}C | "
                   f"Min: {record['temp_min_low_c']:5}C | "
                   f"Precip: {record['precipitation_total_mm']:5}mm")

    # Return data for Databricks Delta table write
    # In production, you would use:
    # spark.createDataFrame(monthly_data).write.mode("append").saveAsTable("climate.monthly_arizona")

    logger.info("\n" + "=" * 60)
    logger.info(f"Job completed successfully - {len(monthly_data)} records ready for Delta table")
    logger.info("=" * 60)

    return monthly_data


# Databricks notebook entry point
if __name__ == "__main__":
    results = main()

    # If running in Databricks, convert to DataFrame and save
    try:
        from pyspark.sql import SparkSession
        spark = SparkSession.builder.getOrCreate()

        df = spark.createDataFrame(results)

        # Create or append to Delta table
        df.write \
            .mode("append") \
            .option("mergeSchema", "true") \
            .saveAsTable("climate_demo.monthly_arizona_weather")

        print(f"Successfully saved {df.count()} records to climate_demo.monthly_arizona_weather")

    except ImportError:
        # Running outside Databricks (local testing)
        print("\nRunning in local mode - data not saved to Delta table")
        print(f"Results: {json.dumps(results, indent=2, default=str)}")
