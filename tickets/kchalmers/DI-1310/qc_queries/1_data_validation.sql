/*******************************************************************************
 * QC Validation Queries - DI-1310
 * South Dakota Money Lender License Q3 2025 Report
 *
 * These queries validate the data quality and business logic used in the
 * main reporting script.
 ******************************************************************************/

-- Variables
SET REPORTING_START_DATE = '2025-07-01';
SET REPORTING_END_DATE = '2025-09-30';
SET AS_OF_DATE = '2025-10-01';

/*******************************************************************************
 * QC 1.1: Verify ASOFDATE represents September 30, 2025 snapshot
 *
 * Expected: ASOFDATE = '2025-10-01' should be the snapshot representing
 * Sept 30, 2025 data
 ******************************************************************************/
--1.1: Verify ASOFDATE represents Sept 30 snapshot
SELECT
    'ASOFDATE Validation' as qc_check,
    MIN(ASOFDATE) as min_asofdate,
    MAX(ASOFDATE) as max_asofdate,
    COUNT(DISTINCT ASOFDATE) as distinct_dates
FROM DATA_STORE.MVW_LOAN_TAPE;


/*******************************************************************************
 * QC 1.2: Validate South Dakota loan counts by status
 *
 * Expected: Total SD loans should equal sum of all status categories
 ******************************************************************************/
--1.2: SD loan counts by status
SELECT
    'SD Loan Status Distribution' as qc_check,
    STATUS,
    COUNT(DISTINCT LOANID) as loan_count,
    ROUND(COUNT(DISTINCT LOANID) * 100.0 / SUM(COUNT(DISTINCT LOANID)) OVER(), 2) as percentage
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
GROUP BY STATUS
ORDER BY loan_count DESC;


/*******************************************************************************
 * QC 1.3: Verify no duplicate loans in snapshot
 *
 * Expected: Each LOANID should appear exactly once for the ASOFDATE
 ******************************************************************************/
--1.3: Check for duplicate loans in snapshot
SELECT
    'Duplicate Loan Check' as qc_check,
    LOANID,
    COUNT(*) as record_count
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
GROUP BY LOANID
HAVING COUNT(*) > 1;


/*******************************************************************************
 * QC 1.4: Validate Q3 origination date range
 *
 * Expected: All new loans should have ORIGINATIONDATE between 7/1 and 9/30
 ******************************************************************************/
--1.4: Verify Q3 origination dates
SELECT
    'Q3 Origination Date Validation' as qc_check,
    MIN(ORIGINATIONDATE) as earliest_origination,
    MAX(ORIGINATIONDATE) as latest_origination,
    COUNT(DISTINCT LOANID) as total_new_loans
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ORIGINATIONDATE BETWEEN $REPORTING_START_DATE AND $REPORTING_END_DATE;


/*******************************************************************************
 * QC 1.5: Validate APR data quality
 *
 * Expected: APR should be non-null and reasonable for outstanding loans
 ******************************************************************************/
--1.5: APR data quality check
SELECT
    'APR Data Quality' as qc_check,
    COUNT(DISTINCT LOANID) as total_outstanding,
    SUM(CASE WHEN APR IS NULL THEN 1 ELSE 0 END) as null_apr_count,
    SUM(CASE WHEN APR <= 0 THEN 1 ELSE 0 END) as zero_or_negative_apr,
    MIN(APR) as min_apr,
    MAX(APR) as max_apr,
    ROUND(AVG(APR), 3) as avg_apr
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';


/*******************************************************************************
 * QC 1.6: Compare to prior quarter baseline
 *
 * Expected: Identify trends vs DI-501 (Q4 2024) and DI-343 (Q3 2024)
 ******************************************************************************/
--1.6: Historical comparison (requires manual review)
SELECT
    'Historical Trend Analysis' as qc_check,
    'Q3 2025' as quarter,
    COUNT(DISTINCT LOANID) as outstanding_loans,
    COUNT(DISTINCT CASE WHEN ORIGINATIONDATE BETWEEN $REPORTING_START_DATE AND $REPORTING_END_DATE THEN LOANID END) as new_loans_this_quarter,
    MIN(APR) as min_apr,
    MAX(APR) as max_apr
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';


/*******************************************************************************
 * QC 1.7: Verify APR range categorization logic
 *
 * Expected: No loans should fall outside the defined ranges
 ******************************************************************************/
--1.7: APR range edge case validation
SELECT
    'APR Range Edge Cases' as qc_check,
    SUM(CASE WHEN APR = 16.0 THEN 1 ELSE 0 END) as exactly_16_percent,
    SUM(CASE WHEN APR = 36.0 THEN 1 ELSE 0 END) as exactly_36_percent,
    SUM(CASE WHEN APR > 36.0 THEN 1 ELSE 0 END) as over_36_percent
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';


/*******************************************************************************
 * QC 1.8: Validate state filtering
 *
 * Expected: Only SD loans should be included, verify state data quality
 ******************************************************************************/
--1.8: State data validation
SELECT
    'State Data Validation' as qc_check,
    APPLICANTRESIDENCESTATE,
    COUNT(DISTINCT LOANID) as loan_count
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE ASOFDATE = $AS_OF_DATE
  AND (APPLICANTRESIDENCESTATE = 'SD' OR APPLICANTRESIDENCESTATE IS NULL)
GROUP BY APPLICANTRESIDENCESTATE;
