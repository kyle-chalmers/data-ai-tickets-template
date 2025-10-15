-- =====================================================================
-- Query: Daily Group Size Trends
-- Purpose: Track daily count of accounts in each test/control group by DPD bucket
-- Analysis Period: April 2024 - Present
-- =====================================================================

WITH call_list_data AS (
    SELECT
        LOAD_DATE,
        LIST_NAME,
        PAYOFFUID,
        -- Identify test/control group based on DPD bucket
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
)

SELECT
    LOAD_DATE,
    LIST_NAME AS dpd_bucket,
    test_group,
    COUNT(DISTINCT PAYOFFUID) AS account_count
FROM
    call_list_data
WHERE
    test_group IS NOT NULL  -- Filter out any accounts that don't match criteria
GROUP BY
    LOAD_DATE,
    LIST_NAME,
    test_group
ORDER BY
    LOAD_DATE,
    LIST_NAME,
    test_group;

-- =====================================================================
-- Expected Output Columns:
-- - LOAD_DATE: Date of call list generation
-- - DPD_BUCKET: DPD3-14, DPD15-29, DPD30-59, DPD60-89
-- - TEST_GROUP: Test (Low Intensity) or Control (High Intensity)
-- - ACCOUNT_COUNT: Number of unique accounts in that group on that day
-- =====================================================================