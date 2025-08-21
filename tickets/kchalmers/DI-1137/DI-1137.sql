-- =============================================================================
-- DI-1137: Massachusetts Regulator Request - Loan Analysis
-- =============================================================================
-- Purpose: Analyze loan data for Massachusetts regulator license application
-- 
-- Business Questions:
-- 1. Has Happy Money processed loans ≤$6,000 with rates >12% for MA residents?
-- 2. Has Happy Money serviced loans for Massachusetts residents?
--
-- Data Source: MVW_LOAN_TAPE (authoritative historical loan data)
-- Output: 4 separate CSV files covering different analysis scenarios
-- =============================================================================

-- =============================================================================
-- PARAMETERS
-- =============================================================================
SET MAX_LOAN_AMOUNT = 6000;           -- $6,000 loan amount threshold
SET MIN_INTEREST_RATE = 12.0;         -- 12% per annum interest rate threshold  
SET STATE_FILTER = 'MA';              -- Massachusetts state filter

-- =============================================================================
-- QUERY 1: Natively Originated MA Limited Loan Population
-- =============================================================================
-- Purpose: Find loans ≤$6,000 with interest rates >12% for native MA residents
-- Business Context: Answers regulator question about small dollar, high rate loans
-- Filter Logic: 
--   - Native MA residents (APPLICANTRESIDENCESTATE = 'MA')
--   - Loan amount ≤ $6,000
--   - Interest rate > 12% (stored as decimal: >0.12)
-- Expected Result: 3 loans totaling $16,000
-- =============================================================================

SELECT
    LOANID,                          -- Unique loan identifier
    PAYOFFUID,                       -- PayOff system identifier
    APPLICANTRESIDENCESTATE,         -- State where applicant resided at origination
    LOANAMOUNT,                      -- Principal loan amount
    INTERESTRATE,                    -- Interest rate (decimal format: 0.12 = 12%)
    APR,                            -- Annual Percentage Rate
    ORIGINATIONDATE,                 -- Date loan was originated
    STATUS,                         -- Current loan status (Paid in Full, Charge off, etc.)
    PORTFOLIONAME,                  -- Portfolio classification
    PLACEMENT_STATUS                -- Collection placement status
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER      -- Native MA residents only
  AND INTERESTRATE > ($MIN_INTEREST_RATE/100.0)           -- Interest rate > 12% (convert to decimal)
  AND LOANAMOUNT <= $MAX_LOAN_AMOUNT;                      -- Loan amount ≤ $6,000

-- =============================================================================
-- QUERY 2: Current MA Residents with Limited Loans  
-- =============================================================================
-- Purpose: Find loans ≤$6,000 with rates >12% for customers who currently reside in MA
-- Business Context: Captures loans to customers who moved to MA after origination
-- Filter Logic:
--   - NOT native MA residents (APPLICANTRESIDENCESTATE <> 'MA')
--   - Currently live in MA (CURRENT_STATE = 'MA')
--   - Loan amount ≤ $6,000 
--   - Interest rate > 12%
-- Join Strategy: Loan Tape → VW_LOAN → Member PII for current address
-- =============================================================================

SELECT
    A.LOANID,                        -- Unique loan identifier
    A.PAYOFFUID,                     -- PayOff system identifier  
    A.APPLICANTRESIDENCESTATE,       -- Original application state (NOT MA)
    A.LOANAMOUNT,                    -- Principal loan amount
    A.INTERESTRATE,                  -- Interest rate (decimal format)
    A.APR,                          -- Annual Percentage Rate
    A.ORIGINATIONDATE,               -- Date loan was originated
    A.STATUS,                       -- Current loan status
    A.PORTFOLIONAME,                -- Portfolio classification
    A.PLACEMENT_STATUS,             -- Collection placement status
    B.STATE as CURRENT_STATE        -- Customer's current state of residence
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE A
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN C
    ON A.PAYOFFUID = C.LEAD_GUID                           -- Link loan tape to analytical view
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII B  
    ON B.MEMBER_ID = C.MEMBER_ID                           -- Link to current customer address
    AND B.MEMBER_PII_END_DATE IS NULL                      -- Use active address record
WHERE UPPER(APPLICANTRESIDENCESTATE) <> $STATE_FILTER     -- NOT native MA residents
  AND INTERESTRATE > ($MIN_INTEREST_RATE/100.0)           -- Interest rate > 12%
  AND LOANAMOUNT <= $MAX_LOAN_AMOUNT                       -- Loan amount ≤ $6,000
  AND UPPER(B.STATE) = $STATE_FILTER;                     -- Currently live in MA

-- =============================================================================
-- QUERY 3: All Natively Originated MA Loans
-- =============================================================================
-- Purpose: Comprehensive list of all loans originated to MA residents
-- Business Context: Answers regulator question about total MA loan servicing
-- Filter Logic: All loans where APPLICANTRESIDENCESTATE = 'MA' (no amount/rate limits)
-- Expected Result: 61 loans totaling $1,030,900
-- =============================================================================

SELECT
    LOANID,                          -- Unique loan identifier
    PAYOFFUID,                       -- PayOff system identifier
    APPLICANTRESIDENCESTATE,         -- State where applicant resided (MA)
    LOANAMOUNT,                      -- Principal loan amount (all amounts)
    INTERESTRATE,                    -- Interest rate (all rates)
    APR,                            -- Annual Percentage Rate
    ORIGINATIONDATE,                 -- Date loan was originated
    STATUS,                         -- Current loan status
    PORTFOLIONAME,                  -- Portfolio classification
    PLACEMENT_STATUS                -- Collection placement status
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
WHERE UPPER(APPLICANTRESIDENCESTATE) = $STATE_FILTER;     -- All native MA residents
-- Rate and amount filters commented out for comprehensive analysis
-- AND INTERESTRATE > ($MIN_INTEREST_RATE/100.0)
-- AND LOANAMOUNT <= $MAX_LOAN_AMOUNT;

-- =============================================================================
-- QUERY 4: All Current MA Residents with Loans
-- =============================================================================
-- Purpose: All loans for customers who currently reside in MA (regardless of origin)
-- Business Context: Comprehensive current MA resident loan servicing analysis
-- Filter Logic: Customers currently living in MA (no amount/rate limits)
-- Join Strategy: Loan Tape → VW_LOAN → Member PII for current address verification
-- =============================================================================

SELECT
    A.LOANID,                        -- Unique loan identifier
    A.PAYOFFUID,                     -- PayOff system identifier
    A.APPLICANTRESIDENCESTATE,       -- Original application state (any state)
    A.LOANAMOUNT,                    -- Principal loan amount (all amounts)
    A.INTERESTRATE,                  -- Interest rate (all rates)
    A.APR,                          -- Annual Percentage Rate
    A.ORIGINATIONDATE,               -- Date loan was originated
    A.STATUS,                       -- Current loan status
    A.PORTFOLIONAME,                -- Portfolio classification
    A.PLACEMENT_STATUS,             -- Collection placement status
    B.STATE as CURRENT_STATE        -- Customer's current state (MA)
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE A
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN C
    ON A.PAYOFFUID = C.LEAD_GUID                           -- Link loan tape to analytical view
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII B
    ON B.MEMBER_ID = C.MEMBER_ID                           -- Link to current customer address
    AND B.MEMBER_PII_END_DATE IS NULL                      -- Use active address record
WHERE UPPER(APPLICANTRESIDENCESTATE) <> $STATE_FILTER     -- NOT native MA (to avoid duplicates with Query 3)
  AND UPPER(B.STATE) = $STATE_FILTER;                     -- Currently live in MA
-- Rate and amount filters commented out for comprehensive analysis
-- AND INTERESTRATE > ($MIN_INTEREST_RATE/100.0)
-- AND LOANAMOUNT <= $MAX_LOAN_AMOUNT

-- =============================================================================
-- EXECUTION NOTES:
-- =============================================================================
-- 1. Run each query separately and export results as CSV
-- 2. CORRECTED: Use IS NULL for active PII records (not IS NOT NULL)
-- 3. MVW_LOAN_TAPE is already unique by LOANID (no deduplication needed)
-- 4. Interest rates in loan tape are stored as decimals (0.12 = 12%)
-- 5. MVW_LOAN_TAPE provides comprehensive historical coverage (2017-2022)
-- 6. PII joins may not return names for all loans (loan tape limitation)
-- =============================================================================