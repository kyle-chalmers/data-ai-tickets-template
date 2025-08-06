-- DI-1150: Drop-off Summary Statistics by Channel
-- Purpose: Get overall drop-off rates for API vs Non-API channels
-- Date Range: July 1-31, 2025

SELECT 
    funnel_type,
    COUNT(*) as total_started,
    COUNT(CASE WHEN applied_ts IS NULL THEN 1 END) as dropped_off,
    ROUND(COUNT(CASE WHEN applied_ts IS NULL THEN 1 END) * 100.0 / COUNT(*), 2) as drop_off_rate
FROM business_intelligence.analytics.vw_app_loan_production
WHERE app_dt >= '2025-07-01' 
  AND app_dt <= '2025-08-01'
GROUP BY funnel_type
ORDER BY funnel_type;