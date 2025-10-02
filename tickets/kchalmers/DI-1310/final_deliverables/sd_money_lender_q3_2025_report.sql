/*******************************************************************************
 * South Dakota Money Lender License Quarterly Report - Q3 2025
 *
 * Reporting Period: July 1, 2025 through September 30, 2025
 * As-Of Date: September 30, 2025 (represented by ASOFDATE = '2025-10-01')
 *
 * Data Source: DATA_STORE.MVW_LOAN_TAPE (Query 1)
 *              DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY (Queries 2-6 for historical ASOFDATE)
 *
 * This script contains 6 queries required for the SD Money Lender License
 * quarterly submission. Each query answers a specific regulatory requirement.
 *
 * Reference: Prior quarter report DI-501 (Q4 2024)
 ******************************************************************************/

-- Variables for parameterization
SET REPORTING_START_DATE = '2025-07-01';
SET REPORTING_END_DATE = '2025-09-30';
SET AS_OF_DATE = '2025-10-01'; -- Snapshot date representing Sept 30, 2025

/*******************************************************************************
 * QUERY 1: New South Dakota Accounts During Q3 2025
 *
 * Question: What is the number of new South Dakota accounts during the quarter?
 *
 * Business Logic:
 * - Count distinct loans where ORIGINATIONDATE falls within Q3 2025
 * - Filter for South Dakota residency (APPLICANTRESIDENCESTATE = 'SD')
 ******************************************************************************/

SELECT
    COUNT(DISTINCT LOANID) as new_sd_accounts_q3_2025,
    'New SD accounts originated between ' || $REPORTING_START_DATE || ' and ' || $REPORTING_END_DATE as description
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ORIGINATIONDATE BETWEEN $REPORTING_START_DATE AND $REPORTING_END_DATE;


/*******************************************************************************
 * QUERY 2: Outstanding Accounts Range Category (As of September 30, 2025)
 *
 * Question: As of September 30, what is the total number of outstanding
 * South Dakota accounts covered by your Money Lending License? (Select a range)
 *
 * Range Options:
 * - 0-50
 * - 50-100
 * - 100+
 *
 * Business Logic:
 * - Outstanding = all loans NOT in "Paid in Full" status
 * - Use ASOFDATE snapshot representing September 30, 2025
 ******************************************************************************/

SELECT
    COUNT(DISTINCT LOANID) as outstanding_count,
    CASE
        WHEN COUNT(DISTINCT LOANID) BETWEEN 0 AND 50 THEN '0-50'
        WHEN COUNT(DISTINCT LOANID) BETWEEN 51 AND 100 THEN '50-100'
        WHEN COUNT(DISTINCT LOANID) > 100 THEN '100+'
    END as range_category,
    'Outstanding SD accounts as of ' || $REPORTING_END_DATE as description
FROM DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';


/*******************************************************************************
 * QUERY 3: Exact Outstanding Account Count (As of September 30, 2025)
 *
 * Question: As of September 30, what is the total number of outstanding
 * South Dakota accounts covered by your Money Lending License? (Exact number)
 *
 * Business Logic:
 * - Same as Query 2 but returns exact count without range categorization
 ******************************************************************************/

SELECT
    COUNT(DISTINCT LOANID) as total_outstanding_accounts,
    'Exact count of outstanding SD accounts as of ' || $REPORTING_END_DATE as description
FROM DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';


/*******************************************************************************
 * QUERY 4: APR Range Category for Outstanding Accounts (As of September 30, 2025)
 *
 * Question: As of September 30, what is the range of APRs for the total number
 * of outstanding South Dakota accounts? (Select a range)
 *
 * Range Options:
 * - 0%- 16%
 * - 16%-36%
 * - Over 36%
 *
 * Business Logic:
 * - Analyze APR distribution across all outstanding loans
 * - Categorize each loan into appropriate APR bucket
 * - Return count and percentage in each category
 ******************************************************************************/

WITH apr_categorization AS (
    SELECT
        LOANID,
        APR,
        CASE
            WHEN APR <= 16.0 THEN '0%-16%'
            WHEN APR > 16.0 AND APR <= 36.0 THEN '16%-36%'
            WHEN APR > 36.0 THEN 'Over 36%'
        END as apr_range_category
    FROM DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    WHERE APPLICANTRESIDENCESTATE = 'SD'
      AND ASOFDATE = $AS_OF_DATE
      AND STATUS <> 'Paid in Full'
)
SELECT
    apr_range_category,
    COUNT(DISTINCT LOANID) as loan_count,
    ROUND(COUNT(DISTINCT LOANID) * 100.0 / SUM(COUNT(DISTINCT LOANID)) OVER(), 2) as percentage
FROM apr_categorization
GROUP BY apr_range_category
ORDER BY
    CASE apr_range_category
        WHEN '0%-16%' THEN 1
        WHEN '16%-36%' THEN 2
        WHEN 'Over 36%' THEN 3
    END;


/*******************************************************************************
 * QUERY 5: Minimum Annual Percentage Rate (As of September 30, 2025)
 *
 * Question: Minimum Annual Percentage Rate (The value must be a number)
 * NOTE: Reported 6.99% on the previously submitted report.
 *       Will the response remain the same for the 3rd quarter report?
 *
 * Business Logic:
 * - Find minimum APR across all outstanding SD loans
 * - Compare to prior quarter: 6.99%
 ******************************************************************************/

SELECT
    MIN(APR) as minimum_apr,
    'Minimum APR for outstanding SD accounts as of ' || $REPORTING_END_DATE as description,
    CASE
        WHEN MIN(APR) = 6.99 THEN 'SAME as prior quarter (6.99%)'
        ELSE 'CHANGED from prior quarter (was 6.99%)'
    END as comparison_to_prior_quarter
FROM DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';


/*******************************************************************************
 * QUERY 6: Maximum Annual Percentage Rate (As of September 30, 2025)
 *
 * Question: Maximum Annual Percentage Rate (The value must be a number)
 * NOTE: Reported 24.99% on the previously submitted report.
 *       Will the response remain the same for the 4th quarter report?
 *
 * Business Logic:
 * - Find maximum APR across all outstanding SD loans
 * - Compare to prior quarter: 24.99%
 ******************************************************************************/

SELECT
    MAX(APR) as maximum_apr,
    'Maximum APR for outstanding SD accounts as of ' || $REPORTING_END_DATE as description,
    CASE
        WHEN MAX(APR) = 24.99 THEN 'SAME as prior quarter (24.99%)'
        ELSE 'CHANGED from prior quarter (was 24.99%)'
    END as comparison_to_prior_quarter
FROM DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE APPLICANTRESIDENCESTATE = 'SD'
  AND ASOFDATE = $AS_OF_DATE
  AND STATUS <> 'Paid in Full';
