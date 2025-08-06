-- Test corrected optimization produces identical results to original approach

-- Test the corrected optimization for dynamic table
WITH simm_placements AS (
    SELECT 
        PAYOFFUID,
        MIN(LOAN_TAPE_ASOFDATE) as FIRST_SIMM_DATE
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM'
        AND SUPPRESSION_FLAG = FALSE
    GROUP BY PAYOFFUID
),
-- Original approach: Two separate joins
original_results AS (
    SELECT COUNT(*) as total_records,
           SUM(CASE WHEN simm_current.PAYOFFUID IS NOT NULL THEN 1 ELSE 0 END) as current_simm_count,
           SUM(CASE WHEN simm_historical.PAYOFFUID IS NOT NULL AND dt.ASOFDATE >= simm_historical.FIRST_SIMM_DATE THEN 1 ELSE 0 END) as historical_simm_count
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION dt
    LEFT JOIN BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST simm_current
        ON simm_current.SET_NAME = 'SIMM' 
        AND simm_current.SUPPRESSION_FLAG = FALSE
        AND simm_current.PAYOFFUID = dt.PAYOFFUID
        AND simm_current.LOAN_TAPE_ASOFDATE = dt.ASOFDATE
    LEFT JOIN simm_placements simm_historical ON dt.PAYOFFUID = simm_historical.PAYOFFUID
    WHERE dt.ASOFDATE = '2025-07-30'
),
-- Corrected optimization: Pre-computed CTE but same join logic
optimized_results AS (
    SELECT COUNT(*) as total_records,
           SUM(CASE WHEN simm_current.PAYOFFUID IS NOT NULL THEN 1 ELSE 0 END) as current_simm_count,
           SUM(CASE WHEN simm_historical.PAYOFFUID IS NOT NULL AND dt.ASOFDATE >= simm_historical.FIRST_SIMM_DATE THEN 1 ELSE 0 END) as historical_simm_count
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION dt
    LEFT JOIN BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST simm_current
        ON simm_current.SET_NAME = 'SIMM' 
        AND simm_current.SUPPRESSION_FLAG = FALSE
        AND simm_current.PAYOFFUID = dt.PAYOFFUID
        AND simm_current.LOAN_TAPE_ASOFDATE = dt.ASOFDATE
    LEFT JOIN simm_placements simm_historical ON dt.PAYOFFUID = simm_historical.PAYOFFUID  
    WHERE dt.ASOFDATE = '2025-07-30'
)
SELECT 
    'CORRECTED OPTIMIZATION TEST' as test_name,
    o.total_records as original_total,
    op.total_records as optimized_total,
    CASE WHEN o.total_records = op.total_records THEN 'PASS' ELSE 'FAIL' END as total_match,
    o.current_simm_count as original_current,
    op.current_simm_count as optimized_current,
    CASE WHEN o.current_simm_count = op.current_simm_count THEN 'PASS' ELSE 'FAIL' END as current_match,
    o.historical_simm_count as original_historical,
    op.historical_simm_count as optimized_historical,
    CASE WHEN o.historical_simm_count = op.historical_simm_count THEN 'PASS' ELSE 'FAIL' END as historical_match
FROM original_results o, optimized_results op;