-- QC Query 2: Transaction summary by attachment source
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

WITH attachment_b_loans AS (
    SELECT * FROM (VALUES
        ('3242c2c1-dde7-4275-b843-04a0b39e9739'), ('ac06df9d-10cc-4eda-9459-3aaa8de635e0'),
        ('d526a598-c3ff-42d8-b6cb-74ed05830695'), ('8d1108ad-6691-4aa6-8904-d28b71f82e82'),
        ('813bc10a-131b-4039-aa81-8e2570cf89e7'), ('1b662706-c43d-43e2-824a-2e27d8ec8836'),
        ('62c208a8-2cc6-48d1-9e56-1432d4ae6fc5'), ('af33f7bc-e87a-4c9f-9373-4ca4a7c2b333'),
        ('4def0a20-7369-4f2d-8ee2-61c41e5ddb27'), ('7242da38-d3a5-4f6c-8da6-d40660e68a55'),
        ('3e541643-d13d-4d3b-8e9f-7c37bc030942'), ('c9278c87-c490-481c-a932-be28182217ff'),
        ('bf487a42-7168-4f24-b06d-05b6fd2adc8a'), ('e29c2eea-46d4-48f6-9c5a-d3e63f7e91fd'),
        ('c2fe725f-d9ff-4c56-acd1-b0bb0f4e83e2'), ('568674a8-a931-4afb-bb65-7629dea33b3c'),
        ('d1edf66b-bab8-4222-93b0-b39b06ce4955'), ('d1244ad9-4c37-4680-9f00-19cd4e724dd5'),
        ('77cd9fc9-7f06-480a-a7da-ebd11c72f678'), ('308935a8-dbfd-42a9-a199-a29862068f1d'),
        ('cf43eed1-4d47-4999-917d-589a2f34db13'), ('79f66f8e-0403-4575-8dd6-530947ad67bc'),
        ('7b9da960-868c-4cf5-8b25-02eeca02ad96'), ('d812992c-227e-4ce4-a780-372d788bd327'),
        ('6cd6a429-e1ea-420c-b3e6-b96b7ab2ae64'), ('fa40b845-77fd-4371-a69e-5b1cfdf18908'),
        ('a9cb18ed-0831-4905-a343-4b360f1f89ee'), ('a02c3d44-2be5-4ac8-879d-71f874716f64'),
        ('bb54829b-7777-459a-95fc-02aed124f009'), ('d1861b1a-d853-4452-8560-341c11d263d8'),
        ('272ea105-4acc-427b-b997-7c59b67887af'), ('1ab1130a-b57a-476b-b3d8-5986210d7eef'),
        ('19c77ace-d385-4819-b991-55dc83a77f44'), ('949185c2-a737-4e7a-a532-f46898d3ea81'),
        ('9ecc15e9-28b7-41bb-b9bc-bf3bd4709d6c'), ('229e8873-d3bd-46c1-ab15-18ad5c786b23'),
        ('289f509b-e1ad-46f6-80d8-109cedf2c1ba'), ('bf273ab5-924c-43ee-9ab7-3fddb4eb5cdf'),
        ('8bbb00ea-54b6-4e78-8e4d-2287d616524f'), ('166ea641-70c6-4902-b3f0-87ff3b96e444'),
        ('d95b9512-899a-43f0-baaf-dd4d8d03eade'), ('a3a69dd0-81b5-450f-a3b2-6ae49b11b2e7'),
        ('eafceb33-4282-4184-8adc-c72c151f747f'), ('02ce95bd-ae3d-4e90-aa27-dfb7789c5a65'),
        ('63204d99-d509-45f8-b023-07d27ed0d92d'), ('aa85b0dd-1ab4-4f5a-aed1-f8d8f792320f'),
        ('95e3864f-9b22-4bad-b3fd-658136d5eddf'), ('825ebbc8-820d-4028-aeaf-f2a5daa60c6e'),
        ('7e58029c-ed69-4d14-8160-59c679eeda5a'), ('f9024957-c033-4284-8170-00fec5fb2a4d'),
        ('653792fb-68fb-44f5-8f87-802dfa7646f6'), ('585f13c6-0077-4b42-a4b4-7df2c09afc6a'),
        ('c701a943-d720-4b29-94e6-e89e4b7dce32'), ('56eb8451-8c8e-49d9-9b53-a010e3c36fef'),
        ('19bc03ac-cc9a-44d1-84a2-e37d18ef869a'), ('cdd81ba0-e029-4d18-855b-1c888ab65029'),
        ('f88cfbe4-3dfc-43b4-af37-22ef38d715e4'), ('dfc5e623-0091-49cf-bc74-f1df528c8876'),
        ('ce09afe4-c31b-40f1-bd44-c0ae3387f781'), ('1687bf8f-f243-4901-b947-ccf48e8890eb'),
        ('e6f4cee9-0e3f-41b1-acf4-cfabf1c704f5'), ('84f4a68a-14f3-478f-8bda-0ea95f8e6672'),
        ('6a9bf765-f443-4237-9dc1-167efc959335'), ('37da346d-0ba0-46b0-b6ed-602ac4feea37'),
        ('92c5a652-e71a-4c68-a645-da25483339bf'), ('6165e06d-c14e-4a88-93f4-05f713f1af3a'),
        ('3cc14fc3-49e1-4c4c-8110-a379cca2d2cc'), ('c982c62c-b692-4bfd-8cf8-311fc8158cca'),
        ('9f389b2f-0476-45c1-9c5f-33ffb3904e8c'), ('32151700-fcad-4239-a5b8-6e2a33664943'),
        ('82a00f9a-2e43-46eb-9ba8-f81cc3ef64b8'), ('0b5171d2-c719-445f-aa50-1eaaa687caa8'),
        ('a08d810d-6465-4c78-ba8b-a3579e0bd897'), ('8e98f902-289a-4c08-99a1-eca4ca83e08d'),
        ('ebf13ba5-4459-4c89-ac24-8a040cf98f92')
    ) AS t(lead_guid)
),

attachment_c_loans AS (
    SELECT * FROM (VALUES
        ('4ecf851d-82cb-4188-808e-d339cb14b81d'), ('90e6908d-bed7-4f79-a485-b9ab70a98326'),
        ('da27a4b9-ab84-4826-bf68-7dcb74c375ad'), ('5e777a59-a8a7-43c2-b65f-716446f4411e'),
        ('2933df70-9a19-41c9-a638-fea7bc6f49c4'), ('9d8ad23d-f0db-4057-ace0-5d2a1caf1ef2'),
        ('2ecbd1a0-92d6-4239-8165-f09ee0212540'), ('98dbe64d-c713-426a-b60c-6eea2555c866'),
        ('499af944-6495-4f69-8bd9-f6e406e22863'), ('6d6666d7-4180-418e-b45a-e55c766b12d3'),
        ('06dc9ada-1f7d-4da0-9f45-871256d420cd'), ('e07f0fb3-f207-464b-acbb-f7387f367cf5'),
        ('c258175c-c2a0-4fb5-a2f2-65197bb16acb'), ('ac915131-20fc-4484-8c8d-68a034e3af31'),
        ('b83177c8-327b-4d03-9fb8-8cf472431307')
    ) AS t(lead_guid)
),

all_fortress_loans AS (
    SELECT lead_guid, 'Attachment_B' as attachment_source FROM attachment_b_loans
    UNION ALL
    SELECT lead_guid, 'Attachment_C' as attachment_source FROM attachment_c_loans
),

loan_details AS (
    SELECT vl.loan_id, LOWER(vl.lead_guid) as lead_guid, afl.attachment_source
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    JOIN all_fortress_loans afl ON LOWER(vl.lead_guid) = LOWER(afl.lead_guid)
)

--2.1: Breakdown by Attachment Source
SELECT
    ld.attachment_source,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT ld.lead_guid) as unique_loans,
    ROUND(AVG(lp.TRANSACTION_AMOUNT), 2) as avg_transaction_amount,
    ROUND(SUM(lp.TRANSACTION_AMOUNT), 2) as total_amount
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION lp
JOIN loan_details ld ON lp.LOAN_ID::TEXT = ld.loan_id::TEXT
WHERE lp.IS_MIGRATED = 0
  AND lp.TRANSACTION_DATE <= '2025-09-30'
  AND lp.APPLY_DATE <= '2025-09-30'
GROUP BY ld.attachment_source
ORDER BY ld.attachment_source;
