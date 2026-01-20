# Demo Scripts - Quick Reference

Copy-paste commands for live demo execution.

---

## Pre-Demo Verification

```bash
# Snowflake
snow connection list
snow sql -q "SELECT 1" --format csv

# AWS
aws sts get-caller-identity
aws s3 ls s3://kclabs-athena-demo-2026/climate-data/

# Repository
git checkout main && git pull
```

---

## Demo 1: Snowflake Analysis

### Prompt for Claude
```
Analyze the top 10 customers by total order value from Snowflake sample TPCH data. Include nation, total orders, and average order value.
```

### Reference Query (if needed manually)
```sql
SELECT
    c.c_name as customer_name,
    n.n_name as nation,
    COUNT(DISTINCT o.o_orderkey) as total_orders,
    SUM(o.o_totalprice) as total_order_value,
    ROUND(AVG(o.o_totalprice), 2) as avg_order_value
FROM snowflake_sample_data.tpch_sf1.customer c
JOIN snowflake_sample_data.tpch_sf1.nation n ON c.c_nationkey = n.n_nationkey
JOIN snowflake_sample_data.tpch_sf1.orders o ON c.c_custkey = o.o_custkey
GROUP BY c.c_name, n.n_name
ORDER BY total_order_value DESC
LIMIT 10;
```

---

## Demo 2: AWS Climate Analysis

### Main Prompt
```
I have climate data in S3 at s3://kclabs-athena-demo-2026/climate-data/. IMF Global Surface Temperature dataset, 1961-2024.

I want to:
1. Verify data is in S3
2. Create an Athena table
3. Find top 10 countries with highest temperature change in 2024
4. Show US temperature trend from 1970 to 2024
5. Export results
```

### Follow-up Prompt
```
Show me how US temperature change evolved from 1970 to 2024.
```

### Reference Commands (if needed manually)

**S3 Check:**
```bash
aws s3 ls s3://kclabs-athena-demo-2026/climate-data/ --human-readable
```

**Create Database:**
```bash
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS climate_demo" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2026/
```

**Create Table:**
```bash
aws athena start-query-execution \
  --query-string "
CREATE EXTERNAL TABLE IF NOT EXISTS climate_demo.global_temperature (
    ObjectId INT, Country STRING, ISO2 STRING, ISO3 STRING,
    Indicator STRING, Unit STRING, Source STRING,
    CTS_Code STRING, CTS_Name STRING, CTS_Full_Descriptor STRING,
    Y1961 DOUBLE, Y1962 DOUBLE, Y1963 DOUBLE, Y1964 DOUBLE, Y1965 DOUBLE,
    Y1966 DOUBLE, Y1967 DOUBLE, Y1968 DOUBLE, Y1969 DOUBLE, Y1970 DOUBLE,
    Y1971 DOUBLE, Y1972 DOUBLE, Y1973 DOUBLE, Y1974 DOUBLE, Y1975 DOUBLE,
    Y1976 DOUBLE, Y1977 DOUBLE, Y1978 DOUBLE, Y1979 DOUBLE, Y1980 DOUBLE,
    Y1981 DOUBLE, Y1982 DOUBLE, Y1983 DOUBLE, Y1984 DOUBLE, Y1985 DOUBLE,
    Y1986 DOUBLE, Y1987 DOUBLE, Y1988 DOUBLE, Y1989 DOUBLE, Y1990 DOUBLE,
    Y1991 DOUBLE, Y1992 DOUBLE, Y1993 DOUBLE, Y1994 DOUBLE, Y1995 DOUBLE,
    Y1996 DOUBLE, Y1997 DOUBLE, Y1998 DOUBLE, Y1999 DOUBLE, Y2000 DOUBLE,
    Y2001 DOUBLE, Y2002 DOUBLE, Y2003 DOUBLE, Y2004 DOUBLE, Y2005 DOUBLE,
    Y2006 DOUBLE, Y2007 DOUBLE, Y2008 DOUBLE, Y2009 DOUBLE, Y2010 DOUBLE,
    Y2011 DOUBLE, Y2012 DOUBLE, Y2013 DOUBLE, Y2014 DOUBLE, Y2015 DOUBLE,
    Y2016 DOUBLE, Y2017 DOUBLE, Y2018 DOUBLE, Y2019 DOUBLE, Y2020 DOUBLE,
    Y2021 DOUBLE, Y2022 DOUBLE, Y2023 DOUBLE, Y2024 DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2026/climate-data/'
TBLPROPERTIES ('skip.header.line.count'='1')
" \
  --work-group "primary" \
  --query-execution-context Database=climate_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2026/
```

**Top 10 Query:**
```bash
QUERY_ID=$(aws athena start-query-execution \
  --query-string "
SELECT Country, ISO3, Y2024 as temp_change_2024
FROM climate_demo.global_temperature
WHERE Y2024 IS NOT NULL AND ISO3 IS NOT NULL
ORDER BY Y2024 DESC LIMIT 10
" \
  --work-group "primary" \
  --query-execution-context Database=climate_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2026/ \
  --output text --query 'QueryExecutionId')
echo "Query ID: $QUERY_ID"
```

**Get Results:**
```bash
aws athena get-query-results --query-execution-id $QUERY_ID | \
  jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @tsv'
```

---

## Cleanup (After Demo)

```bash
# Return to main
git checkout main

# Delete demo branch
git branch -d [branch-name]

# Clean tickets folder
git clean -fd tickets/
```

---

## Troubleshooting

**Athena query stuck:**
```bash
aws athena stop-query-execution --query-execution-id $QUERY_ID
```

**Snowflake connection issues:**
```bash
snow connection test
```

**Claude not responding:**
```
/clear
```
