-- Query 4: Loan Notes (all dates)
-- Run after 0_setup_temp_tables.sql

SELECT
    b.LEAD_GUID AS PAYOFFUID
    ,tpl.legacy_loan_id AS payoffloanid
    ,a.SUBJECT
    ,a.BODY
    ,a.CREATED
FROM
    BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_NOTES a
    LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT b
        ON a.PARENT_ID = b.LOAN_ID
    LEFT JOIN cron_store.temp_payoffuid_lookup tpl
        ON b.lead_guid = tpl.lead_guid
WHERE
    tpl.lead_guid IS NOT NULL
ORDER BY b.LEAD_GUID, a.CREATED DESC;
