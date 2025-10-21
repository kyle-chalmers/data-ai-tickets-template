-- QC Check 2: Verify December 2002 date range
-- Expected Result: 31 days from 2002-12-01 to 2002-12-31

SELECT
    'December 2002 Date Range' as qc_check,
    MIN(D_DATE) as start_date,
    MAX(D_DATE) as end_date,
    COUNT(DISTINCT D_DATE_SK) as date_keys,
    '31' as expected_days,
    CASE
        WHEN COUNT(DISTINCT D_DATE_SK) = 31
         AND MIN(D_DATE) = '2002-12-01'
         AND MAX(D_DATE) = '2002-12-31'
        THEN 'PASS'
        ELSE 'FAIL'
    END as validation_status
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.DATE_DIM
WHERE D_YEAR = 2002 AND D_MOY = 12;
