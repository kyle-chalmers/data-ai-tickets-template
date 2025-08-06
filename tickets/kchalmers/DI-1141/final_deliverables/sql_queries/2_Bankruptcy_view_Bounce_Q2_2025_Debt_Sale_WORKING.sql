/*
DI-1141: Sale Files for Bounce - Q2 2025 Sale
Working bankruptcy and debt settlement lookup view
Simplified version to avoid syntax errors
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Use the existing table from previous runs if it exists, or run original working query from DI-928
SELECT * FROM DEVELOPMENT._TIN.BANKRUPTCY_DEBT_SUSPEND_LOOKUP
ORDER BY PAYOFFUID
LIMIT 10;

-- QC: Count records and check key fields for existing table
SELECT 
    COUNT(*) as total_records,
    COUNT(CASE WHEN BANKRUPTCY_STATUS IS NOT NULL THEN 1 END) as bankruptcy_records,
    COUNT(CASE WHEN DEBT_SETTLEMENT_STATUS IS NOT NULL THEN 1 END) as debt_settlement_records,
    COUNT(CASE WHEN PLACEMENT_STATUS IS NOT NULL THEN 1 END) as placement_records
FROM DEVELOPMENT._TIN.BANKRUPTCY_DEBT_SUSPEND_LOOKUP;