-- DI-1261: Application Data Union Query (ORIGINAL - REFERENCE ONLY)
-- This is the original query structure that combines VW_APPLICATION + VW_APP_LOAN_PRODUCTION
-- Date: September 2025
-- Status: ARCHIVED - For reference only
-- Current Implementation: Uses production-only query (application_data_production_only_query.sql)

CREATE OR REPLACE TABLE CRON_STORE.RPT_APPLICATION_DATA_DI_760_UNION AS (

WITH
-- ==============================================================
-- Decision data (for both applications and leads)
-- ==============================================================
decision AS (
    SELECT lead_guid, ficoscore, logisticalpredictionofdefault, risk_model_version,
           loanamountcounteroffer, finaldecision, risktier, decisionreason
    FROM analytics.vw_decisions_current
    WHERE active_record_flag = true
        AND source = 'prod'
        AND lead_guid IS NOT NULL
),

-- ==============================================================
-- Application Status History (for status tracking)
-- ==============================================================
appl_his_legacy AS (
    SELECT payoff_uid AS lead_guid, gen_new_value AS new_status_value,
           app_his.dss_load_date AS new_status_begin_datetime
    FROM data_store.vw_appl_status_history app_his
    JOIN data_store.vw_application app ON app_his.gen_application = app.id
    WHERE gen_is_latest_status AND application_start_date >= '2023-05-01'
),
app_his_new AS (
    SELECT lead_guid, new_status_value, new_status_begin_datetime
    FROM analytics.vw_appl_status_history his
    JOIN analytics.vw_application a ON his.application_id = a.application_id
    WHERE a.application_started_date >= '2023-05-01'
),
app_his AS (
    SELECT * FROM app_his_new
    UNION
    SELECT * FROM appl_his_legacy
),
app_his_rk AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY lead_guid ORDER BY new_status_begin_datetime DESC) AS rk
    FROM app_his
    WHERE new_status_value IS NOT NULL
),
latest_app_status AS (
    SELECT * FROM app_his_rk WHERE rk = 1
),
penultimate_app_status AS (
    SELECT * FROM app_his_rk WHERE rk = 2
),

-- ==============================================================
-- PART 1: Complete Applications from VW_APPLICATION (includes income)
-- ==============================================================
applications AS (
    SELECT
        app.lead_guid AS customer_id,
        pii.first_name,
        pii.last_name,
        pii.address_1,
        pii.address_2,
        pii.city,
        pii.state,
        pii.zip_code AS zip5,
        pii.phone_number AS phone,
        pii.email,
        pii.date_of_birth,
        app.application_started_date AS application_date,
        latest_app_status.new_status_begin_datetime::DATE AS application_updated_date,
        app.last_touch_utm_channel_grouping AS acquisition_channel,
        app.requested_loan_amount::NUMBER(12,2) AS requested_amount,
        CASE
            WHEN LOWER(decision.finaldecision) = 'approve' AND decision.loanamountcounteroffer IS NULL
                THEN app.requested_loan_amount::NUMBER(12,2)
            WHEN LOWER(decision.finaldecision) = 'approve' AND decision.loanamountcounteroffer IS NOT NULL
                THEN decision.loanamountcounteroffer::NUMBER(12,2)
        END AS credit_line_amount,
        app.annual_income AS income,
        decision.logisticalpredictionofdefault AS custom_credit_score,
        decision.ficoscore::NUMBER(3,0) AS fico_score,
        decision.risktier AS risktier,
        decision.decisionreason,
        latest_app_status.new_status_value AS application_status,
        penultimate_app_status.new_status_value AS application_penultimate_status,
        IFF(app.origination_date IS NULL, 0, 1) AS loan_flag,
        app.origination_date AS loan_date,
        loan_setting.dm_invitation_code AS offer_code,
        'PAYOFF LOAN' AS product
    FROM analytics.vw_application app
    LEFT JOIN analytics_pii.vw_lead_pii pii ON app.lead_guid = pii.lead_guid
    LEFT JOIN bridge.vw_los_custom_loan_settings_current loan_setting ON app.lead_guid = loan_setting.application_guid
    LEFT JOIN decision ON app.lead_guid = decision.lead_guid
    LEFT JOIN latest_app_status ON app.lead_guid = latest_app_status.lead_guid
    LEFT JOIN penultimate_app_status ON app.lead_guid = penultimate_app_status.lead_guid
    WHERE app.application_started_date >= '2023-05-01'
),

-- ==============================================================
-- PART 2: Lead-only data from VW_APP_LOAN_PRODUCTION (enhanced mapping)
-- ==============================================================
leads_only AS (
    SELECT
        lp.guid AS customer_id,
        pii.first_name,
        pii.last_name,
        pii.address_1,
        pii.address_2,
        pii.city,
        pii.state,
        pii.zip_code AS zip5,
        pii.phone_number AS phone,
        COALESCE(pii.email, lp.email) AS email,
        pii.date_of_birth,
        lp.app_dt AS application_date,
        lp.applied_ts::DATE AS application_updated_date,
        COALESCE(utm_lookup.LAST_TOUCH_UTM_CHANNEL_GROUPING, lp.app_channel, lp.utm_source) AS acquisition_channel,
        lp.requested_loan_amt::NUMBER(12,2) AS requested_amount,
        CASE
            WHEN LOWER(decision.finaldecision) = 'approve' AND decision.loanamountcounteroffer IS NULL
                THEN lp.requested_loan_amt::NUMBER(12,2)
            WHEN LOWER(decision.finaldecision) = 'approve' AND decision.loanamountcounteroffer IS NOT NULL
                THEN decision.loanamountcounteroffer::NUMBER(12,2)
            ELSE lp.max_offer_amt::NUMBER(12,2)
        END AS credit_line_amount,
        NULL AS income,
        decision.logisticalpredictionofdefault AS custom_credit_score,
        COALESCE(decision.ficoscore::NUMBER(3,0), lp.credit_score::NUMBER(3,0)) AS fico_score,
        COALESCE(decision.risktier, lp.tier::VARCHAR) AS risktier,
        decision.decisionreason,
        lp.app_status AS application_status,
        NULL AS application_penultimate_status,
        IFF(lp.loan_id IS NULL, 0, 1) AS loan_flag,
        lp.originated_dt AS loan_date,
        lp.dm_invitation_cd AS offer_code,
        'PAYOFF LOAN' AS product
    FROM analytics.vw_app_loan_production lp
    LEFT JOIN analytics_pii.vw_lead_pii pii ON lp.guid = pii.lead_guid
    LEFT JOIN decision ON lp.guid = decision.lead_guid
    LEFT JOIN BRIDGE.VW_UTM_SOURCE_MEDIUM_CHANNEL_GROUPING_LOOKUP AS utm_lookup
        ON UPPER(COALESCE(lp.utm_medium, '')) = UPPER(IFNULL(utm_lookup.utm_medium, ''))
        AND UPPER(COALESCE(lp.utm_source, '')) = UPPER(IFNULL(utm_lookup.utm_source, ''))
    WHERE lp.app_dt >= '2023-05-01'
        AND lp.guid NOT IN (
            SELECT lead_guid
            FROM analytics.vw_application
            WHERE application_started_date >= '2023-05-01'
                AND lead_guid IS NOT NULL
        )
)

-- ==============================================================
-- FINAL UNION: Applications + Lead-only data
-- ==============================================================
SELECT * FROM applications
UNION ALL
SELECT * FROM leads_only

);
