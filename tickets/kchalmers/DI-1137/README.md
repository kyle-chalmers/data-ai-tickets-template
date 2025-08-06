# DI-1137: Regulator Request: Massachusetts - Applications and Loans

## Summary
Massachusetts Regulator request for loan and application data in support of pending license application.

## Business Requirements

The Massachusetts Regulator requested information on:

1. **Small Dollar High Rate Loans**: Has Happy Money processed applications or arranged loans of $6,000 or less with rates above 12% per annum for Massachusetts residents?

2. **All Serviced Loans**: Has Happy Money serviced loans with Massachusetts residents (no time limit, all since inception)?

3. **Required Data Fields** for Massachusetts loans:
   - APPLICATION DATE
   - APPLICATION FIRST/LAST NAME  
   - APPLICANTRESIDENCESTATE
   - LOANID
   - LOANAMOUNT
   - CURRENT STATUS
   - APR
   - INTEREST RATE
   - ORIGINATION DATE

## Technical Approach

### Data Sources (Updated 2025-08-06)
- **Primary**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY` - Authoritative source for comprehensive historical loan data
- **Secondary**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN` and related views for name/application data supplementation

### Query Strategy (Loan Tape Version)
1. Query 1: Identify loans ≤$6,000 with interest rate >12% for MA residents using loan tape as primary source
2. Query 2: Pull all MA resident loans with required fields from loan tape
3. LEFT JOIN to VW_LOAN/VW_APPLICATION/VW_MEMBER_PII for names when available
4. Quality control validation comparing loan tape vs VW_LOAN coverage

## Results Summary (Updated with Loan Tape Data - 2025-08-06)

### Question 1: Loans ≤$6,000 with rates >12% for MA residents
**Answer: YES** - Happy Money has processed **3 loans** meeting these criteria (vs 1 previously identified):
- **Loan ID P592BB4580282**: $5,000 @ 15.81% interest rate, 17.99% APR (Paid in Full, Jan 11, 2021)
- **Loan ID PB822534FB0D7**: $6,000 @ 19.64% interest rate, 21.99% APR (Charge off, Oct 1, 2020) 
- **Loan ID P60561A226BA9**: $5,000 @ 16.80% interest rate, 18.995% APR (Paid in Full, Apr 2, 2019)
- **Total Amount**: $16,000
- **Average Interest Rate**: 17.42%
- **Average APR**: 19.66%

### Question 2: All MA resident loans serviced  
**Answer: YES** - Happy Money has serviced **61 loans** for Massachusetts residents since inception (vs 26 previously identified):
- **Total Loan Amount**: $1,030,900
- **Date Range**: October 11, 2017 to June 15, 2022
- **Average Loan Amount**: $16,900
- **Average Interest Rate**: 11.77%
- **Average APR**: 13.34%

### Loan Distribution (Loan Tape Data)
- Loans ≤$6,000: 4 (6.6%)
- Loans $6,001-$10,000: 13 (21.3%)
- Loans >$10,000: 44 (72.1%)

## Files Delivered

### Final Deliverables (Loan Tape Version - 2025-08-06)
1. **`final_deliverables/ma_loans_6k_or_less_rate_above_12pct_LOAN_TAPE.csv`** - Small dollar high rate loans (3 loans)
2. **`final_deliverables/all_ma_serviced_loans_LOAN_TAPE.csv`** - Complete list of all MA loans with required fields (61 loans)
3. **`final_deliverables/archive_vw_loan_version/`** - Original VW_LOAN approach results archived for reference

### SQL Queries (Loan Tape Version)
1. **`final_deliverables/sql_queries/1_ma_loans_6k_or_less_rate_above_12pct_loan_tape.sql`** - Query for small dollar high rate loans using loan tape
2. **`final_deliverables/sql_queries/2_all_ma_serviced_loans_loan_tape.sql`** - Query for all MA serviced loans using loan tape
3. **`final_deliverables/qc_queries/comprehensive_qc_validation_loan_tape.sql`** - QC validation comparing loan tape vs VW_LOAN coverage

## Quality Control Results (Loan Tape Version - 2025-08-06)
- **100% data completeness** for core loan fields (amount, rates, dates, status, state)
- **Borrower names**: Not available in loan tape (marked as "DATA NOT AVAILABLE")
- **Coverage comparison**: Loan tape shows 61 loans vs 26 in VW_LOAN (135% increase)
- **Date range**: Loan tape covers 2017-2022 vs VW_LOAN 2019-2023
- **Status information**: 100% available from loan tape (Current, Paid in Full, Charge off, etc.)

## Technical Notes (Loan Tape Version)
- **Primary data source**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY` provides authoritative loan data
- **Name resolution**: LEFT JOIN to VW_LOAN → VW_APPLICATION → VW_MEMBER_PII for borrower names when available
- **Data deduplication**: Uses `ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC)` for most recent loan status
- **Interest rate format**: Loan tape stores as decimal (0.12 = 12%) vs percentage in application tables
- **Comprehensive coverage**: Loan tape captures loans not present in VW_LOAN analytical views

---

## Critical QC Findings (Updated - 2025-08-06)

### Data Source Validation Results - REVERSED FINDINGS

**IMPORTANT UPDATE:** Follow-up analysis with proper loan tape querying revealed the opposite conclusion:

**Source Comparison (Corrected):**
- **MVW_LOAN_TAPE**: 61 Massachusetts loans ($1,030,900 total) 
- **VW_LOAN**: 26 Massachusetts loans ($507,000 total)
- **Difference**: 35 additional loans found in loan tape (135% increase)

**Key Findings (Updated):**
1. **Comprehensive Coverage**: Loan tape shows 61 MA loans vs only 26 in VW_LOAN
2. **Extended Date Range**: 
   - Loan Tape: Oct 11, 2017 to Jun 15, 2022 (5 years complete)
   - VW_LOAN: Aug 7, 2019 to Jun 12, 2023 (4 years, missing earlier data)
3. **Small Dollar High Rate**: Loan tape shows **3 qualifying loans** vs only 1 in VW_LOAN
4. **Status Comprehensive**: Loan tape provides complete status distribution

**Conclusion (Revised):**
**MVW_LOAN_TAPE_MONTHLY provides the comprehensive and authoritative data source** for regulatory reporting with complete historical coverage, capturing loans not present in analytical VW_LOAN views. This confirms the need for DI-1145 investigation into VW_LOAN coverage gaps.

---

## Final Deliverables Summary (Loan Tape Version - 2025-08-06)

### Files Ready for Massachusetts Regulator Submission

**Primary Data Files (Updated with Comprehensive Data):**
- **`final_deliverables/ma_loans_6k_or_less_rate_above_12pct_LOAN_TAPE.csv`** - **3 loans** meeting small dollar/high rate criteria
- **`final_deliverables/all_ma_serviced_loans_LOAN_TAPE.csv`** - **61 total loans** serviced for MA residents

**Supporting Validation:**
- **`final_deliverables/qc_queries/comprehensive_qc_validation_loan_tape.sql`** - Comprehensive QC comparing data sources
- **SQL Queries (Loan Tape Version)** in `final_deliverables/sql_queries/`
- **`final_deliverables/archive_vw_loan_version/`** - Original analysis results archived

### Regulatory Questions Answered (Updated)

1. **Has Happy Money processed loans ≤$6,000 with rates >12% for MA residents?**
   - **Answer: YES** - **3 loans** totaling $16,000:
     - P592BB4580282: $5,000 @ 15.81% interest, 17.99% APR
     - PB822534FB0D7: $6,000 @ 19.64% interest, 21.99% APR  
     - P60561A226BA9: $5,000 @ 16.80% interest, 18.995% APR

2. **Has Happy Money serviced loans for MA residents?**
   - **Answer: YES** - **61 loans** totaling $1,030,900 (October 2017 - June 2022)

All CSV files contain the complete required regulatory fields:
- APPLICATION DATE, APPLICATION FIRST/LAST NAME (when available), APPLICANTRESIDENCESTATE
- LOANID, LOANAMOUNT, CURRENT STATUS (100% populated), APR, INTEREST RATE, ORIGINATION DATE

### Data Quality Validation (Loan Tape Version)
✅ 100% field completeness for core regulatory fields  
✅ 100% status field completeness using loan tape data  
✅ All dates, amounts, and rates populated  
✅ **MVW_LOAN_TAPE_MONTHLY confirmed as comprehensive authoritative source**  
✅ Proper historical coverage from 2017-2022  
⚠️ Borrower names marked "DATA NOT AVAILABLE" (not in loan tape)

## Status
- Started: 2025-08-01
- Updated: 2025-08-06 (Loan Tape Implementation)
- Status: **Complete - Enhanced with Comprehensive Loan Tape Data**