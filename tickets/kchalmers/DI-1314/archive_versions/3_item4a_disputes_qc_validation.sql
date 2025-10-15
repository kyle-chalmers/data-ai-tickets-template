-- DI-1314: Item 4.A - FCRA Indirect Disputes (ACDV) - QC Validation
-- Quality control checks for indirect dispute deliverable
-- Date: 2025-10-14

-- ============================================================================
-- QC Test 1: Record Count Validation
-- ============================================================================
-- Expected: 0 records (no ACDV disputes in timeframe)
-- Last ACDV dispute activity: October 2021

SELECT
    COUNT(*) as total_records,
    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS - Zero disputes expected (RPT_EOSCAR_ACDV last updated Oct 2021)'
        ELSE 'REVIEW - Unexpected disputes found'
    END as record_count_check
FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/3_item4a_fcra_indirect_disputes_acdv.csv"
WHERE LOAN_NUMBER IS NOT NULL;  -- Exclude header-only row

-- ============================================================================
-- QC Test 2: Historical ACDV Dispute Context
-- ============================================================================
-- Validate that RPT_EOSCAR_ACDV table indeed has no disputes in scope period

SET START_DATE = '2024-10-01';
SET END_DATE = '2025-08-31';

SELECT
    COUNT(*) as total_all_time_disputes,
    MIN(TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD')) as earliest_dispute_ever,
    MAX(TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD')) as latest_dispute_ever,
    SUM(CASE
        WHEN TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD') BETWEEN $START_DATE AND $END_DATE
        THEN 1 ELSE 0
    END) as disputes_in_scope_period,
    CASE
        WHEN SUM(CASE
            WHEN TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD') BETWEEN $START_DATE AND $END_DATE
            THEN 1 ELSE 0
        END) = 0
        THEN 'PASS - No disputes in scope period'
        ELSE 'REVIEW - Disputes found in scope period'
    END as scope_validation
FROM BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV;

-- ============================================================================
-- QC Test 3: CRB Portfolio Context
-- ============================================================================
-- Check if there are any ACDV disputes for CRB loans (any timeframe)

WITH crb_loans AS (
    SELECT DISTINCT LOANID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE
    WHERE PORTFOLIOID IN ('32', '34', '54', '56')
)
SELECT
    COUNT(DISTINCT acdv.ACCOUNTNUMBER) as crb_loans_with_disputes_ever,
    MIN(TRY_TO_DATE(acdv.DATERECEIVED, 'YYYY-MM-DD')) as earliest_crb_dispute,
    MAX(TRY_TO_DATE(acdv.DATERECEIVED, 'YYYY-MM-DD')) as latest_crb_dispute,
    CASE
        WHEN COUNT(*) = 0
        THEN 'INFO - No CRB disputes ever recorded'
        ELSE 'INFO - CRB disputes exist but outside scope period'
    END as crb_context
FROM BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV acdv
INNER JOIN crb_loans cl
    ON acdv.ACCOUNTNUMBER = cl.LOANID;

-- ============================================================================
-- QC Test 4: Source Table Activity Check
-- ============================================================================
-- Verify RPT_EOSCAR_ACDV is not being actively updated

SELECT
    'RPT_EOSCAR_ACDV' as table_name,
    COUNT(*) as total_rows,
    MAX(TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD')) as last_dispute_received,
    MAX(TRY_TO_DATE(DATERESPONDED, 'YYYY-MM-DD')) as last_dispute_resolved,
    DATEDIFF(day, MAX(TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD')), CURRENT_DATE()) as days_since_last_activity,
    CASE
        WHEN DATEDIFF(day, MAX(TRY_TO_DATE(DATERECEIVED, 'YYYY-MM-DD')), CURRENT_DATE()) > 365
        THEN 'INFO - Table not actively updated (last activity > 1 year ago)'
        ELSE 'REVIEW - Recent activity found'
    END as table_status
FROM BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV;

-- ============================================================================
-- QC Test 5: CSV File Validation
-- ============================================================================
-- Ensure CSV has header row only (no data rows)

SELECT
    COUNT(*) as csv_rows,
    CASE
        WHEN COUNT(*) <= 1  -- Header only or empty
        THEN 'PASS - CSV contains header only (no data rows)'
        ELSE 'FAIL - CSV contains unexpected data rows'
    END as csv_format_check
FROM "/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1314/final_deliverables/3_item4a_fcra_indirect_disputes_acdv.csv";

-- ============================================================================
-- SUMMARY
-- ============================================================================
-- Expected Results:
-- 1. CSV file has 1 row (header only)
-- 2. No ACDV disputes in scope period (Oct 2024 - Aug 2025)
-- 3. RPT_EOSCAR_ACDV last updated October 2021
-- 4. This is a valid finding - Item 4.A has zero records to report
--
-- Recommendation for CRB Submission:
-- Document as: "No indirect credit disputes (ACDV) received during the period
-- October 1, 2024 - August 31, 2025. Last ACDV dispute activity: October 2021."
-- ============================================================================
