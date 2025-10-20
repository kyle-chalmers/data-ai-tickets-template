USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
SET q3_start_date = '2025-07-01';
SET q3_end_date = '2025-09-30';

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

-- Query 5: email_platform Email Activity
SELECT
    a.SENT,
    b.PAYOFFUID,
    b.LOANID AS PAYOFFLOANID,
    DATE(a.EVENT_DATE) AS SENT_DATE,
    a.SEND_TABLE_EMAIL_NAME AS EMAIL_CAMPAIGN_NAME,
    a.EVENT_TYPE,
    a.EMAIL_ID,
    a.CAMPAIGN
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
INNER JOIN BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY b
    ON a.DERIVED_PAYOFFUID = b.PAYOFFUID
    AND DATE(a.EVENT_DATE) = DATEADD('day', 1, b.ASOFDATE)
JOIN cron_store.temp_target_payoff_uids tpl
    ON b.payoffuid = tpl.payoff_uid
WHERE DATE(a.EVENT_DATE) BETWEEN $q3_start_date AND $q3_end_date
    AND UPPER(a.CAMPAIGN) = UPPER('delinquent')
    AND UPPER(a.EVENT_TYPE) = UPPER('Sent')
ORDER BY a.EVENT_DATE DESC;
