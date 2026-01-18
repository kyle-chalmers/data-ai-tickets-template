# Sample Data for AWS S3/Athena Demo

This guide covers the datasets used in the video demonstration.

---

## Demo Strategy

The video uses two datasets:
1. **Wildfire Projections** - For exploring a real data lake structure
2. **Sample Sales CSV** - For the end-to-end workflow demonstration

---

## Dataset 1: California Wildfire Projections (Exploration)

**Best for:** Showing real-world data lake exploration, demonstrating S3 structure navigation.

This is a publicly available dataset from the AWS Data Exchange providing climate projections for California.

### Dataset Details

| Attribute | Value |
|-----------|-------|
| **S3 Location** | `s3://wfclimres/` |
| **Region** | us-west-2 |
| **Format** | NetCDF, Zarr (climate data formats) |
| **Provider** | Cal-Adapt / Eagle Rock Analytics |
| **Use Cases** | Climate analysis, renewable energy planning |

### What's Included

- **Wildfire projections** for California and surrounding regions
- **Renewable energy capacity profiles** for electrical grid operations
- **Climate model outputs** supporting California's Fifth Climate Assessment

### Our Setup

We extracted the renewable energy catalog to a queryable table:

| Resource | Value |
|----------|-------|
| **Demo Bucket** | `s3://kclabs-athena-demo-2025/wildfire-data/` |
| **Database** | `wildfire_demo` |
| **Table** | `renewable_energy_catalog` (216 rows) |

### Table Schema

| Column | Description |
|--------|-------------|
| `installation` | Energy type (pv_distributed, pv_utility, wind) |
| `source_id` | Climate model used |
| `experiment_id` | Scenario (historical, reanalysis, ssp370) |
| `table_id` | Time resolution (1hr, day) |
| `variable_id` | Metric (cf = capacity factor, gen = generation) |
| `path` | S3 location of the actual data files |

### Quick Start

```bash
# Set region for this dataset
export AWS_DEFAULT_REGION=us-west-2

# List public bucket contents
aws s3 ls s3://wfclimres/

# Query our demo table
aws athena start-query-execution \
  --query-string "SELECT * FROM wildfire_demo.renewable_energy_catalog LIMIT 10" \
  --query-execution-context Database=wildfire_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```

### Resources

- [AWS Open Data Registry (GitHub)](https://github.com/awslabs/open-data-registry/blob/main/datasets/caladapt-wildfire-dataset.yaml)
- [Cal-Adapt Analytics Engine](https://analytics.cal-adapt.org/)
- [Cal-Adapt Data Access Portal](https://analytics.cal-adapt.org/data/access/)

---

## Dataset 2: Sample Sales CSV (Workflow Demo)

**Best for:** End-to-end workflow demonstration (CSV -> S3 -> Athena -> Query -> Export).

A simple 10-row CSV for demonstrating the complete workflow without complexity.

### Sample Data

```csv
order_id,customer_id,product_name,quantity,unit_price,order_date,region
1001,C001,Widget A,5,29.99,2024-01-15,North
1002,C002,Widget B,3,49.99,2024-01-16,South
1003,C001,Widget C,2,99.99,2024-01-17,North
1004,C003,Widget A,10,29.99,2024-01-18,East
1005,C002,Widget B,1,49.99,2024-01-19,West
1006,C004,Widget C,4,99.99,2024-01-20,South
1007,C001,Widget A,7,29.99,2024-01-21,North
1008,C005,Widget B,2,49.99,2024-01-22,East
1009,C003,Widget C,1,99.99,2024-01-23,West
1010,C004,Widget A,3,29.99,2024-01-24,South
```

### Workflow Resources

| Resource | Value |
|----------|-------|
| **S3 Location** | `s3://kclabs-athena-demo-2025/sales-demo/` |
| **Database** | `sales_demo` |
| **Table** | `sales` |

### Create Table DDL

```sql
CREATE DATABASE IF NOT EXISTS sales_demo;

CREATE EXTERNAL TABLE sales_demo.sales (
  order_id INT,
  customer_id STRING,
  product_name STRING,
  quantity INT,
  unit_price DOUBLE,
  order_date DATE,
  region STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2025/sales-demo/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

### Sample Analysis Query

```sql
SELECT
  region,
  COUNT(*) as order_count,
  SUM(quantity) as total_units,
  ROUND(SUM(quantity * unit_price), 2) as total_revenue
FROM sales_demo.sales
GROUP BY region
ORDER BY total_revenue DESC;
```

---

## Alternative Datasets (Not Used in Video)

### NYC Taxi Data
- **S3 Location:** `s3://nyc-tlc/trip data/` (us-east-1)
- **Format:** Parquet
- **Size:** 1+ billion rows
- **Best for:** Large-scale analytics demos

### NOAA Weather Data
- **S3 Location:** `s3://noaa-gsod-pds/`
- **Format:** CSV
- **Coverage:** Global weather stations since 1929
- **Best for:** Time-series analysis

---

## Current Setup Summary

**Buckets:**
- `s3://kclabs-athena-demo-2025/wildfire-data/` - Wildfire catalog CSV
- `s3://kclabs-athena-demo-2025/sales-demo/` - Sales workflow data
- `s3://kclabs-athena-results-2025/` - Athena query results

**Athena Databases:**
- `wildfire_demo` - Climate data exploration
- `sales_demo` - Workflow demonstration

**Quick Test:**
```bash
# Test wildfire data
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) as row_count FROM wildfire_demo.renewable_energy_catalog" \
  --query-execution-context Database=wildfire_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```
