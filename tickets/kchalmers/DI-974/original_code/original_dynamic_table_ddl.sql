	PREVIOUS_MONTH_STATUS,
	PREVIOUS_MONTH_DPD,
	CURRENT_DPD,
	PREVIOUS_MONTH_DPD_STATUS,
	CURRENT_DPD_STATUS,
	ROLL_STATUS,
	LOAN_TIER,
	CORE_LPE_FLAG,
	LESS_THAN_18_APR_FLAG,
	REMAINING_PRINCIPAL,
	ORIGINATIONDATE,
	PORTFOLIOID,
	PORTFOLIO_NAME,
	TERM,
	BUREAUFICOSCORE,
	LAST_TOUCH_UTM_CHANNEL_GROUPING
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = BUSINESS_INTELLIGENCE
 as
-- TODO: one the duplicates in daily loan tape is fixed, remove this select distinct
WITH monthly_loan_tape as (SELECT A.LOANID,
                                  A.ASOFDATE,
                                  COALESCE(B.DAYS_PAST_DUE, A.DAYSPASTDUE)            AS DAYSPASTDUE,
                                  COALESCE(B.STATUS, A.STATUS)                        AS STATUS,
                                  COALESCE(B.NEXT_PAYMENT_DATE, A.NEXTPAYMENTDUEDATE) AS NEXTPAYMENTDUEDATE,
                                  A.APR,
                                  A.LOAN_INTENT,
                                  A.PAYOFFUID
                           FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY A
                                    LEFT JOIN BUSINESS_INTELLIGENCE.CRON_STORE.TEMP_DI_652 B
                                              ON A.LOANID = B.LOANID AND DATE(A.ASOFDATE) = DATE(B.AS_OF_DATE))
,daily_loan_tape as (SELECT A.LOANID,
                                  A.ASOFDATE,
                                  COALESCE(B.DAYS_PAST_DUE, A.DAYSPASTDUE)            AS DAYSPASTDUE,
                                  COALESCE(B.STATUS, A.STATUS)                        AS STATUS,
                                  COALESCE(B.NEXT_PAYMENT_DATE, A.NEXTPAYMENTDUEDATE) AS NEXTPAYMENTDUEDATE,
                                  A.APR,
                                  A.LOAN_INTENT,
                                  A.PAYOFFUID,
                                  A.LOANTIER,
                                  A.PRINCIPALBALANCEATCHARGEOFF,
                                  A.REMAININGPRINCIPAL,
                                  A.ORIGINATIONDATE,
                                  A.PORTFOLIOID,
                                  A.TERM,
                                  A.BUREAUFICOSCORE,
                                  PORTFOLIONAME
                           FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY A
                                    LEFT JOIN BUSINESS_INTELLIGENCE.CRON_STORE.TEMP_DI_652 B
                                              ON A.LOANID = B.LOANID AND DATE(A.ASOFDATE) = DATE(B.AS_OF_DATE))
select distinct *
from (
    select
        dlt.PAYOFFUID,
        dlt.ASOFDATE,
        mlt.ASOFDATE as previous_monthend_date,
        dlt.STATUS as current_status,
        -- If null on monthly loan tape, then it's a newly originated loan from current month
        mlt.STATUS as previous_month_status,
        mlt.DAYSPASTDUE as previous_month_dpd,
        dlt.DAYSPASTDUE as current_dpd,
        /*
         Encode DPD status
         We add the numbering ""1.   "" etc.
         so that we can calculate roll status later
         by comparing string values
         */
        case
            when mlt.STATUS = 'Paid in Full' then '0.   paid in full'
            when mlt.STATUS = 'Charge off' or mlt.STATUS = 'Sold Charge Off' then '6.   charge off'
            when mlt.DAYSPASTDUE <= 2 then '1.   not delinquent'
            when mlt.DAYSPASTDUE between 3 and 29 then '2.   3 - 29 DPD'
            when mlt.DAYSPASTDUE between 30 and 59 then '3.   30 - 59 DPD'
            when mlt.DAYSPASTDUE between 60 and 89 then '4.   60 - 89 DPD'
            when mlt.DAYSPASTDUE >= 90 then '5.   90+ DPD'
            else mlt.STATUS
        end as previous_month_dpd_status,
            case
            when dlt.STATUS = 'Paid in Full' then '0.   paid in full'
            when dlt.STATUS = 'Charge off' or dlt.STATUS = 'Sold Charge Off' then '6.   charge off'
            when dlt.DAYSPASTDUE <= 2 then '1.   not delinquent'
            when dlt.DAYSPASTDUE between 3 and 29 then '2.   3 - 29 DPD'
            when dlt.DAYSPASTDUE between 30 and 59 then '3.   30 - 59 DPD'
            when dlt.DAYSPASTDUE between 60 and 89 then '4.   60 - 89 DPD'
            when dlt.DAYSPASTDUE >= 90 then '5.   90+ DPD'
            else dlt.STATUS
        end as current_dpd_status,
        case
            when current_dpd_status = previous_month_dpd_status then 'no change'
            when current_dpd_status = '0.   paid in full' then 'paid in full'
            when current_dpd_status < previous_month_dpd_status then 'roll better'
            when current_dpd_status > previous_month_dpd_status then 'roll worse'
        end
            as roll_status,
        -- Because Theorem has a separate underwriting model, TH loans sometimes have null loan tier value
        coalesce(dlt.LOANTIER, 'TH') as loan_tier,
        iff(mlt.LOAN_INTENT <> 'core', 'LPE', mlt.LOAN_INTENT) as core_lpe_flag,
        mlt.APR < 18 as less_than_18_apr_flag,
        case
            when current_dpd_status = '6.   charge off' then dlt.PRINCIPALBALANCEATCHARGEOFF
    --         when current_dpd_status = 'Paid in Full' then dlt.PRINCIPALPAIDTODATE
            else dlt.REMAININGPRINCIPAL
        end as remaining_principal,
    --     dlt.PAYMENTANNIVERSARYDATE = day(dlt.ASOFDATE) as payment_anniversary_flag, -- what is this?
        dlt.ORIGINATIONDATE,
        dlt.PORTFOLIOID,
        to_varchar(dlt.PORTFOLIOID::int) || ' - ' ||
            last_value(dlt.PORTFOLIONAME) over (partition by dlt.PORTFOLIOID order by dlt.ASOFDATE)
        as portfolio_name,
        dlt.TERM,
        dlt.BUREAUFICOSCORE,
        ast.LAST_TOUCH_UTM_CHANNEL_GROUPING
    --TODO: REPLACE WITH NORMAL DAILY LOAN TAPE
    from daily_loan_tape dlt
    -- inner join because only loans that are over a month old hs relevant to roll rate calculation
    --TODO: REPLACE WITH NORMAL MONTHLY LOAN TAPE
    inner join monthly_loan_tape mlt
        on dlt.PAYOFFUID = mlt.PAYOFFUID
        -- Take only the most recent monthly record (previous month from current date)
        and dateadd(month,-1,date_trunc(month,dlt.ASOFDATE)) = date_trunc(month,mlt.ASOFDATE)
    left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_APPL_STATUS_TRANSITION ast
        on dlt.PAYOFFUID = ast.PAYOFFUID
    -- According to Kyle Christensen and Cale, we won't look at pre-2018 data
    where dlt.ASOFDATE >= to_date('2018-01-01'));
