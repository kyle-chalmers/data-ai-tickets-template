-- DI-1146: Originations Breakdown by Device Type
-- Compare mobile vs desktop origination rates to validate conversion hypothesis

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
    MAX(CASE WHEN PAGE_DEVICE = 'Tablet' THEN 1 ELSE 0 END) as used_tablet,
    SUM(event_count) as total_events,
    MAX(latest_event) as latest_event_date
  FROM device_summary
  GROUP BY EVT_APPLICATION_ID_STR
),
primary_device_info AS (
  SELECT 
    EVT_APPLICATION_ID_STR,
    FIRST_VALUE(PAGE_DEVICE) OVER (PARTITION BY EVT_APPLICATION_ID_STR ORDER BY event_count DESC) as primary_device
  FROM device_summary
  QUALIFY ROW_NUMBER() OVER (PARTITION BY EVT_APPLICATION_ID_STR ORDER BY event_count DESC) = 1
),
with_loan_data AS (
  SELECT 
    adf.*,
    pdi.primary_device,
    CASE 
      WHEN adf.used_mobile = 1 AND adf.used_desktop = 0 THEN 'Mobile-Only'
      WHEN adf.used_desktop = 1 AND adf.used_mobile = 0 THEN 'Desktop-Only'  
      WHEN adf.used_mobile = 1 AND adf.used_desktop = 1 THEN 'Cross-Device'
      WHEN adf.used_tablet = 1 THEN 'Tablet'
      ELSE 'Other'
    END as device_category,
    los.APPLICATION_GUID,
    los.ORIGINATION_DATE,
    los.APPLICATION_SUBMITTED_DATE,
    los.APPLICATION_STARTED_DATE,
    los.ESIGN_DATE,
    los.SELECTED_OFFER_DATE,
    CASE WHEN los.APPLICATION_GUID IS NOT NULL THEN 1 ELSE 0 END as has_loan_data,
    CASE WHEN los.ORIGINATION_DATE IS NOT NULL THEN 1 ELSE 0 END as has_origination
  FROM app_device_flags adf
  LEFT JOIN primary_device_info pdi ON adf.EVT_APPLICATION_ID_STR = pdi.EVT_APPLICATION_ID_STR
  LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT los 
    ON adf.EVT_APPLICATION_ID_STR = CAST(los.LOAN_ID AS VARCHAR)
)
SELECT 
  device_category,
  COUNT(*) as total_applications,
  COUNT(CASE WHEN has_loan_data = 1 THEN 1 END) as matched_applications,
  ROUND(COUNT(CASE WHEN has_loan_data = 1 THEN 1 END) * 100.0 / COUNT(*), 2) as match_rate_pct,
  
  -- Application funnel metrics
  COUNT(CASE WHEN has_loan_data = 1 AND APPLICATION_STARTED_DATE IS NOT NULL THEN 1 END) as started_applications,
  COUNT(CASE WHEN has_loan_data = 1 AND APPLICATION_SUBMITTED_DATE IS NOT NULL THEN 1 END) as submitted_applications,
  COUNT(CASE WHEN has_loan_data = 1 AND SELECTED_OFFER_DATE IS NOT NULL THEN 1 END) as offer_selections,
  COUNT(CASE WHEN has_loan_data = 1 AND ESIGN_DATE IS NOT NULL THEN 1 END) as esignatures,
  COUNT(CASE WHEN has_loan_data = 1 AND ORIGINATION_DATE IS NOT NULL THEN 1 END) as originations,
  
  -- Conversion rates (based on matched applications)
  ROUND(COUNT(CASE WHEN has_loan_data = 1 AND APPLICATION_SUBMITTED_DATE IS NOT NULL THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN has_loan_data = 1 THEN 1 END), 0), 2) as submission_rate_pct,
  ROUND(COUNT(CASE WHEN has_loan_data = 1 AND SELECTED_OFFER_DATE IS NOT NULL THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN has_loan_data = 1 THEN 1 END), 0), 2) as offer_selection_rate_pct,
  ROUND(COUNT(CASE WHEN has_loan_data = 1 AND ESIGN_DATE IS NOT NULL THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN has_loan_data = 1 THEN 1 END), 0), 2) as esign_rate_pct,
  ROUND(COUNT(CASE WHEN has_loan_data = 1 AND ORIGINATION_DATE IS NOT NULL THEN 1 END) * 100.0 / NULLIF(COUNT(CASE WHEN has_loan_data = 1 THEN 1 END), 0), 2) as origination_rate_pct,
  
  -- Primary device distribution for cross-device users
  COUNT(CASE WHEN device_category = 'Cross-Device' AND primary_device = 'Mobile' THEN 1 END) as cross_device_mobile_primary,
  COUNT(CASE WHEN device_category = 'Cross-Device' AND primary_device = 'Desktop' THEN 1 END) as cross_device_desktop_primary

FROM with_loan_data
WHERE has_loan_data = 1  -- Focus on applications with loan data
GROUP BY device_category
ORDER BY total_applications DESC;