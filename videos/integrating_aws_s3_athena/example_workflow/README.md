# Example Workflow: Global Temperature Data Analysis

This workflow demonstrates an end-to-end data analysis using S3 and Athena.

Matches the Practical Workflow Demo in `final_deliverables/script_outline.md`.

---

## Scenario

You have global temperature data in CSV format that needs to be:
1. Uploaded to S3
2. Cataloged in Athena (creates table pointing to S3)
3. Queried for analysis
4. Results exported locally

---

## Prerequisites

- AWS CLI configured (see [setup guide](../instructions/AWS_CLI_SETUP.md))
- S3 buckets:
  - Data: `kclabs-athena-demo-2026`
  - Results: `kclabs-athena-results-2026`
- Region: `us-west-2`

---

## Step 1: Prepare Sample Data

Use the IMF Global Surface Temperature dataset:

```bash
# Use the local sample data
cp ../sample_data/global_surface_temperature.csv ./
```

**Sample Data Structure:**
```
ObjectId,Country,ISO2,ISO3,Indicator,Unit,Source,CTS Code,CTS Name,CTS Full Descriptor,1961,1962,...,2023,2024
1,Afghanistan,AF,AFG,Temperature change...,Degree Celsius,FAO,...,-0.096,-0.143,...,1.748,2.188
2,Africa,,AFRTMP,Temperature change...,Degree Celsius,FAO,...,-0.015,-0.033,...,1.485,1.75
```

**Data Source:**
- International Monetary Fund (IMF) Climate Change Indicators
- Original data: Food and Agriculture Organization of the United Nations (FAO)
- Content: Annual mean surface temperature change (degrees Celsius) vs 1951-1980 baseline

---

## Step 2: Upload to S3

```bash
# Upload file
aws s3 cp global_surface_temperature.csv s3://kclabs-athena-demo-2026/climate-data/global_surface_temperature.csv

# Verify upload
aws s3 ls s3://kclabs-athena-demo-2026/climate-data/
```

**Expected output:**
```
2026-01-19 10:30:00      123456 global_surface_temperature.csv
```

---

## Step 3: Create Athena Database and Table

### Create Database

Run in Athena Console or via CLI:

```sql
CREATE DATABASE IF NOT EXISTS climate_demo;
```

### Create External Table

```sql
CREATE EXTERNAL TABLE climate_demo.global_temperature (
    ObjectId INT,
    Country STRING,
    ISO2 STRING,
    ISO3 STRING,
    Indicator STRING,
    Unit STRING,
    Source STRING,
    CTS_Code STRING,
    CTS_Name STRING,
    CTS_Full_Descriptor STRING,
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
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2026/climate-data/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

> **Note:** The table is just metadata - a schema definition pointing to S3. Athena reads directly from the files. Table metadata is automatically stored in the AWS Glue Data Catalog.

### CLI Alternative

```bash
aws athena start-query-execution \
  --query-string "CREATE DATABASE IF NOT EXISTS climate_demo" \
  --work-group "primary" \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2026/
```

---

## Step 4: Run Analysis Queries

### Business Question: Which countries have the highest temperature change in 2024?

```sql
SELECT Country, ISO3, Y2024 as temp_change_2024
FROM climate_demo.global_temperature
WHERE Y2024 IS NOT NULL AND ISO3 IS NOT NULL
ORDER BY Y2024 DESC
LIMIT 10;
```

**Expected Results:**
```
Country              ISO3    temp_change_2024
Svalbard and Jan...  SJM     4.123
Russian Federation   RUS     3.456
Norway               NOR     3.234
...
```

### Additional Analysis Queries

```sql
-- Temperature trend for USA over decades
SELECT Country, Y1970, Y1980, Y1990, Y2000, Y2010, Y2020, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 = 'USA';

-- Compare recent years across major economies
SELECT Country, ISO3, Y2020, Y2021, Y2022, Y2023, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 IN ('USA', 'CHN', 'DEU', 'JPN', 'GBR', 'FRA')
ORDER BY Y2024 DESC;

-- Continental/regional averages (aggregates have TMP suffix in ISO3)
SELECT Country, Y2020, Y2021, Y2022, Y2023, Y2024
FROM climate_demo.global_temperature
WHERE ISO3 LIKE '%TMP'
ORDER BY Y2024 DESC;
```

### CLI Execution

```bash
# Start query
QUERY_ID=$(aws athena start-query-execution \
  --query-string "SELECT Country, ISO3, Y2024 as temp_change_2024 FROM climate_demo.global_temperature WHERE Y2024 IS NOT NULL AND ISO3 IS NOT NULL ORDER BY Y2024 DESC LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=climate_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2026/ \
  --output text --query 'QueryExecutionId')

echo "Query ID: $QUERY_ID"

# Wait for completion (poll status)
aws athena get-query-execution --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Status.State' --output text

# Get results
aws athena get-query-results --query-execution-id $QUERY_ID
```

---

## Step 5: Export Results

### Download Query Results

Every Athena query automatically saves results to S3. Download the CSV:

```bash
# Download results CSV (replace QUERY_ID)
aws s3 cp s3://kclabs-athena-results-2026/${QUERY_ID}.csv ./results.csv

# View results
cat results.csv
```

---

## Step 6: Cleanup

Clean up test resources:

```sql
DROP TABLE IF EXISTS climate_demo.global_temperature;
DROP DATABASE IF EXISTS climate_demo;
```

```bash
# Remove S3 data
aws s3 rm s3://kclabs-athena-demo-2026/climate-data/ --recursive

# Clean local files
rm -f global_surface_temperature.csv results.csv
```

**Important:** Tables are just pointers - the S3 data persists until you explicitly delete it.

---

## Claude Code Integration

Instead of running these commands manually, ask Claude:

**Data Upload:**
```
"Upload global_surface_temperature.csv to S3 in the climate-data folder"
```

**Table Creation:**
```
"Create an Athena table for the temperature CSV I just uploaded. It has columns for country, ISO codes, and year columns from 1961 to 2024"
```

**Analysis:**
```
"Query the temperature table to find the top 10 countries with the highest warming in 2024"
```

**Trend Analysis:**
```
"Show me how temperature change has evolved in the USA from 1970 to 2024"
```

**Export:**
```
"Export the query results to a local CSV file"
```

**Cleanup:**
```
"Clean up the climate_demo database and remove the S3 test data"
```

---

## Key Takeaways

1. **External Tables** - Athena tables are just metadata pointing to S3; no data copying
2. **Pay Per Query** - Cost is ~$5 per TB scanned (our demo: negligible)
3. **Results in S3** - Every query saves output to your results bucket
4. **Standard SQL** - Use familiar SQL syntax against files in S3
5. **No ETL Required** - Query data directly where it lives
6. **Wide Format Data** - This dataset has year columns (Y1961-Y2024) rather than rows per year
