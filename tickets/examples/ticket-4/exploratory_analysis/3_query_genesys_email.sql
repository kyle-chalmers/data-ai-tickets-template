-- Query 3: ContactCenter Email Activity
-- Run after 0_setup_temp_tables.sql
SET q3_start_date = '2025-07-01';
SET q3_end_date = '2025-09-30';

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
    a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date
ORDER BY a.INTERACTION_START_TIME;
