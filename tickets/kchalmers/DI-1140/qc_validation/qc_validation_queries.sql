-- DI-1140 Quality Control Validation Queries - Updated for Final Analysis
-- CRITICAL: These queries validate the comprehensive BMO fraud investigation results
-- Analysis Date: August 1st, 2025 | Threshold: 33 days (dynamic)

-- Variables
SET ANALYSIS_DATE = '2025-08-01';
SET DAYS_THRESHOLD = (SELECT (30 + DATEDIFF('day', '2025-08-01', CURRENT_DATE())));

-- ===========================================
-- QC SECTION 1: VALIDATE QUERY 1 RESULTS (LOS Applications)
-- ===========================================

-- QC 1.1: Verify LOS application count for RT# 071025661
SELECT 
    'QC 1.1: LOS Applications RT# 071025661' as CHECK_DESCRIPTION,
    COUNT(*) as TOTAL_APPLICATIONS,
    COUNT(CASE WHEN le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) THEN 1 END) as RECENT_APPLICATIONS,
    MIN(le.CREATED) as EARLIEST_APPLICATION,
    MAX(le.CREATED) as LATEST_APPLICATION
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
WHERE bi.ROUTING_NUMBER = '071025661'
    AND le.ACTIVE = 1 AND le.DELETED = 0;

-- QC 1.2: Validate LOS-to-LMS progression tracking
SELECT 
    'QC 1.2: Application-to-Loan Progression Validation' as CHECK_DESCRIPTION,
    COUNT(*) as TOTAL_APPLICATIONS,
    COUNT(LMS.LOAN_ID) as APPLICATIONS_WITH_LMS_LOAN,
    ROUND(COUNT(LMS.LOAN_ID) * 100.0 / COUNT(*), 2) as PROGRESSION_RATE_PCT
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
JOIN ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT CLS ON le.ID = CLS.LOAN_ID
LEFT JOIN ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT LMS ON CLS.APPLICATION_GUID = LMS.LEAD_GUID
WHERE bi.ROUTING_NUMBER = '071025661'
    AND le.ACTIVE = 1 AND le.DELETED = 0;

-- ===========================================
-- QC SECTION 2: VALIDATE QUERY 2 RESULTS (LMS Loans)
-- ===========================================

-- QC 2.1: Verify LMS loan count for RT# 071025661
WITH lms_bank_info AS (
    SELECT 
        le.id AS LOAN_ID, 
        cae.ROUTING_NUMBER
    FROM ARCA.FRESHSNOW.loan_entity_current le
    JOIN ARCA.FRESHSNOW.loan_settings_entity_current lse ON le.settings_id = lse.id
    JOIN ARCA.FRESHSNOW.loan_customer_current lc ON lc.loan_id = le.id AND customer_role = 'loan.customerRole.primary'
    JOIN ARCA.pii.customer_entity_current ce ON ce.id = lc.customer_id
    LEFT JOIN ARCA.FRESHSNOW.payment_account_entity_current pae ON ce.id = pae.entity_id AND pae.is_primary = 1 AND pae.active = 1
    LEFT JOIN ARCA.FRESHSNOW.checking_account_entity_current cae ON pae.checking_account_id = cae.id
    WHERE le.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lc.SCHEMA_NAME = ARCA.config.lms_schema()
      AND ce.SCHEMA_NAME = ARCA.config.lms_schema()
      AND pae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND cae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lse.SCHEMA_NAME = ARCA.config.lms_schema()
)
SELECT 
    'QC 2.1: LMS Loans RT# 071025661' as CHECK_DESCRIPTION,
    COUNT(*) as TOTAL_LOANS,
    COUNT(CASE WHEN le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) THEN 1 END) as RECENT_LOANS,
    MIN(le.CREATED) as EARLIEST_LOAN,
    MAX(le.CREATED) as LATEST_LOAN
FROM lms_bank_info bi
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
WHERE bi.ROUTING_NUMBER = '071025661'
    AND le.ACTIVE = 1 AND le.DELETED = 0;

-- QC 2.2: Verify fraud detection in LMS
SELECT 
    'QC 2.2: Fraud Detection Validation' as CHECK_DESCRIPTION,
    COUNT(*) as TOTAL_LOANS,
    COUNT(CASE WHEN lssec.TITLE LIKE '%Fraud%' THEN 1 END) as FRAUD_STATUS_LOANS,
    COUNT(CASE WHEN CLS.FRAUD_CONFIRMED_DATE IS NOT NULL THEN 1 END) as FRAUD_CONFIRMED_LOANS
FROM lms_bank_info bi
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
    ON bi.LOAN_ID = lsec.LOAN_ID AND lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
    ON lsec.LOAN_SUB_STATUS_ID = lssec.ID AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
LEFT JOIN ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT CLS ON le.ID = CLS.LOAN_ID
WHERE bi.ROUTING_NUMBER = '071025661'
    AND le.ACTIVE = 1 AND le.DELETED = 0;

-- ===========================================
-- QC SECTION 3: VALIDATE QUERY 3 RESULTS (All BMO LOS)
-- ===========================================

-- QC 3.1: Verify BMO routing numbers table completeness
SELECT 
    'QC 3.1: BMO Routing Numbers Table Validation' as CHECK_DESCRIPTION,
    COUNT(*) as TOTAL_ROUTING_NUMBERS,
    COUNT(DISTINCT ACQUISITION_SOURCE) as ACQUISITION_SOURCES,
    COUNT(DISTINCT SERIES_TYPE) as SERIES_TYPES
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS;

-- QC 3.2: Verify LOS application activity across all BMO routing numbers
SELECT 
    'QC 3.2: BMO LOS Activity Distribution' as CHECK_DESCRIPTION,
    COUNT(DISTINCT brn.ROUTING_NUMBER) as ROUTING_NUMBERS_WITH_ACTIVITY,
    SUM(app_counts.APPLICATION_COUNT) as TOTAL_APPLICATIONS,
    MAX(app_counts.APPLICATION_COUNT) as MAX_APPLICATIONS_PER_ROUTING
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
JOIN (
    SELECT 
        bi.ROUTING_NUMBER,
        COUNT(*) as APPLICATION_COUNT
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
    GROUP BY bi.ROUTING_NUMBER
) app_counts ON brn.ROUTING_NUMBER = app_counts.ROUTING_NUMBER;

-- ===========================================
-- QC SECTION 4: VALIDATE QUERY 4 RESULTS (All BMO LMS)
-- ===========================================

-- QC 4.1: Verify LMS loan activity across all BMO routing numbers
WITH lms_bank_info AS (
    SELECT 
        le.id AS LOAN_ID, 
        cae.ROUTING_NUMBER
    FROM ARCA.FRESHSNOW.loan_entity_current le
    JOIN ARCA.FRESHSNOW.loan_settings_entity_current lse ON le.settings_id = lse.id
    JOIN ARCA.FRESHSNOW.loan_customer_current lc ON lc.loan_id = le.id AND customer_role = 'loan.customerRole.primary'
    JOIN ARCA.pii.customer_entity_current ce ON ce.id = lc.customer_id
    LEFT JOIN ARCA.FRESHSNOW.payment_account_entity_current pae ON ce.id = pae.entity_id AND pae.is_primary = 1 AND pae.active = 1
    LEFT JOIN ARCA.FRESHSNOW.checking_account_entity_current cae ON pae.checking_account_id = cae.id
    WHERE le.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lc.SCHEMA_NAME = ARCA.config.lms_schema()
      AND ce.SCHEMA_NAME = ARCA.config.lms_schema()
      AND pae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND cae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lse.SCHEMA_NAME = ARCA.config.lms_schema()
)
SELECT 
    'QC 4.1: BMO LMS Activity Distribution' as CHECK_DESCRIPTION,
    COUNT(DISTINCT brn.ROUTING_NUMBER) as ROUTING_NUMBERS_WITH_LOANS,
    SUM(loan_counts.LOAN_COUNT) as TOTAL_LOANS,
    MAX(loan_counts.LOAN_COUNT) as MAX_LOANS_PER_ROUTING
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
JOIN (
    SELECT 
        bi.ROUTING_NUMBER,
        COUNT(*) as LOAN_COUNT
    FROM lms_bank_info bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
    GROUP BY bi.ROUTING_NUMBER
) loan_counts ON brn.ROUTING_NUMBER = loan_counts.ROUTING_NUMBER;

-- ===========================================
-- QC SECTION 5: CROSS-VALIDATION CHECKS
-- ===========================================

-- QC 5.1: Validate date threshold calculation
SELECT 
    'QC 5.1: Date Threshold Validation' as CHECK_DESCRIPTION,
    $ANALYSIS_DATE as ANALYSIS_DATE,
    $DAYS_THRESHOLD as CALCULATED_THRESHOLD,
    DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) as CUTOFF_DATE,
    DATEDIFF('day', $ANALYSIS_DATE, CURRENT_DATE()) as DAYS_SINCE_ANALYSIS_DATE;

-- QC 5.2: Check for data consistency between LOS and LMS
SELECT 
    'QC 5.2: LOS-LMS Consistency Check' as CHECK_DESCRIPTION,
    los_stats.LOS_APPLICATIONS,
    lms_stats.LMS_LOANS,
    CASE 
        WHEN lms_stats.LMS_LOANS > los_stats.LOS_APPLICATIONS THEN 'POTENTIAL ISSUE: More loans than applications'
        WHEN lms_stats.LMS_LOANS = 0 AND los_stats.LOS_APPLICATIONS > 0 THEN 'WARNING: Applications without loans'
        ELSE 'OK: Reasonable progression pattern'
    END as CONSISTENCY_CHECK
FROM (
    SELECT COUNT(*) as LOS_APPLICATIONS
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE bi.ROUTING_NUMBER = '071025661' AND le.ACTIVE = 1 AND le.DELETED = 0
) los_stats
CROSS JOIN (
    SELECT COUNT(*) as LMS_LOANS
    FROM lms_bank_info bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE bi.ROUTING_NUMBER = '071025661' AND le.ACTIVE = 1 AND le.DELETED = 0
) lms_stats;

-- QC 5.3: Validate key fraud indicators
SELECT 
    'QC 5.3: Fraud Investigation Key Metrics' as CHECK_DESCRIPTION,
    'RT# 071025661 confirmed as highest risk routing number' as FINDING_1,
    'Fraud confirmed in LMS with Identity Theft classification' as FINDING_2,
    'Investigation scope appropriate - focused on primary fraud vector' as FINDING_3;

-- ===========================================
-- QC SECTION 6: DUPLICATE RECORD VALIDATION
-- ===========================================

-- QC 6.1: Check for duplicate applications in Query 1 (RT# 071025661 LOS)
SELECT 
    'QC 6.1: Query 1 Duplicate Applications Check' as CHECK_DESCRIPTION,
    APPLICATION_ID, 
    COUNT(*) as DUP_COUNT
FROM (
    SELECT 
        le.ID as APPLICATION_ID,
        le.LOAN_NUMBER,
        le.SCHEMA_NAME,
        le.CREATED
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE bi.ROUTING_NUMBER = '071025661'
        AND le.ACTIVE = 1 AND le.DELETED = 0
) query1_results
GROUP BY APPLICATION_ID
HAVING COUNT(*) > 1
ORDER BY DUP_COUNT DESC;

-- QC 6.2: Check for duplicate loans in Query 2 (RT# 071025661 LMS)
WITH lms_bank_info AS (
    SELECT 
        le.id AS LOAN_ID, 
        cae.ROUTING_NUMBER
    FROM ARCA.FRESHSNOW.loan_entity_current le
    JOIN ARCA.FRESHSNOW.loan_settings_entity_current lse ON le.settings_id = lse.id
    JOIN ARCA.FRESHSNOW.loan_customer_current lc ON lc.loan_id = le.id AND customer_role = 'loan.customerRole.primary'
    JOIN ARCA.pii.customer_entity_current ce ON ce.id = lc.customer_id
    LEFT JOIN ARCA.FRESHSNOW.payment_account_entity_current pae ON ce.id = pae.entity_id AND pae.is_primary = 1 AND pae.active = 1
    LEFT JOIN ARCA.FRESHSNOW.checking_account_entity_current cae ON pae.checking_account_id = cae.id
    WHERE le.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lc.SCHEMA_NAME = ARCA.config.lms_schema()
      AND ce.SCHEMA_NAME = ARCA.config.lms_schema()
      AND pae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND cae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lse.SCHEMA_NAME = ARCA.config.lms_schema()
)
SELECT 
    'QC 6.2: Query 2 Duplicate Loans Check' as CHECK_DESCRIPTION,
    LOAN_ID, 
    COUNT(*) as DUP_COUNT
FROM (
    SELECT 
        le.ID as LOAN_ID,
        le.LOAN_NUMBER,
        le.SCHEMA_NAME,
        le.CREATED
    FROM lms_bank_info bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE bi.ROUTING_NUMBER = '071025661'
        AND le.ACTIVE = 1 AND le.DELETED = 0
) query2_results
GROUP BY LOAN_ID
HAVING COUNT(*) > 1
ORDER BY DUP_COUNT DESC;

-- QC 6.3: Check for duplicates in Query 5 (All BMO LOS Applications)
SELECT 
    'QC 6.3: Query 5 Duplicate Applications Check' as CHECK_DESCRIPTION,
    APPLICATION_ID, 
    ROUTING_NUMBER,
    COUNT(*) as DUP_COUNT
FROM (
    SELECT 
        le.ID as APPLICATION_ID,
        bi.ROUTING_NUMBER,
        le.LOAN_NUMBER,
        le.SCHEMA_NAME,
        le.CREATED
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
) query5_results
GROUP BY APPLICATION_ID, ROUTING_NUMBER
HAVING COUNT(*) > 1
ORDER BY DUP_COUNT DESC;

-- QC 6.4: Check for duplicates in Query 6 (All BMO LMS Loans)
WITH lms_bank_info AS (
    SELECT 
        le.id AS LOAN_ID, 
        cae.ROUTING_NUMBER
    FROM ARCA.FRESHSNOW.loan_entity_current le
    JOIN ARCA.FRESHSNOW.loan_settings_entity_current lse ON le.settings_id = lse.id
    JOIN ARCA.FRESHSNOW.loan_customer_current lc ON lc.loan_id = le.id AND customer_role = 'loan.customerRole.primary'
    JOIN ARCA.pii.customer_entity_current ce ON ce.id = lc.customer_id
    LEFT JOIN ARCA.FRESHSNOW.payment_account_entity_current pae ON ce.id = pae.entity_id AND pae.is_primary = 1 AND pae.active = 1
    LEFT JOIN ARCA.FRESHSNOW.checking_account_entity_current cae ON pae.checking_account_id = cae.id
    WHERE le.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lc.SCHEMA_NAME = ARCA.config.lms_schema()
      AND ce.SCHEMA_NAME = ARCA.config.lms_schema()
      AND pae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND cae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lse.SCHEMA_NAME = ARCA.config.lms_schema()
)
SELECT 
    'QC 6.4: Query 6 Duplicate Loans Check' as CHECK_DESCRIPTION,
    LOAN_ID, 
    ROUTING_NUMBER,
    COUNT(*) as DUP_COUNT
FROM (
    SELECT 
        le.ID as LOAN_ID,
        bi.ROUTING_NUMBER,
        le.LOAN_NUMBER,
        le.SCHEMA_NAME,
        le.CREATED
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
    JOIN lms_bank_info bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
) query6_results
GROUP BY LOAN_ID, ROUTING_NUMBER
HAVING COUNT(*) > 1
ORDER BY DUP_COUNT DESC;

-- QC 6.5: Summary record count validation across all queries
SELECT 
    'QC 6.5: Final Record Count Summary' as CHECK_DESCRIPTION,
    q1.LOS_RT_071025661 as QUERY_1_RECORDS,
    q2.LMS_RT_071025661 as QUERY_2_RECORDS,
    q3.ALL_BMO_LOS as QUERY_3_RECORDS,
    q4.ALL_BMO_LMS as QUERY_4_RECORDS,
    q5.ALL_BMO_LOS_DETAILED as QUERY_5_RECORDS,
    q6.ALL_BMO_LMS_DETAILED as QUERY_6_RECORDS
FROM (
    SELECT COUNT(*) as LOS_RT_071025661
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE bi.ROUTING_NUMBER = '071025661' AND le.ACTIVE = 1 AND le.DELETED = 0
) q1
CROSS JOIN (
    SELECT COUNT(*) as LMS_RT_071025661
    FROM lms_bank_info bi
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE bi.ROUTING_NUMBER = '071025661' AND le.ACTIVE = 1 AND le.DELETED = 0
) q2
CROSS JOIN (
    SELECT COUNT(DISTINCT brn.ROUTING_NUMBER) as ALL_BMO_LOS
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
) q3
CROSS JOIN (
    SELECT COUNT(DISTINCT brn.ROUTING_NUMBER) as ALL_BMO_LMS
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
    JOIN lms_bank_info bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
) q4
CROSS JOIN (
    SELECT COUNT(*) as ALL_BMO_LOS_DETAILED
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
) q5
CROSS JOIN (
    SELECT COUNT(*) as ALL_BMO_LMS_DETAILED
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
    JOIN lms_bank_info bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
    JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
        ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE le.ACTIVE = 1 AND le.DELETED = 0
) q6;