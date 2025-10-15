-- DI-1314: Credit Dispute System Discovery
-- Searching for FCRA dispute tracking tables
-- For Item 4 (Ref 7.A - Indirect, 7.B - Direct)
-- Date: 2025-10-14

-- =============================================================================
-- BUSINESS REQUIREMENT
-- =============================================================================
-- INDIRECT DISPUTES (7.A): Disputes received through credit bureaus
--   - Receipt Date, Source, Resolution Date, ACDV Control#
--
-- DIRECT DISPUTES (7.B): Disputes received directly from customers
--   - Receipt Date, Source, Resolution Date, AUD Control# (as applicable)
--
-- ACDV = Automated Consumer Dispute Verification (bureau protocol)
-- AUD = Automated Universal Dataform (bureau response format)

-- =============================================================================
-- PART 1: SEARCH FOR DISPUTE TABLES
-- =============================================================================

-- Search for dispute-related tables
SHOW TABLES LIKE '%DISPUTE%' IN DATABASE BUSINESS_INTELLIGENCE;

-- Search for ACDV/AUD tables
SHOW TABLES LIKE '%ACDV%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%AUD%' IN DATABASE BUSINESS_INTELLIGENCE;

-- Search for bureau communication tables
SHOW TABLES LIKE '%BUREAU%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%CREDIT%BUREAU%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 2: SEARCH SERVICER/CUSTOMER SERVICE TABLES
-- =============================================================================

-- Search for customer service/case management tables
SHOW TABLES LIKE '%CASE%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%TICKET%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%COMPLAINT%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%INQUIRY%' IN DATABASE BUSINESS_INTELLIGENCE;

-- Search for servicing tables
SHOW TABLES LIKE '%SERVIC%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%RESOLUTION%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 3: CHECK LOANPRO TABLES FOR DISPUTE DATA
-- =============================================================================

-- Search RAW_DATA_STORE.LOANPRO for dispute tables
SHOW TABLES LIKE '%DISPUTE%' IN SCHEMA RAW_DATA_STORE.LOANPRO;
SHOW TABLES LIKE '%COMPLAINT%' IN SCHEMA RAW_DATA_STORE.LOANPRO;
SHOW TABLES LIKE '%BUREAU%' IN SCHEMA RAW_DATA_STORE.LOANPRO;

-- =============================================================================
-- PART 4: SEARCH FOR METRO2/CREDIT REPORTING TABLES
-- =============================================================================

-- Metro2 is the credit reporting format - disputes might be tracked there
SHOW TABLES LIKE '%METRO%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%FURNISH%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%REPORT%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 5: CHECK DATA_STORE FOR DISPUTE-RELATED VIEWS
-- =============================================================================

-- List all tables in DATA_STORE to scan for relevant names
SHOW TABLES IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;

-- Search for communication/correspondence tables
SHOW TABLES LIKE '%COMMUNICATION%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;
SHOW TABLES LIKE '%CORRESPONDENCE%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;
SHOW TABLES LIKE '%LETTER%' IN SCHEMA BUSINESS_INTELLIGENCE.DATA_STORE;

-- =============================================================================
-- PART 6: CHECK FOR REGULATORY/COMPLIANCE TABLES
-- =============================================================================

-- Search for compliance/regulatory tables
SHOW TABLES LIKE '%COMPLIANCE%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%REGULATORY%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%FCRA%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- PART 7: SEARCH CRON_STORE FOR BATCH PROCESSES
-- =============================================================================

-- Dispute processing might be in CRON_STORE
SHOW TABLES LIKE '%DISPUTE%' IN SCHEMA BUSINESS_INTELLIGENCE.CRON_STORE;
SHOW TABLES LIKE '%BUREAU%' IN SCHEMA BUSINESS_INTELLIGENCE.CRON_STORE;
SHOW TABLES LIKE '%CREDIT%' IN SCHEMA BUSINESS_INTELLIGENCE.CRON_STORE;

-- =============================================================================
-- PART 8: CHECK VW_LOAN AND MVW_LOAN_TAPE FOR DISPUTE FLAGS
-- =============================================================================

-- Check if MVW_LOAN_TAPE has dispute indicators
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATA_STORE'
  AND TABLE_NAME = 'MVW_LOAN_TAPE'
  AND (COLUMN_NAME LIKE '%DISPUTE%'
    OR COLUMN_NAME LIKE '%INQUIRY%'
    OR COLUMN_NAME LIKE '%COMPLAINT%')
ORDER BY COLUMN_NAME;

-- Check VW_LOAN for dispute fields
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'ANALYTICS'
  AND TABLE_NAME = 'VW_LOAN'
  AND (COLUMN_NAME LIKE '%DISPUTE%'
    OR COLUMN_NAME LIKE '%INQUIRY%'
    OR COLUMN_NAME LIKE '%COMPLAINT%')
ORDER BY COLUMN_NAME;

-- =============================================================================
-- PART 9: SEARCH FOR THIRD-PARTY VENDOR TABLES
-- =============================================================================

-- Credit dispute management might be through a vendor
SHOW TABLES LIKE '%VENDOR%' IN DATABASE BUSINESS_INTELLIGENCE;
SHOW TABLES LIKE '%THIRD%PARTY%' IN DATABASE BUSINESS_INTELLIGENCE;

-- =============================================================================
-- NOTES AND NEXT STEPS
-- =============================================================================
--
-- CRITICAL QUESTIONS TO ANSWER:
-- 1. Does Happy Money have a formal dispute tracking system?
-- 2. Where are credit bureau disputes (ACDV) logged?
-- 3. Where are direct customer disputes logged?
-- 4. Are ACDV/AUD control numbers stored in our system?
-- 5. Is dispute management outsourced to a vendor?
--
-- POSSIBLE SCENARIOS:
-- A. Disputes tracked in LoanPro servicing module
-- B. Disputes tracked in separate compliance system
-- C. Disputes tracked in bureau communication tables
-- D. Disputes tracked manually (spreadsheets, emails)
--
-- IF NO TABLES FOUND:
-- - May need to consult with Compliance or Servicing teams
-- - Check for manual processes or external systems
-- - Verify if Happy Money has had any disputes in the timeframe
--
