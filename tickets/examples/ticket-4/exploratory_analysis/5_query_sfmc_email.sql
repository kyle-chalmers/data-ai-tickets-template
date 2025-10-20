-- Query 5: email_platform Email Activity
-- Run after 0_setup_temp_tables.sql
SET q3_start_date = '2025-07-01';
SET q3_end_date = '2025-09-30';

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
    DATE(a.EVENT_DATE) BETWEEN $q3_start_date AND $q3_end_date
    AND UPPER(a.CAMPAIGN) = UPPER('delinquent')
    AND UPPER(a.EVENT_TYPE) = UPPER('Sent')
ORDER BY a.EVENT_DATE DESC;
