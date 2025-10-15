-- DI-1261: Loan Data Query for DMS
-- DI-1309 Compliant: Uses VW_LOAN, VW_APP_LOAN_PRODUCTION, VW_MEMBER_PII
-- Date: October 2025
-- Purpose: Funded loan data for DMS
-- Based on IWCO loan data logic (DI-760) with DI-1309 compliant views

with decision as (
    select
        lead_guid,
        ficoscore,
        logisticalpredictionofdefault,
        risk_model_version,
        loanamountcounteroffer,
        finaldecision
    from analytics.vw_decisions_current
    where active_record_flag = true
        and source = 'prod'
        and lead_guid is not null
)
select
    loan.lead_guid as payoffuid,
    pii.first_name,
    pii.last_name,
    pii.address_1,
    pii.address_2,
    pii.city,
    pii.state,
    pii.zip_code as zip5,
    pii.phone_number as phone,
    pii.email,
    pii.date_of_birth,
    loan.origination_date as member_since_date,
    app.app_ts as first_activation_success_date,
    app.requested_loan_amt as requested_amount,
    case
        when lower(decision.finaldecision) = 'approve' and decision.loanamountcounteroffer is null
            then app.requested_loan_amt
        when lower(decision.finaldecision) = 'approve' and decision.loanamountcounteroffer is not null
            then decision.loanamountcounteroffer
    end as credit_line_amount,
    cls.TOTAL_ANNUAL_INCOME_LS as income,
    decision.logisticalpredictionofdefault as custom_credit_score,
    decision.risk_model_version as custom_credit_score_version,
    decision.ficoscore as fico_score,
    loan.loan_amount,
    loan.term as loan_term,
    loan.apr as loan_apr,
    case when (loan.loan_closed_date is not null and loan.charge_off_date is null) then true else false end as closed_in_good_standing,
    case when (loan.loan_closed_date is null and loan.charge_off_date is null) then true else false end as open_in_good_standing,
    case when loan.charge_off_date is not null then true else false end as not_in_good_standing,
    loan.origination_date
from (
    select distinct
        lead_guid,
        member_id,
        loan_amount,
        origination_date,
        term,
        apr,
        loan_closed_date,
        charge_off_date
    from analytics.vw_loan
) as loan
left join bridge.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls on loan.lead_guid = cls.application_guid
left join analytics.vw_app_loan_production app on loan.lead_guid = app.guid
left join analytics_pii.vw_member_pii pii
    on loan.member_id = pii.member_id
    and pii.member_pii_end_date is null
left join decision on loan.lead_guid = decision.lead_guid
