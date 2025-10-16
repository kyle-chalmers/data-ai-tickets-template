# DI-986: Outbound List Generation for Funnel - Complete Migration

**Job**: DI-986_Outbound_List_Generation_for_Funnel
**File**: `DI-986_Outbound_List_Generation_for_Funnel.ipynb`
**Migration Date**: October 9, 2025
**Complexity**: High (large notebook, partial migration already done in DI-1293)

## Overview

This job generates outbound lists for marketing campaigns and partner allocations. It's a large notebook (~2875 lines) that has already been partially migrated in DI-1293 (Sept 2025) where contact rules were refactored.

## Current State

**Partially Migrated**: Some sections already use `VW_APP_LOAN_PRODUCTION` (per README notes)

**Remaining Legacy Views**: 8 occurrences across 6 cells

## Legacy Views Found

| Cell ID | Line | Legacy View | Current Join Key | Usage |
|---------|------|-------------|------------------|-------|
| cell-11 | ~332 | `ANALYTICS.VW_APPLICATION` | `LEAD_GUID` | Partner allocation list |
| cell-14 | ~421 | `analytics.vw_application` | `lead_guid` | Prescreen email campaign |
| cell-14 | ~423 | `analytics_pii.vw_application_pii` | `lead_guid` | Email data for campaign |
| cell-52 | ~2482 | `ANALYTICS_PII.VW_LEAD_PII` | `LEAD_GUID` | Genesys campaign PII |
| cell-54 | ~2565 | `ANALYTICS.VW_APPLICATION` | `LEAD_GUID` | Partner allocated campaign |
| cell-54 | ~2570 | `ANALYTICS_PII.VW_APPLICATION_PII` | `APPLICATION_ID` | Partner campaign PII |
| cell-56 | ~2670 | `ANALYTICS_PII.VW_LEAD_PII` | `LEAD_GUID` | Genesys campaign PII |
| cell-58 | ~2777 | `ANALYTICS_PII.VW_LEAD_PII` | `LEAD_GUID` | Genesys campaign PII |

## Migration Mapping

### View Replacements

| Legacy View | New View | Notes |
|-------------|----------|-------|
| `ANALYTICS.VW_APPLICATION` | `ANALYTICS.VW_APP_LOAN_PRODUCTION` | 2 occurrences |
| `analytics.vw_application` | `ANALYTICS.VW_APP_LOAN_PRODUCTION` | 1 occurrence |
| `ANALYTICS_PII.VW_APPLICATION_PII` | `ANALYTICS_PII.VW_APP_PII` | 1 occurrence |
| `analytics_pii.vw_application_pii` | `ANALYTICS_PII.VW_APP_PII` | 1 occurrence |
| `ANALYTICS_PII.VW_LEAD_PII` | `ANALYTICS_PII.VW_APP_PII` | 3 occurrences |

### Join Key Changes

| Legacy Join | New Join | Notes |
|-------------|----------|-------|
| `APP.LEAD_GUID` | `APP.GUID` | Standard GUID join |
| `app.lead_guid` | `app.GUID` | Standard GUID join |
| `PII.LEAD_GUID` | `PII.GUID` | Standard GUID join |
| `APP.APPLICATION_ID = PII.APPLICATION_ID` | `APP.GUID = PII.GUID` | ⚠️ Join key change from APP_ID to GUID |

## Detailed Migration Changes

### Cell 11: Partner Allocation List (Line ~332)

**Before**:
```sql
from ANALYTICS.VW_APPLICATION as APP
inner join ANALYTICS.VW_PARTNER as P
    on APP.PARTNER_ID = P.PARTNER_ID
        and APP.SOURCE = P.SOURCE
```

**After**:
```sql
from ANALYTICS.VW_APP_LOAN_PRODUCTION as APP
inner join ANALYTICS.VW_PARTNER as P
    on APP.PARTNER_ID = P.PARTNER_ID
        and APP.SOURCE = P.SOURCE
```

**Fields Used**: `LEAD_GUID`, `PARTNER_ID`, `SOURCE`
**Risk**: Low - straightforward replacement

---

### Cell 14: Prescreen Email Campaign (Lines ~421-423)

**Before**:
```sql
from BUSINESS_INTELLIGENCE.DIRECT_MAIL.VW_IWCO_DATA a
join  analytics.vw_application app
    on a.c_customer_id = app.lead_guid
join analytics_pii.vw_application_pii pii
    on a.c_customer_id = pii.lead_guid
where a.A_UTMCAMPAIGN = 'PSCamp{campaign_value}.tu_dm'
    and pii.email is not null
```

**After**:
```sql
from BUSINESS_INTELLIGENCE.DIRECT_MAIL.VW_IWCO_DATA a
join  analytics.VW_APP_LOAN_PRODUCTION app
    on a.c_customer_id = app.GUID
join analytics_pii.VW_APP_PII pii
    on a.c_customer_id = pii.GUID
where a.A_UTMCAMPAIGN = 'PSCamp{campaign_value}.tu_dm'
    and pii.email is not null
```

**Fields Used**: `lead_guid` → `GUID`, `email`
**Risk**: Low - similar to DI-977 migration

---

### Cell 52: Genesys Campaign List 1 (Line ~2482)

**Before**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    left join DATA_STORE.MVW_LOAN_TAPE as LT
        on OL.PAYOFFUID = LT.PAYOFFUID
    left join ANALYTICS_PII.VW_LEAD_PII as PII
        on OL.PAYOFFUID = PII.LEAD_GUID
```

**After**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    left join DATA_STORE.MVW_LOAN_TAPE as LT
        on OL.PAYOFFUID = LT.PAYOFFUID
    left join ANALYTICS_PII.VW_APP_PII as PII
        on OL.PAYOFFUID = PII.GUID
```

**Fields Used**: `LEAD_GUID` → `GUID`, PII fields
**Risk**: Low - straightforward PII join

---

### Cell 54: Partner Allocated Campaign (Lines ~2565-2570)

**Before**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    inner join  ANALYTICS.VW_APPLICATION as APP
        on OL.PAYOFFUID = APP.LEAD_GUID
    inner join ANALYTICS.VW_PARTNER as P
        on APP.PARTNER_ID = P.PARTNER_ID
            and APP.SOURCE = P.SOURCE
    inner join ANALYTICS_PII.VW_APPLICATION_PII as PII
        on APP.APPLICATION_ID = PII.APPLICATION_ID
```

**After**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    inner join  ANALYTICS.VW_APP_LOAN_PRODUCTION as APP
        on OL.PAYOFFUID = APP.GUID
    inner join ANALYTICS.VW_PARTNER as P
        on APP.PARTNER_ID = P.PARTNER_ID
            and APP.SOURCE = P.SOURCE
    inner join ANALYTICS_PII.VW_APP_PII as PII
        on APP.GUID = PII.GUID
```

**Fields Used**: `LEAD_GUID` → `GUID`, `APPLICATION_ID`, `PARTNER_ID`, `SOURCE`
**Risk**: Medium - join key changes from APPLICATION_ID to GUID

---

### Cell 56: Genesys Campaign List 2 (Line ~2670)

**Before**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    left join DATA_STORE.MVW_LOAN_TAPE as LT
        on OL.PAYOFFUID = LT.PAYOFFUID
    left join ANALYTICS_PII.VW_LEAD_PII as PII
        on OL.PAYOFFUID = PII.LEAD_GUID
```

**After**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    left join DATA_STORE.MVW_LOAN_TAPE as LT
        on OL.PAYOFFUID = LT.PAYOFFUID
    left join ANALYTICS_PII.VW_APP_PII as PII
        on OL.PAYOFFUID = PII.GUID
```

**Fields Used**: `LEAD_GUID` → `GUID`, PII fields
**Risk**: Low

---

### Cell 58: Genesys Campaign List 3 (Line ~2777)

**Before**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    left join DATA_STORE.MVW_LOAN_TAPE as LT
        on OL.PAYOFFUID = LT.PAYOFFUID
    left join ANALYTICS_PII.VW_LEAD_PII as PII
        on OL.PAYOFFUID = PII.LEAD_GUID
```

**After**:
```sql
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
    left join DATA_STORE.MVW_LOAN_TAPE as LT
        on OL.PAYOFFUID = LT.PAYOFFUID
    left join ANALYTICS_PII.VW_APP_PII as PII
        on OL.PAYOFFUID = PII.GUID
```

**Fields Used**: `LEAD_GUID` → `GUID`, PII fields
**Risk**: Low

---

## Fields to Verify

Need to confirm these fields exist in new views:

### From VW_APP_LOAN_PRODUCTION
- [x] `GUID` (replaces `LEAD_GUID`)
- [ ] `PARTNER_ID`
- [ ] `SOURCE`
- [ ] `APP_ID` (replaces `APPLICATION_ID` if needed)

### From VW_APP_PII
- [x] `GUID` (replaces `LEAD_GUID`)
- [x] `EMAIL`
- [ ] All PII fields used in Genesys campaigns

## Testing Checklist

- [ ] Verify row counts match before/after for each query
- [ ] Test Cell 11: Partner allocation list
- [ ] Test Cell 14: Prescreen email campaign (similar to DI-977)
- [ ] Test Cell 52: Genesys campaign list 1
- [ ] Test Cell 54: Partner allocated campaign (most complex - join key change)
- [ ] Test Cell 56: Genesys campaign list 2
- [ ] Test Cell 58: Genesys campaign list 3
- [ ] Validate all PII fields are accessible
- [ ] Compare output files with previous runs

## Risk Assessment

**Overall Risk**: Medium-High

**High Risk Areas**:
- Cell 54: Join key change from `APPLICATION_ID` to `GUID` - needs careful validation
- Large notebook with multiple campaign types - extensive testing required

**Low Risk Areas**:
- Cells 52, 56, 58: Simple PII joins using GUID
- Cell 14: Already validated pattern from DI-977 migration

## Notes

- This notebook was partially refactored in DI-1293 (Sept 2025) for contact rules
- Some sections may already use `VW_APP_LOAN_PRODUCTION` - verify before changing
- `PAYOFFUID` in `RPT_OUTBOUND_LISTS` contains GUID values
- Multiple campaign types: Partner Allocation, Prescreen Email, Genesys campaigns

## Related Documentation

- [VW_APP_LOAN_PRODUCTION.md](../MetaData/VW_APP_LOAN_PRODUCTION.md)
- [VW_APP_PII.md](../MetaData/VW_APP_PII.md)
- [DI-1293](https://happymoneyinc.atlassian.net/browse/DI-1293) - Previous contact rules refactor
- [DI-1309 README](README.md)
