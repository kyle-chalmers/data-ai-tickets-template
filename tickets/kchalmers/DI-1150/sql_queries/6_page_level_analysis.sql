-- DI-1150: Page-Level Abandonment Analysis for API and Non-API Channels
-- Purpose: Detailed page-level journey analysis with abandonment event counts
-- Date Range: 2025-01-01 to 2025-08-05 (Full 2025 analysis period)

-- =============================================================================
-- API CHANNEL PAGE ANALYSIS
-- =============================================================================

-- API Channel: Page-level abandonment patterns with event counts
WITH api_dropoffs AS (
  SELECT 
    CAST(app_id AS STRING) as app_id_str,
    funnel_type,
    app_dt,
    affiliate_landed_ts,
    applied_ts,
    utm_source as partner_name
  FROM business_intelligence.analytics.vw_app_loan_production
  WHERE funnel_type = 'API' 
    AND affiliate_landed_ts IS NOT NULL 
    AND applied_ts IS NULL  -- Drop-offs only
    AND app_dt >= '2025-01-01'
    AND app_dt <= '2025-08-05'
),

api_last_pages AS (
  SELECT 
    f.evt_application_id_str,
    f.page_path_str,
    f.event_start,
    -- Normalize page paths for pattern analysis
    CASE 
      WHEN f.page_path_str LIKE '/apply/api-aff-app-summary/%' THEN '/apply/api-aff-app-summary/*'
      WHEN f.page_path_str LIKE '/apply/route/application/%' THEN '/apply/route/application/*'
      WHEN f.page_path_str LIKE '/apply/%' THEN REGEXP_REPLACE(f.page_path_str, '/[0-9]+', '/*')
      ELSE f.page_path_str
    END as normalized_page_path,
    -- Get the last page visited before abandonment
    ROW_NUMBER() OVER (PARTITION BY f.evt_application_id_str ORDER BY f.event_start DESC) as rn
  FROM fivetran.fullstory.segment_event f
  INNER JOIN api_dropoffs a ON f.evt_application_id_str = a.app_id_str
  WHERE f.event_custom_name = 'Loaded a Page'
    AND TRIM(f.evt_application_id_str) <> ''
)

SELECT 
  'API' as channel,
  normalized_page_path,
  COUNT(*) as abandonment_events,
  COUNT(DISTINCT evt_application_id_str) as unique_applications,
  ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT evt_application_id_str), 2) as avg_events_per_app,
  -- Sample of actual page paths for reference
  LISTAGG(DISTINCT page_path_str, '; ') WITHIN GROUP (ORDER BY page_path_str) as sample_paths
FROM api_last_pages
WHERE rn = 1  -- Only the last page before abandonment
GROUP BY normalized_page_path
HAVING COUNT(*) >= 3  -- Filter for meaningful patterns
ORDER BY abandonment_events DESC
LIMIT 20;

-- =============================================================================
-- NON-API CHANNEL PAGE ANALYSIS  
-- =============================================================================

-- Non-API Channel: Page-level abandonment patterns with event counts
WITH non_api_dropoffs AS (
  SELECT 
    CAST(app_id AS STRING) as app_id_str,
    funnel_type,
    app_dt,
    applied_ts,
    app_status,
    utm_source
  FROM business_intelligence.analytics.vw_app_loan_production
  WHERE funnel_type = 'Non-API' 
    AND applied_ts IS NULL  -- Drop-offs only
    AND app_dt >= '2025-01-01'
    AND app_dt <= '2025-08-05'
),

non_api_last_pages AS (
  SELECT 
    f.evt_application_id_str,
    f.page_path_str,
    f.event_start,
    -- Normalize page paths for pattern analysis
    CASE 
      WHEN f.page_path_str LIKE '/apply/loan-details/%' THEN '/apply/loan-details/*'
      WHEN f.page_path_str LIKE '/apply/personal-information/%' THEN '/apply/personal-information/*'
      WHEN f.page_path_str LIKE '/apply/financial-information/%' THEN '/apply/financial-information/*'
      WHEN f.page_path_str LIKE '/apply/bank-account/%' THEN '/apply/bank-account/*'
      WHEN f.page_path_str LIKE '/apply/application/%' THEN '/apply/application/*'
      WHEN f.page_path_str LIKE '/apply/%' THEN REGEXP_REPLACE(f.page_path_str, '/[0-9]+', '/*')
      ELSE f.page_path_str
    END as normalized_page_path,
    -- Get the last page visited before abandonment
    ROW_NUMBER() OVER (PARTITION BY f.evt_application_id_str ORDER BY f.event_start DESC) as rn
  FROM fivetran.fullstory.segment_event f
  INNER JOIN non_api_dropoffs n ON f.evt_application_id_str = n.app_id_str
  WHERE f.event_custom_name = 'Loaded a Page'
    AND TRIM(f.evt_application_id_str) <> ''
)

SELECT 
  'Non-API' as channel,
  normalized_page_path,
  COUNT(*) as abandonment_events,
  COUNT(DISTINCT evt_application_id_str) as unique_applications,
  ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT evt_application_id_str), 2) as avg_events_per_app,
  -- Sample of actual page paths for reference
  LISTAGG(DISTINCT page_path_str, '; ') WITHIN GROUP (ORDER BY page_path_str) as sample_paths
FROM non_api_last_pages
WHERE rn = 1  -- Only the last page before abandonment
GROUP BY normalized_page_path
HAVING COUNT(*) >= 10  -- Filter for meaningful patterns (higher threshold for Non-API)
ORDER BY abandonment_events DESC
LIMIT 20;

-- =============================================================================
-- COMBINED CHANNEL COMPARISON
-- =============================================================================

-- Combined analysis for direct channel comparison
WITH all_dropoffs AS (
  SELECT 
    CAST(app_id AS STRING) as app_id_str,
    funnel_type,
    app_dt,
    CASE 
      WHEN funnel_type = 'API' THEN utm_source
      ELSE utm_source
    END as traffic_source
  FROM business_intelligence.analytics.vw_app_loan_production
  WHERE ((funnel_type = 'API' AND affiliate_landed_ts IS NOT NULL AND applied_ts IS NULL)
         OR (funnel_type = 'Non-API' AND applied_ts IS NULL))
    AND app_dt >= '2025-01-01'
    AND app_dt <= '2025-08-05'
),

all_last_pages AS (
  SELECT 
    a.funnel_type,
    f.evt_application_id_str,
    -- Universal page path normalization
    CASE 
      WHEN f.page_path_str LIKE '/apply/api-aff-app-summary/%' THEN '/apply/api-aff-app-summary/*'
      WHEN f.page_path_str LIKE '/apply/route/application/%' THEN '/apply/route/application/*'
      WHEN f.page_path_str LIKE '/apply/loan-details/%' THEN '/apply/loan-details/*'
      WHEN f.page_path_str LIKE '/apply/personal-information/%' THEN '/apply/personal-information/*'
      WHEN f.page_path_str LIKE '/apply/financial-information/%' THEN '/apply/financial-information/*'
      WHEN f.page_path_str LIKE '/apply/bank-account/%' THEN '/apply/bank-account/*'
      WHEN f.page_path_str LIKE '/apply/application/%' THEN '/apply/application/*'
      WHEN f.page_path_str LIKE '/apply/%' THEN REGEXP_REPLACE(f.page_path_str, '/[0-9]+', '/*')
      ELSE f.page_path_str
    END as normalized_page_path,
    ROW_NUMBER() OVER (PARTITION BY f.evt_application_id_str ORDER BY f.event_start DESC) as rn
  FROM fivetran.fullstory.segment_event f
  INNER JOIN all_dropoffs a ON f.evt_application_id_str = a.app_id_str
  WHERE f.event_custom_name = 'Loaded a Page'
    AND TRIM(f.evt_application_id_str) <> ''
)

SELECT 
  funnel_type as channel,
  normalized_page_path,
  COUNT(*) as abandonment_events,
  COUNT(DISTINCT evt_application_id_str) as unique_applications,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY funnel_type), 2) as pct_of_channel_abandonment
FROM all_last_pages
WHERE rn = 1  -- Only the last page before abandonment
GROUP BY funnel_type, normalized_page_path
HAVING COUNT(*) >= 3
ORDER BY funnel_type, abandonment_events DESC;

-- =============================================================================
-- COVERAGE ANALYSIS
-- =============================================================================

-- FullStory coverage analysis for the selected time period
WITH coverage_analysis AS (
  SELECT 
    funnel_type,
    COUNT(*) as total_dropoffs,
    COUNT(CASE WHEN has_fullstory = 1 THEN 1 END) as with_fullstory,
    ROUND(COUNT(CASE WHEN has_fullstory = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as coverage_pct
  FROM (
    SELECT 
      d.funnel_type,
      d.app_id_str,
      CASE WHEN f.evt_application_id_str IS NOT NULL THEN 1 ELSE 0 END as has_fullstory
    FROM (
      SELECT 
        CAST(app_id AS STRING) as app_id_str,
        funnel_type
      FROM business_intelligence.analytics.vw_app_loan_production
      WHERE ((funnel_type = 'API' AND affiliate_landed_ts IS NOT NULL AND applied_ts IS NULL)
             OR (funnel_type = 'Non-API' AND applied_ts IS NULL))
        AND app_dt >= $v_start_date
        AND app_dt <= $v_end_date
    ) d
    LEFT JOIN (
      SELECT DISTINCT evt_application_id_str
      FROM fivetran.fullstory.segment_event
      WHERE event_custom_name = 'Loaded a Page'
        AND TRIM(evt_application_id_str) <> ''
    ) f ON d.app_id_str = f.evt_application_id_str
  )
  GROUP BY funnel_type
)

SELECT 
  channel,
  total_dropoffs,
  with_fullstory,
  coverage_pct,
  CONCAT('Analysis based on ', with_fullstory, ' applications with FullStory data out of ', 
         total_dropoffs, ' total drop-offs (', coverage_pct, '% coverage)') as coverage_summary
FROM coverage_analysis
ORDER BY funnel_type;