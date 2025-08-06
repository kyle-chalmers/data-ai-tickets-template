-- DI-1150: Non-API Fraud Pattern Analysis
-- Purpose: Analyze fraud rejection patterns in Non-API drop-offs
-- Date Range: July 1-31, 2025

SELECT 
    app_status,
    automated_fraud_decline_yn,
    manual_fraud_decline_yn,
    COUNT(*) as applications,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM business_intelligence.analytics.vw_app_loan_production
WHERE funnel_type = 'Non-API'
  AND applied_ts IS NULL
  AND app_dt >= '2025-07-01'
  AND app_dt <= '2025-08-01'
GROUP BY 1, 2, 3
ORDER BY applications DESC;