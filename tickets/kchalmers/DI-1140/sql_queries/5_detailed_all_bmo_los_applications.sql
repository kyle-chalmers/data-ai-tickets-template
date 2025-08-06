-- DI-1140 BMO Fraud Investigation - Query 5 DETAILED
-- Individual Applications Analysis - All BMO Routing Numbers
-- This query returns individual application records with EXACT SAME SCHEMA as Query 1
-- Analysis Date: August 1st, 2025 | Dynamic Threshold: 30 + days since analysis

-- Variables
SET ANALYSIS_DATE = '2025-08-01';  -- Friday when request was submitted
SET DAYS_THRESHOLD = (SELECT (30 + DATEDIFF('day', '2025-08-01', CURRENT_DATE())));

-- ===========================================
-- DETAILED BMO LOS APPLICATIONS INVESTIGATION
-- Returns individual application records across all BMO routing numbers
-- EXACT SAME OUTPUT SCHEMA AS QUERY 1
-- ===========================================

with fraud_portfolios as (select listagg(PORTFOLIO_NAME,',') as CURRENT_fraud_portfolios, APPLICATION_ID from BUSINESS_INTELLIGENCE.ANALYTICS.VW_APP_PORTFOLIOS_AND_SUB_PORTFOLIOS
where PORTFOLIO_CATEGORY = 'Fraud' group by all)

SELECT 
    -- === APPLICATION IDENTIFICATION === (EXACT MATCH TO QUERY 1)
    bi.LOAN_ID as APPLICATION_ID,
    -- === BANKING DETAILS === (EXACT MATCH TO QUERY 1)
    bi.ROUTING_NUMBER,
    bi.ACCOUNT_TYPE,
    bi.ACCOUNT_NUMBER,
    -- === DATE ANALYSIS === (EXACT MATCH TO QUERY 1)
    le.CREATED as APPLICATION_CREATED_DATE,
    DATEDIFF('day', le.CREATED, $ANALYSIS_DATE) as DAYS_SINCE_CREATION,
    le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, $ANALYSIS_DATE) as LAST_30_DAYS_IND,
    -- === APPLICATION STATUS === (EXACT MATCH TO QUERY 1)
    le.ACTIVE,
    le.DELETED,
    le.ARCHIVED,
    lssec.TITLE as APP_STATUS,
    vlcc.CUSTOMER_ID,
    CLS.APPLICATION_GUID       as LEAD_GUID,
       CLS.FIRST_NAME             as FIRST_NAME,
       CLS.LAST_NAME              as LAST_NAME,
       CLS.FRAUD_STATUS,
       CLS.FRAUD_REASON,
       vapasp.current_fraud_portfolios,
    -- === LMS PROGRESSION TRACKING === (EXACT MATCH TO QUERY 1)
    LMS.LOAN_ID as LMS_LOAN_ID

FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_BANK_INFO bi
    ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
    ON bi.LOAN_ID = lsec.LOAN_ID and lsec.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
    ON lsec.LOAN_SUB_STATUS_ID = lssec.id and lssec.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT vlcc
    on bi.LOAN_ID = vlcc.LOAN_ID and vlcc.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
join ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as CLS
    on LE.ID = CLS.LOAN_ID
left join fraud_portfolios vapasp
    on bi.LOAN_ID = vapasp.APPLICATION_ID
-- Join to LMS to check if application became a loan
LEFT JOIN ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT LMS
    ON CLS.APPLICATION_GUID = LMS.LEAD_GUID

WHERE 1=1
    -- Exclude primary routing number already analyzed in queries 1&2
    AND brn.ROUTING_NUMBER != '071025661'
    -- Active applications only
    AND le.ACTIVE = 1
    AND le.DELETED = 0
    -- LOS system only (applications)
    AND le.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()

ORDER BY 
    bi.ROUTING_NUMBER,
    le.CREATED DESC;