-- Test to compare optimized vs original query performance and validate identical results
-- This will test both the dynamic table optimization and view optimization

-- Test 1: Dynamic Table - Row Count Comparison
WITH original_simm_placements AS (
    SELECT 
        PAYOFFUID,
        MIN(LOAN_TAPE_ASOFDATE) as FIRST_SIMM_DATE
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM'
        AND SUPPRESSION_FLAG = FALSE
    GROUP BY PAYOFFUID
),
-- Original approach: Two separate joins for SIMM data
original_approach AS (
    SELECT COUNT(*) as record_count,
           SUM(CASE WHEN simm_current.PAYOFFUID IS NOT NULL THEN 1 ELSE 0 END) as current_simm_count,
           SUM(CASE WHEN simm_historical.PAYOFFUID IS NOT NULL AND dt.ASOFDATE >= simm_historical.FIRST_SIMM_DATE THEN 1 ELSE 0 END) as historical_simm_count
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION dt
    LEFT JOIN BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST simm_current
        ON simm_current.SET_NAME = 'SIMM' 
        AND simm_current.SUPPRESSION_FLAG = FALSE
        AND simm_current.PAYOFFUID = dt.PAYOFFUID
        AND simm_current.LOAN_TAPE_ASOFDATE = dt.ASOFDATE
    LEFT JOIN original_simm_placements simm_historical ON dt.PAYOFFUID = simm_historical.PAYOFFUID
    WHERE dt.ASOFDATE = '2025-07-30'
),
-- Optimized approach: Single join with consolidated SIMM data
optimized_simm_data AS (
    SELECT 
        PAYOFFUID,
        LOAN_TAPE_ASOFDATE,
        MIN(LOAN_TAPE_ASOFDATE) OVER (PARTITION BY PAYOFFUID) as FIRST_SIMM_DATE
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM'
        AND SUPPRESSION_FLAG = FALSE
),
optimized_approach AS (
    SELECT COUNT(*) as record_count,
           SUM(CASE WHEN s.LOAN_TAPE_ASOFDATE = dt.ASOFDATE THEN 1 ELSE 0 END) as current_simm_count,
           SUM(CASE WHEN s.PAYOFFUID IS NOT NULL AND dt.ASOFDATE >= s.FIRST_SIMM_DATE THEN 1 ELSE 0 END) as historical_simm_count
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION dt
    LEFT JOIN optimized_simm_data s
        ON dt.PAYOFFUID = s.PAYOFFUID
        AND (s.LOAN_TAPE_ASOFDATE = dt.ASOFDATE OR dt.ASOFDATE >= s.FIRST_SIMM_DATE)
    WHERE dt.ASOFDATE = '2025-07-30'
)
SELECT 
    'DYNAMIC TABLE COMPARISON' as test_type,
    o.record_count as original_records,
    op.record_count as optimized_records,
    o.record_count - op.record_count as record_difference,
    o.current_simm_count as original_current_simm,
    op.current_simm_count as optimized_current_simm,
    o.current_simm_count - op.current_simm_count as current_simm_difference,
    o.historical_simm_count as original_historical_simm,
    op.historical_simm_count as optimized_historical_simm,
    o.historical_simm_count - op.historical_simm_count as historical_simm_difference
FROM original_approach o, optimized_approach op;

-- Test 2: Monthly View - Row Count Comparison
WITH original_monthly_simm AS (
    SELECT DISTINCT 
        PAYOFFUID,
        DATE_TRUNC('MONTH', LOAN_TAPE_ASOFDATE) as SIMM_MONTH
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM' 
        AND SUPPRESSION_FLAG = FALSE
),
monthly_simm_placements AS (
    SELECT 
        PAYOFFUID,
        MIN(LOAN_TAPE_ASOFDATE) as FIRST_SIMM_DATE
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM'
        AND SUPPRESSION_FLAG = FALSE
    GROUP BY PAYOFFUID
),
-- Original monthly approach with subquery
original_monthly AS (
    SELECT COUNT(*) as record_count,
           COUNT(CASE WHEN simm_current.PAYOFFUID IS NOT NULL THEN 1 END) as current_simm_count,
           COUNT(CASE WHEN simm_historical.PAYOFFUID IS NOT NULL AND B.ASOFDATE >= simm_historical.FIRST_SIMM_DATE THEN 1 END) as historical_simm_count
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING A
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY B
        ON LAST_DAY(DATE(A.DATECURRENT)) = LAST_DAY(DATE(B.ASOFDATE))
        AND A.PAYOFFUID = B.PAYOFFUID
    LEFT JOIN original_monthly_simm simm_current 
        ON A.PAYOFFUID = simm_current.PAYOFFUID 
        AND DATE_TRUNC('MONTH', B.ASOFDATE) = simm_current.SIMM_MONTH
    LEFT JOIN monthly_simm_placements simm_historical ON A.PAYOFFUID = simm_historical.PAYOFFUID
    WHERE B.ASOFDATE = '2025-06-30'
        AND ROUND(MONTHS_BETWEEN(LAST_DAY(DATE(A.DATECURRENT)), LAST_DAY(DATE(A.DATEPREVIOUS))),0) = 1
),
-- Optimized monthly approach with CTEs
optimized_monthly_simm AS (
    SELECT 
        PAYOFFUID,
        DATE_TRUNC('MONTH', LOAN_TAPE_ASOFDATE) as SIMM_MONTH
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM' 
        AND SUPPRESSION_FLAG = FALSE
    GROUP BY PAYOFFUID, DATE_TRUNC('MONTH', LOAN_TAPE_ASOFDATE)
),
optimized_monthly AS (
    SELECT COUNT(*) as record_count,
           COUNT(CASE WHEN simm_current.PAYOFFUID IS NOT NULL THEN 1 END) as current_simm_count,
           COUNT(CASE WHEN simm_historical.PAYOFFUID IS NOT NULL AND B.ASOFDATE >= simm_historical.FIRST_SIMM_DATE THEN 1 END) as historical_simm_count
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.VW_DSH_MONTHLY_ROLL_RATE_MONITORING A
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY B
        ON LAST_DAY(DATE(A.DATECURRENT)) = LAST_DAY(DATE(B.ASOFDATE))
        AND A.PAYOFFUID = B.PAYOFFUID
    LEFT JOIN optimized_monthly_simm simm_current 
        ON A.PAYOFFUID = simm_current.PAYOFFUID 
        AND DATE_TRUNC('MONTH', B.ASOFDATE) = simm_current.SIMM_MONTH
    LEFT JOIN monthly_simm_placements simm_historical ON A.PAYOFFUID = simm_historical.PAYOFFUID
    WHERE B.ASOFDATE = '2025-06-30'
        AND ROUND(MONTHS_BETWEEN(LAST_DAY(DATE(A.DATECURRENT)), LAST_DAY(DATE(A.DATEPREVIOUS))),0) = 1
)
SELECT 
    'MONTHLY VIEW COMPARISON' as test_type,
    om.record_count as original_records,
    opm.record_count as optimized_records,
    om.record_count - opm.record_count as record_difference,
    om.current_simm_count as original_current_simm,
    opm.current_simm_count as optimized_current_simm,
    om.current_simm_count - opm.current_simm_count as current_simm_difference,
    om.historical_simm_count as original_historical_simm,
    opm.historical_simm_count as optimized_historical_simm,
    om.historical_simm_count - opm.historical_simm_count as historical_simm_difference
FROM original_monthly om, optimized_monthly opm;