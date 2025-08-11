-- DI-1137: Massachusetts Regulator Request - CONSOLIDATED
-- Query 1: Loans of $6,000 or less with rates above 12% per annum for MA residents
-- Purpose: Identify if Happy Money has processed applications or arranged such loans
-- Data Sources: Analytics Views, Monthly Loan Tape, and Main Loan Tape

-- =============================================================================
-- PARAMETERS
-- =============================================================================
SET MAX_LOAN_AMOUNT = 6000;
SET MIN_INTEREST_RATE = 12.0;  -- 12% per annum
SET STATE_FILTER = 'MA';

-- =============================================================================
-- SECTION 1: ANALYTICS VIEWS (Most Comprehensive)
-- =============================================================================
-- Uses: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN + VW_APPLICATION
-- Best for: Detailed analytical queries with full application context

WITH MA_SMALL_HIGH_RATE_LOANS_ANALYTICS AS (
    SELECT 
        -- Application Information
        B.APPLICATION_ID,
        B.APPLICATION_STARTED_DATE AS APPLICATION_DATE,
        
        -- Member Information
        C.FIRST_NAME AS APPLICATION_FIRST_NAME,
        C.LAST_NAME AS APPLICATION_LAST_NAME,
        A.APPLICANT_RESIDENCE_STATE AS APPLICANTRESIDENCESTATE,
        
        -- Loan Information
        A.LOAN_ID AS LOANID,
        A.LEGACY_LOAN_ID,
        A.LOAN_AMOUNT AS LOANAMOUNT,
        
        -- Status Information
        E.TITLE AS CURRENT_STATUS,
        
        -- Rate Information
        B.APR,
        B.INTEREST_RATE,
        
        -- Date Information
        A.ORIGINATION_DATE AS ORIGINATION_DATE,
        
        -- Source identifier
        'ANALYTICS_VIEWS' AS DATA_SOURCE
        
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
    
    -- Join with application data for APR and interest rate
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION B
        ON A.APPLICATION_ID = B.APPLICATION_ID
    
    -- Join with member data for names
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_MEMBER C
        ON B.MEMBER_ID = C.MEMBER_ID
    
    -- Join with loan status for current status
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_STATUS E
        ON A.LOAN_ID = E.LOAN_ID
    
    WHERE 1=1
        -- Filter for Massachusetts residents
        AND UPPER(A.APPLICANT_RESIDENCE_STATE) = $STATE_FILTER
        
        -- Filter for loans of $6,000 or less
        AND A.LOAN_AMOUNT <= $MAX_LOAN_AMOUNT
        
        -- Filter for interest rates above 12% per annum
        AND (B.APR > $MIN_INTEREST_RATE OR B.INTEREST_RATE > ($MIN_INTEREST_RATE/100.0))
        
        -- Filter for originated loans only
        AND A.ORIGINATION_DATE IS NOT NULL
),

-- =============================================================================
-- SECTION 2: MONTHLY LOAN TAPE (Historical Month-End Data)
-- =============================================================================
-- Uses: BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
-- Best for: Historical month-end reporting and compliance

MA_LOAN_TAPE_MONTHLY_CURRENT AS (
    -- Get most recent loan tape record for each loan
    SELECT 
        LOANID,
        PAYOFFUID,
        APPLICANTRESIDENCESTATE,
        LOANAMOUNT,
        INTERESTRATE,
        APR,
        ORIGINATIONDATE,
        STATUS,
        PORTFOLIONAME,
        PLACEMENT_STATUS,
        -- Use most recent record for each loan
        ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY
    WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
),

MA_SMALL_HIGH_RATE_LOANS_MONTHLY AS (
    SELECT 
        -- Loan Information
        LT.LOANID,
        NULL AS APPLICATION_ID,  -- Not available in loan tape
        NULL AS APPLICATION_DATE,  -- Not available in loan tape
        NULL AS APPLICATION_FIRST_NAME,  -- Not available in loan tape
        NULL AS APPLICATION_LAST_NAME,  -- Not available in loan tape
        LT.APPLICANTRESIDENCESTATE,
        NULL AS LEGACY_LOAN_ID,  -- Not available in loan tape
        LT.LOANAMOUNT,
        LT.STATUS AS CURRENT_STATUS,
        LT.APR,
        LT.INTERESTRATE AS INTEREST_RATE,
        LT.ORIGINATIONDATE AS ORIGINATION_DATE,
        
        -- Source identifier
        'MONTHLY_LOAN_TAPE' AS DATA_SOURCE
        
    FROM MA_LOAN_TAPE_MONTHLY_CURRENT LT
    WHERE 1=1
        -- Use most recent record only
        AND LT.rn = 1
        
        -- Filter for loans of $6,000 or less
        AND LT.LOANAMOUNT <= $MAX_LOAN_AMOUNT
        
        -- Filter for interest rates above 12% per annum
        AND (LT.APR > $MIN_INTEREST_RATE OR LT.INTERESTRATE > ($MIN_INTEREST_RATE/100.0))
        
        -- Filter for originated loans only
        AND LT.ORIGINATIONDATE IS NOT NULL
),

-- =============================================================================
-- SECTION 3: MAIN LOAN TAPE (Current/Real-time Data)
-- =============================================================================
-- Uses: BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
-- Best for: Most current loan tape data and real-time analysis

MA_LOAN_TAPE_MAIN_CURRENT AS (
    -- Get most recent loan tape record for each loan
    SELECT 
        LOANID,
        PAYOFFUID,
        APPLICANTRESIDENCESTATE,
        LOANAMOUNT,
        INTERESTRATE,
        APR,
        ORIGINATIONDATE,
        STATUS,
        PORTFOLIONAME,
        PLACEMENT_STATUS,
        -- Use most recent record for each loan
        ROW_NUMBER() OVER (PARTITION BY LOANID ORDER BY ASOFDATE DESC) as rn
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
    WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER
),

MA_SMALL_HIGH_RATE_LOANS_MAIN AS (
    SELECT 
        -- Loan Information
        LT.LOANID,
        NULL AS APPLICATION_ID,  -- Not available in loan tape
        NULL AS APPLICATION_DATE,  -- Not available in loan tape
        NULL AS APPLICATION_FIRST_NAME,  -- Not available in loan tape
        NULL AS APPLICATION_LAST_NAME,  -- Not available in loan tape
        LT.APPLICANTRESIDENCESTATE,
        NULL AS LEGACY_LOAN_ID,  -- Not available in loan tape
        LT.LOANAMOUNT,
        LT.STATUS AS CURRENT_STATUS,
        LT.APR,
        LT.INTERESTRATE AS INTEREST_RATE,
        LT.ORIGINATIONDATE AS ORIGINATION_DATE,
        
        -- Source identifier
        'MAIN_LOAN_TAPE' AS DATA_SOURCE
        
    FROM MA_LOAN_TAPE_MAIN_CURRENT LT
    WHERE 1=1
        -- Use most recent record only
        AND LT.rn = 1
        
        -- Filter for loans of $6,000 or less
        AND LT.LOANAMOUNT <= $MAX_LOAN_AMOUNT
        
        -- Filter for interest rates above 12% per annum
        AND (LT.APR > $MIN_INTEREST_RATE OR LT.INTERESTRATE > ($MIN_INTEREST_RATE/100.0))
        
        -- Filter for originated loans only
        AND LT.ORIGINATIONDATE IS NOT NULL
)

-- =============================================================================
-- FINAL RESULTS: COMBINED FROM ALL THREE SOURCES
-- =============================================================================
-- Union all three data sources for comprehensive analysis

SELECT * FROM MA_SMALL_HIGH_RATE_LOANS_ANALYTICS
UNION ALL
SELECT 
    LOANID,
    APPLICATION_ID,
    APPLICATION_DATE,
    APPLICATION_FIRST_NAME,
    APPLICATION_LAST_NAME,
    APPLICANTRESIDENCESTATE,
    LEGACY_LOAN_ID,
    LOANAMOUNT,
    CURRENT_STATUS,
    APR,
    INTEREST_RATE,
    ORIGINATION_DATE,
    DATA_SOURCE
FROM MA_SMALL_HIGH_RATE_LOANS_MONTHLY
UNION ALL
SELECT 
    LOANID,
    APPLICATION_ID,
    APPLICATION_DATE,
    APPLICATION_FIRST_NAME,
    APPLICATION_LAST_NAME,
    APPLICANTRESIDENCESTATE,
    LEGACY_LOAN_ID,
    LOANAMOUNT,
    CURRENT_STATUS,
    APR,
    INTEREST_RATE,
    ORIGINATION_DATE,
    DATA_SOURCE
FROM MA_SMALL_HIGH_RATE_LOANS_MAIN

ORDER BY DATA_SOURCE, ORIGINATION_DATE DESC, LOANAMOUNT DESC;

-- =============================================================================
-- SUMMARY STATISTICS BY DATA SOURCE
-- =============================================================================
/*
SELECT 
    DATA_SOURCE,
    COUNT(*) AS LOAN_COUNT,
    SUM(LOANAMOUNT) AS TOTAL_LOAN_AMOUNT,
    AVG(LOANAMOUNT) AS AVG_LOAN_AMOUNT,
    MIN(APR) AS MIN_APR,
    MAX(APR) AS MAX_APR,
    AVG(APR) AS AVG_APR,
    MIN(ORIGINATION_DATE) AS EARLIEST_LOAN,
    MAX(ORIGINATION_DATE) AS LATEST_LOAN
FROM (
    -- Add the same UNION ALL query here for summary stats
) combined_results
GROUP BY DATA_SOURCE
ORDER BY DATA_SOURCE;
*/