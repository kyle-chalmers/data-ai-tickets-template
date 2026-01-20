# Demo Scripts - Quick Reference

Copy-paste commands for live demo execution. Keep this file open during presentation.

**Quick Navigation:**
- [Pre-Demo Verification](#pre-demo-verification)
- [Foundation Section](#foundation-section---terminal-commands)
- [Demo 1: CO2 Analysis](#demo-1-climate-data-analysis-jira---s3---snowflake)
- [Demo 2: Databricks Job](#demo-2-databricks-job---automated-climate-pipeline-12-minutes)
- [Cleanup](#cleanup-after-demo)
- [Troubleshooting](#troubleshooting)

---

## Foundation Section - Terminal Commands

**Show repo structure:**
```bash
ls -la
```

**Show tickets folder:**
```bash
ls -la tickets/kchalmers/
```

**Show inside a ticket folder:**
```bash
ls -la tickets/kchalmers/KAN-4/
```

**Show numbered deliverables:**
```bash
ls tickets/kchalmers/KAN-4/final_deliverables/
```

**View CLAUDE.md (use less for scrolling):**
```bash
less CLAUDE.md
```

**CLAUDE.md key sections to scroll to:**
- Role definition: Line ~37 (search: `/Assistant Role`)
- Permission hierarchy: Line ~65 (search: `/Permission Hierarchy`)
- CLI Tools: Line ~205 (search: `/Available CLI Tools`)

**Show commands folder:**
```bash
ls .claude/commands/
```

---

## Pre-Demo Verification

Run these commands 30 minutes before presentation to verify all connections:

```bash
# 1. Snowflake
snow connection list
snow sql -q "SELECT 1" --format csv

# 2. AWS
aws sts get-caller-identity
aws s3 ls s3://kclabs-athena-demo-2026/

# 3. Jira
acli jira project list --filter "KAN"

# 4. Databricks
databricks workspace list / --profile bidev

# 5. Open-Meteo API (Demo 2 data source)
curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-05&daily=temperature_2m_max" | head -100

# 6. Repository
git checkout main && git pull
```

**Expected Results:**
- Snowflake: Connection list shows default connection, query returns "1"
- AWS: Shows account ID and user ARN
- Jira: Shows KAN project in list
- Databricks: Shows workspace root directory
- Open-Meteo: Returns JSON with temperature data
- Git: Clean working directory on main branch

---

## Demo 1: Climate Data Analysis (Jira -> S3 -> Snowflake)

### Overview
This demo showcases a complete data workflow:
1. Create a Jira ticket from a conversational request
2. Download public climate data (CO2 emissions)
3. Upload to S3
4. Load into Snowflake
5. Analyze and get insights
6. Close the Jira ticket

**Dataset:** Our World in Data CO2 Emissions
**Source:** https://owid-public.owid.io/data/co2/owid-co2-data.csv

---

### Main Prompt for Claude (Type This)

```
I need help with a data analysis project. Here's what I'm thinking:

We should analyze global CO2 emissions to understand which countries are the biggest emitters and how that's changed over time. I found a dataset from Our World in Data that has emissions by country from 1750 to 2024.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Download the data from https://owid-public.owid.io/data/co2/owid-co2-data.csv
3. Upload it to our S3 bucket at kclabs-athena-demo-2026
4. Load it into Snowflake so we can query it
5. Find the top 10 emitting countries in 2024
6. Show how US emissions have changed since 2000

Once we have results, mark the ticket as done.
```

---

### What to Narrate During Demo

**When Claude creates the Jira ticket:**
"Notice Claude understood 'create a ticket' and figured out the right CLI tool - acli. It's using the KAN project as I mentioned."

**When Claude downloads the data:**
"Claude is pulling the CSV directly from the public URL. No browser needed."

**When Claude uploads to S3:**
"Now it's pushing to our S3 bucket using the AWS CLI. Watch for the upload confirmation."

**When Claude creates the Snowflake table:**
"Here's where it gets interesting - Claude is examining the CSV structure and creating a matching table schema. It figured out the column types from the data."

**When Claude runs analysis:**
"The SQL queries give us real insights. Look - [country] is the top emitter, followed by [country]..."

**When Claude closes the ticket:**
"And finally, transitioning the Jira ticket to Done. Full workflow, one conversation."

---

### Reference Commands (Backup if Live Demo Fails)

**Create Jira Ticket:**
```bash
acli jira workitem create --project KAN \
  --type Task \
  --summary "Analyze global CO2 emissions from Our World in Data" \
  --description "Download CO2 emissions dataset, load to Snowflake, analyze top emitters and US trends."
```

**Download Dataset:**
```bash
curl -o /tmp/owid-co2-data.csv "https://owid-public.owid.io/data/co2/owid-co2-data.csv"
```

**Preview Data:**
```bash
head -5 /tmp/owid-co2-data.csv
wc -l /tmp/owid-co2-data.csv
```

**Upload to S3:**
```bash
aws s3 cp /tmp/owid-co2-data.csv s3://kclabs-athena-demo-2026/co2-emissions/owid-co2-data.csv
```

**Verify S3 Upload:**
```bash
aws s3 ls s3://kclabs-athena-demo-2026/co2-emissions/ --human-readable
```

**Create Snowflake Stage and Table:**
```sql
-- Create stage for S3
CREATE OR REPLACE STAGE DEMO_DATA.PUBLIC.CO2_STAGE
  URL = 's3://kclabs-athena-demo-2026/co2-emissions/'
  CREDENTIALS = (AWS_KEY_ID = '...' AWS_SECRET_KEY = '...');

-- Create table
CREATE OR REPLACE TABLE DEMO_DATA.PUBLIC.CO2_EMISSIONS (
    country VARCHAR,
    year INTEGER,
    iso_code VARCHAR(10),
    population FLOAT,
    gdp FLOAT,
    co2 FLOAT,
    co2_per_capita FLOAT,
    coal_co2 FLOAT,
    oil_co2 FLOAT,
    gas_co2 FLOAT,
    share_global_co2 FLOAT
    -- ... additional columns as needed
);

-- Load data
COPY INTO DEMO_DATA.PUBLIC.CO2_EMISSIONS
FROM @DEMO_DATA.PUBLIC.CO2_STAGE
FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');
```

**Top 10 Emitters Query:**
```sql
SELECT
    country,
    iso_code,
    ROUND(co2, 2) as co2_million_tonnes,
    ROUND(co2_per_capita, 2) as co2_per_capita_tonnes,
    ROUND(share_global_co2, 2) as pct_of_global
FROM DEMO_DATA.PUBLIC.CO2_EMISSIONS
WHERE year = 2024
  AND iso_code IS NOT NULL
  AND LENGTH(iso_code) = 3
  AND co2 IS NOT NULL
ORDER BY co2 DESC
LIMIT 10;
```

**US Trend Query:**
```sql
SELECT
    year,
    ROUND(co2, 2) as co2_million_tonnes,
    ROUND(co2_per_capita, 2) as per_capita,
    ROUND(coal_co2, 2) as from_coal,
    ROUND(oil_co2, 2) as from_oil,
    ROUND(gas_co2, 2) as from_gas
FROM DEMO_DATA.PUBLIC.CO2_EMISSIONS
WHERE country = 'United States'
  AND year >= 2000
ORDER BY year;
```

**Transition Jira Ticket:**
```bash
acli jira workitem transition --key "KAN-XX" --status "Done"
```

---

## TRANSITION: Clear Session Before Demo 2

```
/clear
```

---

## Demo 2: Databricks Job - Automated Climate Pipeline (12 minutes)

### Overview
This demo showcases building infrastructure/ETL tasks:
1. Create a Jira ticket from a conversational request
2. Research and identify a climate data API
3. Create a Databricks job that fetches data monthly
4. Deploy and test the job
5. Close the Jira ticket

**Key Difference from Demo 1:** This shows Claude handling infrastructure and automation, not just analysis.

**Data Source:** Open-Meteo Historical Weather API (free, no auth required)
**Target:** Databricks job that runs monthly to collect Arizona weather data

---

### Main Prompt for Claude (Type This)

```
I need to set up automated climate data collection for Arizona. Here's what I'm thinking:

Our team wants to track weather patterns across Arizona cities for climate analysis. We need a scheduled job that pulls weather data monthly and stores it somewhere we can query.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Research what free climate data APIs are available
3. Create a Databricks job that fetches monthly weather data for Arizona cities
4. The job should run on the 3rd of each month and pull the previous month's data
5. Deploy it to our Databricks workspace (use the bidev profile)
6. Run a test to make sure it works
7. Close the ticket with a summary of what was built

I want to see your reasoning on what API to use and how to handle scheduling.
```

---

### What to Narrate During Demo

**When Claude creates the Jira ticket:**
"First, Claude creates a ticket in our KAN project. Watch how it figures out the right CLI tool - `acli jira workitem create`."

**When Claude researches APIs:**
"Now Claude is researching climate data APIs. Watch the reasoning - it's evaluating options based on: free access, no authentication required, data freshness. It'll pick Open-Meteo because it meets all criteria."

**Reasoning Points to Highlight:**
- "Why monthly on the 3rd? Claude figured out the API has a 5-day lag, so running on the 3rd ensures all previous month data is available."
- "Error handling - notice it's adding retries and validation. That's senior engineer thinking."
- "Cluster sizing - it chose a single-node cluster because this is a small job. No over-provisioning."

**When Claude creates the job code:**
"Claude is creating a Python script. Notice it's handling API failures gracefully, validating data before saving, and using logging for visibility."

**When Claude deploys to Databricks:**
"Now deploying using the Databricks CLI. First uploading the script to DBFS, then creating the job from a config file."

**When Claude tests the job:**
"Let's trigger a manual run to verify it works. Claude uses `databricks jobs run-now`."

**When Claude closes the ticket:**
"And finally closing the Jira ticket with a summary. Full infrastructure workflow, one conversation."

---

### Reference Commands (Backup if Live Demo Fails)

**Create Jira Ticket:**
```bash
acli jira workitem create --project KAN \
  --type Task \
  --summary "Set up automated climate data collection for Arizona" \
  --description "Create Databricks job to fetch monthly weather data from Open-Meteo API for Arizona cities."
```

**Test API (verify data source works):**
```bash
curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=America/Phoenix" | jq '.daily'
```

**Upload Job Script to DBFS:**
```bash
databricks fs cp databricks_jobs/climate_data_refresh/climate_refresh.py \
  dbfs:/jobs/climate_data_refresh/climate_refresh.py --profile bidev
```

**Create Databricks Job:**
```bash
databricks jobs create --json-file databricks_jobs/climate_data_refresh/job_config.json --profile bidev
```

**List Jobs (get job ID):**
```bash
databricks jobs list --profile bidev | grep "Climate Data"
```

**Trigger Manual Run:**
```bash
JOB_ID=$(databricks jobs list --profile bidev | grep "Climate Data" | awk '{print $1}')
databricks jobs run-now --job-id $JOB_ID --profile bidev
```

**Check Run Status:**
```bash
RUN_ID=$(databricks runs list --job-id $JOB_ID --limit 1 --profile bidev | tail -1 | awk '{print $1}')
databricks runs get --run-id $RUN_ID --profile bidev
```

**Add Comment to Jira:**
```bash
acli jira workitem comment --key "KAN-XX" --body "Job deployed and tested successfully. Monthly schedule active."
```

**Transition Jira Ticket:**
```bash
acli jira workitem transition --key "KAN-XX" --status "Done"
```

---

### Local Testing (Before Demo)

**Test the Python script locally:**
```bash
cd databricks_jobs/climate_data_refresh
pip install requests python-dateutil
python climate_refresh.py
```

**Expected output:**
```
Climate Data Refresh Job - Starting
Processing month: 2024-12
Date range: 2024-12-01 to 2024-12-31
Cities to process: 10
  Phoenix: Avg temp 12.3C, Precip 0.0mm
  Tucson: Avg temp 11.8C, Precip 0.0mm
  ...
Job completed successfully - 10 records ready for Delta table
```

---

## Cleanup (After Demo)

```bash
# Return to main
git checkout main

# Delete demo branch
git branch -d [branch-name]

# Clean tickets folder
git clean -fd tickets/

# Optional: Remove demo data from Snowflake
snow sql -q "DROP TABLE IF EXISTS DEMO_DATA.PUBLIC.CO2_EMISSIONS"
```

---

## Troubleshooting

**Snowflake connection issues:**
```bash
snow connection test
```

**Jira CLI issues:**
```bash
acli jira project list
```

**Databricks connection issues:**
```bash
databricks workspace list / --profile bidev
```

**Databricks job stuck:**
```bash
# Cancel a running job
databricks runs cancel --run-id $RUN_ID --profile bidev
```

**Claude not responding:**
```
/clear
```

**S3 permission denied:**
```bash
aws sts get-caller-identity
aws s3 ls s3://kclabs-athena-demo-2026/ --debug 2>&1 | head -20
```

---

# APPENDIX: DEMO PROMPTS

## Demo 1: Complete Pipeline (CO2 Data)
```
I need help with a data analysis project. Here's what I'm thinking:

We should analyze global CO2 emissions to understand which countries are the biggest emitters and how that's changed over time. I found a dataset from Our World in Data that has emissions by country from 1750 to 2024.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Download the data from https://owid-public.owid.io/data/co2/owid-co2-data.csv
3. Upload it to our S3 bucket at kclabs-athena-demo-2026
4. Load it into Snowflake so we can query it
5. Find the top 10 emitting countries in 2024
6. Show how US emissions have changed since 2000

Once we have results, mark the ticket as done.
```

## Demo 2: Databricks Job (Infrastructure/ETL)
```
I need to set up automated climate data collection for Arizona. Here's what I'm thinking:

Our team wants to track weather patterns across Arizona cities for climate analysis. We need a scheduled job that pulls weather data monthly and stores it somewhere we can query.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Research what free climate data APIs are available
3. Create a Databricks job that fetches monthly weather data for Arizona cities
4. The job should run on the 3rd of each month and pull the previous month's data
5. Deploy it to our Databricks workspace (use the bidev profile)
6. Run a test to make sure it works
7. Close the ticket with a summary of what was built

I want to see your reasoning on what API to use and how to handle scheduling.
```
