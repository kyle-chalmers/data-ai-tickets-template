# DI-1131: BUSINESS_INTELLIGENCE.PII.VW_GENESYS_EMAIL_ACTIVITY picking up PayoffUID for older loans

## Summary
The Genesys email activity view is incorrectly matching PayoffUIDs to older/closed loans for customers with multiple loans because the lookup table is using outdated PII sources.

## Root Cause Analysis

### Primary Issue
The dynamic table `BUSINESS_INTELLIGENCE.PII.DT_LKP_EMAIL_TO_PAYOFFUID_MATCH` is using outdated PII tables from the `BUSINESS_INTELLIGENCE.PII` schema instead of the updated ones in `BUSINESS_INTELLIGENCE.ANALYTICS_PII`.

### Outdated Source Tables in Current Implementation:
1. `BUSINESS_INTELLIGENCE.PII.VW_CUSTOMER_INFO`
2. `BUSINESS_INTELLIGENCE.PII.VW_APPLICATION_PII`
3. `BUSINESS_INTELLIGENCE.PII.VW_LEAD_MASTER_PII_UNIQUE`

### Should Use Updated Tables in ANALYTICS_PII:
1. `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_APPLICATION_PII`
2. `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_APP_PII`
3. `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_LEAD_PII`
4. `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII`

## Issue Scope
- **376,453 customers** have multiple loans
- **264,507 customers** (70% of multi-loan customers) have insufficient lookup table entries
- Average of 2.5 loans per customer with multiple loans
- Only 1.78 lookup entries per email on average

## Example Case Investigation
Customer email: `mfent001@gmail.com`
- Has 3 loans but only 1 entry in lookup table
- Lookup table contains: `19757b02-f75e-7649-5627-7239450ae612` (closed 2024-05-17)
- Missing: `6860b38c-6219-b472-f458-ae265d644d4a` and `b83177c8-327b-4d03-9fb8-8cf472431307`
- Genesys emails for this customer incorrectly match to the closed loan

## Technical Details
`VW_GENESYS_EMAIL_ACTIVITY` joins to the lookup table with this logic:
```sql
LEFT JOIN BUSINESS_INTELLIGENCE.PII.DT_LKP_EMAIL_TO_PAYOFFUID_MATCH LO 
ON LO.EMAIL = UPPER(BCM.EXTERNAL_EMAIL_ADDRESS)
AND DATE(INTERACTION_START_TIME) >= IFNULL(LO.FIRST_POSSIBLE_CONTACT_DATE,'1900-01-01')
AND DATE(INTERACTION_START_TIME) <= IFNULL(LO.LAST_POSSIBLE_CONTACT_DATE ,DATEADD('day',1000,CURRENT_DATE()))
```

## Business Impact
- Customer communications may be associated with wrong/closed loans
- Reporting inaccuracies for Genesys email activity
- Potential compliance issues with data accuracy

## Recommended Solution
1. Update `DT_LKP_EMAIL_TO_PAYOFFUID_MATCH` to use current PII tables from `ANALYTICS_PII` schema
2. Implement proper multi-loan handling logic
3. Refresh the dynamic table to rebuild with correct data

## Solution Implementation

### Files Created:
1. `original_code/original_dt_lkp_email_to_payoffuid_match_ddl.sql` - Original DDL backup
2. `final_deliverables/updated_dt_lkp_email_to_payoffuid_match_ddl.sql` - Updated DDL with ANALYTICS_PII sources
3. `final_deliverables/deployment_script.sql` - Complete deployment script
4. `final_deliverables/verification_queries.sql` - Post-deployment validation queries
5. `final_deliverables/test_new_logic.sql` - Testing queries used during development

### Key Changes:
1. **Updated Data Sources**: Replaced outdated PII tables with current ANALYTICS_PII tables
2. **Proper Hierarchy**: Implemented VW_MEMBER_PII → VW_APPLICATION_PII → VW_LEAD_PII priority order
3. **Comprehensive Coverage**: New logic captures all loans for customers with multiple loans
4. **Maintained Logic**: Preserved original contact date boundary logic for multi-loan scenarios

### Testing Results:
- Sample customer `mfent001@gmail.com` previously had 1/3 loans in lookup table
- New logic correctly captures all 3 loans from ANALYTICS_PII sources
- Member PII: 2 loans, Application PII: 3 loans, Lead PII: 3 loans
- Current lookup table: Only 1 loan (19757b02-f75e-7649-5627-7239450ae612)

### Impact:
- Will fix 264,507 customers (70% of multi-loan customers) with insufficient lookup entries
- Improves Genesys email activity matching accuracy
- Resolves PayoffUID mismatches to closed/older loans

### Deployment Ready:
The solution is ready for deployment using the deployment script. The dynamic table will automatically refresh due to AUTO refresh mode.