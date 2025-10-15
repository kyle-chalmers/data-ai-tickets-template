# Databricks notebook source
# MAGIC %sh
# MAGIC pip install paramiko

# COMMAND ----------

dbutils.widgets.removeAll()
dbutils.widgets.dropdown("env", "dev", ["dev", "qa", "staging", "prod"])

ENV = dbutils.widgets.get("env")
print(ENV)

# COMMAND ----------

import pandas as pd
from datetime import date, timedelta
import os
import base64
import paramiko

timestr = date.today()
output_dir = "/tmp/"

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

# Get Bounce data from Snowflake
# Uses same query structure as SIMM but filters for BOUNCE set
query = '''
select L.LOAN_ID                                                            as ACCOUNT_NUMBER,
       OL.PAYOFFUID                                                         as PAYOFFUID,
       LT.LOANID                                                            as PAYOFF_LOAN_ID,
       PII.FIRST_NAME                                                       as PRIMARY_FIRST_NAME,
       null                                                                 as PRIMARY_MIDDLE_NAME,
       PII.LAST_NAME                                                        as PRIMARY_LAST_NAME,
       null                                                                 as COBORROWER_FIRST_NAME,
       null                                                                 as COBORROWER_MIDDLE_NAME,
       null                                                                 as COBORROWER_LAST_NAME,
       PII.PHONE_NUMBER                                                     as PRIMARY_WORK_PHONE,
       PII.PHONE_NUMBER                                                     as PRIMARY_HOME_PHONE,
       PII.PHONE_NUMBER                                                     as PRIMARY_CELL_PHONE,
       PII.EMAIL                                                            as PRIMARY_EMAIL,
       null                                                                 as COBORROWER_WORK_PHONE,
       null                                                                 as COBORROWER_HOME_PHONE,
       null                                                                 as COBORROWER_CELL_PHONE,
       null                                                                 as COBORROWER_EMAIL,
       LT.REMAININGPRINCIPAL + LT.ACCRUEDINTEREST                           as CURRENT_BALANCE,
       SA.AMOUNT_DUE                                                        as AMOUNT_DELINQUENT,
       LT.DAYSPASTDUE                                                       as DAYS_DELINQUENT,
       LT.LASTPAYMENTDATE                                                   as DATE_LAST_PAYMENT,
       LT.LASTPAYMENTAMOUNT                                                 as AMOUNT_LAST_PAYMENT,
       PII.ADDRESS_1                                                        as ADDRESS1,
       PII.ADDRESS_2                                                        as ADDRESS2,
       PII.CITY                                                             as CITY,
       PII.STATE                                                            as STATE,
       PII.ZIP_CODE                                                         as ZIP_CODE,
       PII.SSN                                                              as PRI_SSN,
       null                                                                 as COB_SSN,
       LT.ORIGINATIONDATE                                                   as OPEN_DATE,
       try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"1":"amount-due"::float as DEL_1_CYCLE_AMT,
       try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"2":"amount-due"::float as DEL_2_CYCLE_AMT,
       try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"3":"amount-due"::float as DEL_3_CYCLE_AMT,
       try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"4":"amount-due"::float as DEL_4_CYCLE_AMT,
       try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"5":"amount-due"::float as DEL_5_CYCLE_AMT,
       try_parse_json(SA.DELINQUENT_BUCKET_BALANCE):"6":"amount-due"::float as DEL_6_CYCLE_AMT
from CRON_STORE.RPT_OUTBOUND_LISTS as OL
         inner join DATA_STORE.MVW_LOAN_TAPE as LT
                    on OL.PAYOFFUID = LT.PAYOFFUID
         inner join ANALYTICS.VW_LOAN as L
                    on OL.PAYOFFUID = L.LEAD_GUID
         inner join ANALYTICS_PII.VW_MEMBER_PII as PII
                    on L.MEMBER_ID = PII.MEMBER_ID
                        and PII.MEMBER_PII_END_DATE is null
         inner join BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT as SA
                    on L.LOAN_ID = SA.LOAN_ID::string
                        and SA.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                        and SA.DATE = current_date
where OL.SET_NAME = 'BOUNCE'
  and OL.LIST_NAME = 'DPD3-119'
  and OL.SUPPRESSION_FLAG = false
'''

query_construct = (spark
    .read
    .format("snowflake")
    .options(**sf_options)
    .option("query", query)
    .load())
data = query_construct.toPandas()

# COMMAND ----------

# Write to csv with Bounce-specific filename
fname = f"Happy_Money_Bounce_DPD3-119_{timestr.strftime('%Y%m%d')}.csv"
output_filename = os.path.join(output_dir, fname)
data.to_csv(output_filename, index=False)
print(f"wrote {output_filename}")
print(f"Record count: {len(data)}")

# COMMAND ----------

if ENV == "prod":
  # Upload to Bounce SFTP using existing credentials
  # Based on DI-1141 SFTP setup: sftp.finbounce.com with SSH key authentication
  
  host = "sftp.finbounce.com"
  username = "happy-money"
  private_key_path = "/dbfs/FileStore/shared_uploads/bounce_sftp_key"  # Store SSH key in DBFS
  remote_path = "/lendercsvbucket/happy-money/" + fname
  local_file_path = output_filename

  # Load SSH private key
  private_key = paramiko.RSAKey.from_private_key_file(private_key_path)
  
  ssh = paramiko.SSHClient()
  ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

  try:
    ssh.connect(hostname=host, username=username, pkey=private_key, port=22)
    sftp = ssh.open_sftp()
    print("Connection established to Bounce SFTP.")

    sftp.put(local_file_path, remote_path)
    print(f"File uploaded successfully to {remote_path}")
    print(f"Records transferred: {len(data)}")

    sftp.close()
  except Exception as e:
    print(f"SFTP upload failed: {str(e)}")
    raise e
  finally:
    ssh.close()
else:
  print(f"Development mode - skipping SFTP upload. File ready at: {output_filename}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## Job Completion Summary
# MAGIC 
# MAGIC **Job**: DI-862_BOUNCE_File_Upload  
# MAGIC **Purpose**: Daily upload of Bounce collections accounts to SFTP  
# MAGIC **File Format**: Same as SIMM (Happy_Money_Bounce_DPD3-119_YYYYMMDD.csv)  
# MAGIC **Schedule**: Daily (part of BI-2482_Outbound_List_Generation workflow)  
# MAGIC **SFTP**: sftp.finbounce.com:/lendercsvbucket/happy-money/  
# MAGIC 
# MAGIC **Dependencies**:
# MAGIC - BI-2482_Outbound_List_Generation_for_GR (must run first to populate RPT_OUTBOUND_LISTS)
# MAGIC - Bounce SFTP credentials and SSH key access
# MAGIC 
# MAGIC **Business Logic**:
# MAGIC - Filters for SET_NAME = 'BOUNCE' and LIST_NAME = 'DPD3-119'
# MAGIC - Uses same file format as SIMM for Bounce compatibility
# MAGIC - Applies all suppression logic from outbound list generation
# MAGIC 
# MAGIC **File Naming**: Happy_Money_Bounce_DPD3-119_YYYYMMDD.csv