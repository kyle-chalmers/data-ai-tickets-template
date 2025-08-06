-- DI-934: Updated Fraud Loans Analysis with Binary Fraud Portfolio Indicators
-- Includes all loans with fraud confirmed date OR investigation results
-- Binary indicators for specific fraud portfolio types

WITH fraud_loans AS (
    -- Get all loans with any fraud indication (confirmed date OR investigation results)
    SELECT 
        cls.LOAN_ID,
        cls.FRAUD_INVESTIGATION_RESULTS,
        cls.FRAUD_CONFIRMED_DATE,
        cls.FRAUD_NOTIFICATION_RECEIVED,
        cls.FRAUD_CONTACT_EMAIL
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.FRAUD_CONFIRMED_DATE IS NOT NULL 
       OR cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL
),

loan_portfolio_info AS (
    -- Get loan details with partner information (NO FILTERING on partners)
    SELECT 
        l.LOAN_ID,
        l.PARTNER_ID,
        l.LOAN_CLOSED_DATE,
        l.CHARGE_OFF_DATE,
        p.PARTNER_NAME
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN l
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_PARTNER p 
        ON l.PARTNER_ID = p.PARTNER_ID
),

fraud_portfolio_indicators AS (
    -- Create binary indicators for each fraud portfolio type
    SELECT 
        lp.LOAN_ID,
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
)

-- Final result - one row per loan with binary fraud indicators
SELECT 
    fl.LOAN_ID,
    fpi.ALL_PORTFOLIO_IDS as PORTFOLIO_ID,
    fpi.ALL_PORTFOLIO_NAMES as PORTFOLIO_NAME,
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
    CASE 
        WHEN lpi.CHARGE_OFF_DATE IS NOT NULL THEN 'Charged Off'
        WHEN lpi.LOAN_CLOSED_DATE IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END as LOAN_STATUS,
    lpi.LOAN_CLOSED_DATE,
    -- Partner information (NO FILTERING - all partners included)
    lpi.PARTNER_NAME as CURRENT_INVESTOR
FROM fraud_loans fl
LEFT JOIN loan_portfolio_info lpi ON CAST(fl.LOAN_ID AS VARCHAR) = lpi.LOAN_ID
LEFT JOIN fraud_portfolio_indicators fpi ON CAST(fl.LOAN_ID AS VARCHAR) = fpi.LOAN_ID
-- Only include loans that have at least one fraud portfolio assignment
WHERE fpi.LOAN_ID IS NOT NULL
ORDER BY fl.FRAUD_CONFIRMED_DATE DESC NULLS LAST, fl.LOAN_ID;