# View Comparison Summary Report
## BUSINESS_INTELLIGENCE.DATA_STORE.VW_PLAID_TRANSACTION_DETAIL vs DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION_DETAIL

### Executive Summary

The comparison between the DATA_STORE and FRESHSNOW Plaid transaction detail views reveals significant structural differences but maintains compatibility for core fields. The FRESHSNOW view is experiencing performance issues that prevented full data validation.

### Key Findings

#### 1. Schema Analysis

**Column Count:**
- DATA_STORE view: 29 columns
- FRESHSNOW view: 46 columns

**Column Alignment:**
- **Matching columns**: 27 (93% of DATA_STORE columns are present in FRESHSNOW)
- **Missing in FRESHSNOW**: 2 columns
  - `ACCOUNT_AMOUNT`
  - `ACCOUNT_OWNER`
- **New in FRESHSNOW**: 19 columns (mostly enhanced account and transaction details)

#### 2. Missing Columns Detail

| Column Name | Data Type | Impact |
|------------|-----------|---------|
| ACCOUNT_AMOUNT | TEXT | May contain account balance information in legacy format |
| ACCOUNT_OWNER | TEXT | Contains account ownership details |

#### 3. New Columns in FRESHSNOW

The FRESHSNOW view includes 19 additional columns that provide enhanced detail:

**Account Balance Fields** (5 new fields):
- `ACCOUNT_BALANCE_AVAILABLE` (FLOAT)
- `ACCOUNT_BALANCE_CURRENT` (FLOAT)
- `ACCOUNT_BALANCE_ISO_CURRENCY_CODE` (TEXT)
- `ACCOUNT_BALANCE_LIMIT` (FLOAT)
- `ACCOUNT_BALANCE_UNOFFICIAL_CURRENCY_CODE` (TEXT)

**Account Details** (6 new fields):
- `ACCOUNT_MASK` (TEXT)
- `ACCOUNT_NAME` (TEXT)
- `ACCOUNT_OFFICIAL_NAME` (TEXT)
- `ACCOUNT_SUBTYPE` (TEXT)
- `ACCOUNT_TYPE` (TEXT)
- `ACCOUNT_VERIFICATION_STATUS` (TEXT)

**Transaction Enhancement Fields** (6 new fields):
- `TRANSACTION_AMOUNT` (FLOAT) - Critical field for transaction values
- `TRANSACTION_CREDIT_CATEGORY_DETAILED` (TEXT)
- `TRANSACTION_CREDIT_CATEGORY_PRIMARY` (TEXT)
- `TRANSACTION_DATE_TRANSACTED` (TEXT)
- `TRANSACTION_DEBIT_CREDIT_INDICATOR` (TEXT)
- `TRANSACTION_INDEX` (NUMBER)

**Tracking Fields** (2 new fields):
- `OSCILAR_RECORD_ID` (TEXT)
- `ASSET_REPORT_ID` (TEXT)

#### 4. Data Type Consistency

All 27 matching columns maintain the same data types between both views, ensuring type compatibility.

#### 5. Performance Issues

⚠️ **Critical Issue**: The FRESHSNOW view (`VW_OSCILAR_PLAID_TRANSACTION_DETAIL`) is experiencing severe performance problems:
- Queries timeout after 2-3 minutes
- Unable to retrieve sample data for value comparison
- The view sources from `DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS` with complex JSON parsing

### View Definition Analysis

The FRESHSNOW view:
1. Sources data from Oscilar verifications with Plaid Assets responses
2. Uses complex JSON parsing with multiple LATERAL FLATTEN operations
3. Filters for records where `DATA:data:integrations[3]:name = 'Plaid_Assets'`
4. Includes comprehensive transaction-level detail extraction

### Recommendations

1. **Performance Optimization**: The FRESHSNOW view requires performance tuning:
   - Consider materializing intermediate results
   - Add appropriate filters or partitioning
   - Review the base view `VW_OSCILAR_VERIFICATIONS` for optimization opportunities

2. **Missing Fields**: Evaluate if `ACCOUNT_AMOUNT` and `ACCOUNT_OWNER` are critical:
   - These may be replaced by the new balance fields and other account details
   - Confirm with business requirements

3. **Data Validation**: Once performance is resolved, conduct thorough data validation:
   - Compare transaction counts by lead/member
   - Validate amount calculations
   - Ensure date alignments

4. **Migration Path**: The enhanced fields in FRESHSNOW provide richer data:
   - Plan for downstream consumers to utilize new fields
   - Document mapping between old and new field names

### QC Query Files Created

1. `schema_comparison_query.sql` - Full schema comparison
2. `data_alignment_qc.sql` - Data alignment checks (blocked by performance)
3. `schema_summary.sql` - Summary of schema differences
4. `column_differences.sql` - Detailed column differences

### Next Steps

1. Address performance issues with the FRESHSNOW view
2. Once resolved, execute data alignment QC queries
3. Validate data completeness and accuracy
4. Document any business logic differences between views