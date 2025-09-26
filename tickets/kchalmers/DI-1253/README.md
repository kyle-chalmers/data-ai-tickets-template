# DI-1253: Charged Off FTFCU Allocated Population & Transactions

## Overview
Generate population and transaction reports for loans allocated to First Tech Credit Union (FTFCU) that have been charged off.

## Business Context
Extract charged-off loan data for FTFCU allocation, including comprehensive borrower information, loan details, and complete transaction history up to the placement date.

## Deliverables

### 1. Population Report (`deliverables/charged_off_ftfcu_allocated_population.csv`)
- **Record Count**: 19 loans
- **Key Fields**: Borrower PII, loan balances, charge-off details, bankruptcy information, settlement status
- **Filter**: `PLACEMENT_STATUS = 'Placed - First Tech Credit Union'`

### 2. Transaction Report (`deliverables/charged_off_ftfcu_allocated_population_transactions.csv`)
- **Transaction Count**: Varies per loan
- **Coverage**: All transactions prior to placement date
- **Sources**: CLS, LoanPro, and adjustment transactions

## Data Sources
- `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE` - Core loan tape data
- `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY` - Historical snapshots
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY` - Bankruptcy information
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION` - Payment history
- `DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP` - Fraud/deceased indicators

## Key Business Logic

### Population Filtering
- Loans with `PLACEMENT_STATUS = 'Placed - First Tech Credit Union'`
- Must have charge-off date populated
- Placement start date used as cutoff for transaction history

### Unpaid Balance Calculation
```sql
PRINCIPALBALANCEATCHARGEOFF + INTERESTBALANCEATCHARGEOFF
- RECOVERIESPAIDTODATE
- CHARGED_OFF_PRINCIPAL_ADJUSTMENT
- TOTALPRINCIPALWAIVED
```

### Delinquency Dates
- First delinquency: Earliest date with DPD >= 30
- Most recent: Latest date with DPD = 30
- Default to charge-off date minus 90 days if not found

## Assumptions Made

1. **Bankruptcy Filtering**: Include discharged bankruptcies and most recent bankruptcies filed after origination but before placement
2. **Payment Validation**: Only count settled, non-reversed, non-rejected payments
3. **Fraud Indicators**: Combine SCRAFLAG from loan tape with fraud lookup table
4. **Deduplication**: Use ROW_NUMBER() to handle potential duplicates, prioritizing records with SSN

## Quality Control
- No duplicate loans in population (verified by LOANID)
- Transaction counts reconcile with population
- All placement dates occur after charge-off dates
- Validated bankruptcy date logic (filing < placement)

## Technical Notes
- Optimized queries using CTEs to pre-filter data
- Created persistent tables in `BUSINESS_INTELLIGENCE_DEV.CRON_STORE`
- Both scripts include validation queries at the end
- Used QUALIFY clauses for efficient deduplication

## Execution Order
1. Run population script first (`1_charged_off_ftfcu_population_script.sql`)
2. Run transaction script second (`2_charged_off_ftfcu_population_transactions_script.sql`)