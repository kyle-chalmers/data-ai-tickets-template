-- DI-1137: Massachusetts Regulator Request - QC Validation (LOAN TAPE VERSION)
-- Purpose: Quality control validation comparing loan tape results vs original VW_LOAN approach
-- Date: 2025-08-06

-- =============================================================================
-- Section 1: Data Source Comparison - Loan Tape vs VW_LOAN
-- =============================================================================

-- 1.1: Massachusetts loan count comparison
WITH LOAN_TAPE_MA AS (
    SELECT COUNT(DISTINCT LOANID) as loan_count,
           'LOAN_TAPE' as source
    FROM (
        SELECT LOANID,
               ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
        FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
        WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
    ) WHERE rn = 1
),
VW_LOAN_MA AS (
    SELECT COUNT(DISTINCT LOAN_ID) as loan_count,
           'VW_LOAN' as source
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN
    WHERE UPPER(APPLICANT_RESIDENCE_STATE) = 'MA'
)
SELECT source, loan_count FROM LOAN_TAPE_MA
UNION ALL
SELECT source, loan_count FROM VW_LOAN_MA
ORDER BY source;

-- 1.2: Total loan amount comparison
WITH LOAN_TAPE_AMOUNTS AS (
    SELECT SUM(LOANAMOUNT) as total_amount,
           'LOAN_TAPE' as source
    FROM (
        SELECT LOANID, LOANAMOUNT,
               ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
        FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
        WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
    ) WHERE rn = 1
),
VW_LOAN_AMOUNTS AS (
    SELECT SUM(LOAN_AMOUNT) as total_amount,
           'VW_LOAN' as source
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN
    WHERE UPPER(APPLICANT_RESIDENCE_STATE) = 'MA'
)
SELECT source, total_amount FROM LOAN_TAPE_AMOUNTS
UNION ALL
SELECT source, total_amount FROM VW_LOAN_AMOUNTS
ORDER BY source;

-- 1.3: Small dollar high rate loan comparison (≤$6K, >12%)
WITH LOAN_TAPE_SMALL_HIGH AS (
    SELECT COUNT(DISTINCT LOANID) as loan_count,
           SUM(LOANAMOUNT) as total_amount,
           'LOAN_TAPE' as source
    FROM (
        SELECT LOANID, LOANAMOUNT, INTERESTRATE,
               ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
        FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
        WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
    ) 
    WHERE rn = 1 
      AND LOANAMOUNT <= 6000 
      AND INTERESTRATE > 0.12
),
VW_LOAN_SMALL_HIGH AS (
    SELECT COUNT(DISTINCT L.LOAN_ID) as loan_count,
           SUM(L.LOAN_AMOUNT) as total_amount,
           'VW_LOAN' as source
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN L
    JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION A
        ON L.APPLICATION_ID = A.APPLICATION_ID
    WHERE UPPER(L.APPLICANT_RESIDENCE_STATE) = 'MA'
      AND L.LOAN_AMOUNT <= 6000
      AND A.INTEREST_RATE > 12
)
SELECT source, loan_count, total_amount FROM LOAN_TAPE_SMALL_HIGH
UNION ALL
SELECT source, loan_count, total_amount FROM VW_LOAN_SMALL_HIGH
ORDER BY source;

-- =============================================================================
-- Section 2: Data Quality Assessment for Loan Tape Approach
-- =============================================================================

-- 2.1: Field completeness assessment
WITH MA_LOAN_TAPE_CURRENT AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
)
SELECT 
    'Field Completeness Analysis (LOAN TAPE)' as analysis_type,
    COUNT(*) as total_records,
    COUNT(LOANID) as loanid_populated,
    COUNT(LOANAMOUNT) as loanamount_populated,
    COUNT(INTERESTRATE) as interestrate_populated,
    COUNT(APR) as apr_populated,
    COUNT(ORIGINATIONDATE) as originationdate_populated,
    COUNT(STATUS) as status_populated,
    COUNT(APPLICANTRESIDENCESTATE) as state_populated,
    -- Calculate percentages
    ROUND((COUNT(LOANID) * 100.0 / COUNT(*)), 2) as loanid_pct,
    ROUND((COUNT(LOANAMOUNT) * 100.0 / COUNT(*)), 2) as loanamount_pct,
    ROUND((COUNT(INTERESTRATE) * 100.0 / COUNT(*)), 2) as interestrate_pct,
    ROUND((COUNT(APR) * 100.0 / COUNT(*)), 2) as apr_pct,
    ROUND((COUNT(ORIGINATIONDATE) * 100.0 / COUNT(*)), 2) as originationdate_pct,
    ROUND((COUNT(STATUS) * 100.0 / COUNT(*)), 2) as status_pct
FROM MA_LOAN_TAPE_CURRENT
WHERE rn = 1;

-- 2.2: Date range analysis
WITH MA_LOAN_TAPE_CURRENT AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
)
SELECT 
    'Date Range Analysis (LOAN TAPE)' as analysis_type,
    MIN(ORIGINATIONDATE) as earliest_loan,
    MAX(ORIGINATIONDATE) as latest_loan,
    DATEDIFF(year, MIN(ORIGINATIONDATE), MAX(ORIGINATIONDATE)) as years_span,
    COUNT(DISTINCT YEAR(ORIGINATIONDATE)) as distinct_years
FROM MA_LOAN_TAPE_CURRENT
WHERE rn = 1;

-- 2.3: Status distribution analysis
WITH MA_LOAN_TAPE_CURRENT AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
)
SELECT 
    COALESCE(STATUS, 'NULL') as loan_status,
    COUNT(*) as loan_count,
    ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) as percentage
FROM MA_LOAN_TAPE_CURRENT
WHERE rn = 1
GROUP BY STATUS
ORDER BY loan_count DESC;

-- =============================================================================
-- Section 3: Validation of Regulatory Requirements
-- =============================================================================

-- 3.1: Validate small dollar high rate loans meet criteria
SELECT 
    'Small Dollar High Rate Validation' as validation_type,
    LOANID,
    LOANAMOUNT,
    INTERESTRATE,
    INTERESTRATE * 100 as interest_rate_pct,
    APR,
    ORIGINATIONDATE,
    STATUS,
    CASE 
        WHEN LOANAMOUNT <= 6000 THEN 'PASS' 
        ELSE 'FAIL' 
    END as amount_criteria,
    CASE 
        WHEN INTERESTRATE > 0.12 THEN 'PASS' 
        ELSE 'FAIL' 
    END as rate_criteria
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
) 
WHERE rn = 1 
  AND LOANAMOUNT <= 6000 
  AND INTERESTRATE > 0.12
ORDER BY ORIGINATIONDATE DESC;

-- 3.2: Summary validation report
SELECT 
    'LOAN TAPE VALIDATION SUMMARY' as report_section,
    COUNT(DISTINCT 
        CASE WHEN rn = 1 THEN LOANID END
    ) as total_ma_loans,
    
    COUNT(DISTINCT 
        CASE 
            WHEN rn = 1 
             AND LOANAMOUNT <= 6000 
             AND INTERESTRATE > 0.12 
            THEN LOANID 
        END
    ) as small_high_rate_loans,
    
    SUM(CASE WHEN rn = 1 THEN LOANAMOUNT END) as total_loan_amount,
    
    MIN(CASE WHEN rn = 1 THEN ORIGINATIONDATE END) as earliest_origination,
    MAX(CASE WHEN rn = 1 THEN ORIGINATIONDATE END) as latest_origination,
    
    ROUND(AVG(CASE WHEN rn = 1 THEN INTERESTRATE * 100 END), 2) as avg_interest_rate_pct,
    ROUND(AVG(CASE WHEN rn = 1 THEN APR END), 2) as avg_apr
    
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
);