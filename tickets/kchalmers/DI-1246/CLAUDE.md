# DI-1246: Claude Code Implementation Notes

## Ticket Context
**Type:** Data Pull
**Purpose:** Generate list of loans for Collections team to manually scrub in preparation for sending 1099-C tax forms

## Data Requirements
- **Status:** 'Closed-Charged Off' OR 'Closed-Settled in Full'
- **Exclude:** Any accounts with Bankruptcy status
- **Last Recovery Payment Date:** On or after 1/1/2025

## Implementation Approach

### Data Source Selection
Used MVW_LOAN_TAPE as the authoritative source per user guidance, with supplementary joins to:
- VW_LOAN_DEBT_SETTLEMENT for settlement data
- VW_LOAN_BANKRUPTCY for bankruptcy exclusions
- VW_LOAN for LEAD_GUID mapping

### Key Technical Decisions

**1. Bankruptcy Exclusion Logic**
- Interpreted "exclude any accounts with Bankruptcy status" as active bankruptcies only
- Used `MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y' AND ACTIVE = 1`
- Rationale: Discharged/dismissed bankruptcies are historical and shouldn't block 1099-C reporting

**2. Join Strategy**
- Used LEAD_GUID (PAYOFFUID in loan tape) for all joins
- MVW_LOAN_TAPE.LOANID is TEXT format (e.g., 'P006624C30FF2'), not usable for direct joins
- Required LEAD_GUID bridge through VW_LOAN for bankruptcy data

**3. Settlement Status Handling**
- Loan tape STATUS only shows "Charge off" for charged-off loans
- Settlement status comes from VW_LOAN_DEBT_SETTLEMENT.CURRENT_STATUS
- Used UNION ALL to combine both populations

### Data Quality Insights

**Population Breakdown:**
- 5,120 total loans identified
- 4,891 Charge-Off loans (95.5%)
- 229 Settled in Full loans (4.5%)

**Validation Results:**
- Zero duplicate loan IDs
- All records have last payment date >= 2025-01-01
- No active bankruptcy accounts included
- All loans have valid placement status

### Technical Challenges Resolved

**1. Ambiguous Column Names**
Initial query had `LOAN_ID` ambiguity in bankruptcy_exclusions CTE. Fixed by explicitly qualifying with table alias: `vb.LOAN_ID`

**2. Data Type Mismatches**
UNION branches had different data types for LOAN_ID and SETTLEMENT_AMOUNT. Resolved by casting to VARCHAR for consistency.

**3. CSV Output Cleaning**
SQL statement outputs ("Statement executed successfully") appeared in CSV. Cleaned using:
```bash
grep -v "^Statement executed successfully" file.csv | grep -v "^$" > cleaned.csv
```

### Query Structure

**CTEs Used:**
1. `latest_loan_tape` - Latest snapshot from MVW_LOAN_TAPE
2. `charged_off_loans` - Charge-off loans with 2025 recovery payments
3. `settled_in_full_loans` - Settled in full status from debt settlement view
4. `bankruptcy_exclusions` - Active bankruptcy loans to exclude
5. `combined_population` - UNION of charge-off and settlement populations

### Fields Delivered
All 10 requested fields provided:
- Loan ID (from loan tape LOANID, cast to VARCHAR)
- Charge Off Date (CHARGEOFFDATE)
- Charge Off Principal (PRINCIPALBALANCEATCHARGEOFF)
- Settlement Amount (SETTLEMENTAGREEMENTAMOUNT)
- Settlement Status (SETTLEMENTSTATUS)
- Settlement Completion Date (SETTLEMENT_COMPLETION_DATE)
- Last Payment Date (LASTPAYMENTDATE)
- Total Recovery Amount (RECOVERYPAYMENTAMOUNT)
- Placement Status (PLACEMENT_STATUS)
- Placement Status Start Date (PLACEMENT_STATUS_STARTDATE)

## Key Learnings

1. **MVW_LOAN_TAPE LOANID Format:** LOANID in loan tape is TEXT format representing hashed/abbreviated LEAD_GUID, not suitable for joins with other systems

2. **Settlement vs Charge-Off Status:** These are tracked in separate systems - loan tape for charge-offs, VW_LOAN_DEBT_SETTLEMENT for settlements

3. **Bankruptcy Filtering:** Active bankruptcy determination requires joining multiple tables (VW_LOAN_BANKRUPTCY → VW_LOAN → loan tape)

4. **CSV Output Quality:** Always strip SQL execution messages from CSV outputs for clean deliverables

## Files Delivered

### Final Deliverables
- `1_1099c_data_review_query.sql` - Production-ready SQL query
- `2_1099c_data_results_5120_loans.csv` - Clean CSV with 5,120 loans

### Quality Control
- `qc_queries/2_simplified_qc.sql` - 12 validation tests (all passed)

### Documentation
- `README.md` - Complete analysis documentation
- `CLAUDE.md` - Implementation notes (this file)

## Recommendations for Future Work

1. **Data Source Standardization:** Consider creating a unified view that combines loan tape, settlement, and bankruptcy data to simplify similar queries

2. **Recovery Payment Definition:** Clarify business definition of "recovery payment" vs regular payments for consistency across analyses

3. **1099-C Workflow:** Document complete 1099-C workflow including data extraction, manual review, and form generation steps

## Business Impact

This dataset enables Collections team to:
- Perform targeted manual review of 5,120 loans
- Identify loans with recent recovery activity in 2025
- Properly exclude active bankruptcy accounts from 1099-C reporting
- Track settlement amounts and status for tax reporting accuracy
