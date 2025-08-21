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

## ⚠️ DATA CORRECTION UPDATE (August 21, 2025)

**IMPORTANT**: Original results were corrected due to improper PII table filtering. Previous CSV files contained duplicates and incorrect data.

**Root Cause**: Used `MEMBER_PII_END_DATE IS NOT NULL` instead of `IS NULL` for active address records.

## Results Summary (CORRECTED)

### Question 1: Loans ≤$6,000 with rates >12% for MA residents
**Answer: YES** - Happy Money has processed **6 loans** meeting these criteria:

**Current MA Residents** (6 loans):
- **P3400B2DBDEBB**: $5,000 @ 17.51% interest, 20.47% APR (OH→MA, Current)
- **P592BB4580282**: $5,000 @ 15.81% interest, 17.99% APR (MN→MA, Paid in Full)
- **P996481FA8DD0**: $5,500 @ 12.94% interest, 14.99% APR (NC→MA, Paid in Full)
- **PB822534FB0D7**: $6,000 @ 19.64% interest, 21.99% APR (NY→MA, Charge off)
- **P0FFEAD576B44**: $5,000 @ 16.80% interest, 18.99% APR (TN→MA, Paid in Full)
- **PFBE79580713F**: $5,000 @ 12.94% interest, 14.99% APR (NY→MA, Paid in Full)

**Native MA Residents**: **0 loans** (none exist)

### Question 2: All MA resident loans serviced  
**Answer: YES** - Happy Money has serviced **106 loans** for Massachusetts residents since inception:

**Current MA Residents**: **104 loans** (customers who moved to MA after origination)
**Native MA Residents**: **2 loans** (originated directly to MA residents)

## Files Delivered

### Final Deliverables (CORRECTED)
1. **`DI-1137.sql`** - Consolidated SQL queries (corrected PII filter to IS NULL)
2. **`MA_Current_Residents_Loans_6000_and_Above_12_IR.csv`** - Small dollar high rate loans (6 loans)
3. **`MA_Current_Residents_All_Loans.csv`** - Complete list of all current MA resident loans (104 loans)
4. **`Natively_Originated_MA_Loans.csv`** - All loans originated to MA residents (2 loans)
5. **`Natively_Originated_MA_Loans_6000_and_Above_12_IR.csv`** - Native MA small high rate loans (0 loans)

### SQL Query Documentation
The `DI-1137.sql` file contains four main query sections:
1. **Natively_Originated_MA_Limited_Loan_Population**: Loans ≤$6,000 with rates >12% for native MA residents
2. **MA_Current_Residents_Limited_Loans**: Loans ≤$6,000 with rates >12% for current MA residents
3. **Natively_Originated_MA_Loans**: All loans for native MA residents
4. **MA_Current_Residents_All_Loans**: All loans for current MA residents

### Regulatory Questions Answered (CORRECTED)

1. **Has Happy Money processed loans ≤$6,000 with rates >12% for MA residents?**
   - **Answer: YES** - **6 loans** for current MA residents, **0 loans** for native MA residents
   - All 6 loans are for customers who moved to MA after loan origination

2. **Has Happy Money serviced loans for MA residents?**
   - **Answer: YES** - **106 total loans** (104 current + 2 native MA residents)

All CSV files contain the complete required regulatory fields:
- APPLICATION DATE, APPLICATION FIRST/LAST NAME (when available), APPLICANTRESIDENCESTATE
- LOANID, LOANAMOUNT, CURRENT STATUS, APR, INTEREST RATE, ORIGINATION DATE

## Technical Notes
- **Primary data source**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE` provides authoritative loan data (unique by LOANID)
- **Current state resolution**: LEFT JOIN to VW_LOAN → VW_MEMBER_PII for current state verification
- **CORRECTED PII Filter**: `MEMBER_PII_END_DATE IS NULL` for active address records (previously incorrectly used IS NOT NULL)
- **No deduplication needed**: MVW_LOAN_TAPE confirmed to be unique by LOANID (346,398 total = 346,398 unique)
- **Interest rate format**: Loan tape stores as decimal (0.12 = 12%) with parameter conversion
- **Comprehensive coverage**: Captures both native origination and current residence scenarios

## Correction History
- **August 21, 2025**: Data corrected due to improper PII filtering
  - Fixed `MEMBER_PII_END_DATE IS NULL` filter for active records
  - Removed unnecessary deduplication logic  
  - Regenerated all CSV files with correct data
  - Updated Google Drive backup with corrected files

## Status
- Started: 2025-08-01  
- Corrected: 2025-08-21
- Status: **Complete - Corrected Final Deliverables Ready**