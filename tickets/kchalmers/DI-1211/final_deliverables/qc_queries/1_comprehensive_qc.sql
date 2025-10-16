/*
================================================================================
DI-1211 QC: Comprehensive Quality Control - CSV-Based Analysis
================================================================================
Quality control queries to analyze the placement_data_quality_analysis.csv output.
Run these queries using DuckDB for fast CSV analysis.
================================================================================
*/

-- Load the CSV into DuckDB for analysis
-- Run: duckdb -c "SELECT * FROM read_csv_auto('placement_data_quality_analysis.csv')"

--1.1: Total Record Count
SELECT
    COUNT(*) AS TOTAL_LOANS,
    COUNT(DISTINCT LOAN_ID) AS UNIQUE_LOAN_IDS,
    COUNT(DISTINCT LEGACY_LOAN_ID) AS UNIQUE_LEGACY_LOAN_IDS,
    COUNT(DISTINCT LEAD_GUID) AS UNIQUE_LEAD_GUIDS
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true);

--1.2: Placement Status Distribution
SELECT
    PLACEMENT_STATUS,
    COUNT(*) AS LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
GROUP BY PLACEMENT_STATUS
ORDER BY PLACEMENT_STATUS;

--1.3: Conflict Type Breakdown (Individual Indicators)
SELECT
    'Settlement Conflict' AS CONFLICT_TYPE,
    SUM(HAS_SETTLEMENT_CONFLICT) AS LOAN_COUNT,
    ROUND(SUM(HAS_SETTLEMENT_CONFLICT) * 100.0 / COUNT(*), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
UNION ALL
SELECT
    'Post-Chargeoff Payments' AS CONFLICT_TYPE,
    SUM(HAS_POST_CHARGEOFF_PAYMENTS) AS LOAN_COUNT,
    ROUND(SUM(HAS_POST_CHARGEOFF_PAYMENTS) * 100.0 / COUNT(*), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
UNION ALL
SELECT
    'Active AutoPay' AS CONFLICT_TYPE,
    SUM(HAS_AUTOPAY) AS LOAN_COUNT,
    ROUND(SUM(HAS_AUTOPAY) * 100.0 / COUNT(*), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
UNION ALL
SELECT
    'Future Scheduled Payments' AS CONFLICT_TYPE,
    SUM(HAS_FUTURE_PAYMENTS) AS LOAN_COUNT,
    ROUND(SUM(HAS_FUTURE_PAYMENTS) * 100.0 / COUNT(*), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
ORDER BY LOAN_COUNT DESC;

--1.4: Conflict Count Distribution (Loans with Multiple Issues)
SELECT
    TOTAL_CONFLICT_COUNT,
    COUNT(*) AS LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
GROUP BY TOTAL_CONFLICT_COUNT
ORDER BY TOTAL_CONFLICT_COUNT;

--1.5: Settlement Status Breakdown (for loans with settlement conflicts)
SELECT
    SETTLEMENT_STATUS,
    COUNT(*) AS LOAN_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS PERCENTAGE
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
WHERE HAS_SETTLEMENT_CONFLICT = 1
GROUP BY SETTLEMENT_STATUS
ORDER BY LOAN_COUNT DESC;

--1.6: Charge-Off Date Range
SELECT
    MIN(CHARGEOFF_DATE) AS EARLIEST_CHARGEOFF,
    MAX(CHARGEOFF_DATE) AS LATEST_CHARGEOFF,
    DATEDIFF('day', MIN(CHARGEOFF_DATE), MAX(CHARGEOFF_DATE)) AS DATE_RANGE_DAYS
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true);

--1.7: Conflict Overlap Analysis (Cross-tabulation of conflict types)
SELECT
    CASE WHEN HAS_SETTLEMENT_CONFLICT = 1 THEN 'Y' ELSE 'N' END AS HAS_SETTLEMENT,
    CASE WHEN HAS_POST_CHARGEOFF_PAYMENTS = 1 THEN 'Y' ELSE 'N' END AS HAS_PAYMENTS,
    CASE WHEN HAS_AUTOPAY = 1 THEN 'Y' ELSE 'N' END AS HAS_AUTOPAY,
    CASE WHEN HAS_FUTURE_PAYMENTS = 1 THEN 'Y' ELSE 'N' END AS HAS_FUTURE_PMTS,
    COUNT(*) AS LOAN_COUNT
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
GROUP BY HAS_SETTLEMENT, HAS_PAYMENTS, HAS_AUTOPAY, HAS_FUTURE_PMTS
ORDER BY LOAN_COUNT DESC;

--1.8: Payment Amount Statistics (for loans with post-chargeoff payments)
SELECT
    COUNT(*) AS LOANS_WITH_PAYMENTS,
    SUM(POST_CHARGEOFF_PAYMENT_COUNT) AS TOTAL_PAYMENT_TRANSACTIONS,
    ROUND(AVG(POST_CHARGEOFF_PAYMENT_COUNT), 2) AS AVG_PAYMENTS_PER_LOAN,
    SUM(TOTAL_POST_CHARGEOFF_PAYMENTS) AS TOTAL_AMOUNT_COLLECTED,
    ROUND(AVG(TOTAL_POST_CHARGEOFF_PAYMENTS), 2) AS AVG_AMOUNT_PER_LOAN,
    MIN(TOTAL_POST_CHARGEOFF_PAYMENTS) AS MIN_AMOUNT,
    MAX(TOTAL_POST_CHARGEOFF_PAYMENTS) AS MAX_AMOUNT
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
WHERE HAS_POST_CHARGEOFF_PAYMENTS = 1;

--1.9: Future Payment Statistics (for loans with scheduled payments)
SELECT
    COUNT(*) AS LOANS_WITH_FUTURE_PMTS,
    SUM(FUTURE_SCHEDULED_PAYMENT_COUNT) AS TOTAL_SCHEDULED_TRANSACTIONS,
    ROUND(AVG(FUTURE_SCHEDULED_PAYMENT_COUNT), 2) AS AVG_SCHEDULED_PER_LOAN,
    SUM(TOTAL_FUTURE_SCHEDULED_AMOUNT) AS TOTAL_SCHEDULED_AMOUNT,
    ROUND(AVG(TOTAL_FUTURE_SCHEDULED_AMOUNT), 2) AS AVG_SCHEDULED_AMT_PER_LOAN,
    MIN(NEXT_PAYMENT_DATE) AS NEXT_UPCOMING_PAYMENT,
    MAX(NEXT_PAYMENT_DATE) AS FURTHEST_SCHEDULED_PAYMENT
FROM read_csv_auto('tickets/kchalmers/DI-1211/final_deliverables/placement_data_quality_analysis.csv', header=true)
WHERE HAS_FUTURE_PAYMENTS = 1;
