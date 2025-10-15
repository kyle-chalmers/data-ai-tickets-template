/*
DI-912: Validate ANALYTICS/BRIDGE Tables Have Required Fields
Purpose: Verify that replacement tables contain all required data for dist_auto CTE
Author: Hongxia Shi
Date: 2025-10-01
*/

-- ============================================================================
-- QC 1: VW_LOAN_CONTACT_RULES - Cease and Desist
-- ============================================================================
SELECT
    'VW_LOAN_CONTACT_RULES' as source_table,
    COUNT(DISTINCT LOAN_ID) as total_loans,
    COUNT(DISTINCT CASE WHEN CONTACT_RULE_END_DATE IS NULL THEN LOAN_ID END) as active_rules,
    SUM(CASE WHEN CEASE_AND_DESIST = TRUE AND CONTACT_RULE_END_DATE IS NULL THEN 1 ELSE 0 END) as cease_desist_count,
    ROUND(cease_desist_count * 100.0 / NULLIF(active_rules, 0), 2) as cease_desist_pct
FROM ANALYTICS.VW_LOAN_CONTACT_RULES;

-- Sample records
SELECT
    LOAN_ID,
    CEASE_AND_DESIST,
    CONTACT_RULE_START_DATE,
    CONTACT_RULE_END_DATE,
    SOURCE
FROM ANALYTICS.VW_LOAN_CONTACT_RULES
WHERE CEASE_AND_DESIST = TRUE
  AND CONTACT_RULE_END_DATE IS NULL
LIMIT 10;

-- ============================================================================
-- QC 2: VW_LOAN_BANKRUPTCY - Bankruptcy Flag
-- ============================================================================
SELECT
    'VW_LOAN_BANKRUPTCY' as source_table,
    COUNT(DISTINCT PAYOFF_UID) as total_loans,
    COUNT(DISTINCT CASE WHEN ACTIVE_RECORD_FLAG = TRUE THEN PAYOFF_UID END) as active_records,
    SUM(CASE WHEN BANKRUPTCY_FLAG = TRUE AND ACTIVE_RECORD_FLAG = TRUE THEN 1 ELSE 0 END) as bankruptcy_count,
    ROUND(bankruptcy_count * 100.0 / NULLIF(active_records, 0), 2) as bankruptcy_pct
FROM ANALYTICS.VW_LOAN_BANKRUPTCY;

-- Sample records
SELECT
    PAYOFF_UID,
    BANKRUPTCY_FLAG,
    ACTIVE_RECORD_FLAG,
    BANKRUPTCY_FILING_DATE,
    BANKRUPTCY_DISCHARGE_DATE
FROM ANALYTICS.VW_LOAN_BANKRUPTCY
WHERE BANKRUPTCY_FLAG = TRUE
  AND ACTIVE_RECORD_FLAG = TRUE
LIMIT 10;

-- ============================================================================
-- QC 3: VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT - Autopay
-- ============================================================================
SELECT
    'VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT' as source_table,
    COUNT(DISTINCT LOAN_ID) as total_loans,
    SUM(CASE WHEN LOWER(AUTOPAY_OPT_IN) = 'yes' THEN 1 ELSE 0 END) as autopay_enabled,
    SUM(CASE WHEN LOWER(AUTOPAY_OPT_IN) = 'no' THEN 1 ELSE 0 END) as autopay_disabled,
    SUM(CASE WHEN AUTOPAY_OPT_IN IS NULL THEN 1 ELSE 0 END) as autopay_null,
    ROUND(autopay_enabled * 100.0 / NULLIF(total_loans, 0), 2) as autopay_pct
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT;

-- Autopay value distribution
SELECT
    AUTOPAY_OPT_IN,
    COUNT(*) as loan_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT
GROUP BY AUTOPAY_OPT_IN
ORDER BY loan_count DESC;

-- Sample records
SELECT
    LOAN_ID,
    APPLICATION_GUID,
    AUTOPAY_OPT_IN,
    SMS_CONSENT_LS
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT
WHERE LOWER(AUTOPAY_OPT_IN) = 'yes'
LIMIT 10;

-- ============================================================================
-- QC 4: VW_LOAN - Base Table Join Capability
-- ============================================================================
SELECT
    'VW_LOAN' as source_table,
    COUNT(DISTINCT LOAN_ID) as total_loans,
    COUNT(DISTINCT LEAD_GUID) as total_payoff_uids,
    COUNT(DISTINCT CASE WHEN LEAD_GUID IS NOT NULL THEN LOAN_ID END) as loans_with_payoff_uid,
    ROUND(loans_with_payoff_uid * 100.0 / NULLIF(total_loans, 0), 2) as payoff_uid_coverage_pct
FROM ANALYTICS.VW_LOAN;

-- ============================================================================
-- QC 5: Cross-Table Join Test
-- ============================================================================
-- Test that all tables can be joined together successfully
SELECT
    'Join Test' as test_name,
    COUNT(DISTINCT L.LEAD_GUID) as unique_loans,
    COUNT(DISTINCT LCR.LOAN_ID) as has_contact_rules,
    COUNT(DISTINCT BK.PAYOFF_UID) as has_bankruptcy,
    COUNT(DISTINCT LOS.LOAN_ID) as has_loan_settings
FROM ANALYTICS.VW_LOAN as L
    LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
        ON L.LOAN_ID = LCR.LOAN_ID
        AND LCR.CONTACT_RULE_END_DATE IS NULL
    LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY as BK
        ON L.LEAD_GUID = BK.PAYOFF_UID
        AND BK.ACTIVE_RECORD_FLAG = TRUE
    LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as LOS
        ON L.LOAN_ID = LOS.LOAN_ID
LIMIT 100;

-- ============================================================================
-- QC SUMMARY
-- ============================================================================
-- Expected Results:
-- 1. VW_LOAN_CONTACT_RULES: Should have CEASE_AND_DESIST field with TRUE/FALSE values
-- 2. VW_LOAN_BANKRUPTCY: Should have BANKRUPTCY_FLAG with ACTIVE_RECORD_FLAG filter
-- 3. VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT: Should have AUTOPAY_OPT_IN with 'yes'/'no' values
-- 4. VW_LOAN: Should have LOAN_ID and LEAD_GUID for joins
-- 5. All tables should join successfully with minimal NULLs
