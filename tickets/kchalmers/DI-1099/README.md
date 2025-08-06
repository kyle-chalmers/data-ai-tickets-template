# DI-1099: Goodbye Letter List for Theorem (Pagaya) Loan Sale

## Ticket Summary
**Type:** Data Pull  
**Status:** Completed  
**Assignee:** kchalmers@happymoney.com  
**Created:** 2025-07-30  
**Completed:** 2025-07-30  

## Problem Description
Generate goodbye letter/marketing email list for Theorem (Pagaya) loan sale to Resurgent based on final loan lists. This is part of the standard customer communication process for debt sales to notify customers of the loan servicing transfer.

## Related Tickets
**Clones DI-971**: "Goodbye Letter List for Loan Sale" (Status: Deployed)
- **Similar Pattern**: Both tickets generate goodbye letter lists for debt sales  
- **Key Difference**: DI-971 was for Bounce (H2 2024 & Q1 2025), DI-1099 is for Theorem (Q1 2025)  
- **Reference Query**: DI-971 provides template approach using BOUNCE_DEBT_SALE_SELECTED tables
- **SFMC Integration**: Both require SFMC_SUBSCRIBER_ID for marketing system

## Requirements
Based on final loan list for the sale, create a marketing list that:
- **Includes all loans** from the final loan list (2,179 loans)
- **Includes SFMC number** for marketing system integration
- **Includes last four digits of loan ID** with leading zeros preserved
- **Matches format** of previous debt sale marketing lists
- **EXCLUDES all balance information** (unlike previous lists)
- **Include portfolio name** as final column in the sheet
- **Sale Date:** 2025-07-31
- **Filter:** Theorem-only list for loans with PORTFOLIO_NAME containing 'Theorem'

## Data Sources
- **Final Loan List:** `2025 Debt Sale Theorem to Resurgent.csv` (2,179 loans)
- **Source Tables:** 
  - `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE` (loan population)
  - `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_TRANSACTIONS` (transaction history)
  - `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED` (created for selected loans)
- **Reference Queries:** DI-928 debt sale query sequence (1→2→3→4)

## Solution Approach

### 1. Data Preparation
- Created `THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED` table with 2,179 loans from CSV
- Used simple INSERT statement with IN clause for loan IDs
- Verified all loans matched the source sale table

### 2. Goodbye Letter Query Development
- Adapted DI-971 query pattern for Theorem sale
- Key modifications:
  - Removed all balance information per requirements
  - Added `CAST(RIGHT(UPPER(la.LEGACY_LOAN_ID), 4) AS VARCHAR)` for last 4 digits
  - Included portfolio name as final column
  - Set sale date to 2025-07-31
  - Created filtered version for Theorem portfolios only

### 3. Data Quality & Validation
- Total loans selected: 2,179
- Complete goodbye letter list: 2,180 records (100% SFMC coverage)
- Theorem-only filtered list: 1,771 records
- Portfolio breakdown:
  - Theorem Main Master Fund LP: 1,268 loans (58.19%)
  - Theorem Prime Plus Yield Fund Master LP: 502 loans (23.04%)
  - Various credit union portfolios: 409 loans (18.77%)

## Files

### Source Materials (`source_materials/`)
- `2025 Debt Sale Theorem to Resurgent.csv` - Final loan list with 2,179 loans

### Final Deliverables (`final_deliverables/`)
Organized structure with numbered SQL queries for execution order:

```
final_deliverables/
├── sql_queries/
│   ├── 1_theorem_goodbye_letter_list.sql         # Main complete query
│   ├── 2_theorem_goodbye_letter_theorem_only.sql # Filtered version
│   ├── 3_portfolio_breakdown_qc.sql              # Portfolio analysis
│   └── 4_final_qc_validation.sql                 # Comprehensive QC
├── qc_queries/
│   └── 5_final_record_count_validation.sql       # Final validation
├── goodbye_letters/
│   ├── theorem_goodbye_letter_complete_final.csv    # 2,180 rows (with headers)
│   └── theorem_goodbye_letter_theorem_only_final.csv # 1,771 rows (with headers)
└── archive/
    └── csv_to_snowflake_process.md               # Development documentation
```

### Key Query Features
- SFMC_SUBSCRIBER_ID included for marketing integration
- Last 4 digits of loan ID preserved with leading zeros
- No balance information included
- Portfolio name as final column
- Sale date: 2025-07-31

## Final Deliverable
**Primary Output:** `theorem_goodbye_letter_theorem_only_final.csv`
- **Records:** 1,771 (including header row)
- **Filters:** Only Theorem portfolio loans
- **Format:** CSV with column headers
- **Purpose:** SFMC marketing integration for customer notifications

## Status Updates
- **2025-07-30 09:00:** Ticket investigation started, folder structure created
- **2025-07-30 10:00:** Created THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED table
- **2025-07-30 11:00:** Adapted goodbye letter query from DI-971
- **2025-07-30 12:00:** Generated both complete and Theorem-only lists
- **2025-07-30 13:00:** Completed QC validation and folder organization
- **2025-07-30 14:00:** Fixed LAST_FOUR_LOAN_ID logic and regenerated with headers
- **2025-07-30 15:00:** Finalized deliverables with Theorem-only list as primary output
- **2025-07-30 15:15:** Backed up to Google Drive (first time - no previous backup existed)