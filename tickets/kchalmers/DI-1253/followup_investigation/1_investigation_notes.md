# DI-1253 Follow-up Investigation

## Issues Identified

### 1. Reversed Transactions Missing Indicator ✓ RESOLVED - NO ISSUE
**Issue:** Reversed transactions appear in the transaction file but have no indicator column to identify them.

**Investigation Results:** The reversal indicator columns ARE present in the CSV file:
- **Column 16**: LOAN_REVERSED (boolean)
- **Column 17**: LOAN_REJECTED (boolean)
- **Column 18**: LOAN_CLEARED (boolean)

**Sample Data Verification:**
```
TRANSACTION_ID,LOAN_REVERSED,LOAN_REJECTED,LOAN_CLEARED
3033976,true,false,false         -- Reversed transaction
3034064,true,false,false         -- Reversed transaction
3026796,false,false,true         -- Cleared transaction
```

**Conclusion:** The query correctly includes these columns via `SELECT A.*` which captures all columns from the unioned CTEs. The columns are present in both the Snowflake table and the CSV export. **No changes needed.**

---

### 2. Transaction Date Differences vs LoanPro UI ✓ INVESTIGATED
**Issue:** Transaction dates in the file differ from what's shown in LoanPro UI.

**Investigation Results:**
- **Total Transactions**: 120,423
- **Different Dates**: 27,999 (23.25%)
- **Same Dates**: 92,424 (76.75%)
- **Average Difference**: -112 days (negative indicates TRANSACTION_DATE is earlier than APPLY_DATE)
- **Range**: -2,379 to +1,554 days

**Date Difference Patterns:**
1. **Normal ACH Delays (1-3 days)**: Most common - TRANSACTION_DATE slightly before APPLY_DATE
   - Example: TRANSACTION_DATE = 2023-01-04, APPLY_DATE = 2023-01-03 (1 day difference)
   - Typical for "Custom - User Forced" payment types

2. **Batch Posted Recoveries (77-152 days)**: "Write-Off Recovery" payments show large delays
   - Example: TRANSACTION_DATE = 2023-06-14, APPLY_DATE = 2023-08-30 (77 days)
   - APPLY_DATE appears to be when recovery was batch posted to system

3. **Scheduled Future Payments**: Some future TRANSACTION_DATEs with past APPLY_DATEs
   - Example: TRANSACTION_DATE = 2025-03-17, APPLY_DATE = 2024-08-09 (-220 days)
   - Represents scheduled future payments that were applied/posted on an earlier date

**Recommendation:**
- **Keep TRANSACTION_DATE as primary date** - represents when transaction occurred
- **Include APPLY_DATE** as separate column for transparency (currently mapped to EFFECTIVE_DATE)
- **LoanPro UI likely shows APPLY_DATE** - this explains the discrepancy user observed

---

### 3. UNPAID BALANCE Column Definition ✓ CONFIRMED
**Question:** What does the UNPAIDBALANCEDUE column represent?

**Answer:** Based on population query (lines 403-405), UNPAIDBALANCEDUE is calculated as:

```sql
UNPAIDBALANCEDUE =
    PRINCIPALBALANCEATCHARGEOFF
    + INTERESTBALANCEATCHARGEOFF
    - RECOVERIESPAIDTODATE
    - CHARGED_OFF_PRINCIPAL_ADJUSTMENT (if exists)
    - TOTALPRINCIPALWAIVED (if exists)
```

**Definition:** Total charged-off principal AND interest, minus any recoveries, adjustments, and waivers.

**Note:** This is NOT just charged-off principal - it includes both principal and interest balances at charge-off, then subtracts post-charge-off recoveries and adjustments.
