-- DI-1065: QC Query to identify Fortress loans WITHOUT payment transactions
-- This query shows which of the 80 loans do not have any LoanPro payment history

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

WITH attachment_b_loans AS (
    -- 75 loans from Fortress Attachment B
    SELECT * FROM (
        VALUES 
        ('2bbbff4b-f7c3-46ac-a10b-8c91317c97cc'),
        ('8f239083-2784-4033-b926-12aed63cbdc8'),
        ('92c5a652-e71a-4c68-a645-da25483339bf'),
        ('7242da38-d3a5-4f6c-8da6-d40660e68a55'),
        ('1f18cb6b-0729-4054-998a-c823190b8952'),
        ('71d48bb2-11a9-4538-8d02-f19d2656f6de'),
        ('5bfb3052-a13b-48bf-8768-233e2e82983f'),
        ('56eb8451-8c8e-49d9-9b53-a010e3c36fef'),
        ('356261dc-048b-4bd9-9daf-d4d65cead877'),
        ('fbff9b0c-75c3-4684-8c3f-db53aaba68eb'),
        ('ee7efa74-94ce-4104-bd2a-605f7663c2e6'),
        ('882853ac-6f89-4645-84a3-a07ffa6899ab'),
        ('99672f26-62da-43e8-8f33-3fe3ce0fed5c'),
        ('9506dfa7-c07a-4eed-aa8e-25c69b9186e6'),
        ('30759e84-4055-4033-96a6-04abff4c1be7'),
        ('d95b9512-899a-43f0-baaf-dd4d8d03eade'),
        ('5b2ebd0e-ef1b-4c2b-9daf-7446c5919d99'),
        ('57dd3811-b5be-4548-8363-e61fde9a3065'),
        ('42779e29-f9d8-4678-8d8c-93986dd69818'),
        ('ce65c709-9b64-4998-a57b-1173015c3daf'),
        ('19bc03ac-cc9a-44d1-84a2-e37d18ef869a'),
        ('a814367a-7bf0-4616-9723-c5df842fb09c'),
        ('f763031a-0dc7-4a53-a5c2-c11453544d74'),
        ('874829a0-48cb-4643-ba86-526a2a00dbf5'),
        ('5933c20d-6f64-454d-bdec-257d1ca22cb5'),
        ('86da8178-a07c-44be-aba7-0d5d2ac985e8'),
        ('d58e48f6-56a3-43e7-be24-4762e0aa8f23'),
        ('5eed3c4e-f8d7-40f3-a255-2a1f0d91e6a6'),
        ('822ea740-6a41-459a-82d5-a02e1191c80e'),
        ('2b4fa978-42f2-40c5-bd35-c376dc670959'),
        ('2e15ba20-a675-44a0-9675-f82cdef06e79'),
        ('837b1110-553f-446d-9d62-232e04b6a6bb'),
        ('b65db183-24bd-494d-ba83-27f8681275bd'),
        ('2ea893f7-7520-4bca-93c3-ad40330e3531'),
        ('8912e5ef-2828-4e80-ad8a-d0ef43e80d4a'),
        ('2b92cdf7-b5a9-493f-826a-878eb3ef32e1'),
        ('608a9228-57b5-4b65-946e-e7083f299178'),
        ('f758ed6b-4975-41c6-8d84-8088f7dcea20'),
        ('2402c636-6efb-4980-89ec-7c77518a765f'),
        ('6e6a438d-34ba-44b5-aafc-874117496c2e'),
        ('7f335e64-7582-4729-be36-5f8d4c18d232'),
        ('fa4f213a-f775-4399-a7f1-bca23f8f8dd0'),
        ('6c0df0cb-f6e7-42d7-9f69-a9b994373b98'),
        ('8cabad03-cc57-4a05-a321-d9066468c6e1'),
        ('336eab30-2132-4319-8d43-fc2c44bb7a65'),
        ('264c4278-f02b-4348-8f21-5e8f6f44d2d9'),
        ('a153ab18-502c-4138-a026-dc4b0ee57bd1'),
        ('9731a818-c6eb-4ee2-aebf-396b5adda254'),
        ('f716c535-50cd-4fa8-93e7-244893b1811e'),
        ('5e33ef73-4711-4793-998e-2c4717a4d322'),
        ('c7ac4e80-26ea-4bf7-92f7-6a72c24cea98'),
        ('7a5c5d4e-f6d1-41ba-9047-0383a98998da'),
        ('38d8e6aa-ad6b-4dc3-affd-4095d9fd328d'),
        ('272ea105-4acc-427b-b997-7c59b67887af'),
        ('825ebbc8-820d-4028-aeaf-f2a5daa60c6e'),
        ('f9024957-c033-4284-8170-00fec5fb2a4d'),
        ('82c240a7-30e1-4e55-aecc-fa3f433c8784'),
        ('8bdf16ab-9af6-4504-9548-de205e4f47e6'),
        ('8c7abdab-dc6a-4174-9af6-7b085ad466fa'),
        ('5a25c83d-d6af-4c7e-954a-81238b85df0b'),
        ('6b3dc843-35bc-41f8-a0f3-370af1bb9eab'),
        ('03849dc8-848f-4b62-bec6-10a2271fe010'),
        ('80fb2d26-1eef-4152-a31f-a5a107f9d079'),
        ('c83f1261-6f26-4d12-bf7d-8d05b201d848'),
        ('3982cbd8-ad40-4fdb-a7f2-98860438cbcc'),
        ('083dd11a-901f-466c-a334-86cc1d0a073e'),
        ('bea47b9b-d709-4bd4-9c68-2d9104a197d6'),
        ('daeb5048-5e09-429e-afd8-3c94c59b0202'),
        ('c3d3357a-b6a5-46e4-8d12-12791ed10539'),
        ('4ff6bd6a-b6a3-4e82-bba6-8b886430607a'),
        ('755bf378-3e29-4821-98ce-a93a27619236'),
        ('b7a93668-0020-49dd-986f-63604b49db64'),
        ('1687bf8f-f243-4901-b947-ccf48e8890eb'),
        ('6d6666d7-4180-418e-b45a-e55c766b12d3'),
        ('f09dd043-acf7-484f-bf24-f48c96d59c4c')
    ) AS t(lead_guid)
),

attachment_c_loans AS (
    -- 5 loans from Fortress Attachment C
    SELECT * FROM (
        VALUES 
        ('e0c9cac1-d79f-4e5c-88c1-346eef55c040'),
        ('7786013f-4470-43f0-a9ca-5b1cdc5b337c'),
        ('477c272e-be7b-498b-81fb-d07b961de6f5'),
        ('2db140fc-37d1-4d72-ab83-6e79c8990a0e'),
        ('b83177c8-327b-4d03-9fb8-8cf472431307')
    ) AS t(lead_guid)
),

all_fortress_loans AS (
    -- Combined loan list with attachment designation  
    SELECT lead_guid, 'Attachment_B' as attachment_source
    FROM attachment_b_loans
    UNION ALL
    SELECT lead_guid, 'Attachment_C' as attachment_source  
    FROM attachment_c_loans
),

loan_details AS (
    -- All 80 Fortress loans with basic info
    SELECT 
        vl.loan_id,
        LOWER(vl.lead_guid) as lead_guid,
        vl.legacy_loan_id,
        vl.origination_date,
        vl.loan_amount,
        vl.term,
        vl.interest_rate,
        vl.loan_closed_date,
        vl.charge_off_date,
        afl.attachment_source
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    JOIN all_fortress_loans afl ON LOWER(vl.lead_guid) = LOWER(afl.lead_guid)
),

loans_with_transactions AS (
    -- Loans that have LoanPro payment transactions
    SELECT DISTINCT 
        LOWER(ld.lead_guid) as lead_guid,
        ld.attachment_source,
        COUNT(lp.payment_id) as transaction_count
    FROM loan_details ld
    LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION lp 
        ON UPPER(lp.loan_id::TEXT) = UPPER(ld.loan_id::TEXT) 
        AND lp.IS_MIGRATED = 0
    GROUP BY ld.lead_guid, ld.attachment_source
    HAVING COUNT(lp.payment_id) > 0
)

-- Final QC: Show loans WITHOUT transactions
SELECT 
    ld.attachment_source,
    ld.lead_guid as PAYOFFUID,
    ld.loan_id as LOANID,
    ld.legacy_loan_id,
    ld.origination_date,
    ld.loan_amount,
    ld.term,
    ld.interest_rate,
    ld.loan_closed_date,
    ld.charge_off_date,
    CASE 
        WHEN ld.loan_closed_date IS NOT NULL THEN 'LOAN_CLOSED'
        WHEN ld.charge_off_date IS NOT NULL THEN 'CHARGED_OFF'
        ELSE 'ACTIVE_NO_TRANSACTIONS'
    END as loan_status_reason
FROM loan_details ld
LEFT JOIN loans_with_transactions lwt ON ld.lead_guid = lwt.lead_guid
WHERE lwt.lead_guid IS NULL  -- Loans without any transactions
ORDER BY ld.attachment_source, ld.origination_date;