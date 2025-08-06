# Claude Assistant Instructions

## Overview

This document provides instructions for Claude (AI assistant) when working with the data-intelligence-tickets repository. You have access to several powerful command-line tools that can help solve data intelligence tickets and issues.

**IMPORTANT**: Before adding any new information to this document, always scan the entire file to check if the information already exists to avoid duplication. Present all information in a concise, clear manner.

## Prerequisites

For optimal performance, ensure all required tools are installed. See the **[Prerequisite Installation Guide](./documentation/prerequisite_installations.md)** for detailed installation instructions including:
- Essential CLI tools (tree, jq, bat, ripgrep, fd, fzf, htop)
- Database and API tools (already installed: Snowflake CLI, Atlassian CLI, GitHub CLI)
- Custom integrations (Slack CLI functions)
- Platform-specific installation instructions (macOS Homebrew, Windows options)

## Ticket Research and Knowledge Management

### Repository Structure
All completed tickets are stored under `tickets/` directory. **For a complete chronological log, see [main README.md](./README.md#completed-tickets-log).**

```
tickets/
├── [team_member_name]/
│   ├── DI-XXX/
│   │   ├── README.md    # Required: Detailed documentation
│   │   ├── scripts/     # Scripts created for solution
│   │   ├── queries/     # SQL queries used
│   │   └── docs/        # Additional documentation
```

### Google Drive Integration

**Base Path:** `/Users/[USERNAME]/Library/CloudStorage/GoogleDrive-[EMAIL]/Shared drives/Data Intelligence/Tickets`

#### Backup Process for Completed Tickets
**IMPORTANT**: Always create a backup of ticket deliverables in Google Drive for preservation and team access.

**When to Backup:**
- Final ticket completion
- Major deliverable updates  
- Before PR merge

**Required User Permission:**
- **ALWAYS ask for user permission** before performing Google Drive backup operations
- **Never perform backup operations without explicit user approval**

**Backup Workflow:**
1. Request permission for Google Drive backup
2. Remove existing folder: `rm -rf "[GOOGLE_DRIVE_PATH]/[TICKET-ID]"`
3. Copy complete structure: `cp -r "[LOCAL_PATH]/[TICKET-ID]" "[GOOGLE_DRIVE_PATH]/"`
4. Verify successful backup

### Research Process for Related Tickets
When working on a ticket, research for related tickets to understand patterns and reuse solutions:

1. **Check Jira relationships**: Use `acli jira workitem view TICKET-KEY`
2. **Search repository**: Look for similar ticket folders in `tickets/` directory  
3. **Check Google Drive**: Search for historical context if not in repo

**Benefits:**
- Avoid duplicate work by reusing proven solutions
- Maintain consistency following established patterns
- Speed development by adapting existing queries
- Learn from previous experience

## Data Schema Documentation

The repository maintains comprehensive data documentation in **[Data Catalog](./documentation/data_catalog.md)** including:
- Database Architecture: Primary databases and schema organization
- Core Business Objects: Loan management, payment data, portfolio classifications
- Schema Filtering Best Practices: LoanPro multi-instance filtering patterns
- Query Development Patterns: Common SQL patterns for payment history, fraud analysis
- Data Quality Considerations: Known issues and workarounds

## Available CLI Tools

### 1. Snowflake CLI (`snow`)
Execute SQL queries, manage objects, load/unload data, check query history.

```bash
snow sql -q "SELECT * FROM database.schema.table LIMIT 10"
snow connection list
snow warehouse list
```

**Authentication Notes:**
- Uses Duo Security authentication
- **IMPORTANT**: Before FIRST query only, remind user to approve via Duo device
- **LOCKOUT WARNING**: No authentication locks account for 15 minutes

### 2. Jira CLI (`acli`)
Create, update, search tickets, manage workflows, extract data.

```bash
# View ticket details
acli jira workitem view TICKET-KEY

# Create ticket using file input to avoid labels field issues
echo "Ticket Summary\n\nDetailed description..." > /tmp/jira_ticket.txt
acli jira workitem create --from-file "/tmp/jira_ticket.txt" --project "DI" --type "Automation" --parent "DI-174"

# Assign and transition
acli jira workitem assign --key "DI-XXXX" --assignee "@me"
acli jira workitem transition --key "DI-XXXX" --status "Done"
```

# Comment on tickets
acli jira workitem comment --key "DI-XXXX" --body "Comment text"

**Common Mistakes:**
- ❌ `--comment` (incorrect flag - causes "unknown flag" error)
- ✅ `--body` (correct flag)

**Important Notes:**
- Default parent epic for BAU tickets: `DI-174`
- Available types: Automation, Data Engineering Task, Data Pull, Reporting, Dashboard, Research, Epic, Data Engineering Bug
- "In Progress" transition may fail due to time tracking - do manually in UI

### 3. Tableau CLI (`tabcmd`)
Publish workbooks, manage users, refresh extracts, export views.

```bash
tabcmd login -s https://tableau.server.com -u username
tabcmd publish "workbook.twbx" -n "Workbook Name"
```

### 4. GitHub CLI (`gh`)
Create issues, manage PRs, automate workflows.

```bash
gh pr create --title "PR title" --body "PR description"
```

### 5. Slack CLI Functions
Custom integration functions available in `~/.slack_user_functions.zsh` and `resources/slack_user_functions.zsh`:

- `slack_users()`: List all workspace users
- `slack_user_by_email(email)`: Look up user by email
- `slack_dm_by_email(email, message)`: Send direct message
- `slack_dm(user_id, message)`: Send direct message by user ID
- `slack_send(channel_id, message)`: Send message to channel/group
- `slack_group_by_emails_dynamic(email1, email2, ...)`: Create group conversation

**Authentication:** Requires `SLACK_TOKEN` environment variable.

## Business Context and Definitions

### Loan Status Definitions

**Delinquent Loans:** 3-119 Days Past Due (DPD) and NOT charged off or paid in full
- Early Stage (3-30 DPD): Recently delinquent, highest recovery potential
- Critical Stage (91-119 DPD): Near charge-off, intensive collection efforts

**SQL Pattern:** `WHERE DPD BETWEEN 3 AND 119 AND STATUS NOT IN ('CHARGED_OFF', 'PAID_IN_FULL')`

**Current Loans:** 0-2 Days Past Due, considered in good standing

**Charged Off Loans:** Written off as uncollectible (typically 120+ DPD)

### Collections and Placements

**SIMM Placement:** Third-party collections agency placement
- Data Source: `RPT_OUTBOUND_LISTS_HIST` where `SET_NAME = 'SIMM'`
- Coverage: ~47% of delinquent loans
- Available From: May 2025 onwards

### Roll Rate Analysis
Track loan movement between delinquency stages over time:
- Roll Forward: Loans becoming more delinquent
- Roll Back: Loans curing (becoming less delinquent)
- Roll to Charge-off: Loans reaching charge-off status

## Workflow Guidelines

### Ticket Branching Strategy

1. **Create branch:** `git checkout -b DI-XXX`
2. **Create folder structure:**
   ```
   tickets/[team_member]/DI-XXX/
   ├── README.md                    # REQUIRED: Complete documentation
   ├── source_materials/            # Original files and references
   ├── final_deliverables/          # REQUIRED: Ready-to-deliver outputs
   │   ├── qc_queries/              # Quality control queries
   │   └── archive_versions/        # Development iterations
   ├── original_code/               # REQUIRED: When modifying views/tables
   ├── exploratory_analysis/        # Optional: Working files
   └── [ticket_comment].txt         # Final Jira comment
   ```

### Protocol for Modifying Database Objects

1. **Save original definitions first:**
   ```bash
   snow sql -q "SELECT GET_DDL('VIEW', 'schema.view_name')" --format csv | tail -n +7 | sed 's/^"//;s/"$//' > original_code/original_view_ddl.sql
   ```
2. **Create ALTER statements** in final_deliverables/
3. **Test thoroughly** with compatibility queries
4. **Document changes** in README.md
5. **Submit PR** when complete

### Database Deployment Template

When deploying new dynamic tables, views, or tables across environments, use the standardized deployment template from `documentation/db_deploy_template.sql`:

```sql
DECLARE
    -- dev databases
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    v_rds_db varchar default 'DEVELOPMENT';
    
    -- prod databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    -- v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN
    -- FRESHSNOW section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_[VIEW_NAME](
            [COLUMN_LIST]
        ) COPY GRANTS AS 
            [VIEW_DEFINITION]
    ');

    -- BRIDGE section    
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_[VIEW_NAME](
            [COLUMN_LIST]
        ) COPY GRANTS AS 
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_[VIEW_NAME]
    ');
    
    -- ANALYTICS section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_[VIEW_NAME](
            [COLUMN_LIST]
        ) COPY GRANTS AS 
            SELECT * FROM ' || v_bi_db ||'.BRIDGE.VW_[VIEW_NAME]
    ');
END;
```

**Key Features:**
- **Environment variables**: Switch between dev/prod by commenting/uncommenting
- **Multi-schema deployment**: Deploys across FRESHSNOW → BRIDGE → ANALYTICS layers
- **COPY GRANTS**: Preserves existing permissions
- **Dynamic SQL**: Uses EXECUTE IMMEDIATE for parameterized deployment

### General Ticket Resolution Process

1. **Understand the issue**: Read ticket, ask clarifying questions
2. **Research existing solutions**: Check related tickets in repo and Google Drive
3. **Plan approach**: Outline resolution steps
4. **Execute carefully**: Run commands step-by-step, verify results
5. **Document solution**: Create clear documentation
6. **Create Google Drive backup**: Ask permission, backup deliverables

### SQL Development Standards

#### Development Process
1. **Investigate structures**: Use `DESCRIBE` or `SELECT * LIMIT 5`
2. **Build incrementally**: Start basic, add joins/filters
3. **Use appropriate filters**: Apply date filters, limits during exploration
4. **Present final queries**: Show completed queries after exploration
5. **Document logic**: Explain joins, filters, business logic

#### Safety Rules
- Simple SELECT operations permitted without approval
- **NEVER** run ALTER, CREATE, DROP, INSERT, UPDATE, DELETE without permission
- Use LIMIT clauses during exploration
- Apply reasonable date filters

#### Standards
- **Parameterize values** as variables at script top
- **Document variables** with clear comments
- **Include comprehensive commenting** explaining business logic
- **Always output CSV format** using `--format=csv`
- **ALWAYS include column headers** in CSV outputs
- **Use CAST()** for data type conversions when joining
- **Handle missing columns** gracefully using alternatives

#### Query Optimization
Always evaluate queries for efficiency before finalizing:
1. **Structure Review**: Eliminate unnecessary CTEs, optimize joins
2. **Testing Protocol**: Test optimized queries against original results using `diff`
3. **Performance**: Measure and compare execution times
4. **Quality Gates**: SQL must be tested, results identical, performance measured

### Data Analysis and Quality Control Best Practices

**Tool Selection:**
- **Python/pandas**: File comparisons, statistical analysis, pattern identification, complex data transformations
- **SQL**: Data validation queries, record counts, business rule verification
- **Bash**: Simple file operations, system commands only

**Quality Control Process:**
- **Create dedicated QC queries** in `qc_queries/` subfolder  
- **Number by execution order**: 1_, 2_, 3_, etc.
- **Use SQL for data validation**, Python for complex analysis

**Required Libraries:** pandas, numpy, matplotlib/seaborn, requests, openpyxl

### Data Architecture Best Practices

**Joining Strategy:**
- Use LEAD_GUID when possible (most reliable identifier)
- LEGACY_LOAN_ID for user-friendly stakeholder references

**LoanPro Schema Filtering:**
- Filter by `SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()` for loan objects
- Use `SCHEMA_NAME = arca.CONFIG.LOS_SCHEMA()` for application objects
- Critical for avoiding duplicate data from multiple instances

**Status Information:**
- LOAN_SUB_STATUS_TEXT: Actual status as seen in LoanPro UI
- Use `VW_LOAN_STATUS_ARCHIVE_CURRENT` for current states

### Stakeholder Communication

**Requirements Clarification:**
When requirements could be interpreted multiple ways:
1. **State your understanding** of requirements
2. **Identify specific scenarios** that could be handled differently  
3. **Provide concrete examples** from current data
4. **Ask for explicit confirmation** of interpretation

**Template:**
```
@[Stakeholder] With this file, there are X transactions included, but a few scenarios to clarify:
1. [Scenario 1]: Should be [included/excluded], correct?
2. [Scenario 2]: Should be [included/excluded], correct?
Can you confirm my understanding is correct?
```

### File Organization Standards

**Naming Conventions:**
- Include record counts: `fortress_payment_history_193_transactions.csv`
- Use descriptive prefixes: `fortress_`, `bounce_`, `fraud_analysis_`
- Archive development versions in `archive_versions/`
- Number SQL queries by execution order

**Source Tracking:**
Add source identification columns when working with multiple attachments/sources.

### Fraud Analysis Best Practices

**Multi-Source Detection:**
- Check fraud portfolios: `VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS`
- Check investigation results: `VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT`
- Check status text: `VW_LOAN_SUB_STATUS_ENTITY_CURRENT`
- Use inclusive OR conditions

**Binary Classification:**
- Create binary indicators using MAX(CASE WHEN...)
- Use LISTAGG() to flatten partner assignments
- Add indicators for ownership transfer analysis

## Integration Limitations and Workarounds

### Jira CLI Limitations
- **No file attachments**: Use web interface for attachments
- **User tagging**: May not work consistently, use plain text names
- **Workarounds**: Mention file locations in comments, reference by name

### Slack Messaging for Completion
When completing tickets:
1. **Complete ticket** and post to Jira using acli
2. **Get comment link** from Jira ticket
3. **ALWAYS ASK PERMISSION** before sending Slack messages
4. **Use Slack CLI functions** to notify stakeholders

## CLAUDE.md Update Process

**IMPORTANT**: Be concise and avoid duplication when updating CLAUDE.md

Before updating with new knowledge:
1. **Scan entire file** using Grep to check for existing similar content
2. **Consolidate overlapping sections** instead of creating new duplicates  
3. **Keep content concise** - avoid verbose explanations or examples
4. **Identify fundamental insight** that benefits all future tickets
5. **Request approval**: "May I update CLAUDE.md with the following changes?"
6. **Wait for confirmation** before proceeding

**Example duplication check:**
```bash
# Search for existing content before adding new sections
grep -i "python\|pandas\|analysis" CLAUDE.md
```

## Error Handling and Security

**Error Handling:**
- Check authentication, connectivity, syntax, permissions
- Capture error messages and timestamps (especially for Snowflake lockouts)
- Document workarounds

**Security:**
- Never hardcode credentials
- Use environment variables or secure stores
- Ensure compliance with data policies
- Regularly review access credentials

## Getting Help

- Use `--help` flag with CLI tools
- Refer to official documentation
- Check existing solutions in repository
- Ask for clarification when requirements unclear