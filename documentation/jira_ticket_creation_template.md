# Jira Ticket Creation Template

This document provides templates and examples for creating Jira tickets in the DI project using the Atlassian CLI.

## Prerequisites

Ensure you have the Atlassian CLI installed and authenticated:
```bash
acli --version
```

## Finding Available Epics

To find available epics for linking tickets:

```bash
acli jira workitem search --jql "project = DI AND type = Epic" --limit 10 --fields "key,summary"
```

## Available Issue Types

The DI project supports the following issue types:
- **Reporting** - Report generation requests
- **Data Pull** - Data extraction requests
- **Automation** - Automation tasks
- **Dashboard** - Dashboard-related work
- **Research** - Research and investigation tasks
- **Epic** - Large initiatives containing multiple tasks
- **Data Engineering Task** - Standard data engineering work
- **Data Engineering Bug** - Bug fixes

## Basic Ticket Creation

### Using Command Line Flags

```bash
acli jira workitem create \
  --project "DI" \
  --type "Dashboard" \
  --summary "Brief ticket summary" \
  --description "Detailed description of the work needed" \
  --assignee "user@financeco.com" \
  --parent "DI-XXXX"
```

**Note:** The `--parent` flag is used to link tickets to an Epic. Most issue types in the DI project require an Epic to be selected.

### Common Examples

#### Dashboard Investigation Ticket
```bash
acli jira workitem create \
  --project "DI" \
  --type "Dashboard" \
  --summary "Investigate missing data in [Dashboard Name]" \
  --description "Dashboard: [Dashboard Name]
Data Source: [View/Table Name]
Issue: [Description of issue]
Investigation needed:
- [Step 1]
- [Step 2]
- [Step 3]" \
  --assignee "analyst@financeco.com" \
  --parent "DI-1238"
```

#### Data Engineering Task
```bash
acli jira workitem create \
  --project "DI" \
  --type "Data Engineering Task" \
  --summary "Create view for [business purpose]" \
  --description "Business requirement: [Description]
Expected output: [What should be delivered]
Data sources: [List of tables/views]
Acceptance criteria:
- [Criterion 1]
- [Criterion 2]" \
  --assignee "analyst@financeco.com" \
  --parent "DI-1238"
```

#### Research Task
```bash
acli jira workitem create \
  --project "DI" \
  --type "Research" \
  --summary "Research [topic/question]" \
  --description "Background: [Context]
Questions to answer:
- [Question 1]
- [Question 2]
Expected deliverable: [What format/output is needed]" \
  --assignee "analyst@financeco.com" \
  --parent "DI-1238"
```

## Transitioning Tickets

After creating a ticket, transition it to the appropriate status:

```bash
# Common status transitions
acli jira workitem transition --key "DI-XXXX" --status "In Spec"
acli jira workitem transition --key "DI-XXXX" --status "In-Progress"
acli jira workitem transition --key "DI-XXXX" --status "Done"
```

## Viewing Ticket Details

```bash
acli jira workitem view DI-XXXX
```

## Adding Comments

```bash
acli jira workitem comment --key "DI-XXXX" --body "Comment text here"
```

**Note:** Keep comments under 100 words as per project standards.

## Assigning Tickets

```bash
acli jira workitem assign --key "DI-XXXX" --assignee "user@financeco.com"

# Self-assign
acli jira workitem assign --key "DI-XXXX" --assignee "@me"
```

## Complete Workflow Example

```bash
# 1. Find available epics
acli jira workitem search --jql "project = DI AND type = Epic" --limit 5 --fields "key,summary"

# 2. Create ticket
TICKET_KEY=$(acli jira workitem create \
  --project "DI" \
  --type "Dashboard" \
  --summary "Investigate data gap in reporting view" \
  --description "Dashboard showing no data since specific date" \
  --assignee "analyst@financeco.com" \
  --parent "DI-1238" | grep -oE 'DI-[0-9]+')

echo "Created ticket: $TICKET_KEY"

# 3. Transition to In Spec
acli jira workitem transition --key "$TICKET_KEY" --status "In Spec"

# 4. Create git branch
git checkout main && git pull origin main
git checkout -b "$TICKET_KEY"

# 5. Create folder structure
mkdir -p "tickets/examples/$TICKET_KEY/{source_materials,final_deliverables,exploratory_analysis,archive_versions}"

# 6. Create README
cat > "tickets/examples/$TICKET_KEY/README.md" << EOF
# $TICKET_KEY: [Ticket Summary]

## Ticket Information
- **Jira Link:** https://financecoinc.atlassian.net/browse/$TICKET_KEY
- **Type:** Dashboard
- **Status:** In Spec
- **Assignee:** Data Analyst

## Business Context

[Description of business need]

## Investigation Scope

1. [Step 1]
2. [Step 2]

## Assumptions Made

*To be documented during investigation*

## Deliverables

*To be added as investigation progresses*

## Quality Control

*QC steps to be documented*
EOF
```

## Common Issues and Solutions

### Issue: "An epic must be selected in the Epic Link field"
**Solution:** Use the `--parent` flag with an Epic key (e.g., `--parent "DI-1238"`)

### Issue: "User not found for email"
**Solution:** Use the exact email format: `user@financeco.com` (without quotes in the command)

### Issue: "Please provide valid issue type"
**Solution:** Use one of the valid issue types listed above, matching the exact capitalization

## Additional Resources

- [Atlassian CLI Documentation](https://developer.atlassian.com/cloud/cli/)
- View CLAUDE.md for complete workflow standards
- See README.md for completed ticket examples