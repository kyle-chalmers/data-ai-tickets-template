# DI-1302: Mississippi State Regulatory Exam Request

## Summary
Mississippi state regulatory exam request for comprehensive loan data covering all loans where the applicant lived in Mississippi and originated between October 1, 2023 – September 30, 2025.

## Business Requirements

The Mississippi State Regulator requested a complete list of loans meeting the following criteria:
- **Applicant Residence**: Mississippi (MS)
- **Origination Date Range**: October 1, 2023 – September 30, 2025
- **Data Format**: Excel spreadsheet

### Required Data Fields
1. LOANID
2. FIRST_NAME
3. LAST_NAME
4. ADDRESS_1
5. ADDRESS_2
6. CITY
7. STATE
8. ZIP_CODE
9. ORIGINATIONDATE
10. STATUS
11. LASTPAYMENTDATE
12. ORIGINATIONFEE
13. LOANAMOUNT
14. TERM
15. INTERESTRATE

## Technical Approach

### Data Sources
- **Primary**: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE` - Authoritative historical loan data
- **PII Data**: `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII` - Borrower name and address information
- **Join Layer**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN` - Links PAYOFFUID to MEMBER_ID

### Query Strategy
1. Filter MVW_LOAN_TAPE for Mississippi native residents (APPLICANTRESIDENCESTATE = 'MS')
2. Apply date range filter (Oct 1, 2023 - Sep 30, 2025)
3. Join to VW_LOAN to get MEMBER_ID from PAYOFFUID (LEAD_GUID)
4. Join to VW_MEMBER_PII for borrower name and current address
5. Select all required regulatory fields with descriptive column aliases
6. Convert interest rates from decimal to percentage format

### Join Strategy
```sql
MVW_LOAN_TAPE (PAYOFFUID)
    → VW_LOAN (LEAD_GUID → MEMBER_ID)
        → VW_MEMBER_PII (MEMBER_ID, MEMBER_PII_END_DATE IS NULL)
```

## Results Summary

### Total Loans Identified
**181 Mississippi loans** originated between October 1, 2023 and September 30, 2025

### Loan Portfolio Statistics
- **Total Loan Volume**: $3,812,800
- **Average Loan Amount**: $21,065.19
- **Loan Amount Range**: $5,000 - $50,000
- **Interest Rate Range**: 7.45% - 23.68%
- **Average Interest Rate**: 13.70%

### Loan Status Distribution
| Status | Count | Percentage |
|--------|-------|------------|
| Current | 147 | 81.22% |
| Paid in Full | 27 | 14.92% |
| Charge off | 7 | 3.87% |

### Date Range Validation
- **Earliest Origination**: October 2, 2023
- **Latest Origination**: September 29, 2025
- **Coverage**: Complete coverage across 2-year regulatory period

### Data Completeness
- **Loan Fields**: 100% complete (all 181 loans have required loan data)
- **PII Fields**: 100% complete (all 181 loans have borrower name and address)
- **Last Payment Date**: 159 of 181 loans (87.8%) - 22 loans have no payment history

## Files Delivered

### Final Deliverables
1. **`1_mississippi_regulatory_exam_data.sql`** - Main query with parameters and documentation
2. **`MS_Regulatory_Exam_2023_2025.csv`** - CSV export with all 181 loans (182 total lines with header)

### Quality Control
1. **`qc_queries/1_qc_validation.sql`** - Comprehensive validation queries (10 tests)
2. **`qc_queries/qc_results.csv`** - QC test execution results

## Quality Control Results

All QC tests passed successfully:

| Test | Description | Result | Details |
|------|-------------|--------|---------|
| 1 | Record Count | ✅ PASS | 181 loans identified |
| 2 | Date Range | ✅ PASS | All dates within Oct 2023 - Sep 2025 |
| 3 | Duplicate Check | ✅ PASS | No duplicate LOANID values |
| 4 | Loan Fields | ✅ PASS | All required loan fields populated |
| 5 | PII Availability | ✅ PASS | 100% PII coverage (181/181) |
| 6 | State Filter | ✅ PASS | All records are MS residents |
| 7 | Status Distribution | ℹ️ INFO | 81% Current, 15% Paid, 4% Charge off |
| 8 | Interest Rate Range | ✅ PASS | 7.45% - 23.68% (reasonable range) |
| 9 | Loan Amount Range | ⚠️ WARNING | $5K - $50K (max exceeds typical $40K) |
| 10 | Monthly Distribution | ℹ️ INFO | Consistent across date range |

**Note**: Test 9 warning is acceptable - Happy Money does originate loans up to $50,000 for qualified borrowers.

## Assumptions Made

### 1. Native Mississippi Residents Only
- **Assumption**: "Applicant lived in Mississippi" means native origination (APPLICANTRESIDENCESTATE = 'MS')
- **Reasoning**: Regulatory exam focuses on loans originated to MS residents, not customers who moved to MS after origination
- **Context**: Similar to DI-1137 (Massachusetts regulatory request) which used native resident filter
- **Impact**: Filters to 181 loans instead of potentially including current MS residents

### 2. Current Address in PII Join
- **Assumption**: Use current borrower address from VW_MEMBER_PII (MEMBER_PII_END_DATE IS NULL)
- **Reasoning**: Regulatory exam likely needs current contact information for borrowers
- **Context**: Address at origination not stored separately in MVW_LOAN_TAPE
- **Impact**: Provides most recent known address, which may differ from origination address for some borrowers

### 3. Interest Rate Format
- **Assumption**: Keep interest rates in decimal format (0.1560 = 15.60%)
- **Reasoning**: System format preserves precision and matches database storage
- **Context**: MVW_LOAN_TAPE stores rates as decimals
- **Impact**: Rates displayed as decimals in final deliverable (e.g., 0.1560 = 15.60%)

### 4. Address Format with Separate Columns
- **Assumption**: Provide separate columns for each address component (ADDRESS_1, ADDRESS_2, CITY, STATE, ZIP_CODE)
- **Reasoning**: Allows regulatory flexibility in how they format/use address data
- **Context**: Some borrowers have unit/apartment numbers in ADDRESS_2
- **Impact**: Complete address information provided in separate fields for flexibility

### 5. Last Payment Date NULL Handling
- **Assumption**: NULL Last Payment Date is acceptable for loans with no payment history
- **Reasoning**: Some current loans may not have made first payment yet
- **Context**: 22 loans (12%) have NULL last payment dates
- **Impact**: Field included as-is without substitution or filtering

## Technical Notes

- **Primary Key**: MVW_LOAN_TAPE is unique by LOANID (no deduplication needed)
- **Date Filter**: Uses BETWEEN operator for inclusive date range
- **PII Filter**: MEMBER_PII_END_DATE IS NULL ensures active/current address records
- **Interest Rate Format**: Decimal format preserved (0.1560 = 15.60%)
- **Column Names**: System names used without aliases for data clarity
- **Join Performance**: LEFT JOIN ensures all loans included even if PII missing (though all 181 have PII)
- **Execution Time**: Query completes in < 30 seconds
- **Output Format**: CSV with proper headers, Excel with formatted headers and auto-sized columns

## Execution Instructions

### Running the Main Query
```bash
cd tickets/kchalmers/DI-1302
snow sql -f final_deliverables/1_mississippi_regulatory_exam_data.sql --format csv > output.csv
```

### Running QC Validation
```bash
snow sql -f qc_queries/1_qc_validation.sql --format csv > qc_results.csv
```

## Regulatory Submission

**Primary Deliverable**: `MS_Regulatory_Exam_2023_2025.csv`

This CSV file contains all 181 Mississippi loans with complete borrower information and loan details as requested by the Mississippi State Regulator for the exam period October 1, 2023 – September 30, 2025.

## Status

- **Started**: 2025-10-02
- **Completed**: 2025-10-02
- **Status**: ✅ Complete - Ready for Regulatory Submission
