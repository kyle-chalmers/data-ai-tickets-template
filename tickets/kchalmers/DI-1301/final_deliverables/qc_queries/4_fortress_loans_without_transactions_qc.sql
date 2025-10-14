-- QC Query 4: Identify Fortress loans without Q3 2025 transactions
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

-- Shows which loans had zero transactions in Q3 2025

WITH all_fortress_loans AS (
    SELECT DISTINCT LOWER(vl.lead_guid) as lead_guid,
           vl.loan_id,
           vl.legacy_loan_id,
           vl.origination_date
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    WHERE LOWER(vl.lead_guid) IN (
        '3242c2c1-dde7-4275-b843-04a0b39e9739', 'ac06df9d-10cc-4eda-9459-3aaa8de635e0',
        'd526a598-c3ff-42d8-b6cb-74ed05830695', '8d1108ad-6691-4aa6-8904-d28b71f82e82',
        '813bc10a-131b-4039-aa81-8e2570cf89e7', '1b662706-c43d-43e2-824a-2e27d8ec8836',
        '62c208a8-2cc6-48d1-9e56-1432d4ae6fc5', 'af33f7bc-e87a-4c9f-9373-4ca4a7c2b333',
        '4def0a20-7369-4f2d-8ee2-61c41e5ddb27', '7242da38-d3a5-4f6c-8da6-d40660e68a55',
        '3e541643-d13d-4d3b-8e9f-7c37bc030942', 'c9278c87-c490-481c-a932-be28182217ff',
        'bf487a42-7168-4f24-b06d-05b6fd2adc8a', 'e29c2eea-46d4-48f6-9c5a-d3e63f7e91fd',
        'c2fe725f-d9ff-4c56-acd1-b0bb0f4e83e2', '568674a8-a931-4afb-bb65-7629dea33b3c',
        'd1edf66b-bab8-4222-93b0-b39b06ce4955', 'd1244ad9-4c37-4680-9f00-19cd4e724dd5',
        '77cd9fc9-7f06-480a-a7da-ebd11c72f678', '308935a8-dbfd-42a9-a199-a29862068f1d',
        '4ecf851d-82cb-4188-808e-d339cb14b81d', '90e6908d-bed7-4f79-a485-b9ab70a98326',
        'da27a4b9-ab84-4826-bf68-7dcb74c375ad', '5e777a59-a8a7-43c2-b65f-716446f4411e',
        '2933df70-9a19-41c9-a638-fea7bc6f49c4', '9d8ad23d-f0db-4057-ace0-5d2a1caf1ef2',
        '2ecbd1a0-92d6-4239-8165-f09ee0212540', '98dbe64d-c713-426a-b60c-6eea2555c866',
        '499af944-6495-4f69-8bd9-f6e406e22863', '6d6666d7-4180-418e-b45a-e55c766b12d3',
        '06dc9ada-1f7d-4da0-9f45-871256d420cd', 'e07f0fb3-f207-464b-acbb-f7387f367cf5',
        'c258175c-c2a0-4fb5-a2f2-65197bb16acb', 'ac915131-20fc-4484-8c8d-68a034e3af31',
        'b83177c8-327b-4d03-9fb8-8cf472431307'
    )
),

q3_transactions AS (
    SELECT DISTINCT lp.LOAN_ID
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION lp
    WHERE lp.IS_MIGRATED = 0
      AND lp.TRANSACTION_DATE <= '2025-09-30'
      AND lp.APPLY_DATE <= '2025-09-30'
)

--4.1: Loans Without Q3 Transactions
SELECT
    afl.lead_guid,
    afl.loan_id,
    afl.legacy_loan_id,
    afl.origination_date,
    'No Q3 2025 transactions' as status
FROM all_fortress_loans afl
LEFT JOIN q3_transactions qt ON afl.loan_id::TEXT = qt.LOAN_ID::TEXT
WHERE qt.LOAN_ID IS NULL
ORDER BY afl.origination_date DESC;
