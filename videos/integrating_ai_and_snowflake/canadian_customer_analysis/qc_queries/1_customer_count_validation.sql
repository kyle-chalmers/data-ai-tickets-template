-- QC Check 1: Validate US customer count
-- Expected Result: 297,366 customers

SELECT
    'US Customer Count Validation' as qc_check,
    COUNT(*) as customer_count,
    '297366' as expected_count,
    CASE
        WHEN COUNT(*) = 297366 THEN 'PASS'
        ELSE 'FAIL'
    END as validation_status
FROM SNOWFLAKE_SAMPLE_DATA.TPCDS_SF10TCL.CUSTOMER
WHERE C_BIRTH_COUNTRY = 'UNITED STATES';
