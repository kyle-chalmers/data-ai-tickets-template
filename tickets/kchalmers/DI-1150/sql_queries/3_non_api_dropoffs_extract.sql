-- DI-1150: Non-API Drop-offs Data Extract
-- Purpose: Extract Non-API channel drop-off applications with fraud indicators
-- Date Range: July 1-31, 2025

SELECT 
    'Non-API' as channel,
    app_id,
    guid,
    app_dt,
    app_ts,
    utm_source as affiliate_name,
    app_status,
    automated_fraud_decline_yn,
    manual_fraud_decline_yn
FROM business_intelligence.analytics.vw_app_loan_production
WHERE funnel_type = 'Non-API'
  AND applied_ts IS NULL
  AND app_dt >= '2025-07-01'
  AND app_dt <= '2025-08-01'
ORDER BY app_dt DESC;