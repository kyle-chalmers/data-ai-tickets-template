# DI-1293: Verification - Collections Jobs Unaffected

## Summary
Collections jobs (BI-2482, BI-737, BI-820, BI-813, DI-862) will **NOT be affected** by the changes in DI-1293.

## Reason
Collections jobs join `VW_LOAN_CONTACT_RULES` on `LOAN_ID`, not `APPLICATION_GUID`:

### Example from BI-2482 (Line 444-447):
```python
inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
           on L.LOAN_ID = LCR.LOAN_ID
               and LCR.CONTACT_RULE_END_DATE is null
where LCR.CEASE_AND_DESIST = true
```

## What's Changing
- `ANALYTICS.VW_LOAN_CONTACT_RULES` will become: `SELECT * FROM BRIDGE.VW_LOAN_CONTACT_RULES`
- This removes APPLICATION-level data (the `sms_consent` CTE with `APPLICATION_GUID`)
- **LOAN-level data remains unchanged** in `BRIDGE.VW_LOAN_CONTACT_RULES`

## Impact Assessment
✅ **No changes required** to collections jobs:
- BI-2482_Outbound_List_Generation_for_GR
- BI-737_GR_Call_List
- BI-820 (SMS campaigns)
- BI-813 (Remitter)
- DI-862 (SIMM)

All collections jobs will continue to:
- Join on `LOAN_ID`
- Access loan-level suppression flags: `CEASE_AND_DESIST`, `SUPPRESS_PHONE`, `SUPPRESS_EMAIL`, `SUPPRESS_LETTER`, `SUPPRESS_TEXT`
- Function exactly as before

## Testing Recommendation
- Run BI-2482 in dev environment after deployment
- Verify suppression counts match production baseline
- Confirm no records lost due to join changes
