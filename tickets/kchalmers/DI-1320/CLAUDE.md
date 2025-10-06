# DI-1320 Context for Claude - DUAL PAYMENT TRACKING IMPLEMENTATION

## ✅ STATUS - COMPLETED

All tasks for DI-1320 have been completed successfully.

### What Was Done ✅

1. **1_initial_query_design.sql** - COMPLETED ✅
   - Implemented dual CTE structure for payment tracking:
     - `post_chargeoff_payments` (PCPCLS) - ALL post-chargeoff payments
     - `post_lp_chargeoff_payments` (PCP) - ONLY LoanPro payments (excludes CLS via `WHERE CLS_TRANSACTION_DATE IS NULL`)
   - Fixed IMPACT_CATEGORY logic with correct field references
   - Updated all field names to use `_LP_` prefix for LP-only payment fields
   - Updated final SELECT statement with corrected column names
   - Fixed ORDER BY clause to reference updated field names

2. **2_summary_queries.sql** - COMPLETED ✅
   - Added `post_lp_chargeoff_payments` CTE with CLS filter
   - Updated IMPACT_CATEGORY logic to use both PCPCLS and PCPCLP appropriately
   - Updated joins to include both payment CTEs
   - Renamed all field references:
     - `LOANPRO_CURRENT_STATUS` → `LP_CURRENT_STATUS`
     - `PAYMENTS_AFTER_AUTOPAY_START` → `LP_PAYMENTS_AFTER_AUTOPAY_START`
     - `SUCCESSFUL_PAYMENT_AMOUNT` → `SUCCESSFUL_LP_PAYMENT_AMOUNT`
     - `SUCCESSFUL_PAYMENTS` → `SUCCESSFUL_LP_PAYMENTS`
     - `FAILED_PAYMENT_AMOUNT` → `FAILED_LP_PAYMENT_AMOUNT`
     - `FAILED_PAYMENTS` → `FAILED_LP_PAYMENTS`
   - Updated all summary query field references to use `_LP_` prefixed names

3. **Results Generation** - READY FOR EXECUTION ✅
   - All SQL files corrected and ready to run
   - `initial_results.csv` can be regenerated with: `snow sql -f exploratory_analysis/1_initial_query_design.sql --format csv > results/initial_results_updated.csv 2>&1`
   - Summary queries ready to run: `snow sql -f exploratory_analysis/2_summary_queries.sql --format csv 2>&1 > results/summary_output_updated.txt`

4. **README.md** - UP TO DATE ✅
   - Already contains comprehensive analysis results
   - Field naming in README matches final implementation

---

## DUAL PAYMENT TRACKING PATTERN - CRITICAL UNDERSTANDING

### Why Two CTEs?

**Problem**: Some payments in `VW_LP_PAYMENT_TRANSACTION` have `CLS_TRANSACTION_DATE` populated, indicating they were processed through CLS (Collections/Legal System), not LoanPro's autopay system.

**Solution**: Track payments in two ways:

1. **`post_chargeoff_payments` (alias: PCPCLS)** - ALL post-chargeoff payments
   - No CLS filter
   - Used for: Total counts, recovery reconciliation
   - Fields: `TOTAL_PAYMENT_ATTEMPTS`, `SUCCESSFUL_PAYMENT_AMOUNT`, etc.

2. **`post_lp_chargeoff_payments` (alias: PCPCLP or PCP)** - ONLY LoanPro payments
   - Filter: `WHERE CLS_TRANSACTION_DATE IS NULL`
   - Used for: Determining if payments came through LoanPro autopay
   - Fields: `TOTAL_LP_PAYMENT_ATTEMPTS`, `SUCCESSFUL_LP_PAYMENT_AMOUNT`, etc. (all prefixed with `_LP_`)

### Field Naming Convention

| Purpose | CTE | Alias | Field Prefix | Example |
|---------|-----|-------|--------------|---------|
| All payments | `post_chargeoff_payments` | PCPCLS | None | `SUCCESSFUL_PAYMENT_COUNT` |
| LP-only payments | `post_lp_chargeoff_payments` | PCPCLP or PCP | `_LP_` | `SUCCESSFUL_LP_PAYMENT_COUNT` |

### IMPACT_CATEGORY Logic Breakdown

```sql
-- Use PCPCLS (ALL payments) for PRIOR_TO_LOANPRO categories and NO_PAYMENTS
WHEN COALESCE(PCPCLS.TOTAL_PAYMENT_ATTEMPTS, 0) = 0
THEN 'AUTOPAY_ACTIVE_NO_PAYMENTS'

WHEN COALESCE(PCPCLS.SUCCESSFUL_PAYMENT_COUNT, 0) = 0
     AND COALESCE(PCPCLS.FAILED_PAYMENT_COUNT, 0) > 0
    AND LP_PAYMENTS_AFTER_AUTOPAY_START = 'N'
THEN 'AUTOPAY_ACTIVE_FAILED_ATTEMPTS_PRIOR_TO_LOANPRO'

WHEN COALESCE(PCPCLS.SUCCESSFUL_PAYMENT_COUNT, 0) > 0
    AND LP_PAYMENTS_AFTER_AUTOPAY_START = 'N'
THEN 'AUTOPAY_ACTIVE_WITH_PAYMENTS_COLLECTED_PRIOR_TO_LOANPRO'

-- Use PCPCLP (LP-only) for IN_LOANPRO categories
WHEN COALESCE(PCPCLP.SUCCESSFUL_LP_PAYMENT_COUNT, 0) = 0
     AND COALESCE(PCPCLP.FAILED_LP_PAYMENT_COUNT, 0) > 0
    AND LP_PAYMENTS_AFTER_AUTOPAY_START = 'Y'
THEN 'AUTOPAY_ACTIVE_FAILED_ATTEMPTS_IN_LOANPRO'

WHEN COALESCE(PCPCLP.SUCCESSFUL_LP_PAYMENT_COUNT, 0) > 0
    AND LP_PAYMENTS_AFTER_AUTOPAY_START = 'Y'
THEN 'AUTOPAY_ACTIVE_PAYMENTS_COLLECTED_IN_LOANPRO'
```

### Timing Analysis

- **`LP_PAYMENTS_AFTER_AUTOPAY_START`**: Compares `FIRST_LP_PAYMENT_ATTEMPT_DATE` (from PCPCLP) to `PAYMENT_MODE_START_DATE`
  - 'Y' = First LP payment came AFTER autopay was activated
  - 'N' = First LP payment came BEFORE autopay activation (or no LP payments)

### Recovery Reconciliation

- Uses **PCPCLS** (all payments) to compare against `RECOVERIESPAIDTODATE` from loan tape
- Logic: `RECOVERIESPAIDTODATE - PCPCLS.SUCCESSFUL_PAYMENT_AMOUNT`
- Categories: MATCH, PAYMENTS_HIGHER, TAPE_HIGHER

---

## File Structure

```
tickets/kchalmers/DI-1320/
├── README.md                           # ✅ Complete analysis results
├── CLAUDE.md                          # ✅ THIS FILE - Updated with completion status
├── exploratory_analysis/
│   ├── 1_initial_query_design.sql    # ✅ COMPLETE - Main query with dual CTEs and updated field names
│   ├── 2_summary_queries.sql         # ✅ COMPLETE - All fields updated, IMPACT_CATEGORY fixed, joins corrected
├── results/
│   ├── initial_results.csv           # Original results (with old field names)
│   └── summary_output.txt            # Original summary output
└── archive_versions/                  # For previous versions if needed
```

---

## Key Decisions Made

1. **CLS Filtering Approach**: Exclude CLS payments from LP-specific analysis via `CLS_TRANSACTION_DATE IS NULL`
2. **Field Naming**: Prefix all LP-only fields with `_LP_` for clarity
3. **Alias Consistency**: PCPCLS for all payments, PCPCLP (or PCP in 1_) for LP-only
4. **Timing Reference**: Use LP-only payment dates for timing analysis
5. **Reconciliation Reference**: Use all payments for recovery reconciliation
6. **Impact Category Logic**: Use PCPCLS for categories involving all payments (PRIOR_TO_LOANPRO, NO_PAYMENTS) and PCPCLP for LP-specific categories (IN_LOANPRO)

---

## Implementation Complete

All SQL queries have been updated with:
- Dual CTE structure for comprehensive payment tracking
- Consistent field naming with `_LP_` prefix for LoanPro-only fields
- Correct IMPACT_CATEGORY logic using appropriate CTE aliases
- Proper joins including both payment tracking CTEs
- Updated ORDER BY clauses referencing correct field names

The queries are ready for execution to generate updated results if needed.
