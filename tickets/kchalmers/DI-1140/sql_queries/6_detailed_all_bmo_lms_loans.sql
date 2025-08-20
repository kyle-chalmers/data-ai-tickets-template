-- DI-1140 BMO Fraud Investigation - Query 6 ENHANCED
-- Individual Loans Analysis - All BMO Routing Numbers  
-- ENHANCED: Includes GIACT account creation dates, loan amounts, applicant state, and capital partner
-- Analysis Date: August 1st, 2025 | Dynamic Threshold: 30 + days since analysis

-- Variables
SET ANALYSIS_DATE = '2025-08-01';  -- Friday when request was submitted
SET DAYS_THRESHOLD = (SELECT (30 + DATEDIFF('day', '2025-08-01', CURRENT_DATE())));

-- ===========================================
-- ENHANCED BMO LMS LOANS INVESTIGATION
-- Returns individual loan records with ADDITIONAL COLUMNS:
-- - GIACT account creation dates and verification data
-- - Loan amounts (requested, final, and LMS amounts)
-- - Capital partner information
-- - Applicant state and acquisition data
-- ===========================================

-- Create LMS version of bank info (VW_BANK_INFO is LOS-only)
WITH lms_bank_info AS (
    SELECT 
        le.id AS LOAN_ID, 
        cae.ACCOUNT_TYPE, 
        cae.ACCOUNT_NUMBER, 
        cae.ROUTING_NUMBER
    FROM ARCA.FRESHSNOW.loan_entity_current le
    JOIN ARCA.FRESHSNOW.loan_settings_entity_current lse ON le.settings_id = lse.id
    JOIN ARCA.FRESHSNOW.loan_customer_current lc ON lc.loan_id = le.id AND customer_role = 'loan.customerRole.primary'
    JOIN ARCA.pii.customer_entity_current ce ON ce.id = lc.customer_id
    LEFT JOIN ARCA.FRESHSNOW.vw_source_company_entity_current sce ON sce.id = lse.source_company
    LEFT JOIN ARCA.FRESHSNOW.payment_account_entity_current pae ON ce.id = pae.entity_id AND pae.is_primary = 1 AND pae.active = 1
    LEFT JOIN ARCA.FRESHSNOW.checking_account_entity_current cae ON pae.checking_account_id = cae.id
    WHERE 1=1
      -- SWITCH TO LMS SCHEMA FOR ORIGINATED LOANS
      AND le.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lc.SCHEMA_NAME = ARCA.config.lms_schema()
      AND ce.SCHEMA_NAME = ARCA.config.lms_schema()
      AND sce.SCHEMA_NAME = ARCA.config.lms_schema()
      AND pae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND cae.SCHEMA_NAME = ARCA.config.lms_schema()
      AND lse.SCHEMA_NAME = ARCA.config.lms_schema()
),
-- Fraud portfolios for LMS (if any exist)
fraud_portfolios AS (
    SELECT 
        LOAN_ID,
        LISTAGG(PORTFOLIO_NAME, ',') as CURRENT_loan_fraud_portfolios
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS  -- Note: LOAN not APP
    WHERE PORTFOLIO_CATEGORY = 'Fraud' 
    GROUP BY LOAN_ID
)

-- ENHANCED LMS ORIGINATED LOANS QUERY
SELECT 
    -- === LOAN IDENTIFICATION ===
    bi.LOAN_ID,
    vlcc.CUSTOMER_ID,
    -- === BANKING DETAILS ===
    bi.ROUTING_NUMBER,
    bi.ACCOUNT_TYPE,
    bi.ACCOUNT_NUMBER,
    -- === DATE ANALYSIS ===
    le.CREATED as LOAN_ORIGINATED_DATE,
    DATEDIFF('day', le.CREATED, CURRENT_DATE()) as DAYS_SINCE_ORIGINATION,
    $DAYS_THRESHOLD AS ORIGINATION_DAYS_THRESHOLD_BOUNDARY,
    le.CREATED >= DATEADD('day', -$DAYS_THRESHOLD, CURRENT_DATE()) as LOAN_ORIGINATED_INSIDE_OF_BOUNDARY_IND,
    giact.ACCOUNT_ADDED_DATE >= DATEADD('day', -$DAYS_THRESHOLD, CURRENT_DATE()) as GIACT_ACCOUNT_CREATED_INSIDE_OF_BOUNDARY_IND,
    -- === GIACT BANK ACCOUNT INFORMATION ===
    giact.ACCOUNT_ADDED_DATE as GIACT_ACCOUNT_CREATION_DATE,
    giact.ACCOUNT_AGE_DAYS as GIACT_ACCOUNT_AGE_DAYS,
    giact.BANK_NAME as GIACT_BANK_NAME,
    giact.VERIFICATION_RESPONSE as GIACT_VERIFICATION_STATUS,
    -- === LOAN STATUS ===
    /* le.ACTIVE,
    le.DELETED,
    le.ARCHIVED, */
    lssec.TITLE as LOAN_STATUS,
    -- === LMS LOAN DATA ===
    CLS.LEAD_GUID,
    CLS.FRAUD_CONFIRMED_DATE,
    CLS.FRAUD_INVESTIGATION_RESULTS,
    CLS.FRAUD_NOTIFICATION_RECEIVED,
    LOS.LOAN_ID AS APPLICATION_ID,
    LOS.ORIGINATION_DATE,
    fp.current_loan_fraud_portfolios,
    -- === ENHANCED LOAN AND APPLICATION DATA ===
    LOS.REQUESTED_LOAN_AMOUNT as REQUESTED_LOAN_AMOUNT,
    LOS.LOAN_AMOUNT as FINAL_LOAN_AMOUNT,
    LOS.CAPITAL_PARTNER,
    LOS.HOME_ADDRESS_STATE as APPLICANT_STATE,
    LOS.BUREAU_STATE,
    LOS.UTM_SOURCE,
    LOS.UTM_MEDIUM,
    LOS.LOAN_PURPOSE,
    LOS.BORROWER_STATED_ANNUAL_INCOME as STATED_ANNUAL_INCOME
    
    -- === LMS-SPECIFIC LOAN DETAILS ===
    -- CLS.LOAN_STATUS_TEXT and CURRENT_BALANCE fields not available in LMS custom settings

FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BMO_ROUTING_NUMBERS brn
JOIN lms_bank_info bi 
    ON brn.ROUTING_NUMBER = bi.ROUTING_NUMBER

-- Join to loan entity (ALWAYS filter by LMS schema)
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le 
    ON bi.LOAN_ID = le.ID 
    AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()

-- Join to settings (NOTE: Uses LOAN_ID field, not ID)
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lsec
    ON bi.LOAN_ID = lsec.LOAN_ID
    AND lsec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()

-- Join to sub-status for readable status
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lssec
    ON lsec.LOAN_SUB_STATUS_ID = lssec.ID 
    AND lssec.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()

-- Join to customer
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT vlcc
    ON bi.LOAN_ID = vlcc.LOAN_ID 
    AND vlcc.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()

-- Join to custom settings (check if LMS equivalent exists)
LEFT JOIN ARCA.FRESHSNOW.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT CLS
    ON le.ID = CLS.LOAN_ID

-- Join to custom settings (check if LMS equivalent exists)
LEFT JOIN ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT LOS
    ON CLS.LEAD_GUID = LOS.APPLICATION_GUID

-- === ENHANCED JOINS FOR ADDITIONAL DATA ===
-- Join to GIACT data for account creation dates and verification info
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_OSCILAR_GIACT_DATA giact
    ON CAST(LOS.LOAN_ID AS VARCHAR) = CAST(giact.APPLICATION_ID AS VARCHAR)
    AND CAST(bi.ROUTING_NUMBER AS VARCHAR) = CAST(giact.GIACT_ROUTING_NUMBER AS VARCHAR)
    AND CAST(bi.ACCOUNT_NUMBER AS VARCHAR) = CAST(giact.GIACT_ACCOUNT_NUMBER AS VARCHAR)
    

-- Fraud portfolios (if applicable to originated loans)
LEFT JOIN fraud_portfolios fp
    ON bi.LOAN_ID = fp.LOAN_ID

WHERE 1=1
    -- Exclude primary routing number already analyzed in queries 1&2
    AND brn.ROUTING_NUMBER != '071025661'
    -- Active loans only
    AND le.ACTIVE = 1
    AND le.DELETED = 0
    
ORDER BY 
    bi.ROUTING_NUMBER,
    le.CREATED DESC;