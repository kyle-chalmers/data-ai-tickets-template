# Debt Sale Deliverables Workflow Instructions

## Overview

This document provides step-by-step instructions for handling **Phase 2** debt sale deliverable requests (Marketing Goodbye Letters, Credit Reporting Lists, Bulk Upload Lists). This is typically the **follow-up ticket** to debt sale population analysis tickets.

## Business Process Flow

### **Phase 1: Debt Sale Population Analysis** (e.g., DI-1141)
- Generate comprehensive loan population for debt sale
- Apply business exclusions (fraud, SCRA, deceased, bankruptcy)
- Create main analysis table with full loan details
- Produce loan-level and transaction reports for buyer due diligence

### **Phase 2: Debt Sale Deliverables** (e.g., DI-1151) ⬅️ **THIS PROCESS**
- **Input**: Selection results from stakeholder/buyer (status: "Included", "Bankrupt", "Deceased")
- **Output**: Three operational files for loan transfer process
- **Purpose**: Enable loan servicing transfer and compliance requirements

## Prerequisites

### Prerequisite Requirements

#### **1. Completed Phase 1 Ticket** 
Must have completed debt sale population analysis ticket (e.g., DI-1141) with:
- ✅ **Main Analysis Table**: Comprehensive debt sale analysis (e.g., `BOUNCE_DEBT_SALE_Q2_2025_SALE`)
  - Created by Phase 1 ticket (typically DI-114X series)
  - Contains full loan population with business exclusions applied
  - Located in `BUSINESS_INTELLIGENCE_DEV.CRON_STORE`
  - **⚠️ CRITICAL**: Never overwrite this table - it's the authoritative data source

#### **2. Selection Results File**
CSV provided by stakeholder/buyer with final loan selections:
- **Format**: Contains status field with values like "Included", "Bankrupt", "Deceased"
- **Key Value**: "Included" status = loans selected for actual debt sale
- **Source**: Provided by business team after buyer due diligence review
- **Purpose**: Filters Phase 1 population to final selected loans

#### **3. Template Files**
Previous deliverable SQL templates from Google Drive:
- **Location**: `/Data Intelligence/Tickets/Kyle Chalmers/DI-9XX/`
- **Marketing Template**: `Notice_Of_Servicing_Transfer_updated.sql` (from DI-971)
- **Credit/Bulk Templates**: `BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql` (from DI-972)

#### **4. Stakeholder Context**
- **Business Purpose**: Loan servicing transfer to buyer
- **Compliance Requirements**: Credit reporting updates, LoanPro system placement status
- **Communication**: Marketing goodbye letters to borrowers

## Step-by-Step Workflow

### 1. Project Setup and Validation

#### 1.1 Initial Setup
```bash
# Create ticket folder structure
mkdir -p tickets/[team_member]/DI-XXXX/{source_materials,final_deliverables,qc_queries}
mkdir -p tickets/[team_member]/DI-XXXX/final_deliverables/sql_queries

# Copy selection results file with clean name
cp "[original_file].csv" "tickets/[team_member]/DI-XXXX/source_materials/[debt_sale]_selection_results.csv"
```

#### 1.2 Validate Prerequisites
```sql
-- STEP 1: Verify Phase 1 table exists and contains data
SELECT COUNT(*) as total_loans, 
       MIN(CHARGEOFFDATE) as earliest_chargeoff,
       MAX(CHARGEOFFDATE) as latest_chargeoff
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME];
-- Example: BOUNCE_DEBT_SALE_Q2_2025_SALE

-- STEP 2: Check table structure and key fields
DESCRIBE TABLE BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME];
```

#### 1.3 Critical Validation Checkpoints
- ✅ **Phase 1 table exists** with expected loan count
- ✅ **Selection CSV provided** with "Included"/"Excluded" status
- ✅ **Template files accessible** in Google Drive
- ✅ **Related Phase 1 ticket reference** for context

⚠️ **CRITICAL**: Do NOT overwrite the main analysis table. It contains comprehensive loan analysis from Phase 1.

### 3. Create and Populate SELECTED Table

#### 3.1 Extract Selected Loan IDs from CSV
```python
# Python script to extract "Included" status loans
import csv
import json

included_loans = []
with open('source_materials/[selection_file].csv', 'r') as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    for row in reader:
        if row[1] == 'Included':  # Status column (adjust index if needed)
            included_loans.append(row[6])  # EXTERNAL_ACCOUNT_ID column (adjust index)

# Save to JSON for SQL use
with open('included_loans.json', 'w') as f:
    json.dump(included_loans, f)
```

#### 3.2 Create SELECTED Table
```sql
-- Create SELECTED table with standard schema
CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED (
    LOANID VARCHAR,
    PORTFOLIONAME VARCHAR, 
    UNPAIDBALANCEDUE VARCHAR
);
```

#### 3.3 Populate SELECTED Table
```sql
-- Populate with only "Included" loans from main analysis table
INSERT INTO BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED 
(LOANID, PORTFOLIONAME, UNPAIDBALANCEDUE)
SELECT LOANID, PORTFOLIONAME, UNPAIDBALANCEDUE 
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]
WHERE LOANID IN (
    SELECT VALUE::string 
    FROM TABLE(FLATTEN(PARSE_JSON('[JSON_ARRAY_OF_LOAN_IDS]')))
);
```

### 4. Copy and Adapt Template Files

#### 4.1 Copy Templates
```bash
# Copy from Google Drive
cp "[GoogleDrive]/DI-971/.../Notice_Of_Servicing_Transfer_updated.sql" source_materials/
cp "[GoogleDrive]/DI-972/.../BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql" source_materials/
```

#### 4.2 Create Adapted Queries
Create three final deliverable queries:

**Marketing Goodbye Letters Pattern:**
```sql
-- Uses SELECTED table as base, joins with main table for data
SET SALE_DATE = 'YYYY-MM-DD';

SELECT UPPER(ds.LOANID) as loan_id,
       LOWER(ds.LEAD_GUID) as payoffuid,
       UPPER(ds.FIRSTNAME) as first_name,
       UPPER(ds.LASTNAME) as last_name,
       ds.EMAIL,
       ds.STREETADDRESS1 as streetaddress1,
       -- ... other fields from main table
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED sel
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME] ds
    ON sel.LOANID = ds.LOANID
-- Minimal external JOINs only for essential data
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT lc
    ON ds.LP_LOAN_ID = lc.LOAN_ID 
    AND lc.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LOS_SCHEMA();
```

**Credit Reporting Pattern:**
```sql
SET START_DATE = 'YYYY-MM-DD';

SELECT UPPER(ds.LOANID) as loan_id,
       UPPER(ds.FIRSTNAME) as first_name,
       UPPER(ds.LASTNAME) as last_name,
       $START_DATE as PLACEMENT_STATUS_STARTDATE
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED sel
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME] ds
    ON sel.LOANID = ds.LOANID;
```

**Bulk Upload Pattern:**
```sql
SET START_DATE = 'YYYY-MM-DD';

SELECT ds.LP_LOAN_ID,
       UPPER(ds.LOANID) as loanid,
       le.SETTINGS_ID,
       'Bounce' as Placement_Status,
       $START_DATE as Placement_Status_StartDate,
       NULL as Placement_Status_EndDate
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED sel
INNER JOIN BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME] ds
    ON sel.LOANID = ds.LOANID
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_ENTITY_CURRENT le
    ON ds.LP_LOAN_ID::STRING = le.ID::STRING 
    AND le.SCHEMA_NAME = ARCA.CONFIG.LMS_SCHEMA();
```

### 5. Execute Queries and Generate CSV Files

#### 5.1 Execute SQL Files
```bash
# Generate CSV files
snow sql -f 2_marketing_goodbye_letters_[DEBT_SALE]_FINAL.sql --format csv > marketing_goodbye_letters_[DEBT_SALE]_final_RAW.csv
snow sql -f 3_credit_reporting_[DEBT_SALE]_FINAL.sql --format csv > credit_reporting_[DEBT_SALE]_final_RAW.csv  
snow sql -f 4_bulk_upload_[DEBT_SALE]_FINAL.sql --format csv > bulk_upload_[DEBT_SALE]_final_RAW.csv
```

#### 5.2 Clean CSV Files
```bash
# Remove SQL status headers and blank lines
sed '1,2d' marketing_goodbye_letters_[DEBT_SALE]_final_RAW.csv | sed '/^$/d' > marketing_goodbye_letters_[DEBT_SALE]_final.csv
sed '1,2d' credit_reporting_[DEBT_SALE]_final_RAW.csv | sed '/^$/d' > credit_reporting_[DEBT_SALE]_final.csv
sed '1,2d' bulk_upload_[DEBT_SALE]_final_RAW.csv | sed '/^$/d' > bulk_upload_[DEBT_SALE]_final.csv

# Clean up temp files
rm -f *_RAW.csv
```

### 6. Quality Control Validation

#### 6.1 Record Count Validation
```sql
-- QC Query: Verify counts match expected selected population
SELECT 'Selected Population' as source, COUNT(*) as record_count 
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED

UNION ALL

SELECT 'Marketing File' as source, COUNT(*)-1 as record_count  -- Subtract header
FROM (SELECT * FROM TABLE(@[stage]/marketing_goodbye_letters_[DEBT_SALE]_final.csv))

UNION ALL

SELECT 'Credit Reporting File' as source, COUNT(*)-1 as record_count
FROM (SELECT * FROM TABLE(@[stage]/credit_reporting_[DEBT_SALE]_final.csv))

UNION ALL  

SELECT 'Bulk Upload File' as source, COUNT(*)-1 as record_count
FROM (SELECT * FROM TABLE(@[stage]/bulk_upload_[DEBT_SALE]_final.csv));
```

#### 6.2 File Format Validation
```bash
# Check record counts (should all match + 1 for header)
wc -l *.csv

# Verify headers are in row 1, no blank lines
head -3 [each_file].csv
tail -3 [each_file].csv
```

### 7. Google Drive Backup

⚠️ **IMPORTANT**: Always request user permission before performing Google Drive backup.

```bash
# Set Google Drive path (backup under team member's name folder)
GOOGLE_DRIVE_PATH="/Users/[USERNAME]/Library/CloudStorage/GoogleDrive-[EMAIL]/Shared drives/Data Intelligence/Tickets/[Team Member Name]"

# Example: Kyle Chalmers tickets
# GOOGLE_DRIVE_PATH="/Users/kchalmers/Library/CloudStorage/GoogleDrive-kchalmers@happymoney.com/Shared drives/Data Intelligence/Tickets/Kyle Chalmers"

# Remove existing folder (if exists)
rm -rf "${GOOGLE_DRIVE_PATH}/DI-XXXX"

# Copy complete ticket folder to Google Drive
cp -r "tickets/[team_member]/DI-XXXX" "${GOOGLE_DRIVE_PATH}/"

# Verify backup success
ls -la "${GOOGLE_DRIVE_PATH}/DI-XXXX"
```

### 8. Post-Completion Tasks

#### 8.1 Jira Comment and Notification
```bash
# Create completion comment with Google Drive links
echo "DI-XXXX Complete: Generated three debt sale deliverable files for [Debt Sale] with [N] selected loans.

**Final Deliverables:**
• [Marketing Goodbye Letters](GOOGLE_DRIVE_LINK) - [N+1] records (including header)
• [Credit Reporting List](GOOGLE_DRIVE_LINK) - [N+1] records (including header)  
• [Bulk Upload List](GOOGLE_DRIVE_LINK) - [N+1] records (including header)

All files ready for delivery. Created comprehensive workflow documentation for future similar requests." > jira_comment.txt

# Post to Jira
acli jira workitem comment --key "DI-XXXX" --body "$(cat jira_comment.txt)"

# Notify stakeholders via Slack (replace CHANNEL_ID)
slack_send "CHANNEL_ID" "DI-XXXX Complete: All debt sale files generated and ready. JIRA_COMMENT_LINK"
```

#### 8.2 Create SERV Ticket for Bulk Upload
```bash
# Create SERV ticket for LoanPro bulk upload execution
echo "[Debt Sale Partner] Perform Bulk Uploads for Loans Sold ([Quarter] [Year] Debt Sale)

Linked here you will find charge off loans that need to be bulk uploaded into LoanPro that have been sold to [Partner]. Please wait for Mandi's confirmation before executing these bulk uploads into LoanPro. This will be done on [DATE]. The sale date should be [YYYY-MM-DD], hence why the date is on there.

**Bulk Upload File:**
[GOOGLE_DRIVE_BULK_UPLOAD_LINK]

**Details:**
- [N] loans for [Partner] [Quarter] [Year] Debt Sale
- Sale Date: [YYYY-MM-DD]
- File includes: LP_LOAN_ID, loanid, SETTINGS_ID, Placement_Status, Placement_Status_StartDate
- Related DI ticket: DI-XXXX" > /tmp/serv_ticket.txt

# Create SERV ticket
acli jira workitem create --from-file "/tmp/serv_ticket.txt" --project "SERV" --type "Task"
```

#### 8.3 Git Workflow and Pull Request
```bash
# Create branch for ticket (if not already created)
git checkout -b DI-XXXX

# Add all ticket files
git add tickets/[team_member]/DI-XXXX/ INSTRUCTIONS.md

# Commit with descriptive message
git commit -m "$(cat <<'EOF'
DI-XXXX: Complete debt sale deliverables for [Partner] [Quarter] [Year]

- Generated three required deliverable files for [N] selected loans
- Marketing goodbye letters, credit reporting, and bulk upload lists
- Created/updated comprehensive workflow documentation
- Organized SQL queries in numbered execution sequence
- Added post-completion verification and SERV ticket workflow

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"

# Push branch
git push -u origin DI-XXXX

# Create pull request
gh pr create --title "DI-XXXX: Debt sale deliverables for [Partner] [Quarter] [Year]" --body "$(cat <<'EOF'
## Summary
Generated three required debt sale deliverable files for [Partner] [Quarter] [Year] with [N] selected loans:
- Marketing goodbye letters (customer notification)
- Credit reporting list (compliance)
- Bulk upload list (LoanPro placement status)

## Key Deliverables
- **Final CSV files**: All three deliverables ready for stakeholder use
- **SERV ticket created**: SERV-XXX for LoanPro bulk upload coordination
- **Workflow documentation**: Comprehensive INSTRUCTIONS.md for future similar requests
- **Verification process**: Post-upload validation query prepared

## Test plan
- [x] All CSV files generated with exact selected loan count ([N])
- [x] Files uploaded to Google Drive and backed up
- [x] SERV ticket created with Mandi confirmation requirement
- [x] Stakeholder notification completed via Jira and Slack
- [x] Comprehensive workflow documentation created/updated

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

#### 8.4 Post-Upload Verification (Follow-up Task)
**⏳ Execute when SERV ticket moves to IN TESTING status**

```sql
-- Create placement status verification query
-- Template: placement_status_verification.sql

-- Query 1: Verify placement count matches expected
SELECT COUNT(*) AS NUMBER_OF_LOANS, 
       A.PLACEMENT_STATUS, 
       A.PLACEMENT_STATUS_START_DATE
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT B
    ON A.LOAN_ID = B.LOAN_ID 
    AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE 1=1
    AND A.PLACEMENT_STATUS = '[PARTNER_NAME]'
    AND A.PLACEMENT_STATUS_START_DATE = '[SALE_DATE]'
GROUP BY ALL
ORDER BY 3 DESC;

-- Query 2: Cross-reference with original population
SELECT 
    'Original Selected Population' AS source,
    COUNT(*) AS loan_count
FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.[DEBT_SALE_TABLE_NAME]_SELECTED

UNION ALL

SELECT 
    'Placed with [PARTNER]' AS source,
    COUNT(*) AS loan_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT A
WHERE A.PLACEMENT_STATUS = '[PARTNER_NAME]'
    AND A.PLACEMENT_STATUS_START_DATE = '[SALE_DATE]';
```

**Verification Checklist:**
- ✅ Placement count matches expected loan count from bulk upload file
- ✅ Placement date matches sale date in LoanPro system
- ✅ Cross-reference confirms all selected loans were successfully placed
- ✅ Update DI ticket with verification results

### 9. Final Deliverables Structure

```
DI-XXXX/
├── README.md
├── INSTRUCTIONS.md (link from README)
├── source_materials/
│   ├── [debt_sale]_selection_results.csv
│   ├── Notice_Of_Servicing_Transfer_updated.sql
│   └── BULK_UPLOAD_AND_CREDIT_REPORTING_SCRIPTS.sql
├── final_deliverables/
│   ├── sql_queries/
│   │   ├── 1_upload_[debt_sale]_data.sql
│   │   ├── 2_marketing_goodbye_letters_[DEBT_SALE]_FINAL.sql
│   │   ├── 3_credit_reporting_[DEBT_SALE]_FINAL.sql
│   │   ├── 4_bulk_upload_[DEBT_SALE]_FINAL.sql
│   │   └── 5_placement_status_verification_[DEBT_SALE].sql ⏳
│   ├── marketing_goodbye_letters_[DEBT_SALE]_final.csv ✓
│   ├── credit_reporting_[DEBT_SALE]_final.csv ✓
│   └── bulk_upload_[DEBT_SALE]_final.csv ✓
└── qc_queries/
    └── 1_record_count_validation.sql
```

**SQL Query Execution Order:**
1. **Setup Phase**: `1_upload_[debt_sale]_data.sql` - Create and populate SELECTED table
2. **Generation Phase**: `2_marketing_goodbye_letters_[DEBT_SALE]_FINAL.sql` - Generate CSV files
3. **Generation Phase**: `3_credit_reporting_[DEBT_SALE]_FINAL.sql` - Generate CSV files  
4. **Generation Phase**: `4_bulk_upload_[DEBT_SALE]_FINAL.sql` - Generate CSV files
5. **Verification Phase**: `5_placement_status_verification_[DEBT_SALE].sql` ⏳ - **Execute when SERV ticket moves to IN TESTING**

## Key Architecture Principles

### ✅ **DO:**
- Use existing comprehensive main analysis table as data source
- Create SELECTED table with only "Included" status loans
- Join SELECTED table (base filter) with main table (data source)
- Leverage rich data already in main analysis table
- Follow established naming conventions
- Minimize external table JOINs

### ❌ **DON'T:**
- Overwrite or recreate the main analysis table
- Pull data from multiple disparate sources when main table has it
- Upload raw CSV data as primary data source
- Create queries that bypass the SELECTED table filter
- Use complex multi-source JOINs when main table is sufficient

## Common Pitfalls and Solutions

### Pitfall 1: Table Naming Conflicts
**Issue**: Accidentally overwriting main analysis table with CSV data
**Solution**: Always use descriptive suffixes (_SELECTED, _CSV_UPLOAD, etc.)

### Pitfall 2: Wrong Record Counts  
**Issue**: Getting all loans instead of selected subset
**Solution**: Always base queries on SELECTED table, verify "Included" status filter

### Pitfall 3: Missing Data Fields
**Issue**: Pulling from external sources when data exists in main table
**Solution**: Check main table schema first, use direct fields when available

### Pitfall 4: Malformed CSV Output
**Issue**: SQL status messages and blank lines in CSV files
**Solution**: Always clean CSV files with sed commands post-generation

## Success Criteria

### ✅ **Technical Validation:**
- **Exact count match**: [N selected loans + 1 header] in each CSV file
- **Clean CSV format**: Header in row 1, no SQL status messages, no blank lines
- **Data consistency**: All three files reference same loan population from SELECTED table
- **Architecture compliance**: SELECTED table filter + main analysis table data source
- **Database integrity**: Main Phase 1 table preserved and unchanged

### ✅ **Process Completion:**
- **Documentation**: Complete README.md with technical details and business context
- **Stakeholder notification**: Jira comment posted with Google Drive links
- **SERV ticket created**: Bulk upload ticket created with Mandi confirmation requirement
- **Google Drive backup**: Complete ticket folder backed up under team member name
- **Verification prepared**: Query #5 ready for execution when SERV moves to IN TESTING

### ✅ **Business Requirements Met:**
- **Marketing files**: Enable customer notification of servicing transfer
- **Credit reporting**: Ensure compliance with credit bureau reporting requirements  
- **LoanPro upload**: Facilitate placement status updates in loan management system
- **Stakeholder communication**: Clear deliverable links and status updates provided

## Common Troubleshooting

### **Issue: "No main analysis table found"**
- **Cause**: Phase 1 ticket (DI-114X) not completed or table naming mismatch
- **Solution**: Verify Phase 1 completion status, confirm table naming pattern
- **Prevention**: Always reference related Phase 1 ticket in requirements

### **Issue: "Selected population count mismatch"**  
- **Cause**: CSV status filtering incorrect or join key problems
- **Solution**: Verify "Included" status filter, check LOANID/EXTERNAL_ACCOUNT_ID mapping
- **Prevention**: Always validate selected count before query execution

### **Issue: "Template queries fail with missing columns"**
- **Cause**: Phase 1 table structure differs from template expectations
- **Solution**: Check Phase 1 table schema, adapt templates to available fields
- **Prevention**: Compare table structure against previous debt sale schemas

### **Issue: "SERV ticket verification shows 0 placed loans"**
- **Cause**: Bulk upload not yet executed or placement status not updated
- **Solution**: Confirm SERV ticket in testing status, coordinate with LoanPro team
- **Prevention**: Execute verification only after SERV moves to IN TESTING

This comprehensive workflow ensures consistency, accuracy, and maintainability for all future Phase 2 debt sale deliverable requests.