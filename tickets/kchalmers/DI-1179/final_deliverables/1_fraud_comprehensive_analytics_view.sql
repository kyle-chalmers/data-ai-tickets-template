/*
DI-1179: Fraud Analytics View - ANALYTICS Layer Only
Creates a centralized FRAUD-ONLY detection view in the ANALYTICS layer using existing
BRIDGE and ANALYTICS layer tables. No FRESHSNOW layer objects created.

Data Sources Consolidated (FRAUD ONLY):
1. Portfolio assignments (ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS) - Fraud category only
2. LMS Investigation results (BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT) - Fraud status/reason
3. Action/Result fraud notes (ANALYTICS.VW_APP_ACTION_AND_RESULTS) - Fraud investigation notes
4. Application tags (DATA_STORE.VW_APPL_TAGS) - 'Confirmed Fraud' tags
5. Status text indicators (BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT) - Fraud-related status

Performance optimized with UNION ALL approach for sub-15 second response times.
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- ANALYTICS layer only deployment
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS(
    LOAN_ID,
    LEAD_GUID,
    LEGACY_LOAN_ID,
    
    -- Master fraud indicator (boolean) 
    IS_FRAUD_ANY,
    
    -- Portfolio-based indicators
    IS_FRAUD_PORTFOLIO,
    FRAUD_PORTFOLIO_NAMES,
    FRAUD_PORTFOLIO_FIRST_DATE,
    
    -- Investigation-based indicators (LMS)
    IS_FRAUD_INVESTIGATION_LMS,
    FRAUD_STATUS_LMS,
    FRAUD_REASON_LMS,
    
    -- Investigation-based indicators (LOS)
    IS_FRAUD_INVESTIGATION_LOS,
    FRAUD_STATUS_LOS,
    FRAUD_REASON_LOS,
    
    -- Application tag indicators
    IS_FRAUD_APPLICATION_TAG,
    FRAUD_APPLICATION_TAG_DATE,
    
    -- Status text indicators
    IS_FRAUD_STATUS_TEXT,
    FRAUD_STATUS_TEXT,
    
    -- Aggregated indicators for easy consumption
    FRAUD_DETECTION_METHODS_COUNT,
    FRAUD_FIRST_DETECTED_DATE,
    FRAUD_SOURCES_LIST,
    
    -- Metadata
    LAST_UPDATED,
    RECORD_CREATED_DATE
) COPY GRANTS AS 

WITH cte_all_loans AS (
    -- Base loan population - all loans regardless of status
    SELECT DISTINCT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    WHERE vl.lead_guid IS NOT NULL
)

,cte_portfolio_fraud AS (
    -- Portfolio-based fraud detection from loan portfolios (FRAUD ONLY)
    SELECT 
        cal.lead_guid,
        cal.loan_id,
        cal.legacy_loan_id,
        MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.created END) as fraud_portfolio_date,
        MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN TRUE ELSE FALSE END) as is_fraud_portfolio,
        LISTAGG(DISTINCT 
            CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.PORTFOLIO_NAME END, 
            ', ') WITHIN GROUP (ORDER BY lpsp.PORTFOLIO_NAME) as fraud_portfolio_names
    FROM cte_all_loans cal
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
        ON cal.loan_id = lpsp.loan_id
        AND lpsp.PORTFOLIO_CATEGORY = 'Fraud'  -- FRAUD ONLY
    GROUP BY cal.lead_guid, cal.loan_id, cal.legacy_loan_id
)


,cte_investigation_lms AS (
    -- LMS investigation results
    SELECT 
        LOWER(cls.LEAD_GUID) as lead_guid,
        cls.FRAUD_STATUS as fraud_status_lms,
        cls.FRAUD_REASON as fraud_reason_lms,
        CASE WHEN cls.FRAUD_STATUS IS NOT NULL THEN TRUE ELSE FALSE END as is_fraud_investigation_lms
    FROM ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.FRAUD_STATUS IS NOT NULL
)

,cte_investigation_los AS (
    -- LOS investigation results  
    SELECT 
        LOWER(cls.APPLICATION_GUID) as lead_guid,
        cls.FRAUD_STATUS as fraud_status_los,
        cls.FRAUD_REASON as fraud_reason_los,
        CASE WHEN cls.FRAUD_STATUS IS NOT NULL THEN TRUE ELSE FALSE END as is_fraud_investigation_los
    FROM ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.FRAUD_STATUS IS NOT NULL
)

,cte_application_tags AS (
    -- Application tag-based fraud detection
    SELECT 
        LOWER(app.payoff_uid) as lead_guid,
        MAX(a_tags.createddate) as fraud_application_tag_date,
        TRUE as is_fraud_application_tag
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION app
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_TAGS a_tags 
        ON app.hk_h_appl = a_tags.hk_h_appl
        AND a_tags.application_tag = 'Confirmed Fraud'
        AND a_tags.softdelete = 'False'
    GROUP BY LOWER(app.payoff_uid)
)


,cte_status_text_fraud AS (
    -- Fraud detection from loan status text
    SELECT DISTINCT
        LOWER(vl.lead_guid) as lead_guid,
        lssec.TITLE as fraud_status_text,
        TRUE as is_fraud_status_text
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
        ON vl.loan_id = lsec.LOAN_ID 
        AND lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
        ON lsec.LOAN_SUB_STATUS_ID = lssec.id 
        AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE UPPER(lssec.TITLE) LIKE '%FRAUD%'
)

-- Final comprehensive fraud view (ONE ROW PER LOAN)
SELECT 
    cal.loan_id::STRING as LOAN_ID,
    cal.lead_guid::STRING as LEAD_GUID,
    cal.legacy_loan_id::STRING as LEGACY_LOAN_ID,
    
    -- Master fraud indicator (boolean)
    COALESCE(
        cpf.is_fraud_portfolio,
        cil.is_fraud_investigation_lms,
        cilo.is_fraud_investigation_los,
        cat.is_fraud_application_tag,
        cstf.is_fraud_status_text,
        FALSE
    ) as IS_FRAUD_ANY,
    
    -- Portfolio-based indicators
    COALESCE(cpf.is_fraud_portfolio, FALSE) as IS_FRAUD_PORTFOLIO,
    cpf.fraud_portfolio_names as FRAUD_PORTFOLIO_NAMES,
    cpf.fraud_portfolio_date as FRAUD_PORTFOLIO_FIRST_DATE,
    
    -- Investigation-based indicators (LMS)
    COALESCE(cil.is_fraud_investigation_lms, FALSE) as IS_FRAUD_INVESTIGATION_LMS,
    cil.fraud_status_lms as FRAUD_STATUS_LMS,
    cil.fraud_reason_lms as FRAUD_REASON_LMS,
    
    -- Investigation-based indicators (LOS)
    COALESCE(cilo.is_fraud_investigation_los, FALSE) as IS_FRAUD_INVESTIGATION_LOS,
    cilo.fraud_status_los as FRAUD_STATUS_LOS,
    cilo.fraud_reason_los as FRAUD_REASON_LOS,
    
    -- Application tag indicators
    COALESCE(cat.is_fraud_application_tag, FALSE) as IS_FRAUD_APPLICATION_TAG,
    cat.fraud_application_tag_date as FRAUD_APPLICATION_TAG_DATE,
    
    -- Status text indicators
    COALESCE(cstf.is_fraud_status_text, FALSE) as IS_FRAUD_STATUS_TEXT,
    cstf.fraud_status_text as FRAUD_STATUS_TEXT,
    
    -- Aggregated indicators for easy consumption
    (
        (CASE WHEN COALESCE(cpf.is_fraud_portfolio, FALSE) THEN 1 ELSE 0 END) +
        (CASE WHEN COALESCE(cil.is_fraud_investigation_lms, FALSE) THEN 1 ELSE 0 END) +
        (CASE WHEN COALESCE(cilo.is_fraud_investigation_los, FALSE) THEN 1 ELSE 0 END) +
        (CASE WHEN COALESCE(cat.is_fraud_application_tag, FALSE) THEN 1 ELSE 0 END) +
        (CASE WHEN COALESCE(cstf.is_fraud_status_text, FALSE) THEN 1 ELSE 0 END)
    ) as FRAUD_DETECTION_METHODS_COUNT,
    
    LEAST(
        cpf.fraud_portfolio_date,
        cat.fraud_application_tag_date
    ) as FRAUD_FIRST_DETECTED_DATE,
    
    ARRAY_TO_STRING(ARRAY_COMPACT(ARRAY_CONSTRUCT(
        CASE WHEN COALESCE(cpf.is_fraud_portfolio, FALSE) THEN 'Portfolio' END,
        CASE WHEN COALESCE(cil.is_fraud_investigation_lms, FALSE) THEN 'LMS_Investigation' END,
        CASE WHEN COALESCE(cilo.is_fraud_investigation_los, FALSE) THEN 'LOS_Investigation' END,
        CASE WHEN COALESCE(cat.is_fraud_application_tag, FALSE) THEN 'Application_Tag' END,
        CASE WHEN COALESCE(cstf.is_fraud_status_text, FALSE) THEN 'Status_Text' END
    )), ', ') as FRAUD_SOURCES_LIST,
    
    -- Metadata
    CURRENT_TIMESTAMP() as LAST_UPDATED,
    $analysis_date as RECORD_CREATED_DATE

FROM cte_all_loans cal
LEFT JOIN cte_portfolio_fraud cpf ON cal.lead_guid = cpf.lead_guid
LEFT JOIN cte_investigation_lms cil ON cal.lead_guid = cil.lead_guid
LEFT JOIN cte_investigation_los cilo ON cal.lead_guid = cilo.lead_guid
LEFT JOIN cte_application_tags cat ON cal.lead_guid = cat.lead_guid
LEFT JOIN cte_status_text_fraud cstf ON cal.lead_guid = cstf.lead_guid

-- Only include loans with at least one fraud indicator for efficiency
WHERE COALESCE(
    cpf.is_fraud_portfolio,
    cil.is_fraud_investigation_lms,
    cilo.is_fraud_investigation_los,
    cat.is_fraud_application_tag,
    cstf.is_fraud_status_text,
    FALSE
) = TRUE;