# DI-1310: South Dakota Money Lender License Q3 2025 Report

## Ticket Context

This is a **quarterly regulatory compliance report** for South Dakota Money Lender License covering Q3 2025 (July 1 - September 30, 2025). This is a **recurring ticket** that happens every quarter.

## Pattern: Quarterly Regulatory Report

This ticket follows a pattern:
- **Q3 2024**: DI-343
- **Q4 2024**: DI-501
- **Q3 2025**: DI-1310 (this ticket)

Future quarters will follow the same structure.

## Key Technical Details

### Data Sources

**IMPORTANT**: This ticket uses TWO different tables depending on the query:

1. **Query 1**: `DATA_STORE.MVW_LOAN_TAPE`
   - Reason: No ASOFDATE filter needed, only ORIGINATIONDATE range
   - Counts new loans originated during Q3 2025

2. **Queries 2-6**: `DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY`
   - Reason: Need historical snapshot as of September 30, 2025 (ASOFDATE = '2025-10-01')
   - MVW_LOAN_TAPE only has current snapshot, not historical dates
   - All "as of" queries must use DAILY_HISTORY for past dates

### Critical Filters

- **State**: `APPLICANTRESIDENCESTATE = 'SD'`
- **As-Of Date**: `ASOFDATE = '2025-10-01'` (represents Sept 30, 2025)
- **Outstanding Status**: `STATUS <> 'Paid in Full'`
- **Date Range**: `ORIGINATIONDATE BETWEEN '2025-07-01' AND '2025-09-30'`

### Required Outputs

6 specific data points for regulatory submission:
1. New SD accounts during quarter (18)
2. Outstanding accounts range (100+)
3. Exact outstanding count (185)
4. APR range distribution (79 @ 0%-16%, 106 @ 16%-36%)
5. Minimum APR (6.99%)
6. Maximum APR (27.269%)

## Results Summary

All results validated and documented in `query_results.csv` and README.md.

**Key Finding**: Maximum APR increased from 24.99% (prior quarter) to 27.269% - this change must be noted in regulatory submission.

## Files

- `sd_money_lender_q3_2025_report.sql` - All 6 queries in single script
- `query_results.csv` - Clean results (no Snowflake status messages)
- `qc_queries/1_data_validation.sql` - 8 QC validation checks
- `qc_queries/qc_results.csv` - QC results (all passed)

## For Future Quarters

When working on Q4 2025 or later quarters:
1. Copy this query structure
2. Update date variables (REPORTING_START_DATE, REPORTING_END_DATE, AS_OF_DATE)
3. Use same data sources (MVW_LOAN_TAPE for new accounts, DAILY_HISTORY for as-of queries)
4. Compare prior quarter values (min/max APR)
5. Follow same QC validation pattern

## Common Pitfalls

❌ **Don't use MVW_LOAN_TAPE for historical ASOFDATE** - it only has current snapshot
✓ **Use MVW_LOAN_TAPE_DAILY_HISTORY for any "as of" historical date queries**

❌ **Don't include Snowflake status messages in CSV files** - clean them up
✓ **CSV files should only have column headers and data rows**

❌ **Don't forget to compare to prior quarter** - regulatory expects variance notes
✓ **Document any changes in min/max APR or other key metrics**
