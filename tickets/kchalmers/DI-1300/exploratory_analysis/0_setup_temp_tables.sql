-- DI-1300: Setup temp tables (run this first)
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

SELECT 'Setup complete - temp tables created' AS status,
       COUNT(*) as lookup_table_rows
FROM cron_store.temp_payoffuid_lookup;
