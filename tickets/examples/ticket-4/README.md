# ticket-4: Quarterly InvestorPartner Due Diligence for Collections | 2025 Q3

## Ticket Summary
**Type:** Data Pull
**Status:** In Spec
**Assignee:** analyst@example.com
**Created:** 2025-10-10
**Due Date:** 2025-10-10

## Problem Description
InvestorPartner Q3 2025 Diligence Review requires collection activity data (dialer, manual dials, emails, letters, SMS text, etc.) and collection notes for the accounts listed in the 'Attachment C' tab of the provided Excel file.

## Requirements
- **Input:** 15 loans from "Attachment C" tab in provided Excel file
- **Output:** Collection activity across 5 data sources (ContactCenter phone/SMS/email, Loan Notes, email_platform email)
- **Timeline:** Data delivery by 10/10 to allow Ops teams QA ahead of deadline
- **Time Period:** Q3 2025 (July 1 - September 30, 2025)

## Approach
1. Extract 15 PAYOFFUIDs from Attachment C tab
2. Build helper table for PAYOFFUID/email/phone lookup (handles PAYOFFUID changes over time)
3. Generate 5 collection activity queries adapted from DI-1064 predecessor work
4. Apply Q3 2025 date filters to interaction data
5. Execute queries and deliver CSV outputs with QC validation

## Stakeholders
- **Requestor:** TBD (InvestorPartner quarterly diligence)
- **QA Teams:** Ops teams
- **Related Work:** DI-1064 (Tin Nguyen), DI-1065 (Data Analyst - Q2 payment history)

## Files

### Source Materials (`source_materials/`)
- `IRL and Sample Selections (FinanceCo) 2025.10 (2).xlsx` - Original InvestorPartner Excel file
- `attachment_c_15_loans.csv` - Extracted 15 PAYOFFUIDs from Attachment C

### Final Deliverables (`final_deliverables/`)
- `fortress_q3_2025_collection_activity.sql` - Complete SQL with all 5 queries
- `1_fortress_q3_2025_genesys_phonecall_activity.csv` - Phone call interactions
- `2_fortress_q3_2025_genesys_sms_activity.csv` - SMS interactions
- `3_fortress_q3_2025_genesys_email_activity.csv` - Email interactions
- `4_fortress_q3_2025_loan_notes.csv` - Collection notes (all dates)
- `5_fortress_q3_2025_sfmc_email_activity.csv` - Marketing email activity
- `qc_queries/` - Quality control validation queries

## Assumptions Made

### 1. **Scope**: All 15 loans from Attachment C
**Reasoning:** Ticket specifically references "Attachment C" tab
**Context:** Excel file contains 15 loans with PAYOFFUIDs in Attachment C
**Impact:** Query will process exactly 15 loans

### 2. **Time Period**: Q3 2025 = July 1, 2025 through September 30, 2025
**Reasoning:** Ticket title specifies "2025 Q3"
**Context:** Standard quarterly reporting period
**Impact:** All date-based queries filter interactions to this 3-month window

### 3. **Loan Status**: Include all activity regardless of current loan status
**Reasoning:** Collection activity is historical point-in-time data
**Context:** Unlike DI-1064 which filtered for open loans, this ticket requires complete activity history
**Impact:** Removed `loan_closed_date > current_date` filter from queries

### 4. **Loan Notes Date Range**: All dates (not filtered to Q3)
**Reasoning:** Collection notes provide full loan history context
**Context:** Following DI-1064 pattern where notes were not date-restricted
**Impact:** Loan notes query returns all notes for the 15 loans

### 5. **email_platform Email Filters**: Campaign = 'delinquent', Event Type = 'Sent'
**Reasoning:** Consistent with DI-1064 approach for collections-related emails
**Context:** Focus on sent delinquent collection emails, not all marketing emails
**Impact:** email_platform query filters to relevant collection email activity

### 6. **PAYOFFUID Lookup Method**: Use helper table approach for email/phone matching
**Reasoning:** ContactCenter views sometimes capture incorrect/old PAYOFFUIDs
**Context:** DI-1064 established this pattern; issue not yet resolved
**Impact:** Queries use temp tables to match by email/phone with date ranges

### 7. **legacy_contact_platform Data**: Excluded from deliverables
**Reasoning:** Per user confirmation, legacy_contact_platform data not relevant
**Context:** Historical system no longer in use for current collection activity
**Impact:** 5 outputs instead of 6 from DI-1064 template

### 8. **Warehouse**: Use BUSINESS_INTELLIGENCE_LARGE
**Reasoning:** Per user instruction for better query performance
**Context:** Collection activity queries join large PII tables
**Impact:** All queries execute on larger warehouse for efficiency

## Technical Implementation

### Helper Table Logic
Following DI-1064 pattern:
1. Create temp table with all PAYOFFUIDs (current and historical) for each email/phone
2. Use non-equi date joins to match interaction dates to correct loan lifecycle
3. Handles PAYOFFUID changes when customers have multiple loans over time

### Query Structure
- Step 1: Define PAYOFFUID parameter list
- Step 2: Build loan lookup helper table with email/phone numbers
- Step 3: Create PAYOFFUID dimension table for date-based matching
- Step 4-8: Execute 5 collection activity queries with proper joins

## Analysis Results

### Collection Activity Summary (Q3 2025)
**Total Records:** 1,333 collection activity records across 5 data sources

| Data Source | Records | Loans Covered | File |
|-------------|---------|---------------|------|
| ContactCenter Phone Calls | 121 | 11 | 1_fortress_q3_2025_genesys_phonecall_activity.csv |
| ContactCenter SMS | 96 | 10 | 2_fortress_q3_2025_genesys_sms_activity.csv |
| ContactCenter Email | 14 | 9 | 3_fortress_q3_2025_genesys_email_activity.csv |
| Loan Notes (All Dates) | 945 | 15 | 4_fortress_q3_2025_loan_notes.csv |
| email_platform Email Activity | 157 | 9 | 5_fortress_q3_2025_sfmc_email_activity.csv |

### Key Findings
- **All 15 loans** have loan note records (complete history)
- **11 loans** had phone call activity during Q3 2025
- **10 loans** had SMS activity during Q3 2025
- **9 loans** had both ContactCenter email and email_platform email activity
- **Loan notes** not restricted to Q3 - full history provided for context

### Quality Control
- ✓ All 5 CSV files generated successfully with proper headers
- ✓ Record counts validated against query results
- ✓ Date filters verified (Q3 2025: July 1 - Sept 30, 2025)
- ✓ PAYOFFUID helper table approach working correctly
- ✓ File sizes range from 5.9K to 46K

## Status Updates
- **2025-10-13 16:00:** Ticket initiated, folder structure created, PAYOFFUIDs extracted
- **2025-10-14 00:07:** All 5 CSV files generated, QC validation complete
