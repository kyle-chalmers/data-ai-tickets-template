# Databricks notebook source
pip install paramiko

# COMMAND ----------

dbutils.widgets.removeAll()
dbutils.widgets.dropdown("env", "dev", ["dev", "qa", "staging", "prod"])

# COMMAND ----------

ENV = dbutils.widgets.get("env")
print(ENV)

# COMMAND ----------

import pytz
import os
import pandas as pd
from datetime import date
import paramiko
import boto3


# COMMAND ----------

# Snowflake connection
sf_options = {"sfUrl" : "happymoney.us-east-1.snowflakecomputing.com",
              "sfUser" : dbutils.secrets.get("snowflake_bi_pii", "username"),
              "sfPassword" : dbutils.secrets.get("snowflake_bi_pii", "password"),
              "sfRole": "BUSINESS_INTELLIGENCE_TOOLS_PII",
              "sfDatabase" : "BUSINESS_INTELLIGENCE",
              "sfSchema" : "DATA_STORE",
              "sfWarehouse" : "BUSINESS_INTELLIGENCE_CRON"           
             }

query = """
select OL.PAYOFFUID,
       LT.LOANID,
       PII.EMAIL,
       PII.FIRSTNAME,
       PII.LASTNAME,
       PII.STREETADDRESS1                                as STREETADDRESS,
       PII.CITY,
       PII.STATE,
       PII.ZIPCODE,
       LT.CHARGEOFFDATE,
       LT.ASOFDATE,
       datediff(day, LT.CHARGEOFFDATE, LT.CHARGEOFFDATE) as DAYSSINCECHARGEOFF,
       LT.RECOVERIESPAIDTODATE                           as RECOVERIES,
       iff(LA.SUSPEND_LETTER = true, 'Y', null)          as EXCLUDELETTER,
       iff(LA.SUSPEND_EMAIL = true, 'Y', null)           as EXCLUDEEMAIL
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
         inner join DATA_STORE.MVW_LOAN_TAPE as LT
                    on OL.PAYOFFUID = LT.PAYOFFUID
         inner join PII.VW_CUSTOMER_INFO as PII
                    on OL.PAYOFFUID = PII.PAYOFFUID
         inner join DATA_STORE.VW_LOAN_ACCOUNT as LA
                    on upper(LA.PAYOFF_LOAN_ID) = upper(LT.LOANID)
where OL.SET_NAME = 'Recovery Monthly Email'
  and OL.SUPPRESSION_FLAG = false
"""

recovery_monthly = (spark
       .read
       .format("snowflake")
       .options(**sf_options)
       .option("query", query)
       .load())

# COMMAND ----------

# Save to S3
local_dir = '/tmp/'
output_dir = f"secrets/{ENV}/RanYin/BI-857_GR_recoveries/"
fname = "recovery_monthly_email_list_{0}.csv".format(date.today())
local_filename = os.path.join(local_dir, fname)
output_filename = os.path.join(output_dir, fname)

recovery_monthly.toPandas().to_csv(local_filename, index=False)

s3= boto3.client('s3')
s3.upload_file(local_filename, "hm-rstudio-datascience-cron", output_filename, ExtraArgs = {'ACL': 'bucket-owner-full-control'})

# COMMAND ----------

# Connect to the SFTP server
output_dir = f"/dbfs/mnt/rstudio/cron/secrets/{ENV}/RanYin/BI-857_GR_recoveries/"
output_filename = os.path.join(output_dir, fname)

host = 'mc9bltz8jrt0t97x71rmj4m56pv8.ftp.marketingcloudops.com'
username = dbutils.secrets.get("SFMC", "username")
password = dbutils.secrets.get("SFMC", "password")
remote_path = '/Import/' + fname

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    ssh.connect(hostname=host, username=username, password=password, port=22)
    sftp = ssh.open_sftp()
    print("Connection successful")

    sftp.put(output_filename, remote_path)

    sftp.close()
finally:
    ssh.close()
