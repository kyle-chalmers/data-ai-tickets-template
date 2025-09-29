# Databricks notebook source
# Install the Snowflake connector package
%pip install snowflake-connector-python

# COMMAND ----------

import os
import pandas as pd
import base64
import pytz
from pyspark.sql import functions as F
from pyspark.sql import SparkSession
from datetime import datetime, timedelta
import time
from dateutil.relativedelta import relativedelta

# COMMAND ----------

# ENV 
dbutils.widgets.removeAll()
dbutils.widgets.dropdown("env", "dev", ["dev", "qa", "staging", "prod"])
ENV = dbutils.widgets.get("env")
print(f"Current ENV: {ENV}")

# COMMAND ----------

if ENV in ['dev']:
  sfRole = 'BUSINESS_INTELLIGENCE_DEV_PII'
  sfWarehouse = 'BUSINESS_INTELLIGENCE_LARGE'
  BI_db = 'BUSINESS_INTELLIGENCE_DEV'
else:
  sfRole = 'BUSINESS_INTELLIGENCE_TOOLS_PII'
  sfWarehouse = 'BUSINESS_INTELLIGENCE_LARGE'
  BI_db = 'BUSINESS_INTELLIGENCE'

# COMMAND ----------

def create_snowflake_options(url= "https://happymoney.us-east-1.snowflakecomputing.com",
                            database="BUSINESS_INTELLIGENCE",
                            schema="DATA_STORE",
                            warehouse="BUSINESS_INTELLIGENCE_CRON",
                            role="BUSINESS_INTELLIGENCE_TOOLS_PII",
                            preactions=None,
                            secrets_scope="snowflake_bi_pii", #snowflake_bi_pii
                            user_key="username",
                            pass_key="password"):

    if not secrets_scope:
      raise ValueError("Need to specify a secrets_scope for credentials")
      
    user = dbutils.secrets.get(secrets_scope, user_key)
    password = dbutils.secrets.get(secrets_scope, pass_key)

    options = {"sfUrl" : url,
                      "sfUser" : user,
                       "sfRole": role,
                      "sfPassword" : password,
                      "sfDatabase" : database,
                      "sfSchema" : schema,
                      "sfWarehouse" : warehouse
               }
    
    return(options)

# define Snowflake connection options
sfoptions = create_snowflake_options(secrets_scope="snowflake_bi_pii", 
                                     role = sfRole, 
                                     warehouse=sfWarehouse,
                                     database = BI_db,
                                     schema="cron_store")

# COMMAND ----------

# Date filter for DSH_EMAIL_MONITORING_APPLICATION_FUNNEL
now = datetime.now(tz=pytz.timezone('US/Pacific'))
funnel_date_filter = now - relativedelta(years=2) # 2 years
funnel_date_filter = funnel_date_filter.strftime("%Y-%m-%d")
funnel_date_filter


# COMMAND ----------

# Creates the lookup dataframe with inf/utm tag for given Email Names
# Results are on SEND_ID grain
# Dataframe will be joined to event_metrics
query = '''
with cte_url as (
      select send_ID , TRIGGERED_SEND_ID, parse_url(url, 1) as url
          ,trim(EMAIL_NAME) as EMAIL_NAME
          ,EMAIL_ID
          ,s.SFMC_SOURCE
      from BUSINESS_INTELLIGENCE.DATA_STORE.VW_SFMC_EVENT_UNIONED ev
          left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_SFMC_SEND_UNIONED  s
              on s.ID = ev.SEND_ID
      where
          url ilike '%=email%' -- only include emails
           -- and url ilike any ('%button%', '%text%') -- only include button or text; original requirements
          and NOT (url ilike any ('%PSCamp%', '%header%', '%hero%','%esignbtn%','%esignheader%','%header%', '%hero%', '%glamour%', '%shape%', '%wsj%', '%signature%' )) -- remove all prescreen apps and exclude values instead of filter above (BI-2287)
  )
  , cte_lookup_utms as (
      select distinct
          SEND_ID
          ,EMAIL_NAME
          ,EMAIL_ID

        --- inf parameters
          ,f.VALUE:inf_medium::string as inf_medium
          ,f.VALUE:inf_campaign::string as inf_campaign
          ,f.VALUE:inf_source::string as inf_source
          ,f.VALUE:inf_content::string as inf_content
         -- ,f.VALUE:inf_term::string
          ,REGEXP_REPLACE(f.VALUE:inf_term::string, '[0-9]+', '') as inf_term

        --- utm parameters
          ,f.VALUE:utm_medium::string as utm_medium
          ,f.VALUE:utm_campaign::string as utm_campaign
          ,f.VALUE:utm_source::string as utm_source
          ,f.VALUE:utm_content::string as utm_content
          ,REGEXP_REPLACE(f.VALUE:utm_term::string, '[0-9]+', '') as utm_term
      from cte_url url,
      lateral flatten(input => url) f
      where
          key = 'parameters'
  )
, cte_term_list as (
    select
        send_id
        , email_name
        , email_id
        , inf_medium
        , inf_campaign
        , inf_source
        , inf_content
        , inf_term
        , listagg(distinct inf_term, ',') within group ( order by inf_term ) over (partition by SEND_ID) as inf_term_list  -- concat values to make a list
        , utm_medium
        , utm_campaign
        , replace(utm_source, 'sfmc_partner_offer_s', 'sfmc_partner_offers') as utm_source
        , utm_content
        , utm_term
        , listagg(distinct utm_term, ',') within group ( order by utm_term ) over (partition by SEND_ID) as utm_term_list  -- concat values to make a list
    from
        cte_lookup_utms
    group by
        send_id
        , email_name
        , email_id
        , inf_medium
        , inf_campaign
        , inf_source
        , inf_content
        , inf_term

        , utm_medium
        , utm_campaign
        , replace(utm_source, 'sfmc_partner_offer_s', 'sfmc_partner_offers')
        , utm_content
        , utm_term
)
, cte_detail as (
    select
        send_id
        , email_name
        , email_id
        , inf_medium
        , inf_campaign
        , inf_source
        , inf_content
        , iff(len(inf_term_list) = 0 , null, inf_term_list) as inf_term_list -- handle empty string
        , utm_medium, utm_campaign, utm_source, utm_content
        , iff(len(utm_term_list) = 0 , null, utm_term_list) as utm_term_list -- handle empty string
        , row_number() over (partition by SEND_ID order by inf_medium, inf_campaign, inf_source, inf_content,  inf_term_list
                                                            , utm_medium, utm_campaign, utm_source, utm_content,  utm_term_list) as IS_MOST_COMPLETE
        , current_timestamp as LAST_UPDATED
    from
        cte_term_list
    where
        EMAIL_NAME not ilike ('%PSC%') -- remove remaing Prescreen email names
    qualify
        IS_MOST_COMPLETE = 1
)
select
    send_id
    , email_name
    --, email_id
    -- combine marketing tag fields 
    , ifnull(inf_medium, utm_medium) as medium
    , ifnull(inf_campaign, utm_campaign) as campaign
    , ifnull(inf_source, utm_source) as source
    , ifnull(inf_content, utm_content) as content
    , ifnull(inf_term_list, utm_term_list) term
from cte_detail
'''

marketing_tags = spark.read \
  .format('snowflake') \
  .options(**sfoptions) \
  .option('query',query) \
  .load()


# COMMAND ----------

# Lookup dataframe - email and subscriber keys to create DERIVED_PAYOFFUID field 
# Dataframe will be joined to event_metrics
query = '''
with cte_payoffuid_stage as (
-- stage payoffuid to select origination, application first
    select 
        EMAIL
        ,loan_id
         application_id
        ,lead_guid
        ,APPLICATION_GUID
        ,application_started_date
        ,APPLICATION_SUBMITTED_DATE
        ,origination_date
        ,row_number() over 
            (partition by email 
                    order by 
                        origination_date desc NULLS LAST
                        ,APPLICATION_SUBMITTED_DATE desc NULLS LAST
                        ,application_started_date desc NULLS LAST
            ) as row_num
        from  
            BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT 
        qualify row_number() over 
            (partition by email 
                    order by 
                        origination_date desc NULLS LAST
                        ,APPLICATION_SUBMITTED_DATE desc NULLS LAST
                        ,application_started_date desc NULLS LAST
            ) = 1 
)
  select -- 3,750,793
      sub.SUBSCRIBER_KEY
      ,sub.CREATED_DATE
      ,lead.CREATED_DATE AS LEAD_CREATED_DATE
      ,app.CREATEDDATE AS APP_CREATED_DATE
      ,md5(trim(lower(sub.EMAIL_ADDRESS))) as HK_EMAIL_ADDRESS
      ,sub.EMAIL_ADDRESS -- check
      ,lead.GUID
      ,app.PAYOFF_UID
    ---- from cte_stage
      ,cps.EMAIL  -- get payoffupid by email
      ,cps.APPLICATION_GUID
      ,coalesce(lead.guid,app.PAYOFF_UID,cps.APPLICATION_GUID) as DERIVED_PAYOFFUID
      ,sub.SFMC_SOURCE
      ,row_number() over (partition by sub.SUBSCRIBER_KEY order by app.CREATEDDATE desc, lead.CREATED_DATE desc) IS_LATEST_RECORD
  from
      BUSINESS_INTELLIGENCE.DATA_STORE.VW_SFMC_SUBSCRIBER_UNIONED sub
      left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_LEAD lead
          on sub.SUBSCRIBER_KEY = lead.CLS_LEAD_ID
      left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION app
        on sub.SUBSCRIBER_KEY = app.GEN_CONTACT
      left join cte_payoffuid_stage cps
        on sub.EMAIL_ADDRESS = cps.EMAIL
  qualify IS_LATEST_RECORD = 1

'''

email_keys = spark.read \
  .format('snowflake') \
  .options(**sfoptions) \
  .option('query',query) \
  .load()

# COMMAND ----------

# Fetches Events for specific email names
# Results are on Event_ID grain
query = '''
      select
          ev.ID AS EVENT_ID
          ,ev.EVENT_TYPE
          , ev.SUBSCRIBER_KEY
          , ev.EVENT_DATE
          --- SFMC uses Central Standard Time or Mountain Time; convert timezone to account for this
          , convert_timezone('America/Guatemala', 'America/Los_Angeles', ev.EVENT_DATE) as EVENT_DATE_CST
          , s.id as SEND_ID
          , trim(s.EMAIL_NAME) as SEND_TABLE_EMAIL_NAME
          , s.CREATED_DATE as SEND_TABLE_CREATED_DATE
          , s.SEND_DATE as SEND_TABLE_SEND_DATE
          --- SFMC uses Central Standard Time or Mountain Time; convert timezone to account for this
          , convert_timezone('America/Guatemala', 'America/Los_Angeles', s.SEND_DATE) as SEND_TABLE_SEND_DATE_CST
          , s.EMAIL_ID
          , trim(em.Name) as EMAIL_TABLE_EMAIL_NAME
          , EM.CREATED_DATE as EMAIL_TABLE_CREATED_DATE
          , s.UNIQUE_CLICKS -- no not sum, on SEND_ID grain
          , s.NUMBER_SENT -- no not sum, on SEND_ID grain
          , s.UNIQUE_OPENS -- no not sum, on SEND_ID grain
          , ev.SFMC_SOURCE
          , IFF(EVENT_TYPE = 'Open', 1, 0) as OPEN
          , IFF(EVENT_TYPE = 'Sent', 1, 0) as SENT
          , IFF(EVENT_TYPE = 'Click', 1, 0) AS CLICK
          , current_timestamp as LAST_UPDATED
      from
          BUSINESS_INTELLIGENCE.DATA_STORE.VW_SFMC_EVENT_UNIONED ev
          left join  BUSINESS_INTELLIGENCE.DATA_STORE.VW_SFMC_SEND_UNIONED s --23172
              on ev.SEND_ID = s.ID
          left join ( -- dedupe this table as ID is not unique; weird things started in July of 2023
                     SELECT *
                     FROM BUSINESS_INTELLIGENCE.DATA_STORE.VW_SFMC_EMAIL_UNIONED em 
                     QUALIFY ROW_NUMBER() OVER (PARTITION BY ID ORDER BY MODIFIED_DATE DESC) = 1
                ) em

              on s.EMAIL_ID = em.id
      where
          ev.EVENT_TYPE in ('Open','Sent','Click')

'''

event_metrics = spark.read \
  .format('snowflake') \
  .options(**sfoptions) \
  .option('query',query) \
  .load()

# COMMAND ----------

# Create temporary view for unique events table
# table on SEND_ID grain
event_metrics.createOrReplaceTempView("UNIQUE_EVENTS")
unique_metrics = spark.sql("""select distinct
                                SEND_ID
                                , SEND_TABLE_CREATED_DATE 
                                , UNIQUE_CLICKS
                                , NUMBER_SENT
                                , UNIQUE_OPENS
                              from UNIQUE_EVENTS""")


# COMMAND ----------

# Join marketing_tags lookup to event_metrics
event_metrics = event_metrics.join(marketing_tags,event_metrics.SEND_ID ==  marketing_tags.SEND_ID,"left").drop(marketing_tags.SEND_ID)

# COMMAND ----------

# Join event_metrics to email_keys to add derived payoffuid
# DERIVED_PAYOFFUID will be used as a relationship in Tableau Dashboard
event_metrics = event_metrics.join(email_keys,event_metrics.SUBSCRIBER_KEY ==  email_keys.SUBSCRIBER_KEY,"left").select(event_metrics["*"],email_keys["DERIVED_PAYOFFUID"])

# COMMAND ----------

# drop fields not on Event_ID grain; cannot be summed up from table
event_metrics =  event_metrics.drop('UNIQUE_CLICKS','NUMBER_SENT', 'UNIQUE_OPENS')

# COMMAND ----------

# DSH_EMAIL_MONITORING_APPLICATION_FUNNEL
# Table fetches funnel metrics and joins to email (email is hashed)
# Email should be joined here as one email can be linked to multiple PayoffUid's; join here prevents duplicating rows
# Query if being filterd by python variable: 'two_years_ago' (towards beginning of script)

# This is patched with a union to BUSINESS_INTELLIGENCE.analytics.VW_APPLICATION_STATUS_TRANSITION_WIP (for loanpro); logic slightly different than CLS
query = f'''
    with cte_cls_stage as (
        select
            ast.PAYOFFUID
            , ast.CREATEDATLOCAL
            , ast.APPLICATION_STARTED_COUNT
            , ast.FIRST_APPLIED_DATE
            , ast.FIRST_OFFER_SHOWN_DATE
            , ast.FIRST_OFFER_ACCEPTED_DATE
            , ast.LAST_FUNDED_DATE
            , ast.LOAN_INTENT
            , ast.LAST_TOUCH_UTM_CHANNEL_GROUPING
            , ast.SELECTED_OFFER_AMOUNT
            , ast.APPLICATION_STARTED -- BI-2774
            , ast.FIRST_PRE_FUNDING_DATE -- BI-2774
            , app.ORIGINATION_FEE
            , app.LOAN_PREMIUMAMOUNT
            , lt.ORIGINATIONFEE
            , lt.PREMIUMPAID
            , lt.ORIGINATIONFEE + lt.PREMIUMPAID AS TOTAL_REVENUE
            , lt.LOANAMOUNT
           -- , app.ID AS APPLICATION_ID
            , (sum(iff(hist.HK_H_APPL is not null, 1, 0)) > 0)::int as Application_Started_HK_H_APPL
            , (sum(iff(hist.NEWVALUE = 'Default Documents', 1, 0))::int > 0)::int as Applied
            , (sum(iff(hist.NEWVALUE = 'offer_shown', 1, 0)) > 0)::int as Offer_Shown
            , (sum(iff(hist.NEWVALUE = 'offer_accepted', 1, 0)) > 0)::int as Offer_Accepted
            , (sum(iff(hist.NEWVALUE = 'docusign_loan_docs_complete', 1, 0)) > 0)::int as Prefunded
            , (sum(iff(hist.NEWVALUE = 'funded', 1, 0)) > 0)::int as Funded

        from BUSINESS_INTELLIGENCE.DATA_STORE.MVW_APPL_STATUS_TRANSITION ast
            left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPLICATION app
                on ast.PAYOFFUID = app.PAYOFF_UID
            left join BUSINESS_INTELLIGENCE.DATA_STORE.VW_APPL_HISTORY hist
                on hist.HK_H_APPL = app.HK_H_APPL
            left join BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE lt
                on ast.PAYOFFUID = lt.PAYOFFUID
       where CREATEDATLOCAL >= '{funnel_date_filter}'
       --where CREATEDATLOCAL >= '2022-12-31'
           

        group by
            ast.PAYOFFUID
            , ast.CREATEDATLOCAL
            ,ast.APPLICATION_STARTED_COUNT
            ,ast.FIRST_APPLIED_DATE
            ,ast.FIRST_OFFER_SHOWN_DATE
            ,ast.FIRST_OFFER_ACCEPTED_DATE
            ,ast.LAST_FUNDED_DATE
            ,ast.LOAN_INTENT
            ,ast.LAST_TOUCH_UTM_CHANNEL_GROUPING
            , ast.SELECTED_OFFER_AMOUNT
            , ast.APPLICATION_STARTED -- BI-2774
            , ast.FIRST_PRE_FUNDING_DATE -- BI-2774
            , app.ORIGINATION_FEE
            , app.LOAN_PREMIUMAMOUNT
            , lt.ORIGINATIONFEE
            , lt.PREMIUMPAID
            , lt.ORIGINATIONFEE + lt.PREMIUMPAID
            , lt.LOANAMOUNT
          --  , app.ID
)

--     select
--         *
--         , Prefunded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Prefunded_Origination
--         , Funded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Funded_Origination
--         , Prefunded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Prefunded_Revenue
--         , Funded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Funded_Revenue
--         , current_timestamp as LAST_UPDATED
--        -- , 'CLS' AS SOURCE
--     from cte
-- ;


, cte_los_stage as (
    select
        lt.APPLICATION_GUID as PAYOFFUID
        ,CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', lead.CREATED_DATETIME_UTC)  AS CREATEDATLOCAL
       -- ,FIRST_STARTED_DATETIME -- test; remove
        -- ,CASE  ---- gives 100% applied rate in the dashboard
        --     WHEN lead.utm_medium = 'PARTNER'
        --     THEN IFF(wip.selected_offer_amount is not null, 1, 0)  
        --     ELSE IFF(app_pii.FIRST_NAME IS NOT NULL, 1, 0)  
        -- END AS APPLICATION_STARTED_COUNT
        ,IFF(lead.utm_medium = 'PARTNER' and wip.first_affiliate_landed_datetime IS NULL, 0, 1) AS APPLICATION_STARTED_COUNT -- this logic may need to be updated
        ,wip.FIRST_APPLIED_DATETIME AS FIRST_APPLIED_DATE
        ,wip.FIRST_OFFERS_SHOWN_DATETIME AS FIRST_OFFER_SHOWN_DATE
        ,wip.FIRST_OFFER_SELECTED_DATETIME as FIRST_OFFER_ACCEPTED_DATE
        ,wip.LAST_ORIGINATED_DATETIME as LAST_FUNDED_DATE
        ,lead.LOAN_INTENT as LOAN_INTENT  -- need to find loan_intent
        ,lead.LAST_TOUCH_UTM_CHANNEL_GROUPING
        ,wip.SELECTED_OFFER_AMOUNT
        ,wip.FIRST_APPLIED_DATETIME as APPLICATION_STARTED
        ,wip.FIRST_PREFUNDING_DATETIME as FIRST_PRE_FUNDING_DATE
        ,ZEROIFNULL(lt.ORIGINATION_FEE) as ORIGINATION_FEE
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT) as LOAN_PREMIUMAMOUNT
        ,ZEROIFNULL(lt.ORIGINATION_FEE) as ORIGINATIONFEE
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT) as PREMIUMPAID
        ,ZEROIFNULL(lt.ORIGINATION_FEE + lt.PREMIUM_AMOUNT) as TOTAL_REVENUE --ORIGINATIONFEE + lt.PREMIUMPAID
        ,ZEROIFNULL(lt.AMOUNT) as LOANAMOUNT
    
        -- ,APP_HIST.APPLICATION_ID
    
        ,(sum(iff(APP_HIST.APPLICATION_ID is not null, 1, 0)) > 0)::int as Application_Started_HK_H_APPL
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('Default Documents', 'Applied'), 1, 0))::int > 0)::int as Applied
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('offer_shown', 'Offers Shown'), 1, 0)) > 0)::int as Offer_Shown
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('offer_accepted', 'Offer Selected'), 1, 0)) > 0)::int as Offer_Accepted
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('docusign_loan_docs_complete', 'Loan Docs Completed'), 1, 0)) > 0)::int as Prefunded
        , (sum(iff(APP_HIST.NEW_STATUS_VALUE in ('funded', 'Originated'), 1, 0)) > 0)::int as Funded
    
       -- , wip.source 
    from
        BUSINESS_INTELLIGENCE.analytics.VW_APPLICATION_STATUS_TRANSITION_WIP wip 
        left join business_intelligence.analytics.vw_application app
            on wip.application_id = app.application_id
        left join BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT lt
            on wip.APPLICATION_ID = lt.LOAN_ID
        left join BUSINESS_INTELLIGENCE.ANALYTICS.VW_LEAD lead
            on lt.APPLICATION_GUID = lead.LEAD_GUID
        left join BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_STATUS_HISTORY APP_HIST
            ON APP_HIST.APPLICATION_ID = WIP.APPLICATION_ID
        left join business_intelligence.analytics_pii.vw_application_pii app_pii
            on wip.application_id = app_pii.application_id
        where 
            lt.APPLICATION_GUID is not null
            and APP_HIST.SOURCE = 'LOANPRO'
            and CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', lead.CREATED_DATETIME_UTC) >= '{funnel_date_filter}'
            -- -- handle dupes in cls
            -- and lt.APPLICATION_GUID not in (
            --                                 select PAYOFFUID
            --                                 from cte_cls_stage
                
            -- )
    
    group by 
        lt.APPLICATION_GUID 
        ,CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', lead.CREATED_DATETIME_UTC)  
       -- ,FIRST_STARTED_DATETIME -- test; remove
        -- ,CASE  
        --     WHEN lead.utm_medium = 'PARTNER'
        --     THEN IFF(wip.selected_offer_amount is not null, 1, 0)  
        --     ELSE IFF(app_pii.FIRST_NAME IS NOT NULL, 1, 0)  
        -- END
        ,IFF(lead.utm_medium = 'PARTNER' and wip.first_affiliate_landed_datetime IS NULL, 0, 1)
        ,wip.FIRST_APPLIED_DATETIME
        ,wip.FIRST_OFFERS_SHOWN_DATETIME
        ,wip.FIRST_OFFER_SELECTED_DATETIME 
        ,wip.LAST_ORIGINATED_DATETIME 
        ,lead.LOAN_INTENT   -- need to find loan_intent
        ,lead.LAST_TOUCH_UTM_CHANNEL_GROUPING
        ,wip.SELECTED_OFFER_AMOUNT
        ,wip.FIRST_APPLIED_DATETIME 
        ,wip.FIRST_PREFUNDING_DATETIME 
        ,ZEROIFNULL(lt.ORIGINATION_FEE) 
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT) 
        ,ZEROIFNULL(lt.ORIGINATION_FEE) 
        ,ZEROIFNULL(lt.PREMIUM_AMOUNT) 
        ,ZEROIFNULL(lt.ORIGINATION_FEE + lt.PREMIUM_AMOUNT) --ORIGINATIONFEE + lt.PREMIUMPAID
        ,ZEROIFNULL(lt.AMOUNT) 

)

, cte_union_all as (
    select *, 'cls' as source
    from cte_cls_stage 
    union all
    select *, 'los' as source
    from cte_los_stage 
    qualify row_number() 
                over ( partition by payoffuid 
                            order by  GREATEST_IGNORE_NULLS(FIRST_APPLIED_DATE, FIRST_OFFER_SHOWN_DATE, FIRST_OFFER_ACCEPTED_DATE, LAST_FUNDED_DATE, APPLICATION_STARTED, FIRST_PRE_FUNDING_DATE) ) = 1 -- 1 is the latest date of all these fields
)

    select
        * exclude(source)
        , Prefunded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Prefunded_Origination
        , Funded * coalesce(SELECTED_OFFER_AMOUNT, 0) as Funded_Origination
        , Prefunded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Prefunded_Revenue
        , Funded * (coalesce(ORIGINATION_FEE, 0) + coalesce(LOAN_PREMIUMAMOUNT, 0)) as Funded_Revenue
        , current_timestamp as LAST_UPDATED
       -- , 'CLS' AS SOURCE
    from cte_union_all
'''

app_funnel_metric = spark.read \
  .format('snowflake') \
  .options(**sfoptions) \
  .option('query',query) \
  .load()

# COMMAND ----------

# display(app_funnel_metric)
# (app_funnel_metric.count(), len(app_funnel_metric.columns))

# COMMAND ----------

# TRUNCATE CRON_STORE.DSH_EMAIL_MONITORING_EVENTS to not eliminate the permissions
#truncate not supported with spark
import snowflake.connector

# Snowflake connection details
SNOWFLAKE_ACCOUNT = "happymoney.us-east-1"
SNOWFLAKE_USER = dbutils.secrets.get("snowflake_bi_pii", "username")
SNOWFLAKE_PASSWORD = dbutils.secrets.get("snowflake_bi_pii", "password")
SNOWFLAKE_WAREHOUSE = "BUSINESS_INTELLIGENCE_CRON"
SNOWFLAKE_ROLE = "BUSINESS_INTELLIGENCE_TOOLS_PII"
SNOWFLAKE_URL = "https://happymoney.us-east-1.snowflakecomputing.com"
SNOWFLAKE_DATABASE = "BUSINESS_INTELLIGENCE"
SNOWFLAKE_SCHEMA = "CRON_STORE"

# Establish a connection to Snowflake
conn = snowflake.connector.connect(
  user=SNOWFLAKE_USER,
  password=SNOWFLAKE_PASSWORD,
  account=SNOWFLAKE_ACCOUNT,
  database=SNOWFLAKE_DATABASE,
  schema=SNOWFLAKE_SCHEMA,
  role=SNOWFLAKE_ROLE,
  warehouse=SNOWFLAKE_WAREHOUSE,
  url=SNOWFLAKE_URL
  )

# Create a cursor object
cur = conn.cursor()

# Execute the TRUNCATE TABLE command
cur.execute("TRUNCATE TABLE BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS")

# Close the cursor and connection
cur.close()
conn.close()

# COMMAND ----------

# Write to Snowflake CRON_STORE.DSH_EMAIL_MONITORING_EVENTS
event_metrics.write\
      .format("snowflake")\
      .options(**sfoptions)\
      .option("dbtable", "DSH_EMAIL_MONITORING_EVENTS")\
      .mode("append")\
      .save()

# COMMAND ----------

# Write to Snowflake CRON_STORE.DSH_EMAIL_MONITORING_UNIQUE_EVENTS
unique_metrics.write\
      .format("snowflake")\
      .options(**sfoptions)\
      .option("dbtable", "DSH_EMAIL_MONITORING_UNIQUE_EVENTS")\
      .mode("overwrite")\
      .save()

# COMMAND ----------

# Write to Snowflake CRON_STORE.DSH_EMAIL_MONITORING_APPLICATION_FUNNEL
app_funnel_metric.write\
      .format("snowflake")\
      .options(**sfoptions)\
      .option("dbtable", "DSH_EMAIL_MONITORING_APPLICATION_FUNNEL")\
      .mode("overwrite")\
      .save()

# COMMAND ----------

# park.sparkContext._jvm.net.snowflake.spark.snowflake.Utils.runQuery(
#   sfoptions,""" select SYSTEM$CANCEL_QUERY('01ac3379-0503-5ce2-0026-6983345ab682')""")
