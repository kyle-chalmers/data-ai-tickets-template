# SQL Query Explanation: Journey Analysis

## Main Query: Comprehensive Drop-off Analysis

Here's the step-by-step breakdown of the comprehensive query that joins drop-off applications with FullStory journey data:

```sql
WITH dropoff_apps AS (
  SELECT 
    CAST(app_id AS STRING) as app_id,
    funnel_type,
    app_dt,
    DATE_TRUNC('month', app_dt) as month_year,
    DATE_TRUNC('week', app_dt) as week_year,
    utm_source,
    app_status,
    CASE WHEN funnel_type = 'API' THEN affiliate_landed_ts ELSE app_ts END as started_ts,
    automated_fraud_decline_yn,
    manual_fraud_decline_yn
  FROM business_intelligence.analytics.vw_app_loan_production
  WHERE app_dt >= '2025-01-01' 
    AND app_dt <= '2025-08-05'
    AND applied_ts IS NULL
    AND ((funnel_type = 'API' AND affiliate_landed_ts IS NOT NULL) 
         OR funnel_type = 'Non-API')
),
```

### Step 1: Identify Drop-off Applications (`dropoff_apps` CTE)

**Purpose**: Find all applications that started but never completed in 2025

**Key Logic**:
- `CAST(app_id AS STRING)` - Ensures app_id is string format to match FullStory data
- `applied_ts IS NULL` - Core filter: applications that never reached "applied" status
- **API Condition**: `funnel_type = 'API' AND affiliate_landed_ts IS NOT NULL`
  - Must have landed from affiliate but never applied
- **Non-API Condition**: `funnel_type = 'Non-API'`
  - Any Non-API application that didn't apply
- **Time Aggregation**: Creates month_year and week_year for trending analysis

---

```sql
last_page_visited AS (
  SELECT 
    evt_application_id_str as app_id,
    CASE 
      WHEN page_path_str LIKE '/apply/api-aff-app-summary/%' THEN '/apply/api-aff-app-summary/*'
      WHEN page_path_str LIKE '/apply/route/application/%' THEN '/apply/route/application/*'
      WHEN page_path_str LIKE '/apply/application/%' THEN '/apply/application/*'
      WHEN page_path_str LIKE '/apply/%' THEN REGEXP_REPLACE(page_path_str, '/[0-9]+', '/*')
      WHEN page_path_str LIKE '/member/%' THEN REGEXP_REPLACE(page_path_str, '/[0-9]+', '/*')
      ELSE page_path_str
    END as normalized_page_path,
    page_path_str as raw_page_path,
    event_start,
    ROW_NUMBER() OVER (PARTITION BY evt_application_id_str ORDER BY event_start DESC) as rn
  FROM fivetran.fullstory.segment_event
  WHERE event_custom_name = 'Loaded a Page'
    AND evt_application_id_str IS NOT NULL
    AND evt_application_id_str <> ''
    AND event_start >= '2025-01-01'
)
```

### Step 2: Find Last Page Visited (`last_page_visited` CTE)

**Purpose**: Identify the last page each user visited before abandoning their application

**Key Logic**:

1. **Page Path Normalization**:
   - Raw paths like `/apply/api-aff-app-summary/12345` become `/apply/api-aff-app-summary/*`
   - This groups similar pages together for pattern analysis
   - `REGEXP_REPLACE(page_path_str, '/[0-9]+', '/*')` removes app IDs from paths

2. **Last Page Detection**:
   - `ROW_NUMBER() OVER (PARTITION BY evt_application_id_str ORDER BY event_start DESC)` 
   - Ranks all pages by visit time (newest first)
   - `rn = 1` will be the last page visited

3. **Data Quality Filters**:
   - `event_custom_name = 'Loaded a Page'` - Only page load events
   - Excludes null/empty application IDs

---

```sql
SELECT 
  d.funnel_type,
  d.app_id,
  d.app_dt,
  d.month_year,
  d.week_year,
  d.utm_source,
  d.app_status,
  d.automated_fraud_decline_yn,
  d.manual_fraud_decline_yn,
  l.normalized_page_path as last_page_visited,
  l.raw_page_path as last_page_raw,
  l.event_start as last_visit_time,
  CASE WHEN l.app_id IS NOT NULL THEN 1 ELSE 0 END as has_fullstory_data
FROM dropoff_apps d
LEFT JOIN last_page_visited l ON d.app_id = l.app_id AND l.rn = 1
ORDER BY d.app_dt DESC, d.funnel_type
```

### Step 3: Final Join and Output

**Purpose**: Combine drop-off applications with their last page visited

**Key Logic**:

1. **LEFT JOIN Logic**:
   - Keeps ALL drop-off applications, even without FullStory data
   - `l.rn = 1` ensures we only get the LAST page visited per application

2. **Coverage Indicator**:
   - `has_fullstory_data` flag shows which applications have journey data
   - Critical for understanding data completeness

3. **Complete Attribution**:
   - Application details (funnel_type, status, fraud flags)
   - Journey details (last page, visit time)
   - Time dimensions (daily, weekly, monthly grouping)

---

## Why This Approach Works

### 1. **Data Integrity**
- LEFT JOIN preserves all drop-offs for complete coverage analysis
- String casting ensures proper matching between datasets

### 2. **Journey Intelligence** 
- Page normalization reveals common abandonment patterns
- Last page focus identifies final friction points

### 3. **Multi-dimensional Analysis**
- Channel comparison (API vs Non-API)
- Time-series analysis (daily/weekly/monthly)
- Behavioral segmentation (fraud vs non-fraud)

### 4. **Scalable Pattern Detection**
- Normalized paths enable aggregate analysis
- Window functions efficiently find last interactions
- Coverage metrics guide data interpretation

---

## Example Results Interpretation

```
FUNNEL_TYPE | LAST_PAGE_VISITED              | COUNT
API         | /apply/api-aff-app-summary/*   | 245
API         | /apply/route/application/*     | 189  
Non-API     | /apply/loan-details/*          | 1,067
Non-API     | /apply/personal-information/*  | 892
```

This tells us:
- **API users** commonly abandon at affiliate summary page
- **Non-API users** abandon deeper in the flow (loan details, personal info)
- **Different intervention strategies** needed per channel

The query design enables both high-level trending and granular journey analysis.