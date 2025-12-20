# Sample Data for AWS S3/Athena Demo

This guide covers quality public datasets for demonstrating S3 and Athena capabilities.

---

## Option 1: California Wildfire Projections (Selected for Demo)

**Best for:** Climate/environmental analytics, real-world scientific data, unique storytelling angle.

This is a publicly available dataset from the AWS Data Exchange providing wildfire projections for California's climate resilience planning.

### Dataset Details

| Attribute | Value |
|-----------|-------|
| **S3 Location** | `s3://wfclimres/` |
| **Region** | us-west-2 |
| **Format** | NetCDF, Zarr (climate data formats) |
| **Provider** | Cal-Adapt / Eagle Rock Analytics |
| **Use Cases** | Climate analysis, risk assessment, renewable energy planning |

### What's Included

- **Wildfire projections** for California and surrounding regions
- **Historical weather observations**
- **Renewable energy capacity profiles** for electrical grid operations
- **Climate model outputs** supporting California's Fifth Climate Assessment

### Quick Start

```bash
# Set region for this dataset
export AWS_DEFAULT_REGION=us-west-2

# List top-level contents
aws s3 ls s3://wfclimres/

# Explore structure
aws s3 ls s3://wfclimres/ --recursive | head -50

# Copy sample data to your bucket
aws s3 sync s3://wfclimres/sample-folder/ s3://your-bucket/wildfire-data/ --dryrun
```

### Data Access Methods

1. **AWS CLI** (demonstrated in this video)
2. **Cal-Adapt Analytics Engine**: https://analytics.cal-adapt.org/data/access/
3. **Direct S3 via Python/Xarray** for scientific analysis

### Example Analysis Ideas

- Wildfire risk trends by region over time
- Correlation between weather patterns and fire activity
- Renewable energy capacity planning under climate scenarios
- Regional comparison of projected fire intensity

### Resources

- [AWS Marketplace Listing](https://aws.amazon.com/marketplace/pp/prodview-ynmdoogdmotne?sr=0-20&ref_=beagle&applicationId=AWSMPContessa#resources)
- [AWS Open Data Registry (GitHub)](https://github.com/awslabs/open-data-registry/blob/main/datasets/caladapt-wildfire-dataset.yaml)
- [Cal-Adapt Analytics Engine](https://analytics.cal-adapt.org/)
- [Cal-Adapt Data Access Portal](https://analytics.cal-adapt.org/data/access/)
- Contact: analytics@cal-adapt.org

---

## Option 2: NYC Taxi Data (Alternative)

**Best for:** Large-scale analytics, showing Athena performance on familiar data.

The NYC Taxi dataset is a classic public dataset already hosted on AWS S3.

### Dataset Details

| Attribute | Value |
|-----------|-------|
| **S3 Location** | `s3://nyc-tlc/trip data/` |
| **Region** | us-east-1 |
| **Format** | Parquet (newer), CSV (older) |
| **Size** | 1+ billion rows (full dataset) |
| **Time Range** | 2009-present |

### Quick Start

```bash
# List available data
aws s3 ls "s3://nyc-tlc/trip data/" --region us-east-1

# Copy a sample month to your bucket
aws s3 cp "s3://nyc-tlc/trip data/yellow_tripdata_2023-01.parquet" \
  s3://your-bucket/nyc-taxi/yellow_tripdata_2023-01.parquet
```

### Create Athena Table

```sql
CREATE EXTERNAL TABLE nyc_taxi_trips (
  VendorID INT,
  tpep_pickup_datetime TIMESTAMP,
  tpep_dropoff_datetime TIMESTAMP,
  passenger_count DOUBLE,
  trip_distance DOUBLE,
  RatecodeID DOUBLE,
  store_and_fwd_flag STRING,
  PULocationID INT,
  DOLocationID INT,
  payment_type INT,
  fare_amount DOUBLE,
  extra DOUBLE,
  mta_tax DOUBLE,
  tip_amount DOUBLE,
  tolls_amount DOUBLE,
  improvement_surcharge DOUBLE,
  total_amount DOUBLE,
  congestion_surcharge DOUBLE,
  airport_fee DOUBLE
)
STORED AS PARQUET
LOCATION 's3://your-bucket/nyc-taxi/'
```

### Example Queries

```sql
-- Average trip distance and fare by hour
SELECT
  HOUR(tpep_pickup_datetime) as pickup_hour,
  COUNT(*) as trip_count,
  ROUND(AVG(trip_distance), 2) as avg_distance,
  ROUND(AVG(total_amount), 2) as avg_fare
FROM nyc_taxi_trips
GROUP BY HOUR(tpep_pickup_datetime)
ORDER BY pickup_hour;

-- Top pickup locations
SELECT
  PULocationID,
  COUNT(*) as trips,
  ROUND(SUM(total_amount), 2) as total_revenue
FROM nyc_taxi_trips
GROUP BY PULocationID
ORDER BY trips DESC
LIMIT 10;
```

### Resources

- [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- [AWS Registry Entry](https://registry.opendata.aws/nyc-tlc-trip-records-pds/)

---

## Option 3: Kaggle E-Commerce/Retail Datasets

**Best for:** Business-focused demos with customer, product, and sales analysis.

### Top Recommendations

| Dataset | Size | Use Case |
|---------|------|----------|
| [E-Commerce Data](https://www.kaggle.com/datasets/carrie1/ecommerce-data) | 541K rows | Transaction analysis |
| [Online Retail Dataset](https://www.kaggle.com/datasets/lakshmi25npathi/online-retail-dataset) | 1M+ rows | Customer behavior |
| [Sample Sales Data](https://www.kaggle.com/datasets/kyanyoga/sample-sales-data) | 2.8K rows | Quick demos |

### Download and Upload Process

1. Create Kaggle Account (free): https://www.kaggle.com/
2. Download dataset as CSV
3. Upload to your S3 bucket:
   ```bash
   aws s3 cp ecommerce-data.csv s3://your-bucket/ecommerce/
   ```

---

## Option 4: NOAA Weather Data

**Best for:** Time-series analysis, environmental data complement to wildfire dataset.

| Attribute | Value |
|-----------|-------|
| **S3 Location** | `s3://noaa-gsod-pds/` |
| **Format** | CSV |
| **Coverage** | Global weather stations since 1929 |

```bash
# List years available
aws s3 ls s3://noaa-gsod-pds/

# Copy recent data
aws s3 sync s3://noaa-gsod-pds/2023/ s3://your-bucket/weather/2023/
```

---

## Demo Strategy

### Primary Dataset: Wildfire Projections

**Why this works well:**
- Unique angle (not the typical "taxi data" demo everyone uses)
- Real-world relevance (climate change, infrastructure planning)
- Already on AWS (no download/upload needed for initial exploration)
- Interesting story to tell

**Demo flow:**
1. Explore the S3 bucket structure
2. Copy relevant data to your own bucket
3. Create Athena table
4. Run climate analysis queries
5. Show Claude Code helping with data discovery and SQL generation

### Backup: NYC Taxi

If wildfire data format is challenging (NetCDF/Zarr requires special handling), fall back to NYC Taxi which is straightforward Parquet.

---

## Data Preparation Checklist

- [x] Identify dataset for demo (Wildfire Projections)
- [ ] Create S3 bucket in us-west-2
- [ ] Explore wildfire dataset structure
- [ ] Copy sample data to your bucket
- [ ] Create Athena database
- [ ] Create external table(s)
- [ ] Run test queries
- [ ] Prepare analysis queries for video
