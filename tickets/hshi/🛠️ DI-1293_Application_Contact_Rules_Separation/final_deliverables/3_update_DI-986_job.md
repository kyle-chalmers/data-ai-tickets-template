# DI-1293: Update DI-986 Job to Use VW_APP_CONTACT_RULES

## File Updated
`/Users/hshi/WOW/business-intelligence-data-jobs/jobs/DI-986_Outbound_List_Generation_for_Funnel/DI-986_Outbound_List_Generation_for_Funnel.ipynb`

## Changes Summary

### Application-Level Campaigns → VW_APP_CONTACT_RULES (3 suppressions updated)

#### 1. Email Non-Opener SMS Suppression
**Changed FROM:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                on app.guid = LCR.application_guid
                    and LCR.CONTACT_RULE_END_DATE is null
     left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
               on app.guid = SP.PAYOFFUID
                   and SP.SUPPRESSION_TYPE = 'Global'
```

**Changed TO:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_APP_CONTACT_RULES as ACR -- application-level SMS opt out per DI-1293
                on app.guid = ACR.APPLICATION_GUID
                    and ACR.CONTACT_RULE_END_DATE is null
     left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
               on app.guid = SP.PAYOFFUID
                   and SP.SUPPRESSION_TYPE = 'Global'
WHERE ACR.SUPPRESS_TEXT = true
  and SP.PAYOFFUID is null
```

#### 2. Allocated Capital Partner Suppression
**Changed FROM:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                on app.guid = LCR.application_guid
                    and LCR.CONTACT_RULE_END_DATE is null
```

**Changed TO:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_APP_CONTACT_RULES as ACR -- application-level SMS opt out per DI-1293
                on app.guid = ACR.APPLICATION_GUID
                    and ACR.CONTACT_RULE_END_DATE is null
WHERE ACR.SUPPRESS_TEXT = true
  and SP.PAYOFFUID is null
```

#### 3. SMS Funnel Communication Suppression
**Changed FROM:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                on app.guid = LCR.application_guid
                    and LCR.CONTACT_RULE_END_DATE is null
```

**Changed TO:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_APP_CONTACT_RULES as ACR -- application-level SMS opt out per DI-1293
                on app.guid = ACR.APPLICATION_GUID
                    and ACR.CONTACT_RULE_END_DATE is null
WHERE ACR.SUPPRESS_TEXT = true
  and SP.PAYOFFUID is null
```

### Loan-Level Campaigns → Fixed Patterns (3 suppressions fixed)

#### 4. AutoPaySMS Suppression (CRITICAL FIX)
**Changed FROM:**
```python
from ANALYTICS.vw_APP_LOAN_PRODUCTION as app
     inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                on app.guid = LCR.application_guid  -- BROKEN after removing APPLICATION_GUID
                    and LCR.CONTACT_RULE_END_DATE is null
```

**Changed TO:**
```python
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
where LCR.SUPPRESS_TEXT = true
  and SP.PAYOFFUID is null
```

#### 5. PIF Email Suppression (FIXED - Removed VW_APPLICATION join + Fixed suppression flag)
**Changed FROM:**
```python
from ANALYTICS.vw_application as app
     inner join analytics.vw_loan as l
        on app.lead_guid = l.lead_guid
     inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                on L.LOAN_ID = LCR.LOAN_ID
                    and LCR.CONTACT_RULE_END_DATE is null
where LCR.SUPPRESS_TEXT = true  -- WRONG: Should be SUPPRESS_EMAIL
```

**Changed TO:**
```python
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
where LCR.SUPPRESS_EMAIL = true  -- FIXED: Email campaigns check SUPPRESS_EMAIL
  and SP.PAYOFFUID is null
```

#### 6. 6M to PIF Email Suppression (FIXED - Same as PIF Email)
**Changed FROM:**
```python
from ANALYTICS.vw_application as app
     inner join analytics.vw_loan as l
        on app.lead_guid = l.lead_guid
     inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                on L.LOAN_ID = LCR.LOAN_ID
where LCR.SUPPRESS_TEXT = true  -- WRONG
```

**Changed TO:**
```python
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
where LCR.SUPPRESS_EMAIL = true  -- FIXED
  and SP.PAYOFFUID is null
```

### Suppressions Removed

#### 7. Prescreen Email DNC: Email Suppression (REMOVED)
**Reason:**
- Prescreen Email is an application-level campaign
- `VW_APP_CONTACT_RULES` currently only has `SUPPRESS_TEXT` (SMS), not email suppression
- Previous suppression was incorrectly checking loan-level `SUPPRESS_TEXT` for an email campaign
- Removed until we add email suppression to application-level contact rules in a future ticket

**Also updated delete statements:**
- Removed `'Prescreen Email'` from email DNC cleanup queries

## Git Commits

Branch: `DI-1293`

1. **Initial update** - Changed 3 application campaigns to VW_APP_CONTACT_RULES
2. **WHERE clause fix** - Added `WHERE ACR.SUPPRESS_TEXT = true` to all 3 application suppressions
3. **AutoPaySMS fix** - Fixed to use loan-level pattern (critical - prevented breakage)
4. **Prescreen Email removal** - Removed incorrect application-level email suppression
5. **PIF Email fixes** - Simplified both PIF email campaigns and fixed SUPPRESS_EMAIL flag

## Summary

**Application-level campaigns (VW_APP_CONTACT_RULES):**
- ✅ Email Non-Opener SMS → `SUPPRESS_TEXT`
- ✅ Allocated Capital Partner → `SUPPRESS_TEXT`
- ✅ SMS Funnel Communication → `SUPPRESS_TEXT`

**Loan-level campaigns (VW_LOAN → VW_LOAN_CONTACT_RULES):**
- ✅ AutoPaySMS → `SUPPRESS_TEXT` (fixed pattern)
- ✅ PIF Email → `SUPPRESS_EMAIL` (simplified + fixed flag)
- ✅ 6M to PIF Email → `SUPPRESS_EMAIL` (simplified + fixed flag)

**Removed:**
- ✅ Prescreen Email DNC suppression (no application-level email suppression available)

**Total changes:** 6 suppressions updated/fixed, 1 removed, all delete statements adjusted
