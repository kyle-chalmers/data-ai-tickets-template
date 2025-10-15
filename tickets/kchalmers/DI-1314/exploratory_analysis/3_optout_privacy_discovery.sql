-- DI-1314: Opt-Out and Privacy Discovery
-- Exploring VW_LOAN_CONTACT_RULES and related tables
-- For Items 1 (CAN-SPAM) and 2 (GLBA Privacy)
-- Date: 2025-10-14

-- =============================================================================
-- PART 1: VW_LOAN_CONTACT_RULES EXPLORATION
-- =============================================================================

-- Get full column list
DESCRIBE TABLE BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES;

-- Sample data from VW_LOAN_CONTACT_RULES
SELECT *
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES
LIMIT 50;

-- Check for suppression/opt-out columns
SELECT COLUMN_NAME, DATA_TYPE, COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ANALYTICS'
  AND TABLE_NAME = 'VW_LOAN_CONTACT_RULES'
ORDER BY ORDINAL_POSITION;

-- Look for CRB loans with contact rules
SELECT vcr.*
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES vcr
INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE mlt
    ON mlt.LOANID = vcr.LOAN_ID
WHERE mlt.PORTFOLIOID IN ('32', '34', '54', '56')
LIMIT 100;

-- =============================================================================
-- PART 2: SEARCH FOR EMAIL/COMMUNICATION OPT-OUT TABLES
-- =============================================================================

-- Search DATA_STORE for email-related tables
SHOW TABLES LIKE '%EMAIL%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;
SHOW TABLES LIKE '%SFMC%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;
SHOW TABLES LIKE '%OPT%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;
SHOW TABLES LIKE '%UNSUBSCRIBE%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;
SHOW TABLES LIKE '%SUPPRESS%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;

-- Search ANALYTICS schema
SHOW TABLES LIKE '%EMAIL%' IN SCHEMA BUSINESS_INTELLIGENCE.ANALYTICS;
SHOW TABLES LIKE '%OPT%' IN SCHEMA BUSINESS_INTELLIGENCE.ANALYTICS;
SHOW TABLES LIKE '%COMMUNICATION%' IN SCHEMA BUSINESS_INTELLIGENCE.ANALYTICS;

-- =============================================================================
-- PART 3: SEARCH FOR PRIVACY/CONSENT TABLES
-- =============================================================================

-- Search for privacy-related tables
SHOW TABLES LIKE '%PRIVACY%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%CONSENT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%GLBA%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%PREFERENCE%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%POLICY%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 4: CHECK VW_LEAD AND VW_APPLICATION FOR OPT-OUT DATA
-- =============================================================================

-- Check VW_LEAD structure for opt-out fields
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATA_STORE'
  AND TABLE_NAME = 'VW_LEAD'
  AND (COLUMN_NAME LIKE '%OPT%'
    OR COLUMN_NAME LIKE '%EMAIL%'
    OR COLUMN_NAME LIKE '%MARKETING%'
    OR COLUMN_NAME LIKE '%CONSENT%'
    OR COLUMN_NAME LIKE '%PRIVACY%')
ORDER BY COLUMN_NAME;

-- Check VW_APPLICATION structure
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATA_STORE'
  AND TABLE_NAME = 'VW_APPLICATION'
  AND (COLUMN_NAME LIKE '%OPT%'
    OR COLUMN_NAME LIKE '%EMAIL%'
    OR COLUMN_NAME LIKE '%MARKETING%'
    OR COLUMN_NAME LIKE '%CONSENT%'
    OR COLUMN_NAME LIKE '%PRIVACY%')
ORDER BY COLUMN_NAME;

-- =============================================================================
-- PART 5: CHECK VW_MEMBER_PII FOR EMAIL AND OPT-OUT DATA
-- =============================================================================

-- Check VW_MEMBER_PII structure
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ANALYTICS_PII'
  AND TABLE_NAME = 'VW_MEMBER_PII'
  AND (COLUMN_NAME LIKE '%OPT%'
    OR COLUMN_NAME LIKE '%EMAIL%'
    OR COLUMN_NAME LIKE '%MARKETING%'
    OR COLUMN_NAME LIKE '%CONSENT%'
    OR COLUMN_NAME LIKE '%SUPPRESS%')
ORDER BY COLUMN_NAME;

-- Sample email data for CRB loans
SELECT
    pii.MEMBER_ID,
    pii.FIRST_NAME,
    pii.LAST_NAME,
    pii.EMAIL,
    mlt.LOANID,
    mlt.PORTFOLIOID,
    mlt.PORTFOLIONAME
FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII pii
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    ON pii.MEMBER_ID = vl.MEMBER_ID
    AND pii.MEMBER_PII_END_DATE IS NULL
INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE mlt
    ON vl.LEAD_GUID = mlt.PAYOFFUID
WHERE mlt.PORTFOLIOID IN ('32', '34', '54', '56')
LIMIT 100;

-- =============================================================================
-- PART 6: SEARCH FOR EVENT/AUDIT TABLES
-- =============================================================================

-- Look for event tracking tables that might have opt-out events
SHOW TABLES LIKE '%EVENT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%AUDIT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%LOG%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%HISTORY%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 7: CHECK GENESYS TABLES FOR COMMUNICATION DATA
-- =============================================================================

-- Search for Genesys-related tables (might have email send history)
SHOW TABLES LIKE '%GENESYS%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 8: CHECK FOR MARKETING CAMPAIGN TABLES
-- =============================================================================

-- Search for marketing campaign tables
SHOW TABLES LIKE '%CAMPAIGN%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%MARKETING%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- NOTES
-- =============================================================================
--
-- ITEM 1 (CAN-SPAM) NEEDS:
-- - Customer opt-out list (requested date, processed date)
-- - Customer email addresses
-- - Date last email sent to customer
-- - Documentation of opt-out mechanisms
--
-- ITEM 2 (GLBA) NEEDS:
-- - Privacy notice provision date
-- - Information sharing opt-out requests (requested date, processed date)
-- - Different from marketing opt-outs
--
-- KEY QUESTIONS:
-- 1. Where are email opt-out events tracked?
-- 2. Where is "last email sent" date stored?
-- 3. How is privacy notice delivery tracked?
-- 4. How do we distinguish CAN-SPAM vs GLBA opt-outs?
--
