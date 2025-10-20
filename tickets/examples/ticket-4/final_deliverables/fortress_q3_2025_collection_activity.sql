/***********************************************************************************/
-- ticket-4: InvestorPartner Q3 2025 Collection Activity Data Pull
-- Adapted from DI-1064 (Tin Nguyen)
--
-- Purpose: Extract collection activity for 15 InvestorPartner loans from Q3 2025
-- Time Period: July 1, 2025 - September 30, 2025
-- Sources: ContactCenter (phone/SMS/email), Loan Notes, email_platform Email
--
-- Note: Use BUSINESS_INTELLIGENCE_LARGE warehouse for performance
/***********************************************************************************/

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

/***********************************************************************************/
-- STEP 1: Define parameters
/***********************************************************************************/

-- Q3 2025 date range
SET q3_start_date = '2025-07-01';
SET q3_end_date = '2025-09-30';

-- 15 PAYOFFUIDs from Attachment C (using temp table due to variable size limit)
CREATE OR REPLACE TEMP TABLE cron_store.temp_target_payoff_uids AS
SELECT value AS payoff_uid
FROM (VALUES
    ('4ecf851d-82cb-4188-808e-d339cb14b81d'),
    ('90e6908d-bed7-4f79-a485-b9ab70a98326'),
    ('da27a4b9-ab84-4826-bf68-7dcb74c375ad'),
    ('5e777a59-a8a7-43c2-b65f-716446f4411e'),
    ('2933df70-9a19-41c9-a638-fea7bc6f49c4'),
    ('9d8ad23d-f0db-4057-ace0-5d2a1caf1ef2'),
    ('2ecbd1a0-92d6-4239-8165-f09ee0212540'),
    ('98dbe64d-c713-426a-b60c-6eea2555c866'),
    ('499af944-6495-4f69-8bd9-f6e406e22863'),
    ('6d6666d7-4180-418e-b45a-e55c766b12d3'),
    ('06dc9ada-1f7d-4da0-9f45-871256d420cd'),
    ('e07f0fb3-f207-464b-acbb-f7387f367cf5'),
    ('c258175c-c2a0-4fb5-a2f2-65197bb16acb'),
    ('ac915131-20fc-4484-8c8d-68a034e3af31'),
    ('b83177c8-327b-4d03-9fb8-8cf472431307')
) AS t(value);

/***********************************************************************************/
-- STEP 2: Create helper table for loan information
-- Purpose: Get all email/phone combinations for each PAYOFFUID (current and historical)
-- Reason: ContactCenter views sometimes grab incorrect/old PAYOFFUIDs
/***********************************************************************************/

CREATE OR REPLACE TEMP TABLE cron_store.temp_vw_loan AS
WITH email AS (
    SELECT DISTINCT
        member_id
        ,email
        ,REPLACE(phone_number, '+1', '') AS phone_number
    FROM business_intelligence.analytics_pii.vw_member_pii
)
SELECT
    vl.lead_guid
    ,vl.legacy_loan_id
    ,vl.origination_date
    ,IFNULL(vl.loan_closed_date, '2999-12-31') AS loan_closed_date
    ,e.email
    ,e.phone_number
    ,app.app_dt
    ,COALESCE(app.app_dt, vl.origination_date) AS app_start_or_origination_date
FROM
    email e
    LEFT JOIN business_intelligence.analytics.vw_loan vl
        ON vl.member_id = e.member_id
    LEFT JOIN business_intelligence.bridge.app_loan_production app
        ON vl.lead_guid = app.guid
WHERE e.email NOT ILIKE '%IN-MIGRATION%';

/***********************************************************************************/
-- STEP 3: Create PAYOFFUID lookup dimension table
-- Purpose: Filter to only the 15 requested loans and their email/phone history
-- Usage: Join ContactCenter views to this table on email/phone with date range conditions
/***********************************************************************************/

CREATE OR REPLACE TEMP TABLE cron_store.temp_payoffuid_lookup AS
SELECT *
FROM cron_store.temp_vw_loan
WHERE email IN (
    SELECT email
    FROM cron_store.temp_vw_loan
    WHERE lead_guid IN (
        SELECT payoff_uid
        FROM cron_store.temp_target_payoff_uids
    )
)
ORDER BY email, loan_closed_date;

/***********************************************************************************/
-- STEP 4: Query 1 - ContactCenter Phone Call Activity
-- Output: 1_fortress_q3_2025_genesys_phonecall_activity.csv
-- Filter: Q3 2025 interactions only
/***********************************************************************************/

SELECT
    a.RECORDING_URL
    ,a.INTERACTION_START_TIME
    ,a.INTERACTION_END_TIME
    ,a.INTERACTION_DURATION
    ,a.MEDIATYPE
    ,a.MESSAGETYPE
    ,tpl.lead_guid AS payoffuid
    ,tpl.legacy_loan_id AS payoffloanid
    ,a.USERID
    ,a.NAME
    ,a.CALL_ABANDONED
    ,a.CONVERSATIONID
    ,a.CONTACT_PHONE
    ,a.DAY_OF_WEEK
    ,a.DISPOSITION_CODE
    ,a.CALL_DIRECTION
    ,a.ORIGINATINGDIRECTION
    ,a.CAMPAIGN
FROM
    BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY a
    JOIN cron_store.temp_payoffuid_lookup tpl
        ON a.CONTACT_PHONE = tpl.phone_number
WHERE
    -- Q3 2025 filter
    a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    -- Match interaction to correct loan period
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date
ORDER BY a.INTERACTION_START_TIME;

/***********************************************************************************/
-- STEP 5: Query 2 - ContactCenter SMS Activity
-- Output: 2_fortress_q3_2025_genesys_sms_activity.csv
-- Filter: Q3 2025 interactions only
/***********************************************************************************/

SELECT
    a.INTERACTION_START_TIME
    ,a.INTERACTION_END_TIME
    ,a.INTERACTION_DURATION
    ,a.RECORDING_URL
    ,a.CONVERSATIONID
    ,tpl.lead_guid AS payoffuid
    ,tpl.legacy_loan_id AS payoffloanid
    ,a.MEDIATYPE
    ,a.MESSAGETYPE
    ,a.DAY_OF_WEEK
    ,a.LASTDIRECTION
    ,a.ORIGINATINGDIRECTION
    ,a.CONTACT_PHONE
    ,a.WRAPUP
    ,a.IN_BUSINESS_HOURS_DEL
    ,a.MESSAGE_IND
    ,a.TIME_CONNECTED
    ,a.CONNECTED_IND
    ,a.ACDOUTCOME
    ,a.FIRSTNAME
    ,a.LASTNAME
    ,a.ACCOUNTEMAIL
    ,a.CAMPAIGNNAME
FROM
    BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY a
    JOIN cron_store.temp_payoffuid_lookup tpl
        ON (a.CONTACT_PHONE = tpl.phone_number OR LOWER(a.ACCOUNTEMAIL) = LOWER(tpl.email))
WHERE
    -- Q3 2025 filter
    a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    -- Match interaction to correct loan period
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date
ORDER BY a.INTERACTION_START_TIME;

/***********************************************************************************/
-- STEP 6: Query 3 - ContactCenter Email Activity
-- Output: 3_fortress_q3_2025_genesys_email_activity.csv
-- Filter: Q3 2025 interactions only
/***********************************************************************************/

SELECT
    a.INTERACTION_START_TIME
    ,a.INTERACTION_END_TIME
    ,a.INTERACTION_DURATION
    ,a.RECORDING_URL
    ,a.CONVERSATIONID
    ,tpl.lead_guid AS payoffuid
    ,tpl.legacy_loan_id AS payoffloanid
    ,a.MEDIATYPE
    ,a.EXTERNAL_EMAIL_ADDRESS
    ,a.INTERNAL_EMAIL_ADDRESS
    ,a.ORIGINATINGDIRECTION
    ,a.DIRECTION
    ,a.FINAL_AGENT_NAME
    ,a.FINAL_AGENT_EMAIL
    ,a.FINAL_DISPOSITION
    ,a.EMAIL_SUBJECT
FROM
    BUSINESS_INTELLIGENCE.PII.VW_GENESYS_EMAIL_ACTIVITY a
    JOIN cron_store.temp_payoffuid_lookup tpl
        ON LOWER(a.EXTERNAL_EMAIL_ADDRESS) = LOWER(tpl.email)
WHERE
    -- Q3 2025 filter
    a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    -- Match interaction to correct loan period
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date
ORDER BY a.INTERACTION_START_TIME;

/***********************************************************************************/
-- STEP 7: Query 4 - Loan Notes
-- Output: 4_fortress_q3_2025_loan_notes.csv
-- Filter: All dates (not restricted to Q3 - shows complete note history)
-- Note: HTML tags stripped from BODY field for readability
/***********************************************************************************/
--4_fortress_q3_2025_loan_notes
SELECT
    b.LEAD_GUID AS PAYOFFUID
    ,tpl.legacy_loan_id AS payoffloanid
    ,a.SUBJECT
    ,REGEXP_REPLACE(
        REGEXP_REPLACE(a.BODY, '<[^>]+>', ' '),  -- Remove HTML tags
        '\\s+', ' '  -- Collapse multiple spaces into single space
    ) AS BODY
    ,a.CREATED
FROM
    BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_NOTES a
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT b
        ON a.PARENT_ID = b.LOAN_ID
    LEFT JOIN cron_store.temp_payoffuid_lookup tpl
        ON b.lead_guid = tpl.lead_guid
WHERE
    -- Only include notes for our 15 loans
    tpl.lead_guid IS NOT NULL
ORDER BY b.LEAD_GUID, a.CREATED DESC;

/***********************************************************************************/
-- STEP 8: Query 5 - email_platform Email Activity
-- Output: 5_fortress_q3_2025_sfmc_email_activity.csv
-- Filter: Q3 2025, delinquent campaign, sent events only
/***********************************************************************************/

SELECT
    a.sent
    ,b.PAYOFFUID
    ,tpl.legacy_loan_id AS payoffloanid
    ,DATE(a.EVENT_DATE) AS sent_date
    ,a.SEND_TABLE_EMAIL_NAME AS EMAIL_CAMPAIGN_NAME
    ,a.EVENT_TYPE
    ,a.EMAIL_ID
FROM
    BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
    INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY b
        ON a.DERIVED_PAYOFFUID = b.PAYOFFUID
        AND DATE(a.EVENT_DATE) = DATEADD('day', 1, b.ASOFDATE)
    JOIN cron_store.temp_payoffuid_lookup tpl
        ON b.payoffuid = tpl.lead_guid
WHERE
    -- Q3 2025 filter
    DATE(a.EVENT_DATE) BETWEEN $q3_start_date AND $q3_end_date
    -- Collection emails only
    AND UPPER(a.CAMPAIGN) = UPPER('delinquent')
    AND UPPER(a.EVENT_TYPE) = UPPER('Sent')
ORDER BY a.EVENT_DATE DESC;

--ADDITIONAL DATA TO UNION TO THE BOTTOM FOR MISSING LOANS
-- WE NEED TO UTILIZE THIS MATCHING LOGIC FOR THE FUTURE
--union_to_file_5
with identifiers as (
SELECT b.LEGACY_LOAN_ID, b.LOAN_ID, b.LEAD_GUID, b.APPLICATION_ID, c.EMAIL, d.CUSTOMER_ID as LOS_CUSTOMER_ID
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN b
left join business_intelligence.ANALYTICS_PII.VW_MEMBER_PII c
    on c.MEMBER_ID = b.MEMBER_ID
    and c.MEMBER_PII_END_DATE is null
left join BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT d
    on d.LOAN_ID = b.APPLICATION_ID and d.SCHEMA_NAME = CONFIG.LOS_SCHEMA()
where b.LEGACY_LOAN_ID in ('HMFEA7BC6F49C4', 'HMF6E406E22863', 'HMD339CB14B81D', 'HM68A034E3AF31', 'HM7DCB74C375AD')
)
select a.sent
    ,b.LEAD_GUID as PAYOFFUID
    ,b.legacy_loan_id AS payoffloanid
    ,DATE(a.EVENT_DATE) AS sent_date
    ,a.SEND_TABLE_EMAIL_NAME AS EMAIL_CAMPAIGN_NAME
    ,a.EVENT_TYPE
    ,a.EMAIL_ID
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
inner join identifiers b
on a.SUBSCRIBER_KEY = b.LOS_CUSTOMER_ID::varchar
where 1=1
and UPPER(a.EVENT_TYPE) = 'SENT'
and DATE(a.EVENT_DATE) BETWEEN $q3_start_date AND $q3_end_date
order by EVENT_DATE desc;
