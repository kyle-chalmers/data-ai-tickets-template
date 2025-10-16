# DI-977: Prescreen Email List Migration

**Job**: DI-977_Prescreen_Email_List
**File**: `DI-977_Prescreen_Email_List.ipynb`
**Migration Date**: October 9, 2025
**Complexity**: Low

## Overview

This job appends email information for prescreen campaigns. It runs on scheduled dates to pull email data for remarketing leads and uploads to SFMC SFTP.

## Legacy Views Used

| Legacy View | Occurrences | Usage |
|-------------|-------------|-------|
| `analytics.vw_application` | 1 | Join on `lead_guid` to get `application_id` |
| `analytics_pii.vw_application_pii` | 1 | Join on `lead_guid` to get `EMAIL` |

## Fields Used from Legacy Views

### From `analytics.vw_application`
- `application_id` - Application identifier
- Join key: `lead_guid`

### From `analytics_pii.vw_application_pii`
- `EMAIL` - Customer email address
- Join key: `lead_guid`

## Migration Mapping

| Legacy View | New View | Join Key Change |
|-------------|----------|-----------------|
| `analytics.vw_application` | `analytics.VW_APP_LOAN_PRODUCTION` | `lead_guid` → `GUID` |
| `analytics_pii.vw_application_pii` | `analytics_pii.VW_APP_PII` | `lead_guid` → `GUID` |

### Field Mappings

| Legacy Field | New Field | Notes |
|--------------|-----------|-------|
| `app.lead_guid` | `app.GUID` | Primary join key |
| `app.application_id` | `app.APPLICATION_ID` | Available in VW_APP_LOAN_PRODUCTION |
| `pii.lead_guid` | `pii.GUID` | Primary join key |
| `pii.EMAIL` | `pii.EMAIL` | Same field name |

## Code Changes

### Cell 11: Query Update

**Before**:
```sql
left join  analytics.vw_application app
    on a.c_customer_id = app.lead_guid
left join analytics_pii.vw_application_pii pii
    on a.c_customer_id = pii.lead_guid
```

**After**:
```sql
left join  analytics.VW_APP_LOAN_PRODUCTION app
    on a.c_customer_id = app.GUID
left join analytics_pii.VW_APP_PII pii
    on a.c_customer_id = pii.GUID
```

## Testing Checklist

- [ ] Verify `application_id` field exists in VW_APP_LOAN_PRODUCTION
- [ ] Verify `EMAIL` field exists in VW_APP_PII
- [ ] Compare row counts before and after migration
- [ ] Test with actual campaign date to ensure email list generation works
- [ ] Validate SFTP upload in dev environment
- [ ] Check Slack notification sends correctly

## Impact Assessment

**Risk Level**: Low

**Reasons**:
- Only 2 simple joins to update
- Fields have direct 1:1 mappings
- Join key change is straightforward (`lead_guid` → `GUID`)
- No complex logic or aggregations involved

**Data Validation**:
- Row counts should remain identical
- Email addresses should match exactly
- Application IDs should be the same

## Notes

- This job runs conditionally based on campaign schedule in Google Sheets
- Only runs when `is_current_date_in_run_dates` is True
- Outputs to SFMC SFTP only in prod environment
- Uses `c_customer_id` from `VW_IWCO_DATA` which contains the GUID/lead_guid value

## Related Documentation

- [VW_APP_LOAN_PRODUCTION.md](../MetaData/VW_APP_LOAN_PRODUCTION.md)
- [VW_APP_PII.md](../MetaData/VW_APP_PII.md)
- [DI-1309 README](README.md)
