# DI-1253 Technical Documentation

## Query Architecture

### Population Query Structure
The population query uses a multi-CTE approach for optimal performance:

1. **base_query**: Initial filtering for FTFCU placement status
2. **base_ftfcu_allocated_loans**: Join with daily history for charge-off data
3. **bankruptcy_data_filtered**: Pre-filter bankruptcy data to target population
4. **delinquency_dates**: Calculate first and most recent delinquency dates
5. **payment_history**: Aggregate payment transactions with bankruptcy POC logic
6. **bankruptcy_principal_remaining**: Calculate principal at bankruptcy filing
7. **fraud_data_filtered**: Pre-filter fraud/SCRA/deceased indicators

### Transaction Query Structure
Optimized to reference the population table:

1. **target_loans**: Extract loan identifiers from population table
2. **cls_payment_info**: CLS adjustment dates
3. **all_payment_transactions**: Union of CLS and LoanPro payments
4. **loan_other_transactions**: Non-payment transactions
5. **cash_transactions**: Formatted payment transactions
6. **adjustments**: Charged-off principal adjustments

## Performance Optimizations

### Pre-Filtering Strategy
- All CTEs filter to target population immediately
- INNER JOINs used where possible to reduce dataset size
- Window functions with QUALIFY for efficient deduplication

### Index Usage
- Leveraging LEAD_GUID and LOAN_ID indexes
- Date-based filtering on indexed columns
- Partition by PAYOFFUID for window functions

## Data Quality Considerations

### Bankruptcy Logic
Complex bankruptcy filtering with three conditions:
- Discharged bankruptcies after origination
- Most recent bankruptcies (excluding dismissed/removed)
- Filing date must be before placement date

### Payment Processing
- IS_SETTLED check for valid payments
- Exclusion of reversed and rejected transactions
- Post-POC payment tracking for bankruptcy cases

### Deduplication Strategy
- QUALIFY ROW_NUMBER() for latest records
- SSN prioritization in final SELECT
- Transaction ID uniqueness per loan

## SQL Patterns Used

### EXCLUDE Clause
```sql
A.* EXCLUDE (payoffuid, PLACEMENT_STATUS, LOANID)
```
Efficient column selection excluding specific fields

### COALESCE Defaults
```sql
COALESCE(DD.DATEOFFIRSTDELINQUENCY, DATEADD(DAY, -90, A.CHARGEOFFDATE))
```
Business-appropriate defaults for missing data

### Conditional Aggregation
```sql
SUM(CASE WHEN conditions THEN value ELSE 0 END)
```
Efficient single-pass aggregation with conditions

## Table Creation
Both queries create persistent tables with COPY GRANTS:
- `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION`
- `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.CHARGE_OFF_FTFCU_ALLOCATED_POPULATION_TRANSACTIONS`

## Validation Approach
Each script includes QC queries:
1. Duplicate detection by key fields
2. Count summaries with distinct counts
3. Date range validation
4. Cross-table reconciliation

## Known Edge Cases
1. **Missing SSN**: Handled by QUALIFY with DESC NULLS LAST
2. **No delinquency history**: Defaults to charge-off minus 90 days
3. **Multiple bankruptcies**: Takes most recent via LAST_UPDATED_DATE_PT
4. **CLS vs LoanPro payments**: Union with source tracking

## Future Considerations
- TODO comment indicates fraud population optimization opportunity
- Consider indexing DEVELOPMENT._TIN.FRAUD_SCRA_DECEASE_LOOKUP
- Potential for materialized view if run frequently
- Archive strategy for CRON_STORE tables