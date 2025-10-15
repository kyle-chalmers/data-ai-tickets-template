-- Bounce Collections Sample Data with Suppression Logic
-- Based on SIMM suppression logic from BI-2482
-- Date: 2025-09-22
-- Ticket: DI-1223

with SST as (
    select L.LEAD_GUID as PAYOFFUID
    from ANALYTICS.VW_LOAN as L
    inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
        on L.LOAN_ID = LP.LOAN_ID::string
        and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
        and LP.PORTFOLIO_ID = 205
),

BOUNCE_OUTBOUND as (
    select current_date as LOAD_DATE,
           'BOUNCE'     as SET_NAME,
           'DPD3-119'   as LIST_NAME,
           PAYOFFUID,
           false        as SUPPRESSION_FLAG,
           ASOFDATE     as LOAN_TAPE_ASOFDATE
    from DATA_STORE.MVW_LOAN_TAPE
    where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
      and substring(PAYOFFUID, 16, 1) in ('4', '5', '6', '7')
      and PAYOFFUID not in (select SST.PAYOFFUID from SST)
),

-- Global Suppressions CTE (from BI-2482 logic)
GLOBAL_SUPPRESSIONS as (
    -- 1. Bankruptcy (ANALYTICS layer)
    select L.LEAD_GUID as PAYOFFUID, 'Bankruptcy' as SUPPRESSION_REASON
    from ANALYTICS.VW_LOAN_BANKRUPTCY as LB
    inner join ANALYTICS.VW_LOAN as L
        on LB.LOAN_ID = L.LOAN_ID
    where substring(L.LEAD_GUID, 16, 1) in ('4', '5', '6', '7')

    union

    -- 2. OTP - One Time Payments (CLS legacy)
    select PAYOFF_UID as PAYOFFUID, 'OTP' as SUPPRESSION_REASON
    from DATA_STORE.VW_ONE_TIME_PAYMENT_REQUESTS
    where EFFECTIVE_DATE >= current_date
      and STATUS <> 'deleted'

    union

    select PAYOFF_UID as PAYOFFUID, 'OTP' as SUPPRESSION_REASON
    from DATA_STORE.VW_MANUAL_BILL_PAYMENT_REQUESTS
    where SELECTED_DATE >= current_date
      and STATUS <> 'deleted'

    union

    -- 3. Loan Modification (CLS legacy)
    select LT.PAYOFFUID, 'Loan Mod' as SUPPRESSION_REASON
    from DATA_STORE.VW_SURVEYMONKEY_RESPONSES as LM
    inner join DATA_STORE.MVW_LOAN_TAPE as LT
        on LM.PAYOFFUID = LT.PAYOFFUID
    where LM.SURVEY_LAST_UPDATED_DATETIME_PST >= dateadd(day, -3, current_date)
      and LM.SURVEY_NAME = 'Loan Modification Request Survey'
      and LM.RESPONSE_STATUS = 'completed'
      and substring(LT.PAYOFFUID, 16, 1) in ('4', '5', '6', '7')

    union

    -- 4. Natural Disaster
    select LT.PAYOFFUID, 'Natural Disaster' as SUPPRESSION_REASON
    from DATA_STORE.MVW_LOAN_TAPE as LT
    inner join ANALYTICS.VW_LOAN as L
        on LT.PAYOFFUID = L.LEAD_GUID
    inner join ANALYTICS_PII.VW_MEMBER_PII as CI
        on L.MEMBER_ID = CI.MEMBER_ID
        and CI.MEMBER_PII_END_DATE is null
    where CI.ZIP_CODE in (
        select ZIP
        from CRON_STORE.LKP_GR_ND_SUPPRESSION
        where SUPPRESSEDDATE <= current_date
          and EXPIREDDATE >= current_date
    )

    union

    -- 5. Individual Suppression
    select PAYOFFUID, 'Individual Suppression' as SUPPRESSION_REASON
    from CRON_STORE.LKP_GR_INDIVIDUAL_SUPPRESSION
    where SUPPRESSEDDATE <= current_date
      and EXPIREDDATE >= current_date

    union

    -- 6. Next Workable Date
    select L.LEAD_GUID as PAYOFFUID, 'Next Workable Date After Today' as SUPPRESSION_REASON
    from ANALYTICS.VW_LOAN as L
    inner join BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT as CUS
        on L.LOAN_ID = CUS.LOAN_ID::string
    where CUS.NEXT_WORKABLE_DATE > current_date
      and substring(L.LEAD_GUID, 16, 1) in ('4', '5', '6', '7')

    union

    -- 7. 3rd Party Post Charge Off Placement (CLS legacy)
    select lower(VLA.LEAD_GUID) as PAYOFFUID, '3rd Party Post Charge Off Placement' as SUPPRESSION_REASON
    from BUSINESS_INTELLIGENCE.DATA_STORE.VW_LOAN_ACCOUNT VLA
    inner join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE MLT
        on MLT.PAYOFFUID = lower(VLA.LEAD_GUID)
    where VLA.PLACEMENT_STATUS in (
        'Placed - ARS', 'Placed - First Tech Credit Union', 'Placed - Remitter (Post-CO)',
        'Placed - TrueAccord', 'Placed - Resurgent'
    )
      and MLT.STATUS = 'Charge off'

    union

    -- 8. 3rd Party Post Charge Off Placement (LoanPro)
    select LT.PAYOFFUID, '3rd Party Post Charge Off Placement' as SUPPRESSION_REASON
    from DATA_STORE.MVW_LOAN_TAPE as LT
    inner join ANALYTICS.VW_LOAN as L
        on LT.PAYOFFUID = L.LEAD_GUID
    inner join BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT as CUS
        on L.LOAN_ID = CUS.LOAN_ID::string
    where CUS.PLACEMENT_STATUS in (
        'ARS', 'First Tech Credit Union', 'Remitter', 'Bounce',
        'Resurgent', 'Jefferson Capital', 'Certain Capital Partners'
    )
      and LT.STATUS = 'Charge off'
)

select
    L.LOAN_ID                                                            as ACCOUNT_NUMBER,
    OL.PAYOFFUID                                                         as PAYOFFUID,
    LT.LOANID                                                            as PAYOFF_LOAN_ID,
    PII.FIRST_NAME                                                       as PRIMARY_FIRST_NAME,
    null                                                                 as PRIMARY_MIDDLE_NAME,
    PII.LAST_NAME                                                        as PRIMARY_LAST_NAME,
    null                                                                 as COBORROWER_FIRST_NAME,
    null                                                                 as COBORROWER_MIDDLE_NAME,
    null                                                                 as COBORROWER_LAST_NAME,
    PII.PHONE_NUMBER                                                     as PRIMARY_WORK_PHONE,
    PII.PHONE_NUMBER                                                     as PRIMARY_HOME_PHONE,
    PII.PHONE_NUMBER                                                     as PRIMARY_CELL_PHONE,
    PII.EMAIL                                                            as PRIMARY_EMAIL,
    null                                                                 as COBORROWER_WORK_PHONE,
    null                                                                 as COBORROWER_HOME_PHONE,
    null                                                                 as COBORROWER_CELL_PHONE,
    null                                                                 as COBORROWER_EMAIL,
    LT.REMAININGPRINCIPAL + LT.ACCRUEDINTEREST                           as CURRENT_BALANCE,
    SA.AMOUNT_DUE                                                        as AMOUNT_DELINQUENT,
    LT.DAYSPASTDUE                                                       as DAYS_DELINQUENT,
    LT.LASTPAYMENTDATE                                                   as DATE_LAST_PAYMENT,
    LT.LASTPAYMENTAMOUNT                                                 as AMOUNT_LAST_PAYMENT,
    PII.ADDRESS_1                                                        as ADDRESS1,
    PII.ADDRESS_2                                                        as ADDRESS2,
    PII.CITY                                                             as CITY,
    PII.STATE                                                            as STATE,
    PII.ZIP_CODE                                                         as ZIP_CODE,
    PII.SSN                                                              as PRI_SSN,
    null                                                                 as COB_SSN,
    LT.ORIGINATIONDATE                                                   as OPEN_DATE,
    try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"1":"amount-due"::float as DEL_1_CYCLE_AMT,
    try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"2":"amount-due"::float as DEL_2_CYCLE_AMT,
    try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"3":"amount-due"::float as DEL_3_CYCLE_AMT,
    try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"4":"amount-due"::float as DEL_4_CYCLE_AMT,
    try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"5":"amount-due"::float as DEL_5_CYCLE_AMT,
    try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"6":"amount-due"::float as DEL_6_CYCLE_AMT,

    -- Suppression Flags
    case
        when GS.PAYOFFUID is not null or LCR.CEASE_AND_DESIST = true
        then true
        else false
    end as SUPPRESS_GLOBAL,

    case
        when LCR.SUPPRESS_PHONE = true
        then true
        else false
    end as SUPPRESS_PHONE,

    case
        when LCR.SUPPRESS_EMAIL = true
        then true
        else false
    end as SUPPRESS_EMAIL,

    case
        when LCR.SUPPRESS_TEXT = true
        then true
        else false
    end as SUPPRESS_TEXT,

    -- Summary suppression reasons (for reference)
    case
        when LCR.CEASE_AND_DESIST = true then 'Cease & Desist'
        when GS.SUPPRESSION_REASON is not null then GS.SUPPRESSION_REASON
        else null
    end as GLOBAL_SUPPRESSION_REASON

from BOUNCE_OUTBOUND as OL
inner join DATA_STORE.MVW_LOAN_TAPE as LT
    on OL.PAYOFFUID = LT.PAYOFFUID
inner join ANALYTICS.VW_LOAN as L
    on OL.PAYOFFUID = L.LEAD_GUID
inner join ANALYTICS_PII.VW_MEMBER_PII as PII
    on L.MEMBER_ID = PII.MEMBER_ID
    and PII.MEMBER_PII_END_DATE is null
inner join BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT as SA
    on L.LOAN_ID = SA.LOAN_ID::string
    and SA.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
    and SA.DATE = current_date
left join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
    on L.LOAN_ID = LCR.LOAN_ID
    and LCR.CONTACT_RULE_END_DATE is null
left join GLOBAL_SUPPRESSIONS as GS
    on OL.PAYOFFUID = GS.PAYOFFUID;