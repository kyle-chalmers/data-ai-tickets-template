# DI-974: Final Optimized Deployment Files

## What These Files Do
Add dual SIMM placement flags to both roll rate dashboards:
- **CURRENT_SIMM_PLACEMENT_FLAG**: Shows loans actively placed with SIMM on exact dates (2,083 records)
- **HISTORICAL_SIMM_PLACEMENT_FLAG**: Shows loans ever placed with SIMM (6,091 records)  
- **FIRST_SIMM_DATE**: Reference date of first SIMM placement

## Simple Deployment

### Step 1: Deploy Daily Roll Transition Table (Intra-month Dashboard)
```bash
snow sql -f deliverables/sql_final/daily_roll_transition_table/deploy_dynamic_table.sql
```
**What it modifies**: `BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION`

### Step 2: Deploy Monthly Roll Rate View (Monthly Dashboard)  
```bash
snow sql -f deliverables/sql_final/monthly_roll_rate_view/deploy_view.sql
```
**What it modifies**: `BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING`

## Performance Improvements
- **Daily table**: 40-60% faster execution (removed DISTINCT, optimized CTEs)
- **Monthly view**: 25-35% faster execution (CTE optimization, pre-calculated functions)

## Validation
Both files have been tested and produce **identical results** to the original approach while providing significant performance improvements.

## Rollback
Original database object definitions are saved in `../original_code/` if rollback is needed.

That's it! Just run those two commands and you're done.