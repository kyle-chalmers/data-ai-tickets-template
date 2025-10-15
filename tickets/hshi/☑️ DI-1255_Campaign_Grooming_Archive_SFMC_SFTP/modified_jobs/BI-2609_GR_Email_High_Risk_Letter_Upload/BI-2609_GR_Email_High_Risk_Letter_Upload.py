# Databricks notebook source
# MAGIC %sh
# MAGIC pip install paramiko

# COMMAND ----------

dbutils.widgets.removeAll()
dbutils.widgets.dropdown("env", "dev", ["dev", "qa", "staging", "prod"])

ENV = dbutils.widgets.get("env")
print(ENV)

# COMMAND ----------

import os
import paramiko
import pandas as pd
import datetime
import base64
import boto3

# COMMAND ----------

# Snowflake connection 
sf_options = {"sfUrl" : "happymoney.us-east-1.snowflakecomputing.com",
              "sfUser" : dbutils.secrets.get("snowflake_bi_pii", "username"),
              "sfPassword" : dbutils.secrets.get("snowflake_bi_pii", "password"),
              "sfRole": "BUSINESS_INTELLIGENCE_TOOLS_PII",
              "sfDatabase" : "BUSINESS_INTELLIGENCE",
              "sfSchema" : "CRON_STORE",
              "sfWarehouse" : "BUSINESS_INTELLIGENCE_CRON"     
             }

# COMMAND ----------

## ********** Upload marketing campaign list to SFMC **********

# GR outreach campaign (email)
query = """
select OL.PAYOFFUID,
       PII.FIRST_NAME as FIRSTNAME,
       PII.LAST_NAME  as LASTNAME,
       null           as CHOSENNAME,
       LT.DAYSPASTDUE,
       PII.EMAIL,
       LSE.PAYMENT    as REGULAR_PAYMENT_AMOUNT,
       LSA.AMOUNT_DUE as PAST_DUE_AMOUNT,
       PII.ADDRESS_1  as STREETADDRESS1,
       PII.ADDRESS_2  as STREETADDRESS2,
       PII.CITY,
       PII.STATE,
       PII.ZIP_CODE   as ZIPCODE
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
         inner join DATA_STORE.MVW_LOAN_TAPE as LT
                    on OL.PAYOFFUID = LT.PAYOFFUID
         inner join ANALYTICS.VW_LOAN as L
                    on LT.PAYOFFUID = L.LEAD_GUID
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
         inner join BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT as LSA
                    on L.LOAN_ID = LSA.LOAN_ID::string
                        and LSA.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                        and LSA.DATE = current_date
         inner join BRIDGE.VW_LOAN_SETUP_ENTITY_CURRENT as LSE
                    on L.LOAN_ID = LSE.LOAN_ID::string
                        and LSE.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
where OL.SET_NAME = 'GR Email'
  and OL.SUPPRESSION_FLAG = false
"""
query_construct = (spark
      .read
      .format("snowflake")
      .options(**sf_options)
      .option("query", query)
      .load())
upload_data = query_construct.toPandas()

upload_data['EMAIL ADDRESS'] = upload_data['EMAIL']

sfmc_upload  = upload_data[['PAYOFFUID', 'FIRSTNAME', 'LASTNAME', 'CHOSENNAME', 'DAYSPASTDUE', 'STREETADDRESS1', 'STREETADDRESS2', 'CITY', 'STATE', 'ZIPCODE', 'REGULAR_PAYMENT_AMOUNT', 'PAST_DUE_AMOUNT', 'EMAIL ADDRESS']]

local_dir = '/tmp/GR_outreach_campaign_upload_' + datetime.date.today().strftime('%Y-%m-%d') + '.csv'
sfmc_upload.to_csv(local_dir, index = False)

if ENV == 'prod':
    host = 'mc9bltz8jrt0t97x71rmj4m56pv8.ftp.marketingcloudops.com'
    username = dbutils.secrets.get("SFMC", "username")
    password = dbutils.secrets.get("SFMC", "password")
    remote_path = '/Import/' + 'GR_outreach_campaign_upload_' + datetime.date.today().strftime('%Y-%m-%d') + '.csv'

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(hostname=host, username=username, password=password, port=22)
        sftp = ssh.open_sftp()
        print("Connection successful")

        sftp.put(local_dir, remote_path)

        sftp.close()
    finally:
        ssh.close()

# Save to S3
s3_dir = f"secrets/{ENV}/BI-2609_GR_Email_High_Risk_Letter_Upload/GR_outreach_campaign_upload_" + datetime.date.today().strftime('%Y-%m-%d') + '.csv'

s3= boto3.client('s3')
s3.upload_file(local_dir, "hm-rstudio-datascience-cron", s3_dir, ExtraArgs = {'ACL': 'bucket-owner-full-control'})


# COMMAND ----------

## ********** GR Physical Mail Upload - ARCHIVED (DI-1255) **********
# Campaign confirmed inactive - all GR Physical Mail upload code removed
# - Early stage upload (DPD15 Test)
# - Late stage upload (DPD75 Test)
# Original code archived in: /Users/hshi/WOW/data-intelligence-tickets/tickets/hshi/DI-1255_Campaign_Grooming_Archive_SFMC_SFTP/
