-- DI-1151: Bounce Placement Status Verification
-- Purpose: Verify if loans from the bulk upload file have been successfully placed with Bounce
-- Date: [VERIFICATION_DATE] 
-- Related: SERV-472 (bulk upload ticket)
-- Expected Count: 1,483 loans
-- Expected Placement Date: 2025-08-06
-- EXECUTION ORDER: #5 (Final verification - run when SERV ticket moves to IN TESTING)

-- Query 1: Count all loans with Bounce placement on 2025-08-06
SELECT COUNT(*) AS NUMBER_OF_LOANS, 
       A.PLACEMENT_STATUS, 
       A.PLACEMENT_STATUS_START_DATE
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT B
    ON A.LOAN_ID = B.LOAN_ID 
    AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE 1=1
    AND A.PLACEMENT_STATUS = 'Bounce'
    AND A.PLACEMENT_STATUS_START_DATE = '2025-08-06'
GROUP BY ALL
ORDER BY 3 DESC;

-- Expected Result: 1,483 loans with Bounce placement on 2025-08-06

-- Query 2: View sample of loans with details
SELECT A.LOAN_ID, 
       A.PAYOFF_LOAN_ID, 
       B.ID AS SETTINGS_ID, 
       A.PLACEMENT_STATUS, 
       A.PLACEMENT_STATUS_START_DATE
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT B
    ON A.LOAN_ID = B.LOAN_ID 
    AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE 1=1
    AND A.PLACEMENT_STATUS = 'Bounce'
    AND A.PLACEMENT_STATUS_START_DATE = '2025-08-06'
ORDER BY 3 DESC, 1
LIMIT 10;

-- Query 3: Summary of all Bounce placements in 2025
SELECT DISTINCT 
    PLACEMENT_STATUS_START_DATE,
    COUNT(*) AS LOAN_COUNT
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
WHERE PLACEMENT_STATUS = 'Bounce'
    AND PLACEMENT_STATUS_START_DATE >= '2025-01-01'
GROUP BY PLACEMENT_STATUS_START_DATE
ORDER BY PLACEMENT_STATUS_START_DATE DESC;

-- Query 4: Cross-reference with original debt sale population
-- Verify that placed loans match our original selection
SELECT 
    'Original Selected Population' AS source,
    COUNT(*) AS loan_count
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED

UNION ALL

SELECT 
    'Placed with Bounce' AS source,
    COUNT(*) AS loan_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
WHERE A.PLACEMENT_STATUS = 'Bounce'
    AND A.PLACEMENT_STATUS_START_DATE = '2025-08-06';

-- VERIFICATION CHECKLIST:
-- [ ] Query 1: Shows exactly 1,483 loans with Bounce placement on 2025-08-06
-- [ ] Query 2: Sample loans show correct SETTINGS_ID and placement details  
-- [ ] Query 3: New placement date appears in historical summary
-- [ ] Query 4: Placed loan count matches original selected population (1,483)
-- [ ] Update this file with actual results and status

-- CONCLUSION: 
-- [TO BE FILLED AFTER VERIFICATION]
-- Status: ⏳ PENDING / ✅ VERIFIED / ❌ FAILED
-- Notes: [Add verification notes and any discrepancies found]