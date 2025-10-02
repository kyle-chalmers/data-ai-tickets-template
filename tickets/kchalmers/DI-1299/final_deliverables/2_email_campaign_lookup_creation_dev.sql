-- DI-1299: Create Email Campaign DPD Lookup Table (Development)
-- Purpose: Replace hard-coded CASE statements with maintainable lookup table
-- Environment: BUSINESS_INTELLIGENCE_DEV database
-- Note: This simplifies the current 2,901 hard-coded campaign mappings

-- Step 1: Create lookup table structure
CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE_DEV.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING (
    CAMPAIGN_NAME VARCHAR(16777216) PRIMARY KEY,
    DPD_BUCKET VARCHAR(50),
    DPD_MIN INT,
    DPD_MAX INT,
    SPECIAL_RULE VARCHAR(200),
    ACTIVE_FLAG BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Step 2: Populate with campaign pattern parsing logic
-- Note: This automated mapping will require manual review for unmapped campaigns
INSERT INTO BUSINESS_INTELLIGENCE_DEV.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING (
    CAMPAIGN_NAME,
    DPD_BUCKET,
    DPD_MIN,
    DPD_MAX,
    SPECIAL_RULE,
    ACTIVE_FLAG,
    CREATED_DATE,
    UPDATED_DATE
)
SELECT DISTINCT
    SEND_TABLE_EMAIL_NAME as CAMPAIGN_NAME,
    -- Pattern-based DPD bucket inference
    CASE
        -- DPD3-14 patterns
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%3Days%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%3-14%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%4-14%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%5Days%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%10Days%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%Day5%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%Day10%'
            THEN 'DPD3-14'
        -- DPD15-29 patterns
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%15-29%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%25Days%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%Day25%'
            THEN 'DPD15-29'
        -- DPD30-59 patterns
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-59%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%45Days%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%59Days%'
            THEN 'DPD30-59'
        -- DPD60-89 patterns
        WHEN (SEND_TABLE_EMAIL_NAME LIKE '%60Days%' OR SEND_TABLE_EMAIL_NAME LIKE '%Day60%')
            AND SEND_TABLE_EMAIL_NAME NOT LIKE '%60Plus%'
            AND SEND_TABLE_EMAIL_NAME NOT LIKE '%90%'
            THEN 'DPD60-89'
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%40-60%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%30-60%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%Day75%'
            THEN 'DPD60-89'
        -- DPD90+ patterns
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60Plus%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%90%'
            THEN 'DPD90+'
        -- Current patterns
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%0-3Days%'
            THEN 'Current'
        -- Requires manual review
        ELSE NULL
    END as DPD_BUCKET,
    -- DPD_MIN based on bucket
    CASE
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%3-14%' OR SEND_TABLE_EMAIL_NAME LIKE '%3Days%'
            OR SEND_TABLE_EMAIL_NAME LIKE '%4-14%' THEN 3
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%15-29%' THEN 15
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-59%' OR SEND_TABLE_EMAIL_NAME LIKE '%30-60%' THEN 30
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%40-60%' THEN 40
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60%' THEN 60
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%90%' OR SEND_TABLE_EMAIL_NAME LIKE '%60Plus%' THEN 90
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%0-3%' THEN 0
    END as DPD_MIN,
    -- DPD_MAX based on bucket
    CASE
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%3-14%' OR SEND_TABLE_EMAIL_NAME LIKE '%4-14%' THEN 14
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%15-29%' THEN 29
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-59%' THEN 59
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-60%' OR SEND_TABLE_EMAIL_NAME LIKE '%40-60%' THEN 60
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60-89%' THEN 89
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%90%' OR SEND_TABLE_EMAIL_NAME LIKE '%60Plus%' THEN 9999
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%0-3%' THEN 3
    END as DPD_MAX,
    -- Special rules for complex patterns
    CASE
        WHEN SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225')
            THEN 'Requires DPD range validation against loan DPD'
        WHEN SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_0-3Days_EM1_0823','GR_Batch_DLQ_PastDue_0-3Days_EM1_1123',
                                        'GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123')
            THEN 'Multi-bucket campaign - use loan status for determination'
        ELSE NULL
    END as SPECIAL_RULE,
    TRUE as ACTIVE_FLAG,
    CURRENT_TIMESTAMP() as CREATED_DATE,
    CURRENT_TIMESTAMP() as UPDATED_DATE
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS
WHERE SEND_TABLE_EMAIL_NAME IS NOT NULL;

-- Step 3: Review campaigns that need manual classification
SELECT
    'Unmapped Campaigns Requiring Manual Review' as info,
    COUNT(*) as unmapped_count
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING
WHERE DPD_BUCKET IS NULL;

-- Show sample unmapped campaigns for manual review
SELECT
    CAMPAIGN_NAME,
    DPD_BUCKET,
    SPECIAL_RULE
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING
WHERE DPD_BUCKET IS NULL
ORDER BY CAMPAIGN_NAME
LIMIT 50;

-- Step 4: Summary statistics
SELECT
    'Lookup Table Summary' as info,
    COUNT(*) as total_campaigns,
    COUNT(CASE WHEN DPD_BUCKET IS NOT NULL THEN 1 END) as mapped_campaigns,
    COUNT(CASE WHEN DPD_BUCKET IS NULL THEN 1 END) as unmapped_campaigns,
    ROUND(COUNT(CASE WHEN DPD_BUCKET IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as pct_mapped
FROM BUSINESS_INTELLIGENCE_DEV.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING;
