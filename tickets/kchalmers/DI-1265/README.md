# DI-1265: Referral Program Awareness Email Campaign Audience List - September 30, 2025

## Business Context
Generate audience list for Customer Referral Program email campaign. Stakeholder requested list generation for 9/30/2025 as automated monthly process was not yet set up.

## Requirements
- **Target Audience**: Current customers in good standing
- **Loan Criteria**: Active loans, not closed, not charged off, less than 3 days past due
- **Exclusions**: Cease and desists, email suppression flags
- **Delivery Date**: September 30, 2025

## Related Tickets
- **DI-905**: Original referral program audience list (May/June 2025)

## Deliverables
1. **2_AUDIENCE_LIST_FOR_CUSTOMER_REFERRAL_EMAIL_CAMPAIGN_2025-09-30.csv**
   - 11,598 customers eligible for referral program email campaign
   - Includes: Email, LOS/LMS Customer IDs, PayoffUID, Loan Status, Application ID, Name, State

2. **1_audience_list_query.sql**
   - SQL query to generate audience list
   - Simplified from DI-905 version (removed SFMC opt-outs CTE for performance)

3. **qc_queries/1_record_counts_and_duplicates.sql**
   - Quality control validation queries
   - Verified no duplicate records across all key identifiers

## Assumptions Made

1. **SFMC Unsubscribe Handling**: Removed complex SFMC opt-outs suppression CTE from original DI-905 query
   - **Reasoning**: CTE was causing significant performance issues (queries timing out after 10+ minutes)
   - **Context**: When tested independently, the SFMC unsubscribes filter matched 0 current customers
   - **Impact**: SFMC will handle unsubscribe scrubbing on their end as originally specified in requirements

2. **Loan Status Filter**: Customers must have less than 3 days past due (DPD < 3)
   - **Reasoning**: Follows "good standing" requirement from original DI-905 specification
   - **Context**: Ensures only current, actively repaying customers are included
   - **Impact**: Filters out customers who may be experiencing payment difficulties

3. **Email Suppression Logic**: Used VW_LOAN_CONTACT_RULES for cease and desist and email suppression flags
   - **Reasoning**: This view provides the authoritative source for contact preferences
   - **Context**: Filters customers who have requested no contact or email communication
   - **Impact**: Ensures compliance with customer communication preferences

4. **Customer Growth**: List contains 11,598 customers vs 6,055 in June 2025 (91% increase)
   - **Reasoning**: Significant portfolio growth between June and September 2025
   - **Context**: More loans in "Open - Repaying" status with good standing
   - **Impact**: Larger audience for referral program campaign

## QC Results

**Record Counts** (all metrics match - no duplicates):
- Total Records: 11,598
- Distinct PAYOFFUIDs: 11,598
- Distinct LOS Customers: 11,598
- Distinct LMS Customers: 11,598
- Distinct Application IDs: 11,598
- Distinct Emails: 11,598

**Duplicate Checks**: ✅ PASSED
- No duplicate PAYOFFUIDs
- No duplicate emails
- No duplicate customer IDs

## Technical Notes

**Query Performance**:
- Original complex query with SFMC opt-outs CTE: 10+ minutes, frequent timeouts
- Simplified query without SFMC CTEs: 17.3 seconds
- Performance improvement: ~35x faster

**Data Architecture**:
- Uses ANALYTICS and BRIDGE layers following 5-layer architecture
- Properly filters by LOS_SCHEMA() for LoanPro application objects
- Joins on current loan status (CURRENT_DATE)

**Comparison to June 2025**:
- June 2025: 6,055 customers
- September 2025: 11,598 customers
- Growth: +5,543 customers (+91%)