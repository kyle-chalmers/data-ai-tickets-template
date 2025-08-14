-- =====================================================================
-- GIACT Data Quality Control Script
-- =====================================================================
-- Purpose: QC queries for DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
-- Validates data integrity, completeness, and structure
-- =====================================================================

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

-- =====================================================================
-- BASIC DATA VALIDATION
-- =====================================================================

-- Total record count
SELECT 'Total Records' as metric, COUNT(*) as value
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Unique applications
SELECT 'Unique Applications', COUNT(DISTINCT APPLICATION_ID)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Unique borrowers
SELECT 'Unique Borrowers', COUNT(DISTINCT BORROWER_ID)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Records with account numbers
SELECT 'Records with Account Numbers', COUNT(CASE WHEN GIACT_ACCOUNT_NUMBER IS NOT NULL THEN 1 END)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Records with routing numbers
SELECT 'Records with Routing Numbers', COUNT(CASE WHEN GIACT_ROUTING_NUMBER IS NOT NULL THEN 1 END)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Records with bank names
SELECT 'Records with Bank Names', COUNT(CASE WHEN BANK_NAME IS NOT NULL THEN 1 END)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA;

-- =====================================================================
-- DATA COMPLETENESS ANALYSIS
-- =====================================================================

-- Account date completeness
SELECT 
    'Account Dates' as data_field,
    COUNT(CASE WHEN ACCOUNT_ADDED_DATE IS NOT NULL THEN 1 END) as records_with_data,
    COUNT(CASE WHEN ACCOUNT_ADDED_DATE IS NULL THEN 1 END) as records_without_data,
    ROUND(COUNT(CASE WHEN ACCOUNT_ADDED_DATE IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as completion_percentage
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Customer information completeness
SELECT 
    'Customer Names',
    COUNT(CASE WHEN PAYLOAD_FIRST_NAME IS NOT NULL AND PAYLOAD_LAST_NAME IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN PAYLOAD_FIRST_NAME IS NULL OR PAYLOAD_LAST_NAME IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN PAYLOAD_FIRST_NAME IS NOT NULL AND PAYLOAD_LAST_NAME IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- SSN completeness
SELECT 
    'SSN',
    COUNT(CASE WHEN PAYLOAD_SSN IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN PAYLOAD_SSN IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN PAYLOAD_SSN IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA

UNION ALL

-- Address completeness
SELECT 
    'Addresses',
    COUNT(CASE WHEN CITY IS NOT NULL AND STATE IS NOT NULL THEN 1 END),
    COUNT(CASE WHEN CITY IS NULL OR STATE IS NULL THEN 1 END),
    ROUND(COUNT(CASE WHEN CITY IS NOT NULL AND STATE IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2)
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA;

-- =====================================================================
-- GIACT INTEGRATION ANALYSIS
-- =====================================================================

-- GIACT integration versions
SELECT 
    'GIACT Integration Versions' as analysis,
    GIACT_INTEGRATION_NAME,
    COUNT(*) as record_count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
GROUP BY GIACT_INTEGRATION_NAME;

-- Verification response code distribution
SELECT 
    'Verification Response Codes' as analysis,
    VERIFICATION_RESPONSE,
    CASE 
        WHEN VERIFICATION_RESPONSE = 1 THEN 'Account Verified'
        WHEN VERIFICATION_RESPONSE = 2 THEN 'Account Verified with Conditions'
        WHEN VERIFICATION_RESPONSE = 3 THEN 'Account Not Verified'
        WHEN VERIFICATION_RESPONSE = 4 THEN 'Account Closed'
        WHEN VERIFICATION_RESPONSE = 5 THEN 'Account Not Found'
        WHEN VERIFICATION_RESPONSE = 6 THEN 'Unable to Verify'
        WHEN VERIFICATION_RESPONSE = 9 THEN 'Other Response'
        ELSE 'Unknown (' || VERIFICATION_RESPONSE::VARCHAR || ')'
    END as response_description,
    COUNT(*) as count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
GROUP BY VERIFICATION_RESPONSE, response_description;

-- Account type distribution
SELECT 
    'Account Types' as analysis,
    BANK_ACCOUNT_TYPE,
    COUNT(*) as count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
WHERE BANK_ACCOUNT_TYPE IS NOT NULL
GROUP BY BANK_ACCOUNT_TYPE;

-- =====================================================================
-- DATE RANGE AND TEMPORAL ANALYSIS
-- =====================================================================

-- Account opening date range
SELECT 
    'Account Date Range' as analysis,
    MIN(ACCOUNT_ADDED_DATE) as earliest_date,
    MAX(ACCOUNT_ADDED_DATE) as latest_date,
    DATEDIFF(DAY, MIN(ACCOUNT_ADDED_DATE), MAX(ACCOUNT_ADDED_DATE)) as date_span_days
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
WHERE ACCOUNT_ADDED_DATE IS NOT NULL;

-- Account age distribution
SELECT 
    'Account Age Distribution' as analysis,
    CASE 
        WHEN ACCOUNT_AGE_DAYS IS NULL THEN 'No Date Available'
        WHEN ACCOUNT_AGE_DAYS <= 30 THEN '0-30 days'
        WHEN ACCOUNT_AGE_DAYS <= 90 THEN '31-90 days'
        WHEN ACCOUNT_AGE_DAYS <= 365 THEN '91-365 days'
        WHEN ACCOUNT_AGE_DAYS <= 1095 THEN '1-3 years'
        ELSE '3+ years'
    END as age_category,
    COUNT(*) as count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
GROUP BY age_category;

-- =====================================================================
-- TOP BANKS AND ROUTING NUMBERS
-- =====================================================================

-- Top 10 banks by volume
SELECT 
    'Top Banks' as analysis,
    BANK_NAME,
    COUNT(*) as account_count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
WHERE BANK_NAME IS NOT NULL
GROUP BY BANK_NAME
LIMIT 10;

-- Top 10 routing numbers by volume
SELECT 
    'Top Routing Numbers' as analysis,
    GIACT_ROUTING_NUMBER,
    COUNT(*) as account_count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
WHERE GIACT_ROUTING_NUMBER IS NOT NULL
GROUP BY GIACT_ROUTING_NUMBER
LIMIT 10;

-- =====================================================================
-- ERROR AND NULL VALUE ANALYSIS
-- =====================================================================

-- Records with error messages
SELECT 
    'Error Analysis' as analysis,
    COUNT(CASE WHEN ERROR_MESSAGE IS NOT NULL THEN 1 END) as records_with_errors,
    COUNT(CASE WHEN ERROR_MESSAGE IS NULL THEN 1 END) as records_without_errors,
    ROUND(COUNT(CASE WHEN ERROR_MESSAGE IS NOT NULL THEN 1 END) * 100.0 / COUNT(*), 2) as error_percentage
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA;

-- Sample error messages (if any)
SELECT 
    'Error Messages Sample' as analysis,
    ERROR_MESSAGE,
    COUNT(*) as occurrence_count
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
WHERE ERROR_MESSAGE IS NOT NULL
GROUP BY ERROR_MESSAGE
LIMIT 5;

-- =====================================================================
-- OSCILAR TIMESTAMP ANALYSIS
-- =====================================================================

-- Oscilar timestamp range
SELECT 
    'Oscilar Processing Range' as analysis,
    MIN(OSCILAR_TIMESTAMP) as earliest_processing,
    MAX(OSCILAR_TIMESTAMP) as latest_processing,
    DATEDIFF(DAY, MIN(OSCILAR_TIMESTAMP), MAX(OSCILAR_TIMESTAMP)) as processing_span_days
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
WHERE OSCILAR_TIMESTAMP IS NOT NULL;

-- =====================================================================
-- SAMPLE DATA PREVIEW
-- =====================================================================

-- Sample records for manual review
SELECT 
    APPLICATION_ID,
    BORROWER_ID,
    PAYLOAD_FIRST_NAME,
    PAYLOAD_LAST_NAME,
    BANK_NAME,
    GIACT_ROUTING_NUMBER,
    ACCOUNT_AGE_DAYS,
    VERIFICATION_RESPONSE,
    OSCILAR_TIMESTAMP
FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA
LIMIT 10;

-- =====================================================================
-- QC COMPLETE
-- =====================================================================