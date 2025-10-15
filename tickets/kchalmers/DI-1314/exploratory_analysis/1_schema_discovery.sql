-- DI-1314: Schema Discovery for CRB Compliance Testing Data Pulls
-- Research Phase: Finding tables for credit reporting, disputes, and opt-outs
-- Date: 2025-10-14

-- =============================================================================
-- PART 1: CREDIT REPORTING & BUREAU TABLES (For FCRA Negative Reporting - Item 3)
-- =============================================================================

-- Search for credit reporting tables
SHOW TABLES LIKE '%CREDIT%REPORT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%BUREAU%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%DELINQ%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%FURNISH%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%METRO%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 2: DISPUTE TABLES (For FCRA Disputes - Item 4)
-- =============================================================================

-- Search for dispute-related tables
SHOW TABLES LIKE '%DISPUTE%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%ACDV%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%AUD%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 3: OPT-OUT & PRIVACY TABLES (For CAN-SPAM & GLBA - Items 1 & 2)
-- =============================================================================

-- Search for opt-out and privacy tables
SHOW TABLES LIKE '%OPT%OUT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%UNSUBSCRIBE%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%SUPPRESS%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%PRIVACY%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%CONSENT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%PREFERENCE%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 4: MVW_LOAN_TAPE_DAILY_HISTORY EXPLORATION
-- =============================================================================

-- Describe structure
DESCRIBE TABLE BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY;

-- Sample CRB loans in daily history
SELECT *
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE PORTFOLIOID IN ('32', '34', '54', '56')
  AND ASOFDATE >= '2024-10-01'
LIMIT 100;

-- Check DAYSPASTDUE values for CRB loans
SELECT
    PORTFOLIOID,
    PORTFOLIONAME,
    DAYSPASTDUE,
    COUNT(*) as LOAN_COUNT,
    MIN(ASOFDATE) as FIRST_DATE,
    MAX(ASOFDATE) as LAST_DATE
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
WHERE PORTFOLIOID IN ('32', '34', '54', '56')
  AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'
GROUP BY PORTFOLIOID, PORTFOLIONAME, DAYSPASTDUE
ORDER BY PORTFOLIOID, DAYSPASTDUE;

-- =============================================================================
-- PART 5: VW_LOAN_CONTACT_RULES EXPLORATION
-- =============================================================================

-- Describe structure
DESCRIBE TABLE BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES;

-- Sample records
SELECT *
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES
LIMIT 100;

-- Check for suppression/opt-out related fields
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ANALYTICS'
  AND TABLE_NAME = 'VW_LOAN_CONTACT_RULES'
  AND (COLUMN_NAME LIKE '%OPT%'
    OR COLUMN_NAME LIKE '%SUPPRESS%'
    OR COLUMN_NAME LIKE '%EMAIL%'
    OR COLUMN_NAME LIKE '%MARKETING%')
ORDER BY COLUMN_NAME;

-- =============================================================================
-- PART 6: DATA_STORE SCHEMA EXPLORATION
-- =============================================================================

-- Search DATA_STORE schema for relevant tables
SHOW TABLES IN DATA_STORE;

-- Search for email/communication tables
SHOW TABLES LIKE '%EMAIL%' IN SCHEMA DATA_STORE;
SHOW TABLES LIKE '%SFMC%' IN SCHEMA DATA_STORE;
SHOW TABLES LIKE '%GENESYS%' IN SCHEMA DATA_STORE;
SHOW TABLES LIKE '%COMMUNICATION%' IN SCHEMA DATA_STORE;
