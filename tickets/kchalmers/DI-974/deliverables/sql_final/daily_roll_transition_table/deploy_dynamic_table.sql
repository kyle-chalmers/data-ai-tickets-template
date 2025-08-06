-- DI-974: CORRECTED OPTIMIZED ALTER DSH_GR_DAILY_ROLL_TRANSITION Dynamic Table
-- Safe performance optimizations that maintain identical results

-- DI-974: OPTIMIZED Dynamic Table Modification - No ALTER statements needed
-- Dynamic tables use CREATE OR REPLACE which automatically handles new columns
CREATE OR REPLACE DYNAMIC TABLE BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION(
	PAYOFFUID,
	ASOFDATE,
	PREVIOUS_MONTHEND_DATE,
	CURRENT_STATUS,
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
	LAST_TOUCH_UTM_CHANNEL_GROUPING,
	CURRENT_SIMM_PLACEMENT_FLAG,
	HISTORICAL_SIMM_PLACEMENT_FLAG,
	FIRST_SIMM_DATE
) target_lag = '1 day' refresh_mode = AUTO initialize = ON_CREATE warehouse = BUSINESS_INTELLIGENCE
AS
-- OPTIMIZATION 1: Create shared corrected data CTEs to eliminate duplicate COALESCE logic
WITH monthly_loan_tape_corrected as (
    SELECT A.LOANID,
           A.ASOFDATE,
           COALESCE(B.DAYS_PAST_DUE, A.DAYSPASTDUE) AS DAYSPASTDUE,
           COALESCE(B.STATUS, A.STATUS) AS STATUS,
           COALESCE(B.NEXT_PAYMENT_DATE, A.NEXTPAYMENTDUEDATE) AS NEXTPAYMENTDUEDATE,
           A.APR,
           A.LOAN_INTENT,
           A.PAYOFFUID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_MONTHLY A
    LEFT JOIN BUSINESS_INTELLIGENCE.CRON_STORE.TEMP_DI_652 B
        ON A.LOANID = B.LOANID AND DATE(A.ASOFDATE) = DATE(B.AS_OF_DATE)
),
daily_loan_tape_corrected as (
    SELECT A.LOANID,
           A.ASOFDATE,
           COALESCE(B.DAYS_PAST_DUE, A.DAYSPASTDUE) AS DAYSPASTDUE,
           COALESCE(B.STATUS, A.STATUS) AS STATUS,
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
        ON A.LOANID = B.LOANID AND DATE(A.ASOFDATE) = DATE(B.AS_OF_DATE)
),
-- OPTIMIZATION 2: Pre-calculate SIMM historical data once
simm_placements AS (
    SELECT 
        PAYOFFUID,
        MIN(LOAN_TAPE_ASOFDATE) as FIRST_SIMM_DATE
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST
    WHERE SET_NAME = 'SIMM'
        AND SUPPRESSION_FLAG = FALSE
    GROUP BY PAYOFFUID
)
-- OPTIMIZATION 3: Remove outer DISTINCT - should be addressed at data quality level
select 
    dlt.PAYOFFUID,
    dlt.ASOFDATE,
    mlt.ASOFDATE as previous_monthend_date,
    dlt.STATUS as current_status,
    mlt.STATUS as previous_month_status,
    mlt.DAYSPASTDUE as previous_month_dpd,
    dlt.DAYSPASTDUE as current_dpd,
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
    end as roll_status,
    coalesce(dlt.LOANTIER, 'TH') as loan_tier,
    iff(mlt.LOAN_INTENT <> 'core', 'LPE', mlt.LOAN_INTENT) as core_lpe_flag,
    mlt.APR < 18 as less_than_18_apr_flag,
    case
        when current_dpd_status = '6.   charge off' then dlt.PRINCIPALBALANCEATCHARGEOFF
        else dlt.REMAININGPRINCIPAL
    end as remaining_principal,
    dlt.ORIGINATIONDATE,
    dlt.PORTFOLIOID,
    to_varchar(dlt.PORTFOLIOID::int) || ' - ' ||
        last_value(dlt.PORTFOLIONAME) over (partition by dlt.PORTFOLIOID order by dlt.ASOFDATE) as portfolio_name,
    dlt.TERM,
    dlt.BUREAUFICOSCORE,
    ast.LAST_TOUCH_UTM_CHANNEL_GROUPING,
    
    -- Current SIMM placement flag - exact date match for daily activity
    CASE 
        WHEN simm_current.PAYOFFUID IS NOT NULL 
        THEN 1 
        ELSE 0 
    END AS CURRENT_SIMM_PLACEMENT_FLAG,
    
    -- Historical SIMM placement flag - ever been placed with SIMM
    CASE 
        WHEN simm_historical.PAYOFFUID IS NOT NULL 
            AND dlt.ASOFDATE >= simm_historical.FIRST_SIMM_DATE 
        THEN 1 
        ELSE 0 
    END AS HISTORICAL_SIMM_PLACEMENT_FLAG,
    
    -- First SIMM placement date for reference
    simm_historical.FIRST_SIMM_DATE
    
from daily_loan_tape_corrected dlt
inner join monthly_loan_tape_corrected mlt
    on dlt.PAYOFFUID = mlt.PAYOFFUID
    and dateadd(month,-1,date_trunc(month,dlt.ASOFDATE)) = date_trunc(month,mlt.ASOFDATE)
left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_APPL_STATUS_TRANSITION ast
    on dlt.PAYOFFUID = ast.PAYOFFUID
-- OPTIMIZATION 4: Keep original two-join approach but use optimized CTEs
left join BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST simm_current
    on simm_current.SET_NAME = 'SIMM' 
    and simm_current.SUPPRESSION_FLAG = FALSE
    and simm_current.PAYOFFUID = dlt.PAYOFFUID
    and simm_current.LOAN_TAPE_ASOFDATE = dlt.ASOFDATE
left join simm_placements simm_historical on dlt.PAYOFFUID = simm_historical.PAYOFFUID
where dlt.ASOFDATE >= to_date('2018-01-01');