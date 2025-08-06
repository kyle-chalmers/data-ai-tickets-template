-- DI-1140: BMO All Routing Numbers Investigation - LMS Originated Loans Analysis
-- Comprehensive analysis of all BMO routing numbers for originated loans

-- Variables for easy modification  
SET ANALYSIS_DATE = '2025-08-01';  -- Friday when request was submitted
SET DAYS_THRESHOLD = (SELECT (30 + DATEDIFF('day', $ANALYSIS_DATE, CURRENT_DATE())));  -- Dynamic: 30 days + difference between analysis date and today

-- LMS ORIGINATED LOANS QUERY FOR ALL BMO ROUTING NUMBERS
WITH bmo_routing_numbers AS (
    SELECT 
        ROUTING_NUMBER, 
        BANK_NAME, 
        ACQUISITION_SOURCE,
        SERIES_TYPE,
        PRIMARY_USE,
        NOTES
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS
    WHERE ROUTING_NUMBER != '071025661'  -- Exclude primary routing number already analyzed in queries 1&2
),
lms_bank_info AS (
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
),
fraud_portfolios AS (
    SELECT 
        LOAN_ID,
        LISTAGG(PORTFOLIO_NAME, ',') as CURRENT_loan_fraud_portfolios
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
    WHERE PORTFOLIO_CATEGORY = 'Fraud' 
    GROUP BY LOAN_ID
)
SELECT 
    -- === BMO ROUTING INFO ===
    brn.ROUTING_NUMBER,
    brn.BANK_NAME,
    brn.ACQUISITION_SOURCE,
    brn.SERIES_TYPE,
    brn.PRIMARY_USE,
    
    -- === LOAN SUMMARY ===
    COUNT(*) as TOTAL_LOANS,
    COUNT(CASE WHEN le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) THEN 1 END) as RECENT_LOANS,
    
    -- === FRAUD ANALYSIS ===
    COUNT(CASE WHEN lssec.TITLE LIKE '%Fraud%' THEN 1 END) as FRAUD_STATUS_LOANS,
    COUNT(CASE WHEN CLS.FRAUD_CONFIRMED_DATE IS NOT NULL THEN 1 END) as FRAUD_CONFIRMED_LOANS,
    COUNT(CASE WHEN fp.CURRENT_loan_fraud_portfolios IS NOT NULL THEN 1 END) as FRAUD_PORTFOLIO_LOANS,
    
    -- === STATUS BREAKDOWN ===
    COUNT(CASE WHEN lssec.TITLE = 'Open - Repaying' THEN 1 END) as ACTIVE_REPAYING,
    COUNT(CASE WHEN lssec.TITLE = 'Closed - Confirmed Fraud' THEN 1 END) as CONFIRMED_FRAUD_CLOSED,
    COUNT(CASE WHEN lssec.TITLE = 'Closed - Charged-Off Collectible' THEN 1 END) as CHARGED_OFF,
    COUNT(CASE WHEN lssec.TITLE = 'Paid Off - Paid In Full' THEN 1 END) as PAID_IN_FULL,
    
    -- === DATE RANGES ===
    MIN(le.CREATED) as EARLIEST_LOAN,
    MAX(le.CREATED) as LATEST_LOAN,
    
    -- === CUSTOMER PATTERN ANALYSIS ===
    COUNT(DISTINCT vlcc.CUSTOMER_ID) as UNIQUE_CUSTOMERS,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT vlcc.CUSTOMER_ID), 2) as AVG_LOANS_PER_CUSTOMER,
    
    -- === RISK ASSESSMENT ===
    CASE 
        WHEN COUNT(CASE WHEN le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) THEN 1 END) >= 10 THEN 'HIGH'
        WHEN COUNT(CASE WHEN le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) THEN 1 END) >= 5 THEN 'MEDIUM' 
        WHEN COUNT(CASE WHEN le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) THEN 1 END) > 0 THEN 'LOW'
        ELSE 'NONE'
    END as RECENT_ACTIVITY_RISK,
    
    -- === FRAUD RISK INDICATOR ===
    CASE 
        WHEN COUNT(CASE WHEN lssec.TITLE LIKE '%Fraud%' THEN 1 END) > 0 THEN 'FRAUD_DETECTED'
        WHEN COUNT(CASE WHEN CLS.FRAUD_CONFIRMED_DATE IS NOT NULL THEN 1 END) > 0 THEN 'FRAUD_CONFIRMED'
        ELSE 'NO_FRAUD_INDICATORS'
    END as FRAUD_RISK_STATUS

FROM bmo_routing_numbers brn
JOIN lms_bank_info bi ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER  
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
    ON bi.LOAN_ID = lsec.LOAN_ID AND lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
    ON lsec.LOAN_SUB_STATUS_ID = lssec.ID AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT vlcc
    ON bi.LOAN_ID = vlcc.LOAN_ID AND vlcc.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
LEFT JOIN ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT CLS ON le.ID = CLS.LOAN_ID
LEFT JOIN fraud_portfolios fp ON bi.LOAN_ID = fp.LOAN_ID

WHERE le.ACTIVE = 1 AND le.DELETED = 0

GROUP BY 
    brn.ROUTING_NUMBER, 
    brn.BANK_NAME, 
    brn.ACQUISITION_SOURCE, 
    brn.SERIES_TYPE, 
    brn.PRIMARY_USE

HAVING COUNT(*) > 0  -- Only show routing numbers with loan activity

ORDER BY 
    RECENT_LOANS DESC, 
    TOTAL_LOANS DESC,
    FRAUD_STATUS_LOANS DESC;