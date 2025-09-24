CREATE OR REPLACE PROCEDURE BUSINESS_INTELLIGENCE.BRIDGE.APP_LOAN_PRODUCTION()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS '
BEGIN

create or replace table business_intelligence.bridge.app_loan_prod_starts copy grants as
select
app_id
,created_ts
,note_new_value
from
        (select distinct
        app_id
        ,record_id
        ,created_ts
        ,lastupdated_ts
        ,note_new_value
        ,row_number() over (partition by app_id order by created_ts, lastupdated_ts, record_id) as row_asc
        ,row_number() over (partition by app_id order by created_ts desc, lastupdated_ts desc, record_id desc) as row_desc
        from business_intelligence.bridge.app_system_note_entity
        where note_title_detail in (''Loan Status - Loan Sub Status'',''Loan Sub Status'')
            and note_new_value is not null
            and is_hard_deleted = false
        ) x
where row_asc = 1
and note_new_value in (''Started'',''Affiliate Started'')
;

/*************************************************************************************************/
/*ID subset of apps that need to be inserted or updated based on new transactions in notes entity*/
/*************************************************************************************************/
create or replace table business_intelligence.bridge.apps_to_upsert copy grants as
select distinct app_id from business_intelligence.bridge.app_system_note_entity where created_ts::date >= current_date - 1;

/*use this condition if need to rebuild history for any table changes / additions*****************
create or replace table business_intelligence.bridge.apps_to_upsert copy grants as
select distinct app_id from business_intelligence.bridge.app_system_note_entity;
**************************************************************************************************/
create or replace table business_intelligence.bridge.app_system_note_entity_short_new copy grants as
select
a.*
,row_number() over (partition by a.app_id, note_title_detail order by created_ts, lastupdated_ts, record_id) as row_note_asc
,row_number() over (partition by a.app_id, note_title_detail order by created_ts desc, lastupdated_ts desc, record_id desc) as row_note_desc
from business_intelligence.bridge.app_system_note_entity a
join business_intelligence.bridge.apps_to_upsert b
on a.app_id = b.app_id
where note_new_value is not null
    and note_new_value <> ''null''
;


create or replace table business_intelligence.bridge.app_note_title_first copy grants as
select
app_id
,max(case when lower(note_title_detail) = ''application guid'' then note_new_value::varchar(255) end) as guid
,max(case when lower(note_title_detail) = ''application id'' then note_new_value::varchar(255) end) as application_guid
,max(case when lower(note_title_detail) = ''social security number'' then created_ts::timestamp_ntz end) as ssn_entered_ts
,max(case when lower(note_title_detail) = ''offer decision status'' then created_ts::timestamp_ntz end) as first_offer_decision_ts
,max(case when lower(note_title_detail) = ''offer decision status'' then note_new_value::varchar(255) end) as first_offer_decision
,max(case when lower(note_title_detail) = ''agent'' then created_ts::timestamp_ntz end) as uw_agent_assigned_ts
,max(case when lower(note_title_detail) = ''agent'' then note_new_value::integer end) as agent_id
from business_intelligence.bridge.app_system_note_entity_short_new
where row_note_asc = 1
group by all
;


create or replace table business_intelligence.bridge.app_note_title_last copy grants as
select
app_id
,max(case when lower(note_title_detail) = ''social security number'' and note_new_value not in (''123456789'',''111111111'',''222222222'',''333333333'',''444444444'',''555555555'',''666666666'',''777777777'',''888888888'',''999999999'',''000000000'') then note_new_value::char(9) end) as social_sec_nbr
,max(case when lower(note_title_detail) = ''bureau ssn'' and note_new_value not in (''123456789'',''111111111'',''222222222'',''333333333'',''444444444'',''555555555'',''666666666'',''777777777'',''888888888'',''999999999'',''000000000'') then regexp_replace(note_new_value, ''[\\\\[\\\\]]'', '''') end)::char(9) as bureau_ssn
,max(case when lower(note_title_detail) = ''aff ssn'' and note_new_value not in (''123456789'',''111111111'',''222222222'',''333333333'',''444444444'',''555555555'',''666666666'',''777777777'',''888888888'',''999999999'',''000000000'') then note_new_value::char(9) end) as aff_ssn
,max(case when lower(note_title_detail) = ''email'' then trim(upper(note_new_value))::varchar(255) end) as email
,max(case when lower(note_title_detail) = ''tier'' then note_new_value::integer end) as tier
,max(case when lower(note_title_detail) = ''utm source'' and length(note_new_value) <= 55 then note_new_value::varchar(55) end) as utm_source
,max(case when lower(note_title_detail) = ''utm medium'' then note_new_value::varchar(55) end) as utm_medium
,max(case when lower(note_title_detail) = ''utm content'' then note_new_value::string end) as utm_content
,max(case when lower(note_title_detail) = ''utm campaign'' then note_new_value::string end) as utm_campaign
,max(case when lower(note_title_detail) = ''utm term'' then note_new_value::string end) as utm_term
,max(case when lower(note_title_detail) = ''selected offer id'' then note_new_value::char(255) end) as selected_offer_id
,max(case when lower(note_title_detail) = ''requested loan amount'' then note_new_value::numeric(10,2) end) as requested_loan_amt
,max(case when lower(note_title_detail) = ''offer decision status'' then created_ts::timestamp_ntz end) as last_offer_decision_ts
,max(case when lower(note_title_detail) = ''offer decision status'' then note_new_value::varchar(255) end) as last_offer_decision
,max(case when lower(note_title_detail) = ''origination date'' then created_ts::timestamp_ntz end) as originated_ts
,max(case when lower(note_title_detail) = ''origination date'' then note_new_value::date end) as originated_dt
,max(case when lower(note_title_detail) = ''amount'' then note_new_value::numeric(10,2) end) as loan_amt
,max(case when lower(note_title_detail) = ''origination fee'' then note_new_value::numeric(10,2) end) as orig_fee_amt
,max(case when lower(note_title_detail) = ''premium amount'' then note_new_value::numeric(10,2) end) as prem_fee_amt
,max(case when lower(note_title_detail) = ''term months'' then note_new_value::numeric(10,2) end) as term
,max(case when lower(note_title_detail) = ''apr'' then note_new_value/100::numeric(10,4) end) as apr_prct
,max(case when lower(note_title_detail) = ''interest rate'' then note_new_value/100::numeric(10,4) end) as int_rate_prct
,max(case when lower(note_title_detail) = ''monthly payment'' then note_new_value::numeric(10,2) end) as monthly_payment_amt
,max(case when lower(note_title_detail) = ''source company'' then note_new_value::varchar(55) end) as source_company
,max(case when lower(note_title_detail) = ''capital partner'' then note_new_value::varchar(55) end) as capital_partner
,max(case when lower(note_title_detail) = ''loan purpose'' then upper(note_new_value)::varchar(255) end) as loan_purpose
,max(case when lower(note_title_detail) = ''bureau state'' then upper(note_new_value)::char(2) end) as bureau_st
,max(case when lower(note_title_detail) = ''first name'' then trim(upper(note_new_value))::varchar(255) end) as first_name
,max(case when lower(note_title_detail) = ''last name'' then trim(upper(note_new_value))::varchar(255) end) as last_name
,max(case when lower(note_title_detail) = ''home address street1'' then trim(upper(note_new_value))::varchar(255) end) as address_1
,max(case when lower(note_title_detail) = ''home address street2'' then trim(upper(note_new_value))::varchar(255) end) as address_2
,max(case when lower(note_title_detail) = ''home address city'' then trim(upper(note_new_value))::varchar(255) end) as city
,max(case when lower(note_title_detail) = ''home address state'' then upper(regexp_replace(replace(note_new_value, ''geo.state.'', ''''),''[0-9-]+'','''')::char(255)) end) as cust_addr_st
,max(case when lower(note_title_detail) = ''home address zip'' and length(note_new_value) = 5 and left(note_new_value,1) in (''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'')
and note_new_value <> ''00000'' then regexp_replace(note_new_value, ''-.*', '''')::char(5) end) as zip
,max(case when lower(note_title_detail) = ''phone'' then case when length(regexp_replace(note_new_value,''[^[:digit:]]''))=10 and regexp_replace(note_new_value,''[^[:digit:]]'') not in
(''1234567890'',''1111111111'',''2222222222'',''3333333333'',''4444444444'',''5555555555'',''6666666666'',''7777777777'',''8888888888'',''9999999999'',''0000000000'',''2077997158'',''5083459379'',''8459523835'','''')
then regexp_replace(note_new_value, ''[^[:digit:]]'', '''') end::varchar(10) end) as phone
,max(case when lower(note_title_detail) = ''date of birth'' then note_new_value::date end) as dob
,max(case when lower(note_title_detail) = ''migratedfromcls'' then note_new_value::numeric else 0 end) as migrated_from_cls
,max(case when lower(note_title_detail) = ''credit score'' then note_new_value::numeric else 0 end) as credit_score
,max(case when lower(note_title_detail) = ''dm invitation code'' then note_new_value::varchar(25) else null end) as dm_invitation_cd
from business_intelligence.bridge.app_system_note_entity_short_new
where row_note_desc = 1
group by all
;


create or replace table business_intelligence.bridge.app_status_transition_short copy grants as
select
a.*
,coalesce(b.guid,b.application_guid) as guid
from
        (select
        app_id
        ,min(case when note_new_value = ''Affiliate Landed'' then created_ts end) as affiliate_landed_min_ts
        ,max(case when note_new_value = ''Affiliate Landed'' then created_ts end) as affiliate_landed_max_ts
        ,sum(case when note_new_value = ''Affiliate Landed'' then 1 else 0 end) as affiliate_landed_cnt
        ,min(case when note_new_value = ''Affiliate Started'' then created_ts end) as affiliate_started_min_ts
        ,max(case when note_new_value = ''Affiliate Started'' then created_ts end) as affiliate_started_max_ts
        ,sum(case when note_new_value = ''Affiliate Started'' then 1 else 0 end) as affiliate_started_cnt
        ,min(case when note_new_value = ''Allocated'' then created_ts end) as allocated_min_ts
        ,max(case when note_new_value = ''Allocated'' then created_ts end) as allocated_max_ts
        ,sum(case when note_new_value = ''Allocated'' then 1 else 0 end) as allocated_cnt
        ,min(case when note_new_value = ''Applied'' then created_ts end) as applied_min_ts
        ,max(case when note_new_value = ''Applied'' then created_ts end) as applied_max_ts
        ,sum(case when note_new_value = ''Applied'' then 1 else 0 end) as applied_cnt
        ,min(case when note_new_value = ''Approved'' then created_ts end) as approved_min_ts
        ,max(case when note_new_value = ''Approved'' then created_ts end) as approved_max_ts
        ,sum(case when note_new_value = ''Approved'' then 1 else 0 end) as approved_cnt
        ,min(case when note_new_value = ''Approved Received'' then created_ts end) as approved_received_min_ts
        ,max(case when note_new_value = ''Approved Received'' then created_ts end) as approved_received_max_ts
        ,sum(case when note_new_value = ''Approved Received'' then 1 else 0 end) as approved_received_cnt
        ,min(case when note_new_value = ''AutoPay Completed Requested'' then created_ts end) as autopay_completed_requested_min_ts
        ,max(case when note_new_value = ''AutoPay Completed Requested'' then created_ts end) as autopay_completed_requested_max_ts
        ,sum(case when note_new_value = ''AutoPay Completed Requested'' then 1 else 0 end) as autopay_completed_requested_cnt
        ,min(case when note_new_value = ''AutoPay Opt Out Received'' then created_ts end) as autopay_opt_out_received_min_ts
        ,max(case when note_new_value = ''AutoPay Opt Out Received'' then created_ts end) as autopay_opt_out_received_max_ts
        ,sum(case when note_new_value = ''AutoPay Opt Out Received'' then 1 else 0 end) as autopay_opt_out_received_cnt
        ,min(case when note_new_value = ''AutoPay Opt Out Requested'' then created_ts end) as autopay_opt_out_requested_min_ts
        ,max(case when note_new_value = ''AutoPay Opt Out Requested'' then created_ts end) as autopay_opt_out_requested_max_ts
        ,sum(case when note_new_value = ''AutoPay Opt Out Requested'' then 1 else 0 end) as autopay_opt_out_requested_cnt
        ,min(case when note_new_value = ''Automated Underwriting Completed'' then created_ts end) as automated_underwriting_completed_min_ts
        ,max(case when note_new_value = ''Automated Underwriting Completed'' then created_ts end) as automated_underwriting_completed_max_ts
        ,sum(case when note_new_value = ''Automated Underwriting Completed'' then 1 else 0 end) as automated_underwriting_completed_cnt
        ,min(case when note_new_value = ''Automated Underwriting Received'' then created_ts end) as automated_underwriting_received_min_ts
        ,max(case when note_new_value = ''Automated Underwriting Received'' then created_ts end) as automated_underwriting_received_max_ts
        ,sum(case when note_new_value = ''Automated Underwriting Received'' then 1 else 0 end) as automated_underwriting_received_cnt
        ,min(case when note_new_value = ''Automated Underwriting Requested'' then created_ts end) as automated_underwriting_requested_min_ts
        ,max(case when note_new_value = ''Automated Underwriting Requested'' then created_ts end) as automated_underwriting_requested_max_ts
        ,sum(case when note_new_value = ''Automated Underwriting Requested'' then 1 else 0 end) as automated_underwriting_requested_cnt
        ,min(case when note_new_value = ''Autopay Data Submitted'' then created_ts end) as autopay_data_submitted_min_ts
        ,max(case when note_new_value = ''Autopay Data Submitted'' then created_ts end) as autopay_data_submitted_max_ts
        ,sum(case when note_new_value = ''Autopay Data Submitted'' then 1 else 0 end) as autopay_data_submitted_cnt
        ,min(case when note_new_value = ''Awaiting DCP'' then created_ts end) as awaiting_dcp_min_ts
        ,max(case when note_new_value = ''Awaiting DCP'' then created_ts end) as awaiting_dcp_max_ts
        ,sum(case when note_new_value = ''Awaiting DCP'' then 1 else 0 end) as awaiting_dcp_cnt
        ,min(case when note_new_value = ''Credit Freeze'' then created_ts end) as credit_freeze_min_ts
        ,max(case when note_new_value = ''Credit Freeze'' then created_ts end) as credit_freeze_max_ts
        ,sum(case when note_new_value = ''Credit Freeze'' then 1 else 0 end) as credit_freeze_cnt
        ,min(case when note_new_value = ''Credit Freeze Stacker Check'' then created_ts end) as credit_freeze_stacker_check_min_ts
        ,max(case when note_new_value = ''Credit Freeze Stacker Check'' then created_ts end) as credit_freeze_stacker_check_max_ts
        ,sum(case when note_new_value = ''Credit Freeze Stacker Check'' then 1 else 0 end) as credit_freeze_stacker_check_cnt
        ,min(case when note_new_value = ''DCP Captured'' then created_ts end) as dcp_captured_min_ts
        ,max(case when note_new_value = ''DCP Captured'' then created_ts end) as dcp_captured_max_ts
        ,sum(case when note_new_value = ''DCP Captured'' then 1 else 0 end) as dcp_captured_cnt
        ,min(case when note_new_value = ''DCP Opt In'' then created_ts end) as dcp_opt_in_min_ts
        ,max(case when note_new_value = ''DCP Opt In'' then created_ts end) as dcp_opt_in_max_ts
        ,sum(case when note_new_value = ''DCP Opt In'' then 1 else 0 end) as dcp_opt_in_cnt
        ,min(case when note_new_value = ''Declined'' then created_ts end) as declined_min_ts
        ,max(case when note_new_value = ''Declined'' then created_ts end) as declined_max_ts
        ,sum(case when note_new_value = ''Declined'' then 1 else 0 end) as declined_cnt
        ,min(case when note_new_value = ''Doc Upload'' then created_ts end) as doc_upload_min_ts
        ,max(case when note_new_value = ''Doc Upload'' then created_ts end) as doc_upload_max_ts
        ,sum(case when note_new_value = ''Doc Upload'' then 1 else 0 end) as doc_upload_cnt
        ,min(case when note_new_value = ''Expired'' then created_ts end) as expired_min_ts
        ,max(case when note_new_value = ''Expired'' then created_ts end) as expired_max_ts
        ,sum(case when note_new_value = ''Expired'' then 1 else 0 end) as expired_cnt
        ,min(case when note_new_value = ''Fraud Check Failed'' then created_ts end) as fraud_check_failed_min_ts
        ,max(case when note_new_value = ''Fraud Check Failed'' then created_ts end) as fraud_check_failed_max_ts
        ,sum(case when note_new_value = ''Fraud Check Failed'' then 1 else 0 end) as fraud_check_failed_cnt
        ,min(case when note_new_value = ''Fraud Check Received'' then created_ts end) as fraud_check_received_min_ts
        ,max(case when note_new_value = ''Fraud Check Received'' then created_ts end) as fraud_check_received_max_ts
        ,sum(case when note_new_value = ''Fraud Check Received'' then 1 else 0 end) as fraud_check_received_cnt
        ,min(case when note_new_value = ''Fraud Rejected'' then created_ts end) as fraud_rejected_min_ts
        ,max(case when note_new_value = ''Fraud Rejected'' then created_ts end) as fraud_rejected_max_ts
        ,sum(case when note_new_value = ''Fraud Rejected'' then 1 else 0 end) as fraud_rejected_cnt
        ,min(case when note_new_value = ''Funded'' then created_ts end) as funded_min_ts
        ,max(case when note_new_value = ''Funded'' then created_ts end) as funded_max_ts
        ,sum(case when note_new_value = ''Funded'' then 1 else 0 end) as funded_cnt
        ,min(case when note_new_value = ''ICS'' then created_ts end) as ics_min_ts
        ,max(case when note_new_value = ''ICS'' then created_ts end) as ics_max_ts
        ,sum(case when note_new_value = ''ICS'' then 1 else 0 end) as ics_cnt
        ,min(case when note_new_value = ''Loan Docs Completed'' then created_ts end) as loan_docs_completed_min_ts
        ,max(case when note_new_value = ''Loan Docs Completed'' then created_ts end) as loan_docs_completed_max_ts
        ,sum(case when note_new_value = ''Loan Docs Completed'' then 1 else 0 end) as loan_docs_completed_cnt
        ,min(case when note_new_value = ''Loan Docs Ready'' then created_ts end) as loan_docs_ready_min_ts
        ,max(case when note_new_value = ''Loan Docs Ready'' then created_ts end) as loan_docs_ready_max_ts
        ,sum(case when note_new_value = ''Loan Docs Ready'' then 1 else 0 end) as loan_docs_ready_cnt
        ,min(case when note_new_value = ''Loan Docs Signed Requested'' then created_ts end) as loan_docs_signed_requested_min_ts
        ,max(case when note_new_value = ''Loan Docs Signed Requested'' then created_ts end) as loan_docs_signed_requested_max_ts
        ,sum(case when note_new_value = ''Loan Docs Signed Requested'' then 1 else 0 end) as loan_docs_signed_requested_cnt
        ,min(case when note_new_value = ''Offer Selected'' then created_ts end) as offer_selected_min_ts
        ,max(case when note_new_value = ''Offer Selected'' then created_ts end) as offer_selected_max_ts
        ,sum(case when note_new_value = ''Offer Selected'' then 1 else 0 end) as offer_selected_cnt
        ,min(case when note_new_value = ''Offers Decision Completed'' then created_ts end) as offers_decision_completed_min_ts
        ,max(case when note_new_value = ''Offers Decision Completed'' then created_ts end) as offers_decision_completed_max_ts
        ,sum(case when note_new_value = ''Offers Decision Completed'' then 1 else 0 end) as offers_decision_completed_cnt
        ,min(case when note_new_value = ''Offers Decision Received'' then created_ts end) as offers_decision_received_min_ts
        ,max(case when note_new_value = ''Offers Decision Received'' then created_ts end) as offers_decision_received_max_ts
        ,sum(case when note_new_value = ''Offers Decision Received'' then 1 else 0 end) as offers_decision_received_cnt
        ,min(case when note_new_value = ''Offers Decision Requested'' then created_ts end) as offers_decision_requested_min_ts
        ,max(case when note_new_value = ''Offers Decision Requested'' then created_ts end) as offers_decision_requested_max_ts
        ,sum(case when note_new_value = ''Offers Decision Requested'' then 1 else 0 end) as offers_decision_requested_cnt
        ,min(case when note_new_value = ''Offers Shown'' then created_ts end) as offers_shown_min_ts
        ,max(case when note_new_value = ''Offers Shown'' then created_ts end) as offers_shown_max_ts
        ,sum(case when note_new_value = ''Offers Shown'' then 1 else 0 end) as offers_shown_cnt
        ,min(case when note_new_value = ''Open - Repaying'' then created_ts end) as open_repaying_min_ts
        ,max(case when note_new_value = ''Open - Repaying'' then created_ts end) as open_repaying_max_ts
        ,sum(case when note_new_value = ''Open - Repaying'' then 1 else 0 end) as open_repaying_cnt
        ,min(case when note_new_value = ''Originated'' then created_ts end) as originated_min_ts
        ,max(case when note_new_value = ''Originated'' then created_ts end) as originated_max_ts
        ,sum(case when note_new_value = ''Originated'' then 1 else 0 end) as originated_cnt
        ,min(case when note_new_value = ''Partner Rejected'' then created_ts end) as partner_rejected_min_ts
        ,max(case when note_new_value = ''Partner Rejected'' then created_ts end) as partner_rejected_max_ts
        ,sum(case when note_new_value = ''Partner Rejected'' then 1 else 0 end) as partner_rejected_cnt
        ,min(case when note_new_value = ''Pending Funding'' then created_ts end) as pending_funding_min_ts
        ,max(case when note_new_value = ''Pending Funding'' then created_ts end) as pending_funding_max_ts
        ,sum(case when note_new_value = ''Pending Funding'' then 1 else 0 end) as pending_funding_cnt
        ,min(case when note_new_value = ''Pre-Funding'' then created_ts end) as pre_funding_min_ts
        ,max(case when note_new_value = ''Pre-Funding'' then created_ts end) as pre_funding_max_ts
        ,sum(case when note_new_value = ''Pre-Funding'' then 1 else 0 end) as pre_funding_cnt
        ,min(case when note_new_value = ''Stacker Check Completed'' then created_ts end) as stacker_check_completed_min_ts
        ,max(case when note_new_value = ''Stacker Check Completed'' then created_ts end) as stacker_check_completed_max_ts
        ,sum(case when note_new_value = ''Stacker Check Completed'' then 1 else 0 end) as stacker_check_completed_cnt
        ,min(case when note_new_value = ''Stacker Check Request Received'' then created_ts end) as stacker_check_request_received_min_ts
        ,max(case when note_new_value = ''Stacker Check Request Received'' then created_ts end) as stacker_check_request_received_max_ts
        ,sum(case when note_new_value = ''Stacker Check Request Received'' then 1 else 0 end) as stacker_check_request_received_cnt
        ,min(case when note_new_value = ''Stacker Check Requested'' then created_ts end) as stacker_check_requested_min_ts
        ,max(case when note_new_value = ''Stacker Check Requested'' then created_ts end) as stacker_check_requested_max_ts
        ,sum(case when note_new_value = ''Stacker Check Requested'' then 1 else 0 end) as stacker_check_requested_cnt
        ,min(case when note_new_value = ''Started'' then created_ts end) as started_min_ts
        ,max(case when note_new_value = ''Started'' then created_ts end) as started_max_ts
        ,sum(case when note_new_value = ''Started'' then 1 else 0 end) as started_cnt
        ,min(case when note_new_value = ''TIL Acknowledged'' then created_ts end) as til_acknowledged_min_ts
        ,max(case when note_new_value = ''TIL Acknowledged'' then created_ts end) as til_acknowledged_max_ts
        ,sum(case when note_new_value = ''TIL Acknowledged'' then 1 else 0 end) as til_acknowledged_cnt
        ,min(case when note_new_value = ''TIL Generation Complete'' then created_ts end) as til_generation_complete_min_ts
        ,max(case when note_new_value = ''TIL Generation Complete'' then created_ts end) as til_generation_complete_max_ts
        ,sum(case when note_new_value = ''TIL Generation Complete'' then 1 else 0 end) as til_generation_complete_cnt
        ,min(case when note_new_value = ''TIL Generation Received'' then created_ts end) as til_generation_received_min_ts
        ,max(case when note_new_value = ''TIL Generation Received'' then created_ts end) as til_generation_received_max_ts
        ,sum(case when note_new_value = ''TIL Generation Received'' then 1 else 0 end) as til_generation_received_cnt
        ,min(case when note_new_value = ''TIL Generation Requested'' then created_ts end) as til_generation_requested_min_ts
        ,max(case when note_new_value = ''TIL Generation Requested'' then created_ts end) as til_generation_requested_max_ts
        ,sum(case when note_new_value = ''TIL Generation Requested'' then 1 else 0 end) as til_generation_requested_cnt
        ,min(case when note_new_value = ''Underwriting'' then created_ts end) as underwriting_min_ts
        ,max(case when note_new_value = ''Underwriting'' then created_ts end) as underwriting_max_ts
        ,sum(case when note_new_value = ''Underwriting'' then 1 else 0 end) as underwriting_cnt
        ,min(case when note_new_value = ''Underwriting Complete'' then created_ts end) as underwriting_complete_min_ts
        ,max(case when note_new_value = ''Underwriting Complete'' then created_ts end) as underwriting_complete_max_ts
        ,sum(case when note_new_value = ''Underwriting Complete'' then 1 else 0 end) as underwriting_complete_cnt
        ,min(case when note_new_value = ''Withdrawn'' then created_ts end) as withdrawn_min_ts
        ,max(case when note_new_value = ''Withdrawn'' then created_ts end) as withdrawn_max_ts
        ,sum(case when note_new_value = ''Withdrawn'' then 1 else 0 end) as withdrawn_cnt

        from business_intelligence.bridge.app_system_note_entity_short_new
        where note_title_detail in (''Loan Status - Loan Sub Status'',''Loan Sub Status'')
            and note_new_value is not null
            and is_hard_deleted = false
        group by all
        ) a
left join business_intelligence.bridge.app_note_title_first b
on a.app_id = b.app_id

join business_intelligence.bridge.app_note_title_last c
on a.app_id = c.app_id
          and ifnull(upper(c.email),'''') not like ''%HAPPYMONEY%''

;

--select count(*) from business_intelligence.bridge.app_status_transition   1418349
--select count(*) from business_intelligence.bridge.app_loan_production     1418349
--select count(*) from business_intelligence.bridge.lp_app_pii              1418349
--delete from business_intelligence.bridge.lp_app_pii where app_id not in (select distinct app_id from business_intelligence.bridge.app_loan_production);


delete from business_intelligence.bridge.app_status_transition where app_id in (select distinct app_id from business_intelligence.bridge.apps_to_upsert);
insert into business_intelligence.bridge.app_status_transition select * from business_intelligence.bridge.app_status_transition_short;


create or replace table business_intelligence.bridge.lp_app_pii_short copy grants as
select
a.app_id
,coalesce(b.guid,b.application_guid) as guid
,a.first_name
,a.last_name
,a.address_1
,a.address_2
,a.city
,a.cust_addr_st as state
,a.zip as zip_code
,''+1''||a.phone as phone_nbr
,a.email
,a.dob as date_of_birth
,a.social_sec_nbr
,a.bureau_ssn
,a.aff_ssn
,case when c.app_id is not null then ''Y'' else ''N'' end::char(1) as is_app_yn
,''LOANPRO'' as SOURCE
from business_intelligence.bridge.app_note_title_last a

left join business_intelligence.bridge.app_note_title_first b
on a.app_id = b.app_id

left join business_intelligence.bridge.app_status_transition_short c
on a.app_id = c.app_id
          and (c.applied_min_ts is not null or c.loan_docs_completed_min_ts is not null)

where a.migrated_from_cls = 0
and ifnull(a.email,'''') not like ''%HAPPYMONEY%''
;


delete from business_intelligence.bridge.lp_app_pii where app_id in (select distinct app_id from business_intelligence.bridge.apps_to_upsert);
insert into business_intelligence.bridge.lp_app_pii select * from business_intelligence.bridge.lp_app_pii_short;


create or replace table business_intelligence.bridge.app_income_review copy grants as
select distinct
x.loan_id as app_id
,x.automation_identity_check_status::varchar(25) as automation_identity_check_status
,x.automation_bank_account_check_status::varchar(25) as automation_bank_account_check_status
,x.automation_income_check_status::varchar(25) as automation_income_check_status
,case   when x.automation_income_check_status in(''Pass'',''Fail'') then x.automation_income_check_status
        when x.income_verification_result in (''Pass'',''Fail'') then x.income_verification_result
        when y.loan_id is not null then ''Bypass''
        else x.automation_income_check_status end::varchar(25) as internal_auto_income_check_status
from business_intelligence.bridge.vw_los_custom_loan_settings_current x

left join
        (select distinct
        loan_id
        from business_intelligence.bridge.vw_loan_portfolio_current a
        join business_intelligence.bridge.vw_portfolio_entity_current b
        on a.portfolio_id = b.id
        where b.title = ''Income Bypass''
        ) y
on x.loan_id = y.loan_id

join business_intelligence.bridge.apps_to_upsert z
on x.loan_id = z.app_id
;

create or replace table business_intelligence.bridge.app_fraud_declines copy grants as
select
app_id
,max(manual_fraud_decline) as manual_fraud_decline
,max(automated_fraud_decline) as automated_fraud_decline
from
        (select distinct
        app_id
        ,1 as manual_fraud_decline
        ,0 as automated_fraud_decline
        from business_intelligence.bridge.app_system_note_entity_short_new
        where note_new_value = ''Declined''
            and portfolios_added_category = ''Fraud''
            and portfolios_added_label = ''Manual Decline''

        union all

        select distinct
        app_id
        ,0 as manual_fraud_decline
        ,1 as automated_fraud_decline
        from
                (select distinct
                app_id
                from business_intelligence.bridge.app_system_note_entity_short_new
                where note_new_value = ''Fraud Rejected''

                union

                select distinct
                app_id
                from business_intelligence.bridge.app_system_note_entity_short_new
                where note_new_value = ''Declined''
                    and portfolios_added_category = ''Fraud''
                    and portfolios_added_label = ''Auto Decline High Fraud Risk''
                ) x
        ) y
group by all
;

create or replace table business_intelligence.bridge.app_agent_processing_actions copy grants as
select distinct
app_id
,first_value(b.agent_id) over (partition by app_id order by action_result_ts) as agent_id_first
,first_value(agent_name) over (partition by app_id order by action_result_ts) as agent_name_first
,first_value(action_result_ts) over (partition by app_id order by action_result_ts) as action_result_ts_first
,first_value(b.agent_id) over (partition by app_id order by action_result_ts desc) as agent_id_last
,first_value(agent_name) over (partition by app_id order by action_result_ts desc) as agent_name_last
,first_value(action_result_ts) over (partition by app_id order by action_result_ts desc) as action_result_ts_last
from business_intelligence.analytics.vw_app_action_and_results a
join business_intelligence.analytics.ref_agent_info b
on a.agent_name = b.agent_full_name
    and a.action_text = ''Processing''
    and a.agent_name <> ''Joanna Nolazco''
;

create or replace table business_intelligence.bridge.lms_loan_setup copy grants as
select
b.lp_application_id as app_id
,a.loan_id
,upper(b.payoff_loan_id) as payoff_loan_id
,a.loan_amount + a.underwriting as loan_amt
,a.underwriting as orig_fee_amt
,(a.underwriting / loan_amt)::numeric(10,4) as orig_fee_prct
,b.premium_amount::numeric(10,2) as prem_fee_amt
,(b.premium_amount / loan_amt)::numeric(10,4) as prem_fee_prct
,a.loan_term::integer as term
,(a.apr/100)::numeric(10,4) as apr_prct
,(a.loan_rate/100)::numeric(10,4) as int_rate_prct
,a.payment as monthly_payment_amt
from arca.freshsnow.loan_setup_entity_current a
left join arca.freshsnow.vw_lms_custom_loan_settings_current b
on a.loan_id = b.loan_id
where left(upper(b.payoff_loan_id), 1) = ''H''
    and schema_name = config.lms_schema()
    and lp_application_id||load_batch_id <> 26282548102
;

/*************************************************************************************************/
/*Create new records base table for apps to be upserted into the history table********************/
/*************************************************************************************************/
--overall app status field (current status / declined / expired)
--manual fraud review
;


create or replace table business_intelligence.bridge.app_loan_production_new copy grants as
select distinct
a.app_id
,coalesce(d.guid,d.application_guid) as guid
,coalesce(e.social_sec_nbr, e.bureau_ssn, e.aff_ssn)::char(9) as ssn      --need to ensure logic is picking correctly (SSN Identity Match include somehow?)
,trim(upper(e.email))::varchar(255) as email
,e.cust_addr_st
,e.bureau_st
,a.created_ts::date as app_dt
,case when a.note_new_value = ''Started'' then ''Non-API'' when a.note_new_value = ''Affiliate Started'' then ''API'' else null end::varchar(10) as funnel_type
--,null::char(255) as api_partner_request_guid         --need to update
,null::varchar(55) as api_partner_decision
,e.tier
,upper(e.utm_source)::varchar(55) as utm_source
,upper(e.utm_medium)::varchar(55) as utm_medium
,case when upper(e.utm_source) like ''%LIGHTBOX%'' then ''CK Lightbox'' else f.last_touch_utm_channel_grouping end::varchar(55) as app_channel
,case when upper(e.utm_source) like ''%LIGHTBOX%'' then ''CK Lightbox'' else f.last_touch_utm_channel_grouping_parent end::varchar(55) as app_channel_parent
,i.automation_identity_check_status
,i.automation_bank_account_check_status
,i.automation_income_check_status
,case when i.automation_identity_check_status = ''Pass'' and i.automation_bank_account_check_status = ''Pass'' and i.automation_income_check_status in (''Pass'',''Bypass'') then ''Y'' else ''N'' end::char(1) as direct_verif_pass_yn
,case when j.automated_fraud_decline = 1 then ''Y'' else ''N'' end::char(1) as automated_fraud_decline_yn
,''N''::char(1) as manual_fraud_review_yn                 --need to add update logic and ensure logic matches the fraud data from oscilar
,case when j.manual_fraud_decline = 1 then ''Y'' else ''N'' end::char(1) as manual_fraud_decline_yn
,''N''::char(1) as counter_off_yn
,e.selected_offer_id
,null::varchar(55) as app_status                      --need to write a waterfall using business_intelligence.bridge.app_loan_sub_statuses_short (ie declined, expired, withdrawn.....else latest status  )
,a.created_ts::timestamp_ntz as app_ts
,c.affiliate_landed_min_ts::timestamp_ntz as affiliate_landed_ts
,c.applied_min_ts::timestamp_ntz as applied_ts
,c.offers_shown_min_ts::timestamp_ntz as offer_shown_ts
,c.offer_selected_min_ts::timestamp_ntz as offer_selected_ts
,d.ssn_entered_ts
,c.doc_upload_min_ts::timestamp_ntz as doc_upload_ts
,c.underwriting_min_ts::timestamp_ntz as uw_started_ts
,c.underwriting_complete_max_ts::timestamp_ntz as uw_complete_ts
,c.loan_docs_completed_max_ts::timestamp_ntz as esign_ts
,case when c.loan_docs_completed_max_ts is not null then e.originated_ts else null end as originated_ts
,case when c.loan_docs_completed_max_ts is not null then e.originated_dt else null end as originated_dt
,case when k.result_text = ''Withdrawal Reversed'' then null else c.withdrawn_max_ts::timestamp_ntz end as withdrawn_ts
,case when k.result_text = ''Decline Reversed'' then null else c.declined_max_ts::timestamp_ntz end as declined_ts
,c.expired_max_ts::timestamp_ntz as expired_ts
,e.requested_loan_amt
,g.max_offer_amt
,h.loan_amount::numeric(10,2) as selected_offer_amt
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.loan_amt,e.loan_amt,h.loan_amount) else null end::numeric(10,2) as loan_amt
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.orig_fee_amt,e.orig_fee_amt) else null end::numeric(10,2) as orig_fee_amt
,case when c.loan_docs_completed_max_ts is not null and coalesce(m.loan_amt,e.loan_amt,h.loan_amount) > 0 then coalesce(m.orig_fee_prct,e.orig_fee_amt / coalesce(m.loan_amt,e.loan_amt,h.loan_amount)) else null end::numeric(10,4) as orig_fee_prct
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.prem_fee_amt,e.prem_fee_amt) else null end::numeric(10,2) as prem_fee_amt
,case when coalesce(m.loan_amt,e.loan_amt,h.loan_amount) > 0 then e.prem_fee_amt / coalesce(m.loan_amt,e.loan_amt,h.loan_amount) else null end::numeric(10,4) as prem_fee_prct
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.term,e.term) else null end::integer as term
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.apr_prct,e.apr_prct) else null end::numeric(10,4) as apr_prct
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.int_rate_prct,e.int_rate_prct) else null end::numeric(10,4) as int_rate_prct
,case when c.loan_docs_completed_max_ts is not null then coalesce(m.monthly_payment_amt,e.monthly_payment_amt) else null end::numeric(10,2) as monthly_payment_amt
,case when c.loan_docs_completed_max_ts is not null then
                case when e.capital_partner = ''MSUFCU'' and e.source_company = ''First Tech FCU'' then ''Michigan State University FCU''
                     when e.source_company = ''USALLIANCE FCU (Insured)'' then ''USAlliance FCU''
                     else e.source_company end
        else null end::varchar(55) as source_company
,case when c.loan_docs_completed_max_ts is not null then e.capital_partner else null end::varchar(55) as capital_partner
,''N''::char(1) as guid_dupe_yn                                   --need to ensure deduping logic is accurate, current logic picks esign then the first app by min app_id
,e.loan_purpose
,e.utm_content
,e.utm_term
,e.utm_campaign
,i.internal_auto_income_check_status
,coalesce(d.uw_agent_assigned_ts::timestamp_ntz,l.action_result_ts_first) as uw_agent_assigned_ts
,coalesce(d.agent_id,l.agent_id_first) as agent_id
,e.credit_score
,case when c.loan_docs_completed_max_ts is not null then m.loan_id else null end::integer as loan_id
,case when c.loan_docs_completed_max_ts is not null then m.payoff_loan_id else null end::varchar(25) as payoff_loan_id
,n.customer_id
,e.dm_invitation_cd
from business_intelligence.bridge.app_loan_prod_starts a

join business_intelligence.bridge.apps_to_upsert b
on a.app_id = b.app_id

join business_intelligence.bridge.app_status_transition_short c
on a.app_id = c.app_id

join business_intelligence.bridge.app_note_title_first d
on a.app_id = d.app_id

join business_intelligence.bridge.app_note_title_last e
on a.app_id = e.app_id

left join business_intelligence.bridge.vw_utm_source_medium_channel_grouping_lookup f
on upper(ifnull(e.utm_medium,'''')) = upper(ifnull(f.utm_medium,'''')) and upper(ifnull(e.utm_source,'''')) = upper(ifnull(f.utm_source,''''))

left join
            (select
            application_id as app_id
            ,max(loan_amount)::numeric(10,2) as max_offer_amt
            from business_intelligence.analytics.vw_offers
            group by all
            ) g
on a.app_id = g.app_id

left join business_intelligence.analytics.vw_offers h
on e.selected_offer_id  = h.offer_id

left join business_intelligence.bridge.app_income_review i
on a.app_id = i.app_id

left join business_intelligence.bridge.app_fraud_declines j
on a.app_id = j.app_id

left join
            (select distinct
            app_id
            ,result_text
            from business_intelligence.analytics.vw_app_action_and_results
            where result_text in (''Decline Reversed'',''Withdrawal Reversed'')
            ) k
on a.app_id = k.app_id

left join business_intelligence.bridge.app_agent_processing_actions l
on a.app_id = l.app_id

left join business_intelligence.bridge.lms_loan_setup m
on a.app_id = m.app_id

left join
            (select distinct
            loan_id as app_id
            ,first_value(customer_id) over (partition by loan_id order by created desc, lastupdated desc) as customer_id
            from business_intelligence.bridge.vw_loan_customer_current
            where schema_name = ''5203309_P''
            ) n
on a.app_id = n.app_id
;


-- update business_intelligence.cron_store.app_loan_production_new a
-- set
-- api_partner_request_guid = b.request_guid
-- from
--     (select distinct
--     payoff_uid as guid
--     ,first_value(request_guid) over (partition by payoff_uid order by transaction_time_utc desc) as request_guid
--     from business_intelligence.analytics.vw_bureau_responses_header_current a
--     where bureausubtypename = ''Partner Applicant''
--     and payoff_uid <> ''None'' and request_guid is not null
--     and transaction_time_utc::date >= ''2024-10-01''
--     ) b
-- where a.guid = b.guid
-- ;



update business_intelligence.bridge.app_loan_production_new a
set
api_partner_decision = b.api_partner_decision
from
        (select
        x.app_id
        ,first_offer_decision_ts
        ,case when requested_loan_amt > max_offer_amt then ''Counteroffer''
                            when max_offer_amt is not null then ''Conditional Approval''
                            when max_offer_amt is null and (first_offer_decision is null or first_offer_decision = ''Decline'') then ''Decline''
                            when max_offer_amt is null and first_offer_decision = ''Credit Freeze'' and current_date::date - first_offer_decision_ts::date <= 7 then ''Pending - Credit Freeze''
                            when max_offer_amt is null and (first_offer_decision in (''Credit Freeze'',''Retry System Failure'')) then ''Decline - ''||trim(first_offer_decision)
                            else null end as api_partner_decision
        from business_intelligence.bridge.app_loan_production_new x
        left join business_intelligence.bridge.app_note_title_first y
        on x.app_id = y.app_id
        where funnel_type = ''API''
        ) b
where a.app_id = b.app_id
;

update business_intelligence.bridge.app_loan_production_new a
set
counter_off_yn = case when b.app_id is not null then ''Y'' else ''N'' end
from
        (select
        a.applicant_id as app_id
        ,a.requested_loan_amount
        ,b.finaldecision
        from
                    (select distinct
                    applicant_id
                    ,first_value(source) over (partition by applicant_id order by created_at desc) as source
                    ,(first_value(requested_loan_amount) over (partition by applicant_id order by created_at desc))::numeric(10,2) as requested_loan_amount
                    ,first_value(request_id) over (partition by applicant_id order by created_at desc) as request_id
                    from business_intelligence.analytics.vw_applicants_current  --Oscilar CP Workflow
                    where request_intent = ''soft_pull''
                    ) a
        join business_intelligence.analytics.vw_decisions_current  b            --Oscilar CP Workflow
        on a.applicant_id = b.applicant_id
                        and a.request_id = b.requestid
                        and a.source = b.source
                        and b.source_system = ''KF''
        ) b
where a.app_id = b.app_id
and trim(upper(b.finaldecision)) = ''COUNTEROFFER''
;

delete from business_intelligence.bridge.app_loan_production_new where email ilike ''%HAPPYMONEY%''
;


delete from business_intelligence.bridge.app_loan_production where app_id in (select distinct app_id from business_intelligence.bridge.apps_to_upsert);
insert into business_intelligence.bridge.app_loan_production select * from business_intelligence.bridge.app_loan_production_new;


/*use this condition if need to rebuild history for any table changes / additions*/
/*********************************************************************************
create or replace table business_intelligence.bridge.app_loan_production copy grants as
select * from business_intelligence.bridge.app_loan_production_new;
**********************************************************************************/

update business_intelligence.bridge.app_loan_production a
set
app_status = b.loan_sub_status
from
        (select distinct
        a.loan_id as app_id
        ,b.loan_sub_status
        from business_intelligence.bridge.vw_loan_settings_entity_current a
        left join
                    (select distinct
                    title as loan_sub_status
                    ,id::varchar(10) as id
                    ,deleted as deleted_sub_status
                    from raw_data_store.loanpro.loan_sub_status_entity
                    where schema_name = config.los_schema()
                    ) b
        on a.loan_sub_status_id = b.id
        where a.schema_name = config.los_schema()
        ) b
where a.app_id = b.app_id
;

create or replace table business_intelligence.bridge.app_guid_dupes copy grants as
-- select
-- guid
-- ,max(case when esign_ts is not null then app_id else null end) as esign_app_id
-- ,min(app_id) as min_app_id
-- ,min(app_ts) as min_app_ts
-- ,max(app_ts) as max_app_ts
-- ,count(*) as dupe_cnt
-- from
--         (select distinct
--         app_id
--         ,guid
--         ,app_ts
--         ,esign_ts
--         ,from business_intelligence.bridge.app_loan_production
--         ) x
-- group by all
-- having count(*) > 1
-- ;
select
*
from
        (select
        guid
        ,app_ts
        ,app_id
        ,a.app_status
        ,guid_dupe_yn
        ,rank as app_status_rank
        ,row_number() over (partition by guid order by app_status_rank desc, app_ts, app_id) as row_nbr
        from business_intelligence.bridge.app_loan_production a
        left join business_intelligence.analytics.ref_app_status_order b
        on a.app_status = b.app_status
        where guid in
                    (select distinct
                    guid
                    from
                            (select
                            guid
                            ,count(*) as dupe_cnt
                            from
                                    (select distinct
                                    app_id
                                    ,guid
                                    ,from business_intelligence.bridge.app_loan_production
                                    ) x
                            group by all
                            having count(*) > 1
                            ) y
                    )
        )
where row_nbr = 1
;

update business_intelligence.bridge.app_loan_production a
set
guid_dupe_yn = ''N''
where guid_dupe_yn = ''Y''
;

update business_intelligence.bridge.app_loan_production a
set
guid_dupe_yn = case     when b.guid is not null and a.app_id = b.app_id then ''N''
                        -- when b.guid is not null and a.app_id = b.min_app_id and b.esign_app_id is null then ''N''
                        when b.guid is not null then ''Y''
                        else ''N'' end
from business_intelligence.bridge.app_guid_dupes b
where a.guid = b.guid
;

--clears all loan fields when there is a decline or withdrawl post esign
update business_intelligence.bridge.app_loan_production a
set
esign_ts = null
,originated_ts = null
,originated_dt = null
,loan_amt = null
,orig_fee_amt = null
,orig_fee_prct = null
,prem_fee_amt = null
,prem_fee_prct = null
,term = null
,apr_prct = null
,int_rate_prct = null
,monthly_payment_amt = null
,source_company = null
,capital_partner = null

from
        (select distinct
        app_id
        from business_intelligence.bridge.app_loan_production
        where declined_ts > esign_ts or withdrawn_ts > esign_ts or (app_status = ''Expired'' and esign_ts is not null)
        ) b
where a.app_id = b.app_id
;


/*
select last_day(app_dt), count(*), ''BR'' from business_intelligence.bridge.app_loan_production group by all
union all
select last_day(app_dt), count(*), ''CS'' from business_intelligence.cron_store.app_loan_production group by all
order by 1,2
*/

drop table business_intelligence.bridge.app_loan_prod_starts;
drop table business_intelligence.bridge.apps_to_upsert;
drop table business_intelligence.bridge.app_note_title_first;
drop table business_intelligence.bridge.app_note_title_last;
drop table business_intelligence.bridge.app_status_transition_short;
drop table business_intelligence.bridge.lp_app_pii_short;
drop table business_intelligence.bridge.app_income_review;
drop table business_intelligence.bridge.app_fraud_declines;
drop table business_intelligence.bridge.app_agent_processing_actions;
drop table business_intelligence.bridge.app_guid_dupes;
drop table business_intelligence.bridge.app_system_note_entity_short_new;
drop table business_intelligence.bridge.app_loan_production_new;
drop table business_intelligence.bridge.lms_loan_setup;

RETURN ''Procedure Executed Successfully.'';
END;
';