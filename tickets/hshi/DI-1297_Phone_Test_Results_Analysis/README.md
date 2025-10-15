# DI-1297: Phone Test Results Analysis

## Ticket Information
- **Type**: Data Pull
- **Status**: In Spec
- **Assignee**: hshi@happymoney.com
- **Analysis Period**: April 2024 - Present

## Objective
Analyze metrics to determine the effectiveness of the Phone Test A/B experiments comparing low-intensity vs. high-intensity calling strategies across different delinquency stages.

## Phone Test Design

### Four Separate A/B Tests

#### 1. DPD3-14 Test
| Group | Criteria | Size | Call Frequency |
|-------|----------|------|----------------|
| Test Group (Low Intensity) | Position 17 in ('0'-'9','a','b','c') | ~81% | Once per week max (7-day cooldown), no weekend calls |
| Control Group (High Intensity) | Position 17 in ('d','e','f') | ~19% | Daily calls allowed, no weekend calls |

#### 2. DPD15-29 Test
| Group | Criteria | Size | Call Frequency |
|-------|----------|------|----------------|
| Test Group (Low Intensity) | Position 17 in ('0'-'9','a','b','c') | ~81% | Once per week max (7-day cooldown), no weekend calls |
| Control Group (High Intensity) | Position 17 in ('d','e','f') | ~19% | Daily calls allowed, no weekend calls |

#### 3. DPD30-59 Test
| Group | Criteria | Size | Call Frequency |
|-------|----------|------|----------------|
| Test Group (Low Intensity) | Position 12 in ('0','1','2') | ~19% | Once per week max (7-day cooldown), no weekend calls |
| Control Group (High Intensity) | Position 12 in ('3'-'9','a'-'f') | ~81% | Daily calls allowed, no weekend calls |

#### 4. DPD60-89 Test
| Group | Criteria | Size | Call Frequency |
|-------|----------|------|----------------|
| Test Group (Low Intensity) | Position 12 in ('0','1','2') | ~19% | Once per week max (7-day cooldown), no weekend calls |
| Control Group (High Intensity) | Position 12 in ('3'-'9','a'-'f') | ~81% | Daily calls allowed, no weekend calls |

### Test Mechanism
- **Weekdays**: Track in `CRON_STORE.RPT_PHONE_TEST`, suppress if contacted within 7 days
- **Weekends**: Direct suppression using same character position criteria
- **7-Day Cooldown**: Prevents repeated contact for test groups

## Required Metrics

### 1. Daily Group Size Trends
**Purpose**: Track how group sizes fluctuate over time

**Metric**: Count of unique PAYOFFUIDs by day

**Dimensions**:
- Test vs. Control group
- By DPD bucket (DPD3-14, DPD15-29, DPD30-59, DPD60-89)
- By LOAD_DATE

**Data Source**: `CRON_STORE.RPT_OUTBOUND_LISTS_HIST`

### 2. Cure Rate Analysis (Two Approaches)

#### A. First-Time Entry Cohort Analysis
**Purpose**: Track cure journey for accounts that first appear in each DPD bucket

**Definition**: Accounts that first appear in call list in month M, check if cured in month M+1 (or later)

**Cure Definition**: Account reaches DAYSPASTDUE = 0 in subsequent monthly snapshot

**Dimensions**:
- Test vs. Control group
- By DPD bucket (DPD3-14, DPD15-29, DPD30-59, DPD60-89)
- By entry cohort month

#### B. Rolling Monthly Performance
**Purpose**: Track cure rate in the next month since first appearance

**Definition**: % of accounts that cured in the next month since first appearing in the DPD bucket

**Example**: Account appears in April call list → Check if DAYSPASTDUE = 0 in May snapshot

**Dimensions**:
- Test vs. Control group
- By DPD bucket (DPD3-14, DPD15-29, DPD30-59, DPD60-89)
- By month

### 3. Roll Rate Analysis
**Purpose**: Track forward progression through delinquency stages

**Definition**: Consecutive month transitions to higher DPD buckets

**Transitions to Track**:
- DPD 3-14 → DPD 15-29
- DPD 15-29 → DPD 30-59
- DPD 30-59 → DPD 60-89

**Calculation**:
```
Roll Rate = (Accounts in DPD Bucket A in Month M that became DPD Bucket B in Month M+1)
            / (Total accounts in DPD Bucket A in Month M)
```

**Dimensions**:
- Test vs. Control group
- By transition type
- By month

## Data Sources

### Primary Tables

#### 1. CRON_STORE.RPT_OUTBOUND_LISTS_HIST
**Purpose**: Daily call list generation history

**Key Filters**:
- `SET_NAME = 'Call List'`
- `LIST_NAME IN ('DPD3-14', 'DPD15-29', 'DPD30-59', 'DPD60-89')`
- `SUPPRESSION_FLAG = FALSE` (accounts actually included in lists)
- `LOAD_DATE >= '2024-04-01'`

**Key Fields**:
- `LOAD_DATE`: Date of list generation
- `SET_NAME`: Campaign set identifier
- `LIST_NAME`: Specific DPD bucket
- `PAYOFFUID`: Customer identifier
- `SUPPRESSION_FLAG`: Whether customer was suppressed

#### 2. DATA_STORE.MVW_LOAN_TAPE_MONTHLY
**Purpose**: Monthly loan snapshots for DPD status and cure tracking

**Key Fields**:
- `ASOFDATE`: Monthly snapshot date
- `PAYOFFUID`: Customer identifier
- `DAYSPASTDUE`: Days past due
- `STATUS`: Loan status

### Test/Control Group Identification

**Logic**: Use PAYOFFUID character position to classify accounts

**DPD3-14 & DPD15-29 Buckets**:
```sql
CASE
    WHEN SUBSTRING(PAYOFFUID, 17, 1) IN ('0','1','2','3','4','5','6','7','8','9','a','b','c')
    THEN 'Test (Low Intensity)'
    WHEN SUBSTRING(PAYOFFUID, 17, 1) IN ('d','e','f')
    THEN 'Control (High Intensity)'
END
```

**DPD30-59 & DPD60-89 Buckets**:
```sql
CASE
    WHEN SUBSTRING(PAYOFFUID, 12, 1) IN ('0','1','2')
    THEN 'Test (Low Intensity)'
    WHEN SUBSTRING(PAYOFFUID, 12, 1) IN ('3','4','5','6','7','8','9','a','b','c','d','e','f')
    THEN 'Control (High Intensity)'
END
```

## Analysis Framework

Each of the four DPD buckets is analyzed independently:

1. **DPD3-14**: Compare test (81% low intensity) vs. control (19% high intensity)
2. **DPD15-29**: Compare test (81% low intensity) vs. control (19% high intensity)
3. **DPD30-59**: Compare test (19% low intensity) vs. control (81% high intensity)
4. **DPD60-89**: Compare test (19% low intensity) vs. control (81% high intensity)

## Business Context
- **Primary Job**: BI-2482 (Outbound List Generation System)
- **Test Update**: BI-2846 (80% low-intensity for DPD 3-29)
- **Test Start**: April 2024
- **Goal**: Optimize call frequency to balance collection effectiveness with customer experience
- **Hypothesis**:
  - Early DPD (3-29): May self-cure with less intensive calling
  - Later DPD (30-89): May benefit from more intensive calling

## Folder Structure

```
DI-1297_Phone_Test_Results_Analysis/
├── README.md                           # This file - project documentation
├── EXPORT_INSTRUCTIONS.md              # Instructions for exporting query results
├── sql/                                # SQL queries
│   ├── 01_daily_group_size_trends.sql
│   ├── 02_cure_rate_cohort_analysis.sql
│   ├── 03_cure_rate_rolling_monthly.sql
│   └── 04_roll_rate_analysis.sql
├── scripts/                            # Export and automation scripts
│   ├── export_results.sh
│   └── export_results_to_csv.py
└── results/                            # Output CSV files (generated)
    ├── 01_daily_group_size_trends_results.csv
    ├── 02_cure_rate_cohort_analysis_results.csv
    ├── 03_cure_rate_rolling_monthly_results.csv
    └── 04_roll_rate_analysis_results.csv
```

## Deliverables
1. ✅ SQL queries for each metric (in `sql/` folder)
2. Data extracts or dashboard showing:
   - Daily group size trends by DPD bucket
   - Cure rate comparisons (test vs. control) by DPD bucket
   - Roll rate comparisons (test vs. control) by DPD bucket
3. Analysis summary and recommendations

## Progress
- ✅ SQL queries completed (all 4 queries)
- ✅ Query 1 & 2 tested and validated
- ⏳ Export results to CSV files
- ⏳ Create visualizations/dashboard
- ⏳ Analyze results and document findings