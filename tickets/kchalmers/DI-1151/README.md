# DI-1151: Goodbye Letter List, Credit Reporting List, and Bulk Upload List for Bounce 2025 Q2 Debt Sale

## Summary

Generated the three required data export files for the Bounce 2025 Q2 Debt Sale based on the selected loan population (status = 'Included' from the original results file).

## Source Data

- **Population Source**: `HM_AUG_25_Q2_Sale_Results (1).xlsx - Query result.csv`
- **Selected Loans**: 1,483 loans with status = 'Included' 
- **Total Records**: 1,590 (including 103 Bankrupt, 4 Deceased, 1,483 Included)

## Deliverables

### 1. Marketing Goodbye Letters
**File**: `marketing_goodbye_letters_bounce_2025_q2_final.csv`
- **Records**: 1,484 records (including header)
- **Purpose**: Loan information for marketing goodbye letters to borrowers
- **Key Fields**: loan_id, borrower name/contact info, charge-off details, current balance
- **Template Source**: DI-971 Notice_Of_Servicing_Transfer_updated.sql

### 2. Credit Reporting List  
**File**: `credit_reporting_bounce_2025_q2_final.csv`
- **Records**: 1,484 records (including header)
- **Purpose**: Credit bureau reporting updates for transferred loans
- **Key Fields**: loan_id, borrower name, placement start date (2025-08-06)
- **Template Source**: DI-972 BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql

### 3. Bulk Upload List
**File**: `bulk_upload_bounce_2025_q2_final.csv` 
- **Records**: 1,484 records (including header)
- **Purpose**: LoanPro system updates for placement status
- **Key Fields**: LP_LOAN_ID, loanid, SETTINGS_ID, placement status/dates
- **Template Source**: DI-972 BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql

## Data Processing Steps

1. **Data Upload**: Uploaded source CSV to `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_CSV_UPLOAD`
2. **Selected Population**: Created `BOUNCE_DEBT_SALE_Q2_2025_SALE_CSV_SELECTED` with 1,483 'Included' records
3. **Query Adaptation**: Modified templates for Q2 2025 data structures and field mappings
4. **Data Type Handling**: Added proper casting for numeric/date fields with commas and formatting issues
5. **Table Conflict Resolution**: Renamed tables to avoid overwriting the main DI-1141 analysis table

## Key Technical Notes

- **Join Strategy**: Used ACCOUNT_PUBLIC_ID → EXTERNAL_ACCOUNT_ID mapping to connect to loan system data
- **Data Cleansing**: Applied TRY_TO_NUMBER/TRY_TO_DATE functions for formatted CSV data
- **Template Consistency**: Maintained same output structure as previous debt sale deliverables
- **QC Validation**: All 1,483 selected loans successfully matched with loan and PII data
- **Table Naming**: Used `_CSV_` suffix to distinguish from the comprehensive DI-1141 analysis table

## Database Objects Created

- `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_CSV_UPLOAD` (CSV data upload - 1,590 records)
- `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_CSV_SELECTED` (1,483 selected loans from CSV)

**Note**: The main `BOUNCE_DEBT_SALE_Q2_2025_SALE` table from DI-1141 contains the comprehensive loan analysis data and has been preserved separately.

## Files Structure

```
DI-1151/
├── README.md
├── source_materials/
│   ├── bounce_2025_q2_debt_sale_results.csv
│   ├── Notice_Of_Servicing_Transfer_updated.sql
│   └── BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql
├── final_deliverables/
│   ├── 1_upload_bounce_2025_q2_debt_sale_data.sql
│   ├── 2_marketing_goodbye_letters_bounce_2025_q2.sql
│   ├── 3_credit_reporting_bounce_2025_q2.sql
│   ├── 4_bulk_upload_bounce_2025_q2.sql
│   ├── marketing_goodbye_letters_bounce_2025_q2_final.csv ✓
│   ├── credit_reporting_bounce_2025_q2_final.csv ✓
│   └── bulk_upload_bounce_2025_q2_final.csv ✓
└── qc_queries/
    └── 1_record_count_validation.sql
```

## Issue Resolution

**Problem**: Initially overwrote the main `BOUNCE_DEBT_SALE_Q2_2025_SALE` table from DI-1141 with simple CSV upload data.

**Solution**: 
1. Renamed CSV upload table to `BOUNCE_DEBT_SALE_Q2_2025_SALE_CSV_UPLOAD`
2. Created separate selected table: `BOUNCE_DEBT_SALE_Q2_2025_SALE_CSV_SELECTED`  
3. Restored original DI-1141 comprehensive analysis table
4. Updated all query references to use CSV-specific table names

## Workflow Documentation

📋 **[INSTRUCTIONS.md](INSTRUCTIONS.md)** - Complete step-by-step workflow for future debt sale deliverable requests

This comprehensive document provides detailed instructions to ensure consistent, error-free execution of similar requests in the future. The workflow covers all phases from prerequisites and setup through final deliverables and post-completion verification.

## Completion Status
✅ All three required files successfully generated and ready for delivery.
✅ Database table conflicts resolved - both CSV and analysis data preserved.
✅ Comprehensive workflow documentation created for future use.