# DI-1309: Migrate Databricks Jobs from Legacy VW_APPLICATION Views

## Objective
Migrate all assigned Databricks jobs from legacy application views to new standardized tables following the data architecture redesign.

## Background
- **Meeting Date**: October 2, 2025
- **Participants**: Steve Richardson, Tin Nguyen, Hongxia Shi
- **Ticket**: [DI-1309](https://happymoneyinc.atlassian.net/browse/DI-1309)

## Migration Overview

### Target Views (New Standard)
Replace legacy views with these standardized tables:
- `ANALYTICS.VW_APP_LOAN_PRODUCTION` - Replaces `VW_APPLICATION`
- `ANALYTICS.VW_APP_STATUS_TRANSITION` - Replaces `VW_APPLICATION_STATUS_TRANSITION` (has all 46 statuses)
- `ANALYTICS_PII.VW_APP_PII` - Replaces `VW_APPLICATION_PII` and `VW_LEAD_PII` (single table with `IS_APP_YN` flag)
- `ANALYTICS_PII.VW_MEMBER_PII` - Unchanged (handles slowly changing dimensions for member addresses)

### Legacy Views to Remove
- `VW_APPLICATION`
- `VW_APPLICATION_STATUS_TRANSITION`
- `VW_APP_STATUS_HISTORY`
- `VW_APP_HISTORY`
- `VW_APPLICATION_PII`
- `VW_LEAD_PII`
- `DATA_STORE.VW_APPLICATION` (non-compliant schema)
- Other `VW_APPL_*` variants

## Jobs Assigned to Hongxia (6 Jobs)

### Migration Status

| # | Job Name | Legacy Views Found | Status |
|---|----------|-------------------|---------|
| 1 | BI-1451_Loss_Forecasting | `vw_application` (1x) | ✅ Complete (PR #2003) |
| 2 | BI-2421_Prescreen_Marketing_Data | `VW_APPLICATION`, `vw_application_pii` | ✅ Complete (PR #2013) |
| 3 | DI-497_CRB_Fortress_Reporting | `VW_APPLICATION` | ✅ Complete (PR #2004) |
| 4 | DI-760_Weekly_Data_Feeds_for_Datalab_IWCO | `vw_application` (multiple), `vw_lead_pii` (multiple) | ⏳ Pending |
| 5 | DI-977_Prescreen_Email_List | `vw_application`, `vw_application_pii` | ✅ Complete (Merged) |
| 6 | DI-986_Outbound_List_Generation_for_Funnel | `VW_APPLICATION` (multiple), `VW_APPLICATION_PII`, `VW_LEAD_PII` | ✅ Complete (Merged - Oct 9, 2025) |

### Job Details

#### 1. BI-1451_Loss_Forecasting
- **File**: `BI-1451_Loss_Forecasting.py`
- **Legacy Views**: `analytics.vw_application` (1 occurrence at line 693)
- **Complexity**: Low (single occurrence)

#### 2. BI-2421_Prescreen_Marketing_Data
- **File**: `01_DM_Forecast.py`
- **Legacy Views**: `analytics.VW_APPLICATION`, `analytics_pii.vw_application_pii`
- **Complexity**: Medium

#### 3. DI-497_CRB_Fortress_Reporting
- **File**: `02_Originations_Monitoring_Report_Data_for_CRB_Fortress.ipynb`
- **Legacy Views**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION`
- **Complexity**: Low-Medium

#### 4. DI-760_Weekly_Data_Feeds_for_Datalab_IWCO
- **File**: `DI-760_Weekly_Data_Feeds_for_Datalab_IWCO.py`
- **Legacy Views**:
  - `data_store.vw_application`
  - `analytics.vw_application` (multiple)
  - `analytics_pii.vw_lead_pii` (multiple)
- **Complexity**: High (multiple occurrences, mixed schemas)
- **Note**: Uses both DATA_STORE (non-compliant) and ANALYTICS schemas

#### 5. DI-977_Prescreen_Email_List
- **File**: `DI-977_Prescreen_Email_List.ipynb`
- **Legacy Views**: `analytics.vw_application`, `analytics_pii.vw_application_pii`
- **Complexity**: Medium

#### 6. DI-986_Outbound_List_Generation_for_Funnel
- **File**: `DI-986_Outbound_List_Generation_for_Funnel.ipynb`
- **Legacy Views**:
  - `ANALYTICS.VW_APPLICATION` (lines 332, 421, 2565)
  - `analytics_pii.vw_application_pii` (lines 423, 2570)
  - `ANALYTICS_PII.VW_LEAD_PII` (lines 2482, 2670, 2777)
- **Partial Migration Done**:
  - Some sections already use `VW_APP_LOAN_PRODUCTION` (lines 1314, 1354, 1394)
  - Contact rules refactored in DI-1293 (Sept 2025)
- **Complexity**: High (large notebook, partial migration)

## Migration Approach

### For Each Job:
1. **Analyze**: Review current SQL queries and identify all legacy view usage
2. **Document**: Note any fields used that may not exist in new views
3. **Replace**: Swap legacy views with new standard views
4. **Test**: Validate data integrity and query results
5. **Deploy**: Test in dev environment before production

### Special Considerations:
- **CLS Data**: Document if needed; Steve will add bare-bones CLS union to new tables
- **Missing Fields**: Document any fields not found in new views; Steve will add them
- **External Dependencies**: Jobs with external data feeds (e.g., DI-760) need extra validation
- **Schema Compliance**: Migrate DATA_STORE schema references to ANALYTICS schema

## Migration Steps

### Step 1: Field Mapping
For each job, create a mapping of:
- Legacy view fields → New view fields
- Any fields not available in new views (document for Steve)

### Step 2: Query Updates
- Replace `VW_APPLICATION` → `VW_APP_LOAN_PRODUCTION`
- Replace `VW_APPLICATION_PII` → `VW_APP_PII`
- Replace `VW_LEAD_PII` → `VW_APP_PII` (filter with `IS_APP_YN` if needed)
- Replace `VW_APPLICATION_STATUS_TRANSITION` → `VW_APP_STATUS_TRANSITION`

### Step 3: Testing
- Compare row counts before/after migration
- Validate key metrics and aggregations
- Check for NULL values in critical fields
- Test in dev environment first

### Step 4: Documentation
- Update job README files
- Document any schema changes
- Note any behavioral differences

## Resources

### Reference Documentation
- **Google Sheet**: Job inventory created by Claude (shared by Tin)
- **Meeting Notes**: `/Users/hshi/WOW/Zoom/2025-10-02 10.04.26 Zoom Meeting/meeting_saved_closed_caption.txt`
- **Source PDF**: `/Users/hshi/WOW/drive-tickets/DI-1309_VW_APP_Migration/vw_appl sources (Claude) Databricks Only.pdf`

### Key Contacts
- **Steve Richardson**: Architecture questions, missing fields
- **Tin Nguyen**: Overall coordination, Snowflake lineage checks
- **Kyle Chalmers**: Migration support

## Notes
- Some jobs (Kyle's, Tin's) also need migration - coordinate to avoid conflicts
- Snowflake lineage check needed after Databricks migration
- CLS is deprecated - minimal effort on CLS data support
- VW_MEMBER_PII remains unchanged (slowly changing dimension for addresses)

## Progress Tracking
- [x] BI-1451_Loss_Forecasting (PR #2003 - Oct 2, 2025)
- [x] BI-2421_Prescreen_Marketing_Data (PR #2013 - Oct 9, 2025)
- [x] DI-497_CRB_Fortress_Reporting (PR #2004 - Oct 3, 2025)
- [ ] DI-760_Weekly_Data_Feeds_for_Datalab_IWCO
- [x] DI-977_Prescreen_Email_List (Merged - Oct 9, 2025)
- [x] DI-986_Outbound_List_Generation_for_Funnel (Merged - Oct 9, 2025)

**Progress**: 5/6 jobs complete (83%)

---

*Last Updated: October 9, 2025*
