-- ============================================================================
-- COMPREHENSIVE PENDING APPLICATIONS ANALYSIS QUERY
-- Generates detailed CSV data for 44 pending applications from August 7, 2025
-- ============================================================================

WITH 
-- Application list from CSV data
pending_apps AS (
    SELECT value::VARCHAR AS APPLICATION_ID
    FROM TABLE(FLATTEN(INPUT => PARSE_JSON('[
        "3012211","3012495","3016579","2963364","3014115","3016235","3016071",
        "2977446","3011634","3007232","3011932","3016798","3016931","3000933",
        "3003732","3014711","3017141","3012766","3017196","3015042","3016106",
        "3012386","3017586","3010286","3017275","3016050","3017833","3016038",
        "2927052","3013953","3015476","2955104","2993310","3018044","3011226",
        "3009787","3012842","3015898","2833697","3018403","3009694","2129780",
        "3018148","3001929"
    ]')))
),

-- Get basic application data from originations view
app_basic AS (
    SELECT 
        APPLICATION_ID,
        AMOUNT,
        TIER,
        UTM_SOURCE,
        PORTFOLIONAME AS CURRENT_PORTFOLIO_DISPLAY,
        LAST_TOUCH_UTM_CHANNEL_GROUPING AS CHANNEL_GROUPING
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_ORIGINATIONS_AND_PENDING_ORIGINATIONS_OPTIMIZED
    WHERE APPLICATION_ID IN (SELECT APPLICATION_ID FROM pending_apps)
        AND DATE = '2025-08-07'
        AND ORIGINATION_STATUS = 'Pending'
),

-- Get LOS portfolio assignments
los_portfolios AS (
    SELECT 
        APPLICATION_ID,
        COUNT(DISTINCT PORTFOLIO_ID) AS PORTFOLIO_COUNT,
        LISTAGG(PORTFOLIO_NAME, ', ') WITHIN GROUP (ORDER BY PORTFOLIO_NAME) AS PORTFOLIOS_LIST
    FROM ANALYTICS.VW_APP_PORTFOLIOS_AND_SUB_PORTFOLIOS P
    WHERE P.APPLICATION_ID IN (SELECT APPLICATION_ID FROM pending_apps)
    GROUP BY APPLICATION_ID
),

-- Get application status and timeline data
app_status AS (
    SELECT 
        A.APPLICATION_ID,
        A.APPLICATION_STARTED_DATETIME,
        A.FIRST_UNDERWRITING_DATETIME,
        A.FIRST_LOAN_DOCS_COMPLETED_DATETIME,
        A.LAST_LOAN_DOCS_COMPLETED_DATETIME,
        A.SELECTED_OFFER_AMOUNT,
        DATEDIFF('day', A.APPLICATION_STARTED_DATETIME, CURRENT_TIMESTAMP()) AS DAYS_SINCE_START,
        DATEDIFF('day', A.FIRST_UNDERWRITING_DATETIME, CURRENT_TIMESTAMP()) AS DAYS_IN_UNDERWRITING
    FROM ANALYTICS.VW_APPLICATION_STATUS_TRANSITION_WIP A
    WHERE A.APPLICATION_ID IN (SELECT APPLICATION_ID FROM pending_apps)
        AND A.SOURCE = 'LOANPRO'
),

-- Get current loan status
current_status AS (
    SELECT 
        C.LOAN_ID AS APPLICATION_ID,
        SS.TITLE AS CURRENT_STATUS,
        C.LAST_UPDATE,
        SCE.COMPANY_NAME AS CURRENT_PARTNER,
        DATEDIFF('hour', C.LAST_UPDATE, CURRENT_TIMESTAMP()) AS HOURS_SINCE_UPDATE
    FROM BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT C
    INNER JOIN BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT SS
        ON SS.ID = C.LOAN_SUB_STATUS_ID
        AND C.SCHEMA_NAME = SS.SCHEMA_NAME
    LEFT JOIN BRIDGE.VW_SOURCE_COMPANY_ENTITY_CURRENT SCE
        ON C.SOURCE_COMPANY = SCE.ID
        AND SCE.SCHEMA_NAME = CONFIG.LOS_SCHEMA()
    WHERE C.LOAN_ID IN (SELECT APPLICATION_ID FROM pending_apps)
),

-- Get custom loan settings for automation data
custom_settings AS (
    SELECT 
        CF.LOAN_ID AS APPLICATION_ID,
        CF.APPLICATION_STARTED_DATE,
        CF.AFFILIATE_STARTED_DATE_TIME,
        CF.UNDERWRITING_TIMER,
        CF.AUTOMATION_BANK_ACCOUNT_CHECK_STATUS,
        CF.AUTOMATION_IDENTITY_CHECK_STATUS,
        CF.AUTOMATION_INCOME_CHECK_STATUS,
        COALESCE(CF.REQUESTED_LOAN_AMOUNT, CF.SELECTED_OFFER_AMOUNT) AS LOAN_AMOUNT,
        CF.TIER,
        CF.UTM_SOURCE
    FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT CF
    WHERE CF.LOAN_ID IN (SELECT APPLICATION_ID FROM pending_apps)
),

-- Analyze patterns and categorize issues
analysis AS (
    SELECT 
        p.APPLICATION_ID,
        
        -- Basic data
        COALESCE(ab.AMOUNT, cs.LOAN_AMOUNT, ast.SELECTED_OFFER_AMOUNT) AS AMOUNT,
        COALESCE(ab.TIER, cs.TIER) AS TIER_RAW,
        CASE 
            WHEN COALESCE(ab.TIER, cs.TIER) = '1' THEN 'T1'
            WHEN COALESCE(ab.TIER, cs.TIER) = '2' THEN 'T2' 
            WHEN COALESCE(ab.TIER, cs.TIER) = '3' THEN 'T3'
            WHEN COALESCE(ab.TIER, cs.TIER) = '4' THEN 'T4'
            WHEN COALESCE(ab.TIER, cs.TIER) = '5' THEN 'T5'
            ELSE 'Unknown'
        END AS TIER_CATEGORY,
        COALESCE(ab.UTM_SOURCE, cs.UTM_SOURCE) AS UTM_SOURCE,
        ab.CHANNEL_GROUPING,
        COALESCE(ab.CURRENT_PORTFOLIO_DISPLAY, 'Not Yet Allocated') AS CURRENT_PORTFOLIO_DISPLAY,
        
        -- Portfolio analysis
        COALESCE(lp.PORTFOLIO_COUNT, 0) AS PORTFOLIO_COUNT_LOS,
        COALESCE(lp.PORTFOLIOS_LIST, 'None Found') AS LOS_PORTFOLIOS_LIST,
        
        -- Timeline analysis
        COALESCE(DATE(ast.APPLICATION_STARTED_DATETIME), DATE(cs.APPLICATION_STARTED_DATE)) AS ESTIMATED_START_DATE,
        DATE(ast.FIRST_UNDERWRITING_DATETIME) AS ESTIMATED_UNDERWRITING_DATE,
        COALESCE(ast.DAYS_IN_UNDERWRITING, 1) AS ESTIMATED_DAYS_PENDING,
        
        -- Age categorization
        CASE 
            WHEN p.APPLICATION_ID::NUMBER < 2900000 THEN 'Very Old'
            WHEN p.APPLICATION_ID::NUMBER < 3000000 THEN 'Old'
            WHEN p.APPLICATION_ID::NUMBER < 3010000 THEN 'Recent'
            ELSE 'Current'
        END AS APPLICATION_AGE_CATEGORY,
        
        -- Current status analysis
        cur.CURRENT_STATUS,
        cur.HOURS_SINCE_UPDATE,
        
        -- Priority calculation
        CASE 
            WHEN p.APPLICATION_ID IN ('2129780', '3018044', '3012211', '2927052', '3007232') THEN 'CRITICAL'
            WHEN COALESCE(ab.AMOUNT, cs.LOAN_AMOUNT, ast.SELECTED_OFFER_AMOUNT) >= 30000 
                 OR COALESCE(ab.TIER, cs.TIER) = '1' 
                 OR p.APPLICATION_ID::NUMBER < 3000000 THEN 'HIGH'
            WHEN COALESCE(ab.TIER, cs.TIER) IN ('2', '3') THEN 'MEDIUM'
            ELSE 'LOW'
        END AS PRIORITY_LEVEL,
        
        -- Issue identification
        CASE 
            WHEN lp.PORTFOLIOS_LIST LIKE '%Fraud%' THEN 'Fraud Team Review'
            WHEN lp.PORTFOLIO_COUNT = 0 THEN 'No Portfolios Found'
            WHEN lp.PORTFOLIO_COUNT = 1 AND lp.PORTFOLIOS_LIST = 'Ocrolus' THEN 'Income Verification'
            WHEN lp.PORTFOLIOS_LIST LIKE '%Auto Escalation%' THEN 'Auto Escalation'
            WHEN lp.PORTFOLIOS_LIST LIKE '%Document Review%' THEN 'Document Review'
            WHEN lp.PORTFOLIOS_LIST LIKE '%Pending Applicant Response%' THEN 'Document Collection'
            WHEN lp.PORTFOLIOS_LIST LIKE '%Review%' THEN 'Manual Review'
            WHEN lp.PORTFOLIOS_LIST LIKE '%Processing%' THEN 'Processing Queue'
            WHEN ab.CURRENT_PORTFOLIO_DISPLAY = 'Not Yet Allocated' THEN 'Portfolio Allocation'
            ELSE 'System Processing'
        END AS BLOCKING_ISSUE_PRIMARY,
        
        -- Automation status
        cs.AUTOMATION_BANK_ACCOUNT_CHECK_STATUS,
        cs.AUTOMATION_IDENTITY_CHECK_STATUS,
        cs.AUTOMATION_INCOME_CHECK_STATUS,
        
        -- Additional analysis fields
        lp.PORTFOLIOS_LIST,
        cur.CURRENT_PARTNER,
        COALESCE(ast.DAYS_SINCE_START, 1) AS DAYS_SINCE_START
        
    FROM pending_apps p
    LEFT JOIN app_basic ab ON p.APPLICATION_ID = ab.APPLICATION_ID
    LEFT JOIN los_portfolios lp ON p.APPLICATION_ID = lp.APPLICATION_ID
    LEFT JOIN app_status ast ON p.APPLICATION_ID = ast.APPLICATION_ID
    LEFT JOIN current_status cur ON p.APPLICATION_ID = cur.APPLICATION_ID
    LEFT JOIN custom_settings cs ON p.APPLICATION_ID = cs.APPLICATION_ID
)

-- Final output with all analysis columns
SELECT 
    APPLICATION_ID,
    AMOUNT,
    TIER_RAW,
    TIER_CATEGORY,
    UTM_SOURCE,
    CHANNEL_GROUPING,
    CURRENT_PORTFOLIO_DISPLAY,
    PORTFOLIO_COUNT_LOS,
    LOS_PORTFOLIOS_LIST,
    ESTIMATED_START_DATE,
    ESTIMATED_UNDERWRITING_DATE,
    ESTIMATED_DAYS_PENDING,
    APPLICATION_AGE_CATEGORY,
    PRIORITY_LEVEL,
    BLOCKING_ISSUE_PRIMARY,
    
    -- Secondary issue analysis
    CASE 
        WHEN BLOCKING_ISSUE_PRIMARY = 'Fraud Team Review' THEN 'Portfolio Allocation'
        WHEN BLOCKING_ISSUE_PRIMARY = 'No Portfolios Found' THEN 'System Error'
        WHEN BLOCKING_ISSUE_PRIMARY = 'Income Verification' AND APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN 'System Stuck'
        WHEN BLOCKING_ISSUE_PRIMARY = 'Portfolio Allocation' AND TIER_CATEGORY = 'T1' THEN 'Auto-Approval Failure'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Pending Applicant Response%' THEN 'Document Collection'
        ELSE 'None'
    END AS BLOCKING_ISSUE_SECONDARY,
    
    -- Verification status estimation
    CASE 
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Fraud%' THEN 'Failed Multiple'
        WHEN PORTFOLIO_COUNT_LOS = 0 THEN 'No Portfolio Data'
        WHEN PORTFOLIO_COUNT_LOS = 1 AND LOS_PORTFOLIOS_LIST = 'Ocrolus' THEN 'Stuck Single Portfolio'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Complete%' THEN 'Complete but Processing'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Pending%' THEN 'Pending Multiple'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Review%' THEN 'Under Review'
        WHEN APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN 'Failed Multiple'
        ELSE 'In Progress'
    END AS VERIFICATION_STATUS_ESTIMATED,
    
    -- Flags
    CASE WHEN LOS_PORTFOLIOS_LIST LIKE '%Fraud%' THEN TRUE ELSE FALSE END AS FRAUD_FLAG,
    
    -- Automation failures estimation
    CASE 
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Fraud%' THEN 'Fraud Detection + Income'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%GIACT%' THEN 'GIACT + Income'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Citizenship%' THEN 'Citizenship + Income'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%DOB%' THEN 'DOB Match + Income'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Auto Escalation%' THEN 'Auto Escalation + Income'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Income Bypass%' THEN 'Income Bypass Used'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Ocrolus%' THEN 'Income Verification'
        WHEN PORTFOLIO_COUNT_LOS = 0 THEN 'No Portfolio Assignment'
        ELSE 'None'
    END AS AUTOMATION_FAILURES_ESTIMATED,
    
    -- Customer action required
    CASE 
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Pending Applicant Response%' THEN 'Document Upload' 
        ELSE 'None' 
    END AS CUSTOMER_ACTION_REQUIRED,
    
    -- Partner capacity issues
    CASE 
        WHEN CURRENT_PORTFOLIO_DISPLAY IN ('First Tech FCU', 'Michigan State University FCU') THEN TRUE 
        ELSE FALSE 
    END AS PARTNER_CAPACITY_ISSUE,
    
    -- System stuck flag
    CASE 
        WHEN APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN TRUE
        WHEN PORTFOLIO_COUNT_LOS = 0 THEN TRUE
        WHEN PORTFOLIO_COUNT_LOS = 1 AND APPLICATION_ID::NUMBER < 3000000 THEN TRUE
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Complete%' AND CURRENT_PORTFOLIO_DISPLAY = 'Not Yet Allocated' THEN TRUE
        ELSE FALSE 
    END AS SYSTEM_STUCK_FLAG,
    
    -- Business impact description
    CASE 
        WHEN APPLICATION_ID = '2129780' THEN 'Oldest App Critical'
        WHEN APPLICATION_ID = '3018044' THEN 'Highest Value Same Day No Portfolio'
        WHEN APPLICATION_ID = '3012211' THEN 'High Value T1 Fraud Flag'
        WHEN AMOUNT >= 35000 AND TIER_CATEGORY = 'T1' THEN 'High Value T1'
        WHEN AMOUNT >= 30000 AND APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN 'High Value Old App'
        WHEN TIER_CATEGORY = 'T1' AND CURRENT_PORTFOLIO_DISPLAY = 'Not Yet Allocated' THEN 'T1 Not Allocated'
        WHEN AMOUNT >= 30000 THEN 'High Value'
        WHEN APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN 'Old App'
        ELSE 'Standard'
    END AS BUSINESS_IMPACT,
    
    -- Resolution complexity
    CASE 
        WHEN APPLICATION_ID IN ('2129780', '3018044', '3012211', '2927052') THEN 'Critical'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Fraud%' OR PORTFOLIO_COUNT_LOS = 0 THEN 'High'
        WHEN APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN 'High'
        WHEN TIER_CATEGORY IN ('T1', 'T2') AND CURRENT_PORTFOLIO_DISPLAY = 'Not Yet Allocated' THEN 'Medium'
        ELSE 'Low'
    END AS RESOLUTION_COMPLEXITY,
    
    -- Immediate action required
    CASE 
        WHEN APPLICATION_ID = '2129780' THEN 'Immediate Manual Override'
        WHEN APPLICATION_ID = '3012211' THEN 'Manual Fraud Review'
        WHEN APPLICATION_ID = '3018044' THEN 'Immediate System Investigation'
        WHEN APPLICATION_ID = '2927052' THEN 'Manual Override'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Fraud%' THEN 'Fraud Review'
        WHEN PORTFOLIO_COUNT_LOS = 0 AND TIER_CATEGORY = 'T1' THEN 'System Investigation'
        WHEN PORTFOLIO_COUNT_LOS = 0 THEN 'System Investigation'
        WHEN TIER_CATEGORY = 'T1' AND CURRENT_PORTFOLIO_DISPLAY = 'Not Yet Allocated' THEN 'Force Allocation'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Pending Applicant Response%' THEN 'Doc Outreach'
        WHEN APPLICATION_AGE_CATEGORY IN ('Old', 'Very Old') THEN 'Manual Investigation'
        ELSE 'Standard Processing'
    END AS IMMEDIATE_ACTION_REQUIRED,
    
    -- Notes field with detailed analysis
    CASE 
        WHEN APPLICATION_ID = '2129780' THEN 'OLDEST APPLICATION - stuck in Ocrolus income verification for 300+ days'
        WHEN APPLICATION_ID = '3012211' THEN 'Prime customer falsely flagged for fraud despite T1 tier and CREDIBLE source'
        WHEN APPLICATION_ID = '3018044' THEN 'Highest value T1 same-day application with no portfolio assignment - critical system error'
        WHEN APPLICATION_ID = '2927052' THEN 'Highest value old application stuck in GIACT bank verification for over 30 days'
        WHEN LOS_PORTFOLIOS_LIST LIKE '%Fraud%' THEN 'Application flagged for fraud team review'
        WHEN PORTFOLIO_COUNT_LOS = 0 AND CURRENT_PORTFOLIO_DISPLAY != 'Not Yet Allocated' THEN 'Allocated to partner but no LOS portfolio data'
        WHEN PORTFOLIO_COUNT_LOS = 0 THEN 'No portfolio data found - potential system error'
        WHEN PORTFOLIO_COUNT_LOS = 1 AND LOS_PORTFOLIOS_LIST = 'Ocrolus' AND AMOUNT >= 30000 THEN 'High-value stuck in single Ocrolus portfolio - system error'
        WHEN APPLICATION_AGE_CATEGORY = 'Very Old' THEN 'Very old application requiring immediate investigation'
        WHEN APPLICATION_AGE_CATEGORY = 'Old' THEN 'Old application with extended processing delays'
        WHEN TIER_CATEGORY = 'T1' AND CURRENT_PORTFOLIO_DISPLAY = 'Not Yet Allocated' THEN 'Prime customer should be auto-approved but stuck in allocation'
        ELSE 'Standard pending application processing'
    END AS NOTES

FROM analysis
ORDER BY 
    CASE PRIORITY_LEVEL 
        WHEN 'CRITICAL' THEN 1 
        WHEN 'HIGH' THEN 2 
        WHEN 'MEDIUM' THEN 3 
        ELSE 4 
    END,
    AMOUNT DESC;

-- ============================================================================
-- USAGE NOTES:
-- 1. This query combines data from multiple sources to create comprehensive analysis
-- 2. Some columns use estimation logic based on patterns observed in the data
-- 3. The APPLICATION_ID list should be updated for different date ranges
-- 4. Priority and issue classification logic can be adjusted based on business rules
-- 5. Query may timeout on large datasets - consider adding date filters
-- ============================================================================