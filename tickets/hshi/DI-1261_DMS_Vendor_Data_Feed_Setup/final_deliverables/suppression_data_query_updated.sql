-- DI-1261: Suppression Data Query for DMS
-- DI-1309 Compliant: Uses VW_APP_LOAN_PRODUCTION, VW_APP_STATUS_TRANSITION, VW_APP_PII
-- Date: October 2025
-- Purpose: Customer suppression rules for DMS to apply
-- Based on IWCO suppression logic (DI-760) with DI-1309 compliant views

-- ==============================================================================
-- LEAD SUPPRESSIONS (from applications)
-- ==============================================================================

-- LoanPro applications: declined in past 20 days
with lead_suppressions as (
    select
        appl.GUID as PAYOFFUID,
        'declined_in_the_past_20_days_loanpro' as SUPPRESSION_TYPE,
        st.declined_max_ts::date as UPDATED_DATE
    from analytics.VW_APP_LOAN_PRODUCTION appl
    inner join analytics.vw_app_status_transition st on appl.GUID = st.guid
    where st.declined_max_ts is not null
        and datediff(day, date(st.declined_max_ts), current_date()) <= 20
),

-- ==============================================================================
-- LOAN SUPPRESSIONS (bad standing loans)
-- ==============================================================================

-- Bad standing loans: not paid in full or current
bad_standing_loans as (
    select
        LT.PAYOFFUID,
        'bad_standing_loan' as SUPPRESSION_TYPE,
        LT.ASOFDATE::date as UPDATED_DATE
    from DATA_STORE.MVW_LOAN_TAPE LT
    where lower(LT.STATUS) not in ('paid in full', 'current')
)

-- ==============================================================================
-- FINAL OUTPUT - Join with PII data
-- ==============================================================================
select
    s.PAYOFFUID,
    pii_app.FIRST_NAME,
    pii_app.LAST_NAME,
    pii_app.ADDRESS_1,
    pii_app.ADDRESS_2,
    pii_app.CITY,
    pii_app.STATE,
    pii_app.ZIP_CODE as ZIP5,
    pii_app.PHONE_NBR as PHONE,
    pii_app.EMAIL,
    s.SUPPRESSION_TYPE
from lead_suppressions s
left join ANALYTICS_PII.VW_APP_PII pii_app on s.PAYOFFUID = pii_app.GUID
union
select
    l.PAYOFFUID,
    pii_member.FIRST_NAME,
    pii_member.LAST_NAME,
    pii_member.ADDRESS_1,
    pii_member.ADDRESS_2,
    pii_member.CITY,
    pii_member.STATE,
    pii_member.ZIP_CODE as ZIP5,
    pii_member.PHONE_NUMBER as PHONE,
    pii_member.EMAIL,
    l.SUPPRESSION_TYPE
from bad_standing_loans l
inner join ANALYTICS.VW_LOAN vl on l.PAYOFFUID = vl.LEAD_GUID
left join ANALYTICS_PII.VW_MEMBER_PII pii_member
    on vl.MEMBER_ID = pii_member.MEMBER_ID
    and pii_member.MEMBER_PII_END_DATE is null
union
select
    null as PAYOFFUID,
    m.FIRSTNAME as FIRST_NAME,
    m.LASTNAME as LAST_NAME,
    m.ADDRESSLINE1 as ADDRESS_1,
    m.ADDRESSLINE2 as ADDRESS_2,
    m.CITY,
    m.STATE,
    m.POSTALCODE as ZIP5,
    null as PHONE,
    null as EMAIL,
    'mail_optout' as SUPPRESSION_TYPE
from PII.RPT_OPTOUT_MAIL_SFMC m
