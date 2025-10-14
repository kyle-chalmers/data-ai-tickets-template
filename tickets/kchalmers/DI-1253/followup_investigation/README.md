# DI-1253 Follow-up Investigation

## Purpose
Investigation of three issues raised in Jira comment [539625](https://happymoneyinc.atlassian.net/browse/DI-1253?focusedCommentId=539625) regarding the FTFCU charged-off loans transaction file.

## Files in This Folder

### 1_investigation_notes.md
Detailed findings for each of the three issues:
- Reversed transaction indicators
- Transaction date differences
- Unpaid balance column definition

### 2_date_field_investigation.sql
SQL queries used to investigate transaction date differences:
- Comparison of TRANSACTION_DATE vs APPLY_DATE
- Analysis of date difference patterns
- Statistics on date field discrepancies

### date_differences_sample.csv
Sample data showing transactions where TRANSACTION_DATE differs from APPLY_DATE, including:
- ACH processing delays
- Batch posted recoveries
- Scheduled future payments

### 3_summary_and_recommendations.md
Executive summary of investigation results and recommendations.

## Key Findings

**Issue #1 - Reversal Indicators:** ✅ RESOLVED
- Columns already present in CSV (LOAN_REVERSED, LOAN_REJECTED, LOAN_CLEARED)
- No action needed

**Issue #2 - Date Differences:** ✅ EXPLAINED
- 23.25% of transactions have different dates due to ACH processing, batch posting, and scheduled payments
- Current design is correct (TRANSACTION_DATE = when occurred, APPLY_DATE = when posted)
- No action needed

**Issue #3 - Unpaid Balance:** ✅ CLARIFIED
- UNPAIDBALANCEDUE = (Principal + Interest at Charge-off) - (Recoveries + Adjustments + Waivers)
- Formula documented
- No action needed

## Conclusion
All three issues have been addressed through investigation and clarification. No changes needed to queries or deliverables.
