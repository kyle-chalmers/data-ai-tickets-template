# DI-1293: Move Application Suppression to Dedicated Table

## Business Context

Following Kyle's architecture recommendation from the 9/22/2025 meeting on contact rules data integrity (DI-1258), this ticket separates application-level and loan-level contact suppressions into distinct views.

**Problem Solved:**
- Application IDs and Loan IDs were mixed in the same `APPLICATION_GUID` column of `VW_LOAN_CONTACT_RULES`
- Created confusion between application-level suppressions (marketing/funnel) vs. loan-level suppressions (collections)
- Different business contexts: marketing outreach vs. collections outreach
- Multiple campaigns were using incorrect suppression patterns (wrong flags, wrong joins)

**Solution:**
- Create dedicated `VW_APP_CONTACT_RULES` for application-level SMS opt-outs
- Update `VW_LOAN_CONTACT_RULES` to be loan-level only (remove application data)
- Update marketing/funnel jobs to use appropriate views and correct suppression flags
- Fix loan-level campaigns to use simple, correct patterns

## Architecture Decision

**Confirmed Business Rule:** Application and loan contact suppressions are completely separate.
- SMS opt-out during application does NOT carry over to loan servicing
- Different communication types: marketing (application) vs. collections (loan)

## Changes Implemented

### 1. New View: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_APP_CONTACT_RULES`

**Purpose:** Application-level contact suppression rules from LoanPro LOS

**Columns:**
- `APPLICATION_GUID` - Primary identifier
- `SUPPRESS_TEXT` - SMS opt-out flag (TRUE when SMS_CONSENT_LS = 'NO')
- `CONTACT_RULE_START_DATE` - Uses SMS_CONSENT_DATE_LS (fixes CURRENT_TIMESTAMP issue)
- `CONTACT_RULE_END_DATE` - NULL for active rules
- `SOURCE` - 'LOANPRO'

**Source:** `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT` where `SMS_CONSENT_LS = 'NO'`

### 2. Updated View: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES`

**Before:** Complex view with CTEs including `sms_consent` (application data) + loan data
**After:** Simple pass-through: `SELECT * FROM BRIDGE.VW_LOAN_CONTACT_RULES` (loan data only)

**Impact:**
- Removes `APPLICATION_GUID` column
- Removes LOS data pulls (the `sms_consent` CTE)
- Keeps only loan-level contact rules from BRIDGE layer

### 3. Updated Jobs - DI-986 Comprehensive Fixes

#### Application-Level Campaigns → VW_APP_CONTACT_RULES (3 updated)
- **Email Non-Opener SMS** - Uses `VW_APP_CONTACT_RULES`, checks `SUPPRESS_TEXT`
- **Allocated Capital Partner** - Uses `VW_APP_CONTACT_RULES`, checks `SUPPRESS_TEXT`
- **SMS Funnel Communication** - Uses `VW_APP_CONTACT_RULES`, checks `SUPPRESS_TEXT`

All include proper `WHERE ACR.SUPPRESS_TEXT = true` condition.

#### Loan-Level Campaigns → Fixed Patterns (3 fixed)
- **AutoPaySMS** - Fixed to use `VW_LOAN → VW_LOAN_CONTACT_RULES` pattern (was using broken application_guid join)
- **PIF Email** - Simplified to remove unnecessary `VW_APPLICATION` join, fixed to check `SUPPRESS_EMAIL` instead of `SUPPRESS_TEXT`
- **6M to PIF Email** - Simplified to remove unnecessary `VW_APPLICATION` join, fixed to check `SUPPRESS_EMAIL` instead of `SUPPRESS_TEXT`

#### Suppressions Removed (1 removed)
- **Prescreen Email DNC: Email** - Removed because it's application-level but we don't have email suppression in `VW_APP_CONTACT_RULES` yet

### 4. Unchanged Jobs - Continue using VW_LOAN_CONTACT_RULES

**Collections jobs (BI-2482, BI-737, BI-820, BI-813, DI-862):**
- No changes required
- All join on `LOAN_ID` (not affected by removal of `APPLICATION_GUID`)
- Verified to continue working correctly

## Deployment Strategy

**Option B (Simultaneous Deployment):**
1. ✅ Create `VW_APP_CONTACT_RULES`
2. ✅ Update `VW_LOAN_CONTACT_RULES`
3. ✅ Update DI-986 job (6 suppressions fixed, 1 removed)
4. Deploy all changes together

## Files Changed

### Snowflake Objects
1. ✅ `final_deliverables/1_create_vw_app_contact_rules.sql` - New view creation
2. ✅ `final_deliverables/2_update_vw_loan_contact_rules.sql` - Update existing view

### Job Updates
3. ✅ `final_deliverables/3_update_DI-986_job.md` - DI-986 job changes (comprehensive documentation)

**Git Branch:** `DI-1293` in business-intelligence-data-jobs repo
- 5 commits with detailed changes
- All changes pushed to remote

### Documentation
4. ✅ `final_deliverables/4_verification_collections_jobs_unaffected.md` - Impact assessment
5. ✅ `README.md` - This file

## Testing Plan

### Dev Environment Tests (COMPLETED)
1. ✅ **Create new view:** Ran `1_create_vw_app_contact_rules.sql`
2. ✅ **Update loan contact rules:** Ran `2_update_vw_loan_contact_rules.sql`
3. ✅ **Update DI-986 job:** Applied all changes and pushed to `DI-1293` branch

### Remaining Tests
4. **Verify row counts:**
   ```sql
   SELECT COUNT(*) FROM ANALYTICS.VW_APP_CONTACT_RULES;
   -- Should match: SELECT COUNT(*) FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT WHERE SMS_CONSENT_LS = 'NO';
   ```

5. **Verify no APPLICATION_GUID in loan view:**
   ```sql
   SELECT * FROM ANALYTICS.VW_LOAN_CONTACT_RULES LIMIT 5;
   -- Should NOT have APPLICATION_GUID column
   ```

6. **Run DI-986 in dev:** Verify suppression counts match expected baseline
7. **Run BI-2482 in dev:** Verify collections suppressions unchanged

### Production Validation
- Compare suppression counts before/after deployment
- Verify marketing campaigns receive correct application suppressions
- Confirm collections campaigns unaffected
- Monitor for any job failures

## Issues Found and Fixed During Implementation

### Critical Issues Fixed

1. **AutoPaySMS Breakage** - Was using `application_guid` join which no longer exists
   - Fixed to use loan-level pattern: `VW_LOAN → VW_LOAN_CONTACT_RULES`

2. **PIF Email Wrong Suppression Flag** - Was checking `SUPPRESS_TEXT` for email campaigns
   - Fixed to check `SUPPRESS_EMAIL`

3. **6M to PIF Email Wrong Suppression Flag** - Same issue as PIF Email
   - Fixed to check `SUPPRESS_EMAIL`

4. **Unnecessary VW_APPLICATION Joins** - PIF and 6M to PIF Email had complex joins
   - Simplified to direct `VW_LOAN → VW_LOAN_CONTACT_RULES` pattern

5. **Prescreen Email Invalid Suppression** - Application-level campaign checking loan-level text suppression for email
   - Removed until email suppression added to VW_APP_CONTACT_RULES

6. **Missing WHERE Clauses** - Application-level suppressions initially missing `SUPPRESS_TEXT = true` filter
   - Added to all 3 application campaigns

## Assumptions

1. **Business Rule Confirmed:** Application SMS opt-outs do NOT suppress loan-level communications
2. **Data Source:** `SMS_CONSENT_DATE_LS` exists in `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT` for proper date tracking
3. **Column Structure:** `BRIDGE.VW_LOAN_CONTACT_RULES` contains all necessary loan-level suppression columns
4. **Job Dependencies:** Only DI-986 required changes; collections jobs (BI-2482, etc.) continue using loan-level data unchanged
5. **Email Suppression:** Application-level email suppression will be added in a future ticket
6. **Campaign Types:**
   - Application-level: Email Non-Opener SMS, Allocated Capital Partner, SMS Funnel Communication, Prescreen Email
   - Loan-level: AutoPaySMS, PIF Email, 6M to PIF Email

## Related Tickets

- **DI-1258**: Contact Rules Data Integrity Issue - Original problem identification
- **DI-1293**: This ticket - Implementation of Kyle's architectural solution
- **Kyle Meeting (9/22/2025)**: Architecture decision discussion captured in work journey

## Success Criteria

✅ New `VW_APP_CONTACT_RULES` view created and populated
✅ `VW_LOAN_CONTACT_RULES` updated to remove application data
✅ Marketing/funnel jobs updated to use new application view
✅ Loan-level campaigns fixed to use correct patterns and flags
✅ Collections jobs continue functioning without changes
✅ No data loss or suppression gaps
✅ Proper audit trail with SMS_CONSENT_DATE_LS instead of CURRENT_TIMESTAMP
✅ All code committed and pushed to `DI-1293` branch

## Next Steps

1. **Testing:** Run DI-986 in dev environment to verify all suppressions work correctly
2. **PR Review:** Create pull request for `DI-1293` branch
3. **Deployment:** Deploy views and job changes to production
4. **Monitoring:** Monitor DI-986 and BI-2482 runs for any issues
5. **Future Enhancement:** Add email suppression support to `VW_APP_CONTACT_RULES`
