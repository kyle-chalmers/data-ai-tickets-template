/*
DI-1179: Optimized Fraud Analytics View - ANALYTICS Layer Only
High-performance fraud detection using BRIDGE and ANALYTICS layer data sources only
FRAUD DETECTION ONLY (no deceased/SCRA data)
Data Sources: BUSINESS_INTELLIGENCE.ANALYTICS and BUSINESS_INTELLIGENCE.BRIDGE tables only
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Deploy optimized fraud view to BUSINESS_INTELLIGENCE_DEV
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS(
    LOAN_ID,
    LEAD_GUID,
    LEGACY_LOAN_ID,
    IS_FRAUD_ANY,
    IS_FRAUD_PORTFOLIO,
    FRAUD_PORTFOLIO_NAMES,
    IS_FRAUD_INVESTIGATION_LMS,
    FRAUD_STATUS_LMS,
    IS_FRAUD_ACTION_RESULT,
    IS_FRAUD_APPLICATION_TAG,
    IS_FRAUD_STATUS_TEXT,
    FRAUD_DETECTION_METHODS_COUNT,
    FRAUD_SOURCES_LIST,
    LAST_UPDATED
) COPY GRANTS AS 

WITH cte_fraud_loans AS (
    -- Optimized: Collect fraud loans from each source individually, then UNION
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        'Portfolio' as fraud_source,
        lpsp.PORTFOLIO_NAME as fraud_detail
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
        ON TRY_CAST(REPLACE(vl.loan_id, 'LAI-', '') AS INTEGER) = lpsp.loan_id
    WHERE lpsp.PORTFOLIO_CATEGORY = 'Fraud'
    
    UNION ALL
    
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        'LMS_Investigation' as fraud_source,
        cls.FRAUD_INVESTIGATION_RESULTS as fraud_detail
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
        ON LOWER(vl.lead_guid) = LOWER(cls.LEAD_GUID)
    WHERE cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL
    
    UNION ALL
    
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        'Action_Result' as fraud_source,
        'Fraud Notes' as fraud_detail
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APP_ACTION_AND_RESULTS aar 
        ON TRY_CAST(REPLACE(vl.application_id, 'APP-', '') AS INTEGER) = aar.APP_ID
    WHERE UPPER(aar.NOTE) LIKE '%FRAUD%'
    
    UNION ALL
    
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        'Application_Tag' as fraud_source,
        'Confirmed Fraud' as fraud_detail
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION app
        ON LOWER(vl.lead_guid) = LOWER(app.payoff_uid)
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_TAGS a_tags 
        ON app.hk_h_appl = a_tags.hk_h_appl
    WHERE a_tags.application_tag = 'Confirmed Fraud'
    AND a_tags.softdelete = 'False'
    
    UNION ALL
    
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        'Status_Text' as fraud_source,
        lssec.TITLE as fraud_detail
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
        ON TRY_CAST(REPLACE(vl.loan_id, 'LAI-', '') AS INTEGER) = lsec.LOAN_ID 
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
        ON lsec.LOAN_SUB_STATUS_ID = lssec.id 
    WHERE lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    AND UPPER(lssec.TITLE) LIKE '%FRAUD%'
)

-- Aggregate by loan for final output
SELECT 
    loan_id as LOAN_ID,
    lead_guid as LEAD_GUID,
    MAX(legacy_loan_id) as LEGACY_LOAN_ID,
    
    -- Master fraud indicator
    TRUE as IS_FRAUD_ANY,
    
    -- Source-specific indicators
    MAX(CASE WHEN fraud_source = 'Portfolio' THEN TRUE ELSE FALSE END) as IS_FRAUD_PORTFOLIO,
    LISTAGG(DISTINCT CASE WHEN fraud_source = 'Portfolio' THEN fraud_detail END, ', ') as FRAUD_PORTFOLIO_NAMES,
    
    MAX(CASE WHEN fraud_source = 'LMS_Investigation' THEN TRUE ELSE FALSE END) as IS_FRAUD_INVESTIGATION_LMS,
    MAX(CASE WHEN fraud_source = 'LMS_Investigation' THEN fraud_detail END) as FRAUD_STATUS_LMS,
    
    MAX(CASE WHEN fraud_source = 'Action_Result' THEN TRUE ELSE FALSE END) as IS_FRAUD_ACTION_RESULT,
    MAX(CASE WHEN fraud_source = 'Application_Tag' THEN TRUE ELSE FALSE END) as IS_FRAUD_APPLICATION_TAG,
    MAX(CASE WHEN fraud_source = 'Status_Text' THEN TRUE ELSE FALSE END) as IS_FRAUD_STATUS_TEXT,
    
    -- Aggregated indicators
    COUNT(DISTINCT fraud_source) as FRAUD_DETECTION_METHODS_COUNT,
    LISTAGG(DISTINCT fraud_source, ', ') as FRAUD_SOURCES_LIST,
    
    -- Metadata
    CURRENT_TIMESTAMP() as LAST_UPDATED

FROM cte_fraud_loans
GROUP BY loan_id, lead_guid
ORDER BY loan_id;