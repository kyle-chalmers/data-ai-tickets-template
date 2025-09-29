# DI-1283: Investigate Missing Outbound Outreach Data in Genesys Dashboard Since Sept 24

## Ticket Information
- **Jira Link:** https://happymoneyinc.atlassian.net/browse/DI-1283
- **Type:** Dashboard
- **Status:** In Spec
- **Epic:** DI-1238 - Data Object Alteration
- **Assignee:** Kyle Chalmers

## Business Context

The Goal Realignment Outbound Outreaches and Outcomes dashboard is not showing any outreach data since September 24th, 2025. This impacts visibility into outbound communication efforts and outcomes tracking.

- **Dashboard:** [Goal Realignment Outbound Outreaches and Outcomes](https://10ay.online.tableau.com/#/site/happymoney/views/GoalRealignmentOutboundOutreachesandOutcomes/OutboundOutreachesandOutcomes?:iid=1)
- **Data Source:** `BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES`
- **Issue:** No outreaches visible after 9/24/2025

## Root Cause Analysis

### Primary Issue: Databricks Job Failure on September 24, 2025

The dashboard stopped showing data after Sept 24, 2025 because the upstream Databricks job **BI-2011_In_Funnel_Email_Monitoring** failed with a **SQL compilation error**.

**Databricks Job Details:**
- **Job ID:** 804582665441010
- **Failed Run ID:** 604748953895353
- **Run Date:** September 24, 2025 at 11:15 PM (1758815353289 epoch)
- **Failure Type:** INTERNAL_ERROR / SQL compilation error
- **Git Commit:** 3db484da4f2fc89b9ae0ac13804c368b4d4992dd

**Error Message:**
```
net.snowflake.client.jdbc.SnowflakeSQLException: SQL compilation error:
Object 'BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY' does not exist or not authorized.
```

### Technical Explanation

The Databricks notebook `jobs/BI-2011_In_Funnel_Email_Monitoring/BI-2011_In_Funnel_Email_Monitoring` attempts to query `BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY`, but this view **does not exist in the DATA_STORE schema**.

**Current State:**
- `VW_APPL_HISTORY` exists in `BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_HISTORY` (created 2025-09-24 15:34:07)
- The Databricks job references the incorrect schema path: `DATA_STORE.VW_APPL_HISTORY`
- This job populates `BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS`

### Data Flow Impact

```
Databricks BI-2011 Job (FAILED)
    ↓
DSH_EMAIL_MONITORING_EVENTS (No new data after Sept 24)
    ↓
VW_DSH_OUTBOUND_GENESYS_OUTREACHES (emails_sent CTE returns no data)
    ↓
Goal Realignment Outbound Outreaches Dashboard (Empty after Sept 24)
```

### Affected Data Components

**View Structure:** `VW_DSH_OUTBOUND_GENESYS_OUTREACHES` has 5 CTEs:
1. **dqs** - Delinquent population (✅ Working - uses MVW_LOAN_TAPE_DAILY_HISTORY)
2. **phone_calls** - Phone outreach metrics (✅ Working - uses GENESYS_OUTBOUND_LIST_EXPORTS)
3. **sent_texts** - SMS outreach metrics (✅ Working - uses GENESYS_OUTBOUND_LIST_EXPORTS)
4. **emails_sent** - Email metrics (❌ BROKEN - depends on DSH_EMAIL_MONITORING_EVENTS)
5. **gr_email_lists** - GR email lists (✅ Working - uses RPT_OUTBOUND_LISTS_HIST)

**Data Freshness Check:**
- `GENESYS_OUTBOUND_LIST_EXPORTS`: Latest data = 2025-09-29 ✅
- `DSH_EMAIL_MONITORING_EVENTS`: Latest data = 2025-09-24 ❌ (Stopped)
- `RPT_OUTBOUND_LISTS_HIST`: Continues to update ✅

### Solution Required

The Databricks notebook needs to be updated to reference the correct schema:
- **INCORRECT:** `BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY`
- **CORRECT:** `BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_HISTORY`

**Repository:** https://github.com/HappyMoneyInc/business-intelligence-data-jobs
**Notebook Path:** `jobs/BI-2011_In_Funnel_Email_Monitoring/BI-2011_In_Funnel_Email_Monitoring`
**Fix Required:** Update schema reference from DATA_STORE to ANALYTICS

## Assumptions Made

1. **View Migration:** VW_APPL_HISTORY was moved or recreated in the ANALYTICS schema on Sept 24, 2025, but the Databricks job was not updated to reflect this change
2. **No Permissions Issue:** The failure is due to incorrect schema path, not authorization issues
3. **Single Point of Failure:** Only the email metrics component is affected; phone and text outreach data continues to flow
4. **Dashboard Dependency:** The dashboard relies on ALL CTEs joining together, so even though 4/5 CTEs work, the view returns no results when emails_sent CTE is empty

## Resolution

### Issue #1: Email Data Pipeline (RESOLVED)
**Root Cause:** Databricks job failure due to incorrect schema reference

**Fix Applied:**
**File:** `business-intelligence-data-jobs/jobs/BI-2011_In_Funnel_Email_Monitoring/BI-2011_In_Funnel_Email_Monitoring.py`
**Line 389 Changed:**
- **Before:** `left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY hist`
- **After:** `left join BUSINESS_INTELLIGENCE.BRIDGE.VW_CLS_APPL_HISTORY hist`

**Verification:**
- ✅ Databricks job successfully ran on Sept 29, 2025
- ✅ DSH_EMAIL_MONITORING_EVENTS now has data through Sept 29, 2025
- ✅ Dashboard data pipeline restored
- ✅ Email event counts confirmed for Sept 24-29:
  - Sept 29: 4,816 events
  - Sept 28: 4,641 events
  - Sept 27: 5,270 events
  - Sept 26: 6,649 events
  - Sept 25: 7,252 events
  - Sept 24: 7,900 events

### Issue #2: Phone Call Activity Data (IN PROGRESS - Data Engineering)
**Root Cause:** Genesys phone call activity data pipeline stopped on September 17, 2025

**Data Analysis:**
- `GENESYS_OUTBOUND_LIST_EXPORTS` (Phone channel): ✅ Data continues through Sept 28
- `GENESYS_FACT_PHONE_CALL_CONVERSATION`: ❌ No data after Sept 17, 2025
- Latest outbound call data: September 17, 2025 (135 calls)

**Impact:**
Dashboard shows zero values for:
- Phone connections
- Call attempts
- Voicemails left
- Voicemails attempted

**Status:** This is a Genesys data ingestion issue being handled by Data Engineering (Metin)

## Deliverables

### Final Deliverables
- `altered_sql_that_was_failing.sql` - Corrected SQL query with proper schema reference

### Source Materials
- `BI-2011_In_Funnel_Email_Monitoring.py` - Original Databricks notebook for reference

### Investigation Files (exploratory_analysis/)
- `1_cte_dqs_validation.sql` - Delinquent population validation queries
- `2_cte_phone_calls_validation.sql` - Phone outreach metrics validation
- `3_cte_sent_texts_validation.sql` - SMS outreach metrics validation
- `4_cte_emails_sent_validation.sql` - Email metrics validation (identified the gap)
- `5_cte_gr_email_lists_validation.sql` - GR email lists validation

## Quality Control

QC steps completed:
- ✅ Verified DSH_EMAIL_MONITORING_EVENTS data stopped on Sept 24, 2025
- ✅ Confirmed Databricks job failure via CLI (job run 604748953895353)
- ✅ Identified root cause: SQL compilation error for non-existent view path
- ✅ Applied fix to Databricks notebook (line 389 schema correction)
- ✅ Verified job ran successfully after fix
- ✅ Confirmed DSH_EMAIL_MONITORING_EVENTS now contains data through Sept 29, 2025
- ✅ Validated daily event counts for Sept 24-29 period