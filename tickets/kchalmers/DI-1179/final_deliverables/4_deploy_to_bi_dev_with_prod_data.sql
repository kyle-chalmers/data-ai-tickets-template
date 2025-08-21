/*
DI-1179: Deploy Fraud Analytics to BUSINESS_INTELLIGENCE_DEV with Production Data
Creates fraud view in BUSINESS_INTELLIGENCE_DEV database using production data sources
for validation and testing purposes.

Target: BUSINESS_INTELLIGENCE_DEV database
Data Sources: Production (BUSINESS_INTELLIGENCE, ARCA)
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Deploy directly to BUSINESS_INTELLIGENCE_DEV with production data sources
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS(
    LOAN_ID,
    LEAD_GUID,
    LEGACY_LOAN_ID,
    IS_FRAUD_ANY,
    IS_FRAUD_PORTFOLIO,
    FRAUD_PORTFOLIO_NAMES,
    FRAUD_PORTFOLIO_FIRST_DATE,
    IS_FRAUD_INVESTIGATION_LMS,
    FRAUD_STATUS_LMS,
    FRAUD_REASON_LMS,
    IS_FRAUD_ACTION_RESULT,
    FRAUD_ACTION_RESULT_DATE,
    FRAUD_ACTION_RESULT_DETAILS,
    IS_FRAUD_APPLICATION_TAG,
    FRAUD_APPLICATION_TAG_DATE,
    IS_FRAUD_STATUS_TEXT,
    FRAUD_STATUS_TEXT,
    FRAUD_DETECTION_METHODS_COUNT,
    FRAUD_FIRST_DETECTED_DATE,
    FRAUD_SOURCES_LIST,
    LAST_UPDATED,
    RECORD_CREATED_DATE
) COPY GRANTS AS 

WITH cte_fraud_lead_guids AS (
    -- Efficiently collect all LEAD_GUIDs with fraud indicators from any source
    SELECT DISTINCT LOWER(lead_guid) as lead_guid
    FROM (
        -- Portfolio fraud loans
        SELECT DISTINCT LOWER(vl.lead_guid) as lead_guid
        FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
            ON TRY_CAST(REPLACE(vl.loan_id, 'LAI-', '') AS INTEGER) = lpsp.loan_id
        WHERE lpsp.PORTFOLIO_CATEGORY = 'Fraud'
        
        UNION
        
        -- LMS investigation fraud loans
        SELECT DISTINCT LOWER(cls.LEAD_GUID) as lead_guid
        FROM ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
        WHERE cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL
        
        UNION
        
        -- Action/result fraud loans
        SELECT DISTINCT LOWER(vl.lead_guid) as lead_guid
        FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APP_ACTION_AND_RESULTS aar 
            ON TRY_CAST(REPLACE(vl.application_id, 'APP-', '') AS INTEGER) = aar.APP_ID
        WHERE UPPER(aar.NOTE) LIKE '%FRAUD%'
        
        UNION
        
        -- Application tag fraud loans
        SELECT DISTINCT LOWER(app.payoff_uid) as lead_guid
        FROM BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION app
        INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_TAGS a_tags 
            ON app.hk_h_appl = a_tags.hk_h_appl
        WHERE a_tags.application_tag = 'Confirmed Fraud'
        AND a_tags.softdelete = 'False'
        
        UNION
        
        -- Status text fraud loans
        SELECT DISTINCT LOWER(vl.lead_guid) as lead_guid
        FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
            ON TRY_CAST(REPLACE(vl.loan_id, 'LAI-', '') AS INTEGER) = lsec.LOAN_ID 
        INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
            ON lsec.LOAN_SUB_STATUS_ID = lssec.id 
        WHERE lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
        AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
        AND UPPER(lssec.TITLE) LIKE '%FRAUD%'
    )
)

,cte_all_loans AS (
    -- Get loan details only for fraud cases
    SELECT DISTINCT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN cte_fraud_lead_guids flg ON LOWER(vl.lead_guid) = flg.lead_guid
)

,cte_portfolio_fraud AS (
    -- Portfolio-based fraud detection (FRAUD ONLY) - PRODUCTION data
    SELECT 
        cal.lead_guid,
        cal.loan_id,
        cal.legacy_loan_id,
        MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.created END) as fraud_portfolio_date,
        MAX(CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN TRUE ELSE FALSE END) as is_fraud_portfolio,
        LISTAGG(DISTINCT 
            CASE WHEN lpsp.PORTFOLIO_CATEGORY = 'Fraud' THEN lpsp.PORTFOLIO_NAME END, 
            ', ') as fraud_portfolio_names
    FROM cte_all_loans cal
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lpsp
        ON TRY_CAST(REPLACE(cal.loan_id, 'LAI-', '') AS INTEGER) = lpsp.loan_id
        AND lpsp.PORTFOLIO_CATEGORY = 'Fraud'
    GROUP BY cal.lead_guid, cal.loan_id, cal.legacy_loan_id
)

,cte_investigation_lms AS (
    -- LMS investigation results - PRODUCTION data
    SELECT 
        LOWER(cls.LEAD_GUID) as lead_guid,
        cls.FRAUD_INVESTIGATION_RESULTS as fraud_status_lms,
        'LMS Investigation' as fraud_reason_lms,
        CASE WHEN cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL THEN TRUE ELSE FALSE END as is_fraud_investigation_lms
    FROM ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL
)

-- LOS investigation removed - focuses on applications, not active loans

,cte_action_result_fraud AS (
    -- Action/Results fraud notes - PRODUCTION data
    SELECT 
        LOWER(vl.lead_guid) as lead_guid,
        MAX(aar.ACTION_RESULT_TS) as fraud_action_result_date,
        TRUE as is_fraud_action_result,
        LISTAGG(DISTINCT CONCAT(aar.ACTION_TEXT, ': ', aar.RESULT_TEXT), '; ') as fraud_action_result_details
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APP_ACTION_AND_RESULTS aar 
        ON TRY_CAST(REPLACE(vl.application_id, 'APP-', '') AS INTEGER) = aar.APP_ID
    WHERE UPPER(aar.NOTE) LIKE '%FRAUD%'
    GROUP BY LOWER(vl.lead_guid)
)

,cte_application_tags AS (
    -- Application tag-based fraud detection - PRODUCTION data
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
    -- Fraud detection from loan status text - PRODUCTION data
    SELECT DISTINCT
        LOWER(vl.lead_guid) as lead_guid,
        lssec.TITLE as fraud_status_text,
        TRUE as is_fraud_status_text
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
        ON TRY_CAST(REPLACE(vl.loan_id, 'LAI-', '') AS INTEGER) = lsec.LOAN_ID 
        AND lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
        ON lsec.LOAN_SUB_STATUS_ID = lssec.id 
        AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    WHERE UPPER(lssec.TITLE) LIKE '%FRAUD%'
)

-- Final comprehensive fraud view (ONE ROW PER LOAN)
SELECT 
    cal.loan_id as LOAN_ID,
    cal.lead_guid as LEAD_GUID,
    cal.legacy_loan_id as LEGACY_LOAN_ID,
    
    -- Master fraud indicator (boolean)
    COALESCE(
        cpf.is_fraud_portfolio,
        cil.is_fraud_investigation_lms,
        carf.is_fraud_action_result,
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
    
    -- Action/Result fraud indicators
    COALESCE(carf.is_fraud_action_result, FALSE) as IS_FRAUD_ACTION_RESULT,
    carf.fraud_action_result_date as FRAUD_ACTION_RESULT_DATE,
    carf.fraud_action_result_details as FRAUD_ACTION_RESULT_DETAILS,
    
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
        (CASE WHEN COALESCE(carf.is_fraud_action_result, FALSE) THEN 1 ELSE 0 END) +
        (CASE WHEN COALESCE(cat.is_fraud_application_tag, FALSE) THEN 1 ELSE 0 END) +
        (CASE WHEN COALESCE(cstf.is_fraud_status_text, FALSE) THEN 1 ELSE 0 END)
    ) as FRAUD_DETECTION_METHODS_COUNT,
    
    LEAST(
        cpf.fraud_portfolio_date,
        carf.fraud_action_result_date,
        cat.fraud_application_tag_date
    ) as FRAUD_FIRST_DETECTED_DATE,
    
    ARRAY_TO_STRING(ARRAY_COMPACT(ARRAY_CONSTRUCT(
        CASE WHEN COALESCE(cpf.is_fraud_portfolio, FALSE) THEN 'Portfolio' END,
        CASE WHEN COALESCE(cil.is_fraud_investigation_lms, FALSE) THEN 'LMS_Investigation' END,
        CASE WHEN COALESCE(carf.is_fraud_action_result, FALSE) THEN 'Action_Result' END,
        CASE WHEN COALESCE(cat.is_fraud_application_tag, FALSE) THEN 'Application_Tag' END,
        CASE WHEN COALESCE(cstf.is_fraud_status_text, FALSE) THEN 'Status_Text' END
    )), ', ') as FRAUD_SOURCES_LIST,
    
    -- Metadata
    CURRENT_TIMESTAMP() as LAST_UPDATED,
    CURRENT_DATE() as RECORD_CREATED_DATE

FROM cte_all_loans cal
LEFT JOIN cte_portfolio_fraud cpf ON cal.lead_guid = cpf.lead_guid
LEFT JOIN cte_investigation_lms cil ON cal.lead_guid = cil.lead_guid
LEFT JOIN cte_action_result_fraud carf ON cal.lead_guid = carf.lead_guid
LEFT JOIN cte_application_tags cat ON cal.lead_guid = cat.lead_guid
LEFT JOIN cte_status_text_fraud cstf ON cal.lead_guid = cstf.lead_guid

-- Base CTE already filters for fraud cases, no additional WHERE needed