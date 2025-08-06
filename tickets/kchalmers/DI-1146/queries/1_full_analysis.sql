-- DI-1146: Full Application Device Usage Analysis
-- Analyzes each EVT_APPLICATION_ID_STR by operating system and device patterns
-- Shows single vs multi-device usage with boolean indicators

WITH device_summary AS (
  SELECT 
    EVT_APPLICATION_ID_STR,
    PAGE_OPERATING_SYSTEM,
    PAGE_DEVICE,
    COUNT(*) as event_count,
    COUNT(DISTINCT SESSION_ID) as unique_sessions,
    COUNT(DISTINCT USER_ID) as unique_users,
    MIN(_FIVETRAN_SYNCED) as first_event,
    MAX(_FIVETRAN_SYNCED) as last_event
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
    COUNT(DISTINCT PAGE_OPERATING_SYSTEM) as os_types_used,
    MAX(CASE WHEN PAGE_DEVICE = 'Mobile' THEN 1 ELSE 0 END) as used_mobile,
    MAX(CASE WHEN PAGE_DEVICE = 'Desktop' THEN 1 ELSE 0 END) as used_desktop,
    MAX(CASE WHEN PAGE_DEVICE = 'Tablet' THEN 1 ELSE 0 END) as used_tablet,
    MAX(CASE WHEN PAGE_OPERATING_SYSTEM = 'iOS' THEN 1 ELSE 0 END) as used_ios,
    MAX(CASE WHEN PAGE_OPERATING_SYSTEM = 'Android' THEN 1 ELSE 0 END) as used_android,
    MAX(CASE WHEN PAGE_OPERATING_SYSTEM = 'Windows' THEN 1 ELSE 0 END) as used_windows,
    MAX(CASE WHEN PAGE_OPERATING_SYSTEM = 'OS X' THEN 1 ELSE 0 END) as used_macos,
    SUM(event_count) as total_events,
    SUM(unique_sessions) as total_sessions,
    MAX(unique_users) as total_users,
    MAX(last_event) as latest_event_date
  FROM device_summary
  GROUP BY EVT_APPLICATION_ID_STR
),
primary_device_info AS (
  SELECT 
    EVT_APPLICATION_ID_STR,
    FIRST_VALUE(PAGE_DEVICE) OVER (PARTITION BY EVT_APPLICATION_ID_STR ORDER BY event_count DESC) as primary_device,
    FIRST_VALUE(PAGE_OPERATING_SYSTEM) OVER (PARTITION BY EVT_APPLICATION_ID_STR ORDER BY event_count DESC) as primary_os
  FROM device_summary
  QUALIFY ROW_NUMBER() OVER (PARTITION BY EVT_APPLICATION_ID_STR ORDER BY event_count DESC) = 1
)
SELECT 
  adf.EVT_APPLICATION_ID_STR,
  adf.device_types_used,
  adf.os_types_used,
  CASE WHEN adf.device_types_used > 1 THEN 'Multi-Device' ELSE 'Single-Device' END as device_usage_pattern,
  adf.used_mobile::BOOLEAN as used_mobile,
  adf.used_desktop::BOOLEAN as used_desktop,
  adf.used_tablet::BOOLEAN as used_tablet,
  adf.used_ios::BOOLEAN as used_ios,
  adf.used_android::BOOLEAN as used_android,
  adf.used_windows::BOOLEAN as used_windows,
  adf.used_macos::BOOLEAN as used_macos,
  adf.total_events,
  adf.total_sessions,
  adf.total_users,
  adf.latest_event_date,
  -- Get primary device and OS using window functions
  pdi.primary_device,
  pdi.primary_os,
  -- Loan application details
  los.APPLICATION_GUID,
  los.ORIGINATION_DATE,
  los.APPLICATION_SUBMITTED_DATE,
  los.SELECTED_OFFER_DATE,
  los.application_started_date,
  los.esign_date
FROM app_device_flags adf
LEFT JOIN primary_device_info pdi ON adf.EVT_APPLICATION_ID_STR = pdi.EVT_APPLICATION_ID_STR
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT los 
  ON adf.EVT_APPLICATION_ID_STR = CAST(los.LOAN_ID AS VARCHAR)
ORDER BY adf.total_events DESC;