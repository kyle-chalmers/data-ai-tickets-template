-- =====================================================================
-- Query: Cure Rate - Rolling Monthly Performance
-- Purpose: Track cure rate in the next month since first appearance
-- Definition: % of accounts that cured in the next month after appearing in call list
-- Example: Account in April call list → Check if DPD = 0 in May snapshot
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
    -- Get unique accounts per month in call lists
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

loan_tape_monthly AS (
    -- Get monthly DPD snapshots
    SELECT
        DATE_TRUNC('MONTH', ASOFDATE) AS snapshot_month,
        PAYOFFUID,
        DAYSPASTDUE
    FROM
        DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE
        ASOFDATE >= '2024-04-01'
),

cure_next_month AS (
    -- Check if accounts cured in the next month
    SELECT
        mcl.call_list_month,
        mcl.LIST_NAME,
        mcl.test_group,
        mcl.PAYOFFUID,
        ltm.DAYSPASTDUE AS next_month_dpd,
        CASE
            WHEN ltm.DAYSPASTDUE = 0 THEN 1
            ELSE 0
        END AS cured_flag
    FROM
        monthly_call_list mcl
    LEFT JOIN
        loan_tape_monthly ltm
        ON mcl.PAYOFFUID = ltm.PAYOFFUID
        AND ltm.snapshot_month = DATEADD(MONTH, 1, mcl.call_list_month)  -- Next month
)

-- Final output: Monthly cure rates
SELECT
    call_list_month,
    LIST_NAME AS dpd_bucket,
    test_group,
    COUNT(DISTINCT PAYOFFUID) AS total_accounts,
    COUNT(DISTINCT CASE WHEN cured_flag = 1 THEN PAYOFFUID END) AS cured_count,
    COUNT(DISTINCT CASE WHEN cured_flag = 0 THEN PAYOFFUID END) AS not_cured_count,
    COUNT(DISTINCT CASE WHEN next_month_dpd IS NULL THEN PAYOFFUID END) AS no_data_count,
    ROUND(COUNT(DISTINCT CASE WHEN cured_flag = 1 THEN PAYOFFUID END) * 100.0 /
          NULLIF(COUNT(DISTINCT CASE WHEN next_month_dpd IS NOT NULL THEN PAYOFFUID END), 0), 2) AS cure_rate_pct
FROM
    cure_next_month
GROUP BY
    call_list_month,
    LIST_NAME,
    test_group
ORDER BY
    call_list_month,
    LIST_NAME,
    test_group;

-- =====================================================================
-- Expected Output Columns:
-- - CALL_LIST_MONTH: Month when accounts appeared in call list
-- - DPD_BUCKET: DPD3-14, DPD15-29, DPD30-59, DPD60-89
-- - TEST_GROUP: Test (Low Intensity) or Control (High Intensity)
-- - TOTAL_ACCOUNTS: Total unique accounts in call list that month
-- - CURED_COUNT: Number that cured in the next month
-- - NOT_CURED_COUNT: Number that did not cure in the next month
-- - NO_DATA_COUNT: Number with no data in next month (loan closed, etc.)
-- - CURE_RATE_PCT: % that cured in the next month (excluding no data)
-- =====================================================================