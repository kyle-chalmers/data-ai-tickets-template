-- Query 2: ContactCenter SMS Activity
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
    a.INTERACTION_START_TIME BETWEEN $q3_start_date AND $q3_end_date
    AND a.INTERACTION_START_TIME BETWEEN tpl.app_start_or_origination_date AND tpl.loan_closed_date
ORDER BY a.INTERACTION_START_TIME;
