-- DI-1146: Summary Analysis for Executive Dashboard
-- High-level metrics on device usage patterns across all applications
-- Used for Slack channel update and stakeholder reporting

WITH device_summary AS (
  SELECT 
    EVT_APPLICATION_ID_STR,
    PAGE_OPERATING_SYSTEM,
    PAGE_DEVICE,
    COUNT(*) as event_count,
    MAX(_FIVETRAN_SYNCED) as latest_event
  FROM FIVETRAN.FULLSTORY.SEGMENT_EVENT 
  WHERE EVT_APPLICATION_ID_STR IS NOT NULL
    AND PAGE_OPERATING_SYSTEM IS NOT NULL
    AND PAGE_DEVICE IS NOT NULL
  GROUP BY EVT_APPLICATION_ID_STR, PAGE_OPERATING_SYSTEM, PAGE_DEVICE
),
app_device_flags AS (
  SELECT 
    EVT_APPLICATION_ID_STR,
    COUNT(DISTINCT PAGE_DEVICE) as device_types_used,
    MAX(CASE WHEN PAGE_DEVICE = 'Mobile' THEN 1 ELSE 0 END) as used_mobile,
    MAX(CASE WHEN PAGE_DEVICE = 'Desktop' THEN 1 ELSE 0 END) as used_desktop,
    SUM(event_count) as total_events,
    MAX(latest_event) as latest_event_date
  FROM device_summary
  GROUP BY EVT_APPLICATION_ID_STR
),
with_loan_data AS (
  SELECT 
    adf.*,
    los.APPLICATION_GUID,
    los.ORIGINATION_DATE,
    los.APPLICATION_SUBMITTED_DATE,
    los.APPLICATION_APPROVED_DATE,
    los.SELECTED_OFFER_DATE,
    los.APPLICATION_STARTED_DATE,
    los.ESIGN_DATE,
    CASE WHEN los.APPLICATION_GUID IS NOT NULL THEN 1 ELSE 0 END as has_loan_data
  FROM app_device_flags adf
  LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT los 
    ON adf.EVT_APPLICATION_ID_STR = CAST(los.LOAN_ID AS VARCHAR)
)
SELECT 
  'Application Device Usage Analysis' as analysis_type,
  COUNT(*) as total_applications_tracked,
  COUNT(CASE WHEN device_types_used > 1 THEN 1 END) as multi_device_applications,
  COUNT(CASE WHEN device_types_used = 1 THEN 1 END) as single_device_applications,
  ROUND(COUNT(CASE WHEN device_types_used > 1 THEN 1 END) * 100.0 / COUNT(*), 2) as pct_multi_device,
  
  COUNT(CASE WHEN used_mobile = 1 AND used_desktop = 0 THEN 1 END) as mobile_only_apps,
  COUNT(CASE WHEN used_desktop = 1 AND used_mobile = 0 THEN 1 END) as desktop_only_apps,
  COUNT(CASE WHEN used_mobile = 1 AND used_desktop = 1 THEN 1 END) as mobile_and_desktop_apps,
  
  ROUND(COUNT(CASE WHEN used_mobile = 1 AND used_desktop = 0 THEN 1 END) * 100.0 / COUNT(*), 2) as pct_mobile_only,
  ROUND(COUNT(CASE WHEN used_desktop = 1 AND used_mobile = 0 THEN 1 END) * 100.0 / COUNT(*), 2) as pct_desktop_only,
  ROUND(COUNT(CASE WHEN used_mobile = 1 AND used_desktop = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as pct_cross_device,
  
  -- Loan application matching
  COUNT(CASE WHEN has_loan_data = 1 THEN 1 END) as applications_with_loan_data,
  COUNT(CASE WHEN has_loan_data = 0 THEN 1 END) as applications_without_loan_data,
  ROUND(COUNT(CASE WHEN has_loan_data = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as pct_matched_to_loans,
  
  -- Date information  
  COUNT(CASE WHEN has_loan_data = 1 AND ORIGINATION_DATE IS NOT NULL THEN 1 END) as applications_with_origination,
  COUNT(CASE WHEN has_loan_data = 1 AND APPLICATION_SUBMITTED_DATE IS NOT NULL THEN 1 END) as applications_with_submission,
  COUNT(CASE WHEN has_loan_data = 1 AND SELECTED_OFFER_DATE IS NOT NULL THEN 1 END) as applications_with_offer_selection,
  COUNT(CASE WHEN has_loan_data = 1 AND APPLICATION_STARTED_DATE IS NOT NULL THEN 1 END) as applications_with_start_date,
  COUNT(CASE WHEN has_loan_data = 1 AND ESIGN_DATE IS NOT NULL THEN 1 END) as applications_with_esign,
  
  SUM(total_events) as total_tracked_events,
  MIN(DATE(latest_event_date)) as earliest_latest_event,
  MAX(DATE(latest_event_date)) as most_recent_latest_event,
  CURRENT_DATE() as analysis_date
  
FROM with_loan_data;