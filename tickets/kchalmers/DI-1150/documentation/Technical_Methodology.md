# SQL Queries - DI-1150 Application Drop-off Analysis

## Query Execution Order

Run these queries in sequence to reproduce the analysis:

### 1. Drop-off Summary Statistics
**File:** `1_drop_off_summary_stats.sql`
**Purpose:** Get overall drop-off rates by channel
**Output:** Summary statistics showing API (34.51%) vs Non-API (22.98%) drop-off rates

### 2. API Drop-offs Extract  
**File:** `2_api_dropoffs_extract.sql`
**Purpose:** Extract detailed API channel drop-off data
**Output:** `api_dropoffs.csv` (500 records sample)

### 3. Non-API Drop-offs Extract
**File:** `3_non_api_dropoffs_extract.sql` 
**Purpose:** Extract detailed Non-API channel drop-off data with fraud indicators
**Output:** `non_api_dropoffs.csv` (500 records sample)

### 4. Non-API Fraud Analysis
**File:** `4_non_api_fraud_analysis.sql`
**Purpose:** Analyze fraud rejection patterns in Non-API drop-offs
**Output:** `non_api_fraud_analysis.csv` showing 71.58% "Started", 24.36% "Fraud Rejected"

### 5. FullStory Journey Analysis
**File:** `5_fullstory_journey_analysis.sql`
**Purpose:** Attempt to join drop-off data with FullStory user journey data
**Output:** `common_page_patterns.csv` (limited data available)

## Key Findings from Queries

- **API Channel**: 34.51% drop-off rate, mostly at "Affiliate Landed" stage
- **Non-API Channel**: 22.98% drop-off rate, 71.58% are "Started" but incomplete
- **Fraud Impact**: 1,432 Non-API applications (24.36%) flagged as fraud rejections
- **FullStory**: Limited journey data available for comprehensive analysis

## Usage Notes

- All queries use date range: July 1-31, 2025
- LIMIT clauses applied for sample data extraction
- FullStory integration has limited coverage for drop-off applications
- Queries assume access to `business_intelligence.analytics.vw_app_loan_production` and `fivetran.fullstory.segment_event`