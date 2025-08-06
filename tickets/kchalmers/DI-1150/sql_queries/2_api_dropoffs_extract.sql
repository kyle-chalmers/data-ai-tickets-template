-- DI-1150: API Drop-offs Data Extract
-- Purpose: Extract API channel drop-off applications with details
-- Date Range: July 1-31, 2025

SELECT 
    'API' as channel,
    app_id,
    guid,
    app_dt,
    affiliate_landed_ts,
    utm_source as affiliate_name,
    app_status
FROM business_intelligence.analytics.vw_app_loan_production
WHERE funnel_type = 'API'
  AND affiliate_landed_ts IS NOT NULL 
  AND applied_ts IS NULL
  AND app_dt >= '2025-07-01'
  AND app_dt <= '2025-08-01'
ORDER BY app_dt DESC;