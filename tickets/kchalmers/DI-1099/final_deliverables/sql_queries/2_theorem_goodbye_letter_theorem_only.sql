-- DI-1099: Theorem Goodbye Letter List - THEOREM LOANS ONLY
-- Adapted from DI-971 query pattern
-- Source: THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED (filtered to Theorem portfolios only)
-- Requirements: Include SFMC number, last 4 of loan ID with leading zeros, exclude balance info, include portfolio name
-- Filter: Only loans with PORTFOLIO_NAME containing "Theorem"

SET SALE_DATE = '2025-07-31'; -- Updated sale date

-- Theorem Goodbye Letter List - THEOREM PORTFOLIOS ONLY
SELECT 
    UPPER(la.LEGACY_LOAN_ID) as loan_id,
    -- Last 4 digits with leading zeros preserved, cast as VARCHAR
    CAST(RIGHT(UPPER(la.LEGACY_LOAN_ID), 4) AS VARCHAR) as last_four_loan_id,
    lower(la.LEAD_GUID) as payoffuid,
    UPPER(ci.FIRST_NAME) as first_name,
    UPPER(ci.LAST_NAME) as last_name,
    ci.email,
    ci.ADDRESS_1 as streetaddress1,
    ci.ADDRESS_2 as streetaddress2,
    ci.city,
    ci.state,
    ci.ZIP_CODE as zipcode,
    cust.CUSTOMER_ID as SFMC_SUBSCRIBER_ID, -- Required for SFMC integration
    A.CHARGEOFFDATE AS CHARGE_OFF_DATE,
    $SALE_DATE AS SALE_DATE,
    -- Portfolio name as final column (no balance info per requirements)
    A.PORTFOLIONAME as portfolio_name
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED C
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LA
    ON LA.LEGACY_LOAN_ID = C.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII ci
    ON ci.MEMBER_ID::VARCHAR = la.MEMBER_ID::VARCHAR 
    AND ci.MEMBER_PII_END_DATE IS NULL
LEFT JOIN business_intelligence.bridge.vw_los_custom_loan_settings_current los
    ON los.APPLICATION_GUID = la.LEAD_GUID
INNER JOIN business_intelligence.bridge.VW_LOAN_CUSTOMER_CURRENT cust
    ON los.loan_id = cust.loan_id 
    AND cust.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LOS_SCHEMA()
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.THEOREM_DEBT_SALE_Q1_2025_SALE A
    ON C.LOANID = A.LOANID
WHERE A.PORTFOLIONAME LIKE '%Theorem%' -- Filter to only Theorem portfolios
ORDER BY la.LEGACY_LOAN_ID;