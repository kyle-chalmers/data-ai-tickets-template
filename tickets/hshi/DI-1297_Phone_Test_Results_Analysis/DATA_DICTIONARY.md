# Data Dictionary - DI-1297 Phone Test Results Analysis

## Overview
This document defines all data points, metrics, and business logic used in the Phone Test A/B analysis comparing low-intensity vs high-intensity calling strategies across four DPD buckets.

---

## Source Tables

### CRON_STORE.RPT_OUTBOUND_LISTS_HIST
**Description**: Historical outbound call list data showing which accounts were targeted for calls on each day.

| Column Name | Data Type | Description |
|------------|-----------|-------------|
| LOAD_DATE | Date | Date when the call list was generated |
| SET_NAME | String | Call list category (filtered to 'Call List') |
| LIST_NAME | String | DPD bucket identifier (DPD3-14, DPD15-29, DPD30-59, DPD60-89) |
| PAYOFFUID | String | Unique account identifier |
| SUPPRESSION_FLAG | Boolean | Whether account was suppressed from calling (filtered to FALSE) |

### DATA_STORE.MVW_LOAN_TAPE_MONTHLY
**Description**: Monthly snapshot of loan-level data including delinquency status.

| Column Name | Data Type | Description |
|------------|-----------|-------------|
| ASOFDATE | Date | Snapshot date (end of month) |
| PAYOFFUID | String | Unique account identifier |
| DAYSPASTDUE | Integer | Number of days the account is past due (0 = current) |

---

## Test Design Fields

### DPD_BUCKET
**Data Type**: String
**Possible Values**:
- `DPD3-14`: Accounts 3-14 days past due
- `DPD15-29`: Accounts 15-29 days past due
- `DPD30-59`: Accounts 30-59 days past due
- `DPD60-89`: Accounts 60-89 days past due

**Business Logic**: Derived from `LIST_NAME` column in RPT_OUTBOUND_LISTS_HIST

### TEST_GROUP
**Data Type**: String
**Possible Values**:
- `Test (Low Intensity)`: 1 call per week maximum
- `Control (High Intensity)`: Daily calls allowed

**Business Logic**: Determined by character position in PAYOFFUID (deterministic assignment)

#### For DPD3-14 and DPD15-29:
- Position 17 of PAYOFFUID
- Characters `0-9, a, b, c` → Test (Low Intensity) - ~81%
- Characters `d, e, f` → Control (High Intensity) - ~19%

#### For DPD30-59 and DPD60-89:
- Position 12 of PAYOFFUID
- Characters `0, 1, 2` → Test (Low Intensity) - ~19%
- Characters `3-9, a-f` → Control (High Intensity) - ~81%

---

## Query 1: Daily Group Size Trends

**File**: `01_daily_group_size_trends.sql`
**Purpose**: Track daily account counts in each test/control group by DPD bucket

### Output Columns

| Column Name | Data Type | Description | Business Logic |
|------------|-----------|-------------|----------------|
| LOAD_DATE | Date | Date of call list generation | Direct from RPT_OUTBOUND_LISTS_HIST |
| DPD_BUCKET | String | DPD bucket identifier | LIST_NAME field |
| TEST_GROUP | String | Test or Control group | Based on PAYOFFUID character position |
| ACCOUNT_COUNT | Integer | Number of unique accounts | COUNT(DISTINCT PAYOFFUID) per day/bucket/group |

**Filters Applied**:
- SET_NAME = 'Call List'
- SUPPRESSION_FLAG = FALSE
- LOAD_DATE >= '2024-04-01'
- TEST_GROUP IS NOT NULL

---

## Query 2: Cure Rate - Cohort Analysis

**File**: `02_cure_rate_cohort_analysis.sql`
**Purpose**: Track cure journey for accounts from their first appearance in each DPD bucket

### Key Concepts

**Cohort Definition**: Accounts that first appear in a specific DPD bucket during a specific month

**Cure Definition**: Account reaches DAYSPASTDUE = 0 in loan tape monthly snapshot

**First Appearance**: Earliest LOAD_DATE an account appears in a specific DPD bucket

### Output Columns

| Column Name | Data Type | Description | Business Logic |
|------------|-----------|-------------|----------------|
| ENTRY_COHORT_MONTH | Date | Month when accounts first appeared | DATE_TRUNC('MONTH', MIN(LOAD_DATE)) |
| DPD_BUCKET | String | DPD bucket identifier | LIST_NAME field |
| TEST_GROUP | String | Test or Control group | Based on PAYOFFUID character position |
| COHORT_SIZE | Integer | Total accounts in cohort | COUNT(DISTINCT PAYOFFUID) |
| CURED_COUNT | Integer | Number that eventually cured | COUNT(DISTINCT PAYOFFUID WHERE cure_date IS NOT NULL) |
| CURED_1_MONTH | Integer | Number that cured within 1 month | COUNT(DISTINCT PAYOFFUID WHERE months_to_cure = 1) |
| CURED_2_MONTHS | Integer | Number that cured in exactly 2 months | COUNT(DISTINCT PAYOFFUID WHERE months_to_cure = 2) |
| CURED_3_MONTHS | Integer | Number that cured in exactly 3 months | COUNT(DISTINCT PAYOFFUID WHERE months_to_cure = 3) |
| CURED_4PLUS_MONTHS | Integer | Number that cured after 4+ months | COUNT(DISTINCT PAYOFFUID WHERE months_to_cure >= 4) |
| OVERALL_CURE_RATE_PCT | Decimal | % that eventually cured | (CURED_COUNT / COHORT_SIZE) * 100 |
| CURE_RATE_1_MONTH_PCT | Decimal | % that cured within 1 month | (CURED_1_MONTH / COHORT_SIZE) * 100 |
| CURE_RATE_2_MONTHS_PCT | Decimal | % that cured within 2 months | (CURED_1_MONTH + CURED_2_MONTHS) / COHORT_SIZE * 100 |
| CURE_RATE_3_MONTHS_PCT | Decimal | % that cured within 3 months | (SUM of 1-3 months) / COHORT_SIZE * 100 |

### Calculated Fields

**months_to_cure**:
```sql
DATEDIFF(MONTH, entry_cohort_month, cure_date)
```
Number of months between first entry and cure date

**cure_date**:
```sql
MIN(CASE WHEN DAYSPASTDUE = 0 THEN ASOFDATE END)
```
First date when account reached DPD = 0 after entry

---

## Query 3: Cure Rate - Rolling Monthly

**File**: `03_cure_rate_rolling_monthly.sql`
**Purpose**: Track month-over-month cure performance

### Key Concepts

**Rolling Monthly Cure**: Account that appeared in call list in month M cures in month M+1 (DAYSPASTDUE = 0)

**Time Window**: Only looks at immediate next month, not eventual cure

### Output Columns

| Column Name | Data Type | Description | Business Logic |
|------------|-----------|-------------|----------------|
| CALL_LIST_MONTH | Date | Month when accounts appeared in call list | DATE_TRUNC('MONTH', LOAD_DATE) |
| DPD_BUCKET | String | DPD bucket identifier | LIST_NAME field |
| TEST_GROUP | String | Test or Control group | Based on PAYOFFUID character position |
| TOTAL_ACCOUNTS | Integer | Total unique accounts in that month | COUNT(DISTINCT PAYOFFUID) |
| CURED_COUNT | Integer | Number that cured in next month | COUNT(DISTINCT PAYOFFUID WHERE next_month_dpd = 0) |
| NOT_CURED_COUNT | Integer | Number that did not cure in next month | COUNT(DISTINCT PAYOFFUID WHERE next_month_dpd > 0) |
| NO_DATA_COUNT | Integer | Number with no data in next month (loan closed/paid off) | COUNT(DISTINCT PAYOFFUID WHERE next_month_dpd IS NULL) |
| CURE_RATE_PCT | Decimal | % that cured in next month | (CURED_COUNT / (TOTAL_ACCOUNTS - NO_DATA_COUNT)) * 100 |

### Calculated Fields

**cured_flag**:
```sql
CASE WHEN next_month_dpd = 0 THEN 1 ELSE 0 END
```

**next_month_dpd**: DAYSPASTDUE from MVW_LOAN_TAPE_MONTHLY for snapshot_month = call_list_month + 1 month

---

## Query 4: Roll Rate Analysis

**File**: `04_roll_rate_analysis.sql`
**Purpose**: Track forward progression through delinquency stages

### Key Concepts

**Roll Forward**: Account moves from current DPD bucket to the next higher bucket in consecutive months

**Valid Transitions**:
1. DPD3-14 → DPD15-29
2. DPD15-29 → DPD30-59
3. DPD30-59 → DPD60-89

**Note**: DPD60-89 has no forward bucket, so excluded from analysis

**Total Accounts**: All accounts in the current DPD bucket in month M, regardless of what happened in month M+1

### Output Columns

| Column Name | Data Type | Description | Business Logic |
|------------|-----------|-------------|----------------|
| CURRENT_MONTH | Date | Month of the current DPD bucket | DATE_TRUNC('MONTH', LOAD_DATE) |
| CURRENT_DPD_BUCKET | String | Starting DPD bucket | LIST_NAME field (DPD3-14, DPD15-29, DPD30-59 only) |
| TEST_GROUP | String | Test or Control group | Based on PAYOFFUID character position |
| TOTAL_ACCOUNTS | Integer | All accounts in current bucket that month | COUNT(DISTINCT PAYOFFUID) in current month |
| ROLLED_FORWARD_COUNT | Integer | Number that rolled to next higher bucket | COUNT(DISTINCT PAYOFFUID WHERE roll_status = 'Rolled Forward') |
| DID_NOT_ROLL_COUNT | Integer | Number that stayed, improved, or moved elsewhere | COUNT(DISTINCT PAYOFFUID WHERE roll_status = 'Did Not Roll Forward') |
| NO_DATA_COUNT | Integer | Number with no data in next month (loan closed/paid off) | COUNT(DISTINCT PAYOFFUID WHERE next_month_dpd_bucket IS NULL) |
| ROLL_RATE_PCT | Decimal | % that rolled forward (excluding no data) | (ROLLED_FORWARD_COUNT / (TOTAL_ACCOUNTS - NO_DATA_COUNT)) * 100 |
| TRANSITION_TYPE | String | Reference label for the roll transition | Based on CURRENT_DPD_BUCKET (e.g., "DPD3-14 → DPD15-29") |

### Calculated Fields

**roll_status**:
```sql
CASE
    WHEN current_dpd_bucket = 'DPD3-14' AND next_month_dpd_bucket = 'DPD15-29' THEN 'Rolled Forward'
    WHEN current_dpd_bucket = 'DPD15-29' AND next_month_dpd_bucket = 'DPD30-59' THEN 'Rolled Forward'
    WHEN current_dpd_bucket = 'DPD30-59' AND next_month_dpd_bucket = 'DPD60-89' THEN 'Rolled Forward'
    WHEN next_month_dpd_bucket IS NULL THEN 'No Data Next Month'
    ELSE 'Did Not Roll Forward'
END
```

---

## Analysis Period

**Start Date**: April 1, 2024 (`'2024-04-01'`)
**End Date**: Present (queries pull all data through most recent available date)

---

## Data Quality Considerations

### Exclusions
- Accounts with SUPPRESSION_FLAG = TRUE are excluded
- Accounts without valid test group assignment (based on PAYOFFUID logic) are excluded
- Non-"Call List" SET_NAME records are excluded

### NULL Handling
- `NO_DATA_COUNT` tracks accounts missing from subsequent monthly snapshots (typically loans that closed or paid off completely)
- Cure rate and roll rate percentages exclude accounts with no follow-up data from the denominator
- `NULLIF` used to prevent division by zero errors

### Account Counting
- All account metrics use `COUNT(DISTINCT PAYOFFUID)` to ensure unique counts
- Same account can appear in multiple cohorts if it enters different DPD buckets at different times

---

## Key Metrics Summary

### Primary Success Metrics
1. **Cure Rate**: Higher cure rates indicate better performance
2. **Roll Rate**: Lower roll rates indicate better performance (fewer accounts getting worse)

### Test Hypothesis
- **Test Group (Low Intensity)**: Fewer calls may reduce customer stress and improve outcomes
- **Control Group (High Intensity)**: More frequent calls may drive faster action

### Expected Insights
- Compare Test vs Control cure rates by DPD bucket
- Compare Test vs Control roll rates by DPD bucket
- Understand time-to-cure patterns for different calling strategies
- Identify optimal calling frequency for different delinquency stages

---

## File Locations

- **SQL Queries**: `/Users/hshi/WOW/data-intelligence-tickets/tickets/hshi/DI-1297_Phone_Test_Results_Analysis/sql/`
- **Results (CSV/Excel)**: `/Users/hshi/WOW/data-intelligence-tickets/tickets/hshi/DI-1297_Phone_Test_Results_Analysis/results/`
- **Combined Excel**: `/Users/hshi/WOW/drive-tickets/DI-1297 Phone Test Results Analysis/DI-1297_Phone_Test_Results_Combined.xlsx`
- **Dashboard**: `/Users/hshi/WOW/drive-tickets/DI-1297 Phone Test Results Analysis/DI-1297_Dashboard.html`
- **Tableau Workbook**: `/Users/hshi/WOW/drive-tickets/DI-1297 Phone Test Results Analysis/DI-1297_Phone_Test_Analysis.twb`

---

**Document Created**: 2025-10-11
**Last Updated**: 2025-10-11
**Ticket**: DI-1297
**Author**: Data Intelligence Team