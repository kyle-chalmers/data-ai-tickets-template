# DI-1065: Quarterly Fortress Due Diligence for Payment History | 2025 Q2

## Ticket Summary
**Type:** Data Pull  
**Status:** Backlog  
**Assignee:** kchalmers@happymoney.com  
**Created:** 2025-07-08  
**Due Date:** 2025-07-30  

## Problem Description
Fortress requires quarterly due diligence similar to their initial onboarding collateral review. They provided a loan list on 7/15 requiring payment history transaction reports by 7/30.

## Requirements
- **Input:** Loan lists from "Attachment B" and "Attachment C" tabs in provided Excel file
- **Output:** Transaction report using Bounce sales format as baseline
- **Timeline:** Data delivery by 7/25 to allow Ops team QA before 7/30 deadline
- **Format:** Start with existing Bounce sales transaction file format, adapt as needed

## Approach
1. Research existing Bounce sales transaction format and queries
2. Extract loan lists from provided Excel file tabs
3. Build payment history queries for specified accounts
4. Generate transaction reports matching established format
5. Deliver by 7/25 for Ops QA review

## Stakeholders
- **Requestor:** Neha Sharma (nsharma@happymoney.com)
- **QA Teams:** John Triggas, Mandi Sinner
- **External:** Fortress (quarterly due diligence)

## Files

### Source Materials (`source_materials/`)
- `fortress_loan_list_2025_07.xlsx` - Original Fortress Excel file with loan lists
- `fortress_attachment_b_75_loans.csv` - Attachment B: 75 loans in Fortress format
- `fortress_attachment_c_5_loans.csv` - Attachment C: 5 loans in Fortress format
- `bounce_debt_sale_reference_query.sql` - Reference query for Bounce debt sales format

### Final Deliverables (`final_deliverables/`)
- `fortress_payment_history_final_q2_2025.sql` - Final Q2 2025 query with parameterized AS_OF_DATE and comprehensive filtering logic
- `fortress_payment_history_final_q2_2025_116_transactions.csv` - Q2 2025 filtered payment history (116 transactions)
- `qc_queries/` - Quality control and validation queries
  - `transaction_count_validation.sql` - SQL-based transaction count validation
- `archive_versions/` - Development iterations and previous versions

## Analysis Results

### Updated Requirements (Q2 2025 Focus)
Following stakeholder clarification from Neha Sharma:
- **Payoff Loan ID:** Include formatted LOANID field (e.g., "HME61FDE9A3065")
- **Q2 2025 Filter:** Transactions through June 30, 2025 only
- **Additional Dates:** Include REVERSAL_DATE, LAST_UPDATED_DATE, APPLY_DATE
- **As-of-Date Logic:** Show payment status as of June 30th (pre-reversal for July reversals)

### Final Data Summary
- **80 Fortress loans total:** 75 Attachment B + 5 Attachment C
- **116 Q2 2025 transactions:** Filtered from original 193 total transactions
- **SQL-based QC:** Validated using dedicated QC queries instead of shell commands
- **Parameterized query:** AS_OF_DATE variable for easy date modification

### Filtering Logic Implementation
**Scenario 1:** Payment made/applied in June but reversed in July = **INCLUDED** (shows as not-reversed)
**Scenario 2:** Payment transacted in June but applied in July = **EXCLUDED**

### Technical Improvements
- **Query optimization:** 49.6% performance improvement (32.070s → 16.169s)
- **Parameterization:** Hard-coded dates moved to variables
- **Comprehensive commenting:** Full business logic documentation
- **As-of-date perspective:** Reversal fields adjusted for temporal accuracy

## Status Updates
- **2025-07-29:** Ticket investigation started, folder structure created
- **2025-07-30:** Initial payment history analysis completed, 193 transactions extracted from LoanPro
- **2025-07-30:** Updated for Q2 2025 requirements: filtered to 116 transactions, added payoff loan ID, implemented as-of-date logic, optimized query performance