-- Query 1: Genesys Phone Call Activity
-- Run after 0_setup_temp_tables.sql
SET q3_start_date = '2025-07-01';
SET q3_end_date = '2025-09-30';

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
    a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date
ORDER BY a.INTERACTION_START_TIME;
