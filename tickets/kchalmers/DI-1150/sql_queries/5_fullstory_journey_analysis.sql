-- DI-1150: FullStory Journey Analysis
-- Purpose: Join drop-off applications with FullStory page visit data
-- Note: Limited data available in FullStory for drop-off applications

-- Sample query to check FullStory data for specific app IDs
SELECT 
    evt_application_id_str as app_id,
    page_path_str,
    COUNT(*) as page_visits
FROM fivetran.fullstory.segment_event
WHERE event_custom_name = 'Loaded a Page'
  AND evt_application_id_str IN ('2902798', '2908037', '2916342', '2896961', '2875888', '2888002')
  AND trim(evt_application_id_str) <> ''
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- Broader analysis of common page patterns (limited results)
WITH dropoff_sample AS (
  SELECT DISTINCT CAST(app_id AS STRING) as app_id
  FROM business_intelligence.analytics.vw_app_loan_production
  WHERE (funnel_type = 'API' AND affiliate_landed_ts IS NOT NULL AND applied_ts IS NULL)
     OR (funnel_type = 'Non-API' AND applied_ts IS NULL)
    AND app_dt >= '2025-07-01'
    AND app_dt <= '2025-08-01'
  LIMIT 1000
)
SELECT 
  f.page_path_str,
  COUNT(DISTINCT f.evt_application_id_str) as unique_apps,
  COUNT(*) as total_visits,
  ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT f.evt_application_id_str), 2) as avg_visits_per_app
FROM fivetran.fullstory.segment_event f
INNER JOIN dropoff_sample d ON f.evt_application_id_str = d.app_id
WHERE f.event_custom_name = 'Loaded a Page'
  AND trim(f.evt_application_id_str) <> ''
GROUP BY f.page_path_str
HAVING COUNT(DISTINCT f.evt_application_id_str) >= 5
ORDER BY unique_apps DESC, total_visits DESC
LIMIT 50;