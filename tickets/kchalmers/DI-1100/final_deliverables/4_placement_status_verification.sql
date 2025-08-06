-- DI-1100 Placement Status Verification
-- Purpose: Verify if loans from the bulk upload file have been successfully placed with Resurgent
-- Date: 2025-08-04
-- Related: SERV-381 (bulk upload ticket)
-- Status: ✅ VERIFIED - All 1,770 loans successfully uploaded

-- Query 1: Count all loans with Resurgent placement on 2025-07-31
SELECT COUNT(*) AS NUMBER_OF_LOANS, 
       A.PLACEMENT_STATUS, 
       A.PLACEMENT_STATUS_START_DATE
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT B
    ON A.LOAN_ID = B.LOAN_ID 
    AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE 1=1
    AND A.PLACEMENT_STATUS = 'Resurgent'
    AND A.PLACEMENT_STATUS_START_DATE = '2025-07-31'
GROUP BY ALL
ORDER BY 3 DESC;

-- Results (as of 2025-08-04): ✅ All 1,770 loans successfully uploaded
-- +------------------------------------------------------------------+
-- | NUMBER_OF_LOANS | PLACEMENT_STATUS | PLACEMENT_STATUS_START_DATE |
-- |-----------------+------------------+-----------------------------|
-- | 1770            | Resurgent        | 2025-07-31                  |
-- +------------------------------------------------------------------+

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
    AND A.PLACEMENT_STATUS = 'Resurgent'
    AND A.PLACEMENT_STATUS_START_DATE = '2025-07-31'
ORDER BY 3 DESC, 1
LIMIT 10;

-- Sample Results:
-- +------------------------------------------------------------------------------+
-- |         |                |             |                  | PLACEMENT_STATUS |
-- | LOAN_ID | PAYOFF_LOAN_ID | SETTINGS_ID | PLACEMENT_STATUS | _START_DATE      |
-- |---------+----------------+-------------+------------------+------------------|
-- | 125138  | Pcb671c9d25fc  | 125138      | Resurgent        | 2025-07-31       |
-- | 102446  | P30f670980e1f  | 102446      | Resurgent        | 2025-07-31       |
-- | 102444  | Pee07c91a9737  | 102444      | Resurgent        | 2025-07-31       |
-- | 100950  | P8bcba7cd1fb1  | 100950      | Resurgent        | 2025-07-31       |
-- | 100940  | Pa6ca1f31a9d5  | 100940      | Resurgent        | 2025-07-31       |
-- +------------------------------------------------------------------------------+

-- Query 3: Summary of all Resurgent placements in 2025
SELECT DISTINCT 
    PLACEMENT_STATUS_START_DATE,
    COUNT(*) AS LOAN_COUNT
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
WHERE PLACEMENT_STATUS = 'Resurgent'
    AND PLACEMENT_STATUS_START_DATE >= '2025-01-01'
GROUP BY PLACEMENT_STATUS_START_DATE
ORDER BY PLACEMENT_STATUS_START_DATE DESC;

-- Results:
-- +------------------------------------------+
-- | PLACEMENT_STATUS_START_DATE | LOAN_COUNT |
-- |-----------------------------+------------|
-- | 2025-07-31                  | 1770       | <-- DI-1100 loans
-- | 2025-03-28                  | 3          |
-- | 2025-02-28                  | 846        |
-- +------------------------------------------+

-- CONCLUSION: 
-- All 1,770 loans from the DI-1100 bulk upload file have been successfully
-- placed with Resurgent in the LMS system with the correct placement date of 2025-07-31.