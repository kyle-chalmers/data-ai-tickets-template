# SIMM Character Filtering Bug - Code Fix Documentation

## Overview

This document provides the specific code changes needed to fix the character filtering logic in BI-2482 that incorrectly excludes SIMM accounts from non-DPD3-119 campaigns.

## Root Cause Analysis

### Current Problematic Logic

The character filtering logic is being applied universally to all campaign types:

```sql
-- Current problematic pattern in multiple campaigns:
and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
```

This was designed for DPD 3-119 partner allocation but is incorrectly excluding SIMM accounts from:
- Charge-off campaigns (when accounts should return to Happy Money)
- Payment reminders and due date notifications (universal customer communications)

### Business Rule Clarification

**Correct Logic:**
- **DPD 3-119**: Apply character allocation (Happy Money 0-7, SIMM 8-f)
- **Outside DPD 3-119**: Include ALL customers (no character filtering)

## Code Changes Required

### 1. Call List Campaign (Line 237) - CRITICAL FIX

**File:** `/jobs/BI-2482_Outbound_List_Generation_for_GR/BI-2482_Outbound_List_Generation_for_GR.py`

**Current Code:**
```sql
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold'))
  and LIST_NAME <> 'Exclude'
  and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
  and PAYOFFUID not in (select SST.PAYOFFUID from SST)
```

**Fixed Code:**
```sql
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold'))
  and LIST_NAME <> 'Exclude'
  and (
    (DAYSPASTDUE between 3 and 119 and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7'))
    OR
    (DAYSPASTDUE not between 3 and 119)
  )
  and PAYOFFUID not in (select SST.PAYOFFUID from SST)
```

**Impact:** Allows SIMM charge-off accounts to return to Happy Money Call List "Charge off" bucket.

### 2. SMS Campaign (Line 295) - CRITICAL FIX

**Current Code:**
```sql
where LT.STATUS <> 'Charge off'
  and LIST_NAME <> 'Exclude'
  and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
```

**Fixed Code:**
```sql
where LT.STATUS <> 'Charge off'
  and LIST_NAME <> 'Exclude'
  and (
    (DAYSPASTDUE between 3 and 119 and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7'))
    OR
    (DAYSPASTDUE not between 3 and 119)
  )
```

**Impact:** Allows SIMM accounts to receive payment reminders and due date notifications regardless of partner allocation.

### 3. Remitter Campaign (Line 260) - NO CHANGE REQUIRED

**Current Code** (Working Correctly):
```sql
where DAYSPASTDUE >= 60
  and STATUS not in ('Paid in Full', 'Sold', 'Charge off')
  and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
  and PAYOFFUID not in (select SST.PAYOFFUID from SST)
```

**Status:** This is working as intended - SIMM should be excluded from Remitter for DPD 3-119 range.

## Implementation Notes

### Before Making Changes

1. **Backup Current Code**: Create a copy of the current BI-2482 file
2. **Test in Development**: Deploy changes to dev environment first
3. **Coordinate with Collections Team**: Notify stakeholders of pending fix

### After Making Changes

1. **Run Validation Queries**: Verify SIMM accounts appear in appropriate campaigns
2. **Monitor Campaign Volumes**: Check for expected increases in Call List and SMS volumes
3. **Stakeholder Communication**: Update Collections team on implementation

## Testing Strategy

### Pre-Implementation Testing

1. **Identify Test Accounts**: Find SIMM accounts (8-f characters) that are currently:
   - Charged off (should appear in Call List after fix)
   - Have payment reminders due (should appear in SMS after fix)

2. **Document Current Behavior**: Run queries to show these accounts are currently excluded

3. **Test Fix Logic**: Run modified queries in development to verify inclusion

### Post-Implementation Validation

1. **Volume Verification**: Compare campaign volumes before/after fix
2. **Account Verification**: Confirm test accounts now appear in appropriate campaigns
3. **Business Logic Check**: Ensure DPD 3-119 allocation still works correctly

## Risk Assessment

### Low Risk Changes
- Logic is additive (includes more accounts rather than excluding)
- Does not affect existing Happy Money (0-7) account handling
- Maintains DPD 3-119 partner allocation as designed

### Mitigation Steps
- Gradual rollout if possible
- Real-time monitoring during first few days
- Easy rollback plan (revert to previous character filtering)

## Business Impact Post-Fix

### Expected Improvements
- **Increased Collections Recovery**: Charge-off accounts return to Happy Money workflow
- **Better Customer Communication**: All customers receive appropriate payment reminders
- **Campaign Optimization**: More complete account coverage for internal campaigns

### Metrics to Monitor
- Call List "Charge off" volume increase
- SMS payment reminder delivery rates
- Collections performance on previously missed SIMM accounts

---

*Technical Implementation Ready*
*Estimated Development Time: 2-4 hours*
*Testing Time: 4-8 hours*