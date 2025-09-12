-- BUSINESS IMPACT ANALYSIS: VW_LOAN_BANKRUPTCY vs DATA_STORE.VW_LOAN_COLLECTION
-- Analyzing the impact of replacing bankruptcy suppression logic in BI-2482 Outbound List Generation
-- Ticket: DI-1239 | Analysis Date: 2025-01-11

-- **CURRENT STATE**: BI-2482 uses DATA_STORE.VW_LOAN_COLLECTION.BANKRUPTCY_FLAG = 'Y'
-- **PROPOSED STATE**: Replace with BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY

-- =====================================================================================
-- 1. CURRENT BANKRUPTCY SUPPRESSIONS FROM DATA_STORE.VW_LOAN_COLLECTION
-- =====================================================================================
SELECT 
    'Current VW_LOAN_COLLECTION Suppressions' as analysis_section,
    COUNT(*) as total_suppressed_loans,
    COUNT(DISTINCT PAYOFF_UID) as unique_payoff_uids
FROM DATA_STORE.VW_LOAN_COLLECTION
WHERE BANKRUPTCY_FLAG = 'Y';

-- =====================================================================================
-- 2. PROPOSED BANKRUPTCY SUPPRESSIONS FROM VW_LOAN_BANKRUPTCY
-- =====================================================================================
-- Total loans that would be suppressed using new view (all bankruptcy records)
SELECT 
    'Proposed VW_LOAN_BANKRUPTCY Total Suppressions' as analysis_section,
    COUNT(DISTINCT LOAN_ID) as total_suppressed_loans,
    COUNT(DISTINCT LOAN_ID) as unique_loan_ids
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY;

-- Most recent active bankruptcies only (recommended approach)
SELECT 
    'Proposed VW_LOAN_BANKRUPTCY Most Recent Active Only' as analysis_section,
    COUNT(*) as total_suppressed_loans,
    COUNT(DISTINCT LOAN_ID) as unique_loan_ids
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY
WHERE MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y';

-- =====================================================================================
-- 3. DIRECT COMPARISON: OLD vs NEW SUPPRESSION COUNTS
-- =====================================================================================
WITH current_suppressions AS (
    SELECT 
        PAYOFF_UID as identifier,
        'VW_LOAN_COLLECTION' as source
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE BANKRUPTCY_FLAG = 'Y'
),

proposed_suppressions_all AS (
    SELECT 
        vl.LEAD_GUID as identifier,
        'VW_LOAN_BANKRUPTCY_ALL' as source
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl 
        ON vb.LOAN_ID = vl.LOAN_ID
),

proposed_suppressions_active AS (
    SELECT 
        vl.LEAD_GUID as identifier,
        'VW_LOAN_BANKRUPTCY_ACTIVE' as source
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl 
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y'
)

SELECT 
    'Suppression Count Comparison' as analysis_section,
    'Current VW_LOAN_COLLECTION' as suppression_source,
    COUNT(*) as suppression_count
FROM current_suppressions
UNION ALL
SELECT 
    'Suppression Count Comparison' as analysis_section,
    'Proposed VW_LOAN_BANKRUPTCY (All Records)' as suppression_source,
    COUNT(*) as suppression_count
FROM proposed_suppressions_all
UNION ALL
SELECT 
    'Suppression Count Comparison' as analysis_section,
    'Proposed VW_LOAN_BANKRUPTCY (Active Only)' as suppression_source,
    COUNT(*) as suppression_count
FROM proposed_suppressions_active;

-- =====================================================================================
-- 4. LOAN OVERLAP ANALYSIS: Which loans are in both/either system
-- =====================================================================================
WITH current_suppressions AS (
    SELECT DISTINCT PAYOFF_UID as lead_guid
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE BANKRUPTCY_FLAG = 'Y'
),

proposed_suppressions AS (
    SELECT DISTINCT vl.LEAD_GUID as lead_guid
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl 
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y'
)

SELECT 
    'Overlap Analysis' as analysis_section,
    CASE 
        WHEN c.lead_guid IS NOT NULL AND p.lead_guid IS NOT NULL THEN 'In Both Systems'
        WHEN c.lead_guid IS NOT NULL AND p.lead_guid IS NULL THEN 'Only in VW_LOAN_COLLECTION'
        WHEN c.lead_guid IS NULL AND p.lead_guid IS NOT NULL THEN 'Only in VW_LOAN_BANKRUPTCY'
    END as overlap_category,
    COUNT(*) as loan_count
FROM current_suppressions c
FULL OUTER JOIN proposed_suppressions p ON c.lead_guid = p.lead_guid
GROUP BY 
    CASE 
        WHEN c.lead_guid IS NOT NULL AND p.lead_guid IS NOT NULL THEN 'In Both Systems'
        WHEN c.lead_guid IS NOT NULL AND p.lead_guid IS NULL THEN 'Only in VW_LOAN_COLLECTION'
        WHEN c.lead_guid IS NULL AND p.lead_guid IS NOT NULL THEN 'Only in VW_LOAN_BANKRUPTCY'
    END
ORDER BY loan_count DESC;

-- =====================================================================================
-- 5. EXISTING GLOBAL SUPPRESSION OVERLAP ANALYSIS
-- =====================================================================================
-- Check how many loans from VW_LOAN_BANKRUPTCY already have other global suppressions
WITH new_bankruptcy_suppressions AS (
    SELECT DISTINCT vl.LEAD_GUID as payoff_uid
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl 
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y'
),

existing_global_suppressions AS (
    SELECT DISTINCT 
        PAYOFFUID,
        SUPPRESSION_REASON
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
    WHERE SUPPRESSION_TYPE = 'Global'
    AND LOAD_DATE = CURRENT_DATE
    AND SUPPRESSION_REASON != 'Bankruptcy'  -- Exclude current bankruptcy suppressions
)

SELECT 
    'Global Suppression Overlap' as analysis_section,
    CASE 
        WHEN egs.PAYOFFUID IS NOT NULL THEN 'Already Has Other Global Suppression'
        ELSE 'New Global Suppression Only'
    END as suppression_status,
    COUNT(*) as loan_count
FROM new_bankruptcy_suppressions nbs
LEFT JOIN existing_global_suppressions egs ON nbs.payoff_uid = egs.PAYOFFUID
GROUP BY 
    CASE 
        WHEN egs.PAYOFFUID IS NOT NULL THEN 'Already Has Other Global Suppression'
        ELSE 'New Global Suppression Only'
    END
ORDER BY loan_count DESC;

-- =====================================================================================
-- 6. BREAKDOWN OF EXISTING GLOBAL SUPPRESSIONS FOR BANKRUPTCY LOANS
-- =====================================================================================
WITH new_bankruptcy_suppressions AS (
    SELECT DISTINCT vl.LEAD_GUID as payoff_uid
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl 
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y'
)

SELECT 
    'Global Suppression Breakdown for Bankruptcy Loans' as analysis_section,
    egs.SUPPRESSION_REASON,
    COUNT(DISTINCT egs.PAYOFFUID) as loan_count,
    ROUND(COUNT(DISTINCT egs.PAYOFFUID) * 100.0 / 
          (SELECT COUNT(*) FROM new_bankruptcy_suppressions), 2) as pct_of_bankruptcy_loans
FROM new_bankruptcy_suppressions nbs
INNER JOIN BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION egs 
    ON nbs.payoff_uid = egs.PAYOFFUID
WHERE egs.SUPPRESSION_TYPE = 'Global'
    AND egs.LOAD_DATE = CURRENT_DATE
    AND egs.SUPPRESSION_REASON != 'Bankruptcy'
GROUP BY egs.SUPPRESSION_REASON
ORDER BY loan_count DESC;

-- =====================================================================================
-- 7. NET NEW SUPPRESSIONS IMPACT
-- =====================================================================================
-- Loans that would be newly suppressed by switching to VW_LOAN_BANKRUPTCY
WITH current_bankruptcy_suppressions AS (
    SELECT DISTINCT PAYOFF_UID as lead_guid
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE BANKRUPTCY_FLAG = 'Y'
),

proposed_bankruptcy_suppressions AS (
    SELECT DISTINCT vl.LEAD_GUID as lead_guid
    FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl 
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE vb.MOST_RECENT_ACTIVE_BANKRUPTCY = 'Y'
),

all_existing_global_suppressions AS (
    SELECT DISTINCT PAYOFFUID as lead_guid
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
    WHERE SUPPRESSION_TYPE = 'Global'
    AND LOAD_DATE = CURRENT_DATE
),

net_new_suppressions AS (
    SELECT p.lead_guid
    FROM proposed_bankruptcy_suppressions p
    LEFT JOIN all_existing_global_suppressions egs ON p.lead_guid = egs.lead_guid
    WHERE egs.lead_guid IS NULL  -- Not already globally suppressed for any reason
)

SELECT 
    'Net New Suppression Impact' as analysis_section,
    'Loans that would be newly globally suppressed' as metric,
    COUNT(*) as loan_count
FROM net_new_suppressions

UNION ALL

SELECT 
    'Net New Suppression Impact' as analysis_section,
    'Total proposed bankruptcy suppressions' as metric,
    COUNT(*) as loan_count
FROM proposed_bankruptcy_suppressions

UNION ALL

SELECT 
    'Net New Suppression Impact' as analysis_section,
    'Current bankruptcy suppressions' as metric,
    COUNT(*) as loan_count
FROM current_bankruptcy_suppressions;

-- =====================================================================================
-- 8. BUSINESS LOGIC VALIDATION: PETITION STATUS ANALYSIS
-- =====================================================================================
-- Analyze which petition statuses are included in the new suppressions
-- Business rule: Dismissed/Discharged bankruptcies should NOT suppress outbound communications
SELECT 
    'Business Logic Validation' as analysis_section,
    vb.PETITION_STATUS,
    vb.ACTIVE,
    vb.MOST_RECENT_ACTIVE_BANKRUPTCY,
    COUNT(*) as record_count,
    COUNT(DISTINCT vb.LOAN_ID) as unique_loans
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY vb
GROUP BY vb.PETITION_STATUS, vb.ACTIVE, vb.MOST_RECENT_ACTIVE_BANKRUPTCY
ORDER BY vb.ACTIVE DESC, vb.MOST_RECENT_ACTIVE_BANKRUPTCY DESC, record_count DESC;