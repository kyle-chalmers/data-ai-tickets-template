-- DI-1137: Massachusetts Regulator Request - Quality Control Validation
-- Purpose: Validate data completeness and accuracy for regulatory submission

-- ============================================================================
-- QC 1: Data Completeness Check
-- ============================================================================
WITH MA_LOAN_COMPLETENESS AS (
    SELECT 
        A.LOAN_ID,
        A.APPLICATION_ID,
        A.MEMBER_ID,
        B.APR,
        B.INTEREST_RATE,
        C.FIRST_NAME,
        C.LAST_NAME,
        E.TITLE AS LOAN_SUB_STATUS_TEXT,
        A.LOAN_AMOUNT,
        A.ORIGINATION_DATE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION B
        ON A.APPLICATION_ID = B.APPLICATION_ID
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII C
        ON A.MEMBER_ID::STRING = C.MEMBER_ID::STRING
        AND C.MEMBER_PII_END_DATE IS NULL
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT D
        ON A.LOAN_ID::STRING = D.LOAN_ID::STRING
        AND D.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA()
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT E
        ON D.LOAN_SUB_STATUS_ID = E.ID
    WHERE UPPER(A.APPLICANT_RESIDENCE_STATE) = 'MA'
)
SELECT 
    'Data Completeness Check' AS QC_TYPE,
    COUNT(*) AS TOTAL_MA_LOANS,
    COUNT(APPLICATION_ID) AS LOANS_WITH_APP_ID,
    COUNT(FIRST_NAME) AS LOANS_WITH_FIRST_NAME,
    COUNT(LAST_NAME) AS LOANS_WITH_LAST_NAME,
    COUNT(APR) AS LOANS_WITH_APR,
    COUNT(INTEREST_RATE) AS LOANS_WITH_INTEREST_RATE,
    COUNT(ORIGINATION_DATE) AS LOANS_WITH_ORIG_DATE,
    COUNT(LOAN_SUB_STATUS_TEXT) AS LOANS_WITH_STATUS,
    -- Calculate completeness percentages
    ROUND(COUNT(FIRST_NAME) * 100.0 / COUNT(*), 2) AS PCT_WITH_FIRST_NAME,
    ROUND(COUNT(LAST_NAME) * 100.0 / COUNT(*), 2) AS PCT_WITH_LAST_NAME,
    ROUND(COUNT(APR) * 100.0 / COUNT(*), 2) AS PCT_WITH_APR,
    ROUND(COUNT(LOAN_SUB_STATUS_TEXT) * 100.0 / COUNT(*), 2) AS PCT_WITH_STATUS
FROM MA_LOAN_COMPLETENESS;

-- ============================================================================
-- QC 7: Loan Tape Validation - Check for Small Dollar High Rate Loans
-- ============================================================================
-- Note: This query returns 0 results, but loan 107383 exists in loan tape 
-- with LOANID 'PB822534FB0D7' showing APPLICANTRESIDENCESTATE as 'NY' not 'MA'.
-- This reveals a critical data discrepancy between sources.

SELECT 
    'Loan Tape Small Dollar High Rate Check' AS QC_TYPE,
    CASE WHEN COUNT(*) = 0 THEN 'NO QUALIFYING LOANS FOUND IN LOAN TAPE' 
         ELSE CAST(COUNT(*) AS VARCHAR) END AS RESULT,
    'Data discrepancy: Loan 107383 shows NY in tape vs MA in VW_LOAN' AS VALIDATION_RESULT
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = 'MA'
    AND LOANAMOUNT <= 6000
    AND INTERESTRATE > 12.0;

-- ============================================================================
-- QC 8: Cross-Reference Validation - Loan 107383 State Discrepancy
-- ============================================================================
-- Direct lookup of loan 107383 (PB822534FB0D7) to confirm state discrepancy

SELECT 
    'Loan 107383 State Verification' AS QC_TYPE,
    LOANID,
    APPLICANTRESIDENCESTATE AS LOAN_TAPE_STATE,
    LOANAMOUNT,
    INTERESTRATE,
    'Should be MA per VW_LOAN' AS EXPECTED_STATE
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE LOANID = 'PB822534FB0D7';

-- ============================================================================
-- QC 2: Rate Distribution Analysis
-- ============================================================================
SELECT 
    'Rate Distribution' AS QC_TYPE,
    COUNT(CASE WHEN B.INTEREST_RATE <= 6 THEN 1 END) AS RATE_0_TO_6_PCT,
    COUNT(CASE WHEN B.INTEREST_RATE > 6 AND B.INTEREST_RATE <= 12 THEN 1 END) AS RATE_6_TO_12_PCT,
    COUNT(CASE WHEN B.INTEREST_RATE > 12 AND B.INTEREST_RATE <= 18 THEN 1 END) AS RATE_12_TO_18_PCT,
    COUNT(CASE WHEN B.INTEREST_RATE > 18 AND B.INTEREST_RATE <= 24 THEN 1 END) AS RATE_18_TO_24_PCT,
    COUNT(CASE WHEN B.INTEREST_RATE > 24 THEN 1 END) AS RATE_ABOVE_24_PCT,
    MIN(B.INTEREST_RATE) AS MIN_INTEREST_RATE,
    MAX(B.INTEREST_RATE) AS MAX_INTEREST_RATE,
    ROUND(AVG(B.INTEREST_RATE), 2) AS AVG_INTEREST_RATE
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION B
    ON A.APPLICATION_ID = B.APPLICATION_ID
WHERE UPPER(A.APPLICANT_RESIDENCE_STATE) = 'MA';

-- ============================================================================
-- QC 3: Loan Amount Distribution
-- ============================================================================
SELECT 
    'Loan Amount Distribution' AS QC_TYPE,
    COUNT(CASE WHEN LOAN_AMOUNT <= 6000 THEN 1 END) AS LOANS_0_TO_6K,
    COUNT(CASE WHEN LOAN_AMOUNT > 6000 AND LOAN_AMOUNT <= 10000 THEN 1 END) AS LOANS_6K_TO_10K,
    COUNT(CASE WHEN LOAN_AMOUNT > 10000 AND LOAN_AMOUNT <= 20000 THEN 1 END) AS LOANS_10K_TO_20K,
    COUNT(CASE WHEN LOAN_AMOUNT > 20000 AND LOAN_AMOUNT <= 30000 THEN 1 END) AS LOANS_20K_TO_30K,
    COUNT(CASE WHEN LOAN_AMOUNT > 30000 THEN 1 END) AS LOANS_ABOVE_30K,
    MIN(LOAN_AMOUNT) AS MIN_LOAN_AMOUNT,
    MAX(LOAN_AMOUNT) AS MAX_LOAN_AMOUNT,
    ROUND(AVG(LOAN_AMOUNT), 2) AS AVG_LOAN_AMOUNT
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN
WHERE UPPER(APPLICANT_RESIDENCE_STATE) = 'MA';

-- ============================================================================
-- QC 4: Year-over-Year Origination Trend
-- ============================================================================
SELECT 
    YEAR(ORIGINATION_DATE) AS ORIGINATION_YEAR,
    COUNT(*) AS LOANS_ORIGINATED,
    SUM(LOAN_AMOUNT) AS TOTAL_ORIGINATED_AMOUNT,
    ROUND(AVG(LOAN_AMOUNT), 2) AS AVG_LOAN_AMOUNT,
    MIN(ORIGINATION_DATE) AS FIRST_LOAN_DATE,
    MAX(ORIGINATION_DATE) AS LAST_LOAN_DATE
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN
WHERE UPPER(APPLICANT_RESIDENCE_STATE) = 'MA'
GROUP BY 1
ORDER BY 1;

-- ============================================================================
-- QC 5: Small Dollar High Rate Loan Validation
-- ============================================================================
SELECT 
    'Small Dollar High Rate Validation' AS QC_TYPE,
    COUNT(*) AS TOTAL_MA_LOANS,
    COUNT(CASE WHEN A.LOAN_AMOUNT <= 6000 THEN 1 END) AS LOANS_6K_OR_LESS,
    COUNT(CASE WHEN A.LOAN_AMOUNT <= 6000 AND B.INTEREST_RATE > 12 THEN 1 END) AS LOANS_6K_OR_LESS_RATE_ABOVE_12,
    COUNT(CASE WHEN A.LOAN_AMOUNT <= 6000 AND B.APR > 12 THEN 1 END) AS LOANS_6K_OR_LESS_APR_ABOVE_12,
    -- List specific loans meeting criteria
    LISTAGG(CASE WHEN A.LOAN_AMOUNT <= 6000 AND B.INTEREST_RATE > 12 
            THEN A.LOAN_ID || ' ($' || A.LOAN_AMOUNT || ', ' || B.INTEREST_RATE || '%)' 
            END, '; ') AS QUALIFYING_LOAN_DETAILS
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION B
    ON A.APPLICATION_ID = B.APPLICATION_ID
WHERE UPPER(A.APPLICANT_RESIDENCE_STATE) = 'MA';

-- ============================================================================
-- QC 6: Missing Data Investigation
-- ============================================================================
SELECT 
    'Missing PII Data' AS ISSUE_TYPE,
    A.LOAN_ID,
    A.LEGACY_LOAN_ID,
    A.MEMBER_ID,
    A.ORIGINATION_DATE,
    'Missing Name Data' AS REASON
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN A
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII C
    ON A.MEMBER_ID::STRING = C.MEMBER_ID::STRING
    AND C.MEMBER_PII_END_DATE IS NULL
WHERE UPPER(A.APPLICANT_RESIDENCE_STATE) = 'MA'
    AND (C.FIRST_NAME IS NULL OR C.LAST_NAME IS NULL)
ORDER BY A.ORIGINATION_DATE DESC;