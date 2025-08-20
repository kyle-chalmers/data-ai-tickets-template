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
    SELECT A.LOAN_ID::VARCHAR AS LOAN_ID, B.TITLE as LOAN_STATUS FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT A
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT B
ON A.LOAN_SUB_STATUS_ID = B.ID AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE A.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
),

partner_aggregation AS (
    -- Aggregate partner information similar to portfolios
    SELECT
        l.LOAN_ID::VARCHAR AS LOAN_ID,
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
),

loan_tape_portfolio AS (
    -- Get current loan tape portfolio information for better ownership identification
    SELECT 
        lt.PAYOFFUID as LEAD_GUID,
        lt.LOANID as LOAN_TAPE_LOAN_ID,
        lt.PORTFOLIONAME as LOAN_TAPE_PORTFOLIO_NAME,
        lt.SECONDARY_BUYER,
        lt.SECONDARY_SELLER,
        -- Create clear Happy Money ownership indicator
        CASE 
            WHEN lt.PORTFOLIONAME IN (
                'Payoff',
                'Payoff Consumer Credit Income Fund I LP',
                'Payoff Consumer Loan Trust'
            )
            THEN 1 
            ELSE 0 
        END as HAPPY_MONEY_OWNED_INDICATOR
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE lt
)

-- Final result - one row per loan with columns ordered per ticket requirements
SELECT
    -- Core loan identifiers
    l.LOAN_ID,
    l.LEGACY_LOAN_ID,
    l.LEAD_GUID,
    -- Portfolio information (Portfolio ID | Portfolio Name from ticket)
    fpi.ALL_PORTFOLIO_IDS as PORTFOLIO_ID,
    fpi.ALL_PORTFOLIO_NAMES as PORTFOLIO_NAME,
    -- Loan Tape Portfolio Information (for reliable ownership identification)
    ltp.LOAN_TAPE_LOAN_ID,
    ltp.LOAN_TAPE_PORTFOLIO_NAME,
    ltp.SECONDARY_BUYER as LOAN_TAPE_SECONDARY_BUYER,
    ltp.SECONDARY_SELLER as LOAN_TAPE_SECONDARY_SELLER,
    ltp.HAPPY_MONEY_OWNED_INDICATOR,
    -- Fraud type indicators (binary flags for detailed analysis)
    fpi.FIRST_PARTY_FRAUD_CONFIRMED,
    fpi.IDENTITY_THEFT_FRAUD_CONFIRMED,
    fpi.FRAUD_DECLINED,
    fpi.FRAUD_PENDING_INVESTIGATION,
    -- Fraud confirmed date (from ticket requirements)
    fl.FRAUD_CONFIRMED_DATE,
    -- Loan status information (Loan Status | Loan Closed Date from ticket)
    mrs.LOAN_STATUS,
    IFF(mrs2.LOAN_ID IS NOT NULL,TRUE,FALSE) AS FRAUD_LOAN_STATUS,
    l.LOAN_CLOSED_DATE,
    l.CHARGE_OFF_DATE,
    -- Additional investigation details
    fl.FRAUD_INVESTIGATION_RESULTS,
    fl.FRAUD_NOTIFICATION_RECEIVED,
    fl.FRAUD_CONTACT_EMAIL,
    -- Partner/investor information (flattened to avoid duplicates)
    pa.ALL_PARTNER_IDS,
    pa.ALL_PARTNER_NAMES as CURRENT_INVESTOR_PARTNERS,
    pa.MULTIPLE_PARTNERS_INDICATOR,
    pa.PARTNER_COUNT
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN l
LEFT JOIN fraud_loans fl ON l.LEAD_GUID = fl.LEAD_GUID
LEFT JOIN fraud_portfolio_indicators fpi ON l.LOAN_ID = fpi.LOAN_ID
LEFT JOIN most_recent_status mrs ON mrs.loan_id = l.LOAN_ID
LEFT JOIN most_recent_status mrs2 ON mrs2.loan_id = l.LOAN_ID AND MRS2.LOAN_STATUS ILIKE '%FRAUD%'
LEFT JOIN partner_aggregation pa ON pa.LOAN_ID = l.LOAN_ID
LEFT JOIN loan_tape_portfolio ltp ON ltp.LEAD_GUID = l.LEAD_GUID
-- Loans must fit one of the following criteria
WHERE fpi.LOAN_ID IS NOT NULL OR fl.LEAD_GUID IS NOT NULL OR mrs2.LOAN_ID IS NOT NULL
ORDER BY fl.FRAUD_CONFIRMED_DATE DESC NULLS LAST, l.LOAN_ID;