# BI-1451_Loss_Forecasting Migration Notes

## Job Information
- **File**: `BI-1451_Loss_Forecasting.py`
- **Current Status**: ✅ **DEPLOYED TO PRODUCTION** (PR #2003)
- **Merge Date**: October 2, 2025
- **Commit**: bf1d5991
- **Complexity**: Low (single vw_application reference)

## Current Usage of Legacy Views
- **Line 693**: `left join analytics.vw_application as app`
- **Join Key**: `elt.PAYOFFUID = app.lead_guid`

## Fields Used from vw_application
| Field in Code | Line | Available in VW_APP_LOAN_PRODUCTION | Replacement Field | Status |
|---------------|------|-------------------------------------|-------------------|--------|
| `lead_guid` | 694 | ✅ Yes | `GUID` | ✅ OK |
| `LAST_TOUCH_UTM_CHANNEL_GROUPING` | 625 | ✅ Yes | `APP_CHANNEL` | ✅ OK (Renamed) |
| `utm_source` | 626 | ✅ Yes | `UTM_SOURCE` | ✅ OK |
| `utm_campaign` | 627 | ✅ Yes | `UTM_CAMPAIGN` | ✅ OK |
| `utm_medium` | 628 | ✅ Yes | `UTM_MEDIUM` | ✅ OK |

## Field Mapping Analysis ✅

### LAST_TOUCH_UTM_CHANNEL_GROUPING → APP_CHANNEL
**Status**: ✅ **CONFIRMED - Fields are equivalent (renamed field)**

Data comparison of 195,986 matching records shows identical values:
- Unattributed: 121,868 exact matches
- Paid Search: 28,257 exact matches
- Affiliate Non-API/CK Lightbox: 22,748 matches
- Affiliate API: 12,301 exact matches
- Direct Mail: 6,124 exact matches
- Plus 12 additional matching categories

**Conclusion**: `APP_CHANNEL` is the direct replacement for `LAST_TOUCH_UTM_CHANNEL_GROUPING`

## Proposed Migration Changes

### Change 1: Replace Table Reference
```sql
-- BEFORE (line 693-694):
left join analytics.vw_application as app
    on elt.PAYOFFUID = app.lead_guid

-- AFTER:
left join analytics.VW_APP_LOAN_PRODUCTION as app
    on elt.PAYOFFUID = app.GUID
```

### Change 2: Update Field Reference
```sql
-- BEFORE (line 625):
, app.LAST_TOUCH_UTM_CHANNEL_GROUPING

-- AFTER:
, app.APP_CHANNEL as LAST_TOUCH_UTM_CHANNEL_GROUPING
```

## Testing Plan
1. **Pre-Migration Validation**:
   - Count rows in current output
   - Sample values for LAST_TOUCH_UTM_CHANNEL_GROUPING

2. **Post-Migration Validation**:
   - Compare row counts
   - Verify LAST_TOUCH_UTM_CHANNEL_GROUPING values match
   - Check for unexpected NULLs
   - Validate utm_source, utm_campaign, utm_medium fields

3. **Test Query**:
```sql
-- Compare old vs new view
SELECT
    old.lead_guid,
    old.LAST_TOUCH_UTM_CHANNEL_GROUPING as old_channel,
    new.GUID,
    new.APP_CHANNEL as new_channel,
    CASE WHEN old.LAST_TOUCH_UTM_CHANNEL_GROUPING = new.APP_CHANNEL THEN 'MATCH' ELSE 'DIFF' END as comparison
FROM analytics.vw_application old
LEFT JOIN analytics.VW_APP_LOAN_PRODUCTION new ON old.lead_guid = new.GUID
WHERE old.lead_guid IS NOT NULL
LIMIT 100;
```

## Migration Changes Made ✅

### Change 1: Field Reference (Line 625)
```python
# BEFORE:
, app.LAST_TOUCH_UTM_CHANNEL_GROUPING

# AFTER:
, app.APP_CHANNEL as LAST_TOUCH_UTM_CHANNEL_GROUPING
```

### Change 2: Table Reference (Lines 693-694)
```python
# BEFORE:
left join analytics.vw_application as app
    on elt.PAYOFFUID = app.lead_guid

# AFTER:
left join analytics.VW_APP_LOAN_PRODUCTION as app
    on elt.PAYOFFUID = app.GUID
```

## Verification
- ✅ No more references to `vw_application` found
- ✅ New references confirmed: `VW_APP_LOAN_PRODUCTION` (line 693), `APP_CHANNEL` (line 625)

## Deployment Complete
1. ✅ Code changes complete
2. ✅ Tested in Databricks - Job ran successfully
3. ✅ PR #2003 merged to main (Oct 2, 2025)
4. ✅ Deployed to production

## Notes
- ✅ All fields mapped successfully - no missing fields!
- ✅ Migration complete - 2 simple changes made
- No external dependencies
- No CLS data requirements
- Ready for testing

---

*Status: ✅ DEPLOYED TO PRODUCTION*
*PR: #2003*
*Merged: October 2, 2025*
*Commit: bf1d5991*
