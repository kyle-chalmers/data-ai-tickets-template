# ticket-2 Analysis Comparison Report

## Executive Summary

**Critical Finding:** The ticket-2 analysis went through three iterations to reach accurate results:

| Metric | Incomplete (Oct 6) | Incorrect (Oct 15) | **CORRECTED (Oct 16)** |
|--------|-------------------|-------------------|----------------------|
| **Total Loans** | 501 | 20,966 | **4,411** |
| **Indicators Checked** | 1 (Settlement only) | 4 (All requested) | **4 (Corrected)** |
| **DebtBuyerA Placements** | 468 (93.4%) | 13,760 (65.6%) | **3,234 (73.3%)** |
| **DebtBuyerB Placements** | 33 (6.6%) | 7,206 (34.4%) | **1,177 (26.7%)** |
| **Primary Issue** | Settlement only | Future payments (99.8%) | **Settlement (88.4%)** |

## Analysis Evolution

### Version 1: Incomplete Analysis (October 6, 2025)
❌ **Only checked:** Settlement conflicts
❌ **Missing:** Post-chargeoff payments, AutoPay status, Future scheduled payments
❌ **Result:** 501 loans identified

### Version 2: Comprehensive but Incorrect (October 15, 2025)
✅ **Attempted all 4 indicators**
❌ **Critical Error:** Used VW_LOAN_SCHED_FCST_PAYMENTS (amortization schedule projections)
❌ **False Positive Rate:** 99.8% (20,932 of 20,966 loans)
❌ **Result:** 20,966 loans with incorrect "future payments" indicator

### Version 3: CORRECTED Analysis (October 16, 2025)
✅ **Settlement Conflicts:** 3,901 loans (88.4%) - PRIMARY ISSUE
✅ **Post-Chargeoff Payments:** 1,328 loans (30.1%)
✅ **Active/Pending Autopay:** 59 loans (1.3%)
✅ **Future Payment Transactions:** 0 loans (0.0%)
✅ **Result:** 4,411 loans with accurate conflict identification

## The False Positive Investigation

### What Went Wrong
The October 15 analysis used `VW_LOAN_SCHED_FCST_PAYMENTS` assuming it contained actual payment obligations. This view actually contains **amortization schedule projections** that persist after chargeoff, not real future payments.

**Evidence of False Positives:**
- 94,412 total loans have "future" schedule entries
- 42,865 charged-off loans have these entries
- 20,932 placed charged-off loans flagged (99.8%)
- These are mathematical projections, not actual obligations

### Investigation Process
1. **User questioned results:** "that does not seem right. explore different options"
2. **Explored underlying views:** VW_COMMON_PAYMENT_TRANSACTIONS, VW_SYSTEM_PAYMENT_TRANSACTION
3. **Discovered correct sources:**
   - `LOAN_AUTOPAY_ENTITY` - Actual pending/processing autopay transactions
   - `VW_SYSTEM_PAYMENT_TRANSACTION` with `APPLY_DATE > CURRENT_DATE()` - Actual scheduled payments
4. **Validated findings:** Only 1,817 total loans have future payment transactions, 0 for placed charged-off loans
5. **Rewrote query** with corrected indicators

### Corrected Approach

**REMOVED (Incorrect):**
```sql
-- VW_LOAN_SCHED_FCST_PAYMENTS - amortization schedule projections
future_scheduled_payments AS (
    SELECT LOAN_ID, COUNT(*), MIN(DATE), SUM(PAYMENT_AMOUNT)
    FROM VW_LOAN_SCHED_FCST_PAYMENTS
    WHERE DATE > CURRENT_DATE() AND FUTURE = 1
)
```

**ADDED (Correct):**
```sql
-- LOAN_AUTOPAY_ENTITY - actual pending/processing autopay
active_pending_autopay AS (
    SELECT ap.LOAN_ID, ap.TYPE, MIN(ap.APPLY_DATE), COUNT(*)
    FROM RAW_DATA_STORE.LOANPRO.LOAN_AUTOPAY_ENTITY ap
    WHERE ap.SCHEMA_NAME = ARCA.CONFIG.loan_management_system_SCHEMA()
      AND ap.ACTIVE = 1
      AND ap.STATUS IN ('autopay.status.pending', 'autopay.status.processing')
    GROUP BY ap.LOAN_ID, ap.TYPE
)

-- VW_SYSTEM_PAYMENT_TRANSACTION - actual scheduled payments
future_payment_transactions AS (
    SELECT pt.LOAN_ID, COUNT(*), MIN(pt.APPLY_DATE)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_SYSTEM_PAYMENT_TRANSACTION pt
    WHERE pt.APPLY_DATE > CURRENT_DATE()
    GROUP BY pt.LOAN_ID
)
```

## Conflict Type Analysis

### Corrected Results (October 16, 2025)

| Conflict Type | Loan Count | Percentage | Change from Incorrect |
|---------------|------------|------------|----------------------|
| Settlement Conflicts | 3,901 | 88.4% | No change (accurate) |
| Post-Chargeoff Payments | 1,328 | 30.1% | No change (accurate) |
| Active/Pending Autopay | 59 | 1.3% | +59 (was 0) |
| Future Payment Transactions | 0 | 0.0% | -20,932 (false positives) |

**Conflict Count Distribution:**
- Single Conflict: 3,553 loans (80.6%)
- Two Conflicts: 839 loans (19.0%)
- Three Conflicts: 19 loans (0.4%)

**Settlement Status Details (3,901 loans):**
- Closed - Charged-Off Collectible: 3,894 loans (99.8%)
- Closed - Charged-Off: 5 loans (0.1%)
- Open - Repaying: 1 loan (<0.1%)
- Closed - Bankruptcy: 1 loan (<0.1%)

**Post-Chargeoff Payment Impact (1,328 loans):**
- Total Collected: $3,746,599
- Average Per Loan: $2,821.23
- Payment Transactions: 5,288 total

## Business Impact Analysis

### Incorrect Analysis Impact (What We Avoided)
- **Would have flagged:** 20,966 loans for review
- **False alarm rate:** 79% (16,555 loans incorrectly flagged)
- **Business consequence:** Wasted operations resources, undermined trust in analysis
- **Root cause:** Using amortization schedule instead of actual obligations

### Corrected Analysis Impact
- **Correctly identified:** 4,411 loans with actual placement conflicts
- **Primary Issue:** Settlement conflicts (88.4%) - loans with debt buyers shouldn't have settlement arrangements
- **Financial Risk:** $3.7M in post-chargeoff payments from placed loans
- **Operational Risk:** 59 loans with active autopay could route payments incorrectly

### Prioritized Action Items
1. **Settlement Conflicts (3,901 loans):** Review settlement arrangements on placed loans
2. **Multi-Conflict Loans (858 loans):** Immediate attention for 2+ conflicts
3. **Payment Collections (1,328 loans):** Audit $3.7M collected from placed loans
4. **Active Autopay (59 loans):** Disable or redirect autopay transactions

## Technical Learnings

### Key Insight: Schedule vs. Obligations
**VW_LOAN_SCHED_FCST_PAYMENTS** is for amortization schedule analysis, not identifying actual payment obligations. It shows what payments *would be* if the loan continued on schedule, not what payments *are scheduled*.

**Correct Sources for Payment Obligations:**
- **Actual Autopay:** `LOAN_AUTOPAY_ENTITY` with `ACTIVE=1` and `STATUS='pending/processing'`
- **Actual Scheduled Payments:** `VW_SYSTEM_PAYMENT_TRANSACTION` with `APPLY_DATE > CURRENT_DATE()`

### Data Source Comparison

| Source | Purpose | Correct Use |
|--------|---------|-------------|
| VW_LOAN_SCHED_FCST_PAYMENTS | Amortization schedule projections | Financial modeling, forecasting |
| LOAN_AUTOPAY_ENTITY | Actual autopay transactions | Identifying pending autopay |
| VW_SYSTEM_PAYMENT_TRANSACTION | Payment history and future transactions | Actual scheduled payments |

## Recommendations

### Immediate Actions
1. **Review 3,901 settlement conflicts:** Primary data quality issue
2. **Investigate 59 autopay conflicts:** Prevent payment routing errors
3. **Audit $3.7M in collections:** Compliance review for placed loans
4. **Prioritize 858 multi-conflict loans:** Handle cases with multiple issues first

### Data Quality Improvements
1. **Settlement Workflow Validation:** Prevent settlements on placed loans
2. **Automated Monitoring:** Alert on new settlement/placement conflicts
3. **Documentation:** Clarify when to use schedule vs. transaction views
4. **Testing Standards:** Validate indicator logic with known examples

### Analysis Process Improvements
1. **Sanity Check Results:** Question 99.8% rates before finalizing
2. **Understand Data Structures:** Investigate view purposes and underlying data
3. **Validate with Subject Matter Experts:** Confirm interpretations
4. **Test with Known Cases:** Use specific loans to verify logic

## Conclusion

The ticket-2 analysis demonstrates the importance of:
1. **Questioning unexpected results:** 99.8% rate triggered investigation
2. **Understanding data semantics:** Schedule projections ≠ actual obligations
3. **Thorough validation:** Prevented 16,555 false positives (79% error rate)
4. **Iterative refinement:** Three versions to reach accurate results

**Final accurate analysis identifies 4,411 loans with real placement conflicts, primarily settlement-related (88.4%), requiring business review and remediation.**

**Total Correction Impact:** Reduced from 20,966 loans (79% false positives) to 4,411 loans (accurate identification of actual conflicts).
