# AWS S3 + Athena Integration - Script Outline

## HOOK

- **Option 1:** "What if you never had to open the AWS Console again to query your data lake?"

- **Option 2:** "I used to spend 15 minutes just clicking through the AWS Console to run a simple query. Now I do it in one sentence. Let me show you how."

- **Option 3:** "Your data lake is sitting there, full of insights. But if you're still clicking through S3 and Athena in the browser, you're working harder than you need to."

---

## INTRO

- The real power here isn't just running AWS commands from your terminal
- Claude can take care of searching in S3 and querying Athena for you
- You describe what you want in plain English
- Claude figures out the right S3 paths, writes the Athena queries, handles the async execution
- Your job? Just QC the results
- This is delegation, not automation

---

## THE LESSONS AND THE VALUE

### Section 1: Setup and Configuration
- Installing AWS CLI v2 on Mac/Windows/Linux
- Running `aws configure` with access keys
- Setting up IAM permissions for S3 and Athena (least privilege)
- Verifying your setup: `aws sts get-caller-identity`
- Pro tip: Using named profiles for multiple AWS accounts

### Section 2: S3 Operations
- Listing buckets and exploring objects: `aws s3 ls`
- Uploading files to S3 in one command: `aws s3 cp`
- Syncing entire directories: `aws s3 sync`
- Working with partitioned data lake structures
- Generating presigned URLs for sharing

### Section 3: Athena Queries
- Running SQL queries from the terminal: `aws athena start-query-execution`
- Waiting for results and fetching them: `aws athena get-query-results`
- Managing databases and tables via Glue Catalog
- Cost optimization: workgroups and query limits
- Parsing results with jq

### Section 4: Practical Workflow Demo
- Complete example: CSV → S3 → Create Table → Query → Export
- "Upload this sales data to S3 and create an Athena table for it"
- "Query the table for Q4 totals by region"
- "Export the results to a local CSV"
- Building reusable patterns for daily work

---

## CLOSING

- Thanks so much for watching
- If this helped you work faster with S3 and Athena, drop a like and subscribe
- See you in the next one
