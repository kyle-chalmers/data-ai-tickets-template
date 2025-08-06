-- DI-934: List of Confirmed Fraud Loans and Repurchase Details
-- Query to identify confirmed fraud loans with portfolio and repurchase information

WITH fraud_loans AS (
    -- Get loans with confirmed fraud
    SELECT 
        cls.LOAN_ID,
        cls.FRAUD_INVESTIGATION_RESULTS,
        cls.FRAUD_CONFIRMED_DATE,
        cls.FRAUD_NOTIFICATION_RECEIVED,
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.FRAUD_CONFIRMED_DATE IS NOT NULL
      AND cls.FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
),

loan_portfolio_info AS (
    -- Get loan details with partner information
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

portfolio_assignments AS (
    -- Get current portfolio assignments for portfolio ID and name
    SELECT 
        lp.LOAN_ID,
        lp.PORTFOLIO_ID,
        lp.PORTFOLIO_NAME
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lp
)

-- Final result combining all data
SELECT 
    fl.LOAN_ID,
    pa.PORTFOLIO_ID,
    pa.PORTFOLIO_NAME,
    -- Determine fraud type based on available data (placeholder logic - needs business clarification)
    'TBD - Needs Business Logic' as FRAUD_TYPE,
    fl.FRAUD_CONFIRMED_DATE,
    -- Derive loan status from available date fields
    CASE 
        WHEN lpi.CHARGE_OFF_DATE IS NOT NULL THEN 'Charged Off'
        WHEN lpi.LOAN_CLOSED_DATE IS NOT NULL THEN 'Closed'
        ELSE 'Active'
    END as LOAN_STATUS,
    lpi.LOAN_CLOSED_DATE,
    -- Check if loan has been repurchased by Happy Money (current investor is PayOff)
    CASE 
        WHEN lpi.PARTNER_NAME ILIKE '%PayOff%' THEN 'Yes - Repurchased'
        ELSE 'No'
    END as REPURCHASED_BY_HAPPY_MONEY,
    lpi.PARTNER_NAME as CURRENT_INVESTOR
FROM fraud_loans fl
LEFT JOIN loan_portfolio_info lpi ON CAST(fl.LOAN_ID AS VARCHAR) = lpi.LOAN_ID
LEFT JOIN portfolio_assignments pa ON CAST(fl.LOAN_ID AS VARCHAR) = pa.LOAN_ID
ORDER BY fl.FRAUD_CONFIRMED_DATE DESC, fl.LOAN_ID;

-- Note: This query needs refinement for:
-- 1. Fraud type determination (1st party vs 3rd party) - requires business logic input
-- 2. Validation of repurchase logic
-- 3. Handling of multiple portfolio assignments per loan