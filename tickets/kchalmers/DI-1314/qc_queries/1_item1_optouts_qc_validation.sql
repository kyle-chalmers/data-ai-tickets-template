-- DI-1314: Item 1 - CAN-SPAM Email Opt-Outs - QC Validation
-- Quality control checks for email opt-out deliverable
-- Date: 2025-10-14

-- ============================================================================
-- QC Test 1: Record Count Validation
-- ============================================================================
-- Expected: 592 unique CRB customers with email opt-outs

SELECT
    COUNT(*) as total_records,
    COUNT(DISTINCT UNIQUE_CUSTOMER_IDENTIFIER) as unique_customers,
    CASE
        WHEN COUNT(*) = COUNT(DISTINCT UNIQUE_CUSTOMER_IDENTIFIER)
        THEN 'PASS - No duplicate customers'
        ELSE 'FAIL - Duplicate customers found'
    END as deduplication_check
FROM (
    -- Inline the main query for validation
    SELECT UNIQUE_CUSTOMER_IDENTIFIER
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/1_item1_canspam_email_optouts.csv"
);

-- ============================================================================
-- QC Test 2: CRB Portfolio Filter Validation
-- ============================================================================
-- Expected: All records should have PORTFOLIOID IN ('32', '34', '54', '56')

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/1_item1_canspam_email_optouts.csv"
)
SELECT
    PORTFOLIOID,
    COUNT(*) as record_count,
    CASE
        WHEN PORTFOLIOID IN ('32', '34', '54', '56')
        THEN 'PASS'
        ELSE 'FAIL - Invalid portfolio'
    END as portfolio_check
FROM result_data
GROUP BY PORTFOLIOID
ORDER BY PORTFOLIOID;

-- ============================================================================
-- QC Test 3: Date Range Validation
-- ============================================================================
-- Expected: All DATE_OPTOUT_REQUESTED between 2023-10-01 and 2025-08-31

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/1_item1_canspam_email_optouts.csv"
)
SELECT
    MIN(DATE_OPTOUT_REQUESTED) as earliest_optout,
    MAX(DATE_OPTOUT_REQUESTED) as latest_optout,
    COUNT(*) as total_records,
    SUM(CASE
        WHEN DATE_OPTOUT_REQUESTED >= '2023-10-01'
         AND DATE_OPTOUT_REQUESTED <= '2025-08-31'
        THEN 1 ELSE 0
    END) as records_in_scope,
    CASE
        WHEN COUNT(*) = SUM(CASE
            WHEN DATE_OPTOUT_REQUESTED >= '2023-10-01'
             AND DATE_OPTOUT_REQUESTED <= '2025-08-31'
            THEN 1 ELSE 0
        END)
        THEN 'PASS - All dates in scope'
        ELSE 'FAIL - Dates outside scope found'
    END as date_range_check
FROM result_data;

-- ============================================================================
-- QC Test 4: NULL Value Check
-- ============================================================================
-- Expected: No NULLs in required fields

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/1_item1_canspam_email_optouts.csv"
)
SELECT
    'UNIQUE_CUSTOMER_IDENTIFIER' as field_name,
    SUM(CASE WHEN UNIQUE_CUSTOMER_IDENTIFIER IS NULL THEN 1 ELSE 0 END) as null_count,
    CASE WHEN SUM(CASE WHEN UNIQUE_CUSTOMER_IDENTIFIER IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END as null_check
FROM result_data
UNION ALL
SELECT
    'CUSTOMER_NAME',
    SUM(CASE WHEN CUSTOMER_NAME IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN CUSTOMER_NAME IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data
UNION ALL
SELECT
    'CUSTOMER_EMAIL_ADDRESS',
    SUM(CASE WHEN CUSTOMER_EMAIL_ADDRESS IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN CUSTOMER_EMAIL_ADDRESS IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data
UNION ALL
SELECT
    'DATE_OPTOUT_REQUESTED',
    SUM(CASE WHEN DATE_OPTOUT_REQUESTED IS NULL THEN 1 ELSE 0 END),
    CASE WHEN SUM(CASE WHEN DATE_OPTOUT_REQUESTED IS NULL THEN 1 ELSE 0 END) = 0
         THEN 'PASS' ELSE 'FAIL' END
FROM result_data;

-- ============================================================================
-- QC Test 5: Email Format Validation
-- ============================================================================
-- Expected: All email addresses contain '@' symbol

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/1_item1_canspam_email_optouts.csv"
)
SELECT
    COUNT(*) as total_emails,
    SUM(CASE WHEN CUSTOMER_EMAIL_ADDRESS LIKE '%@%' THEN 1 ELSE 0 END) as valid_email_format,
    SUM(CASE WHEN CUSTOMER_EMAIL_ADDRESS NOT LIKE '%@%' THEN 1 ELSE 0 END) as invalid_email_format,
    CASE
        WHEN SUM(CASE WHEN CUSTOMER_EMAIL_ADDRESS NOT LIKE '%@%' THEN 1 ELSE 0 END) = 0
        THEN 'PASS - All emails contain @'
        ELSE 'FAIL - Invalid email formats found'
    END as email_format_check
FROM result_data;

-- ============================================================================
-- QC Test 6: Portfolio Distribution
-- ============================================================================
-- Informational: Show distribution across CRB portfolios

WITH result_data AS (
    SELECT *
    FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/1_item1_canspam_email_optouts.csv"
)
SELECT
    PORTFOLIONAME,
    PORTFOLIOID,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM result_data
GROUP BY PORTFOLIONAME, PORTFOLIOID
ORDER BY customer_count DESC;

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Tests to Pass:
-- 1. Total records = 592
-- 2. Unique customers = 592 (no duplicates)
-- 3. All PORTFOLIOID in ('32', '34', '54', '56')
-- 4. All dates between 2023-10-01 and 2025-08-31
-- 5. No NULLs in required fields
-- 6. All emails contain '@' symbol
-- ============================================================================
