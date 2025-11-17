# Databricks notebook source
# MAGIC %md
# MAGIC # Product Sales Analysis
# MAGIC
# MAGIC Analyze product sales performance and revenue patterns

# COMMAND ----------

# Import libraries
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, count, avg, round

# COMMAND ----------

# MAGIC %md
# MAGIC ## Load Data

# COMMAND ----------

# Read lineitem and part tables
# INTENTIONAL ERROR: This table does not exist!
df_lineitem = spark.table("samples.tpch.lineitem_nonexistent")
df_part = spark.table("samples.tpch.part")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Analysis

# COMMAND ----------

# Join and aggregate product sales
product_sales = (
    df_lineitem
    .join(df_part, df_lineitem.l_partkey == df_part.p_partkey)
    .groupBy("p_partkey", "p_name", "p_type", "p_brand")
    .agg(
        count("l_orderkey").alias("total_orders"),
        sum("l_quantity").alias("total_quantity"),
        sum("l_extendedprice").alias("total_revenue"),
        round(avg("l_extendedprice"), 2).alias("avg_sale_price")
    )
    .orderBy(col("total_revenue").desc())
)

# Display top 20 products by revenue
display(product_sales.limit(20))
