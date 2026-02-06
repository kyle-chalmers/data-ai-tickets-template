# Databricks notebook source
# MAGIC %md
# MAGIC One-time setup: create climate_demo_cursor catalog and default schema so the climate job can write to climate_demo_cursor.default.arizona_weather_monthly.

# COMMAND ----------

# CREATE CATALOG uses metastore default storage when no MANAGED LOCATION is given.
spark.sql("CREATE CATALOG IF NOT EXISTS climate_demo_cursor COMMENT 'Cursor demo catalog for Arizona climate data'")

# COMMAND ----------

spark.sql("CREATE SCHEMA IF NOT EXISTS climate_demo_cursor.default")

# COMMAND ----------

# Verify
spark.sql("SHOW SCHEMAS IN climate_demo_cursor").show()
