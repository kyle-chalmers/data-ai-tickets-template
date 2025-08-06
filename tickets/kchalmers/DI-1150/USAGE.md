# DI-1150: Usage Guide

## Quick Start

### 1. Run Complete Analysis
```bash
python analysis_script.py
```
This executes the comprehensive analysis and displays key insights.

### 2. Review Reports
- **API Channel**: `reports/API_Channel_Analysis.md`
- **Non-API Channel**: `reports/Non_API_Channel_Analysis.md`

### 3. Access Raw Data
All datasets are in `final_deliverables/data_extracts/`:
- `comprehensive_dropoff_analysis.csv` - Master dataset
- `fullstory_coverage_analysis.csv` - Coverage metrics
- `monthly_trending_analysis.csv` - Monthly patterns
- Plus 9 additional analysis files

### 4. Reproduce Analysis
Execute SQL queries in order from `sql_queries/` folder:
1. `1_drop_off_summary_stats.sql`
2. `2_api_dropoffs_extract.sql`  
3. `3_non_api_dropoffs_extract.sql`
4. `4_non_api_fraud_analysis.sql`
5. `5_fullstory_journey_analysis.sql`

### 5. Technical Documentation
- `documentation/SQL_Query_Guide.md` - Step-by-step SQL explanations
- `documentation/Technical_Methodology.md` - Analysis approach

## Key Findings Summary

**API Channel (3,652 drop-offs):**
- 8.1% FullStory coverage → tracking investigation needed
- 84.4% abandon at "Affiliate Landed" → partner optimization required

**Non-API Channel (38,297 drop-offs):**
- 44.8% FullStory coverage → actionable insights available
- April-July 2025: 70-82% coverage → optimization window
- Top abandonment: `/apply/loan-details/*` (1,067+ events)

## Immediate Actions
1. A/B test Non-API loan details page
2. Audit API partner landing pages  
3. Investigate API FullStory tracking gaps
4. Review 9,371 fraud-flagged applications