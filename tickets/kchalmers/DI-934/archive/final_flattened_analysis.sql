-- DI-934: Final Fraud Loans Analysis with Flattened Partner Data
-- Eliminates duplicates by flattening partner information like portfolios
-- Includes indicator for multiple partner assignments

WITH fraud_loans AS (
    -- Get all loans with any fraud indication (confirmed date OR investigation results)
    SELECT 
        CAST(cls.LOAN_ID as varchar) as loan_id,
        cls.FRAUD_INVESTIGATION_RESULTS,
        cls.FRAUD_CONFIRMED_DATE,
        cls.FRAUD_NOTIFICATION_RECEIVED,
        cls.FRAUD_CONTACT_EMAIL,
        cls.LEAD_GUID,
        cls.PLACEMENT_STATUS,
        cls.PLACEMENT_STATUS_START_DATE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.FRAUD_CONFIRMED_DATE IS NOT NULL 
       OR cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL
),

fraud_portfolio_indicators AS (
    -- Create binary indicators for each fraud portfolio type
    SELECT 
        lp.LOAN_ID::varchar as loan_id,
        -- Binary indicators for specific fraud portfolios
        MAX(CASE WHEN lp.PORTFOLIO_NAME = 'First Party Fraud - Confirmed' THEN 1 ELSE 0 END) as FIRST_PARTY_FRAUD_CONFIRMED,
        MAX(CASE WHEN lp.PORTFOLIO_NAME = 'Fraud - Declined' THEN 1 ELSE 0 END) as FRAUD_DECLINED,
        MAX(CASE WHEN lp.PORTFOLIO_NAME = 'Fraud - Pending Investigation' THEN 1 ELSE 0 END) as FRAUD_PENDING_INVESTIGATION,
        MAX(CASE WHEN lp.PORTFOLIO_NAME = 'Identity Theft Fraud - Confirmed' THEN 1 ELSE 0 END) as IDENTITY_THEFT_FRAUD_CONFIRMED,
        -- Aggregate portfolio information for reference
        LISTAGG(lp.PORTFOLIO_ID, '; ') WITHIN GROUP (ORDER BY lp.PORTFOLIO_ID) as ALL_PORTFOLIO_IDS,
        LISTAGG(lp.PORTFOLIO_NAME, '; ') WITHIN GROUP (ORDER BY lp.PORTFOLIO_NAME) as ALL_PORTFOLIO_NAMES
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lp
    WHERE lp.PORTFOLIO_NAME IN (
        'First Party Fraud - Confirmed',
        'Fraud - Declined', 
        'Fraud - Pending Investigation',
        'Identity Theft Fraud - Confirmed'
    )
    GROUP BY lp.LOAN_ID
),

most_recent_status AS (
    SELECT 
        LOAN_ID::varchar as loan_id, 
        date, 
        LOAN_SUB_STATUS_TEXT, 
        LAST_HUMAN_ACTIVITY, 
        LOAN_STATUS_TEXT 
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT
    WHERE SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LOAN_ID ORDER BY date DESC) = 1
),

partner_aggregation AS (
    -- Aggregate partner information similar to portfolios
    SELECT 
        l.LOAN_ID,
        -- Aggregate all partner information
        LISTAGG(DISTINCT l.PARTNER_ID, '; ') WITHIN GROUP (ORDER BY l.PARTNER_ID) as ALL_PARTNER_IDS,
        LISTAGG(DISTINCT p.PARTNER_NAME, '; ') WITHIN GROUP (ORDER BY p.PARTNER_NAME) as ALL_PARTNER_NAMES,
        -- Indicator for multiple partners
        CASE 
            WHEN COUNT(DISTINCT p.PARTNER_NAME) > 1 THEN 1 
            ELSE 0 
        END as MULTIPLE_PARTNERS_INDICATOR,
        COUNT(DISTINCT p.PARTNER_NAME) as PARTNER_COUNT
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN l
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_PARTNER p ON l.PARTNER_ID = p.PARTNER_ID
    GROUP BY l.LOAN_ID
)

-- Final result - one row per loan with flattened partner data
SELECT
    l.LEGACY_LOAN_ID,
    l.LEAD_GUID,
    fl.LOAN_ID,
    fpi.ALL_PORTFOLIO_NAMES,
    -- Binary fraud type indicators
    fpi.FIRST_PARTY_FRAUD_CONFIRMED,
    fpi.IDENTITY_THEFT_FRAUD_CONFIRMED,
    fpi.FRAUD_DECLINED,
    fpi.FRAUD_PENDING_INVESTIGATION,
    -- Investigation details
    fl.FRAUD_INVESTIGATION_RESULTS,
    fl.FRAUD_CONFIRMED_DATE,
    fl.FRAUD_NOTIFICATION_RECEIVED,
    fl.FRAUD_CONTACT_EMAIL,
    -- Loan status
    l.LOAN_CLOSED_DATE,
    l.CHARGE_OFF_DATE,
    mrs.LOAN_SUB_STATUS_TEXT,
    -- Flattened partner information
    pa.ALL_PARTNER_IDS,
    pa.ALL_PARTNER_NAMES,
    pa.MULTIPLE_PARTNERS_INDICATOR,
    pa.PARTNER_COUNT
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN l
LEFT JOIN fraud_loans fl ON l.LEAD_GUID = fl.LEAD_GUID
LEFT JOIN fraud_portfolio_indicators fpi ON l.LOAN_ID = fpi.LOAN_ID
LEFT JOIN most_recent_status mrs ON mrs.loan_id = l.LOAN_ID
LEFT JOIN partner_aggregation pa ON pa.LOAN_ID = l.LOAN_ID
-- Loans must fit one of the following criteria
WHERE fpi.LOAN_ID IS NOT NULL OR fl.LEAD_GUID IS NOT NULL
ORDER BY fl.FRAUD_CONFIRMED_DATE DESC NULLS LAST, fl.LOAN_ID;