# DI-1246: 1099-C Data Review for Loans Settled in Full in 2025

## Ticket Summary
**Type:** Data Pull
**Status:** In Progress
**Assignee:** kchalmers@happymoney.com
**Created:** 2025-10-02

## Problem Description
Generate list of loans that were settled in full in 2025 for Collections team manual scrub in preparation for sending out 1099-C tax forms.

## Requirements

### Data Criteria
- **Loan Status:** 'Closed-Charged Off' OR 'Closed-Settled in Full'
- **Exclude:** Any accounts with Bankruptcy status
- **Last Recovery Payment Date:** On or after 1/1/2025

### Requested Fields
1. Loan ID
2. Charge Off Date
3. Charge Off Principal
4. Settlement Amount
5. Settlement Status
6. Settlement Completion Date
7. Last Payment Date
8. Total Recovery Amount Received
9. Placement Status
10. Placement Status Start Date

## Solution Approach

### Data Sources Used
1. **BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE**
   - Primary source for recovery payment data, last payment dates, charge-off information
   - Uses PAYOFFUID (mapped to LEAD_GUID) for joining
   - Latest ASOFDATE snapshot used

2. **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT**
   - Settlement amount, status, and completion dates
   - Filtered to 'Closed - Settled in Full' status

3. **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY**
   - Bankruptcy exclusion logic
   - Filtered to MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y' AND ACTIVE = 1

4. **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN**
   - Bridge table for LEAD_GUID mapping between bankruptcy data and loan tape

### Query Logic
1. **Charge-Off Population:** Loans with STATUS = 'Charge off' in loan tape AND LASTPAYMENTDATE >= '2025-01-01'
2. **Settled in Full Population:** Loans with CURRENT_STATUS = 'Closed - Settled in Full' in VW_LOAN_DEBT_SETTLEMENT AND LASTPAYMENTDATE >= '2025-01-01'
3. **Bankruptcy Exclusions:** Remove loans with active bankruptcy status
4. **Combined Results:** UNION ALL of both populations

## Key Findings

### Population Summary
- **Total Loans:** 5,120 loans meeting criteria
- **Charge-Off Population:** 4,891 loans (95.5%)
- **Settled in Full Population:** 229 loans (4.5%)
- **Date Range:** Last payment dates from 2025-01-01 to 2025-10-01
- **Bankruptcy Exclusions:** 487 loans excluded due to active bankruptcy (422 Chapter 13, 58 Chapter 7, 7 unspecified)

### Placement Status Breakdown
- **Placed - HM:** 3,623 loans (70.8%)
- **Placed - Bounce:** 1,143 loans (22.3%)
- **Other Placements:** 354 loans (6.9%)

### Quality Control Results
✅ **No Duplicate Loan IDs:** All 5,120 loans have unique identifiers
✅ **Date Filter Applied:** Zero records with last payment date < 2025-01-01
✅ **No Null Payment Dates:** All records have valid last payment dates
✅ **Bankruptcy Exclusions:** Active bankruptcy accounts successfully excluded

## Assumptions Made

### 1. Bankruptcy Exclusion Definition
**Assumption:** "Exclude any accounts with Bankruptcy status" means exclude only loans with ACTIVE bankruptcy status (MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y' AND ACTIVE = 1).

**Reasoning:**
- Discharged or dismissed bankruptcies are historical and should not block 1099-C reporting
- Only active bankruptcies would prevent debt forgiveness reporting
- VW_LOAN_BANKRUPTCY provides clear active bankruptcy flags

**Impact:** Loans with discharged/dismissed bankruptcies ARE included in the population if they meet other criteria.

### 2. "Closed - Settled in Full" Status Interpretation
**Assumption:** "Closed-Settled in Full" refers to CURRENT_STATUS = 'Closed - Settled in Full' in VW_LOAN_DEBT_SETTLEMENT view.

**Reasoning:**
- Loan tape STATUS field only contains "Charge off" for charged-off loans
- Settlement status is tracked separately in VW_LOAN_DEBT_SETTLEMENT
- CURRENT_STATUS field provides the most accurate settlement state

**Impact:** 229 settled in full loans identified from VW_LOAN_DEBT_SETTLEMENT.

### 3. Recovery Payment Definition
**Assumption:** "Last Recovery Payment Date" = LASTPAYMENTDATE from MVW_LOAN_TAPE, and "Total Recovery Amount Received" = RECOVERYPAYMENTAMOUNT.

**Reasoning:**
- MVW_LOAN_TAPE is the authoritative source for loan tape data per user guidance
- RECOVERYPAYMENTAMOUNT field specifically tracks recovery amounts on charged-off loans
- LASTPAYMENTDATE provides the most recent payment activity

**Impact:** Used loan tape fields directly without additional payment transaction queries.

### 4. Placement Status Source
**Assumption:** PLACEMENT_STATUS and PLACEMENT_STATUS_STARTDATE from MVW_LOAN_TAPE are the authoritative placement status fields.

**Reasoning:**
- Loan tape maintains current placement status
- PLACEMENT_STATUS_STARTDATE tracks when placement began
- No need for portfolio-based placement logic

**Impact:** Direct use of loan tape placement fields in output.

### 5. Data Freshness
**Assumption:** Latest ASOFDATE snapshot from MVW_LOAN_TAPE represents current state as of analysis date (2025-10-02).

**Reasoning:**
- MVW_LOAN_TAPE is a point-in-time snapshot refreshed regularly
- Using MAX(ASOFDATE) ensures most recent data
- Analysis date aligns with ticket creation date

**Impact:** Results reflect loan state as of latest available loan tape date.

## Implementation Details

### Join Strategy
- Used LEAD_GUID (PAYOFFUID in loan tape) for all joins
- LOWER() function applied to LEAD_GUID comparisons for case-insensitive matching
- CAST() to VARCHAR used for consistent data type handling across systems

### Data Type Handling
- LOAN_ID cast to VARCHAR in both UNION branches for consistency
- SETTLEMENT_AMOUNT cast to VARCHAR to match NULL placeholders
- All date fields maintained as DATE type

### Performance Considerations
- Filtered to latest ASOFDATE in loan tape CTE to reduce data volume
- Applied recovery date filter (>= 2025-01-01) early in query
- Used LEFT JOIN for bankruptcy exclusions with WHERE NULL check

## Files and Deliverables

### Final Deliverables
```
final_deliverables/
├── 1_1099c_data_review_query.sql               # Production SQL query for qualifying loans
├── 2_1099c_data_results_5120_loans.csv         # Final dataset (5,120 loans)
├── 3_bankruptcy_excluded_loans_query.sql       # Query for bankruptcy exclusion analysis
└── 4_bankruptcy_excluded_loans_487.csv         # Loans excluded due to bankruptcy (487 loans)
```

### Quality Control
```
qc_queries/
└── 2_simplified_qc.sql                         # QC validation (12 tests, all passed)
```

### Exploratory Analysis
```
exploratory_analysis/
├── 1_1099c_data_review_query.sql               # Development version
├── 1099c_data_results.csv                      # Initial results
├── 2_bankruptcy_excluded_loans.sql             # Bankruptcy analysis development
└── 2_bankruptcy_excluded_loans.csv             # Excluded loans working file
```

### Documentation
```
├── README.md                                   # Complete project documentation
├── CLAUDE.md                                   # Implementation notes and learnings
└── jira_comment.txt                            # Jira update comment
```

## Data Quality Validation

All QC checks passed successfully:
1. ✅ Total Record Count: 5,120 loans
2. ✅ Distinct Loan IDs: 5,120 (no duplicates)
3. ✅ Duplicate Check: 0 duplicates found
4. ✅ Charge Off Population: 4,891 loans
5. ✅ Settled in Full Population: 229 loans
6. ✅ Date Filter Compliance: 0 records before 2025-01-01
7. ✅ Null Date Check: 0 null payment dates
8. ✅ Date Range: 2025-01-01 to 2025-10-01
9. ✅ Placement Status: All loans have valid placement status

### Bankruptcy Exclusion Analysis
- **Total Excluded:** 487 loans with active bankruptcy status
- **Chapter 13:** 422 loans (87% of exclusions)
- **Chapter 7:** 58 loans (12% of exclusions)
- **Plan Confirmed Status:** 395 loans (81% of exclusions)
- All excluded loans documented in `4_bankruptcy_excluded_loans_487.csv`

## Business Impact

This dataset enables the Collections team to:
- Perform manual review of 5,120 loans for 1099-C tax form preparation
- Identify loans with recent recovery payments in 2025
- Exclude active bankruptcy accounts from 1099-C reporting
- Track settlement status and amounts for tax reporting purposes
- Understand placement status for collection coordination

## Next Steps

1. **Collections Team Review:** Manual scrub of 5,120 loans in dataset
2. **1099-C Form Preparation:** Use validated data for tax form generation
3. **Stakeholder Communication:** Provide dataset to Collections team for processing
4. **Documentation:** Archive analysis in repository and Google Drive

## Technical Notes

- **LOANID Format:** LOANID in MVW_LOAN_TAPE is TEXT format (e.g., 'P006624C30FF2'), representing hashed/abbreviated LEAD_GUID
- **Join Complexity:** Required LEAD_GUID bridge through VW_LOAN for bankruptcy exclusions
- **Settlement Data:** VW_LOAN_DEBT_SETTLEMENT may not have complete settlement information for all loans
- **Loan Tape Dependency:** Analysis depends on most recent MVW_LOAN_TAPE snapshot availability

## Related Documentation

- [Data Catalog](../../../documentation/data_catalog.md) - Reference for data sources
- [Data Business Context](../../../documentation/data_business_context.md) - Business rules and definitions
- [CLAUDE.md](../../../CLAUDE.md) - Development standards and guidelines
