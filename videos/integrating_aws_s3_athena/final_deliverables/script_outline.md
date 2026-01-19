# AWS S3 + Athena Integration - Video Script

**Total Estimated Runtime:** 13-16 minutes

---

## HOOK INTRO (30-45 seconds)

### First 5 Seconds
*(Standing, high energy, direct to camera)*

**Option 1:**
- "What if you didn't have to open the AWS Console again to query your data lake?"

### 6-15 Seconds
*(Set expectations)*

- "In this video, I'm going to show you how to connect the AWS CLI to your AWS data lake, and then - here's the real magic - how to let Claude Code handle the heavy lifting of working with S3 and Amazon Athena for you."

### Rest of Hook (Build the value proposition)

- "The real power here isn't just running AWS commands from your terminal."

- "Claude can take care of searching in S3 and querying Athena for you. You describe what you want in plain English. Claude figures out the right S3 paths, writes the Athena queries, handles the async execution."

- "Your job? Just QC the results."

- "This is delegation, not automation. Big difference."

[Personal anecdote opportunity: Share a specific example of time saved or a complex query Claude wrote for you]
- "For me, my team has multiple reporting jobs that produce csv files that are saved to AWS. If we want to query that data with Athena, we need to navigate to where the data is placed within S3 and then we need to set up the structure within Athena to properly query it, which means we were spending time searching and navigating through interfaces. But now with Claude, it can quickly interpret the information for where data is stored in our S3 buckets and quickley set up the queries from Athena to give me the information. Additionally, it can navigate to S3 and place files there when we need it to."

**Section Transition:**
- "So today to show you the power of this integration, I will first show you how to install the AWS CLI and cover the prerequisites you need to have in order to have it work. Then we will utilize the AWS CLI as if we are doing a real data analysis, placing data into S3 and then analyzing it using Athena, and compare that process to what we would have to do using the AWS Console."

---

## SECTION 1: KEY TERMS (45-60 seconds)

### Opening (10 seconds)

- "Before we jump in, let me quickly define a few terms you'll hear throughout this video."

### Brief Verbal Overview (30-40 seconds)

- "**S3** - Amazon's cloud storage. Think of it as an infinitely expandable hard drive in the sky."

- "**Athena** - A query service that lets you run SQL directly on files in S3. No database server needed."

- "**Data Lake** - A storage approach where you dump raw data first, then figure out how to use it later."

- "**CLI** - Command Line Interface. The text-based terminal where you type commands instead of clicking through a graphical interface."

- "**IAM** - AWS's permission system. Controls who can do what with your cloud resources."

- "**External Table** - A table definition that points to files somewhere else. The data stays in S3, Athena just knows how to read it."

### Transition (5 seconds)

- "I've put detailed definitions in the video description and the README if you want to reference them later."

**Section Transition:**
- "Alright, let's get the AWS CLI set up."

---

## SECTION 2: SETUP AND CONFIGURATION (2-3 minutes)

### Opening (10 seconds)

- "First things first - we need to get the AWS CLI installed and connected to your account."

### Installing AWS CLI v2 (30-45 seconds)
[Show on screen: Terminal commands]

- "AWS CLI v2 is available for Mac, Windows, and Linux. I'll show Mac, but I'll link the other installers in the description."

**Mac installation:**
```bash
# Download and install
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Verify installation
aws --version
```

- "If you're on Windows, there's an MSI installer. Linux, there's a zip file. Links in the description."

### Configuring Access Keys (45-60 seconds)
[Show on screen: aws configure prompts]

- "Now we configure your credentials. Run `aws configure` and enter your access keys."

```bash
aws configure
# AWS Access Key ID: [your key]
# AWS Secret Access Key: [your secret]
# Default region name: us-west-2
# Default output format: json
```

- "Quick note on security: never commit these keys to git, never share them in screenshots. If you do, rotate them immediately."

### IAM Permissions (30-45 seconds)

- "You'll need the right IAM permissions. At minimum, you need S3 read access and Athena query access."

- "The principle of least privilege applies here - only give access to the specific buckets and databases you need."

[Show on screen: IAM policy example or console]

### Verify Your Setup (15 seconds)
[Show on screen: Command output]

```bash
aws sts get-caller-identity
```

- "If you see your account ID and user ARN, you're good to go."

### Pro Tip: Named Profiles (20 seconds)

- "Quick pro tip: if you work with multiple AWS accounts, use named profiles."

```bash
aws configure --profile production
aws configure --profile development

# Then use: aws s3 ls --profile production
```

**Section Transition:**
- "CLI is set up. Now let's look at the data we'll be working with."

---

## SECTION 3: THE DEMO DATASET (60-90 seconds)

### Opening (10 seconds)
*(Explaining the data)*

- "For this demo, I'm using a real climate research dataset from the AWS Data Exchange - not some toy example."

### Dataset Overview (30-40 seconds)
[Show on screen: S3 bucket structure, table preview]

- "This is the California Wildfire and Renewable Energy Projections dataset from Cal-Adapt and Eagle Rock Analytics."

**Key details to mention:**
- S3 Location: `s3://wfclimres/` (public dataset, us-west-2)
- Database: `wildfire_demo`
- Table: `renewable_energy_catalog` (216 rows)

- "What's cool about this dataset is it contains climate model projections for California renewable energy generation - solar PV, wind power, capacity factors across multiple climate scenarios."

### Why This Dataset (20 seconds)

- "I picked this because it's a real catalog that points to terabytes of actual climate projection data. Perfect for showing how to explore and navigate a real data lake, not just a CSV with ten rows."

[Show on screen: Sample of the data columns]

| Column | What it means |
|--------|---------------|
| `installation` | Energy type (pv_distributed, pv_utility, wind) |
| `source_id` | Climate model used |
| `experiment_id` | Scenario (historical, reanalysis, ssp370) |
| `path` | S3 location of actual data files |

**Section Transition:**
- "Now let me show you where this lives in the AWS Console, so you understand what we're replacing with the CLI."

---

## SECTION 4: AWS CONSOLE NAVIGATION (90-120 seconds)

### Opening (10 seconds)

- "Before we automate anything, you need to know what the manual process looks like. This is the 'before' picture."

### Athena Query Editor Walkthrough (45-60 seconds)
[Show on screen: AWS Console screen recording]

**Step-by-step narration:**

1. "First, go to AWS Console, then Athena."
   [Show: Navigate to Athena]

2. "Click Query Editor in the left sidebar."
   [Show: Click on Query Editor]

3. "Select your database from the dropdown - in our case, `wildfire_demo`."
   [Show: Database dropdown selection]

4. "You can see your tables listed here - `renewable_energy_catalog`."
   [Show: Tables panel]

5. "Run a simple query to see what we're working with."
   [Show: Execute query]
   ```sql
   SELECT * FROM wildfire_demo.renewable_energy_catalog LIMIT 20;
   ```

### What to Point Out (20-30 seconds)
[Show on screen: Highlighting each element]

- "Notice the query results displayed in a grid."
- "Query history and saved queries are over here."
- "And every query Athena runs automatically writes results to an S3 bucket - you can grab those CSVs anytime."

### The Problem with This Approach (15 seconds)

- "This works fine for ad-hoc queries. But if you're doing this five, ten, twenty times a day? All that clicking adds up. And good luck scripting this workflow."

[Personal anecdote opportunity: How many times did you have to click through this before you got frustrated enough to automate?]

**Section Transition:**
- "Alright, let's get out of the browser and into the terminal. Here's where it gets good."

---

## SECTION 5: S3 OPERATIONS (2-3 minutes)

### Opening (10 seconds)

- "S3 is your data lake storage. Let's learn to navigate it from the terminal."

### Listing Buckets and Objects (30-45 seconds)
[Show on screen: Terminal output]

```bash
# List all buckets
aws s3 ls

# List bucket contents
aws s3 ls s3://kclabs-athena-demo-2025/

# List with details
aws s3 ls s3://kclabs-athena-demo-2025/ --human-readable --summarize
```

- "The `--human-readable` flag shows file sizes in MB and GB instead of bytes. The `--summarize` flag gives you totals."

### Uploading Files (30-45 seconds)
[Show on screen: Upload command and S3 verification]

```bash
# Upload a single file
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/

# Upload a directory
aws s3 cp ./local-dir s3://bucket-name/prefix/ --recursive
```

- "The `cp` command is your workhorse for moving files between local and S3, or between buckets."

### Syncing Directories (30-45 seconds)
[Show on screen: Sync command]

```bash
# Sync local to S3
aws s3 sync ./local-dir s3://bucket-name/prefix/

# Sync with delete (mirror exactly)
aws s3 sync ./local-dir s3://bucket-name/prefix/ --delete
```

- "Sync is smart - it only uploads files that have changed. The `--delete` flag makes S3 match your local exactly, removing files that don't exist locally."

### Working with Partitioned Data (20 seconds)

- "Real data lakes are usually partitioned by date or category. The CLI handles this naturally - just specify the path."

### Presigned URLs (20 seconds)
[Show on screen: Presigned URL output]

```bash
aws s3 presign s3://bucket-name/file.csv --expires-in 3600
```

- "Need to share a file temporarily without giving someone AWS access? Presigned URLs. They expire after the time you specify."

**Section Transition:**
- "Data's in S3. Now let's make it queryable with Athena."

---

## SECTION 6: ATHENA QUERIES FROM CLI (2-3 minutes)

### Opening (10 seconds)

- "Athena queries work a bit differently from the CLI. It's asynchronous - you start a query, it runs in the background, then you fetch the results."

### Starting a Query (45-60 seconds)
[Show on screen: Command and output]

```bash
# Start query execution
aws athena start-query-execution \
  --query-string "SELECT * FROM wildfire_demo.renewable_energy_catalog LIMIT 10" \
  --work-group "primary" \
  --query-execution-context Database=wildfire_demo \
  --result-configuration OutputLocation=s3://kclabs-athena-results-2025/
```

- "This returns a Query Execution ID. Think of it like a ticket number - you use it to check status and get results."

### Checking Status and Getting Results (45-60 seconds)
[Show on screen: Status check and results]

```bash
# Check query status
aws athena get-query-execution --query-execution-id $QUERY_ID \
  --query 'QueryExecution.Status.State' --output text

# Get results when complete
aws athena get-query-results --query-execution-id $QUERY_ID
```

- "The status will be RUNNING, SUCCEEDED, FAILED, or CANCELLED. Once it's SUCCEEDED, you can fetch the results."

### Parsing Results with jq (30 seconds)
[Show on screen: jq output]

```bash
# Clean up the JSON output
aws athena get-query-results --query-execution-id $QUERY_ID | \
  jq -r '.ResultSet.Rows[] | [.Data[].VarCharValue] | @csv'
```

- "The raw output is verbose JSON. Use jq to extract just the data you need."

### Cost Awareness (20 seconds)

- "Quick cost note: Athena charges about five dollars per terabyte scanned. Use workgroups to set query limits and avoid surprise bills."

**Section Transition:**
- "Now let's put it all together in a real workflow."

---

## SECTION 7: PRACTICAL WORKFLOW DEMO (4-5 minutes)

### Opening (10 seconds)

- "Here's the complete end-to-end workflow: CSV to S3, create a table, run analysis, export results."

---

### Step 1: Upload Data to S3 (60-90 seconds)

#### The Data (15 seconds)
[Show on screen: CSV preview]

- "We're using a simple sales dataset - ten rows of regional sales data."

```
order_id,customer_id,product_name,quantity,unit_price,order_date,region
1001,C001,Widget A,5,29.99,2024-01-15,North
1002,C002,Widget B,3,49.99,2024-01-16,South
...
```

#### Console Method (20 seconds)
[Show on screen: S3 Console screen recording]

- "In the console, you'd navigate to your bucket, create a folder, click upload, select the file, confirm."
- "Five clicks minimum, plus wait time."

#### CLI Method (20 seconds)
[Show on screen: Terminal commands]

```bash
aws s3 cp sample_sales.csv s3://kclabs-athena-demo-2025/sales-demo/
aws s3 ls s3://kclabs-athena-demo-2025/sales-demo/
```

- "One command. Done. Data's in S3."

**Talking point:**
- "Data's uploaded. Now let's make it queryable."

---

### Step 2: Create Database and Table (90-120 seconds)

#### In Athena Console (30 seconds)
[Show on screen: Athena Query Editor]

- "In the console, open Query Editor, run these two queries."

#### Create Database (15 seconds)
[Show on screen: Query execution]

```sql
CREATE DATABASE IF NOT EXISTS sales_demo;
```

#### Create External Table (45 seconds)
[Show on screen: Query and explanation]

```sql
CREATE EXTERNAL TABLE sales_demo.sales (
  order_id INT,
  customer_id STRING,
  product_name STRING,
  quantity INT,
  unit_price DOUBLE,
  order_date DATE,
  region STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION 's3://kclabs-athena-demo-2025/sales-demo/'
TBLPROPERTIES ('skip.header.line.count'='1');
```

- "This creates an external table - it's just metadata, a schema definition pointing to S3. The data stays where it is. Athena reads directly from the files."

#### Verify (15 seconds)
[Show on screen: Table appearing in left panel]

- "You'll see the new database and table appear in the left panel. Click the table and hit Preview to see the data."

**Talking point:**
- "The table is just a pointer. Athena reads directly from S3. No data copying, no ETL pipeline."

---

### Step 3: Run Analysis Query (60-90 seconds)

#### The Business Question (10 seconds)

- "Let's answer a real question: What's the total revenue by region?"

#### Run the Query (30-40 seconds)
[Show on screen: Query execution and results grid]

```sql
SELECT
  region,
  COUNT(*) as order_count,
  SUM(quantity) as total_units,
  ROUND(SUM(quantity * unit_price), 2) as total_revenue
FROM sales_demo.sales
GROUP BY region
ORDER BY total_revenue DESC;
```

#### What to Point Out (20-30 seconds)
[Show on screen: Highlighting each element]

- "Results grid shows our aggregated data by region."
- "Query execution time is at the bottom - fraction of a second for this small dataset."
- "Data scanned shows you the cost - about five dollars per terabyte."
- "Query history tab lets you re-run or reference past queries."

**Talking point:**
- "Standard SQL, but running directly against files in S3. No data loading, no ETL pipeline - just query."

[Personal anecdote opportunity: Example of a complex analysis you ran this way, or a time when the simplicity of this approach saved you hours]

---

### Step 4: Export Results to S3 (45-60 seconds)

#### Finding the Results (20-30 seconds)
[Show on screen: S3 Console showing results bucket]

- "Every Athena query automatically saves results to your designated S3 bucket."

1. Navigate to `s3://kclabs-athena-results-2025/`
2. Find the query result file (named by query execution ID)
3. You'll see a `.csv` and `.metadata` file for each query

#### Download via CLI (15-20 seconds)
[Show on screen: Terminal commands]

```bash
aws s3 cp s3://kclabs-athena-results-2025/{query-id}.csv ./results.csv
cat ./results.csv
```

**Talking point:**
- "Every Athena query automatically saves results to S3. Grab the CSV anytime, share it, or feed it into another process."

---

### Step 5: Cleanup (30-45 seconds)

[Show on screen: Cleanup commands]

- "Good hygiene: clean up when you're done experimenting."

```sql
DROP TABLE IF EXISTS sales_demo.sales;
DROP DATABASE IF EXISTS sales_demo;
```

```bash
aws s3 rm s3://kclabs-athena-demo-2025/sales-demo/ --recursive
```

**Talking point:**
- "Tables are just pointers, but the S3 data persists until you delete it. Don't leave test data lying around accumulating storage costs."

**Section Transition:**
- "That's the manual CLI workflow. But here's where it gets really powerful..."

---

## SECTION 8: THE CLAUDE INTEGRATION (60-90 seconds)

*If including AI delegation content*

### The Real Workflow (30 seconds)

- "Everything I just showed you? I rarely type those commands anymore."

- "Instead, I tell Claude: 'Find all the wind power projections in the wildfire dataset and summarize by climate model.'"

- "Claude figures out the S3 paths, writes the Athena query, handles the async execution, and presents me with results to review."

### What This Means (30 seconds)

- "My job becomes quality control, not query writing."

- "I'm delegating the execution to Claude while retaining oversight of the results."

- "That's the difference between automation and delegation. Automation replaces you. Delegation frees you to focus on higher-value work."

[Personal anecdote opportunity: Specific example of a complex multi-step analysis Claude handled for you]

---

## CLOSING (45-60 seconds)

### Recap (15-20 seconds)

- "To recap: we installed the AWS CLI, connected it to S3 and Athena, and walked through a complete data lake workflow - upload, create table, query, export, cleanup."

### The Value Proposition (15-20 seconds)

- "The console is fine for exploration. But if you're doing this work regularly, the CLI is faster, scriptable, and - most importantly - it opens the door to AI delegation."

### Call to Action (15-20 seconds)

- "If this helped you work faster with S3 and Athena, drop a like and subscribe."

- "I'm creating more content on AI-assisted data engineering workflows, so hit that bell if you want to see what's next."

- "Also apologies for the sporadic releases of my video, with the birth of my son, time has been more difficult to come by, but I'm planning on releasing on more normal schedule here shortly."

- "Thanks so much for watching. See you in the next one."

---

## APPENDIX: QUICK REFERENCE COMMANDS

*Optional on-screen graphic or linked resource*

```bash
# S3 Basics
aws s3 ls
aws s3 cp file.csv s3://bucket/path/
aws s3 sync ./local s3://bucket/prefix/

# Athena
aws athena start-query-execution --query-string "SQL" --work-group primary
aws athena get-query-execution --query-execution-id ID
aws athena get-query-results --query-execution-id ID

# Identity Check
aws sts get-caller-identity
```

---

## PRODUCTION NOTES

**B-Roll Needed:**
- AWS Console navigation (S3, Athena)
- Terminal with CLI commands executing
- Query results appearing
- File upload progress

**Graphics Needed:**
- Key terms overlay
- S3/Athena architecture diagram
- Cost breakdown visual
- CLI vs Console comparison

**Screen Recording Checklist:**
- [ ] S3 bucket navigation
- [ ] Athena Query Editor
- [ ] Terminal with clean prompt
- [ ] Query results grid
- [ ] Results bucket in S3
