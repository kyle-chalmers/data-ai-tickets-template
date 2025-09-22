-- COMPLETE SUPPRESSION TRANSITION ANALYSIS - OPTION B
-- Comprehensive analysis combining all suppression impacts with proper exclusions
-- Ticket: DI-1239 | Analysis Date: 2025-01-12
--
-- EXCLUSION CRITERIA APPLIED:
-- 1. Filing date must be >= origination date 
-- 2. Petition status must NOT be "Remove Bankruptcy"
-- 3. Net new = loans with ZERO current global suppressions (not just bankruptcy)

-- =====================================================================================
-- SECTION 1: SUMMARY TRANSITION METRICS
-- =====================================================================================

WITH all_current_global_suppressions AS (SELECT DISTINCT LEAD_GUID FROM
(SELECT DISTINCT PAYOFFUID as lead_guid
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_TYPE = 'Global'  -- ALL global suppressions (any reason)
AND LOAD_DATE = CURRENT_DATE
UNION
SELECT PAYOFFUID AS LEAD_GUID
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_REASON ILIKE ANY ('%DNC:%')
AND LOAD_DATE = CURRENT_DATE
GROUP BY PAYOFFUID
HAVING COUNT(DISTINCT SUPPRESSION_REASON) >= 4)),

all_current_global_suppressions AS (SELECT DISTINCT LEAD_GUID FROM
(SELECT DISTINCT PAYOFFUID as lead_guid
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_TYPE = 'Global'  -- ALL global suppressions (any reason)
AND LOAD_DATE = CURRENT_DATE
UNION
SELECT PAYOFFUID AS LEAD_GUID
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_REASON ILIKE ANY ('%DNC:%')
AND LOAD_DATE = CURRENT_DATE
GROUP BY PAYOFFUID
HAVING COUNT(DISTINCT SUPPRESSION_REASON) >= 4)),

proposed_suppressions AS (
    SELECT vl.LEAD_GUID as lead_guid,
       vl.LOAN_ID,
       vl.ORIGINATION_DATE,
       vb.* EXCLUDE (LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE (PETITION_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (PROCESS_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (vb.MOST_RECENT_BANKRUPTCY = 'Y'  -- Option B: All most recent bankruptcies
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE  -- Filing on or after origination
            AND COALESCE(vb.PETITION_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed')  -- Exclude remove bankruptcy
            AND COALESCE(vb.PROCESS_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed'))
),

suppressions_lost AS (
    SELECT c.lead_guid
    FROM all_current_global_suppressions c
    LEFT JOIN proposed_suppressions p ON c.lead_guid = p.lead_guid
    WHERE p.lead_guid IS NULL  -- Currently suppressed for bankruptcy but won't be under Option B
),

net_new_suppressions AS (
    SELECT p.lead_guid, p.LOAN_ID, p.ORIGINATION_DATE
    FROM proposed_suppressions p
    LEFT JOIN all_current_global_suppressions ags ON p.lead_guid = ags.lead_guid
    WHERE ags.lead_guid IS NULL  -- Will be suppressed under Option B but has ZERO current global suppressions
)

-- Summary metrics
SELECT '1_TRANSITION_SUMMARY' as analysis_section, 'Current Bankruptcy Suppressions' as metric, COUNT(*) as count FROM all_current_global_suppressions
UNION ALL
SELECT '1_TRANSITION_SUMMARY' as analysis_section, 'Current Global Suppressions (All Reasons)' as metric, COUNT(*) as count FROM all_current_global_suppressions  
UNION ALL
SELECT '1_TRANSITION_SUMMARY' as analysis_section, 'Proposed Suppressions (Option B with Exclusions)' as metric, COUNT(*) as count FROM proposed_suppressions  
UNION ALL
SELECT '1_TRANSITION_SUMMARY' as analysis_section, 'Bankruptcy Suppressions That Will Be Lost' as metric, COUNT(*) as count FROM suppressions_lost
UNION ALL
SELECT '1_TRANSITION_SUMMARY' as analysis_section, 'Net New Suppressions (Zero Current Suppressions)' as metric, COUNT(*) as count FROM net_new_suppressions
UNION ALL
SELECT '1_TRANSITION_SUMMARY' as analysis_section, 'Net Change in Bankruptcy Suppressions' as metric, 
       (SELECT COUNT(*) FROM proposed_suppressions) - (SELECT COUNT(*) FROM all_current_global_suppressions) as count

UNION ALL

-- =====================================================================================
-- SECTION 2: NET NEW SUPPRESSIONS CHARACTERISTICS (Zero Current Suppressions)
-- =====================================================================================

-- Chapter Distribution for Net New Suppressions
SELECT '2_NET_NEW_CHARACTERISTICS' as analysis_section,
       CONCAT('Chapter: ', COALESCE(vb.BANKRUPTCY_CHAPTER, 'NULL')) as metric,
       COUNT(*) as count
FROM net_new_suppressions nns
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    ON nns.LOAN_ID = vb.LOAN_ID AND vb.MOST_RECENT_BANKRUPTCY = 'Y'
    AND vb.FILING_DATE >= nns.ORIGINATION_DATE
    AND COALESCE(vb.PETITION_STATUS, '') != 'Remove Bankruptcy'
GROUP BY COALESCE(vb.BANKRUPTCY_CHAPTER, 'NULL')

UNION ALL

-- Petition Status Distribution for Net New Suppressions
SELECT '2_NET_NEW_CHARACTERISTICS' as analysis_section,
       CONCAT('Status: ', COALESCE(vb.PETITION_STATUS, 'NULL')) as metric,
       COUNT(*) as count
FROM net_new_suppressions nns
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    ON nns.LOAN_ID = vb.LOAN_ID AND vb.MOST_RECENT_BANKRUPTCY = 'Y'
    AND vb.FILING_DATE >= nns.ORIGINATION_DATE
    AND COALESCE(vb.PETITION_STATUS, '') != 'Remove Bankruptcy'
GROUP BY COALESCE(vb.PETITION_STATUS, 'NULL')

UNION ALL

-- Data Source Distribution for Net New Suppressions
SELECT '2_NET_NEW_CHARACTERISTICS' as analysis_section,
       CONCAT('Source: ', vb.DATA_SOURCE) as metric,
       COUNT(*) as count
FROM net_new_suppressions nns
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    ON nns.LOAN_ID = vb.LOAN_ID AND vb.MOST_RECENT_BANKRUPTCY = 'Y'
    AND vb.FILING_DATE >= nns.ORIGINATION_DATE
    AND COALESCE(vb.PETITION_STATUS, '') != 'Remove Bankruptcy'
GROUP BY vb.DATA_SOURCE

UNION ALL

-- =====================================================================================
-- SECTION 3: LOST SUPPRESSIONS ANALYSIS 
-- =====================================================================================

-- Reasons for Lost Bankruptcy Suppressions
SELECT '3_LOST_SUPPRESSIONS' as analysis_section,
       CASE 
           WHEN vb.LOAN_ID IS NULL THEN 'Reason: Not in VW_LOAN_BANKRUPTCY'
           WHEN vb.MOST_RECENT_BANKRUPTCY = 'N' THEN 'Reason: Not Most Recent Bankruptcy'
           WHEN COALESCE(vb.PETITION_STATUS, '') = 'Remove Bankruptcy' THEN 'Reason: Remove Bankruptcy Status'
           WHEN vb.FILING_DATE < vl.ORIGINATION_DATE THEN 'Reason: Filing Before Origination'
           ELSE 'Reason: Other'
       END as metric,
       COUNT(*) as count
FROM suppressions_lost ls
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON ls.lead_guid = vl.LEAD_GUID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb ON vl.LOAN_ID = vb.LOAN_ID
GROUP BY CASE 
           WHEN vb.LOAN_ID IS NULL THEN 'Reason: Not in VW_LOAN_BANKRUPTCY'
           WHEN vb.MOST_RECENT_BANKRUPTCY = 'N' THEN 'Reason: Not Most Recent Bankruptcy'
           WHEN COALESCE(vb.PETITION_STATUS, '') = 'Remove Bankruptcy' THEN 'Reason: Remove Bankruptcy Status'
           WHEN vb.FILING_DATE < vl.ORIGINATION_DATE THEN 'Reason: Filing Before Origination'
           ELSE 'Reason: Other'
       END

ORDER BY analysis_section, count DESC;

-- =====================================================================================
-- SECTION 4: LOST SUPPRESSIONS - OTHER SUPPRESSIONS IMPACT
-- =====================================================================================

-- Analysis of whether lost bankruptcy suppressions have other global suppressions
WITH current_bankruptcy_suppressions AS (
    SELECT DISTINCT PAYOFFUID as lead_guid
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
    WHERE SUPPRESSION_TYPE = 'Global'
    AND SUPPRESSION_REASON = 'Bankruptcy'  -- Only bankruptcy suppressions
    AND LOAD_DATE = CURRENT_DATE
),

proposed_suppressions AS (
SELECT vl.LEAD_GUID as lead_guid,
       vl.LOAN_ID,
       vl.ORIGINATION_DATE,
       vb.* EXCLUDE (LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE (PETITION_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (PROCESS_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (vb.MOST_RECENT_BANKRUPTCY = 'Y'  -- Option B: All most recent bankruptcies
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE  -- Filing on or after origination
            AND COALESCE(vb.PETITION_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed')  -- Exclude remove bankruptcy
            AND COALESCE(vb.PROCESS_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed'))
),

suppressions_lost AS (
    SELECT c.lead_guid
    FROM current_bankruptcy_suppressions c
    LEFT JOIN proposed_suppressions p ON c.lead_guid = p.lead_guid
    WHERE p.lead_guid IS NULL  -- Currently suppressed for bankruptcy but won't be under Option B
),

other_global_suppressions AS (
    SELECT DISTINCT 
        PAYOFFUID as lead_guid,
        SUPPRESSION_REASON
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
    WHERE SUPPRESSION_TYPE = 'Global'
    AND SUPPRESSION_REASON != 'Bankruptcy'  -- All non-bankruptcy global suppressions
    AND LOAD_DATE = CURRENT_DATE
)

SELECT 
    '4_LOST_SUPPRESSION_IMPACT' as analysis_section,
    CASE 
        WHEN ogs.lead_guid IS NOT NULL THEN 'Still Has Other Global Suppressions'
        ELSE 'Will Become Fully Eligible for Contact'
    END as metric,
    COUNT(*) as count
FROM suppressions_lost lbs
LEFT JOIN other_global_suppressions ogs ON lbs.lead_guid = ogs.lead_guid
GROUP BY 
    CASE 
        WHEN ogs.lead_guid IS NOT NULL THEN 'Still Has Other Global Suppressions'
        ELSE 'Will Become Fully Eligible for Contact'
    END

UNION ALL

-- Breakdown of other suppression reasons for those that remain suppressed
SELECT 
    '4_LOST_SUPPRESSION_IMPACT' as analysis_section,
    CONCAT('Other Reason: ', ogs.SUPPRESSION_REASON) as metric,
    COUNT(DISTINCT ogs.lead_guid) as count
FROM suppressions_lost lbs
INNER JOIN other_global_suppressions ogs ON lbs.lead_guid = ogs.lead_guid
GROUP BY ogs.SUPPRESSION_REASON

ORDER BY analysis_section, count DESC;

-- =====================================================================================
-- SECTION 5: ROW-LEVEL NET NEW SUPPRESSIONS (Zero Current Global Suppressions)
-- =====================================================================================

--gained_suppressions
WITH all_current_global_suppressions AS (SELECT DISTINCT LEAD_GUID FROM
(SELECT DISTINCT PAYOFFUID as lead_guid
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_TYPE = 'Global'  -- ALL global suppressions (any reason)
AND LOAD_DATE = CURRENT_DATE
UNION
SELECT PAYOFFUID AS LEAD_GUID
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_REASON ILIKE ANY ('%DNC:%')
AND LOAD_DATE = CURRENT_DATE
GROUP BY PAYOFFUID
HAVING COUNT(DISTINCT SUPPRESSION_REASON) >= 4)),
proposed_suppressions AS (
    SELECT vl.LEAD_GUID as lead_guid,
       vl.LOAN_ID,
       vl.ORIGINATION_DATE,
       vb.* EXCLUDE (LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE (PETITION_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (PROCESS_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (vb.MOST_RECENT_BANKRUPTCY = 'Y'  -- Option B: All most recent bankruptcies
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE  -- Filing on or after origination
            AND COALESCE(vb.PETITION_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed')  -- Exclude remove bankruptcy
            AND COALESCE(vb.PROCESS_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed'))),
net_new_suppressions AS (
    SELECT p.*
    FROM proposed_suppressions p
    LEFT JOIN all_current_global_suppressions ags ON p.lead_guid = ags.lead_guid
    WHERE ags.lead_guid IS NULL  -- Will be suppressed under Option B but has ZERO current global suppressions
)
SELECT
    nns.lead_guid as LEAD_GUID,
    nns.LOAN_ID,
    vl.LEGACY_LOAN_ID,
    nns.ORIGINATION_DATE,
    vl.LOAN_AMOUNT,
    vl.LOAN_CLOSED_DATE,
    vl.CHARGE_OFF_DATE,
    nns.FILING_DATE,
    nns.BANKRUPTCY_CHAPTER,
    nns.PETITION_STATUS,
    nns.PROCESS_STATUS,
    nns.DATA_SOURCE,
    nns.CASE_NUMBER,
    nns.DISMISSED_DATE,
    nns.AUTOMATIC_STAY_STATUS,
    nns.BANKRUPTCY_DISTRICT,
    DATEDIFF(days, nns.FILING_DATE, nns.ORIGINATION_DATE) as DAYS_FILING_TO_ORIGINATION,
    'NET_NEW_SUPPRESSION' as SUPPRESSION_CHANGE_TYPE
FROM net_new_suppressions nns
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON nns.LOAN_ID = vl.LOAN_ID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES vlcr
on vlcr.LOAN_ID = nns.LOAN_ID AND ((SUPPRESS_PHONE AND SUPPRESS_EMAIL AND SUPPRESS_TEXT AND SUPPRESS_LETTER) OR CEASE_AND_DESIST)
WHERE vlcr.LOAN_ID IS NULL
ORDER BY nns.FILING_DATE DESC, nns.LOAN_ID;

WITH all_current_global_suppressions AS (SELECT DISTINCT LEAD_GUID FROM
(SELECT DISTINCT PAYOFFUID as lead_guid
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_TYPE = 'Global'  -- ALL global suppressions (any reason)
AND LOAD_DATE = CURRENT_DATE
UNION
SELECT PAYOFFUID AS LEAD_GUID
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_REASON ILIKE ANY ('%DNC:%')
AND LOAD_DATE = CURRENT_DATE
GROUP BY PAYOFFUID
HAVING COUNT(DISTINCT SUPPRESSION_REASON) >= 4)),
proposed_suppressions AS (
    SELECT vl.LEAD_GUID as lead_guid,
       vl.LOAN_ID,
       vl.ORIGINATION_DATE,
       vb.* EXCLUDE (LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE (PETITION_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (PROCESS_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (vb.MOST_RECENT_BANKRUPTCY = 'Y'  -- Option B: All most recent bankruptcies
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE  -- Filing on or after origination
            AND COALESCE(vb.PETITION_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed')  -- Exclude remove bankruptcy
            AND COALESCE(vb.PROCESS_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed'))),
net_new_suppressions AS (
    SELECT p.*
    FROM proposed_suppressions p
    LEFT JOIN all_current_global_suppressions ags ON p.lead_guid = ags.lead_guid
    WHERE ags.lead_guid IS NULL  -- Will be suppressed under Option B but has ZERO current global suppressions
)
,suppress as (SELECT
    nns.lead_guid as LEAD_GUID,
    nns.LOAN_ID,
    vl.LEGACY_LOAN_ID,
    nns.ORIGINATION_DATE,
    vl.LOAN_AMOUNT,
    vl.LOAN_CLOSED_DATE,
    vl.CHARGE_OFF_DATE,
    nns.FILING_DATE,
    nns.BANKRUPTCY_CHAPTER,
    nns.PETITION_STATUS,
    nns.PROCESS_STATUS,
    nns.DATA_SOURCE,
    nns.CASE_NUMBER,
    nns.DISMISSED_DATE,
    nns.AUTOMATIC_STAY_STATUS,
    nns.BANKRUPTCY_DISTRICT,
    DATEDIFF(days, nns.FILING_DATE, nns.ORIGINATION_DATE) as DAYS_FILING_TO_ORIGINATION,
    'NET_NEW_SUPPRESSION' as SUPPRESSION_CHANGE_TYPE
FROM net_new_suppressions nns
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON nns.LOAN_ID = vl.LOAN_ID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES vlcr
on vlcr.LOAN_ID = nns.LOAN_ID AND ((SUPPRESS_PHONE AND SUPPRESS_EMAIL AND SUPPRESS_TEXT AND SUPPRESS_LETTER) OR CEASE_AND_DESIST)
WHERE vlcr.LOAN_ID IS NULL)
select listagg(concat(SET_NAME,': ',LIST_NAME), ', ') as SET_LIST_NAMES, b.LEAD_GUID, a.LOAD_DATE as LIST_LOAD_DATE
from BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST a
inner join suppress b
on a.PAYOFFUID = b.LEAD_GUID
WHERE LIST_LOAD_DATE >= DATEADD(day, -30, CURRENT_DATE)
group by all ORDER BY LIST_LOAD_DATE DESC;
-- =====================================================================================
-- SECTION 6: ROW-LEVEL LOST SUPPRESSIONS 
-- =====================================================================================

--lost_bk_suppressions
WITH all_current_global_suppressions AS (SELECT DISTINCT LEAD_GUID FROM
(SELECT DISTINCT PAYOFFUID as lead_guid
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_TYPE = 'Global'  -- ALL global suppressions (any reason)
AND LOAD_DATE = CURRENT_DATE
UNION
SELECT PAYOFFUID AS LEAD_GUID
FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE SUPPRESSION_REASON ILIKE ANY ('%DNC:%')
AND LOAD_DATE = CURRENT_DATE
GROUP BY PAYOFFUID
HAVING COUNT(DISTINCT SUPPRESSION_REASON) >= 4)),

proposed_suppressions AS (
SELECT vl.LEAD_GUID as lead_guid,
       vl.LOAN_ID,
       vl.ORIGINATION_DATE,
       vb.* EXCLUDE (LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb
    INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
        ON vb.LOAN_ID = vl.LOAN_ID
    WHERE (PETITION_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (PROCESS_STATUS = 'Discharged'
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE)
    OR (vb.MOST_RECENT_BANKRUPTCY = 'Y'  -- Option B: All most recent bankruptcies
            AND vb.FILING_DATE >= vl.ORIGINATION_DATE  -- Filing on or after origination
            AND COALESCE(vb.PETITION_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed')  -- Exclude remove bankruptcy
            AND COALESCE(vb.PROCESS_STATUS, '') NOT IN ('Remove Bankruptcy','Dismissed'))
),

lost_suppressions AS (
    SELECT c.lead_guid
    FROM all_current_global_suppressions c
    LEFT JOIN proposed_suppressions p ON c.lead_guid = p.lead_guid
    WHERE p.lead_guid IS NULL  -- Currently suppressed for bankruptcy but won't be under Option B
)

SELECT 
    ls.lead_guid as LEAD_GUID,
    vl.LOAN_ID,
    vl.LEGACY_LOAN_ID,
    vl.ORIGINATION_DATE,
    vl.LOAN_AMOUNT,
    vl.LOAN_CLOSED_DATE,
    vl.CHARGE_OFF_DATE,
    vb.FILING_DATE,
    vb.BANKRUPTCY_CHAPTER,
    vb.PETITION_STATUS,
    vb.PROCESS_STATUS,
    vb.DATA_SOURCE,
    vb.CASE_NUMBER,
    vb.DISMISSED_DATE,
    vb.AUTOMATIC_STAY_STATUS,
    vb.BANKRUPTCY_DISTRICT,
    CASE 
        WHEN vb.FILING_DATE IS NOT NULL AND vl.ORIGINATION_DATE IS NOT NULL 
        THEN DATEDIFF(days, vb.FILING_DATE, vl.ORIGINATION_DATE)
        ELSE NULL 
    END as DAYS_FILING_TO_ORIGINATION,
    CASE 
        WHEN vb.LOAN_ID IS NULL THEN 'NOT_IN_VW_LOAN_BANKRUPTCY'
        WHEN vb.MOST_RECENT_BANKRUPTCY = 'N' THEN 'NOT_MOST_RECENT'
        WHEN COALESCE(vb.PETITION_STATUS, '') = 'Remove Bankruptcy' THEN 'REMOVE_BANKRUPTCY_STATUS'
        WHEN vb.FILING_DATE < vl.ORIGINATION_DATE THEN 'FILING_BEFORE_ORIGINATION'
        ELSE 'OTHER_REASON'
    END as REASON_FOR_LOSS,
    'LOST_SUPPRESSION' as SUPPRESSION_CHANGE_TYPE
FROM lost_suppressions ls
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl ON ls.lead_guid = vl.LEAD_GUID
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY vb ON vl.LOAN_ID = vb.LOAN_ID
ORDER BY REASON_FOR_LOSS, vl.LOAN_ID;