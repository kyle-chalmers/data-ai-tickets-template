/*
DI-912: Compare Old DATA_STORE Pattern vs New ANALYTICS Pattern
Purpose: Validate that new ANALYTICS/BRIDGE query produces equivalent results to old DATA_STORE query
Author: Hongxia Shi
Date: 2025-10-01
*/

-- ============================================================================
-- OLD PATTERN: DATA_STORE.VW_LOAN_COLLECTION
-- ============================================================================
WITH old_dist_auto AS (
    SELECT
        PAYOFF_UID,
        CEASE_AND_DESIST,
        BANKRUPTCY_FLAG,
        DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    -- Original duplicate exclusion logic
    -- Excludes these 3 loans:
    --   a76f33d5-00e8-4f7e-a4d3-65d3907b383f
    --   4d8d470b-64de-4f3e-8857-593e7b3a4058
    --   4ba57978-06d4-4e70-b866-2bcfe4d235f3
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID
        FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1
        HAVING COUNT(*) < 2
    )
),

-- ============================================================================
-- NEW PATTERN: ANALYTICS/BRIDGE
-- ============================================================================
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID
            AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID
            AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)

-- ============================================================================
-- QC 1: RECORD COUNT COMPARISON
-- ============================================================================
SELECT
    'Old Pattern (DATA_STORE)' AS source,
    COUNT(*) AS record_count,
    SUM(CASE WHEN CEASE_AND_DESIST = TRUE THEN 1 ELSE 0 END) AS cease_desist,
    SUM(CASE WHEN BANKRUPTCY_FLAG = TRUE THEN 1 ELSE 0 END) AS bankruptcy,
    SUM(CASE WHEN DEBIT_BILL_AUTOMATIC = TRUE THEN 1 ELSE 0 END) AS autopay
FROM old_dist_auto

UNION ALL

SELECT
    'New Pattern (ANALYTICS/BRIDGE)' AS source,
    COUNT(*) AS record_count,
    SUM(CASE WHEN CEASE_AND_DESIST = TRUE THEN 1 ELSE 0 END) AS cease_desist,
    SUM(CASE WHEN BANKRUPTCY_FLAG = TRUE THEN 1 ELSE 0 END) AS bankruptcy,
    SUM(CASE WHEN DEBIT_BILL_AUTOMATIC = TRUE THEN 1 ELSE 0 END) AS autopay
FROM new_dist_auto;

-- ============================================================================
-- QC 2: IDENTIFY LOANS ONLY IN ONE PATTERN
-- ============================================================================
-- Loans only in old pattern (not in new)
WITH old_dist_auto AS (
    SELECT PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1 HAVING COUNT(*) < 2
    )
),
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)

SELECT
    'Only in old pattern' AS discrepancy_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
WHERE NOT EXISTS (SELECT 1 FROM new_dist_auto n WHERE n.PAYOFF_UID = o.PAYOFF_UID)

UNION ALL

SELECT
    'Only in new pattern' AS discrepancy_type,
    COUNT(*) AS loan_count
FROM new_dist_auto n
WHERE NOT EXISTS (SELECT 1 FROM old_dist_auto o WHERE o.PAYOFF_UID = n.PAYOFF_UID)

UNION ALL

SELECT
    'In both patterns' AS discrepancy_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
INNER JOIN new_dist_auto n ON o.PAYOFF_UID = n.PAYOFF_UID;

-- ============================================================================
-- QC 3: FLAG VALUE MISMATCHES
-- ============================================================================
-- Find loans where flag values differ between old and new patterns
WITH old_dist_auto AS (
    SELECT PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1 HAVING COUNT(*) < 2
    )
),
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)

SELECT
    'CEASE_AND_DESIST mismatch' AS mismatch_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
INNER JOIN new_dist_auto n ON o.PAYOFF_UID = n.PAYOFF_UID
WHERE COALESCE(o.CEASE_AND_DESIST, FALSE) <> COALESCE(n.CEASE_AND_DESIST, FALSE)

UNION ALL

SELECT
    'BANKRUPTCY_FLAG mismatch' AS mismatch_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
INNER JOIN new_dist_auto n ON o.PAYOFF_UID = n.PAYOFF_UID
WHERE COALESCE(o.BANKRUPTCY_FLAG, FALSE) <> COALESCE(n.BANKRUPTCY_FLAG, FALSE)

UNION ALL

SELECT
    'DEBIT_BILL_AUTOMATIC mismatch' AS mismatch_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
INNER JOIN new_dist_auto n ON o.PAYOFF_UID = n.PAYOFF_UID
WHERE COALESCE(o.DEBIT_BILL_AUTOMATIC, FALSE) <> COALESCE(n.DEBIT_BILL_AUTOMATIC, FALSE);

-- ============================================================================
-- QC 4: DETAILED MISMATCH ANALYSIS
-- ============================================================================
-- Show specific loans with flag mismatches for investigation
WITH old_dist_auto AS (
    SELECT PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1 HAVING COUNT(*) < 2
    )
),
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)

SELECT
    o.PAYOFF_UID,
    o.CEASE_AND_DESIST AS old_cease_desist,
    n.CEASE_AND_DESIST AS new_cease_desist,
    o.BANKRUPTCY_FLAG AS old_bankruptcy,
    n.BANKRUPTCY_FLAG AS new_bankruptcy,
    o.DEBIT_BILL_AUTOMATIC AS old_autopay,
    n.DEBIT_BILL_AUTOMATIC AS new_autopay
FROM old_dist_auto o
INNER JOIN new_dist_auto n ON o.PAYOFF_UID = n.PAYOFF_UID
WHERE COALESCE(o.CEASE_AND_DESIST, FALSE) <> COALESCE(n.CEASE_AND_DESIST, FALSE)
   OR COALESCE(o.BANKRUPTCY_FLAG, FALSE) <> COALESCE(n.BANKRUPTCY_FLAG, FALSE)
   OR COALESCE(o.DEBIT_BILL_AUTOMATIC, FALSE) <> COALESCE(n.DEBIT_BILL_AUTOMATIC, FALSE)
LIMIT 100;

-- ============================================================================
-- QC 5: NULL VALUE DISTRIBUTION
-- ============================================================================
-- Compare NULL value patterns between old and new
WITH old_dist_auto AS (
    SELECT PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1 HAVING COUNT(*) < 2
    )
),
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)

SELECT
    'Old Pattern' AS source,
    SUM(CASE WHEN CEASE_AND_DESIST IS NULL THEN 1 ELSE 0 END) AS cease_desist_nulls,
    SUM(CASE WHEN BANKRUPTCY_FLAG IS NULL THEN 1 ELSE 0 END) AS bankruptcy_nulls,
    SUM(CASE WHEN DEBIT_BILL_AUTOMATIC IS NULL THEN 1 ELSE 0 END) AS autopay_nulls
FROM old_dist_auto

UNION ALL

SELECT
    'New Pattern' AS source,
    SUM(CASE WHEN CEASE_AND_DESIST IS NULL THEN 1 ELSE 0 END) AS cease_desist_nulls,
    SUM(CASE WHEN BANKRUPTCY_FLAG IS NULL THEN 1 ELSE 0 END) AS bankruptcy_nulls,
    SUM(CASE WHEN DEBIT_BILL_AUTOMATIC IS NULL THEN 1 ELSE 0 END) AS autopay_nulls
FROM new_dist_auto;

-- ============================================================================
-- EXPECTED RESULTS
-- ============================================================================
-- QC 1: Record counts and flag counts should be very similar (within 1-2% tolerance)
-- QC 2: Minimal loans should appear in only one pattern (investigate if > 5%)
-- QC 3: Flag mismatches should be minimal (investigate if > 1%)
-- QC 4: Review specific mismatches to understand data quality differences
-- QC 5: New pattern may have fewer NULLs due to COALESCE/IFF logic
