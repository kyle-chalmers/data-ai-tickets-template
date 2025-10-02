# DI-1310: South Dakota Money Lender License Q3 2025 Report

## Ticket Information
- **Jira Link:** https://happymoneyinc.atlassian.net/browse/DI-1310
- **Type:** Reporting
- **Status:** Backlog
- **Assignee:** Kyle Chalmers
- **Prior Quarter Reference:** DI-501

## Business Context

Quarterly regulatory report for South Dakota Money Lender License covering the period July 1, 2025 through September 30, 2025. This is a recurring compliance requirement with six specific data points for submission.

## Investigation Scope

### Required Data Points

1. **New SD Accounts During Quarter**
   - Count of new South Dakota accounts from July 1 - September 30, 2025
   - Must be numeric value

2. **Total Outstanding SD Accounts (Range)**
   - As of September 30, 2025
   - Select range: 0-50, 50-100, or 100+

3. **Total Outstanding SD Accounts (Count)**
   - As of September 30, 2025
   - Must be numeric value

4. **APR Range for Outstanding Accounts**
   - As of September 30, 2025
   - Select range: 0%-16%, 16%-36%, or Over 36%

5. **Minimum Annual Percentage Rate**
   - Previous quarter reported: 6.99%
   - Verify if value remains the same

6. **Maximum Annual Percentage Rate**
   - Previous quarter reported: 24.99%
   - Verify if value remains the same

## Final Report Results

### Query 1: New SD Accounts During Q3 2025
**Result:** 18 accounts

### Query 2: Outstanding Accounts Range Category
**Result:** 100+ (185 outstanding accounts)

### Query 3: Exact Outstanding Account Count
**Result:** 185 accounts

### Query 4: APR Range Distribution for Outstanding Accounts
- **0%-16%:** 79 loans (42.70%)
- **16%-36%:** 106 loans (57.30%)
- **Over 36%:** 0 loans (0%)

### Query 5: Minimum Annual Percentage Rate
**Result:** 6.99%
**Status:** SAME as prior quarter (6.99%)

### Query 6: Maximum Annual Percentage Rate
**Result:** 27.269%
**Status:** CHANGED from prior quarter (was 24.99%)

## Assumptions Made

1. **Data Source Selection**: Using MVW_LOAN_TAPE_DAILY_HISTORY for queries 2-6 requiring historical ASOFDATE
   - **Reasoning**: MVW_LOAN_TAPE only contains current snapshot; historical dates require DAILY_HISTORY table
   - **Context**: Query 1 uses MVW_LOAN_TAPE (no ASOFDATE filter), queries 2-6 use DAILY_HISTORY for Sept 30 snapshot
   - **Impact**: All "as of September 30" metrics use MVW_LOAN_TAPE_DAILY_HISTORY with ASOFDATE = '2025-10-01'

2. **Outstanding Loans Definition**: Outstanding = all loans where STATUS <> 'Paid in Full'
   - **Reasoning**: Regulatory reporting typically considers all active and delinquent loans as "outstanding"
   - **Context**: Includes Current (93), Charge off (88), Seriously Delinquent (4) = 185 total
   - **Impact**: Paid in Full loans (475) are excluded from outstanding counts

3. **New Accounts Definition**: New accounts = loans with ORIGINATIONDATE between July 1 - September 30, 2025
   - **Reasoning**: Quarterly regulatory report measures originations within the specific quarter
   - **Context**: Total universe is 660 SD loans; 18 originated in Q3 2025
   - **Impact**: Counts new originations only, not transfers or status changes

4. **APR Range Categorization Logic**: Loans with APR = 16.0% categorized as "0%-16%"
   - **Reasoning**: Used <= 16.0 for lower bucket to ensure no ambiguity at boundaries
   - **Context**: No loans found at exactly 16% or 36% in current data
   - **Impact**: Consistent categorization at bucket boundaries

5. **State Identification**: APPLICANTRESIDENCESTATE = 'SD' identifies South Dakota loans
   - **Reasoning**: Standard field for borrower residence state in MVW_LOAN_TAPE
   - **Context**: 660 SD loans total, 20 loans have NULL state (excluded)
   - **Impact**: Only loans with explicit 'SD' state are included

## Deliverables

### Final Deliverables (`final_deliverables/`)
- `sd_money_lender_q3_2025_report.sql` - All 6 queries with parameterized dates and comprehensive documentation
- `query_results.csv` - Complete execution results for all 6 queries

### Quality Control (`qc_queries/`)
- `1_data_validation.sql` - 8 QC checks validating data quality and business logic
- `qc_results.csv` - Complete QC validation results

## Quality Control Summary

### QC Results (All Passed)

**QC 1.1 - ASOFDATE Validation:** ✓ PASSED
- Single snapshot date: 2025-10-01
- Represents September 30, 2025 data

**QC 1.2 - Status Distribution:** ✓ PASSED
- Paid in Full: 475 (71.97%)
- Current: 93 (14.09%)
- Charge off: 88 (13.33%)
- Seriously Delinquent: 4 (0.60%)
- Total: 660 SD loans

**QC 1.3 - Duplicate Check:** ✓ PASSED
- No duplicate loans found in snapshot

**QC 1.4 - Q3 Origination Dates:** ✓ PASSED
- Earliest: 2025-07-03
- Latest: 2025-09-22
- All within Q3 2025 range

**QC 1.5 - APR Data Quality:** ✓ PASSED
- No NULL APR values for outstanding loans
- No zero or negative APR values
- Min: 6.99%, Max: 27.269%, Avg: 16.842%

**QC 1.6 - Historical Trend:** ✓ PASSED
- Q3 2025: 185 outstanding, 18 new originations
- Consistent with regulatory reporting expectations

**QC 1.7 - APR Range Edge Cases:** ✓ PASSED
- No loans at exactly 16% or 36% boundaries
- No loans over 36% APR

**QC 1.8 - State Data Validation:** ✓ PASSED
- 660 SD loans confirmed
- 20 loans with NULL state (excluded from analysis)

## Key Findings

1. **Maximum APR Increase**: Maximum APR increased from 24.99% (prior quarter) to 27.269%
   - Indicates at least one loan with higher APR originated or became outstanding this quarter
   - Requires note in regulatory submission

2. **Outstanding Portfolio Growth**: 185 outstanding SD loans as of Sept 30
   - Falls in "100+" range category
   - Represents 28% of total SD portfolio (185/660)

3. **APR Distribution**: Majority of outstanding loans (57.3%) have APRs in 16%-36% range
   - Lower risk segment (0%-16%): 42.7%
   - No high-risk loans (>36%)

4. **New Originations**: 18 new SD loans in Q3 2025
   - Steady origination activity
   - All loans fall within compliant APR ranges

## References

- **Prior Quarter:** DI-501 (Q4 2024 report)
- **Historical Reference:** DI-343 (Q3 2024 report)
- **Data Source:** DATA_STORE.MVW_LOAN_TAPE
- **Regulatory Requirements:** South Dakota Money Lender License quarterly reporting
