# DI-1302: Mississippi State Regulatory Exam Request - Claude Context

## Ticket Overview
Mississippi state regulatory exam request for comprehensive loan data covering October 1, 2023 – September 30, 2025.

## Key Technical Details

### Data Architecture Used
- **Primary Source**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE`
  - Used for regulatory compliance tickets (per CLAUDE.md guidelines)
  - Contains historical loan tape data with all required fields
  - LOANID is unique (no deduplication needed)

### Join Strategy
```
MVW_LOAN_TAPE (PAYOFFUID)
  → VW_LOAN (LEAD_GUID → MEMBER_ID)
    → VW_MEMBER_PII (MEMBER_ID, MEMBER_PII_END_DATE IS NULL)
```

### Critical Filters Applied
1. **State Filter**: `UPPER(APPLICANTRESIDENCESTATE) = 'MS'`
   - Native Mississippi residents at origination
2. **Date Range**: `ORIGINATIONDATE BETWEEN '2023-10-01' AND '2025-09-30'`
3. **Active PII**: `MEMBER_PII_END_DATE IS NULL`
   - Ensures current/active borrower address records

## Results Summary
- **Total Loans**: 181 Mississippi loans
- **Date Range**: October 2, 2023 – September 29, 2025
- **100% Data Completeness**: All loans have required loan fields and PII
- **Status Distribution**: 81% Current, 15% Paid in Full, 4% Charge off

## Key Assumptions Made

1. **Native MS Residents**: Used `APPLICANTRESIDENCESTATE = 'MS'` to filter for loans originated to MS residents (similar to DI-1137 Massachusetts request)

2. **Current Address**: Joined to `VW_MEMBER_PII` with `MEMBER_PII_END_DATE IS NULL` to get current borrower address (origination address not separately stored)

3. **Interest Rate Format**: Kept decimal format (0.1560 = 15.60%) matching system storage

4. **Address Structure**: Provided separate columns (ADDRESS_1, ADDRESS_2, CITY, STATE, ZIP_CODE) for regulatory flexibility

5. **NULL Last Payment Date**: Accepted for loans with no payment history (22 loans, 12%)

## Quality Control Highlights

All 10 QC tests passed:
- ✅ Record count validation (181 loans)
- ✅ Date range verification
- ✅ No duplicate LOANID values
- ✅ 100% loan field completeness
- ✅ 100% PII coverage (181/181)
- ✅ State filter validation (all MS)
- ⚠️ Loan amount range $5K-$50K (max exceeds typical $40K but acceptable)

## File Generation Notes

### CSV Output
- Used `--format csv` with Snowflake CLI
- Removed empty lines to ensure 182 lines total (1 header + 181 data rows)
- Column headers properly formatted

### Excel Conversion
- Used Python with openpyxl
- Bold, centered headers with text wrapping
- Auto-sized columns (max 50 characters)
- Clean formatting for regulatory submission

## Similar Tickets for Reference
- **DI-1137**: Massachusetts regulatory request (same pattern)
- Uses same data architecture and filtering approach
- MVW_LOAN_TAPE for compliance/regulatory tickets

## Query Performance
- **Execution Time**: < 30 seconds
- **Primary Filter**: APPLICANTRESIDENCESTATE + ORIGINATIONDATE
- **Join Performance**: LEFT JOIN ensures all loans included even if PII missing
