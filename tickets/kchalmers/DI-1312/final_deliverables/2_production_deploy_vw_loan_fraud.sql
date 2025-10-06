/*
DI-1312: VW_LOAN_FRAUD - Production Deployment Template

IMPORTANT: This script deploys VW_LOAN_FRAUD to production environment
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD (single view with core logic)

Pre-Deployment Checklist:
[  ] All QC validation tests passed in development
[  ] 509 fraud loans confirmed in development
[  ] EARLIEST_FRAUD_DATE working correctly (~502 loans with dates)
[  ] User has reviewed and approved development view
[  ] Stakeholders notified of deployment

Deployment Steps:
1. Review development view: SELECT * FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD LIMIT 100
2. Execute this script to deploy to production
3. Run post-deployment validation queries
4. Update dependent systems (DI-1141 debt sale query)
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- ============================================================================
-- PRODUCTION DEPLOYMENT
-- ============================================================================

-- ANALYTICS LAYER: Core fraud view logic
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD(
    LOAN_ID,
    LEAD_GUID,
    -- Custom Field Data (Source 1)
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_CONFIRMED_DATE,
    FRAUD_NOTIFICATION_RECEIVED,
    FRAUD_CONTACT_EMAIL,
    -- Portfolio Data (Source 2)
    FRAUD_PORTFOLIOS,
    FRAUD_PORTFOLIO_COUNT,
    FIRST_PARTY_FRAUD_CONFIRMED_DATE,
    IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
    FRAUD_DECLINED_DATE,
    FRAUD_PENDING_INVESTIGATION_DATE,
    -- Current Status Data (Source 3)
    CURRENT_SUB_STATUS,
    LOAN_SUB_STATUS_ID,
    -- Calculated Date Fields
    EARLIEST_FRAUD_DATE,
    -- Fraud Classification Flags
    FRAUD_STATUS,
    IS_CONFIRMED_FRAUD,
    IS_DECLINED_FRAUD,
    IS_UNDER_INVESTIGATION,
    IS_ACTIVE_FRAUD,
    -- Data Quality Flags
    HAS_CUSTOM_FIELDS,
    HAS_FRAUD_PORTFOLIO,
    HAS_FRAUD_SUB_STATUS,
    DATA_SOURCE_COUNT,
    DATA_COMPLETENESS_FLAG,
    DATA_SOURCE_LIST,
    DATA_QUALITY_FLAG
) COPY GRANTS AS
WITH loan_lead_guid AS (
    -- Get LEAD_GUID for all production loans
    SELECT
        LOAN_ID,
        LEAD_GUID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN
),
custom_fields AS (
    -- Source 1: Custom fraud fields from loan settings
    SELECT
        LOAN_ID,
        FRAUD_INVESTIGATION_RESULTS,
        FRAUD_CONFIRMED_DATE,
        FRAUD_NOTIFICATION_RECEIVED,
        FRAUD_CONTACT_EMAIL,
        'CUSTOM_FIELDS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
    WHERE FRAUD_CONFIRMED_DATE IS NOT NULL
       OR FRAUD_INVESTIGATION_RESULTS IS NOT NULL
       OR FRAUD_NOTIFICATION_RECEIVED IS NOT NULL
       OR FRAUD_CONTACT_EMAIL IS NOT NULL
),
fraud_portfolios AS (
    -- Source 2: Fraud portfolios aggregated by loan
    SELECT
        LOAN_ID,
        LISTAGG(DISTINCT PORTFOLIO_NAME, '; ') WITHIN GROUP (ORDER BY PORTFOLIO_NAME) as FRAUD_PORTFOLIOS,
        COUNT(DISTINCT PORTFOLIO_NAME) as FRAUD_PORTFOLIO_COUNT,
        MAX(CASE WHEN PORTFOLIO_NAME = 'First Party Fraud - Confirmed' THEN CREATED END) as FIRST_PARTY_FRAUD_CONFIRMED_DATE,
        MAX(CASE WHEN PORTFOLIO_NAME = 'Identity Theft Fraud - Confirmed' THEN CREATED END) as IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
        MAX(CASE WHEN PORTFOLIO_NAME = 'Fraud - Declined' THEN CREATED END) as FRAUD_DECLINED_DATE,
        MAX(CASE WHEN PORTFOLIO_NAME = 'Fraud - Pending Investigation' THEN CREATED END) as FRAUD_PENDING_INVESTIGATION_DATE,
        'PORTFOLIOS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
    WHERE PORTFOLIO_CATEGORY = 'Fraud'
    GROUP BY LOAN_ID
),
fraud_sub_status AS (
    -- Source 3: Current fraud sub-status
    SELECT
        ls.LOAN_ID,
        lss.TITLE as CURRENT_SUB_STATUS,
        ls.LOAN_SUB_STATUS_ID,
        'SUB_STATUS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT ls
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lss
        ON ls.LOAN_SUB_STATUS_ID = lss.ID
        AND lss.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    WHERE ls.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
        AND ls.DELETED = 0
        AND ls.LOAN_SUB_STATUS_ID IN (32, 61)  -- 32: Open - Fraud Process, 61: Closed - Confirmed Fraud
),
all_fraud_loans AS (
    -- Union all sources to get complete fraud loan population
    -- Filter to only production loans (those in VW_LOAN)
    SELECT LOAN_ID FROM custom_fields
    UNION
    SELECT LOAN_ID FROM fraud_portfolios
    UNION
    SELECT LOAN_ID FROM fraud_sub_status
)
-- Main query: Join all sources back to complete fraud loan list
SELECT
    llg.LOAN_ID,
    llg.LEAD_GUID,

    -- Custom Field Data
    cf.FRAUD_INVESTIGATION_RESULTS,
    cf.FRAUD_CONFIRMED_DATE,
    cf.FRAUD_NOTIFICATION_RECEIVED,
    cf.FRAUD_CONTACT_EMAIL,

    -- Portfolio Data
    fp.FRAUD_PORTFOLIOS,
    fp.FRAUD_PORTFOLIO_COUNT,
    fp.FIRST_PARTY_FRAUD_CONFIRMED_DATE,
    fp.IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
    fp.FRAUD_DECLINED_DATE,
    fp.FRAUD_PENDING_INVESTIGATION_DATE,

    -- Current Status Data
    fss.CURRENT_SUB_STATUS,
    fss.LOAN_SUB_STATUS_ID,

    -- Calculated: Earliest Fraud Date (using NULLIF to handle nulls in LEAST)
    NULLIF(
        LEAST(
            COALESCE(cf.FRAUD_NOTIFICATION_RECEIVED, '9999-12-31'::DATE),
            COALESCE(cf.FRAUD_CONFIRMED_DATE, '9999-12-31'::DATE),
            COALESCE(CAST(fp.FIRST_PARTY_FRAUD_CONFIRMED_DATE AS DATE), '9999-12-31'::DATE),
            COALESCE(CAST(fp.IDENTITY_THEFT_FRAUD_CONFIRMED_DATE AS DATE), '9999-12-31'::DATE),
            COALESCE(CAST(fp.FRAUD_PENDING_INVESTIGATION_DATE AS DATE), '9999-12-31'::DATE),
            COALESCE(CAST(fp.FRAUD_DECLINED_DATE AS DATE), '9999-12-31'::DATE)
        ),
        '9999-12-31'::DATE
    ) as EARLIEST_FRAUD_DATE,

    -- Fraud Classification: Conservative approach (any confirmation = CONFIRMED)
    CASE
        -- CONFIRMED: Any source indicates confirmed fraud
        WHEN cf.FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
             OR fp.FRAUD_PORTFOLIOS LIKE '%Confirmed%'
             OR fss.LOAN_SUB_STATUS_ID = 61  -- Closed - Confirmed Fraud
        THEN 'CONFIRMED'

        -- UNDER_INVESTIGATION: Pending investigation or open fraud process
        WHEN fp.FRAUD_PORTFOLIOS LIKE '%Pending Investigation%'
             OR fss.LOAN_SUB_STATUS_ID = 32  -- Open - Fraud Process
        THEN 'UNDER_INVESTIGATION'

        -- MIXED: Conflicting data (confirmed in one source, declined in another)
        WHEN (cf.FRAUD_INVESTIGATION_RESULTS = 'Confirmed' AND fp.FRAUD_PORTFOLIOS LIKE '%Declined%')
             OR (cf.FRAUD_INVESTIGATION_RESULTS = 'Declined' AND fp.FRAUD_PORTFOLIOS LIKE '%Confirmed%')
        THEN 'MIXED'

        -- DECLINED: Only if no confirmed indicators
        WHEN cf.FRAUD_INVESTIGATION_RESULTS = 'Declined'
             OR fp.FRAUD_PORTFOLIOS = 'Fraud - Declined'
        THEN 'DECLINED'

        ELSE 'UNKNOWN'
    END as FRAUD_STATUS,

    -- Boolean Flags for Fraud Classification
    CASE
        WHEN cf.FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
             OR fp.FRAUD_PORTFOLIOS LIKE '%Confirmed%'
             OR fss.LOAN_SUB_STATUS_ID = 61
        THEN TRUE
        ELSE FALSE
    END as IS_CONFIRMED_FRAUD,

    CASE
        WHEN cf.FRAUD_INVESTIGATION_RESULTS = 'Declined'
             OR fp.FRAUD_PORTFOLIOS = 'Fraud - Declined'
        THEN TRUE
        ELSE FALSE
    END as IS_DECLINED_FRAUD,

    CASE
        WHEN fp.FRAUD_PORTFOLIOS LIKE '%Pending Investigation%'
             OR fss.LOAN_SUB_STATUS_ID = 32
        THEN TRUE
        ELSE FALSE
    END as IS_UNDER_INVESTIGATION,

    -- IS_ACTIVE_FRAUD: Has fraud portfolio OR fraud sub-status OR confirmed investigation
    CASE
        WHEN fp.FRAUD_PORTFOLIO_COUNT > 0
             OR fss.LOAN_SUB_STATUS_ID IN (32, 61)
             OR cf.FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
        THEN TRUE
        ELSE FALSE
    END as IS_ACTIVE_FRAUD,

    -- Data Source Tracking Flags
    CASE WHEN cf.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_CUSTOM_FIELDS,
    CASE WHEN fp.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_PORTFOLIO,
    CASE WHEN fss.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_SUB_STATUS,

    -- Data Source Count and Completeness
    COALESCE(
        CASE WHEN cf.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN fp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
        CASE WHEN fss.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END,
        0
    ) as DATA_SOURCE_COUNT,

    CASE
        WHEN DATA_SOURCE_COUNT = 3 THEN 'COMPLETE'
        WHEN DATA_SOURCE_COUNT = 2 THEN 'PARTIAL'
        ELSE 'SINGLE_SOURCE'
    END as DATA_COMPLETENESS_FLAG,

    -- Data Source List (CSV)
    REPLACE(CONCAT_WS(', ',
        CASE WHEN cf.LOAN_ID IS NOT NULL THEN cf.SOURCE ELSE '' END,
        CASE WHEN fp.LOAN_ID IS NOT NULL THEN fp.SOURCE ELSE '' END,
        CASE WHEN fss.LOAN_ID IS NOT NULL THEN fss.SOURCE ELSE '' END
    ), ' , ', ' ') as DATA_SOURCE_LIST,

    -- Data Quality Flag based on consistency
    CASE
        -- Inconsistent: Conflicting classifications
        WHEN FRAUD_STATUS = 'MIXED' THEN 'INCONSISTENT'

        -- Complete and consistent
        WHEN DATA_SOURCE_COUNT = 3 AND FRAUD_STATUS IN ('CONFIRMED', 'DECLINED', 'UNDER_INVESTIGATION')
        THEN 'CONSISTENT'

        -- Partial data
        WHEN DATA_SOURCE_COUNT = 2 THEN 'PARTIAL'

        -- Single source only
        WHEN DATA_SOURCE_COUNT = 1 THEN 'SINGLE_SOURCE'

        ELSE 'UNKNOWN'
    END as DATA_QUALITY_FLAG

FROM loan_lead_guid llg
INNER JOIN all_fraud_loans afl ON llg.LOAN_ID = afl.LOAN_ID
LEFT JOIN custom_fields cf ON llg.LOAN_ID = cf.LOAN_ID
LEFT JOIN fraud_portfolios fp ON llg.LOAN_ID = fp.LOAN_ID
LEFT JOIN fraud_sub_status fss ON llg.LOAN_ID = fss.LOAN_ID;

-- ============================================================================
-- POST-DEPLOYMENT VALIDATION
-- ============================================================================

SELECT 'Production deployment complete. Running validation...' as status;

-- Verify row count matches development
SELECT
    'Row Count Validation' as test,
    COUNT(*) as production_count,
    'Expected: ~509' as expected
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD;

-- Verify fraud status distribution
SELECT
    'Fraud Status Distribution' as test,
    FRAUD_STATUS,
    COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
GROUP BY FRAUD_STATUS
ORDER BY loan_count DESC;

-- Verify EARLIEST_FRAUD_DATE working
SELECT
    'Earliest Fraud Date Validation' as test,
    COUNT(EARLIEST_FRAUD_DATE) as loans_with_date,
    'Expected: ~502' as expected
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD;

-- Sample confirmed fraud loans
SELECT
    'Sample Confirmed Fraud' as test,
    LOAN_ID,
    FRAUD_STATUS,
    IS_CONFIRMED_FRAUD,
    IS_ACTIVE_FRAUD
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
WHERE FRAUD_STATUS = 'CONFIRMED'
LIMIT 5;

SELECT '============================================' as summary;
SELECT 'PRODUCTION DEPLOYMENT COMPLETE' as summary;
SELECT '============================================' as summary;
