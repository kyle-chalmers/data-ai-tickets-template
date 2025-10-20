-- ticket-4 QC: Record Count Summary
-- Validates record counts for all 5 collection activity outputs

USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;

SET q3_start_date = '2025-07-01';
SET q3_end_date = '2025-09-30';

-- Recreate temp tables for QC
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

-- QC Summary
SELECT '1. ContactCenter Phone Calls' AS data_source,
       COUNT(*) AS record_count,
       COUNT(DISTINCT tpl.lead_guid) AS unique_loans,
       MIN(a.INTERACTION_START_TIME) AS earliest_interaction,
       MAX(a.INTERACTION_START_TIME) AS latest_interaction
FROM BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY a
JOIN cron_store.temp_payoffuid_lookup tpl
    ON a.CONTACT_PHONE = tpl.phone_number
WHERE a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date

UNION ALL

SELECT '2. ContactCenter SMS' AS data_source,
       COUNT(*) AS record_count,
       COUNT(DISTINCT tpl.lead_guid) AS unique_loans,
       MIN(a.INTERACTION_START_TIME) AS earliest_interaction,
       MAX(a.INTERACTION_START_TIME) AS latest_interaction
FROM BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY a
JOIN cron_store.temp_payoffuid_lookup tpl
    ON (a.CONTACT_PHONE = tpl.phone_number OR LOWER(a.ACCOUNTEMAIL) = LOWER(tpl.email))
WHERE a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date

UNION ALL

SELECT '3. ContactCenter Email' AS data_source,
       COUNT(*) AS record_count,
       COUNT(DISTINCT tpl.lead_guid) AS unique_loans,
       MIN(a.INTERACTION_START_TIME) AS earliest_interaction,
       MAX(a.INTERACTION_START_TIME) AS latest_interaction
FROM BUSINESS_INTELLIGENCE.PII.VW_GENESYS_EMAIL_ACTIVITY a
JOIN cron_store.temp_payoffuid_lookup tpl
    ON LOWER(a.EXTERNAL_EMAIL_ADDRESS) = LOWER(tpl.email)
WHERE a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date

UNION ALL

SELECT '4. Loan Notes (All Dates)' AS data_source,
       COUNT(*) AS record_count,
       COUNT(DISTINCT b.LEAD_GUID) AS unique_loans,
       MIN(a.CREATED) AS earliest_interaction,
       MAX(a.CREATED) AS latest_interaction
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_NOTES a
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT b
    ON a.PARENT_ID = b.LOAN_ID
LEFT JOIN cron_store.temp_payoffuid_lookup tpl
    ON b.lead_guid = tpl.lead_guid
WHERE tpl.lead_guid IS NOT NULL

UNION ALL

SELECT '5. email_platform Email' AS data_source,
       COUNT(*) AS record_count,
       COUNT(DISTINCT b.PAYOFFUID) AS unique_loans,
       MIN(a.EVENT_DATE) AS earliest_interaction,
       MAX(a.EVENT_DATE) AS latest_interaction
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY b
    ON a.DERIVED_PAYOFFUID = b.PAYOFFUID
    AND DATE(a.EVENT_DATE) = DATEADD('day', 1, b.ASOFDATE)
JOIN cron_store.temp_payoffuid_lookup tpl
    ON b.payoffuid = tpl.lead_guid
WHERE DATE(a.EVENT_DATE) BETWEEN $q3_start_date AND $q3_end_date
    AND UPPER(a.CAMPAIGN) = UPPER('delinquent')
    AND UPPER(a.EVENT_TYPE) = UPPER('Sent')

ORDER BY data_source;
