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

### Data Sources
- **Primary**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE` - Authoritative source for comprehensive historical loan data
- **Secondary**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN` and related views for current state data supplementation

### Query Strategy
1. Identify loans ≤$6,000 with interest rate >12% for MA residents (native origination)
2. Identify current MA residents with loans ≤$6,000 and rates >12% (current residence)
3. Pull all native MA resident loans with required fields
4. Pull all current MA resident loans with required fields

## Results Summary

### Question 1: Loans ≤$6,000 with rates >12% for MA residents
**Answer: YES** - Happy Money has processed **3 loans** meeting these criteria:
- **Loan ID P592BB4580282**: $5,000 @ 15.81% interest rate, 17.99% APR (Paid in Full, Jan 11, 2021)
- **Loan ID PB822534FB0D7**: $6,000 @ 19.64% interest rate, 21.99% APR (Charge off, Oct 1, 2020) 
- **Loan ID P60561A226BA9**: $5,000 @ 16.80% interest rate, 18.995% APR (Paid in Full, Apr 2, 2019)
- **Total Amount**: $16,000
- **Average Interest Rate**: 17.42%
- **Average APR**: 19.66%

### Question 2: All MA resident loans serviced  
**Answer: YES** - Happy Money has serviced **61 loans** for Massachusetts residents since inception:
- **Total Loan Amount**: $1,030,900
- **Date Range**: October 11, 2017 to June 15, 2022
- **Average Loan Amount**: $16,900
- **Average Interest Rate**: 11.77%
- **Average APR**: 13.34%

### Loan Distribution
- Loans ≤$6,000: 4 (6.6%)
- Loans $6,001-$10,000: 13 (21.3%)
- Loans >$10,000: 44 (72.1%)

## Files Delivered

### Final Deliverables
1. **`DI-1137.sql`** - Consolidated SQL queries for all analysis scenarios
2. **`MA_Current_Residents_Loans_6000_and_Above_12_IR.csv`** - Small dollar high rate loans (3 loans)
3. **`MA_Current_Residents_All_Loans.csv`** - Complete list of all current MA resident loans with required fields (61 loans)
4. **`Natively_Originated_MA_Loans.csv`** - All loans originated to MA residents

### SQL Query Documentation
The `DI-1137.sql` file contains four main query sections:
1. **Natively_Originated_MA_Limited_Loan_Population**: Loans ≤$6,000 with rates >12% for native MA residents
2. **MA_Current_Residents_Limited_Loans**: Loans ≤$6,000 with rates >12% for current MA residents
3. **Natively_Originated_MA_Loans**: All loans for native MA residents
4. **MA_Current_Residents_All_Loans**: All loans for current MA residents

### Regulatory Questions Answered

1. **Has Happy Money processed loans ≤$6,000 with rates >12% for MA residents?**
   - **Answer: YES** - **3 loans** totaling $16,000:
     - P592BB4580282: $5,000 @ 15.81% interest, 17.99% APR
     - PB822534FB0D7: $6,000 @ 19.64% interest, 21.99% APR  
     - P60561A226BA9: $5,000 @ 16.80% interest, 18.995% APR

2. **Has Happy Money serviced loans for MA residents?**
   - **Answer: YES** - **61 loans** totaling $1,030,900 (October 2017 - June 2022)

All CSV files contain the complete required regulatory fields:
- APPLICATION DATE, APPLICATION FIRST/LAST NAME (when available), APPLICANTRESIDENCESTATE
- LOANID, LOANAMOUNT, CURRENT STATUS, APR, INTEREST RATE, ORIGINATION DATE

## Technical Notes
- **Primary data source**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE` provides authoritative loan data
- **Current state resolution**: LEFT JOIN to VW_LOAN → VW_MEMBER_PII for current state verification
- **Data deduplication**: Uses `ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC)` for most recent loan status
- **Interest rate format**: Loan tape stores as decimal (0.12 = 12%) with parameter conversion
- **Comprehensive coverage**: Captures both native origination and current residence scenarios

## Status
- Started: 2025-08-01  
- Status: **Complete - Final Deliverables Ready**