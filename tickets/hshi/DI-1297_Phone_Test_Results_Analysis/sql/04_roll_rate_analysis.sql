-- =====================================================================
-- Query: Roll Rate Analysis
-- Purpose: Track forward progression through delinquency stages
-- Definition: Consecutive month transitions to higher DPD buckets
-- Transitions: DPD 3-14 → DPD 15-29 → DPD 30-59 → DPD 60-89
-- Analysis Period: April 2024 - Present
-- =====================================================================

WITH call_list_data AS (
    -- Get all call list records with test/control group assignment
    SELECT
        LOAD_DATE,
        LIST_NAME,
        PAYOFFUID,
        CASE
            WHEN LIST_NAME IN ('DPD3-14', 'DPD15-29') THEN
                CASE
                    WHEN SUBSTRING(PAYOFFUID, 17, 1) IN ('0','1','2','3','4','5','6','7','8','9','a','b','c')
                    THEN 'Test (Low Intensity)'
                    WHEN SUBSTRING(PAYOFFUID, 17, 1) IN ('d','e','f')
                    THEN 'Control (High Intensity)'
                END
            WHEN LIST_NAME IN ('DPD30-59', 'DPD60-89') THEN
                CASE
                    WHEN SUBSTRING(PAYOFFUID, 12, 1) IN ('0','1','2')
                    THEN 'Test (Low Intensity)'
                    WHEN SUBSTRING(PAYOFFUID, 12, 1) IN ('3','4','5','6','7','8','9','a','b','c','d','e','f')
                    THEN 'Control (High Intensity)'
                END
        END AS test_group
    FROM
        CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE
        SET_NAME = 'Call List'
        AND LIST_NAME IN ('DPD3-14', 'DPD15-29', 'DPD30-59', 'DPD60-89')
        AND SUPPRESSION_FLAG = FALSE
        AND LOAD_DATE >= '2024-04-01'
),

monthly_call_list AS (
    -- Get unique accounts per month in call lists with their DPD bucket
    SELECT DISTINCT
        DATE_TRUNC('MONTH', LOAD_DATE) AS call_list_month,
        LIST_NAME,
        test_group,
        PAYOFFUID
    FROM
        call_list_data
    WHERE
        test_group IS NOT NULL
),

current_and_next_month AS (
    -- Join current month with next month to identify transitions
    SELECT
        curr.call_list_month AS current_month,
        curr.LIST_NAME AS current_dpd_bucket,
        curr.test_group,
        curr.PAYOFFUID,
        next.LIST_NAME AS next_month_dpd_bucket
    FROM
        monthly_call_list curr
    LEFT JOIN
        monthly_call_list next
        ON curr.PAYOFFUID = next.PAYOFFUID
        AND next.call_list_month = DATEADD(MONTH, 1, curr.call_list_month)
        AND curr.test_group = next.test_group  -- Keep same test group
),

roll_classification AS (
    -- Classify transitions
    SELECT
        current_month,
        current_dpd_bucket,
        test_group,
        PAYOFFUID,
        next_month_dpd_bucket,
        CASE
            -- Define forward roll transitions
            WHEN current_dpd_bucket = 'DPD3-14' AND next_month_dpd_bucket = 'DPD15-29' THEN 'Rolled Forward'
            WHEN current_dpd_bucket = 'DPD15-29' AND next_month_dpd_bucket = 'DPD30-59' THEN 'Rolled Forward'
            WHEN current_dpd_bucket = 'DPD30-59' AND next_month_dpd_bucket = 'DPD60-89' THEN 'Rolled Forward'
            WHEN next_month_dpd_bucket IS NULL THEN 'No Data Next Month'
            ELSE 'Did Not Roll Forward'
        END AS roll_status,
        CASE
            WHEN current_dpd_bucket = 'DPD3-14' AND next_month_dpd_bucket = 'DPD15-29' THEN 'DPD3-14 → DPD15-29'
            WHEN current_dpd_bucket = 'DPD15-29' AND next_month_dpd_bucket = 'DPD30-59' THEN 'DPD15-29 → DPD30-59'
            WHEN current_dpd_bucket = 'DPD30-59' AND next_month_dpd_bucket = 'DPD60-89' THEN 'DPD30-59 → DPD60-89'
            ELSE NULL
        END AS transition_type
    FROM
        current_and_next_month
)

-- Final output: Roll rates by month and DPD bucket
SELECT
    current_month,
    current_dpd_bucket,
    test_group,
    COUNT(DISTINCT PAYOFFUID) AS total_accounts,
    COUNT(DISTINCT CASE WHEN roll_status = 'Rolled Forward' THEN PAYOFFUID END) AS rolled_forward_count,
    COUNT(DISTINCT CASE WHEN roll_status = 'Did Not Roll Forward' THEN PAYOFFUID END) AS did_not_roll_count,
    COUNT(DISTINCT CASE WHEN roll_status = 'No Data Next Month' THEN PAYOFFUID END) AS no_data_count,
    ROUND(COUNT(DISTINCT CASE WHEN roll_status = 'Rolled Forward' THEN PAYOFFUID END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN next_month_dpd_bucket IS NOT NULL THEN PAYOFFUID END), 0), 2) AS roll_rate_pct,
    -- Show the transition type for reference
    CASE
        WHEN current_dpd_bucket = 'DPD3-14' THEN 'DPD3-14 → DPD15-29'
        WHEN current_dpd_bucket = 'DPD15-29' THEN 'DPD15-29 → DPD30-59'
        WHEN current_dpd_bucket = 'DPD30-59' THEN 'DPD30-59 → DPD60-89'
    END AS transition_type
FROM
    roll_classification
WHERE
    current_dpd_bucket IN ('DPD3-14', 'DPD15-29', 'DPD30-59')  -- Exclude DPD60-89 as it has no forward bucket
GROUP BY
    current_month,
    current_dpd_bucket,
    test_group
ORDER BY
    current_month,
    current_dpd_bucket,
    test_group;

-- =====================================================================
-- Expected Output Columns:
-- - CURRENT_MONTH: Month of the current DPD bucket
-- - CURRENT_DPD_BUCKET: Starting DPD bucket (DPD3-14, DPD15-29, DPD30-59)
-- - TEST_GROUP: Test (Low Intensity) or Control (High Intensity)
-- - TRANSITION_TYPE: The specific roll transition (e.g., "DPD3-14 → DPD15-29")
-- - TOTAL_ACCOUNTS: Total accounts in current bucket that month
-- - ROLLED_FORWARD_COUNT: Number that rolled to next higher bucket
-- - DID_NOT_ROLL_COUNT: Number that stayed or improved
-- - NO_DATA_COUNT: Number with no data in next month
-- - ROLL_RATE_PCT: % that rolled forward (excluding no data)
-- =====================================================================