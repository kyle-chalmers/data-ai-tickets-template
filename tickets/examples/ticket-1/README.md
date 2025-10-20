# ticket-1: Portfolio Investor Credit Reporting and Placement Upload List for Loan Sale

## Ticket Information
- **Ticket Key**: ticket-1
- **Type**: Data Pull
- **Status**: In Spec
- **Assignee**: Data Analyst
- **Created**: [Date TBD]
- **Updated**: [Date TBD]

## Summary
Generate credit reporting and placement upload lists for the Loan Management System (LMS) based on the final loan lists from a portfolio investor loan sale (DI-1099). This utilizes existing template scripts to extract the necessary data for credit reporting and loan placement uploads.

## Business Context
Following the completion of DI-1099 (goodbye letter list for loan sale to a debt buyer), we now need to prepare the corresponding credit reporting and placement upload data for the LMS. This ensures proper credit reporting compliance and loan placement tracking for the sold loans.

## Requirements
- Extract credit reporting data for loans in the portfolio investor sale
- Generate placement upload list for LMS
- Follow established template script patterns
- Ensure data consistency with DI-1099 loan lists

## Related Tickets
**Clones DI-972**: "Credit Reporting and Placement Upload List for Loan Sale" (Status: Deployed)
- **Similar Pattern**: Both tickets extract LMS upload data for loan sales
- **Key Difference**: ticket-1 uses portfolio investor sale data vs DI-972's different debt buyer sale data
- **Reference Template**: Shared template script for both tickets
- **Reusable Components**: SQL structure and file formats adapted from DI-972

**Depends on DI-1099**: "Portfolio investor goodbye letter list for loan sale to debt buyer" (Status: Completed)
- **Relationship**: This ticket builds on the loan lists generated in DI-1099
- **Data Source**: Uses the same loan universe (2,179 loans) but extracts different data fields
- **Reference Files**: DI-1099 final deliverables provide the base loan set

## Resources
- **Template Script**: [Shared template location - see internal documentation]
- **Related Tickets**: DI-972 (template), DI-1099 (loan universe)

## Data Sources
- **Primary Source**: `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.PORTFOLIO_DEBT_SALE_Q1_2025_SALE_SELECTED` (1,770 portfolio loans filtered from 2,179 total)
- **Loan Data**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN`
- **LMS Settings**: `BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT`
- **Member PII**: `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII`

## Solution Approach
1. **Template Analysis**: Used DI-972 as template, adapted for portfolio investor sale data
2. **Data Extraction**: Applied same SQL patterns but with investor-specific source tables
3. **Dual File Generation**: Created both Bulk Upload (placement) and Credit Reporting files
4. **Quality Control**: Comprehensive SQL-based validation ensuring 100% data completeness

## Implementation Notes
- **Schema Filtering**: Applied `ARCA.CONFIG.LMS_SCHEMA()` for LMS data consistency
- **Date Standardization**: Used '2025-07-31' as placement start date across both files
- **Data Completeness**: Achieved 100% completeness for all required fields
- **File Naming**: Followed DI-972 naming convention with investor-specific identifiers

## Deliverables
- [x] **Bulk Upload Placement File**: `Bulk_Upload_Placement_File_Portfolio_2025_SALE.csv` (1,770 records)
- [x] **Credit Reporting File**: `Credit_Reporting_File_Portfolio_2025_SALE.csv` (1,770 records)
- [x] **SQL Queries**: Main extraction query and comprehensive QC validation
- [x] **QC Documentation**: Complete validation showing 100% data quality

## Testing & Validation
- **Source Data Validation**: Confirmed 1,770 unique portfolio investor loans (filtered from 2,179 total)
- **Portfolio Filtering**: Applied portfolio filtering to target specific investor loans
- **Data Completeness**: 100% coverage for all required fields (LOAN_ID, SETTINGS_ID, names, dates)
- **File Consistency**: Both files contain identical loan universe
- **Template Compliance**: Files match DI-972 structure and format requirements
- **SQL-Based QC**: All validation queries passed successfully
- **File Generation**: Generated complete files with all 1,770 portfolio loans

## Results & Outcomes
- **Perfect Data Quality**: 0 missing records, 0 data quality issues
- **Correct Portfolio Filtering**: Only target portfolio included (1,770 loans vs 2,179 total)
- **Production Ready**: Both files validated and ready for LMS upload and credit reporting
- **Template Replication**: Successfully adapted DI-972 pattern for new loan sale
- **Stakeholder Ready**: Complete deliverables with comprehensive QC documentation

## Files Generated
```
tickets/examples/ticket-1/
├── README.md (this file)
├── source_materials/
│   └── BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql (DI-972 template)
├── final_deliverables/
│   ├── 1_portfolio_credit_reporting_and_placement_upload.sql (Main SQL queries)
│   ├── 2_comprehensive_qc_validation.sql (QC validation queries)
│   ├── 3_final_qc_summary.sql (Final validation summary)
│   ├── 4_placement_status_verification.sql (Verification of debt buyer placement)
│   ├── Bulk_Upload_Placement_File_Portfolio_2025_SALE.csv (1,770 records)
│   └── Credit_Reporting_File_Portfolio_2025_SALE.csv (1,770 records)
└── [additional documentation as needed]
```

## Post-Upload Verification (2025-08-04)

### Placement Status Verification

Following the upload, verification was performed to check if the loans were successfully placed with the debt buyer in the LMS system.

#### Key Findings:
1. **Total Loans in ticket-1 CSV File**: 1,770 loans
2. **Expected Placement**: All 1,770 loans should be placed with the debt buyer with a start date of 2025-07-31
3. **Actual Status in Database**: ✅ **ALL 1,770 loans successfully uploaded**
   - All loans have `placement_status = 'DebtBuyerName'`
   - All loans have `placement_status_start_date = '2025-07-31'`
   - 100% success rate

#### Database Query Results:
```sql
SELECT COUNT(*) AS NUMBER_OF_LOANS, A.PLACEMENT_STATUS, A.PLACEMENT_STATUS_START_DATE
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT B
ON A.LOAN_ID = B.LOAN_ID AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE A.PLACEMENT_STATUS = 'DebtBuyerName'
AND A.PLACEMENT_STATUS_START_DATE = '2025-07-31'
GROUP BY ALL;
```

Results:
```
+------------------------------------------------------------------+
| NUMBER_OF_LOANS | PLACEMENT_STATUS | PLACEMENT_STATUS_START_DATE |
|-----------------+------------------+-----------------------------|
| 1770            | DebtBuyerName    | 2025-07-31                  |
+------------------------------------------------------------------+
```

#### Verification Query:
The correct verification requires joining with `VW_LOAN_SETTINGS_ENTITY_CURRENT` and applying the schema filter. See `final_deliverables/4_placement_status_verification.sql` for the complete verification queries.

#### Conclusion:
✅ The bulk upload was completed successfully. All 1,770 loans from the ticket-1 file have been properly placed with the debt buyer in the LMS system with the correct placement date.

### Post-Upload Verification Comment

```
## Bulk Upload Verification Complete ✅

The Data team has verified that the bulk upload for ticket-1 was successful.

**Verification Summary:**
- **Total loans uploaded**: 1,770
- **Placement status**: DebtBuyerName
- **Placement start date**: 2025-07-31
```

---
*Ticket created: 2025-07-30*
*Last updated: 2025-08-04*
*Status: Completed - Bulk upload verified successful*