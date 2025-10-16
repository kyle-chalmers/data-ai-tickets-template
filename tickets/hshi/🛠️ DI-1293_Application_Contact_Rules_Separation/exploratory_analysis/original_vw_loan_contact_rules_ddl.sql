create or replace view BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES(
	APPLICATION_GUID,
	LOAN_ID,
	CEASE_AND_DESIST,
	SUPPRESS_PHONE,
	SUPPRESS_EMAIL,
	SUPPRESS_LETTER,
	SUPPRESS_TEXT,
	CONTACT_RULE_START_DATE,
	CONTACT_RULE_END_DATE,
	SOURCE
) as
with base as (
    select 
        al.guid as application_guid, 
        lrc.loan_id,
        lrc.cease_and_desist,
        lrc.suppress_phone,
        lrc.suppress_email,
        lrc.suppress_letter,
        lrc.suppress_text,
        lrc.contact_rule_start_date,
        lrc.contact_rule_end_date,
        lrc.source
    from BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CONTACT_RULES lrc
    left join BUSINESS_INTELLIGENCE.bridge.APP_LOAN_PRODUCTION al
        on lrc.loan_id::string = al.loan_id::string
),
sms_consent as (
    select 
        a.application_guid,
        a.loan_id,
        null as cease_and_desist,
        null as suppress_phone,
        null as suppress_email,
        null as suppress_letter,
        case when sms_consent_ls = 'NO' then true end as suppress_text,
        current_timestamp() as contact_rule_start_date,
        null as contact_rule_end_date,
        'LOANPRO' as source
    from BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT a
    where sms_consent_ls = 'NO'
)
select 
    coalesce(b.application_guid, s.application_guid) as application_guid,
    coalesce(b.loan_id::string, s.loan_id::string) as loan_id,
    coalesce(b.cease_and_desist, s.cease_and_desist) as cease_and_desist,
    coalesce(b.suppress_phone, s.suppress_phone) as suppress_phone,
    coalesce(b.suppress_email, s.suppress_email) as suppress_email,
    coalesce(b.suppress_letter, s.suppress_letter) as suppress_letter,
    case 
        when s.application_guid is not null then true
        else b.suppress_text
    end as suppress_text,
    case 
        when s.application_guid is not null then current_timestamp()
        else b.contact_rule_start_date
    end as contact_rule_start_date,
    coalesce(b.contact_rule_end_date, s.contact_rule_end_date) as contact_rule_end_date,
    coalesce(b.source, s.source) as source
from base b
full outer join sms_consent s
    on b.loan_id::string = s.loan_id::string;