CREATE OR REPLACE PROCEDURE BUSINESS_INTELLIGENCE.REPORTING.APP_DAILY_EXEC_REPORTING()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN

create or replace table business_intelligence.reporting.production_by_cal_day_summ copy grants as 
select
calendar_date
,last_day(calendar_date) as calendar_month
,decode(extract(dayofweek from calendar_date),1,''Mon'',2,''Tue'',3,''Wed'',4,''Thu'',5,''Fri'',6,''Sat'',0,''Sun'') as day_of_week
,extract(day from calendar_date) as day_num
,case when calendar_date <= current_date - 1 then ''Current Date'' else ''NA'' end as current_date_filter
,case when day_num <= extract(day from current_date - 1) then ''MTD'' else ''NA'' end as mtd_filter
,case when calendar_month > last_day((current_date - 1) - interval ''3 months'') then ''Last 3 Months'' else ''NA'' end as recent_mo_filter
,extract(week from calendar_date) as week_num
,y.week_begin_dt
,extract(month from calendar_date) as month_num
,monthname(calendar_date)::char(3) as month_name
,extract(year from calendar_date) as year_num
,z.business_day_of_month_num as business_day_num
,z.business_mo_num
,z.business_yr_num
,funnel_type
,case   when funnel_type = ''Non-API'' and ifnull(app_channel_parent,''Null'') in (''Unattributed'',''Null'') then ''Non-API Unattributed''
        when funnel_type = ''Non-API'' then ''Non-API Attributed''
        else funnel_type end::varchar(55) as funnel_type_non_api_unattr
,case   when funnel_type = ''Non-API'' and ifnull(app_channel_parent,''Null'') in (''Unattributed'',''Null'') then ''Non-API Unattributed''
        when funnel_type = ''Non-API'' and app_channel_parent in (''CK Lightbox'',''Affiliates'') then ''Non-API Affiliate''
        when funnel_type = ''Non-API'' and app_channel_parent in (''Direct Mail'',''Email'') then ''Non-API DM/Email''      
        when funnel_type = ''Non-API'' then ''Non-API Search/Social/Organic''       
        else funnel_type end::varchar(55) as funnel_type_non_api_segments       
,tier
,case when tier in (1,2,3) then ''1-3'' when tier in (4,5,6) then ''4-6'' else ''7+'' end::varchar(10) as tier_grp 
,automation_income_check_status
,automation_identity_check_status
,automation_bank_account_check_status
,dynamic_verif_pass_yn as direct_verif_pass_yn
,utm_source
,utm_medium
,app_channel 
,app_channel_parent 
,source_company
,term
,loan_amt_rng
,sum(app_cnt) as app_cnt
,sum(api_soft_approved_cnt) as api_soft_approved_cnt
,sum(api_soft_counter_cnt) as api_soft_counter_cnt
,sum(api_soft_declined_cnt) as api_soft_declined_cnt
,sum(auto_fraud_decline_cnt) as auto_fraud_decline_cnt 
,sum(applied_cnt) as applied_cnt
,sum(aff_landed_cnt) as aff_landed_cnt
,sum(requested_loan_amt) as requested_loan_amt
,sum(case when funnel_type = ''API'' then aff_landed_cnt else applied_cnt end) as offer_shown_prct_denom
,sum(offer_shown_cnt) as offer_shown_cnt
,sum(max_offer_amt) as max_offer_amt
,sum(offer_selected_cnt) as offer_selected_cnt
,sum(case when dynamic_verif_pass_yn = ''Y'' then offer_selected_cnt else 0 end) as offer_selected_cnt_dir_ver
,sum(selected_offer_amt) as selected_offer_amt
,sum(uw_complete_by_app_dt) as uw_complete_by_app_dt
,sum(esign_cnt_by_app_dt) as esign_cnt_by_app_dt
,sum(esign_cnt) as esign_cnt
,sum(case when automation_income_check_status is not null then app_cnt 
            when automation_identity_check_status is not null then app_cnt
            when automation_bank_account_check_status is not null then app_cnt
            else 0 end) as apps_with_automation_cnt
,sum(loan_amt) as loan_amt
,sum(case when source_company = ''Cross River Bank Fortress'' then esign_cnt else 0 end) as esign_cnt_IC
,sum(case when source_company like ''%FCU%'' then esign_cnt else 0 end) as esign_cnt_CU
,sum(case when dynamic_verif_pass_yn = ''Y'' then esign_cnt else 0 end) as esign_cnt_dir_ver
,sum(case when source_company = ''Cross River Bank Fortress'' then loan_amt else 0 end) as loan_amt_IC
,sum(case when source_company like ''%FCU%'' then loan_amt else 0 end) as loan_amt_CU
,sum(case when dynamic_verif_pass_yn = ''Y'' then loan_amt else 0 end) as loan_amt_dir_ver
,sum(fee_amt) as fee_amt
,sum(case when source_company = ''Cross River Bank Fortress'' then fee_amt else 0 end) as fee_amt_IC
,sum(case when source_company like ''%FCU%'' then fee_amt else 0 end) as fee_amt_CU
,sum(case when dynamic_verif_pass_yn = ''Y'' then fee_amt else 0 end)  as fee_amt_dir_ver
,segment
,current_timestamp as data_as_of
from 
        (select 
        app_dt as calendar_date
        ,funnel_type
        ,tier
        ,automation_income_check_status
        ,automation_identity_check_status
        ,automation_bank_account_check_status
        ,dynamic_verif_pass_yn
        ,utm_source
        ,utm_medium
        ,app_channel 
        ,app_channel_parent 
        ,source_company
        ,0 as term
        ,'''' as loan_amt_rng
        ,count(*) as app_cnt
        ,sum(case when funnel_type = ''API'' and api_partner_decision = ''Conditional Approval'' then 1 else 0 end) as api_soft_approved_cnt
        ,sum(case when funnel_type = ''API'' and api_partner_decision = ''Counteroffer'' then 1 else 0 end) as api_soft_counter_cnt
        ,sum(case when funnel_type = ''API'' and api_partner_decision like ''Decline%'' then 1
                  when funnel_type = ''API'' and api_partner_decision like ''Pending%'' then 1 else 0 end) as api_soft_declined_cnt
        ,sum(case when funnel_type = ''API'' and affiliate_landed_ts is not null then 1 else 0 end) as aff_landed_cnt
        ,sum(case when automated_fraud_decline_yn = ''Y'' then 1 else 0 end) as auto_fraud_decline_cnt
        ,sum(case when applied_ts is not null then 1 else 0 end) as applied_cnt
--        ,sum(case when funnel_type = ''API'' and last_day(app_dt) = last_day(affiliate_landed_ts) and extract(day from affiliate_landed_ts) <= extract(day from current_date - 1) then 1 else 0 end) as aff_landed_cnt
--        ,sum(case when last_day(app_dt) = last_day(applied_ts) and extract(day from applied_ts) <= extract(day from current_date - 1) then 1 else 0 end) as applied_cnt
        ,sum(requested_loan_amt) as requested_loan_amt
--        ,sum(case when last_day(app_dt) = last_day(offer_shown_ts) and extract(day from offer_shown_ts) <= extract(day from current_date - 1) then 1 else 0 end) as offer_shown_cnt        
--        ,sum(case when last_day(app_dt) = last_day(offer_shown_ts) and extract(day from offer_shown_ts) <= extract(day from current_date - 1) then max_offer_amt else 0 end) as max_offer_amt  
        ,0 as offer_shown_cnt
        ,0 as max_offer_amt
        ,0 as offer_selected_cnt
        ,0 as selected_offer_amt
        ,sum(case when uw_complete_ts is not null then 1 else 0 end) as uw_complete_by_app_dt
        ,sum(case when esign_ts is not null then 1 else 0 end) as esign_cnt_by_app_dt
        ,0 as esign_cnt
        ,0 as loan_amt
        ,0 as fee_amt
        ,''MTD'' as segment
        from business_intelligence.analytics.vw_app_loan_production 
        where guid_dupe_yn = ''N''
            --and extract(day from app_dt) <= extract(day from current_date - 1)      
        group by all
        
        union all
        
        select 
        offer_shown_ts::date as calendar_date
        ,funnel_type
        ,tier
        ,automation_income_check_status
        ,automation_identity_check_status
        ,automation_bank_account_check_status
        ,dynamic_verif_pass_yn
        ,utm_source
        ,utm_medium
        ,app_channel 
        ,app_channel_parent 
        ,source_company
        ,0 as term
        ,'''' as loan_amt_rng
        ,0 as app_cnt
        ,0 as api_soft_approved_cnt
        ,0 as api_soft_counter_cnt
        ,0 as api_soft_declined_cnt
        ,0 as aff_landed_cnt
        ,0 as auto_fraud_decline_cnt
        ,0 as applied_cnt
        ,0 as requested_loan_amt
        ,sum(case when offer_shown_ts::date <= current_date - 1 then 1 else 0 end) as offer_shown_cnt
        ,sum(max_offer_amt) as max_offer_amt
        ,0 as offer_selected_cnt
        ,0 as selected_offer_amt
        ,0 as uw_complete_by_app_dt
        ,0 as esign_cnt_by_app_dt
        ,0 as esign_cnt
        ,0 as loan_amt
        ,0 as fee_amt
        ,''MTD'' as segment
        from business_intelligence.analytics.vw_app_loan_production 
        where guid_dupe_yn = ''N''
        and offer_shown_ts is not null
        group by all
        
        union all
        
        select 
        offer_selected_ts::date as calendar_date
        ,funnel_type
        ,tier
        ,automation_income_check_status
        ,automation_identity_check_status
        ,automation_bank_account_check_status
        ,dynamic_verif_pass_yn
        ,utm_source
        ,utm_medium
        ,app_channel 
        ,app_channel_parent 
        ,source_company
        ,0 as term
        ,'''' as loan_amt_rng
        ,0 as app_cnt
        ,0 as api_soft_approved_cnt
        ,0 as api_soft_counter_cnt
        ,0 as api_soft_declined_cnt
        ,0 as aff_landed_cnt
        ,0 as auto_fraud_decline_cnt 
        ,0 as applied_cnt
        ,0 as requested_loan_amt
        ,0 as offer_shown_cnt
        ,0 as max_offer_amt
        ,count(*) as offer_selected_cnt
        ,sum(selected_offer_amt) as selected_offer_amt
        ,0 as uw_complete_by_app_dt
        ,0 as esign_cnt_by_app_dt
        ,0 as esign_cnt
        ,0 as loan_amt
        ,0 as fee_amt
        ,''MTD'' as segment
        from business_intelligence.analytics.vw_app_loan_production 
        where guid_dupe_yn = ''N''
            and offer_selected_ts is not null
            --and extract(day from offer_selected_ts) <= extract(day from current_date - 1)   
        group by all
        
        union all
        
        select 
        esign_ts::date as calendar_date
        ,funnel_type
        ,tier
        ,automation_income_check_status
        ,automation_identity_check_status
        ,automation_bank_account_check_status
        ,dynamic_verif_pass_yn
        ,utm_source
        ,utm_medium
        ,app_channel 
        ,app_channel_parent 
        ,source_company
        ,term
        ,case   when loan_amt < 5000 then ''a.0-4999''
                when loan_amt < 15000 then ''b.5000-14999''
                when loan_amt < 25000 then ''c.15000-24999''
                when loan_amt < 35000 then ''d.25000-34999''
                else ''e.35000+'' end as loan_amt_rng
        ,0 as app_cnt
        ,0 as api_soft_approved_cnt
        ,0 as api_soft_counter_cnt
        ,0 as api_soft_declined_cnt
        ,0 as aff_landed_cnt
        ,0 as auto_fraud_decline_cnt 
        ,0 as applied_cnt
        ,0 as requested_loan_amt
        ,0 as offer_shown_cnt
        ,0 as max_offer_amt
        ,0 as offer_selected_cnt
        ,0 as selected_offer_amt
        ,0 as uw_complete_by_app_dt
        ,0 as esign_cnt_by_app_dt
        ,count(*) as esign_cnt
        ,sum(loan_amt) as loan_amt
        ,sum(orig_fee_amt + prem_fee_amt) as fee_amt 
        ,''MTD'' as segment
        from business_intelligence.analytics.vw_app_loan_production 
        where guid_dupe_yn = ''N''
            and esign_ts is not null
            --and extract(day from esign_ts) <= extract(day from current_date - 1)   
        group by all
        ) x
       
left join 
        (select
        extract(year from calendar_date) as year_num
        ,extract(week from calendar_date) as week_num
        ,min(calendar_date) as week_begin_dt
        from 
                (select
                dateadd(day, row_number() over (order by seq4()) - 1, dateadd(year, -3, current_date)) as calendar_date
                --,extract(week from dateadd(day, row_number() over (order by seq4()) - 1, dateadd(year, -3, current_date))) as week_num
                from table(GENERATOR(ROWCOUNT => 1096))
                ) a
        where calendar_date >= ''2025-01-01''
        group by all
        ) y
on extract(week from calendar_date) = y.week_num

left join business_intelligence.analytics.vw_allocation_business_months z
on x.calendar_date = z.date

group by all
;

create or replace table business_intelligence.reporting.days_between_funnel_starts copy grants as 
select
app_mo
,app_wk
,week_begin_dt
,funnel_type
,tier
,utm_source
,dynamic_verif_pass_yn
,days_between
,case when days_between is null then null
        when days_between < 0 then 0
        when (current_date - 1) - (week_begin_dt + 6) >= 45 then days_between
        when days_between > (current_date - 1) - (week_begin_dt + 6) then null
        else days_between end as valid_days_between
,sum(lead_start_to_landed) as lead_start_to_landed
,sum(lead_start_to_applied) as lead_start_to_applied
,sum(applied_to_offer_shown) as applied_to_offer_shown
,sum(offer_shown_to_offer_selected) as offer_shown_to_offer_selected
,sum(offer_selected_to_esigned) as offer_selected_to_esigned
,sum(lead_start_to_esigned) as lead_start_to_esigned
from 
        (select
        last_day(app_dt) as app_mo
        ,extract(week from app_dt) as app_wk
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,case when affiliate_landed_ts::date - app_ts::date >= 45 then 45 else affiliate_landed_ts::date - app_ts::date end as days_between
        ,count(*) as lead_start_to_landed
        ,0 as lead_start_to_applied
        ,0 as applied_to_offer_shown
        ,0 as offer_shown_to_offer_selected
        ,0 as offer_selected_to_esigned
        ,0 as lead_start_to_esigned
        from business_intelligence.analytics.vw_app_loan_production
        where app_dt >= ''2025-01-01''
        and (api_partner_decision not like ''Decline%'' or api_partner_decision not like ''Pending%'' or funnel_type = ''Non-API'')
        group by all

        union all
        
        select
        last_day(app_dt) as app_mo
        ,extract(week from app_dt) as app_wk
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,case when applied_ts::date - app_ts::date >= 45 then 45 else applied_ts::date - app_ts::date end as days_between
        ,0 as lead_start_to_landed
        ,count(*) as lead_start_to_applied
        ,0 as applied_to_offer_shown
        ,0 as offer_shown_to_offer_selected
        ,0 as offer_selected_to_esigned
        ,0 as lead_start_to_esigned
        from business_intelligence.analytics.vw_app_loan_production
        where app_dt >= ''2025-01-01''
        and (api_partner_decision not like ''Decline%'' or api_partner_decision not like ''Pending%'' or funnel_type = ''Non-API'')
        group by all
        
        union all
        
        select
        last_day(app_dt) as app_mo
        ,extract(week from app_dt) as app_wk
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,case when offer_shown_ts::date - applied_ts::date >= 45 then 45 else offer_shown_ts::date - applied_ts::date end as days_between
        ,0 as lead_start_to_landed
        ,0 as lead_start_to_applied
        ,count(*) as applied_to_offer_shown
        ,0 as offer_shown_to_offer_selected
        ,0 as offer_selected_to_esigned
        ,0 as lead_start_to_esigned
        from business_intelligence.analytics.vw_app_loan_production
        where app_dt >= ''2025-01-01''
        and (api_partner_decision not like ''Decline%'' or api_partner_decision not like ''Pending%'' or funnel_type = ''Non-API'')
        group by all
        
        union all
        
        select
        last_day(app_dt) as app_mo
        ,extract(week from app_dt) as app_wk
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,case when offer_selected_ts::date - offer_shown_ts::date >= 45 then 45 else offer_selected_ts::date - offer_shown_ts::date end as days_between
        ,0 as lead_start_to_landed
        ,0 as lead_start_to_applied
        ,0 as applied_to_offer_shown
        ,count(*) as offer_shown_to_offer_selected
        ,0 as offer_selected_to_esigned
        ,0 as lead_start_to_esigned
        from business_intelligence.analytics.vw_app_loan_production
        where app_dt >= ''2025-01-01''
        and (api_partner_decision not like ''Decline%'' or api_partner_decision not like ''Pending%'' or funnel_type = ''Non-API'')
        group by all
        
        union all
        
        select
        last_day(app_dt) as app_mo
        ,extract(week from app_dt) as app_wk
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,case when esign_ts::date - offer_selected_ts::date >= 45 then 45 else esign_ts::date - offer_selected_ts::date end as days_between
        ,0 as lead_start_to_landed
        ,0 as lead_start_to_applied
        ,0 as applied_to_offer_shown
        ,0 as offer_shown_to_offer_selected
        ,count(*) as offer_selected_to_esigned
        ,0 as lead_start_to_esigned
        from business_intelligence.analytics.vw_app_loan_production
        where app_dt >= ''2025-01-01''
        and (api_partner_decision not like ''Decline%'' or api_partner_decision not like ''Pending%'' or funnel_type = ''Non-API'')
        group by all
                
        union all
        
        select
        last_day(app_dt) as app_mo
        ,extract(week from app_dt) as app_wk
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,case when esign_ts::date - app_ts::date >= 45 then 45 else esign_ts::date - app_ts::date end as days_between
        ,0 as lead_start_to_landed
        ,0 as lead_start_to_applied
        ,0 as applied_to_offer_shown
        ,0 as offer_shown_to_offer_selected
        ,0 as offer_selected_to_esigned
        ,count(*) as lead_start_to_esigned
        from business_intelligence.analytics.vw_app_loan_production
        where app_dt >= ''2025-01-01''
        and (api_partner_decision not like ''Decline%'' or api_partner_decision not like ''Pending%'' or funnel_type = ''Non-API'')
        group by all
        ) x
left join 
        (select
        extract(year from calendar_date) as year_num
        ,extract(week from calendar_date) as week_num
        ,min(calendar_date) as week_begin_dt
        from 
                (select
                dateadd(day, row_number() over (order by seq4()) - 1, dateadd(year, -3, current_date)) as calendar_date
                --,extract(week from dateadd(day, row_number() over (order by seq4()) - 1, dateadd(year, -3, current_date))) as week_num
                from table(GENERATOR(ROWCOUNT => 1096))
                ) a
        where calendar_date >= ''2025-01-01''
        group by all
        ) y
on x.app_wk = y.week_num
group by all
;

create or replace table business_intelligence.reporting.days_between_funnel_steps copy grants as 
select 
app_mo
,app_wk
,week_begin_dt
,funnel_type
,tier
,utm_source
,dynamic_verif_pass_yn as direct_verif_pass_yn
,days_between as all_days_between
,valid_days_between as days_between
,sum(lead_start_to_landed) as lead_start_to_landed
,sum(lead_start_to_applied) as lead_start_to_applied
,sum(applied_to_offer_shown) as applied_to_offer_shown
,sum(offer_shown_to_offer_selected) as offer_shown_to_offer_selected
,sum(offer_selected_to_esigned) as offer_selected_to_esigned
,sum(lead_start_to_esigned) as lead_start_to_esigned
from 
        (select
        *
        from business_intelligence.reporting.days_between_funnel_starts  
        
        union all
        
        select distinct
        app_mo
        ,a.app_wk
        ,b.week_begin_dt
        ,funnel_type
        ,tier
        ,utm_source
        ,dynamic_verif_pass_yn
        ,b.days_between
        ,b.valid_days_between
        ,0 as LEAD_START_TO_LANDED
        ,0 as LEAD_START_TO_APPLIED
        ,0 as APPLIED_TO_OFFER_SHOWN
        ,0 as OFFER_SHOWN_TO_OFFER_SELECTED
        ,0 as OFFER_SELECTED_TO_ESIGNED
        ,0 as LEAD_START_TO_ESIGNED
        from business_intelligence.reporting.days_between_funnel_starts a
        join     
            (select distinct
            week_begin_dt
            ,days_between
            ,valid_days_between
            from business_intelligence.reporting.days_between_funnel_starts
            ) b
        on a.week_begin_dt = b.week_begin_dt
        ) 
group by all
--order by 1,2,3,4,5,6,7,8
;

drop table business_intelligence.reporting.days_between_funnel_starts;


create or replace table business_intelligence.reporting.pending_app_segments copy grants as 
select 
a.app_dt
,last_day(app_dt) as app_mo
,a.app_id
,case   when a.funnel_type = ''Non-API'' and ifnull(app_channel_parent,''Null'') in (''Organic'',''Unattributed'',''Null'') then ''Non-API Organic Search''
        when a.funnel_type = ''Non-API'' and app_channel_parent in (''CK Lightbox'',''Affiliates'') then ''Non-API Affiliate''
        when a.funnel_type = ''Non-API'' and app_channel_parent in (''Direct Mail'') then ''Non-API DM''     
        when a.funnel_type = ''Non-API'' and app_channel_parent in (''Email'') then ''Non-API Email''   
        when a.funnel_type = ''Non-API'' then ''Non-API Search/Social''       
        else a.funnel_type end::varchar(55) as funnel_type_non_api_segments
,a.utm_content
,a.utm_term
,a.utm_campaign
,a.utm_source
,a.utm_medium
,a.app_channel 
,a.app_channel_parent         
,a.tier
,a.automation_identity_check_status
,a.automation_income_check_status
,a.automation_bank_account_check_status
,case when ssn_entered_ts is null then ''SSN Drop''
     when a.automation_income_check_status = ''Bypass'' then ''Bypass Plaid - Bypass Talx''
     when bank_1_plaid_access_token is not null and model_verified_annual_income is not null then ''Plaid Pass'' 
     when bank_1_plaid_access_token is not null and model_verified_annual_income is null and talx_income_check = ''Pass'' then ''Plaid Fail - Talx Pass'' 
     when bank_1_plaid_access_token is not null and model_verified_annual_income is null and talx_income_check = ''Fail'' then ''Plaid Fail - Talx Fail'' 
     when bank_1_plaid_access_token is not null and model_verified_annual_income is null and talx_rundate is not null and talx_income_check is null then ''Plaid Fail - Talx No Outcome'' 
     when bank_1_plaid_access_token is not null and model_verified_annual_income is null then ''Plaid Fail''
     when bank_1_plaid_access_token is null and talx_income_check = ''Pass'' then ''Plaid No Attempt - Talx Pass''
     when bank_1_plaid_access_token is null and talx_income_check = ''Fail'' then ''Plaid No Attempt - Talx Fail''
     when bank_1_plaid_access_token is null and talx_rundate is not null and talx_income_check is null then ''Plaid No Attempt - Talx No Outcome''
     else ''SSN Entered - No Plaid - No Talx'' end as plaid_talx_waterfall
,case when app_status = ''Offer Selected'' and ssn_entered_ts is not null then ''SSN Entered'' 
      when app_status = ''Underwriting'' and agent_id is not null and dynamic_verif_pass_yn = ''N'' and internal_dynamic_verif_pass_yn = ''N'' then ''UW Manual / Assigned''
      when app_status like ''%Credit Freeze%'' then ''Credit Freeze''
      else app_status end as app_status_defined
,app_status
,selected_offer_amt       

from business_intelligence.analytics.vw_app_loan_production a
left join business_intelligence.bridge.vw_los_custom_loan_settings_current b
on a.app_id = b.loan_id

where offer_selected_ts is not null
and esign_ts is null
and app_status not in (''Declined'',''Expired'',''Withdrawn'',''Automated Underwriting Requested'')
--and app_dt >= ''2025-08-11''
;


RETURN ''Procedure Executed Successfully.'';
END;
';