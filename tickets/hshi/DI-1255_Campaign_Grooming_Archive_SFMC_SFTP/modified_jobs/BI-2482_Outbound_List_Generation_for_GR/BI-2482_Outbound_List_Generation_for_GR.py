# Databricks notebook source
# MAGIC %sh
# MAGIC pip install sendgrid
# MAGIC pip install snowflake-connector-python==3.13.2
# MAGIC

# COMMAND ----------

dbutils.widgets.removeAll()
dbutils.widgets.dropdown("env", "dev", ["dev", "qa", "staging", "prod"])

ENV = dbutils.widgets.get("env")
print(ENV)

# COMMAND ----------

import pandas as pd
import snowflake.connector as sf
from pyspark.sql.functions import col
import os
import base64
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Attachment, FileContent, FileName, FileType, Disposition
import json
from datetime import date, timedelta

# COMMAND ----------

# Snowflake connection 
sf_options = {"sfUrl" : "happymoney.us-east-1.snowflakecomputing.com",
              "sfUser" : dbutils.secrets.get("snowflake_bi_pii", "username"),
              "sfPassword" : dbutils.secrets.get("snowflake_bi_pii", "password"),
              "sfRole": "BUSINESS_INTELLIGENCE_TOOLS_PII",
              "sfDatabase" : "BUSINESS_INTELLIGENCE",
              "sfSchema" : "CRON_STORE",
              "sfWarehouse" : "BUSINESS_INTELLIGENCE_LARGE"     
             }

# Snowflake connection for DML
sfUtils = sc._jvm.net.snowflake.spark.snowflake.Utils

# COMMAND ----------

def send_email(sender, recipients, subject, html_body, text_fallback=None, attachments=None):
  # Attachment type is hard-coded as .csv
  message = Mail(
      from_email=sender,
      to_emails=recipients,
      subject=subject,
      html_content=html_body,
      plain_text_content=text_fallback or " "
  )

  if attachments:
      for attachment_path in attachments:
          with open(attachment_path, "rb") as f:
              encoded = base64.b64encode(f.read()).decode()

          # Use a sane default MIME; you can branch by extension if needed
          ext = os.path.splitext(attachment_path)[1].lower()
          mime = "text/csv" if ext == ".csv" else "application/octet-stream"

          attachment = Attachment(
              FileContent(encoded),
              FileName(os.path.basename(attachment_path)),
              FileType(mime),
              Disposition("attachment"),
          )
          message.add_attachment(attachment)

  try:
      sg = SendGridAPIClient(dbutils.secrets.get("sendgrid", "api"))
      response = sg.send(message)
      print("Email sent successfully!")
      print(response.status_code)
      print(response.body)
      print(response.headers)
  except Exception as e:
      print("Email sending failed.")
      print(str(e))

# COMMAND ----------

## **************** 1. Preparation **************** ##

# 1.1 Check loan tape
query = '''
select PAYOFFUID from DATA_STORE.MVW_LOAN_TAPE
where ASOFDATE = dateadd(day, -1, current_date)
limit 1
'''
query_construct = (spark
    .read
    .format("snowflake")
    .options(**sf_options)
    .option("query", query)
    .load())
lt_check = query_construct.toPandas()

if lt_check.empty:
    # Send email
    sender = 'biteam@happymoney.com'
    recipients = ['bma@happymoney.com', 'goalrealignment_managers@happymoney.com'] if ENV == 'prod' else ['bma@happymoney.com']
    email_subject = "Call List job failed " + str(date.today())
    email_body = 'Loan tape data not up-to-date. Call list did not load.'

    send_email(sender, recipients, email_subject, email_body)

    raise SystemExit("Loan tape data not up-to-date.")

# 1.2 SST Alert (Remove once SST has DQ loans)
query = '''
with SST as
         (select L.LEAD_GUID as PAYOFFUID,
                 L.LOAN_ID
          from ANALYTICS.VW_LOAN as L
                   inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
                              on L.LOAN_ID = LP.LOAN_ID::string
                                  and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                                  and LP.PORTFOLIO_ID = 205)
select LT.LOANID as DISPLAY_ID,
       SST.LOAN_ID
from DATA_STORE.MVW_LOAN_TAPE as LT
         inner join SST
                    on LT.PAYOFFUID = SST.PAYOFFUID
                        and not ((STATUS = 'Current' and DAYSPASTDUE < 3) or
                                 STATUS in ('Paid in Full', 'Sold', 'Charge off'))
'''
query_construct = (spark
    .read
    .format("snowflake")
    .options(**sf_options)
    .option("query", query)
    .load())
sst_check = query_construct.toPandas()

if not sst_check.empty:
    # Keep only the columns you want and (optionally) rename headers
    df = sst_check[['DISPLAY_ID', 'LOAN_ID']].rename(
        columns={'DISPLAY_ID': 'Display ID', 'LOAN_ID': 'Loan ID'}
    )

    MAX_ROWS = 50
    shown = df.head(MAX_ROWS)
    note_html = ""
    note_text = ""
    if len(df) > MAX_ROWS:
        note_html = f"<p><em>Showing first {MAX_ROWS} of {len(df)} rows.</em></p>"
        note_text = f"\n\n(Showing first {MAX_ROWS} of {len(df)} rows.)"

    # Create a clean HTML table
    # We use to_html and then add inline styles that survive most email clients
    base_table = shown.to_html(index=False, border=0, justify='left', escape=True)
    styled_table = (
        base_table
        .replace('<table border="0" class="dataframe">', '<table style="border-collapse:collapse; width:100%; max-width:900px;">')
        .replace('<th>', '<th style="text-align:left; padding:8px; border:1px solid #ddd; background:#f6f6f6;">')
        .replace('<td>', '<td style="padding:8px; border:1px solid #ddd;">')
    )

    html_email_body = f"""
    <html>
      <body style="font-family: Arial, Helvetica, sans-serif; font-size:14px; color:#222;">
        <p>There should be records in today's SST DQ call list. The list should be uploaded to Genesys. Please confirm.</p>
        {note_html}
        {styled_table}
      </body>
    </html>
    """

    text_fallback = (
        "There should be records in today's SST DQ call list. "
        "The list should be uploaded to Genesys. Please confirm.\n\n"
        + shown.to_string(index=False)
        + note_text
    )

    sender = 'biteam@happymoney.com'
    recipients = (
        ['bma@happymoney.com', 'hdavis@happymoney.com', 'jkohrumel@happymoney.com', 'lcarney@happymoney.com']
        if ENV == 'prod' else ['bma@happymoney.com']
    )
    subject = 'SST DQ Loans Alert'

    send_email(
        sender=sender,
        recipients=recipients,
        subject=subject,
        html_body=html_email_body,
        text_fallback=text_fallback,
        attachments=None  # or a list of file paths
    )



# COMMAND ----------

## **************** 2. Segmentation **************** ##
sfUtils.runQuery(sf_options, '''
delete
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME in ('Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly', 'SIMM', 'SST')
''')

## 2.1 Call List
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
with SST as
         (select L.LEAD_GUID as PAYOFFUID
          from ANALYTICS.VW_LOAN as L
                   inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
                              on L.LOAN_ID = LP.LOAN_ID::string
                                  and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                                  and LP.PORTFOLIO_ID = 205)
select current_date as LOAD_DATE,
       'Call List'  as SET_NAME,
       case
           when CHARGEOFFDATE is not null then 'Charge off'
           when PORTFOLIONAME = 'Payoff FBO Blue Federal Credit Union' and DAYSPASTDUE < 90 then 'Blue'
           when PORTFOLIONAME in ('Payoff FBO USAlliance Federal Credit Union',
                                  'Payoff FBO Michigan State University Federal Credit Union') and
                DAYSPASTDUE < 90
               then 'Due Diligence DPD3-89'
           when DAYSPASTDUE between 3 and 14 then 'DPD3-14'
           when DAYSPASTDUE between 15 and 29 then 'DPD15-29'
           when DAYSPASTDUE between 30 and 59 then 'DPD30-59'
           when DAYSPASTDUE between 60 and 89 then 'DPD60-89'
           when DAYSPASTDUE >= 90 then 'DPD90+'
           else 'Exclude'
           end      as LIST_NAME,
       PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       ASOFDATE     as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold'))
  and LIST_NAME <> 'Exclude'
  and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
  and PAYOFFUID not in (select SST.PAYOFFUID from SST)
''')

## 2.2 Remitter
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
with SST as
         (select L.LEAD_GUID as PAYOFFUID
          from ANALYTICS.VW_LOAN as L
                   inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
                              on L.LOAN_ID = LP.LOAN_ID::string
                                  and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                                  and LP.PORTFOLIO_ID = 205)
select current_date     as LOAD_DATE,
       'Remitter'       as SET_NAME,
       'DPD60+ Min Pay' as LIST_NAME,
       PAYOFFUID,
       false            as SUPPRESSION_FLAG,
       ASOFDATE         as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where DAYSPASTDUE >= 60
  and STATUS not in ('Paid in Full', 'Sold', 'Charge off')
  and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
  and PAYOFFUID not in (select SST.PAYOFFUID from SST)
''')

## 2.3 SMS
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
select current_date as LOAD_DATE,
       'SMS'        as SET_NAME,
       case
           when LT.DAYSPASTDUE = 17 and LT.ORIGINATIONDATE > '2023-01-23' then 'TruStage DPD17'
           when LT.DAYSPASTDUE = 33 and LT.ORIGINATIONDATE > '2023-01-23' then 'TruStage DPD33'
           when datediff(day, LT.ASOFDATE, LT.NEXTPAYMENTDUEDATE) = 4 then 'Payment Reminder'
           when datediff(day, LT.ASOFDATE, LT.NEXTPAYMENTDUEDATE) = 1 then 'Due Date'
           when LT.DAYSPASTDUE = 3 then 'DPD3'
           when LT.DAYSPASTDUE = 6 then 'DPD6'
           when LT.DAYSPASTDUE = 8 then 'DPD8'
           when LT.DAYSPASTDUE = 11 then 'DPD11'
           when LT.DAYSPASTDUE = 15 then 'DPD15'
           when LT.DAYSPASTDUE = 17 then 'DPD17'
           when LT.DAYSPASTDUE = 21 then 'DPD21'
           when LT.DAYSPASTDUE = 23 then 'DPD23'
           when LT.DAYSPASTDUE = 25 then 'DPD25'
           when LT.DAYSPASTDUE = 28 then 'DPD28'
           when LT.DAYSPASTDUE = 33 then 'DPD33'
           when LT.DAYSPASTDUE = 38 then 'DPD38'
           when LT.DAYSPASTDUE = 44 then 'DPD44'
           else 'Exclude'
           end      as LIST_NAME,
       LT.PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       LT.ASOFDATE  as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE as LT
where LT.STATUS <> 'Charge off'
  and LIST_NAME <> 'Exclude'
  and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')
''')

## 2.4 GR Email
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
select current_date as LOAD_DATE,
       'GR Email'   as SET_NAME,
       'GR Email'   as LIST_NAME,
       PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       ASOFDATE     as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
''')

## 2.5 GR Physical Mail - ARCHIVED (DI-1255)
# Campaign confirmed inactive - code removed

## 2.6 Recovery Weekly (every Tuesday)
if date.today().weekday() == 1:
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS
  select current_date            as LOAD_DATE,
        'Recovery Weekly' as SET_NAME,
        'Recovery Weekly' as LIST_NAME,
        PAYOFFUID,
        false                   as SUPPRESSION_FLAG,
        ASOFDATE                as LOAN_TAPE_ASOFDATE
  from DATA_STORE.MVW_LOAN_TAPE
  where STATUS = 'Charge off'
    and datediff(day, CHARGEOFFDATE, ASOFDATE) <= 7
    and RECOVERIESPAIDTODATE = 0
  ''')

## 2.7 Recovery Monthly Email - ARCHIVED (DI-1255)
# Campaign confirmed inactive - code removed

## 2.8 SIMM
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
with SST as
         (select L.LEAD_GUID as PAYOFFUID
          from ANALYTICS.VW_LOAN as L
                   inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
                              on L.LOAN_ID = LP.LOAN_ID::string
                                  and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                                  and LP.PORTFOLIO_ID = 205)
select current_date as LOAD_DATE,
       'SIMM'       as SET_NAME,
       'DPD3-119'   as LIST_NAME,
       PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       ASOFDATE     as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  and substring(PAYOFFUID, 16, 1) in ('8', '9', 'a', 'b', 'c', 'd', 'e', 'f')
  and PAYOFFUID not in (select SST.PAYOFFUID from SST)
''')

## 2.9 SST
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
with SST as
         (select L.LEAD_GUID as PAYOFFUID
          from ANALYTICS.VW_LOAN as L
                   inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
                              on L.LOAN_ID = LP.LOAN_ID::string
                                  and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                                  and LP.PORTFOLIO_ID = 205)
select current_date as LOAD_DATE,
       'SST'        as SET_NAME,
       'DPD3-119'   as LIST_NAME,
       PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       ASOFDATE     as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  and PAYOFFUID in (select SST.PAYOFFUID from SST)
''')



# COMMAND ----------

## **************** 3. Suppression **************** ##
sfUtils.runQuery(sf_options, '''
delete
from CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
where SUPPRESSION_REASON in (
                             -- Global Suppression
                             'Bankruptcy', 'Cease & Desist', 'OTP', 'Loan Mod','Inaccurate Information due to LoanPro Migration',
                             'Natural Disaster', 'Individual Suppression', 'Next Workable Date After Today',
                             '3rd Party Post Charge Off Placement', 'Loan Account Marked for Closure',
                             -- Set Level Suppression
                             'State Regulation: Minnesota', 'State Regulation: Massachusetts', 'State Regulation: DC',
                             'DNC: Phone', 'DNC: Text', 'DNC: Letter', 'DNC: Email', 'Delinquent Amount Zero',
                             -- List Level and Cross Set Suppression
                             'Phone Test', 'Autopay', 'Remitter'
    )       
''')

## 3.1 Global suppression
# Bankruptcy (This can be removed after fully migrated out of CLS)
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Global'     as SUPPRESSION_TYPE,
       'Bankruptcy'  as SUPPRESSION_REASON,
       PAYOFF_UID,
       'N/A'        as SET_NAME,
       'N/A'        as LIST_NAME
from DATA_STORE.VW_LOAN_COLLECTION
where BANKRUPTCY_FLAG = 'Y'
''')

# Cease & Desist
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date     as LOAD_DATE,
       'Global'         as SUPPRESSION_TYPE,
       'Cease & Desist' as SUPPRESSION_REASON,
       L.LEAD_GUID      as PAYOFF_UID,
       'N/A'            as SET_NAME,
       'N/A'            as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
where LCR.CEASE_AND_DESIST = true
''')

# NEXT WORK DATE
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                     as LOAD_DATE,
       'Global'                         as SUPPRESSION_TYPE,
       'Next Workable Date After Today' as SUPPRESSION_REASON,
       L.LEAD_GUID                      as PAYOFF_UID,
       'N/A'                            as SET_NAME,
       'N/A'                            as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT as CUS
                    on L.LOAN_ID = CUS.LOAN_ID::string
where CUS.NEXT_WORKABLE_DATE > current_date
and substring(L.LEAD_GUID, 16, 1) not in ('8', '9', 'a', 'b', 'c', 'd', 'e', 'f')
''')


# OTP (This can be removed after fully migrated out of CLS)
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
with PMT as (select PAYOFF_UID
             from DATA_STORE.VW_ONE_TIME_PAYMENT_REQUESTS
             where EFFECTIVE_DATE >= current_date
               and STATUS <> 'deleted'
             union
             select PAYOFF_UID
             from DATA_STORE.VW_MANUAL_BILL_PAYMENT_REQUESTS
             where SELECTED_DATE >= current_date
               and STATUS <> 'deleted')
select current_date as LOAD_DATE,
       'Global'     as SUPPRESSION_TYPE,
       'OTP'        as SUPPRESSION_REASON,
       PAYOFF_UID,
       'N/A'        as SET_NAME,
       'N/A'        as LIST_NAME
from PMT
''')

# Loan Modification
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Global'     as SUPPRESSION_TYPE,
       'Loan Mod'   as SUPPRESSION_REASON,
       LT.PAYOFFUID,
       'N/A'        as SET_NAME,
       'N/A'        as LIST_NAME
from DATA_STORE.VW_SURVEYMONKEY_RESPONSES as LM
         inner join DATA_STORE.MVW_LOAN_TAPE as LT
                    on LM.PAYOFFUID = LT.PAYOFFUID
where LM.SURVEY_LAST_UPDATED_DATETIME_PST >= dateadd(day, -3, current_date)
  and LM.SURVEY_NAME = 'Loan Modification Request Survey'
  and LM.RESPONSE_STATUS = 'completed'
  and substring(LT.PAYOFFUID, 16, 1) not in ('8', '9', 'a', 'b', 'c', 'd', 'e', 'f')
''')

# Natural Disaster
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date       as LOAD_DATE,
       'Global'           as SUPPRESSION_TYPE,
       'Natural Disaster' as SUPPRESSION_REASON,
       LT.PAYOFFUID,
       'N/A'              as SET_NAME,
       'N/A'              as LIST_NAME
from DATA_STORE.MVW_LOAN_TAPE as LT
         inner join ANALYTICS.VW_LOAN as L
                    on LT.PAYOFFUID = L.LEAD_GUID
         inner join ANALYTICS_PII.VW_MEMBER_PII as CI
                    on L.MEMBER_ID = CI.MEMBER_ID
                        and CI.MEMBER_PII_END_DATE is null
where CI.ZIP_CODE in (select ZIP
                      from CRON_STORE.LKP_GR_ND_SUPPRESSION
                      where SUPPRESSEDDATE <= current_date
                        and EXPIREDDATE >= current_date)
''')

# Individual Suppression
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date             as LOAD_DATE,
       'Global'                 as SUPPRESSION_TYPE,
       'Individual Suppression' as SUPPRESSION_REASON,
       PAYOFFUID,
       'N/A'                    as SET_NAME,
       'N/A'                    as LIST_NAME
from CRON_STORE.LKP_GR_INDIVIDUAL_SUPPRESSION
where SUPPRESSEDDATE <= current_date
  and EXPIREDDATE >= current_date
''')


# Placement with 3rd Party Post CO Suppression (The first part can be removed after fully migrated out of CLS)
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                          as LOAD_DATE,
       'Global'                              as SUPPRESSION_TYPE,
       '3rd Party Post Charge Off Placement' as SUPPRESSION_REASON,
       lower(VLA.LEAD_GUID)                  as PAYOFFUID,
       'N/A'                                 as SET_NAME,
       'N/A'                                 as LIST_NAME
from BUSINESS_INTELLIGENCE.DATA_STORE.VW_LOAN_ACCOUNT VLA
         inner join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE MLT
                    on MLT.PAYOFFUID = lower(VLA.LEAD_GUID)
where VLA.PLACEMENT_STATUS in
      ('Placed - ARS', 'Placed - First Tech Credit Union', 'Placed - Remitter (Post-CO)', 'Placed - TrueAccord',
       'Placed - Resurgent')
  and MLT.STATUS = 'Charge off'

union

select current_date                          as LOAD_DATE,
       'Global'                              as SUPPRESSION_TYPE,
       '3rd Party Post Charge Off Placement' as SUPPRESSION_REASON,
       LT.PAYOFFUID                          as PAYOFFUID,
       'N/A'                                 as SET_NAME,
       'N/A'                                 as LIST_NAME
from DATA_STORE.MVW_LOAN_TAPE as LT
         inner join ANALYTICS.VW_LOAN as L
                    on LT.PAYOFFUID = L.LEAD_GUID
         inner join BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT as CUS
                    on L.LOAN_ID = CUS.LOAN_ID::string
where CUS.PLACEMENT_STATUS in
      ('ARS', 'First Tech Credit Union', 'Remitter', 'Bounce',
       'Resurgent', 'Jefferson Capital', 'Certain Capital Partners')
  and LT.STATUS = 'Charge off'
''')


## 3.2 Set level suppression
## 3.2.1 Set: Call List, SST
# State Regulation: Minnesota
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                  as LOAD_DATE,
       'Set'                         as SUPPRESSION_TYPE,
       'State Regulation: Minnesota' as SUPPRESSION_REASON,
       L.LEAD_GUID                   as PAYOFF_UID,
       'Call List'                   as SET_NAME,
       'N/A'                         as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
where PII.STATE in ('MN')
  and date_part(dw, current_date) not in (3, 5)
''')

sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                  as LOAD_DATE,
       'Set'                         as SUPPRESSION_TYPE,
       'State Regulation: Minnesota' as SUPPRESSION_REASON,
       L.LEAD_GUID                   as PAYOFF_UID,
       'SST'                         as SET_NAME,
       'N/A'                         as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
where PII.STATE in ('MN')
  and date_part(dw, current_date) not in (3, 5)
''')

# State Regulation: Massachusetts
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                      as LOAD_DATE,
       'Set'                             as SUPPRESSION_TYPE,
       'State Regulation: Massachusetts' as SUPPRESSION_REASON,
       L.LEAD_GUID                       as PAYOFF_UID,
       'Call List'                       as SET_NAME,
       'N/A'                             as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
where PII.STATE in ('MA')
  and date_part(dw, current_date) not in (2, 4)
''')

sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                      as LOAD_DATE,
       'Set'                             as SUPPRESSION_TYPE,
       'State Regulation: Massachusetts' as SUPPRESSION_REASON,
       L.LEAD_GUID                       as PAYOFF_UID,
       'SST'                             as SET_NAME,
       'N/A'                             as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
where PII.STATE in ('MA')
  and date_part(dw, current_date) not in (2, 4)
''')

# State Regulation: DC
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date           as LOAD_DATE,
       'Set'                  as SUPPRESSION_TYPE,
       'State Regulation: DC' as SUPPRESSION_REASON,
       L.LEAD_GUID            as PAYOFF_UID,
       'Call List'            as SET_NAME,
       'N/A'                  as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
where PII.STATE in ('DC')
  and date_part(dw, current_date) not in (1, 3, 4)
''')

sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date           as LOAD_DATE,
       'Set'                  as SUPPRESSION_TYPE,
       'State Regulation: DC' as SUPPRESSION_REASON,
       L.LEAD_GUID            as PAYOFF_UID,
       'SST'                  as SET_NAME,
       'N/A'                  as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
where PII.STATE in ('DC')
  and date_part(dw, current_date) not in (1, 3, 4)
''')

# DNC: Phone
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Set'        as SUPPRESSION_TYPE,
       'DNC: Phone' as SUPPRESSION_REASON,
       L.LEAD_GUID  as PAYOFF_UID,
       'Call List'  as SET_NAME,
       'N/A'        as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
         left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                   on L.LEAD_GUID = SP.PAYOFFUID
                       and SP.SUPPRESSION_TYPE = 'Global'
where LCR.SUPPRESS_PHONE = true
  and SP.PAYOFFUID is null
''')

sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Set'        as SUPPRESSION_TYPE,
       'DNC: Phone' as SUPPRESSION_REASON,
       L.LEAD_GUID  as PAYOFF_UID,
       'SST'        as SET_NAME,
       'N/A'        as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
         left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                   on L.LEAD_GUID = SP.PAYOFFUID
                       and SP.SUPPRESSION_TYPE = 'Global'
where LCR.SUPPRESS_PHONE = true
  and SP.PAYOFFUID is null
''')

# Debt Settlement Agency Phone Number
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                          as LOAD_DATE,
       'Set'                                 as SUPPRESSION_TYPE,
       'Debt Settlement Agency Phone Number' as SUPPRESSION_REASON,
       L.LEAD_GUID                           as PAYOFF_UID,
       'Call List'                           as SET_NAME,
       'N/A'                                 as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
         inner join CRON_STORE.LKP_DEBT_SETTLEMENT_PHONE_NUMBER as DSP
                    on PII.PHONE_NUMBER = DSP.PHONE_NUMBER
''')

sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                          as LOAD_DATE,
       'Set'                                 as SUPPRESSION_TYPE,
       'Debt Settlement Agency Phone Number' as SUPPRESSION_REASON,
       L.LEAD_GUID                           as PAYOFF_UID,
       'SST'                                 as SET_NAME,
       'N/A'                                 as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
         inner join CRON_STORE.LKP_DEBT_SETTLEMENT_PHONE_NUMBER as DSP
                    on PII.PHONE_NUMBER = DSP.PHONE_NUMBER
''')


## 3.2.2 Set: Remitter
# DNC: Text
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Set'        as SUPPRESSION_TYPE,
       'DNC: Text'  as SUPPRESSION_REASON,
       L.LEAD_GUID  as PAYOFF_UID,
       'Remitter'   as SET_NAME,
       'N/A'        as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
         left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                   on L.LEAD_GUID = SP.PAYOFFUID
                       and SP.SUPPRESSION_TYPE = 'Global'
where LCR.SUPPRESS_TEXT = true
  and SP.PAYOFFUID is null
''')


## 3.2.3 Set: SMS
# DNC: Text
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Set'        as SUPPRESSION_TYPE,
       'DNC: Text'  as SUPPRESSION_REASON,
       L.LEAD_GUID  as PAYOFF_UID,
       'SMS'        as SET_NAME,
       'N/A'        as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
         left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                   on L.LEAD_GUID = SP.PAYOFFUID
                       and SP.SUPPRESSION_TYPE = 'Global'
where LCR.SUPPRESS_TEXT = true
  and SP.PAYOFFUID is null
''')


## 3.2.4 Set: GR Physical Mail - ARCHIVED (DI-1255)
# Suppression logic removed with campaign archival

## 3.2.5 Set: Recovery Weekly

if date.today().weekday() == 1:
  # DNC: Letter
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
  select current_date      as LOAD_DATE,
        'Set'             as SUPPRESSION_TYPE,
        'DNC: Letter'     as SUPPRESSION_REASON,
        L.LEAD_GUID       as PAYOFF_UID,
        'Recovery Weekly' as SET_NAME,
        'N/A'             as LIST_NAME
  from ANALYTICS.VW_LOAN as L
          inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                      on L.LOAN_ID = LCR.LOAN_ID
                          and LCR.CONTACT_RULE_END_DATE is null
          left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                    on L.LEAD_GUID = SP.PAYOFFUID
                        and SP.SUPPRESSION_TYPE = 'Global'
  where LCR.SUPPRESS_LETTER = true
    and SP.PAYOFFUID is null
  ''')

## 3.2.6 Set: Recovery Monthly Email - ARCHIVED (DI-1255)
# Suppression logic removed with campaign archival

## 3.2.7 Set: SIMM
# DNC: Phone
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Set'        as SUPPRESSION_TYPE,
       'DNC: Phone' as SUPPRESSION_REASON,
       L.LEAD_GUID  as PAYOFF_UID,
       'SIMM'       as SET_NAME,
       'N/A'        as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
         left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                   on L.LEAD_GUID = SP.PAYOFFUID
                       and SP.SUPPRESSION_TYPE = 'Global'
where LCR.SUPPRESS_PHONE = true
  and SP.PAYOFFUID is null
''')

## 3.3 List level suppression
# 3.3.1 Set: Call List; List: DPD3-14, DPD15-29, DPD30-59, DPD60-89
# Phone Test, weekdays
if date.today().weekday() < 5:
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_PHONE_TEST
  select distinct OL.PAYOFFUID,
                  OL.SET_NAME,
                  OL.LIST_NAME,
                  current_date as LOAD_DATE
  from CRON_STORE.RPT_OUTBOUND_LISTS as OL
           left join CRON_STORE.RPT_PHONE_TEST as PT
                     on OL.PAYOFFUID = PT.PAYOFFUID
                         and datediff(day, PT.LOAD_DATE, current_date) < 7
                         and datediff(day, PT.LOAD_DATE, current_date) > 0
  where OL.SET_NAME = 'Call List'
    and OL.LIST_NAME in ('DPD3-14', 'DPD15-29')
    and substring(OL.PAYOFFUID, 17, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c')
    and PT.PAYOFFUID is null
  ''')
  
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_PHONE_TEST
  select distinct OL.PAYOFFUID,
                  OL.SET_NAME,
                  OL.LIST_NAME,
                  current_date as LOAD_DATE
  from CRON_STORE.RPT_OUTBOUND_LISTS as OL
          left join CRON_STORE.RPT_PHONE_TEST as PT
                    on OL.PAYOFFUID = PT.PAYOFFUID
                        and datediff(day, PT.LOAD_DATE, current_date) < 7
                        and datediff(day, PT.LOAD_DATE, current_date) > 0
  where OL.SET_NAME = 'Call List'
    and OL.LIST_NAME in ('DPD30-59', 'DPD60-89')
    and substring(OL.PAYOFFUID, 12, 1) in ('0', '1', '2')
    and PT.PAYOFFUID is null
  ''')

  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
  select current_date as LOAD_DATE,
         'List'       as SUPPRESSION_TYPE,
         'Phone Test' as SUPPRESSION_REASON,
         OL.PAYOFFUID,
         OL.SET_NAME,
         OL.LIST_NAME
  from CRON_STORE.RPT_OUTBOUND_LISTS as OL
           left join CRON_STORE.RPT_PHONE_TEST as PT
                     on OL.PAYOFFUID = PT.PAYOFFUID
                         and datediff(day, PT.LOAD_DATE, current_date) < 7
                         and datediff(day, PT.LOAD_DATE, current_date) > 0
  where OL.SET_NAME = 'Call List'
    and OL.LIST_NAME in ('DPD3-14', 'DPD15-29')
    and substring(OL.PAYOFFUID, 17, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c')
    and PT.PAYOFFUID is not null
  ''')
  
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
  select current_date as LOAD_DATE,
        'List'       as SUPPRESSION_TYPE,
        'Phone Test' as SUPPRESSION_REASON,
        OL.PAYOFFUID,
        OL.SET_NAME,
        OL.LIST_NAME
  from CRON_STORE.RPT_OUTBOUND_LISTS as OL
          left join CRON_STORE.RPT_PHONE_TEST as PT
                    on OL.PAYOFFUID = PT.PAYOFFUID
                        and datediff(day, PT.LOAD_DATE, current_date) < 7
                        and datediff(day, PT.LOAD_DATE, current_date) > 0
  where OL.SET_NAME = 'Call List'
    and OL.LIST_NAME in ('DPD30-59', 'DPD60-89')
    and substring(OL.PAYOFFUID, 12, 1) in ('0', '1', '2')
    and PT.PAYOFFUID is not null
  ''')

# Phone Test, weekends
if date.today().weekday() >= 5:
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
  select current_date as LOAD_DATE,
         'List'       as SUPPRESSION_TYPE,
         'Phone Test' as SUPPRESSION_REASON,
         OL.PAYOFFUID,
         OL.SET_NAME,
         OL.LIST_NAME
  from CRON_STORE.RPT_OUTBOUND_LISTS as OL
  where OL.SET_NAME = 'Call List'
    and OL.LIST_NAME in ('DPD3-14', 'DPD15-29')
    and substring(OL.PAYOFFUID, 17, 1) in ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c')
  ''')
  
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
  select current_date as LOAD_DATE,
        'List'       as SUPPRESSION_TYPE,
        'Phone Test' as SUPPRESSION_REASON,
        OL.PAYOFFUID,
        OL.SET_NAME,
        OL.LIST_NAME
  from CRON_STORE.RPT_OUTBOUND_LISTS as OL
  where OL.SET_NAME = 'Call List'
    and OL.LIST_NAME in ('DPD30-59', 'DPD60-89')
    and substring(OL.PAYOFFUID, 12, 1) in ('0', '1', '2')
  ''')

# 3.3.2 Set: SMS; List: Payment Reminder, Due Date
# Autopay
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'List'       as SUPPRESSION_TYPE,
       'Autopay'    as SUPPRESSION_REASON,
       OL.PAYOFFUID,
       OL.SET_NAME,
       OL.LIST_NAME
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
         inner join ANALYTICS.VW_LOAN as L
                    on OL.PAYOFFUID = L.LEAD_GUID
         inner join ANALYTICS.VW_LOAN_PAYMENT_MODE as LPM
                    on L.LOAN_ID = LPM.LOAN_ID
                        and LPM.PAYMENT_MODE_END_DATE is null
where LPM.PAYMENT_MODE = 'Auto Payer'
  and OL.SET_NAME = 'SMS'
  and OL.LIST_NAME in ('Payment Reminder', 'Due Date')
''')

## 3.4 Cross set level suppression
# Remitter -> SMS
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Cross Set'  as SUPPRESSION_TYPE,
       'Remitter'   as SUPPRESSION_REASON,
       PAYOFFUID,
       'SMS'        as SET_NAME,
       'N/A'        as LIST_NAME
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME = 'Remitter'
''')

# Remitter -> GR Email
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Cross Set'  as SUPPRESSION_TYPE,
       'Remitter'   as SUPPRESSION_REASON,
       PAYOFFUID,
       'GR Email'   as SET_NAME,
       'N/A'        as LIST_NAME
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME = 'Remitter'
''')

## 3.5 Cross list level suppression


## 3.6 Apply suppression logic
# Global suppression
sfUtils.runQuery(sf_options, '''
update CRON_STORE.RPT_OUTBOUND_LISTS as OL
set SUPPRESSION_FLAG = true
from CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
where OL.PAYOFFUID = SP.PAYOFFUID
  and SP.SUPPRESSION_TYPE = 'Global'
''')

# Set and cross set level suppression
sfUtils.runQuery(sf_options, '''
update CRON_STORE.RPT_OUTBOUND_LISTS as OL
set SUPPRESSION_FLAG = true
from CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
where OL.PAYOFFUID = SP.PAYOFFUID
  and SP.SUPPRESSION_TYPE in ('Set', 'Cross Set')
  and OL.SET_NAME = SP.SET_NAME
''')

# List and cross list level suppression
sfUtils.runQuery(sf_options, '''
update CRON_STORE.RPT_OUTBOUND_LISTS as OL
set SUPPRESSION_FLAG = true
from CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
where OL.PAYOFFUID = SP.PAYOFFUID
  and SP.SUPPRESSION_TYPE in ('List', 'Cross List')
  and OL.SET_NAME = SP.SET_NAME
  and OL.LIST_NAME = SP.LIST_NAME
''')

## 3.7 Save the segmentation and suppression table
sfUtils.runQuery(sf_options, '''
delete
from CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION_HIST
where LOAD_DATE = current_date
  and SUPPRESSION_REASON in (
                             -- Global Suppression
                             'Bankruptcy', 'Cease & Desist', 'OTP', 'Loan Mod', 'Inaccurate Information due to LoanPro Migration',
                             'Natural Disaster', 'Individual Suppression', 'Next Workable Date After Today',
                             '3rd Party Post Charge Off Placement', 'Loan Account Marked for Closure',
                             -- Set Level Suppression
                             'State Regulation: Minnesota', 'State Regulation: Massachusetts', 'State Regulation: DC',
                             'DNC: Phone', 'DNC: Text', 'DNC: Letter', 'DNC: Email', 
                             -- List Level and Cross Set Suppression
                             'Phone Test', 'Autopay', 'Remitter'
    )
''')
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION_HIST
select *
from CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
where SUPPRESSION_REASON in (
                             -- Global Suppression
                             'Bankruptcy', 'Cease & Desist', 'OTP', 'Loan Mod', 'Inaccurate Information due to LoanPro Migration',
                             'Natural Disaster', 'Individual Suppression', 'Next Workable Date After Today',
                             '3rd Party Post Charge Off Placement', 'Loan Account Marked for Closure',
                             -- Set Level Suppression
                             'State Regulation: Minnesota', 'State Regulation: Massachusetts', 'State Regulation: DC',
                             'DNC: Phone', 'DNC: Text', 'DNC: Letter', 'DNC: Email',
                             -- List Level and Cross Set Suppression
                             'Phone Test', 'Autopay', 'Remitter'
    )          
''')

sfUtils.runQuery(sf_options, '''
delete
from CRON_STORE.RPT_OUTBOUND_LISTS_HIST
where LOAD_DATE = current_date
  and SET_NAME in (
                   'Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly',
                   'SIMM', 'SST'
    )         
''')
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_HIST
select *
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME in (
                   'Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly',
                   'SIMM', 'SST'
    )        
''')


# COMMAND ----------

## **************** 4. Generate Genesys data **************** ##
# 4.1 Phone
sfUtils.runQuery(sf_options, '''
delete
from PII.RPT_GENESYS_CAMPAIGN_LISTS
where LOADDATE = current_date
  and CHANNEL = 'Phone'
  and CAMPAIGN in
      ('DPD3-14', 'DPD15-29', 'DPD30-59', 'DPD60-89', 'DPD90+', 'Blue', 'Due Diligence DPD3-89', 'SST')
''')

sfUtils.runQuery(sf_options, '''
insert into PII.RPT_GENESYS_CAMPAIGN_LISTS
select OL.PAYOFFUID,
       LT.LOANID,
       LT.ASOFDATE                                         as DATEADDED,
       PII.FIRST_NAME                                      as FIRSTNAME,
       PII.LAST_NAME                                       as LASTNAME,
       null                                                as CHOSENNAME,
       PII.ADDRESS_1                                       as STREETADDRESS1,
       PII.ADDRESS_2                                       as STREETADDRESS2,
       PII.CITY,
       PII.STATE,
       PII.ZIP_CODE                                        as ZIPCODE,
       PII.PHONE_NUMBER                                    as PHONE,
       PII.EMAIL,
       LT.PORTFOLIONAME,
       CUS.LAST_COLLECTIONS_CONTACT_DATE                   as LATESTCONTACT,
       LPM.PAYMENT_MODE                                    as PAYMENTMETHOD,
       LT.DAYSPASTDUE,
       case
           when LT.DAYSPASTDUE > 0 and LT.DAYSPASTDUE <= 29 then 'DPD 1-29'
           when LT.DAYSPASTDUE > 29 and LT.DAYSPASTDUE <= 59 then 'DPD 30-59'
           when LT.DAYSPASTDUE > 59 and LT.DAYSPASTDUE <= 89 then 'DPD 60-89'
           when LT.DAYSPASTDUE > 89 then 'DPD 90+'
           else 'N/A' end                                  as AGING,
       to_date(dateadd(day, -LT.DAYSPASTDUE, LT.ASOFDATE)) as LASTDUEDATE,
       LSA.AMOUNT_DUE                                      as DELINQUENTAMOUNT,
       'Phone'                                             as CHANNEL,
       OL.LIST_NAME                                        as CAMPAIGN,
       current_date                                        as LOADDATE
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
         inner join DATA_STORE.MVW_LOAN_TAPE as LT
                    on OL.PAYOFFUID = LT.PAYOFFUID
         inner join ANALYTICS.VW_LOAN as L
                    on LT.PAYOFFUID = L.LEAD_GUID
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
         inner join ANALYTICS.VW_LOAN_PAYMENT_MODE as LPM
                    on L.LOAN_ID = LPM.LOAN_ID
                        and LPM.PAYMENT_MODE_END_DATE is null
         inner join BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT as CUS
                    on L.LOAN_ID = CUS.LOAN_ID::string
         inner join BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT as LSA
                    on L.LOAN_ID = LSA.LOAN_ID::string
                        and LSA.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                        and LSA.DATE = current_date
where OL.SET_NAME in ('Call List', 'SST')
  and OL.LIST_NAME in
      ('DPD3-14', 'DPD15-29', 'DPD30-59', 'DPD60-89', 'DPD90+', 'Blue', 'Due Diligence DPD3-89', 'DPD3-119')
  and OL.SUPPRESSION_FLAG = false
''')


# 4.2. Text
sfUtils.runQuery(sf_options, '''
delete
from PII.RPT_GENESYS_CAMPAIGN_LISTS
where LOADDATE = current_date
  and CHANNEL = 'Text'
  and CAMPAIGN in
      ('Payment Reminder', 'Due Date', 'DPD3', 'DPD6', 'DPD8', 'DPD11', 'DPD15', 'DPD17', 'DPD21', 'DPD23', 'DPD25',
       'DPD28', 'DPD33', 'DPD38', 'DPD44', 'TruStage DPD17', 'TruStage DPD33')
''')

sfUtils.runQuery(sf_options, '''
insert into PII.RPT_GENESYS_CAMPAIGN_LISTS
select OL.PAYOFFUID,
       LT.LOANID,
       LT.ASOFDATE                                         as DATEADDED,
       PII.FIRST_NAME                                      as FIRSTNAME,
       PII.LAST_NAME                                       as LASTNAME,
       null                                                as CHOSENNAME,
       PII.ADDRESS_1                                       as STREETADDRESS1,
       PII.ADDRESS_2                                       as STREETADDRESS2,
       PII.CITY,
       PII.STATE,
       PII.ZIP_CODE                                        as ZIPCODE,
       PII.PHONE_NUMBER                                    as PHONE,
       PII.EMAIL,
       LT.PORTFOLIONAME,
       CUS.LAST_COLLECTIONS_CONTACT_DATE                   as LATESTCONTACT,
       LPM.PAYMENT_MODE                                    as PAYMENTMETHOD,
       LT.DAYSPASTDUE,
       case
           when LT.DAYSPASTDUE > 0 and LT.DAYSPASTDUE <= 29 then 'DPD 1-29'
           when LT.DAYSPASTDUE > 29 and LT.DAYSPASTDUE <= 59 then 'DPD 30-59'
           when LT.DAYSPASTDUE > 59 and LT.DAYSPASTDUE <= 89 then 'DPD 60-89'
           when LT.DAYSPASTDUE > 89 then 'DPD 90+'
           else 'N/A' end                                  as AGING,
       to_date(dateadd(day, -LT.DAYSPASTDUE, LT.ASOFDATE)) as LASTDUEDATE,
       LSA.AMOUNT_DUE                                      as DELINQUENTAMOUNT,
       'Text'                                              as CHANNEL,
       OL.LIST_NAME                                        as CAMPAIGN,
       current_date                                        as LOADDATE
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
         inner join DATA_STORE.MVW_LOAN_TAPE as LT
                    on OL.PAYOFFUID = LT.PAYOFFUID
         inner join ANALYTICS.VW_LOAN as L
                    on LT.PAYOFFUID = L.LEAD_GUID
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
         inner join ANALYTICS.VW_LOAN_PAYMENT_MODE as LPM
                    on L.LOAN_ID = LPM.LOAN_ID
                        and LPM.PAYMENT_MODE_END_DATE is null
         inner join BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT as CUS
                    on L.LOAN_ID = CUS.LOAN_ID::string
         inner join BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT as LSA
                    on L.LOAN_ID = LSA.LOAN_ID::string
                        and LSA.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                        and LSA.DATE = current_date
where OL.SET_NAME in ('SMS')
  and OL.LIST_NAME in
      ('Payment Reminder', 'Due Date', 'DPD3', 'DPD6', 'DPD8', 'DPD11', 'DPD15', 'DPD17', 'DPD21', 'DPD23', 'DPD25',
       'DPD28', 'DPD33', 'DPD38', 'DPD44', 'TruStage DPD17', 'TruStage DPD33')
  and OL.SUPPRESSION_FLAG = false
''')
