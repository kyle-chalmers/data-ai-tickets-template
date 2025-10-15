-- =====================================================================
-- Query: Cure Rate - First-Time Entry Cohort Analysis
-- Purpose: Track cure journey for accounts that first appear in each DPD bucket
-- Definition: Accounts first appearing in month M, track if/when they cure
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

first_appearance AS (
    -- Identify first time each account appears in each DPD bucket
    SELECT
        PAYOFFUID,
        LIST_NAME,
        test_group,
        MIN(LOAD_DATE) AS first_entry_date,
        DATE_TRUNC('MONTH', MIN(LOAD_DATE)) AS entry_cohort_month
    FROM
        call_list_data
    WHERE
        test_group IS NOT NULL
    GROUP BY
        PAYOFFUID,
        LIST_NAME,
        test_group
),

loan_tape_monthly AS (
    -- Get monthly DPD snapshots
    SELECT
        ASOFDATE,
        PAYOFFUID,
        DAYSPASTDUE
    FROM
        DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE
        ASOFDATE >= '2024-04-01'
),

cure_tracking AS (
    -- Track when accounts cure (reach DPD = 0)
    SELECT
        fa.PAYOFFUID,
        fa.LIST_NAME,
        fa.test_group,
        fa.first_entry_date,
        fa.entry_cohort_month,
        MIN(CASE WHEN ltm.DAYSPASTDUE = 0 THEN ltm.ASOFDATE END) AS cure_date,
        DATEDIFF(MONTH, fa.entry_cohort_month, MIN(CASE WHEN ltm.DAYSPASTDUE = 0 THEN ltm.ASOFDATE END)) AS months_to_cure
    FROM
        first_appearance fa
    LEFT JOIN
        loan_tape_monthly ltm
        ON fa.PAYOFFUID = ltm.PAYOFFUID
        AND ltm.ASOFDATE > fa.first_entry_date  -- Only look at snapshots after first entry
    GROUP BY
        fa.PAYOFFUID,
        fa.LIST_NAME,
        fa.test_group,
        fa.first_entry_date,
        fa.entry_cohort_month
)

-- Final output: Cohort cure rates by time period
SELECT
    entry_cohort_month,
    LIST_NAME AS dpd_bucket,
    test_group,
    COUNT(DISTINCT PAYOFFUID) AS cohort_size,
    COUNT(DISTINCT CASE WHEN cure_date IS NOT NULL THEN PAYOFFUID END) AS cured_count,
    COUNT(DISTINCT CASE WHEN months_to_cure = 1 THEN PAYOFFUID END) AS cured_1_month,
    COUNT(DISTINCT CASE WHEN months_to_cure = 2 THEN PAYOFFUID END) AS cured_2_months,
    COUNT(DISTINCT CASE WHEN months_to_cure = 3 THEN PAYOFFUID END) AS cured_3_months,
    COUNT(DISTINCT CASE WHEN months_to_cure >= 4 THEN PAYOFFUID END) AS cured_4plus_months,
    ROUND(COUNT(DISTINCT CASE WHEN cure_date IS NOT NULL THEN PAYOFFUID END) * 100.0 / NULLIF(COUNT(DISTINCT PAYOFFUID), 0), 2) AS overall_cure_rate_pct,
    ROUND(COUNT(DISTINCT CASE WHEN months_to_cure = 1 THEN PAYOFFUID END) * 100.0 / NULLIF(COUNT(DISTINCT PAYOFFUID), 0), 2) AS cure_rate_1_month_pct,
    ROUND(COUNT(DISTINCT CASE WHEN months_to_cure <= 2 THEN PAYOFFUID END) * 100.0 / NULLIF(COUNT(DISTINCT PAYOFFUID), 0), 2) AS cure_rate_2_months_pct,
    ROUND(COUNT(DISTINCT CASE WHEN months_to_cure <= 3 THEN PAYOFFUID END) * 100.0 / NULLIF(COUNT(DISTINCT PAYOFFUID), 0), 2) AS cure_rate_3_months_pct
FROM
    cure_tracking
GROUP BY
    entry_cohort_month,
    LIST_NAME,
    test_group
ORDER BY
    entry_cohort_month,
    LIST_NAME,
    test_group;

-- =====================================================================
-- Expected Output Columns:
-- - ENTRY_COHORT_MONTH: Month when accounts first appeared
-- - DPD_BUCKET: DPD3-14, DPD15-29, DPD30-59, DPD60-89
-- - TEST_GROUP: Test (Low Intensity) or Control (High Intensity)
-- - COHORT_SIZE: Total accounts in cohort
-- - CURED_COUNT: Number that eventually cured
-- - CURED_1_MONTH: Number that cured within 1 month
-- - CURED_2_MONTHS: Number that cured in exactly 2 months
-- - CURED_3_MONTHS: Number that cured in exactly 3 months
-- - CURED_4PLUS_MONTHS: Number that cured after 4+ months
-- - OVERALL_CURE_RATE_PCT: % that eventually cured
-- - CURE_RATE_1_MONTH_PCT: % that cured within 1 month
-- - CURE_RATE_2_MONTHS_PCT: % that cured within 2 months
-- - CURE_RATE_3_MONTHS_PCT: % that cured within 3 months
-- =====================================================================