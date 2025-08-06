# Implementation Guide: Adding SIMM Flag to Roll Rate Dashboards

## Overview
This guide provides step-by-step instructions for adding the SIMM placement flag to both the intra-month (daily) and monthly roll rate dashboards by modifying the underlying database objects.

## IMPORTANT: Database Object Modifications

**This implementation modifies existing database objects:**
- `BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION` (Dynamic Table)
- `BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING` (View)

**Original definitions have been saved in the `original_code/` folder for rollback purposes.**

## Implementation Steps

### Step 1: Review Original Code Backup
Before making changes, review the original definitions saved in:
- `original_code/original_dynamic_table_ddl.sql`
- `original_code/original_view_ddl.sql`

### Step 2: Modify Dynamic Table (for Daily/Intra-month Dashboard)

Execute the SQL in `alter_dynamic_table_add_simm_flag.sql`:

This will:
1. Add `SIMM_PLACEMENT_FLAG` column (INTEGER: 1 = placed with SIMM, 0 = not placed)
2. Add `FIRST_SIMM_DATE` column (DATE: first SIMM placement date)
3. Update the dynamic table query to populate these columns with proper join logic

**Join Logic for Daily Data:**
- Matches on `PAYOFFUID` 
- Includes SIMM placement when `ASOFDATE >= FIRST_SIMM_DATE`
- This ensures daily snapshots correctly reflect SIMM status

### Step 3: Modify View (for Monthly Dashboard)

Execute the SQL in `alter_view_add_simm_flag.sql`:

This will:
1. Add the same SIMM columns to the monthly view
2. Update the view query with proper SIMM join logic
3. Maintain all existing functionality while adding SIMM data

## Alternative Option: Dashboard-Level Implementation

If the dashboard uses a custom SQL query, add the following to your existing query:

### Step 1: Add the CTE or subquery for SIMM data
```sql
WITH simm_placements AS (
    SELECT 
        PAYOFFUID,
        MIN(LOAN_TAPE_ASOFDATE) as FIRST_SIMM_DATE
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM'
        AND SUPPRESSION_FLAG = FALSE
    GROUP BY PAYOFFUID
)
```

### Step 2: Add LEFT JOIN to your main query
```sql
LEFT JOIN simm_placements s ON rr.PAYOFFUID = s.PAYOFFUID
```

### Step 3: Add the flag to your SELECT clause
```sql
CASE 
    WHEN s.PAYOFFUID IS NOT NULL 
        AND rr.ASOFDATE >= s.FIRST_SIMM_DATE 
    THEN 1 
    ELSE 0 
END AS SIMM_PLACEMENT_FLAG
```

## Option 2: Create a Calculated Field in Tableau

If modifying the SQL is not possible, create a calculated field:

### Tableau Calculated Field:
```
IF { FIXED [PAYOFFUID] : 
    COUNTD(
        IF [Data Source].[SET_NAME] = 'SIMM' 
        AND NOT [Data Source].[SUPPRESSION_FLAG]
        AND [Data Source].[LOAN_TAPE_ASOFDATE] <= [ASOFDATE]
        THEN 1 
        END
    ) } > 0 
THEN 1 
ELSE 0 
END
```

Note: This requires the RPT_OUTBOUND_LISTS_HIST table to be included in your data source.

## Option 3: Create a View

Create a new view that includes the SIMM flag:

```sql
CREATE OR REPLACE VIEW VW_ROLL_RATE_WITH_SIMM AS
-- Use the complete query from add_simm_flag_to_roll_rate_dashboard.sql
```

## Filter Implementation

Once the flag is added, create a dashboard filter:
- Field Name: SIMM_PLACEMENT_FLAG
- Values: 
  - 0 = Not placed with SIMM
  - 1 = Placed with SIMM
- Default: Show all

## Performance Considerations

- The LEFT JOIN approach is most efficient for batch processing
- Consider creating an index on RPT_OUTBOUND_LISTS_HIST (SET_NAME, PAYOFFUID) if performance is slow
- The SIMM data is relatively small (~6,300 unique loans), so performance impact should be minimal

## Validation

After implementation, validate using the provided validation query to ensure:
1. SIMM loans are correctly identified
2. Historical placement dates are respected
3. Performance metrics show expected differences between SIMM and non-SIMM loans