# BI-2421_Prescreen_Marketing_Data Migration Notes

## Job Information
- **Files**:
  - `01_DM_Forecast.py` (main file with legacy views)
  - `02_DM_EMAIL_MATCHBACK.py` (legacy view commented out)
  - `03_Data_Source_Checking.py` (no legacy views)
- **Current Status**: ✅ **CODE COMPLETE** - Ready for Testing
- **Branch**: `DI-1309/BI-2421-migration`
- **Commit**: `98f931be`
- **Date**: October 9, 2025
- **Complexity**: Medium (2 legacy views, straightforward mapping)

## Current Usage of Legacy Views

### File: 01_DM_Forecast.py

#### VW_APPLICATION (Line 322)
```sql
left join analytics.VW_APPLICATION a
    on a.lead_guid = b.lead_guid
```

#### vw_application_pii (Line 328)
```sql
left join analytics_pii.vw_application_pii pii
    on a.lead_guid = pii.lead_guid
```

#### vw_application_status_transition (Line 326-327) - ALREADY COMMENTED OUT
```sql
--left join analytics.vw_application_status_transition d
--on a.lead_guid = d.lead_guid
```

### File: 02_DM_EMAIL_MATCHBACK.py (Line 168)
```sql
#left join DATA_STORE.VW_APPLICATION as app
```
**Status**: ✅ Already commented out - no action needed

## Fields Used from Legacy Views

### From VW_APPLICATION (alias: `a`)
| Field | Line | Available in VW_APP_LOAN_PRODUCTION | Replacement Field | Status |
|-------|------|-------------------------------------|-------------------|--------|
| `lead_guid` | 323, 329 | ✅ Yes | `GUID` | ✅ OK |
| `selected_offer_amount` | 300 | ✅ Yes | `SELECTED_OFFER_AMT` | ✅ OK |
| `last_touch_utm_channel_grouping` | 301 | ✅ Yes | `APP_CHANNEL` | ✅ OK (Renamed) |
| `selected_offer_interest_rate` | 302 | ✅ Yes | `SELECTED_OFFER_INTEREST_RATE` | ✅ OK |
| `selected_offer_apr` | 303 | ✅ Yes | `SELECTED_OFFER_APR` | ✅ OK |
| `selected_offer_term` | 304 | ✅ Yes | `SELECTED_OFFER_TERM` | ✅ OK |

### From vw_application_pii (alias: `pii`)
| Field | Line | Available in VW_APP_PII | Replacement Field | Status |
|-------|------|-------------------------|-------------------|--------|
| `lead_guid` | 329 | ✅ Yes | `GUID` | ✅ OK |
| `date_of_birth` | 307 | ✅ Yes | `DATE_OF_BIRTH` | ✅ OK |

## Query Context

The query is building a `DSH_DM_Mart` table for prescreen marketing forecasting. It joins:
1. `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT` (base table with application data)
2. `analytics.VW_APPLICATION` (for offer and channel data) → **TO BE REPLACED**
3. `analytics.vw_decisions_current` (for credit scores, pricing tier)
4. `analytics_pii.vw_application_pii` (for date of birth) → **TO BE REPLACED**
5. `analytics.vw_applicants_current` (for housing payment)
6. `analytics.vw_loan` (for premium, origination fee)

## Proposed Migration Changes

### Change 1: Replace VW_APPLICATION with VW_APP_LOAN_PRODUCTION
```sql
-- BEFORE (Line 322-323):
left join analytics.VW_APPLICATION a
    on a.lead_guid = b.lead_guid

-- AFTER:
left join analytics.VW_APP_LOAN_PRODUCTION a
    on a.GUID = b.lead_guid
```

### Change 2: Update field references from VW_APPLICATION
```sql
-- BEFORE (Line 300-304):
a.selected_offer_amount,
a.last_touch_utm_channel_grouping,
a.selected_offer_interest_rate,
a.selected_offer_apr,
a.selected_offer_term,

-- AFTER:
a.SELECTED_OFFER_AMT as selected_offer_amount,
a.APP_CHANNEL as last_touch_utm_channel_grouping,
a.SELECTED_OFFER_INTEREST_RATE as selected_offer_interest_rate,
a.SELECTED_OFFER_APR as selected_offer_apr,
a.SELECTED_OFFER_TERM as selected_offer_term,
```

### Change 3: Replace vw_application_pii with VW_APP_PII
```sql
-- BEFORE (Line 328-329):
left join analytics_pii.vw_application_pii pii
    on a.lead_guid = pii.lead_guid

-- AFTER:
left join analytics_pii.VW_APP_PII pii
    on a.GUID = pii.GUID
```

### Change 4: Update date_of_birth reference (already correct)
```sql
-- BEFORE (Line 307):
pii.date_of_birth

-- AFTER (no change needed):
pii.DATE_OF_BIRTH
```

## Field Mapping Summary

### VW_APPLICATION → VW_APP_LOAN_PRODUCTION
- ✅ All 6 fields have direct mappings
- ✅ `last_touch_utm_channel_grouping` → `APP_CHANNEL` (confirmed from BI-1451 migration)
- ✅ `selected_offer_amount` → `SELECTED_OFFER_AMT` (simple name change)

### vw_application_pii → VW_APP_PII
- ✅ Single field `date_of_birth` has direct mapping
- ✅ Join key changes from `lead_guid` to `GUID`

## Testing Plan

### Pre-Migration Validation
1. Count rows in `CRON_STORE.DSH_DM_Mart` current production
2. Sample key fields (selected_offer_amount, last_touch_utm_channel_grouping, date_of_birth)
3. Check for NULL values in critical fields

### Post-Migration Validation
1. Compare row counts (before vs after)
2. Validate field values match:
   - `selected_offer_amount` values unchanged
   - `last_touch_utm_channel_grouping` values match `APP_CHANNEL`
   - `date_of_birth` values unchanged
3. Check JOIN behavior (LEFT JOIN should maintain same row counts)
4. Verify downstream reports using DSH_DM_Mart still work

### Test Query
```sql
-- Compare old vs new view fields
SELECT
    old_app.lead_guid,
    old_app.selected_offer_amount as old_offer_amt,
    new_app.SELECTED_OFFER_AMT as new_offer_amt,
    old_app.last_touch_utm_channel_grouping as old_channel,
    new_app.APP_CHANNEL as new_channel,
    old_pii.date_of_birth as old_dob,
    new_pii.DATE_OF_BIRTH as new_dob,
    CASE WHEN old_app.selected_offer_amount = new_app.SELECTED_OFFER_AMT THEN 'MATCH' ELSE 'DIFF' END as offer_match,
    CASE WHEN old_app.last_touch_utm_channel_grouping = new_app.APP_CHANNEL THEN 'MATCH' ELSE 'DIFF' END as channel_match
FROM analytics.VW_APPLICATION old_app
LEFT JOIN analytics.VW_APP_LOAN_PRODUCTION new_app
    ON old_app.lead_guid = new_app.GUID
LEFT JOIN analytics_pii.vw_application_pii old_pii
    ON old_app.lead_guid = old_pii.lead_guid
LEFT JOIN analytics_pii.VW_APP_PII new_pii
    ON new_app.GUID = new_pii.GUID
WHERE old_app.lead_guid IS NOT NULL
LIMIT 100;
```

## Migration Steps

- [ ] Create development branch: `DI-1309/BI-2421-migration`
- [ ] Update VW_APPLICATION to VW_APP_LOAN_PRODUCTION (Line 322)
- [ ] Update VW_APPLICATION field references (Lines 300-304)
- [ ] Update vw_application_pii to VW_APP_PII (Line 328)
- [ ] Update join conditions (a.lead_guid → a.GUID)
- [ ] Run test query in Snowflake to validate field mappings
- [ ] Test full job in dev environment
- [ ] Compare output table row counts and sample data
- [ ] Create PR and get review
- [ ] Deploy to production

## Notes
- ✅ All fields have direct mappings - no missing fields
- ✅ No CLS data requirements
- ✅ File 02_DM_EMAIL_MATCHBACK.py already has legacy view commented out
- ✅ Only one file needs changes (01_DM_Forecast.py)
- ✅ Straightforward migration with well-documented field mapping from BI-1451

## Business Context
- **Purpose**: Direct mail and email prescreen marketing forecasting
- **Output**: `CRON_STORE.DSH_DM_Mart` table
- **Stakeholders**: Marketing/Prescreen team
- **Impact**: Used for campaign performance tracking and goal forecasting

---

*Status: 🔄 IN PROGRESS - Analysis Complete*
*Next Step: Create branch and implement changes*
*Last Updated: October 9, 2025*
