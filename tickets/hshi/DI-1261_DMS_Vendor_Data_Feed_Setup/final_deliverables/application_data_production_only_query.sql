-- DI-1261: Application Data Query for DMS
-- DI-1309 Compliant: Uses VW_APP_LOAN_PRODUCTION and VW_APP_STATUS_TRANSITION
-- Date: October 2025
-- Purpose: Application-level customer data from 2023-05-01 to present

WITH
-- ==============================================================
-- Decision data (for applications)
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
-- Application Status History using VW_APP_STATUS_TRANSITION
-- ==============================================================
status_transitions AS (
    SELECT guid, status_name, status_timestamp
    FROM analytics.vw_app_status_transition
    UNPIVOT (
        status_timestamp FOR status_name IN (
            AFFILIATE_LANDED_MAX_TS,
            AFFILIATE_STARTED_MAX_TS,
            ALLOCATED_MAX_TS,
            APPLIED_MAX_TS,
            APPROVED_MAX_TS,
            APPROVED_RECEIVED_MAX_TS,
            AUTOMATED_UNDERWRITING_COMPLETED_MAX_TS,
            AUTOMATED_UNDERWRITING_RECEIVED_MAX_TS,
            AUTOMATED_UNDERWRITING_REQUESTED_MAX_TS,
            AUTOPAY_COMPLETED_REQUESTED_MAX_TS,
            AUTOPAY_DATA_SUBMITTED_MAX_TS,
            AUTOPAY_OPT_OUT_RECEIVED_MAX_TS,
            AUTOPAY_OPT_OUT_REQUESTED_MAX_TS,
            AWAITING_DCP_MAX_TS,
            CREDIT_FREEZE_MAX_TS,
            CREDIT_FREEZE_STACKER_CHECK_MAX_TS,
            DCP_CAPTURED_MAX_TS,
            DCP_OPT_IN_MAX_TS,
            DECLINED_MAX_TS,
            DOC_UPLOAD_MAX_TS,
            EXPIRED_MAX_TS,
            FRAUD_CHECK_FAILED_MAX_TS,
            FRAUD_CHECK_RECEIVED_MAX_TS,
            FRAUD_REJECTED_MAX_TS,
            FUNDED_MAX_TS,
            ICS_MAX_TS,
            LOAN_DOCS_COMPLETED_MAX_TS,
            LOAN_DOCS_READY_MAX_TS,
            LOAN_DOCS_SIGNED_REQUESTED_MAX_TS,
            OFFERS_DECISION_COMPLETED_MAX_TS,
            OFFERS_DECISION_RECEIVED_MAX_TS,
            OFFERS_DECISION_REQUESTED_MAX_TS,
            OFFERS_SHOWN_MAX_TS,
            OFFER_SELECTED_MAX_TS,
            OPEN_REPAYING_MAX_TS,
            ORIGINATED_MAX_TS,
            PARTNER_REJECTED_MAX_TS,
            PENDING_FUNDING_MAX_TS,
            PRE_FUNDING_MAX_TS,
            STACKER_CHECK_COMPLETED_MAX_TS,
            STACKER_CHECK_REQUESTED_MAX_TS,
            STACKER_CHECK_REQUEST_RECEIVED_MAX_TS,
            STARTED_MAX_TS,
            TIL_ACKNOWLEDGED_MAX_TS,
            TIL_GENERATION_COMPLETE_MAX_TS,
            TIL_GENERATION_RECEIVED_MAX_TS,
            TIL_GENERATION_REQUESTED_MAX_TS,
            UNDERWRITING_COMPLETE_MAX_TS,
            UNDERWRITING_MAX_TS,
            WITHDRAWN_MAX_TS
        )
    )
    WHERE status_timestamp IS NOT NULL
),
app_his_rk AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY guid ORDER BY status_timestamp DESC) AS rk
    FROM status_transitions
),
latest_app_status AS (
    SELECT * FROM app_his_rk WHERE rk = 1
),
penultimate_app_status AS (
    SELECT * FROM app_his_rk WHERE rk = 2
)

-- ==============================================================
-- Main query: VW_APP_LOAN_PRODUCTION with enhanced field mapping
-- ==============================================================
SELECT
    lp.guid AS payoffuid,
    pii.first_name,
    pii.last_name,
    pii.address_1,
    pii.address_2,
    pii.city,
    pii.state,
    pii.zip_code AS zip5,
    pii.phone_nbr AS phone,
    COALESCE(pii.email, lp.email) AS email,
    pii.date_of_birth,
    lp.app_dt AS application_date,
    latest_app_status.status_timestamp::DATE AS application_updated_date,
    COALESCE(utm_lookup.LAST_TOUCH_UTM_CHANNEL_GROUPING, lp.app_channel, lp.utm_source) AS acquisition_channel,
    lp.requested_loan_amt::NUMBER(12,2) AS requested_amount,
    CASE
        WHEN LOWER(decision.finaldecision) = 'approve' AND decision.loanamountcounteroffer IS NULL
            THEN lp.requested_loan_amt::NUMBER(12,2)
        WHEN LOWER(decision.finaldecision) = 'approve' AND decision.loanamountcounteroffer IS NOT NULL
            THEN decision.loanamountcounteroffer::NUMBER(12,2)
        ELSE lp.max_offer_amt::NUMBER(12,2)
    END AS credit_line_amount,
    cls.TOTAL_ANNUAL_INCOME_LS AS income,
    decision.logisticalpredictionofdefault AS custom_credit_score,
    COALESCE(decision.ficoscore::NUMBER(3,0), lp.credit_score::NUMBER(3,0)) AS fico_score,
    COALESCE(decision.risktier, lp.tier::VARCHAR) AS risktier,
    decision.decisionreason,
    COALESCE(latest_app_status.status_name, lp.app_status) AS application_status,
    penultimate_app_status.status_name AS application_penultimate_status,
    IFF(lp.loan_id IS NULL, 0, 1) AS loan_flag,
    lp.originated_dt AS loan_date,
    lp.dm_invitation_cd AS offer_code,
    'PAYOFF LOAN' AS product
FROM analytics.vw_app_loan_production lp
left join bridge.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls on lp.guid = cls.application_guid
LEFT JOIN analytics_pii.vw_app_pii pii ON lp.guid = pii.guid
LEFT JOIN decision ON lp.guid = decision.lead_guid
LEFT JOIN latest_app_status ON lp.guid = latest_app_status.guid
LEFT JOIN penultimate_app_status ON lp.guid = penultimate_app_status.guid
LEFT JOIN BRIDGE.VW_UTM_SOURCE_MEDIUM_CHANNEL_GROUPING_LOOKUP AS utm_lookup
    ON UPPER(COALESCE(lp.utm_medium, '')) = UPPER(IFNULL(utm_lookup.utm_medium, ''))
    AND UPPER(COALESCE(lp.utm_source, '')) = UPPER(IFNULL(utm_lookup.utm_source, ''))
