-- =====================================================================
-- Query: Delinquency Curve Analysis
-- Purpose: Track delinquency progression from DPD 3 over time by test/control group
-- Definition: For accounts starting at DPD 3, track how long it takes to cure
-- Analysis Period: April 2024 - Present
-- =====================================================================

WITH testing AS (
    SELECT
        lt1.payoffuid,
        CASE
            WHEN SUBSTRING(lt1.PAYOFFUID, 17, 1) IN ('0','1','2','3','4','5','6','7','8','9','a','b','c')
            THEN 'Test (Low Intensity) in DPD3-29'
            WHEN SUBSTRING(lt1.PAYOFFUID, 17, 1) IN ('d','e','f')
            THEN 'Control (High Intensity) in DPD3-29'
        END AS test_group,
        DATE_TRUNC(quarter, lt1.asofdate) AS dq_vintage,
        lt1.asofdate AS starting_dq_date,
        lt1.dayspastdue AS dpd_starting,
        lt2.asofdate AS later_date,
        lt2.dayspastdue AS dpd_reached,
        DATEDIFF(day, lt1.asofdate, lt2.asofdate) + 3 AS dpd_sim,
        MAX(starting_dq_date) OVER (PARTITION BY dq_vintage) AS last_daily_vintage,
        CASE
            WHEN dpd_reached = dpd_sim THEN lt2.payoffuid
            ELSE NULL
        END AS loan_reached_dpd_sim
    FROM
        "BUSINESS_INTELLIGENCE"."DATA_STORE"."MVW_LOAN_TAPE_DAILY_HISTORY" AS lt1
    LEFT JOIN
        "BUSINESS_INTELLIGENCE"."DATA_STORE"."MVW_LOAN_TAPE_DAILY_HISTORY" AS lt2
        ON lt1.payoffuid = lt2.payoffuid
        AND lt2.asofdate > lt1.asofdate
    WHERE
        lt1.asofdate >= '2024-04-01'
        AND lt1.dayspastdue = 3
        AND lt2.dayspastdue <= 119
        AND lt1.payoffuid IN (
            SELECT payoffuid
            FROM cron_store.RPT_OUTBOUND_LISTS_HIST
            WHERE SET_NAME = 'Call List'
                AND LIST_NAME IN ('DPD3-14', 'DPD15-29')
                AND SUPPRESSION_FLAG = FALSE
                AND LOAD_DATE >= '2024-04-01'
        )
    ORDER BY 1, starting_dq_date, later_date
),

cutoff AS (
    SELECT
        starting_dq_date,
        test_group,
        MAX(dpd_sim) AS cutoff
    FROM testing
    GROUP BY 1, 2
    ORDER BY 1, 2
),

agg AS (
    SELECT
        dq_vintage,
        t.test_group,
        last_daily_vintage,
        dpd_sim,
        cutoff,
        COUNT(payoffuid) AS vintage_start_count,
        COUNT(loan_reached_dpd_sim) AS dpd_curve_count
    FROM
        testing AS t
    LEFT JOIN
        cutoff AS c
        ON t.last_daily_vintage = c.starting_dq_date
        AND t.test_group = c.test_group
    GROUP BY 1, 2, 3, 4, 5
    ORDER BY 1, 2, 3, 4, 5
)

SELECT *
FROM agg
WHERE dpd_sim <= cutoff
    AND dpd_sim <= 119
ORDER BY 1, 2, 3, 4, 5, 6, 7;

-- =====================================================================
-- Expected Output Columns:
-- - DQ_VINTAGE: Quarter when accounts started at DPD 3
-- - TEST_GROUP: Test (Low Intensity) or Control (High Intensity) in DPD3-29
-- - LAST_DAILY_VINTAGE: Last date in the vintage quarter
-- - DPD_SIM: Simulated DPD days (days since starting at DPD 3 + 3)
-- - CUTOFF: Maximum DPD_SIM for this vintage/group
-- - VINTAGE_START_COUNT: Number of accounts that started at DPD 3
-- - DPD_CURVE_COUNT: Number of accounts that reached the simulated DPD level
--
-- Purpose: Create delinquency curves showing what % of accounts reach each
-- DPD level over time, comparing test vs control calling strategies
-- =====================================================================
