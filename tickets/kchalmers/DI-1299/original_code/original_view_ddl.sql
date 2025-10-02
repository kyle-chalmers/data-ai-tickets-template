create or replace view VW_DSH_OUTBOUND_GENESYS_OUTREACHES(
	ASOFDATE,
	LOANSTATUS,
	PORTFOLIONAME,
	PORTFOLIOID,
	ALL_ACTIVE_LOANS,
	DQ_COUNT,
	CALL_LIST,
	CALL_ATTEMPTED,
	CONNECTIONS,
	VOICEMAILS_ATTEMPTED,
	VOICEMAILS_LEFT,
	RPCS,
	PTPS,
	OTPS,
	CONVERSIONS,
	TEXT_LIST,
	TEXTS_SENT,
	TEXT_RPCS,
	TEXT_PTPS,
	TEXT_OTPS,
	TEXT_CONVERSIONS,
	EMAILS_SENT,
	GR_EMAIL_LIST
) as
/********************************************************************************************
DQS CTE PURPOSE:
To collect the delinquent population for all portfolios and divide it up into categories that
can be later used for filtering purposes.
********************************************************************************************/
WITH dqs AS (SELECT DATE(asofdate)                                    AS ASOFDATE,
                    CASE
                        WHEN dlt.status = 'Current' AND to_number(dlt.dayspastdue) < 3 THEN 'Current'
                        WHEN to_number(dlt.dayspastdue) >= 3 AND to_number(dlt.dayspastdue) < 15 THEN 'DPD3-14'
                        WHEN to_number(dlt.dayspastdue) >= 15 AND to_number(dlt.dayspastdue) < 30 THEN 'DPD15-29'
                        WHEN to_number(dlt.dayspastdue) >= 30 AND to_number(dlt.dayspastdue) < 60 THEN 'DPD30-59'
                        WHEN to_number(dlt.dayspastdue) >= 60 AND to_number(dlt.dayspastdue) < 90 THEN 'DPD60-89'
                        WHEN to_number(dlt.dayspastdue) >= 90 THEN 'DPD90+'
                        WHEN dlt.status = 'Sold' THEN 'Sold'
                        WHEN dlt.status = 'Paid in Full' THEN 'Paid in Full'
                        WHEN dlt.status = 'Charge off' THEN 'Charge off'
                        WHEN dlt.status = 'Debt Settlement' THEN 'Debt Settlement'
                        WHEN dlt.status = 'Cancelled' THEN 'Cancelled'
                        WHEN dlt.status IS NULL THEN 'Originated' END AS loanstatus,
                    portfolioname,
                    REPLACE(TO_CHAR(portfolioid), '.00000', '')       as portfolioid,
                    COUNT(DISTINCT loanid)                            AS all_active_loans,
                    COUNT(DISTINCT CASE
                                       WHEN loanstatus IN ('DPD90+', 'DPD60-89', 'DPD30-59', 'DPD15-29', 'DPD3-14')
                                           THEN loanid
                                       ELSE NULL END)                 AS dq_count
             FROM ""BUSINESS_INTELLIGENCE"".""DATA_STORE"".""MVW_LOAN_TAPE_DAILY_HISTORY"" AS dlt
             WHERE status NOT IN ('Sold', 'Charge off', 'Paid in Full', 'Debt Settlement', 'Cancelled')
               AND DATE(asofdate) >= DATE((Select MIN(DATE(DATEADD('day', -1, record_insert_date)))
                                           from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
             GROUP BY 1, 2, 3, 4)
/********************************************************************************************
PHONE_CALL_BASE CTE PURPOSE:
To collect the data for what has been utilized for phone calls, and specifically for phone calls that
  are connected to an outbound list we want to call. The base of this query is BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
  which is the export location for the outbound lists from Genesys once they have been completed after the close of business for a certain
  day. They are inserted the day after they are called, which is why the day before the RECORD_INSERT_DATE is taken as the asofdate.
  Additionally, VW_PHONECALL_ACTIVITY is joined in 2 ways - by inin-outbound-id and by payoffuid & call date. The reason that this is done
  is because IF we made a call using the data from a call list, but did not call it in the dialer campaign, then it would not get picked up
  in the export. Manual calls made outside of campaigns are not associated with campaigns, so even though it was meant to be a part of this
  campaign, it would not have been noted as such. This double join - specifically the join by payoffuid and date, solves for that issue. That
  is why all of those values are coalesced together.
********************************************************************************************/
   , phone_calls as (select CASE
                                WHEN to_number(c.dayspastdue) < 3 THEN 'Current'
                                WHEN to_number(c.dayspastdue) >= 3 AND to_number(c.dayspastdue) < 15 THEN 'DPD3-14'
                                WHEN to_number(c.dayspastdue) >= 15 AND to_number(c.dayspastdue) < 30 THEN 'DPD15-29'
                                WHEN to_number(c.dayspastdue) >= 30 AND to_number(c.dayspastdue) < 60 THEN 'DPD30-59'
                                WHEN to_number(c.dayspastdue) >= 60 AND to_number(c.dayspastdue) < 90 THEN 'DPD60-89'
                                WHEN to_number(c.dayspastdue) >= 90 THEN 'DPD90+' END AS loanstatus,
                            c.PORTFOLIONAME,
                            DATE(LOADDATE)            as asofdate,
                            count(DISTINCT c.PAYOFFUID)                               as call_list,
                            count(distinct COALESCE(a.CONVERSATIONID, b.CONVERSATIONID))            as call_attempted,
                            COUNT(DISTINCT CASE
                                               WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IS NOT NULL
                                                   THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
                                               ELSE NULL END)                         AS connections,
                            COUNT(DISTINCT CASE
                                               WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN
                                                    ('Other::Left Message', 'Voicemail Not Set Up or Full')
                                                   THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
                                               ELSE NULL END)                         AS voicemails_attempted,
                            COUNT(DISTINCT CASE
                                               WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) =
                                                    'Other::Left Message' THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
                                               ELSE NULL END)                         AS voicemails_left,
                            COUNT(DISTINCT CASE
                                               WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
                                                   THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
                                               ELSE NULL END)                         AS RPCs,
                            COUNT(DISTINCT CASE
                                               WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN
                                                    ('MBR::DPD::Promise to Pay (PTP)',
                                                     'MBR::Payment Requests::ACH Retry',
                                                     'MBR::Payment Type Change::Manual to ACH')
                                                   THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
                                               ELSE NULL END)                         AS PTPs,
                            COUNT(DISTINCT CASE
                                               WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) =
                                                    'MBR::Payment Requests::One Time Payments (OTP)'
                                                   THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
                                               ELSE NULL END)                         AS OTPs,
                            PTPs + OTPs                                               AS conversions
                     from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
                              left join BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY a
                                        on a.""inin-outbound-id"" = c.""inin-outbound-id"" and
                                           DATE(a.INTERACTION_START_TIME) >=
                                           DATE((Select MIN(DATE(LOADDATE))
                                                 from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
                              left join BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY b
                                        on c.PAYOFFUID = b.PAYOFFUID and
                                           DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE) and
                                           b.ORIGINATINGDIRECTION = 'outbound' and b.CALL_DIRECTION = 'outbound' and
                                           c.""CallRecordLastAttempt-PHONE"" is null and
                                           DATE(b.INTERACTION_START_TIME) >=
                                           DATE((Select MIN(DATE(LOADDATE))
                                                 from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
                     where c.CHANNEL = 'Phone'
                     group by c.PORTFOLIONAME, asofdate, loanstatus)
/********************************************************************************************
sent_texts CTE PURPOSE:
The explanation for this CTE is exactly the same as the above for the phone_call_base, however it
  is for outbound texts and to incorporate them into outreaches. Please read the above, but replace phone calls with texts, and then you will understand this
  query as well.
********************************************************************************************/
   , sent_texts as (select c.PORTFOLIONAME,
                           CASE
                               WHEN to_number(c.dayspastdue) < 3 THEN 'Current'
                               WHEN to_number(c.dayspastdue) >= 3 AND to_number(c.dayspastdue) < 15 THEN 'DPD3-14'
                               WHEN to_number(c.dayspastdue) >= 15 AND to_number(c.dayspastdue) < 30 THEN 'DPD15-29'
                               WHEN to_number(c.dayspastdue) >= 30 AND to_number(c.dayspastdue) < 60 THEN 'DPD30-59'
                               WHEN to_number(c.dayspastdue) >= 60 AND to_number(c.dayspastdue) < 90 THEN 'DPD60-89'
                               WHEN to_number(c.dayspastdue) >= 90 THEN 'DPD90+' END AS loanstatus,
                           DATE(DATEADD('day', -1, c.RECORD_INSERT_DATE))            as asofdate,
                           count(*)                                                  as text_list,
                           count(coalesce(a.CONVERSATIONID, b.CONVERSATIONID))       as texts_sent,
                           COUNT(CASE
                                     WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
                                         THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
                                     ELSE NULL END)                                  AS text_RPCs,
                           COUNT(CASE
                                     WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN
                                          ('MBR::DPD::Promise to Pay (PTP)', 'MBR::Payment Requests::ACH Retry',
                                           'MBR::Payment Type Change::Manual to ACH')
                                         THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
                                     ELSE NULL END)                                  AS text_PTPs,
                           COUNT(CASE
                                     WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) =
                                          'MBR::Payment Requests::One Time Payments (OTP)'
                                         THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
                                     ELSE NULL END)                                  AS text_OTPs,
                           text_PTPs + text_OTPs                                     AS text_conversions
                    from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
                             left join BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY a
                                       on a.""inin-outbound-id"" = c.""inin-outbound-id"" and
                                          DATE(a.INTERACTION_START_TIME) >=
                                          DATE((Select MIN(DATE(DATEADD('day', -1, record_insert_date)))
                                                from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
                             left join BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY b
                                       on c.PAYOFFUID = b.PAYOFFUID and DATE(b.INTERACTION_START_TIME) =
                                                                        DATE(DATEADD('day', -1, c.record_insert_date)) and
                                          b.ORIGINATINGDIRECTION = 'outbound' and c.""SmsLastAttempt-PHONE"" is null and
                                          DATE(b.INTERACTION_START_TIME) >=
                                          DATE((Select MIN(DATE(DATEADD('day', -1, record_insert_date)))
                                                from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
                    where c.CHANNEL = 'Text'
                    group by c.PORTFOLIONAME, loanstatus, asofdate)
,subscriber_key_matching as (SELECT vlcc.CUSTOMER_ID,
       vlcc.LOAN_ID as APPLICATION_ID,
       va.APPLICATION_GUID
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT VLCC
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT VA
ON VA.LOAN_ID::VARCHAR = VLCC.LOAN_ID::VARCHAR
where VLCC.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
qualify row_number() over (partition by vlcc.CUSTOMER_ID order by ORIGINATION_DATE desc, APPLICATION_STARTED_DATE desc) = 1)
/********************************************************************************************
new_sent_email_source CTE PURPOSE:
This data utilizes the actual source of the emails sent everyday from SFMC. Please note that this data source is not perfect
  as it is approximating the matches of an email to a loan, so it suffers from the problem that we cannot accurately map every
  email we send to a loan with the output from SFMC that is returned back to us through Fivetran. However, Tin Nguyen built a
  data source off of SFMC that is attempting to approximate the PayoffUID associated with an email within this job
  and the output table from that () is being utilized here.
  Please note that email names do indicate the DPD of a loan since the loans from the email lists are match onto a campaign
  for this, therefore they are utilize within the criteria for matching a loan's DPD, since at the time they were placed onto
  the campaign they had to have the corresponding DPD.
  Please note that SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_0-3Days_EM1_0823','GR_Batch_DLQ_PastDue_0-3Days_EM1_1123',
  'GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123') cannot be used in the same way the other email
  campaigns can because they do not correspond directly to the Days Past Due categories we have set up.
  TO DO: This will eventually be sunsetted once we transition emails to Genesys.
********************************************************************************************/
, emails_sent as (select sum(a.sent) as emails_sent,
       date(a.EVENT_DATE) as ASOFDATE,
CASE WHEN b.status = 'Current' AND to_number(b.dayspastdue) < 3 THEN 'Current'
                        WHEN (to_number(b.dayspastdue) >= 3 AND to_number(b.dayspastdue)< 15) OR
                            SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_4-14Days_EM1_0823','GR_Batch_DLQ_PastDue_4-14Days_EM1_1123',
'COL_Batch_DLQ_PastDue_3Days_EM1_0225','COL_Batch_DLQ_PastDue_5Days_EM2_0225','COL_Batch_DLQ_PastDue_10Days_EM3_0225','COL_Batch_DLQ_PastDue_15-29Days_EM4_0125','COL_Batch_DLQ_PastDue_5Days_EM2_0125'
,'COL_Batch_DLQ_PastDue_10Days_EM3_0125','COL_Batch_DLQ_PastDue_25Days_EM5_0125','COL_Batch_DLQ_PastDue_3Days_EM1_0125','12 GR_Batch_DLQ_PastDue_0-3Days_EM1_0824','GR_Batch_DLQ_PastDue_15-29Days_EM1_0824'
,'GR_Batch_DLQ_PastDue_3Days_EM1_0125' ,'GR_Batch_DLQ_PastDue_Day10_EM1_0824' ,'GR_Batch_DLQ_PastDue_Day25_EM1_0824','GR_Batch_DLQ_PastDue_Day5_EM1_0824')
OR ((to_number(b.dayspastdue) >= 3 AND to_number(b.dayspastdue)< 15) AND SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225'))--added new emails
                        THEN 'DPD3-14'
                        WHEN (to_number(b.dayspastdue) >= 15 AND to_number(b.dayspastdue) < 30) OR
                            SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_15-29Days_EM1_0823','GR_Batch_DLQ_PastDue_15-29Days_EM1_1123',
'COL_Batch_DLQ_PastDue_15-29Days_EM4_0225','COL_Batch_DLQ_PastDue_25Days_EM5_0225') --added new emails
OR ((to_number(b.dayspastdue) >= 15 AND to_number(b.dayspastdue)< 30) AND SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225'))
                            THEN 'DPD15-29'
                        WHEN (to_number(b.dayspastdue) >= 30 AND to_number(b.dayspastdue) < 60) OR
                             SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_45Days_EM1_1123','GR_Batch_DLQ_PastDue_45Days_EM1_0823','MKT_Batch_GR_PastDue_45Days_EM5_0523',
'GR_Batch_DLQ_PastDue_30-59Days_EM1_1123','GR_Batch_DLQ_PastDue_30-59Days_EM1_0823','COL_Batch_DLQ_PastDue_59Days_EM7_0225') --added new emails
OR ((to_number(b.dayspastdue) >= 30 AND to_number(b.dayspastdue)< 60) AND SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225'))
                             THEN 'DPD30-59'
WHEN SEND_TABLE_EMAIL_NAME IN ('COL_Adhoc_DLQ_PastDue_3-59Days_EM1_020725','COL_Adhoc_DLQ_PastDue_3-59Days_EM1_0225') THEN 'DPD3-14'
                        WHEN (to_number(b.dayspastdue) >= 60 AND to_number(b.dayspastdue) < 90)
                            OR (to_number(b.dayspastdue) >= 60 AND to_number(b.dayspastdue) < 90
                                    AND SEND_TABLE_EMAIL_NAME IN ('COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125'
,'COL_Batch_DLQ_PastDue_40-60Days_EM6_0225','GR_Batch_DLQ_PastDue_30-60Days_EM1_0824','COL_Batch_DLQ_PastDue_30-60Days_EM6_0225','COL_Batch_DLQ_PastDue_30-60Days_EM5_0125',
'GR_Batch_DLQ_PastDue_Day75_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125')) THEN 'DPD60-89'
                        WHEN (to_number(b.dayspastdue) >= 90
                                  AND SEND_TABLE_EMAIL_NAME IN ('COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125',
                                                                'GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123'))
                                 OR to_number(b.dayspastdue) >= 90
                             OR (b.status = 'Charge off' AND SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123',
                                                                                   'COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125'))
                            OR SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_60PlusDays_EM1_0823', 'GR_Batch_DLQ_PastDue_60PlusDays_EM1_1123')
                             THEN 'DPD90+'
           WHEN SEND_TABLE_EMAIL_NAME IN ('COL_Batch_DLQ_PastDue_40-60Days_EM6_0225','GR_Batch_DLQ_PastDue_30-60Days_EM1_0824','COL_Batch_DLQ_PastDue_30-60Days_EM6_0225','GR_Batch_DLQ_PastDue_Day75_EM1_0824'
,'COL_Batch_DLQ_PastDue_30-60Days_EM5_0125','COL_Batch_DLQ_PastDue_60Days_EM7_0225','GR_Batch_DLQ_PastDue_Day60_EM1_0824','COL_Batch_DLQ_PastDue_60Days_EM6_0125')
               THEN 'DPD60-89'
           WHEN b.status = 'Paid in Full' AND SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_0-3Days_EM1_0823','GR_Batch_DLQ_PastDue_0-3Days_EM1_1123')
                             THEN 'Current'
                        WHEN b.status = 'Sold' THEN 'Sold'
                        WHEN b.status = 'Paid in Full' THEN 'Paid in Full'
                        WHEN b.status = 'Charge off' THEN 'Charge off'
                        WHEN b.status = 'Debt Settlement' THEN 'Debt Settlement'
                        WHEN b.status = 'Cancelled' THEN 'Cancelled'
                        WHEN b.status IS NULL THEN 'Originated' END AS LOANSTATUS,
                         b.PORTFOLIONAME
from BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
left join subscriber_key_matching c
on a.SUBSCRIBER_KEY::VARCHAR = c.CUSTOMER_ID::VARCHAR
inner join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY b
on COALESCE(a.DERIVED_PAYOFFUID,c.APPLICATION_GUID) = b.PAYOFFUID and date(a.EVENT_DATE) = DATEADD('day',1,b.ASOFDATE)
group by b.PORTFOLIONAME, LOANSTATUS, date(a.EVENT_DATE)
having sum(a.SENT) > 0
order by date(a.EVENT_DATE) desc)
   , gr_email_lists as (select count(OL.PAYOFFUID)                                        AS gr_email_list,
                                          OL.LOAD_DATE                                               as ASOFDATE,
                                          CASE
                                              WHEN to_number(LT.dayspastdue) < 3 THEN 'Current'
                                              WHEN to_number(LT.dayspastdue) >= 3 AND to_number(LT.dayspastdue) < 15
                                                  THEN 'DPD3-14'
                                              WHEN to_number(LT.dayspastdue) >= 15 AND to_number(LT.dayspastdue) < 30
                                                  THEN 'DPD15-29'
                                              WHEN to_number(LT.dayspastdue) >= 30 AND to_number(LT.dayspastdue) < 60
                                                  THEN 'DPD30-59'
                                              WHEN to_number(LT.dayspastdue) >= 60 AND to_number(LT.dayspastdue) < 90
                                                  THEN 'DPD60-89'
                                              WHEN to_number(LT.dayspastdue) >= 90 THEN 'DPD90+' END AS loanstatus,
                                          LT.PORTFOLIONAME
                                   from BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST as OL
                                            inner join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY as LT
                                                       on OL.PAYOFFUID = LT.PAYOFFUID and OL.LOAN_TAPE_ASOFDATE = LT.ASOFDATE
                                   where OL.SET_NAME = 'GR Email'
                                   and OL.SUPPRESSION_FLAG = false
                                   GROUP BY LT.PORTFOLIONAME, loanstatus, OL.LOAD_DATE)
select dqs.*,
       coalesce(pc.call_list, 0)            as call_list,
       coalesce(pc.call_attempted, 0)       as call_attempted,
       coalesce(pc.connections, 0)          as connections,
       coalesce(pc.voicemails_attempted, 0) as voicemails_attempted,
       coalesce(pc.voicemails_left, 0)      as voicemails_left,
       coalesce(pc.RPCs, 0)                 as RPCs,
       coalesce(pc.PTPs, 0)                 as PTPs,
       coalesce(pc.OTPs, 0)                 as OTPs,
       coalesce(pc.conversions, 0)          as conversions,
       coalesce(st.text_list, 0)            as text_list,
       coalesce(texts_sent, 0)              as texts_sent,
       coalesce(text_RPCs, 0)               as text_RPCs,
       coalesce(text_PTPs, 0)               as text_PTPs,
       coalesce(text_OTPs, 0)               as text_OTPs,
       coalesce(text_conversions, 0)        as text_conversions,
       coalesce(es.emails_sent, 0)          as emails_sent,
       coalesce(el.gr_email_list, 0)        as gr_email_list
from dqs dqs
         left join phone_calls pc on dqs.PORTFOLIONAME = pc.PORTFOLIONAME and dqs.loanstatus = pc.loanstatus and
                                     dqs.ASOFDATE = pc.asofdate
         left join sent_texts st on dqs.PORTFOLIONAME = st.PORTFOLIONAME and dqs.loanstatus = st.loanstatus and
                                    dqs.ASOFDATE = st.asofdate
         left join emails_sent es on dqs.PORTFOLIONAME = es.PORTFOLIONAME and dqs.loanstatus = es.loanstatus and
                                     dqs.ASOFDATE = es.asofdate
         left join gr_email_lists el on dqs.PORTFOLIONAME = el.PORTFOLIONAME and dqs.loanstatus = el.loanstatus and
                                     dqs.ASOFDATE = el.asofdate;
