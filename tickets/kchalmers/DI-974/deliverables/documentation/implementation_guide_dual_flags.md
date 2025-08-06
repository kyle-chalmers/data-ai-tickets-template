# Implementation Guide: Adding Dual SIMM Flags to Roll Rate Dashboards

## Overview
This implementation adds **TWO** SIMM placement flags to provide comprehensive visibility into SIMM placement activity:

1. **CURRENT_SIMM_PLACEMENT_FLAG**: Shows exact daily SIMM placement activity (2,083 records on 2025-07-30)
2. **HISTORICAL_SIMM_PLACEMENT_FLAG**: Shows cumulative "ever been placed" status (6,091 records on 2025-07-30)

## Business Value of Dual Flags

### Current SIMM Placement Flag (Exact Date Match)
- **Purpose**: Track daily SIMM placement activity
- **Use Case**: "Show me loans that were actively placed with SIMM on this specific date"  
- **Business Insight**: Daily workflow analysis, placement timing, immediate impact assessment
- **Data Pattern**: 0.61% of daily records show active SIMM placement

### Historical SIMM Placement Flag (Cumulative Status)
- **Purpose**: Track cumulative SIMM exposure
- **Use Case**: "Show me loans that have ever been placed with SIMM and are still within the placement period"
- **Business Insight**: Long-term performance analysis, total SIMM portfolio impact
- **Data Pattern**: 1.77% of daily records show historical SIMM placement

## Database Object Modifications

### Dynamic Table: DSH_GR_DAILY_ROLL_TRANSITION
**New Columns Added:**
- `CURRENT_SIMM_PLACEMENT_FLAG` (INTEGER): 1 = actively placed on this date, 0 = not placed
- `HISTORICAL_SIMM_PLACEMENT_FLAG` (INTEGER): 1 = ever been placed and date >= first placement, 0 = never placed or before placement
- `FIRST_SIMM_DATE` (DATE): Date of first SIMM placement for reference

### View: VW_DSH_MONTHLY_ROLL_RATE_MONITORING  
**New Columns Added:**
- `CURRENT_SIMM_PLACEMENT_FLAG` (INTEGER): 1 = placed during this month, 0 = not placed during month
- `HISTORICAL_SIMM_PLACEMENT_FLAG` (INTEGER): 1 = ever been placed and month >= first placement, 0 = never placed or before placement
- `FIRST_SIMM_DATE` (DATE): Date of first SIMM placement for reference

## Implementation Steps

### Step 1: Execute Dynamic Table Changes
```bash
snow sql -f deliverables/sql_queries/1_alter_dynamic_table_add_simm_flag.sql
```

### Step 2: Execute View Changes  
```bash
snow sql -f deliverables/sql_queries/2_alter_view_add_simm_flag.sql
```

### Step 3: Validation Testing
```bash
snow sql -f deliverables/testing/test_both_simm_flags.sql --format csv
```

**Expected Results:**
- Current SIMM Flag: ~2,083 records (0.61%)
- Historical SIMM Flag: ~6,091 records (1.77%)
- No impact on existing row counts

## Dashboard Integration Options

### Option 1: Separate Filters
Create two separate filters in your dashboard:
- **Current SIMM Activity**: Use `CURRENT_SIMM_PLACEMENT_FLAG`
- **Historical SIMM Portfolio**: Use `HISTORICAL_SIMM_PLACEMENT_FLAG`

### Option 2: Combined Analysis
Create calculated fields to analyze combinations:
- **Never SIMM**: Both flags = 0
- **Currently Active**: Current = 1, Historical = 1  
- **Previously Active**: Current = 0, Historical = 1
- **New Placement**: Current = 1, Historical = 0 (rare edge case)

### Option 3: Time-Series Analysis
Use `FIRST_SIMM_DATE` with Historical flag to analyze:
- Time since first SIMM placement
- Performance trends post-SIMM placement
- SIMM placement duration analysis

## Query Examples

### Daily Dashboard - Current Activity Analysis
```sql
SELECT 
    CURRENT_DPD_STATUS,
    ROLL_STATUS,
    COUNT(*) as TOTAL_LOANS,
    COUNT(CASE WHEN CURRENT_SIMM_PLACEMENT_FLAG = 1 THEN 1 END) as CURRENT_SIMM_LOANS,
    ROUND(COUNT(CASE WHEN CURRENT_SIMM_PLACEMENT_FLAG = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as CURRENT_SIMM_PCT
FROM DSH_GR_DAILY_ROLL_TRANSITION
WHERE ASOFDATE = '2025-07-30'
GROUP BY CURRENT_DPD_STATUS, ROLL_STATUS
ORDER BY CURRENT_DPD_STATUS, ROLL_STATUS;
```

### Historical Impact Analysis
```sql
SELECT 
    HISTORICAL_SIMM_PLACEMENT_FLAG,
    ROLL_STATUS,
    COUNT(*) as LOAN_COUNT,
    AVG(REMAINING_PRINCIPAL) as AVG_PRINCIPAL,
    AVG(CURRENT_DPD) as AVG_DPD
FROM DSH_GR_DAILY_ROLL_TRANSITION
WHERE ASOFDATE = '2025-07-30'
GROUP BY HISTORICAL_SIMM_PLACEMENT_FLAG, ROLL_STATUS
ORDER BY HISTORICAL_SIMM_PLACEMENT_FLAG, ROLL_STATUS;
```

## Performance Considerations

- **Current Flag**: Requires direct JOIN with RPT_OUTBOUND_LISTS_HIST (higher cost)
- **Historical Flag**: Uses pre-aggregated CTE (optimized)
- **Combined Impact**: Minimal performance impact due to efficient join strategies
- **Indexing**: Consider index on (SET_NAME, SUPPRESSION_FLAG, PAYOFFUID, LOAN_TAPE_ASOFDATE)

## Rollback Procedures

Original definitions saved in `original_code/` folder:
- `original_dynamic_table_ddl.sql`
- `original_view_ddl.sql`

To rollback, execute the original CREATE OR REPLACE statements.

## Validation Checklist

- [ ] Row counts remain identical after deployment
- [ ] Current SIMM flag shows ~2,083 records (0.61%)
- [ ] Historical SIMM flag shows ~6,091 records (1.77%)
- [ ] All existing functionality preserved
- [ ] New columns populate correctly
- [ ] Dashboard filters work as expected