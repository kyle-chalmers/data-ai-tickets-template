-- DI-1261: Column Statistics Query
-- Purpose: Validate data quality and record counts for DMS data feeds
-- Use: Run in Snowflake to check data volumes and completeness

-- Application Data Statistics
SELECT
    'Application Data' as feed_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT GUID) as unique_guids,
    MIN(APP_CREATED_TS::date) as earliest_app_date,
    MAX(APP_CREATED_TS::date) as latest_app_date,
    COUNT(CASE WHEN EMAIL IS NOT NULL THEN 1 END) as records_with_email,
    COUNT(CASE WHEN PHONE_NUMBER IS NOT NULL THEN 1 END) as records_with_phone,
    COUNT(CASE WHEN SSN IS NOT NULL THEN 1 END) as records_with_ssn
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION
WHERE DATE(APP_CREATED_TS) >= '2023-05-01'

UNION ALL

-- Loan Data Statistics
SELECT
    'Loan Data' as feed_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT L.LEAD_GUID) as unique_guids,
    MIN(L.ORIGINATION_DATE::date) as earliest_app_date,
    MAX(L.ORIGINATION_DATE::date) as latest_app_date,
    COUNT(CASE WHEN PII.EMAIL IS NOT NULL THEN 1 END) as records_with_email,
    COUNT(CASE WHEN PII.PHONE_NUMBER IS NOT NULL THEN 1 END) as records_with_phone,
    COUNT(CASE WHEN PII.SSN IS NOT NULL THEN 1 END) as records_with_ssn
FROM ANALYTICS.VW_LOAN as L
INNER JOIN ANALYTICS_PII.VW_MEMBER_PII as PII
    ON L.MEMBER_ID = PII.MEMBER_ID
    AND PII.MEMBER_PII_END_DATE IS NULL
WHERE L.LOAN_STATUS IN ('Active - Good Standing', 'Active - Bad Standing', 'Charged Off')

UNION ALL

-- Suppression Data Statistics
SELECT
    'Suppression Data' as feed_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT PAYOFFUID) as unique_guids,
    NULL as earliest_app_date,
    NULL as latest_app_date,
    NULL as records_with_email,
    NULL as records_with_phone,
    NULL as records_with_ssn
FROM (
    -- LoanPro Declined
    SELECT appl.GUID as PAYOFFUID
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    INNER JOIN (
        SELECT guid, status_timestamp
        FROM analytics.vw_app_status_transition
        UNPIVOT (status_timestamp FOR status_name IN (DECLINED_MAX_TS))
        WHERE status_timestamp IS NOT NULL
    ) status_unpivot ON appl.GUID = status_unpivot.guid
    WHERE DATEDIFF(day, DATE(status_timestamp), CURRENT_DATE()) <= 20

    UNION ALL

    -- CLS Declined
    SELECT appl.GUID as PAYOFFUID
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    INNER JOIN analytics.vw_app_status_transition status
        ON appl.GUID = status.guid
    WHERE status.declined_max_ts IS NOT NULL
        AND DATEDIFF(day, DATE(status.declined_max_ts), CURRENT_DATE()) <= 20

    UNION ALL

    -- Recent Applications
    SELECT appl.GUID as PAYOFFUID
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    WHERE DATEDIFF(day, DATE(appl.APP_CREATED_TS), CURRENT_DATE()) <= 20

    UNION ALL

    -- TCPA Suppressions
    SELECT appl.GUID as PAYOFFUID
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    INNER JOIN analytics_pii.VW_APP_PII pii
        ON appl.GUID = pii.GUID
    WHERE pii.DO_NOT_CALL = true
        OR pii.DO_NOT_EMAIL = true

    UNION ALL

    -- Mail Opt-outs
    SELECT L.LEAD_GUID as PAYOFFUID
    FROM ANALYTICS.VW_LOAN as L
    INNER JOIN ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
        ON L.LOAN_ID = LCR.LOAN_ID::VARCHAR
        AND LCR.CONTACT_RULE_END_DATE IS NULL
    WHERE LCR.SUPPRESS_MAIL = true
) suppressions;

-- Suppression Breakdown by Type
SELECT
    suppression_type,
    COUNT(*) as record_count,
    COUNT(DISTINCT PAYOFFUID) as unique_customers,
    MIN(updated_date) as earliest_date,
    MAX(updated_date) as latest_date
FROM (
    SELECT
        appl.GUID as PAYOFFUID,
        'declined_in_the_past_20_days_loanpro' as suppression_type,
        status_timestamp::date as updated_date
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    INNER JOIN (
        SELECT guid, status_timestamp
        FROM analytics.vw_app_status_transition
        UNPIVOT (status_timestamp FOR status_name IN (DECLINED_MAX_TS))
        WHERE status_timestamp IS NOT NULL
    ) status_unpivot ON appl.GUID = status_unpivot.guid
    WHERE DATEDIFF(day, DATE(status_timestamp), CURRENT_DATE()) <= 20

    UNION ALL

    SELECT
        appl.GUID as PAYOFFUID,
        'declined_in_the_past_20_days_cls' as suppression_type,
        status.declined_max_ts::date as updated_date
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    INNER JOIN analytics.vw_app_status_transition status
        ON appl.GUID = status.guid
    WHERE status.declined_max_ts IS NOT NULL
        AND DATEDIFF(day, DATE(status.declined_max_ts), CURRENT_DATE()) <= 20

    UNION ALL

    SELECT
        appl.GUID as PAYOFFUID,
        'app_submitted_in_the_past_20_days' as suppression_type,
        appl.APP_CREATED_TS::date as updated_date
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    WHERE DATEDIFF(day, DATE(appl.APP_CREATED_TS), CURRENT_DATE()) <= 20

    UNION ALL

    SELECT
        appl.GUID as PAYOFFUID,
        'tcpa_suppression' as suppression_type,
        CURRENT_DATE() as updated_date
    FROM analytics.VW_APP_LOAN_PRODUCTION appl
    INNER JOIN analytics_pii.VW_APP_PII pii
        ON appl.GUID = pii.GUID
    WHERE pii.DO_NOT_CALL = true
        OR pii.DO_NOT_EMAIL = true

    UNION ALL

    SELECT
        L.LEAD_GUID as PAYOFFUID,
        'mail_opt_out' as suppression_type,
        LCR.SUPPRESS_MAIL_START_DATE::date as updated_date
    FROM ANALYTICS.VW_LOAN as L
    INNER JOIN ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
        ON L.LOAN_ID = LCR.LOAN_ID::VARCHAR
        AND LCR.CONTACT_RULE_END_DATE IS NULL
    WHERE LCR.SUPPRESS_MAIL = true
) suppressions
GROUP BY suppression_type
ORDER BY record_count DESC;
