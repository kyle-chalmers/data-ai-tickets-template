# ticket-2: Loans Placed with DebtBuyerA or DebtBuyerB - Data Quality Analysis

## Ticket Information
- **Jira Link:** https://happymoneyinc.atlassian.net/browse/ticket-2
- **Type:** Data Pull
- **Status:** In Progress
- **Assignee:** Data Analyst
- **Branch:** `DI-1254_and_ticket-2`

## Business Context

### Problem Statement
Data quality discrepancies have been identified with loans marked as placed with DebtBuyerA or DebtBuyerB. These loans show evidence of:
1. Active or completed settlement arrangements
2. Post-chargeoff payments being received
3. AutoPay still enabled
4. Future scheduled payments in the system

These indicators suggest that the placement status in loan_management_system settings does not reflect the true status of the account, potentially causing:
- Incorrect routing of payments
- Customer confusion
- Collections conflicts
- Regulatory compliance concerns

### Business Impact
Identifying these discrepancies allows the collections and servicing teams to:
- Correct placement status data in loan_management_system
- Prevent future payment routing errors
- Resolve customer service issues proactively
- Ensure accurate debt buyer reporting

## Deliverables

### SQL Files
1. **`1_placement_settlement_conflicts.sql`** - Main analysis query
   - Identifies charged-off loans with DebtBuyerA/DebtBuyerB placement status
   - Filters for active or completed settlements
   - Outputs data quality conflicts for business remediation

### QC Queries
1. **`qc_queries/1_comprehensive_qc.sql`** - DuckDB-based CSV analysis covering:
   - Record counts and uniqueness validation
   - Placement status distribution (DebtBuyerA vs DebtBuyerB)
   - Conflict type breakdown (all 4 indicators)
   - Conflict count distribution (single vs multiple issues)
   - Settlement status breakdown
   - Charge-off date range
   - Conflict overlap cross-tabulation
   - Payment and scheduling statistics

### Output File
- **`placement_data_quality_analysis.csv`** - 20,966 loans requiring placement status review with conflict indicators

## Data Fields

| Field Name | Description | Source |
|------------|-------------|--------|
| LOAN_ID | loan_management_system loan identifier | VW_LOAN |
| LEGACY_LOAN_ID | CLS legacy loan identifier | VW_LOAN |
| LEAD_GUID | Universal loan identifier | VW_LOAN |
| PLACEMENT_STATUS | Current placement (DebtBuyerA/DebtBuyerB) | VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT |
| CHARGEOFF_DATE | Date loan was charged off | VW_LOAN |
| CHARGEOFF_PRINCIPAL_AMOUNT | Principal balance at chargeoff | VW_LOAN |
| TOTAL_PAYMENTS_POST_CHARGEOFF | Sum of all payments after chargeoff date | VW_SYSTEM_PAYMENT_TRANSACTION |
| POST_CHARGEOFF_PAYMENT_COUNT | Number of payments after chargeoff | VW_SYSTEM_PAYMENT_TRANSACTION |
| CURRENT_PRINCIPAL_BALANCE | Current outstanding principal | VW_LOAN |
| AUTOPAY_STATUS | Whether AutoPay is enabled (Y/N) | VW_LOAN |
| FUTURE_SCHEDULED_PAYMENTS | Whether future payments are scheduled (Y/N) | VW_PAYMENT_SCHEDULE_ENTITY_CURRENT |
| NEXT_SCHEDULED_PAYMENT_DATE | Next scheduled payment date | VW_PAYMENT_SCHEDULE_ENTITY_CURRENT |
| SETTLEMENT_STATUS | Debt settlement status | VW_LOAN_DEBT_SETTLEMENT |
| SETTLEMENT_ACCEPTED_DATE | Date settlement accepted | VW_LOAN_DEBT_SETTLEMENT |
| SETTLEMENT_COMPLETION_DATE | Date settlement completed | VW_LOAN_DEBT_SETTLEMENT |
| SETTLEMENT_AMOUNT | Total settlement amount | VW_LOAN_DEBT_SETTLEMENT |
| SETTLEMENT_AMOUNT_PAID | Amount paid toward settlement | VW_LOAN_DEBT_SETTLEMENT |
| LOAN_STATUS_TEXT | Current loan status | VW_LOAN |
| LOAN_SUB_STATUS_TEXT | Current loan sub-status | VW_LOAN |

## Query Logic

### Inclusion Criteria
- Loan has chargeoff date (CHARGE_OFF_DATE IS NOT NULL)
- Placement status = 'DebtBuyerA' OR 'DebtBuyerB'
- **AND** at least one of the following data quality conflicts:
  1. **Settlement Conflict**: CURRENT_STATUS <> 'Closed - Settled in Full' in VW_LOAN_DEBT_SETTLEMENT
  2. **Post-Chargeoff Payments**: Payments received after chargeoff date (IS_SETTLED = TRUE, not reversed/rejected)
  3. **Active/Pending Autopay**: ACTIVE=1 and STATUS IN ('pending', 'processing') in LOAN_AUTOPAY_ENTITY
  4. **Future Payment Transactions**: APPLY_DATE > CURRENT_DATE() in VW_SYSTEM_PAYMENT_TRANSACTION (actual scheduled payments)

### Data Sources
- **BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN** - Core loan data (numeric LOAN_ID for joins)
- **BUSINESS_INTELLIGENCE.BRIDGE.VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT** - Placement status
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT** - Settlement information (join on LEAD_GUID - LOAN_ID is TEXT)
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_SYSTEM_PAYMENT_TRANSACTION** - Post-chargeoff payment history AND future payment transactions
- **RAW_DATA_STORE.LOANPRO.LOAN_AUTOPAY_ENTITY** - Active/pending autopay transactions (actual pending/processing autopay)

## Assumptions Made

### 1. Post-Chargeoff Payment Definition
**Assumption:** Post-chargeoff payments are any payments where:
- `IS_SETTLED = TRUE`
- `IS_REVERSED <> TRUE`
- `IS_REJECTED <> TRUE`
- `TRANSACTION_DATE > CHARGEOFF_DATE`

**Reasoning:** These represent actual successful payments received after the loan was charged off, indicating potential data quality issues with placement status.

**Impact:** Excludes reversed or rejected payment attempts, focusing only on settled payments that represent real cash flow conflicts with placement status.

### 2. AutoPay Status Source
**Assumption:** AutoPay status is determined from `VW_LOAN.AUTOPAY_ENABLED` field.

**Reasoning:** This is the most current AutoPay setting in loan_management_system.

**Impact:** Identifies loans where AutoPay is still active despite being placed with a debt buyer.

### 3. Future Scheduled Payment Criteria
**Assumption:** Future scheduled payments are those where:
- `EXPECTED_PAYMENT_DATE > CURRENT_DATE()`
- From VW_PAYMENT_SCHEDULE_ENTITY_CURRENT

**Reasoning:** Active payment schedules indicate the loan is still being serviced internally, conflicting with placement status.

**Impact:** Highlights scheduling system discrepancies that could cause payment routing errors.

### 4. Settlement Status Categorization
**Assumption:** Settlement conflicts exist when:
- `CURRENT_STATUS <> 'Closed - Settled in Full'` in VW_LOAN_DEBT_SETTLEMENT
- Includes statuses like 'Closed - Charged-Off Collectible', 'Open - Repaying', 'Closed - Bankruptcy', etc.

**Reasoning:** Any settlement record that is NOT fully settled represents a potential conflict with placement status, as it indicates ongoing settlement activity or incomplete settlement arrangements.

**Impact:** Identifies 3,901 loans with settlement conflicts, representing loans that should not be placed while settlement arrangements are active or incomplete.

### 5. TEXT vs NUMBER LOAN_ID Join Strategy
**Technical Solution:** Different views use different data types for LOAN_ID, requiring bridge joins:
- **VW_LOAN_DEBT_SETTLEMENT.LOAN_ID** is TEXT → Join on LEAD_GUID instead
- **VW_LOAN_PAYMENT_MODE.LOAN_ID** is TEXT → Bridge through VW_LOAN.LEGACY_LOAN_ID
- **VW_LOAN_SCHED_FCST_PAYMENTS.LOAN_ID** is NUMBER → Direct join on VW_LOAN.LOAN_ID

**Reasoning:** Prevents "Numeric value 'LAI-00XXXXXX' is not recognized" errors by using appropriate join columns for each view's data type.

**Impact:** Enables comprehensive 4-indicator analysis across all data sources without type conversion errors.

## Execution Instructions

### Step 1: Run Main Query
```bash
cd /Users/analyst/Development/data-intelligence-tickets
snow sql -f tickets/examples/ticket-2/final_deliverables/1_placement_data_quality_analysis.sql --format csv -o header=true -o timing=false > tickets/examples/ticket-2/final_deliverables/placement_data_quality_analysis.csv
```

### Step 2: Run QC Queries (DuckDB)
```bash
# Run all QC queries individually or execute the SQL file with DuckDB
cd tickets/examples/ticket-2/final_deliverables
duckdb -c "SELECT * FROM read_csv_auto('placement_data_quality_analysis.csv', header=true) LIMIT 5"

# Or execute specific QC queries from the file
# See qc_queries/1_comprehensive_qc.sql for all validation queries
```

### Step 3: Review Results
- Open `placement_data_quality_analysis.csv`
- Review record counts from QC queries
- Document any anomalies or unexpected patterns

## Quality Control

### Expected QC Results
- **No duplicate LOAN_IDs** - Each loan appears exactly once (20,966 unique)
- **Placement status** - Only 'DebtBuyerA' (65.6%) and 'DebtBuyerB' (34.4%) appear
- **All records have at least one conflict** - TOTAL_CONFLICT_COUNT between 1-3
- **Conflict distribution validates**:
  - Future Scheduled Payments: ~99.8% (dominant indicator)
  - Settlement Conflicts: ~18.6%
  - Post-Chargeoff Payments: ~6.3%
  - Active AutoPay: 0% (no current conflicts)

### QC Validation Steps
1. Verify no duplicate loan records
2. Confirm placement status distribution
3. Validate data quality issue type counts
4. Review payment amount ranges for reasonableness
5. Check settlement status distribution

## Execution Results

### Latest Execution (October 16, 2025) - CORRECTED 3-INDICATOR ANALYSIS

**Key Findings:**
- **Total Loans Identified:** 4,411 charged-off loans with placement conflicts
- **DebtBuyerA Placements:** 3,234 loans (73.3%)
- **DebtBuyerB Placements:** 1,177 loans (26.7%)

**Conflict Type Breakdown:**
- **Settlement Conflicts:** 3,901 loans (88.4%) - **PRIMARY ISSUE**
- **Post-Chargeoff Payments:** 1,328 loans (30.1%)
- **Active/Pending Autopay:** 59 loans (1.3%)
- **Future Payment Transactions:** 0 loans (0.0%)

**Conflict Count Distribution:**
- **Single Conflict:** 3,553 loans (80.6%)
- **Two Conflicts:** 839 loans (19.0%)
- **Three Conflicts:** 19 loans (0.4%)

**Post-Chargeoff Payment Statistics (for 1,328 loans):**
- Total Payments Collected: $3,746,599
- Average Per Loan: $2,821.23

**Data Quality Impact:**
This corrected analysis identified 4,411 loans marked as placed with debt buyers (DebtBuyerA/DebtBuyerB) that have ACTUAL evidence of continued FinanceCo servicing. The primary issue is settlement conflicts (88.4%), followed by post-chargeoff payments (30.1%), and active/pending autopay transactions (1.3%).

**Correction Notes:**
Previous analysis incorrectly used VW_LOAN_SCHED_FCST_PAYMENTS (amortization schedule projections) showing 99.8% false positives. Corrected analysis uses:
- LOAN_AUTOPAY_ENTITY for actual pending/processing autopay (found 59 vs previous 0)
- VW_SYSTEM_PAYMENT_TRANSACTION for future-dated payment transactions (found 0, confirming no actual scheduled payments)

### Original Execution (October 6, 2025)

**Key Findings:**
- **Total Loans Identified:** 500 charged-off loans with placement conflicts
- **DebtBuyerA Placements:** 467 loans (93.4%)
- **DebtBuyerB Placements:** 32 loans (6.4%)
- **Settlement Status Breakdown:**
  - Active Settlements: 268 loans (53.6%)
  - Completed Settlements: 231 loans (46.2%)

**Archived Results:** `archive_versions/placement_data_quality_analysis_2025-10-06_original_500_loans.csv`

## Next Steps

### For Business/Operations Team
1. Review output file for 4,411 loans requiring placement status correction
2. **Priority Focus - Settlement Conflicts:** 3,901 loans (88.4%) with active/incomplete settlements - PRIMARY ISSUE
3. **Payment Collections:** 1,328 loans collecting post-chargeoff payments ($3.7M total)
4. **Active Autopay:** 59 loans with pending/processing autopay transactions
5. **Multi-Conflict Loans:** 858 loans with 2+ conflicts need immediate attention
6. Coordinate with debt buyers (DebtBuyerA/DebtBuyerB) on discrepancies
7. Update loan_management_system placement status for corrected loans

### For Data Engineering
1. Investigate root cause of settlement conflicts being primary issue
2. Review placement workflow to prevent settlements on placed loans
3. Consider automated monitoring for settlement/placement conflicts
4. Add settlement status validation to placement workflows

## Technical Notes

### Corrected 3-Indicator Implementation
The corrected implementation includes three accurate data quality indicators:
1. **Settlement Conflicts** - VW_LOAN_DEBT_SETTLEMENT (join on LEAD_GUID)
2. **Post-Chargeoff Payments** - VW_SYSTEM_PAYMENT_TRANSACTION (filtered for settled, non-reversed)
3. **Active/Pending Autopay** - LOAN_AUTOPAY_ENTITY (actual pending/processing autopay transactions)
4. **Future Payment Transactions** - VW_SYSTEM_PAYMENT_TRANSACTION with APPLY_DATE > CURRENT_DATE() (actual scheduled payments)

**Evolution from Original Approach:**
- Initial implementation (Oct 6): Only settlement conflicts (501 loans)
- Comprehensive but incorrect (Oct 15): Added 4 indicators using VW_LOAN_SCHED_FCST_PAYMENTS (20,966 loans with 99.8% false positives)
- **CORRECTED (Oct 16)**: Replaced amortization schedule projections with actual payment transactions and autopay records (4,411 loans - accurate)

**Key Correction:**
VW_LOAN_SCHED_FCST_PAYMENTS contains amortization schedule projections that persist after chargeoff, not actual payment obligations. This caused 99.8% false positive rate. Corrected approach uses:
- LOAN_AUTOPAY_ENTITY for actual pending/processing autopay (found 59 vs previous 0)
- VW_SYSTEM_PAYMENT_TRANSACTION for future-dated payment transactions (found 0, correctly confirming no actual scheduled payments)

### View Usage and Join Strategy
- `BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN` - Core loan data with numeric LOAN_ID
- `BUSINESS_INTELLIGENCE.BRIDGE.VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT` - Placement status
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT` - Settlement data (TEXT LOAN_ID, join on LEAD_GUID)
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_SYSTEM_PAYMENT_TRANSACTION` - Payment history AND future payment transactions (numeric LOAN_ID)
- `RAW_DATA_STORE.LOANPRO.LOAN_AUTOPAY_ENTITY` - Active/pending autopay transactions (numeric LOAN_ID, filtered by schema)

### Performance Considerations
- Query uses `BUSINESS_INTELLIGENCE_LARGE` warehouse
- Estimated runtime: 30-60 seconds
- Uses CTEs to pre-aggregate each indicator before final join
- Direct CSV export (no intermediate table required)

## Related Tickets
- **DI-1254**: BK Sale Evaluation for DebtBuyerB (related placement exclusions)
- **DI-1312**: VW_LOAN_FRAUD creation (modern view architecture reference)
