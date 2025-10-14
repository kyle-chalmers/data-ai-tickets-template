-- QC Query 3: Q3 2025 date cutoff analysis
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Uses simplified query to check date filtering logic

SET AS_OF_DATE = '2025-09-30';

--3.1: Date Range Analysis
SELECT
    'Q3 2025 Date Range Analysis' as check_type,
    MIN(lp.TRANSACTION_DATE) as earliest_transaction,
    MAX(lp.TRANSACTION_DATE) as latest_transaction,
    MIN(lp.APPLY_DATE) as earliest_apply_date,
    MAX(lp.APPLY_DATE) as latest_apply_date,
    COUNT(*) as total_transactions,
    CASE
        WHEN MAX(lp.TRANSACTION_DATE) <= $AS_OF_DATE 
         AND MAX(lp.APPLY_DATE) <= $AS_OF_DATE THEN 'PASS'
        ELSE 'FAIL'
    END as date_filter_check
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION lp
WHERE lp.LOAN_ID IN (
    SELECT DISTINCT vl.loan_id
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    WHERE LOWER(vl.lead_guid) IN (
        '3242c2c1-dde7-4275-b843-04a0b39e9739', 'ac06df9d-10cc-4eda-9459-3aaa8de635e0',
        'd526a598-c3ff-42d8-b6cb-74ed05830695', '8d1108ad-6691-4aa6-8904-d28b71f82e82',
        '813bc10a-131b-4039-aa81-8e2570cf89e7', '1b662706-c43d-43e2-824a-2e27d8ec8836',
        '4ecf851d-82cb-4188-808e-d339cb14b81d', '90e6908d-bed7-4f79-a485-b9ab70a98326',
        'da27a4b9-ab84-4826-bf68-7dcb74c375ad', '5e777a59-a8a7-43c2-b65f-716446f4411e'
    )
)
AND lp.IS_MIGRATED = 0
AND lp.TRANSACTION_DATE <= $AS_OF_DATE
AND lp.APPLY_DATE <= $AS_OF_DATE;
