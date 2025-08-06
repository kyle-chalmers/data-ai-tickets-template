-- DI-934: Deduplicated List of Confirmed Fraud Loans and Repurchase Details
-- One row per loan with aggregated portfolio information

WITH fraud_loans AS (
    -- Get loans with confirmed fraud
    SELECT 
        cls.LOAN_ID,
        cls.FRAUD_INVESTIGATION_RESULTS,
        cls.FRAUD_CONFIRMED_DATE
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
    -- Get portfolio assignments aggregated per loan
    SELECT 
        lp.LOAN_ID,
        LISTAGG(lp.PORTFOLIO_ID, '; ') WITHIN GROUP (ORDER BY lp.PORTFOLIO_ID) as PORTFOLIO_IDS,
        LISTAGG(lp.PORTFOLIO_NAME, '; ') WITHIN GROUP (ORDER BY lp.PORTFOLIO_NAME) as PORTFOLIO_NAMES
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS lp
    GROUP BY lp.LOAN_ID
)

-- Final result - one row per loan
SELECT 
    fl.LOAN_ID,
    pa.PORTFOLIO_IDS as PORTFOLIO_ID,
    pa.PORTFOLIO_NAMES as PORTFOLIO_NAME,
    -- Determine fraud type based on portfolio names
    CASE 
        WHEN pa.PORTFOLIO_NAMES ILIKE '%First Party Fraud%' THEN '1st Party Fraud'
        WHEN pa.PORTFOLIO_NAMES ILIKE '%Third Party Fraud%' THEN '3rd Party Fraud'
        WHEN pa.PORTFOLIO_NAMES ILIKE '%Fraud%' THEN 'Fraud - Type TBD'
        ELSE 'TBD - Needs Business Logic'
    END as FRAUD_TYPE,
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