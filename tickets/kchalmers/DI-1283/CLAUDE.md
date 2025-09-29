# DI-1283: Investigation Approach and Resolution

## Ticket Summary
Dashboard showing no outbound outreach data after September 24, 2025 for the Goal Realignment Outbound Outreaches and Outcomes dashboard.

## Investigation Methodology

### 1. Initial Data Analysis
**Challenge:** The source view `VW_DSH_OUTBOUND_GENESYS_OUTREACHES` is notoriously slow and times out when queried directly.

**Approach:**
- Broke down the complex view into its 5 constituent CTEs
- Created modular validation queries for each CTE to isolate the failing component
- Checked data freshness for all upstream dependencies

**Key Finding:** Email monitoring data (`DSH_EMAIL_MONITORING_EVENTS`) stopped on Sept 24, 2025, while other data sources (phone, text, GR lists) continued flowing.

### 2. Databricks Job Investigation
**Tool Used:** Databricks CLI (`databricks` command with `biprod` profile)

**Commands:**
```bash
# Retrieved job run details
databricks jobs get-run 604748953895353 --profile biprod

# Retrieved job run output/error logs
databricks jobs get-run-output 138344791774066 --profile biprod
```

**Discovery:** The Databricks job `BI-2011_In_Funnel_Email_Monitoring` failed on Sept 24, 2025 with:
```
SQL compilation error:
Object 'BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY' does not exist or not authorized.
```

### 3. Root Cause Analysis
**Issue:** The Databricks notebook referenced an incorrect schema path:
- **Incorrect Reference:** `BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY`
- **Actual Location:** `BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_HISTORY` (created Sept 24, 2025)

**Impact Chain:**
```
Databricks BI-2011 Job (FAILED)
    ↓
DSH_EMAIL_MONITORING_EVENTS (No new data)
    ↓
VW_DSH_OUTBOUND_GENESYS_OUTREACHES (Empty results)
    ↓
Dashboard (No data visible)
```

### 4. Source Code Analysis
**Method:** Checked out the exact git commit that failed from the Databricks job metadata:
```bash
cd /Users/kchalmers/Development/business-intelligence-data-jobs
git checkout 3db484da4f2fc89b9ae0ac13804c368b4d4992dd
```

**Located Failing Line:** Line 389 in `jobs/BI-2011_In_Funnel_Email_Monitoring/BI-2011_In_Funnel_Email_Monitoring.py`

## Resolution

### Fix Applied
**File:** `business-intelligence-data-jobs/jobs/BI-2011_In_Funnel_Email_Monitoring/BI-2011_In_Funnel_Email_Monitoring.py`

**Change:**
```python
# Line 389 - BEFORE (incorrect schema)
left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY hist

# Line 389 - AFTER (correct schema)
left join BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_APPL_HISTORY hist
```

### Verification Process
1. User applied fix to Databricks notebook
2. Ran Databricks job successfully on Sept 29, 2025
3. Verified data pipeline restoration:
   ```sql
   SELECT MAX(EVENT_DATE), COUNT(*)
   FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS
   ```
   - Result: Data now through Sept 29, 2025 (152.6M total events)

4. Validated daily event counts for recovery period (Sept 24-29)

## Key Learnings

### Debugging Slow/Complex Views
When investigating views that timeout:
1. **Decompose into CTEs** - Break down complex views into component parts
2. **Test independently** - Query each CTE separately to isolate issues
3. **Check upstream dependencies** - Verify all source tables have current data

### Databricks Job Debugging
The Databricks CLI is essential for investigating job failures:
- `databricks jobs get-run <run_id>` - Get job metadata and status
- `databricks jobs get-run-output <task_run_id>` - Get detailed error messages
- Job metadata includes the git commit hash used - crucial for reproducing the issue

### Schema Migration Impact
When views are moved between schemas:
- Check all downstream consumers (Databricks jobs, other views, reports)
- The view might exist in the new location but old references will fail
- SQL compilation errors indicate the object path is wrong, not a permissions issue

## Tools and Techniques Used

1. **Snowflake CLI:** Data freshness checks and validation queries
2. **Databricks CLI:** Job failure investigation and log retrieval
3. **Git:** Checking out specific commits to examine failing code
4. **Modular SQL Analysis:** Breaking down complex views into testable components
5. **DataGrip Console Variables:** Created `SET` variable for `funnel_date_filter` to make SQL portable

## Files Organization

**Final Deliverables:**
- Corrected SQL with proper schema references

**Source Materials:**
- Original failing Databricks notebook for reference

**Exploratory Analysis:**
- 5 modular CTE validation queries used during investigation
- These remain useful for future debugging of this view

## Time Efficiency Notes

**Investigation Time:** ~30 minutes from ticket assignment to root cause identification
- Modular CTE approach avoided multiple timeout failures
- Databricks CLI provided immediate access to error logs
- Git commit hash from job metadata allowed exact code reproduction

**Resolution Time:** ~5 minutes to apply fix and verify
- Single line schema change
- Immediate verification via data freshness checks