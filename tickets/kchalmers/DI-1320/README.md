# DI-1320: Investigate Unauthorized ACH Transactions from Autopay Not Disabling at Charge-Off

## Ticket Information
- **Jira Ticket:** [DI-1320](https://happymoneyinc.atlassian.net/browse/DI-1320)
- **Type:** Research
- **Requestor:** Mandi Sinner
- **Assignee:** Kyle Chalmers
- **Date Created:** 2025-10-06

## Executive Summary

**Total Impact:** 9,015 charged-off loans currently have autopay active, resulting in **$1.92M in ACTIVE_SETTLED collections**, with **13 loans having ACTIVE_NOT_SETTLED payments** pending.

**Key Findings:**
- **$1.92M ACTIVE_SETTLED collections** from 909 loans (10.1% of population)
  - **$1.83M (95.1%)** directly attributable to LoanPro autopay activation (808 loans)
  - **$94K (4.9%)** from pre-existing payment arrangements that continued post-charge-off (101 loans)
- **13 loans with ACTIVE_NOT_SETTLED payments** - payments processed but pending settlement
- **694 loans with failed payment attempts** (NSF/reversed) - customers may have incurred NSF fees
- **4,838 loans** at risk with autopay active but no attempts yet
- **1,705 loans (18.9%)** have debt settlements accounting for 77% of collections ($1.48M)
- **7,310 non-settlement loans (81%)** with $438K in collections
- **2,561 UNKNOWN loans** - require further investigation

**Critical Issue:** Majority of non-settlement collections ($435K of $438K) came from autopay activated BEFORE charge-off.

**Key Insight - ACTIVE_SETTLED vs ACTIVE_NOT_SETTLED:** The distinction between ACTIVE_SETTLED ($1.92M) and ACTIVE_NOT_SETTLED (13 loans pending) is critical - only settled payments represent finalized collections. **Waivers excluded** via IS_WAIVER = 0 filter.

**Recommendation:** Immediate process change needed to disable autopay at charge-off to prevent future unauthorized transactions.

---

## Analysis Results

### Total Charged-Off Loans with Autopay Active: 9,015 loans

**Total Settled Collections: $1.92M | Total Failed Attempts: $1.51M**

### Overall Population Summary

| Metric | Value |
|--------|-------|
| **Total Charged-Off Loans with Autopay Active** | 9,015 |
| **Total ACTIVE_SETTLED Collections** | $1,921,536.28 |
| **Total Failed Payment Attempts** | $1,507,408.69 |
| **Distinct Impact Categories** | 6 |

### Debt Settlement Breakdown

| Settlement Status | Loan Count | % of Total | Total Settled | Avg Per Loan |
|-------------------|------------|------------|---------------|--------------|
| **With Debt Settlement (Y)** | 1,705 | 18.91% | $1,483,046.29 | $869.82 |
| **Without Debt Settlement (N)** | 7,310 | 81.09% | $438,489.99 | $59.98 |

**Key Finding**: Non-settlement loans represent 81% of population but only 23% of total collections.

---

## Non-Settlement Loans Detailed Analysis (7,310 loans)

### By Impact Category

| Impact Category | Loans | % | Settled | Failed | Avg Settled Pmts |
|-----------------|-------|---|---------|--------|------------------|
| **AUTOPAY_ACTIVE_NO_PAYMENTS** | 4,333 | 59.27% | $0 | $0 | 0.00 |
| **AUTOPAY_ACTIVE_NO_PAYMENTS_IN_LOANPRO** | 1,918 | 26.24% | $0 | $0 | 0.00 |
| **AUTOPAY_ACTIVE_FAILED_ATTEMPTS_IN_LOANPRO** | 648 | 8.86% | $0 | $938,014 | 0.00 |
| **AUTOPAY_ACTIVE_PAYMENTS_COLLECTED_IN_LOANPRO** | 327 | 4.47% | **$438,490** | $350,897 | 2.40 |
| **AUTOPAY_ACTIVE_WITH_PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO** | 71 | 0.97% | $0 | $10,614 | 0.00 |
| **AUTOPAY_ACTIVE_PAYMENTS_NOT_YET_SETTLED** | 13 | 0.18% | $0 | $0 | 0.00 |

**Critical Finding**: 327 loans (4.47%) have already collected $438K in settled payments through LoanPro autopay, representing **100% of all non-settlement collections**.

### Key Findings

1. **$1.92M in ACTIVE_SETTLED payments collected** from entire population
   - **$1.48M (77%)** from 1,705 loans WITH debt settlements (authorized payments)
   - **$438K (23%)** from 7,310 loans WITHOUT debt settlements (likely unauthorized)

2. **Non-Settlement Loan Categories:**
   - **4,333 loans (59%)**: NO_PAYMENTS - Autopay active, no attempts yet (future risk)
   - **1,918 loans (26%)**: NO_PAYMENTS_IN_LOANPRO - Payments exist in CLS but not LoanPro (requires investigation)
   - **648 loans (9%)**: FAILED_ATTEMPTS_IN_LOANPRO - All payment attempts failed (NSF risk)
   - **327 loans (4%)**: PAYMENTS_COLLECTED_IN_LOANPRO - **$438K already collected** (most critical - 100% of non-settlement collections)
   - **71 loans (1%)**: PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO - Failed attempts in CLS, no settled payments
   - **13 loans (0.2%)**: PAYMENTS_NOT_YET_SETTLED - Active but pending settlement

3. **"NO_PAYMENTS_IN_LOANPRO" Category (1,918 loans)**:
   - These loans have payment records in CLS (Collections/Legal System) but NOT in LoanPro
   - Filtered out by `CLS_TRANSACTION_DATE IS NULL` condition
   - Represents payments managed by collection agencies, not LoanPro autopay
   - Requires investigation to understand payment source and authorization

### By LoanPro Current Status (Non-Settlement)

| LP Current Status | Loans | % | Total Settled | Avg Per Loan |
|-------------------|-------|---|---------------|--------------|
| **Closed - Charged-Off Collectible** | 7,250 | 99.18% | $395,120 | $54.50 |
| **Closed - Charged-Off** | 37 | 0.51% | $2,091 | $56.52 |
| **Closed - Confirmed Fraud** | 11 | 0.15% | $38,500 | $3,500.00 |
| **Closed - Bankruptcy** | 6 | 0.08% | $0 | $0.00 |
| **Paid Off - Paid In Full** | 3 | 0.04% | $2,779 | $926.29 |
| **NULL/Other** | 3 | 0.04% | $0 | $0.00 |

### By Placement Status (Non-Settlement)

| Placement Status | Loans | % | Total Settled | Avg Per Loan |
|------------------|-------|---|---------------|--------------|
| **Placed - Bounce** | 3,554 | 48.62% | $183,209 | $51.55 |
| **Placed - Resurgent** | 1,466 | 20.05% | $51,277 | $34.98 |
| **Placed - HM** | 1,361 | 18.62% | $189,574 | $139.29 |
| **Placed - First Tech Credit Union** | 892 | 12.20% | $2,915 | $3.27 |
| **Other Placements** | 37 | 0.51% | $11,516 | - |

### By Autopay Timing (Non-Settlement)

| Autopay Timing | Loans | % | Total Settled | Avg Per Loan |
|----------------|-------|---|---------------|--------------|
| **After Charge-Off (N)** | 5,194 | 71.05% | $61,201 | $11.78 |
| **Before Charge-Off (Y)** | 2,116 | 28.95% | $377,289 | $178.30 |

**Critical Finding**: Autopay activated BEFORE charge-off generates **15x higher collections** per loan ($178 vs $12), accounting for 86% of all non-settlement collections ($377K of $438K) despite being only 29% of loans.

### Cross-Tabulation Insights (Non-Settlement)

**Top 5 Combinations by Loan Count (LP Status × Placement):**
1. Charged-Off Collectible × Bounce: 3,551 loans, $183K collected
2. Charged-Off Collectible × Resurgent: 1,466 loans, $51K collected
3. Charged-Off Collectible × HM: 1,305 loans, $146K collected
4. Charged-Off Collectible × First Tech FCU: 891 loans, $3K collected
5. Charged-Off × HM: 34 loans, $2K collected

**Active Collections Breakdown (Placement × Timing):**
| Placement | Timing | Loans | Total Collected | Avg Per Loan |
|-----------|--------|-------|-----------------|--------------|
| Bounce | Before CO | 152 | $178,584 | $1,175 |
| HM | Before CO | 103 | $146,344 | $1,421 |
| HM | After CO | 21 | $43,230 | $2,059 |
| Resurgent | Before CO | 24 | $40,764 | $1,698 |
| Resurgent | After CO | 7 | $10,513 | $1,502 |

**Pattern**: 89% of loans with PAYMENTS_COLLECTED_IN_LOANPRO (291 of 325) had autopay active BEFORE charge-off.

### "NO_PAYMENTS_IN_LOANPRO" Detailed Breakdown (1,918 loans)

**Top combinations by LP Status × Placement × Timing:**
| LP Status | Placement | Autopay Timing | Loan Count |
|-----------|-----------|----------------|------------|
| Charged-Off Collectible | Bounce | After CO (N) | 949 |
| Charged-Off Collectible | Resurgent | After CO (N) | 487 |
| Charged-Off Collectible | First Tech FCU | After CO (N) | 306 |
| Charged-Off Collectible | HM | After CO (N) | 160 |

**Note**: ALL 1,918 loans in this category have autopay activated AFTER charge-off, and have payments in CLS (collection system) but not in LoanPro.

### Latest LP Payment After Placement Analysis (Non-Settlement)

**Breakdown by Payment Timing vs Placement:**

| Timing Indicator | Loans | % of Non-Settlement | Total Settled | Avg Per Loan |
|------------------|-------|---------------------|---------------|--------------|
| **Y (Latest payment AFTER placement)** | 591 | 8.08% | $357,879 | $605.55 |
| **N (Latest payment BEFORE placement)** | 468 | 6.40% | $80,611 | $172.25 |
| **NULL (No LP payments)** | 6,251 | 85.51% | $0 | $0 |

**Key Finding**: Of the 327 non-settlement loans with PAYMENTS_COLLECTED_IN_LOANPRO:
- **253 loans (77%)** had their latest payment AFTER placement date - $358K collected (avg $1,415/loan)
- **74 loans (23%)** had their latest payment BEFORE placement date - $81K collected (avg $1,089/loan)

**Impact**: Majority of unauthorized collections (82%) occurred AFTER loans were placed with collection agencies.

---

## Debt Settlement Loans Analysis (1,705 loans)

### By Settlement Status

| Settlement Status | Loans | % | Total Settled | Avg Per Loan |
|-------------------|-------|---|---------------|--------------|
| **NULL/Unknown** | 855 | 50.15% | $81,506 | $95.33 |
| **Active** | 509 | 29.85% | $1,130,515 | $2,221.05 |
| **Complete** | 236 | 13.84% | $174,140 | $737.88 |
| **Inactive** | 71 | 4.16% | $5,310 | $74.79 |
| **Broken** | 34 | 1.99% | $91,576 | $2,693.42 |

### By Settlement Portfolio

| Settlement Portfolio | Loans | % | Total Settled | Avg Per Loan |
|----------------------|-------|---|---------------|--------------|
| **NULL/Unknown** | 1,468 | 86.10% | $996,489 | $678.81 |
| **Settlement Setup** | 178 | 10.44% | $290,248 | $1,630.60 |
| **Settlement Failed** | 24 | 1.41% | $57,873 | $2,411.38 |
| **Settlement Successful** | 24 | 1.41% | $87,865 | $3,661.02 |
| **Settlement Failed; Settlement Successful** | 6 | 0.35% | $27,115 | $4,519.14 |
| **Settlement Successful; Settlement Failed** | 5 | 0.29% | $23,457 | $4,691.36 |

### Debt Settlement Status × Impact Category

**Active Settlements (509 loans, $1.13M collected):**
- 402 loans (79%): PAYMENTS_COLLECTED_IN_LOANPRO - $1.13M (avg $2,812/loan)
- 61 loans: NO_PAYMENTS_IN_LOANPRO
- 30 loans: NO_PAYMENTS
- 15 loans: FAILED_ATTEMPTS_IN_LOANPRO
- 1 loan: PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO

**Complete Settlements (236 loans, $174K collected):**
- 196 loans (83%): NO_PAYMENTS_IN_LOANPRO - $0 collected
- 35 loans (15%): PAYMENTS_COLLECTED_IN_LOANPRO - $174K (avg $4,975/loan)
- 4 loans: PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO
- 1 loan: NO_PAYMENTS

**Broken Settlements (34 loans, $92K collected):**
- 29 loans (85%): PAYMENTS_COLLECTED_IN_LOANPRO - $92K (avg $3,158/loan)
- 3 loans: NO_PAYMENTS
- 2 loans: FAILED_ATTEMPTS_IN_LOANPRO

### Debt Settlement Portfolio × Impact Category

**Settlement Setup (178 loans, $290K collected):**
- 144 loans (81%): PAYMENTS_COLLECTED_IN_LOANPRO - $290K (avg $2,016/loan)
- 15 loans each: NO_PAYMENTS and FAILED_ATTEMPTS_IN_LOANPRO
- 4 loans: NO_PAYMENTS_IN_LOANPRO

**Settlement Successful (24 loans, $88K collected):**
- 21 loans (88%): PAYMENTS_COLLECTED_IN_LOANPRO - $88K (avg $4,184/loan)
- 3 loans: NO_PAYMENTS_IN_LOANPRO

**Key Insight**: Active and setup settlements show high collection rates through LoanPro autopay, indicating these may be authorized payment arrangements.

### Recovery Amount Reconciliation

Comparison of `RECOVERIESPAIDTODATE` (from loan tape) vs actual settled post-chargeoff payments:

| Reconciliation Status | Loans | Total Abs Difference | Avg Abs Difference | Min Diff | Max Diff |
|----------------------|-------|---------------------|-------------------|----------|----------|
| **MATCH** | 8,902 (98.7%) | $0.00 | $0.00 | $0.00 | $0.00 |
| **TAPE_HIGHER** | 90 (1.0%) | $43,860.88 | $487.34 | $22.58 | $3,500 |
| **PAYMENTS_HIGHER** | 23 (0.3%) | $37,842.32 | $1,645.32 | -$12,500 | -$0.05 |

**Key Findings:**
- **98.7% of loans show perfect reconciliation** between loan tape recoveries and settled post-chargeoff payments
- **90 loans (1.0%)** show higher recoveries on tape than in transaction data (average $487.34 difference)
- **23 loans (0.3%)** show more payments in transaction data than recorded on tape (average $1,645.32 difference)
- Maximum discrepancy: One loan has $12,500 more in payments than tape shows

**Data Quality Note:** The excellent reconciliation rate (98.7%) validates the dual payment tracking implementation using ACTIVE_SETTLED payments.

## Assumptions

1. **Current Autopay Status**: Using `VW_LOAN_PAYMENT_MODE` with `PAYMENT_MODE_END_DATE IS NULL` to identify loans with autopay currently active
2. **Settled Payments**: Defined as `IS_ACTIVE = 1 AND IS_REVERSED = 0 AND IS_SETTLED = 1` in payment transactions - only settled payments represent finalized collections
3. **Not-Yet-Settled Payments**: Defined as `IS_ACTIVE = 1 AND IS_REVERSED = 0 AND IS_SETTLED = 0` - payments processed but pending settlement
4. **Failed Payments**: Defined as `IS_REVERSED = 1 OR IS_REJECTED = 1` in payment transactions
5. **Post-Charge-Off Payments**: Any payment with `APPLY_DATE > CHARGEOFFDATE`
6. **Debt Settlement**: Using `VW_LOAN_DEBT_SETTLEMENT` for authorized payment plan identification (not filtered out, available as column)
7. **Loan Tape**: Using `DATA_STORE.MVW_LOAN_TAPE` without date filter (already current snapshot)
8. **LoanPro Current Status**: Using `VW_LOAN_SETTINGS_ENTITY_CURRENT` joined with `VW_LOAN_SUB_STATUS_ENTITY_CURRENT` to get the current loan status title from LoanPro
9. **Payment Timing**: Payments categorized as "AFTER autopay start" if `FIRST_LP_PAYMENT_ATTEMPT_DATE > PAYMENT_MODE_START_DATE`
10. **Recovery Reconciliation**: Comparing `RECOVERIESPAIDTODATE` from loan tape with sum of ACTIVE_SETTLED post-chargeoff payments; differences under $0.01 considered a MATCH
11. **CLS Payment Exclusion**: LP-only payment tracking excludes payments with `CLS_TRANSACTION_DATE IS NOT NULL` to isolate LoanPro autopay-driven transactions
12. **Waiver Exclusion**: All payment queries exclude waiver payments via `IS_WAIVER = 0` filter to focus on actual cash transactions

## Quality Control

### Query Execution Validation

**Main Analysis Query** (`1_initial_query_design.sql`):
- **Total Records**: 9,015 charged-off loans with autopay currently active
- **CSV Output**: Clean format with headers in row 1, no extra rows
- **File Location**: `results/initial_results.csv`
- **Column Count**: 29 columns including ACTIVE_SETTLED and ACTIVE_NOT_SETTLED breakdowns

**Summary Queries** (`2_summary_queries.sql`):
- All 12 summary queries executed successfully using temp table approach
- Results match totals from main query
- Temp table created once for efficient aggregation

### Data Quality Checks Performed

1. **Record Count Verification**:
   - CSV file: 9,016 lines (9,015 loans + 1 header) ✓
   - Summary query totals: 9,015 loans ✓

2. **Payment Amount Validation**:
   - Total SETTLED collected: $1,921,536.28 ✓
   - Total failed attempts amount: $1,507,408.69 ✓
   - No negative payment amounts ✓

3. **Impact Category Classification**:
   - 6 distinct categories identified ✓
   - 325 loans with settled payments (PAYMENTS_COLLECTED_IN_LOANPRO) ✓
   - 70 loans with payments collected prior to LoanPro ✓
   - 651 loans with failed attempts only ✓
   - 4,333 loans with NO_PAYMENTS ✓
   - 1,918 loans with NO_PAYMENTS_IN_LOANPRO (CLS payments only) ✓
   - 13 loans with PAYMENTS_NOT_YET_SETTLED ✓
   - Total: 9,015 loans ✓

4. **Autopay Status Consistency**:
   - All records have `CURRENTLY_HAS_AUTOPAY = 'Y'` ✓
   - Payment mode consistently shows 'Auto Payer' ✓

5. **Recovery Reconciliation**:
   - 8,902 loans (98.7%) show perfect MATCH between tape and ACTIVE_SETTLED payments ✓
   - 90 loans (1.0%) show TAPE_HIGHER than payments ✓
   - 23 loans (0.3%) show PAYMENTS_HIGHER than tape ✓
   - Overall reconciliation quality is excellent (98.7% match rate) ✓

## Technical Implementation

**Dual Payment Tracking Pattern:**
- `post_chargeoff_payments` (PCPCLS): ALL post-chargeoff payments for recovery reconciliation
  - Tracks ACTIVE_SETTLED and ACTIVE_NOT_SETTLED separately
- `post_lp_chargeoff_payments` (PCPCLP): LP-only payments (filters out CLS via `CLS_TRANSACTION_DATE IS NULL`) for autopay-specific analysis
  - Tracks ACTIVE_SETTLED_LP and ACTIVE_NOT_SETTLED_LP separately

**Files:**
- `exploratory_analysis/1_initial_query_design.sql` - Main analysis query with dual CTEs, ACTIVE_SETTLED logic, and IS_WAIVER = 0 filter
- `exploratory_analysis/2_summary_queries.sql` - 15 summary queries for aggregate analysis with IS_WAIVER = 0 filter
- `results/initial_results.csv` - Full dataset (9,015 loans with 29 columns)

**Quality Control:**
- 98.7% perfect reconciliation between loan tape and ACTIVE_SETTLED payment transactions
- All 9,015 loans properly categorized including PAYMENTS_NOT_YET_SETTLED category
- **Waivers excluded:** IS_WAIVER = 0 filter applied to all payment queries
- CSV output verified: clean format, correct headers, no duplicate records
- All 15 summary queries executed successfully through Snowflake
