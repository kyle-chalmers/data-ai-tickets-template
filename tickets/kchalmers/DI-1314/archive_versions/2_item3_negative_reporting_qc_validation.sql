-- DI-1314: Item 3 - FCRA Negative Credit Reporting - QC Validation
-- Quality control checks for first late payment deliverable
-- Date: 2025-10-14

-- ============================================================================
-- QC Test 1: Record Count and Uniqueness Validation
-- ============================================================================
-- Expected: 7,081 unique loans (one first late payment per loan)

SELECT
    COUNT(*) as total_records,
    COUNT(DISTINCT LOAN_NUMBER) as unique_loans,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT LOAN_NUMBER)
        THEN 'PASS - One record per loan (no duplicates)'
        ELSE 'FAIL - Duplicate loans found'
    END as uniqueness_check
FROM (
    SELECT LOAN_NUMBER
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
);

-- ============================================================================
-- QC Test 2: CRB Portfolio Filter Validation
-- ============================================================================
-- Expected: All records should have PORTFOLIOID IN ('32', '34', '54', '56')

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    PORTFOLIOID,
    COUNT(*) as loan_count,
    CASE
        WHEN PORTFOLIOID IN ('32.00000', '34.00000', '54.00000', '56.00000')
        THEN 'PASS'
        ELSE 'FAIL - Invalid portfolio'
    END as portfolio_check
FROM result_data
GROUP BY PORTFOLIOID
ORDER BY PORTFOLIOID;

-- ============================================================================
-- QC Test 3: Date Range Validation
-- ============================================================================
-- Expected: All DATE_OF_FIRST_LATE_PAYMENT between 2024-10-01 and 2025-08-31

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    MIN(DATE_OF_FIRST_LATE_PAYMENT) as earliest_late_date,
    MAX(DATE_OF_FIRST_LATE_PAYMENT) as latest_late_date,
    COUNT(*) as total_records,
    SUM(CASE
        WHEN DATE_OF_FIRST_LATE_PAYMENT >= '2024-10-01'
         AND DATE_OF_FIRST_LATE_PAYMENT <= '2025-08-31'
        THEN 1 ELSE 0
    END) as records_in_scope,
    CASE
        WHEN COUNT(*) = SUM(CASE
            WHEN DATE_OF_FIRST_LATE_PAYMENT >= '2024-10-01'
             AND DATE_OF_FIRST_LATE_PAYMENT <= '2025-08-31'
            THEN 1 ELSE 0
        END)
        THEN 'PASS - All dates in scope'
        ELSE 'FAIL - Dates outside scope found'
    END as date_range_check
FROM result_data;

-- ============================================================================
-- QC Test 4: Days Past Due Validation
-- ============================================================================
-- Expected: All DAYS_PAST_DUE > 0 (definition of "late payment")

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    MIN(DAYS_PAST_DUE) as min_dpd,
    MAX(DAYS_PAST_DUE) as max_dpd,
    AVG(DAYS_PAST_DUE) as avg_dpd,
    COUNT(*) as total_records,
    SUM(CASE WHEN DAYS_PAST_DUE > 0 THEN 1 ELSE 0 END) as dpd_greater_than_zero,
    CASE
        WHEN COUNT(*) = SUM(CASE WHEN DAYS_PAST_DUE > 0 THEN 1 ELSE 0 END)
        THEN 'PASS - All DPD > 0'
        ELSE 'FAIL - DPD <= 0 found'
    END as dpd_validation
FROM result_data;

-- ============================================================================
-- QC Test 5: Reported to CRA Distribution
-- ============================================================================
-- Informational: Show distribution of CRA reporting status

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    REPORTED_LATE_TO_CRA,
    COUNT(*) as loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM result_data
GROUP BY REPORTED_LATE_TO_CRA
ORDER BY loan_count DESC;

-- ============================================================================
-- QC Test 6: NULL Value Check
-- ============================================================================
-- Expected: No NULLs in required fields

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    'LOAN_NUMBER' as field_name,
    SUM(CASE WHEN LOAN_NUMBER IS NULL THEN 1 ELSE 0 END) as null_count,
    CASE WHEN SUM(CASE WHEN LOAN_NUMBER IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END as null_check
FROM result_data
UNION ALL
SELECT
    'BORROWER_NAME',
    SUM(CASE WHEN BORROWER_NAME IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN BORROWER_NAME IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data
UNION ALL
SELECT
    'DATE_OF_FIRST_LATE_PAYMENT',
    SUM(CASE WHEN DATE_OF_FIRST_LATE_PAYMENT IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN DATE_OF_FIRST_LATE_PAYMENT IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data
UNION ALL
SELECT
    'DAYS_PAST_DUE',
    SUM(CASE WHEN DAYS_PAST_DUE IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN DAYS_PAST_DUE IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data
UNION ALL
SELECT
    'REPORTED_LATE_TO_CRA',
    SUM(CASE WHEN REPORTED_LATE_TO_CRA IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN REPORTED_LATE_TO_CRA IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data;

-- ============================================================================
-- QC Test 7: Days Past Due Distribution
-- ============================================================================
-- Informational: Show distribution of delinquency severity at first late payment

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    CASE
        WHEN DAYS_PAST_DUE BETWEEN 1 AND 15 THEN '01-15 days'
        WHEN DAYS_PAST_DUE BETWEEN 16 AND 30 THEN '16-30 days'
        WHEN DAYS_PAST_DUE BETWEEN 31 AND 60 THEN '31-60 days'
        WHEN DAYS_PAST_DUE BETWEEN 61 AND 90 THEN '61-90 days'
        WHEN DAYS_PAST_DUE > 90 THEN '90+ days'
        ELSE 'Unknown'
    END as dpd_bucket,
    COUNT(*) as loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM result_data
GROUP BY dpd_bucket
ORDER BY MIN(DAYS_PAST_DUE);

-- ============================================================================
-- QC Test 8: Portfolio Distribution
-- ============================================================================
-- Informational: Show distribution across CRB portfolios

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/2_item3_fcra_negative_credit_reporting.csv"
)
SELECT
    PORTFOLIONAME,
    PORTFOLIOID,
    COUNT(*) as loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM result_data
GROUP BY PORTFOLIONAME, PORTFOLIOID
ORDER BY loan_count DESC;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Tests to Pass:
-- 1. Total records = 7,081
-- 2. Unique loans = 7,081 (no duplicates)
-- 3. All PORTFOLIOID in ('32', '34', '54', '56')
-- 4. All dates between 2024-10-01 and 2025-08-31
-- 5. All DAYS_PAST_DUE > 0
-- 6. No NULLs in required fields
-- 7. REPORTED_LATE_TO_CRA has values (Yes/No/Pending)
-- ============================================================================
