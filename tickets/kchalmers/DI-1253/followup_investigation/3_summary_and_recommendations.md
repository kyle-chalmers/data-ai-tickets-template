# DI-1253 Follow-up Investigation Summary

## Overview
Investigation of three issues raised in Jira comment regarding the FTFCU charged-off loans transaction file.

## Issue #1: Reversed Transaction Indicators
### Status: ✅ RESOLVED - No Issue Found

**Original Concern:** Reversed transactions present in file without indicator

**Finding:** Reversal indicator columns ARE present in the deliverable:
- `LOAN_REVERSED` (Column 16)
- `LOAN_REJECTED` (Column 17)
- `LOAN_CLEARED` (Column 18)

**Evidence:** Sample data shows reversed transactions properly flagged:
- Transaction 3033976: `LOAN_REVERSED=true`
- Transaction 3034064: `LOAN_REVERSED=true`

**Action Required:** None. The columns exist and are populated correctly.

---

## Issue #2: Transaction Date Differences
### Status: ✅ EXPLAINED - Working as Designed

**Original Concern:** Transaction dates differ from LoanPro UI

**Investigation Results:**
- **23.25%** of transactions (27,999 of 120,423) have different TRANSACTION_DATE vs APPLY_DATE
- **76.75%** have matching dates

**Root Causes of Differences:**

1. **ACH Processing Delays** (Most Common)
   - TRANSACTION_DATE = when payment was initiated
   - APPLY_DATE = when payment posted to account
   - Typical 1-3 day difference

2. **Batch Posted Recoveries**
   - Write-Off Recovery payments show 77-152 day delays
   - APPLY_DATE represents batch posting date

3. **Scheduled Future Payments**
   - Some transactions have future TRANSACTION_DATE
   - APPLY_DATE shows when scheduled payment was set up

**Current Query Design:**
- Uses `TRANSACTION_DATE` as primary date (when transaction occurred)
- Uses `APPLY_DATE` for POSTED_DATE/EFFECTIVE_DATE column
- Both dates are included in output

**Recommendation:**
- ✅ **Keep current design** - TRANSACTION_DATE represents true transaction timing
- ✅ **APPLY_DATE already available** in output as EFFECTIVE_DATE column
- **Note:** LoanPro UI likely displays APPLY_DATE, explaining the observed differences

---

## Issue #3: UNPAID BALANCE Definition
### Status: ✅ CLARIFIED

**Question:** What does UNPAIDBALANCEDUE represent?

**Answer:** UNPAIDBALANCEDUE is calculated as:

```sql
UNPAIDBALANCEDUE =
    PRINCIPALBALANCEATCHARGEOFF
    + INTERESTBALANCEATCHARGEOFF
    - RECOVERIESPAIDTODATE
    - CHARGED_OFF_PRINCIPAL_ADJUSTMENT
    - TOTALPRINCIPALWAIVED
```

**Definition:** Total charged-off amount (principal + interest) minus post-charge-off recoveries and adjustments.

**Important:** This is NOT just charged-off principal - it includes BOTH principal AND interest at charge-off, then subtracts any subsequent recoveries.

**Source:** Population query lines 403-405 in `1_charged_off_ftfcu_population_script.sql`

---

## Summary

| Issue | Status | Action Required |
|-------|--------|----------------|
| #1 Reversal Indicators | ✅ Resolved | None - columns already present |
| #2 Date Differences | ✅ Explained | None - working as designed |
| #3 Unpaid Balance | ✅ Clarified | None - definition documented |

**Overall Recommendation:** No changes needed to queries or deliverables. All concerns have been addressed through investigation and clarification.

## Investigation Artifacts

Created in `followup_investigation/` folder:
1. `1_investigation_notes.md` - Detailed findings
2. `2_date_field_investigation.sql` - SQL queries for date analysis
3. `date_differences_sample.csv` - Sample transactions with date differences
4. `3_summary_and_recommendations.md` - This document
