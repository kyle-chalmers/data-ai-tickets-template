# DI-1211: Loans Placed with Bounce or Resurgent - Data Quality Analysis

## Ticket Information
- **Jira Link:** https://happymoneyinc.atlassian.net/browse/DI-1211
- **Type:** Data Pull
- **Status:** In Progress
- **Assignee:** Kyle Chalmers
- **Branch:** `DI-1254_and_DI-1211`

## Business Context

### Problem Statement
Data quality discrepancies have been identified with loans marked as placed with Bounce or Resurgent. These loans show evidence of:
1. Active or completed settlement arrangements
2. Post-chargeoff payments being received
3. AutoPay still enabled
4. Future scheduled payments in the system

These indicators suggest that the placement status in LoanPro settings does not reflect the true status of the account, potentially causing:
- Incorrect routing of payments
- Customer confusion
- Collections conflicts
- Regulatory compliance concerns

### Business Impact
Identifying these discrepancies allows the collections and servicing teams to:
- Correct placement status data in LoanPro
- Prevent future payment routing errors
- Resolve customer service issues proactively
- Ensure accurate debt buyer reporting

## Deliverables

### SQL Files
1. **`1_placement_data_quality_analysis.sql`** - Main analysis query
   - Identifies charged-off loans with Bounce/Resurgent placement status
   - Filters for loans showing post-chargeoff activity
   - Outputs comprehensive data for review and correction

### QC Queries
1. **`qc_queries/1_record_count_validation.sql`** - Record counts and duplicate checks
2. **`qc_queries/2_placement_distribution.sql`** - Placement status breakdown
3. **`qc_queries/3_settlement_status_breakdown.sql`** - Settlement and payment analysis

### Output File
- **`placement_data_quality_analysis.csv`** - Results for business review

## Data Fields

| Field Name | Description | Source |
|------------|-------------|--------|
| LOAN_ID | LoanPro loan identifier | VW_LOAN |
| LEGACY_LOAN_ID | CLS legacy loan identifier | VW_LOAN |
| LEAD_GUID | Universal loan identifier | VW_LOAN |
| PLACEMENT_STATUS | Current placement (Bounce/Resurgent) | VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT |
| CHARGEOFF_DATE | Date loan was charged off | VW_LOAN |
| CHARGEOFF_PRINCIPAL_AMOUNT | Principal balance at chargeoff | VW_LOAN |
| TOTAL_PAYMENTS_POST_CHARGEOFF | Sum of all payments after chargeoff date | VW_LP_PAYMENT_TRANSACTION |
| POST_CHARGEOFF_PAYMENT_COUNT | Number of payments after chargeoff | VW_LP_PAYMENT_TRANSACTION |
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
- Loan status = 'Charge off'
- Placement status = 'Bounce' OR 'Resurgent'
- **AND** at least one of the following:
  - Total post-chargeoff payments > $0
  - Settlement status = 'Active' OR 'Complete'
  - AutoPay enabled = TRUE
  - Future scheduled payments exist

### Data Sources
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN** - Core loan data
- **BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT** - Placement status
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT** - Settlement information
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION** - Payment history
- **BUSINESS_INTELLIGENCE.BRIDGE.VW_PAYMENT_SCHEDULE_ENTITY_CURRENT** - Scheduled payments

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

**Reasoning:** This is the most current AutoPay setting in LoanPro.

**Impact:** Identifies loans where AutoPay is still active despite being placed with a debt buyer.

### 3. Future Scheduled Payment Criteria
**Assumption:** Future scheduled payments are those where:
- `EXPECTED_PAYMENT_DATE > CURRENT_DATE()`
- From VW_PAYMENT_SCHEDULE_ENTITY_CURRENT

**Reasoning:** Active payment schedules indicate the loan is still being serviced internally, conflicting with placement status.

**Impact:** Highlights scheduling system discrepancies that could cause payment routing errors.

### 4. Settlement Status Categorization
**Assumption:** Settlement conflicts exist when:
- `SETTLEMENTSTATUS IN ('Active', 'Complete')` OR
- `CURRENT_STATUS IN ('Active', 'Complete')`

**Reasoning:** Active or completed settlements should prevent placement with debt buyers, as Happy Money is still actively servicing the debt through settlement arrangements.

**Impact:** Identifies the most critical conflicts where settlement arrangements exist alongside placement status.

## Execution Instructions

### Step 1: Run Main Query
```bash
cd /Users/kchalmers/Development/data-intelligence-tickets
snow sql -f tickets/kchalmers/DI-1211/final_deliverables/1_placement_data_quality_analysis.sql --format csv -o header=true -o timing=false > tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv
```

### Step 2: Run QC Queries
```bash
# Record count validation
snow sql -f tickets/kchalmers/DI-1211/final_deliverables/qc_queries/1_record_count_validation.sql

# Placement distribution
snow sql -f tickets/kchalmers/DI-1211/final_deliverables/qc_queries/2_placement_distribution.sql

# Settlement status breakdown
snow sql -f tickets/kchalmers/DI-1211/final_deliverables/qc_queries/3_settlement_status_breakdown.sql
```

### Step 3: Review Results
- Open `placement_data_quality_analysis.csv`
- Review record counts from QC queries
- Document any anomalies or unexpected patterns

## Quality Control

### Expected QC Results
- **No duplicate LOAN_IDs** - Each loan should appear only once
- **Placement status** - Only 'Bounce' and 'Resurgent' should appear
- **All records have at least one indicator** - Post-chargeoff payments OR settlement OR AutoPay OR future payments

### QC Validation Steps
1. Verify no duplicate loan records
2. Confirm placement status distribution
3. Validate data quality issue type counts
4. Review payment amount ranges for reasonableness
5. Check settlement status distribution

## Next Steps

### For Business/Operations Team
1. Review output file for loans requiring placement status correction
2. Prioritize by payment amount and settlement status
3. Coordinate with debt buyers (Bounce/Resurgent) on discrepancies
4. Update LoanPro placement status for corrected loans

### For Data Engineering
1. Investigate root cause of placement status mismatches
2. Document any systematic data quality patterns
3. Consider automated monitoring for future prevention

## Technical Notes

### Modern View Usage
This query uses modern ANALYTICS layer views instead of legacy lookup tables, following the evolving data architecture standards from DI-1312.

### Performance Considerations
- Query uses `BUSINESS_INTELLIGENCE_LARGE` warehouse
- Estimated runtime: 2-5 minutes
- Output temp table: `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.DI_1211_PLACEMENT_DATA_QUALITY`

## Related Tickets
- **DI-1254**: BK Sale Evaluation for Resurgent (related placement exclusions)
- **DI-1312**: VW_LOAN_FRAUD creation (modern view architecture reference)
