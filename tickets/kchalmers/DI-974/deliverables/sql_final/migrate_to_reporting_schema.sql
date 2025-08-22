-- DI-974: Migration Script from CRON_STORE to REPORTING Schema
-- This script helps migrate the dashboard objects to the REPORTING schema for Tableau access

-- Step 1: Backup existing CRON_STORE objects (optional - for safety)
-- Uncomment these lines if you want to create backups before migration:
/*
CREATE OR REPLACE DYNAMIC TABLE BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION_BACKUP AS
  SELECT * FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION;

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING_BACKUP AS
  SELECT * FROM BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING;
*/

-- Step 2: Create new objects in REPORTING schema
-- (Run the main deployment files to create these)

-- Step 3: Verify data integrity between old and new locations
SELECT 
    'CRON_STORE Daily' as location,
    COUNT(*) as record_count,
    MAX(ASOFDATE) as latest_date,
    SUM(CASE WHEN CURRENT_SIMM_PLACEMENT_FLAG = 1 THEN 1 ELSE 0 END) as current_simm_count
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION

UNION ALL

SELECT 
    'REPORTING Daily' as location,
    COUNT(*) as record_count,
    MAX(ASOFDATE) as latest_date,
    SUM(CASE WHEN CURRENT_SIMM_PLACEMENT_FLAG = 1 THEN 1 ELSE 0 END) as current_simm_count
FROM BUSINESS_INTELLIGENCE.REPORTING.DSH_GR_DAILY_ROLL_TRANSITION

UNION ALL

SELECT 
    'CRON_STORE Monthly' as location,
    COUNT(*) as record_count,
    MAX(ASOFDATE) as latest_date,
    SUM(CASE WHEN CURRENT_SIMM_PLACEMENT_FLAG = 1 THEN 1 ELSE 0 END) as current_simm_count
FROM BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING

UNION ALL

SELECT 
    'REPORTING Monthly' as location,
    COUNT(*) as record_count,
    MAX(ASOFDATE) as latest_date,
    SUM(CASE WHEN CURRENT_SIMM_PLACEMENT_FLAG = 1 THEN 1 ELSE 0 END) as current_simm_count
FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_MONTHLY_ROLL_RATE_MONITORING

ORDER BY location;

-- Step 4: Update Tableau connections (manual step)
-- Update your Tableau dashboards to point to:
-- - BUSINESS_INTELLIGENCE.REPORTING.DSH_GR_DAILY_ROLL_TRANSITION (for intra-month dashboard)
-- - BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_MONTHLY_ROLL_RATE_MONITORING (for monthly dashboard)

-- Step 5: Clean up old CRON_STORE objects (run after Tableau migration is complete)
-- Uncomment these lines ONLY after confirming Tableau is using REPORTING schema:
/*
DROP DYNAMIC TABLE IF EXISTS BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION;
DROP VIEW IF EXISTS BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING;
*/