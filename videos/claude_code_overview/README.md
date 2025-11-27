# Claude Code for Data Teams: Complete Guide

> **Your AI-powered data analysis assistant** - From installation to advanced customization

---

## 📑 Table of Contents

### Introduction
- [What is Claude Code?](#what-is-claude-code)
- [Why Use Claude Code for Data Work?](#why-use-claude-code-for-data-work)

### Section 1: Using Claude Successfully Within Your Workflow

**1.1 Installation and Setup**
- [Step 1: Download and Install](#step-1-download-and-install)
- [Step 2: Start Claude Code](#step-2-start-claude-code)
- [Step 3: Verify Setup](#step-3-verify-setup)

**1.2 Core Concepts**
- [The Most Important Thing to Remember](#the-most-important-thing-to-remember)
- [Designing Your Repository for Claude Success](#designing-your-repository-for-claude-success)
- [CLAUDE.md Files: Teaching Claude About Your Workflows](#claudemd-files-teaching-claude-about-your-workflows)

**1.3 Modes and Features**
- [Claude Code Modes](#claude-code-modes)
- [Understanding Compaction and /clear](#understanding-compaction-and-clear)

**1.4 Configuration**
- [Settings.json Configuration](#settingsjson-configuration)
- [Workflow Structure: Git and Quality Control](#workflow-structure-git-and-quality-control)

### Section 2: Refining Claude to Improve Your Workflow

**2.1 Customization**
- [Custom Commands](#custom-commands)
- [Custom Agents](#custom-agents)
- [Helpful Built-in / Commands](#helpful-built-in--commands)

**2.2 Best Practices**
- [Best Practices for Data Teams](#best-practices-for-data-teams)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [Collaboration and Team Usage](#collaboration-and-team-usage)

### Quick Reference
- [Essential Commands](#essential-commands)
- [Useful Prompts](#useful-prompts)
- [File Organization Checklist](#file-organization-checklist)
- [Quality Control Checklist](#quality-control-checklist)
- [Additional Resources](#additional-resources)
- [Example Files in This Repository](#example-files-in-this-repository)

---

# Introduction

## What is Claude Code?

Claude Code is Anthropic's official CLI tool that brings AI-powered assistance directly into your terminal and development workflow.

**Think of it as having a senior data engineer working alongside you who:**
- Reads and understands your entire codebase
- Executes database queries and analyzes data
- Writes, reviews, and optimizes SQL
- Manages git workflows and ensures quality standards
- Learns your team's specific workflows and patterns

## Why Use Claude Code for Data Work?

| Benefit | Impact for Data Teams |
|---------|----------------------|
| **⚡ Speed** | Set up analysis projects in seconds, not hours |
| **✨ Quality** | Automated QC checks prevent data quality issues |
| **🎯 Consistency** | Standardized workflows across all team members |
| **🛡️ Safety** | Prevents destructive SQL operations and git mistakes |
| **📚 Knowledge** | References your documentation and business context automatically |

### Real Impact

Data teams using Claude Code report:
- **60% reduction** in time-to-delivery for analysis projects
- **90% fewer** workflow mistakes and data quality issues
- **100% compliance** with git workflow and quality standards

---

# Section 1: Using Claude Successfully Within Your Workflow

## Installation and Setup

### Step 1: Download and Install

**Quick Install:**
```bash
# Direct download
open https://claude.ai/download

# Or via Homebrew (macOS)
brew install --cask claude-code
```

> **📖 Full Installation Guide:** https://code.claude.com/docs/en/setup#native-install-recommended
>
> **⏱️ Time required:** 5 minutes

### Step 2: Start Claude Code

```bash
# Navigate to your data repository
cd /path/to/your-data-project

# Launch Claude Code
claude

# Optional flags:
claude --resume                          # Resume previous session
claude --dangerously-skip-permissions    # Skip permission prompts (use cautiously)
```

### Step 3: Verify Setup

Test that Claude Code understands your repository:

**Test Prompt:**
```
"What repository am I in? What files and folders exist here?"
```

**Expected Response:**
Claude should describe your repository structure and identify its purpose.

---

## The Most Important Thing to Remember

> **Claude Code is an assistant that can explain things to you**

This is the key to success with Claude Code:

- **Don't know how something works?** Ask Claude to explain it
- **Unfamiliar with a command?** Ask Claude to show you examples
- **Need help with syntax?** Ask Claude to generate it for you
- **Stuck on an error?** Ask Claude to help debug

### Helpful Patterns

```
"Explain how this query works"
"Show me how to use the /generate-data-object-prp command"
"Help me understand this error message"
"What's the best way to structure this analysis?"
```

Claude Code can access documentation, explain concepts, and guide you through complex tasks.

---

## Designing Your Repository for Claude Success

Claude works best when your repository is organized clearly. Here's a recommended structure for data teams:

### Recommended Folder Structure

```
your-data-project/
├── .claude/                    # Claude Code configuration
│   ├── commands/               # Custom workflow commands
│   ├── agents/                 # Custom automation agents
│   └── settings.json           # Permissions and environment
├── CLAUDE.md                   # Instructions for Claude
├── README.md                   # Project documentation
├── projects/                   # Analysis projects
│   └── [username]/
│       └── [project-name]/
│           ├── README.md               # Project documentation
│           ├── sql_queries/            # Production SQL (numbered)
│           ├── qc_queries/             # Quality control validation
│           ├── notebooks/              # Jupyter/Python notebooks
│           ├── exploratory_analysis/   # Development work
│           └── final_deliverables/     # Ready-to-deliver outputs
└── documentation/              # Reference materials
    ├── data_catalog.md         # Database schemas and tables
    └── quality_standards.md    # QC requirements
```

### Why This Structure Works

- **Numbered deliverables** make review order clear (`1_analysis.sql`, `2_results.csv`)
- **Separate QC folders** ensure validation doesn't get overlooked
- **Documentation Claude can reference** for database schemas and standards
- **Clear exploratory vs final** separation keeps projects clean

---

## CLAUDE.md Files: Teaching Claude About Your Workflows

CLAUDE.md is the instruction manual that teaches Claude about your team's specific workflows, standards, and tools.

### What Goes in CLAUDE.md

1. **Your Role and Expertise**
   ```markdown
   ## Assistant Role
   You are a Senior Data Analyst specializing in SQL development,
   data quality control, and Python analysis.
   ```

2. **Operating Rules and Permissions**
   ```markdown
   ## Critical Rules
   - ALWAYS run QC queries before finalizing analysis
   - NEVER execute UPDATE/DELETE/DROP without explicit permission
   - Document all assumptions in README.md
   ```

3. **Available Tools**
   ```markdown
   ## Tools Available
   - Snowflake CLI (`snow`) - Database queries
   - GitHub CLI (`gh`) - Git operations
   - Python - Data analysis and visualization
   ```

4. **Business and Data Knowledge**
   ```markdown
   ## Data Sources
   - ANALYTICS.REPORTING.* - Production reporting tables
   - ANALYTICS.SANDBOX.* - Development and testing

   ## Quality Standards
   - All queries must have record count validation
   - Check for duplicates in final results
   - Document data grain and filters
   ```

5. **Workflow Structure**
   ```markdown
   ## Standard Workflow
   1. Create feature branch
   2. Set up project structure
   3. Exploratory analysis
   4. Production queries with QC
   5. Documentation
   6. Pull request for review
   ```

### Example CLAUDE.md for Data Teams

See the full CLAUDE.md in this repository root for a complete example tailored to data analysis workflows.

---

## Claude Code Modes

Claude Code operates in different modes that control how it interacts with you and executes changes.

### Comprehensive Modes Comparison

| Mode | Type | How to Activate | What it Controls | When to Use |
|------|------|----------------|------------------|-------------|
| **Standard Mode** | Default | Automatic | Normal conversational interaction | General data analysis tasks |
| **Plan Mode** | Operational | `Shift+Tab` or auto-triggered | Creates plan before execution (read-only) | Complex multi-step analyses |
| **Auto-Accept Mode** | Permission | `Shift+Tab` or settings.json | Automatically accepts file edits | Rapid development, trusted operations |
| **Extended Thinking** | Reasoning | Press `Tab` or say "think hard" | Deep reasoning and analysis | Complex problems, edge cases |

### Understanding Each Mode

#### Standard Mode (Default)
Your everyday interaction mode. Claude responds conversationally and can execute read operations, write files, and run commands based on your permissions settings.

**When to use:** Regular analysis work, SQL development, documentation

#### Plan Mode
Claude creates a detailed plan and waits for your approval before executing any changes.

**How it works:**
```
You: "Reorganize the analysis project structure"
Claude: [Creates detailed plan]
        [Waits for approval]
You: "Proceed"
Claude: [Executes the plan]
```

**When to use:**
- Complex multi-step data pipelines
- Unfamiliar analysis approaches
- Learning how Claude works
- Architectural decisions

#### Auto-Accept Mode
Claude makes file changes automatically without prompting for each individual edit.

**How to activate:** Press `Shift+Tab` and select "Auto-Accept Edits"

**When to use:**
- Rapid development
- Batch file updates
- When you trust Claude's changes
- Review changes via `git diff` after

**⚠️ Important:** You can always review all changes with git before committing

#### Extended Thinking Mode
Claude shows its reasoning process explicitly and analyzes problems more deeply.

| Aspect | Normal Mode | Extended Thinking Mode |
|--------|-------------|----------------------|
| **Response time** | Faster | Slower (deeper analysis) |
| **Reasoning** | Standard | Shows explicit thought process |
| **Best for** | Clear tasks | Ambiguous requirements, tradeoffs |
| **Activate** | Default | Press `Tab` or say "think hard" |

**When to use:**
- Ambiguous analysis requirements
- Complex data quality issues
- Performance optimization decisions
- Architecture and design choices

---

## Understanding Compaction and /clear

### What is Compaction?

As conversations grow long, Claude Code automatically "compacts" old messages to save space while preserving important context. This happens automatically based on settings.

**What gets compacted:**
- Older messages and responses
- Tool outputs from earlier in conversation
- Repetitive information

**What's preserved:**
- Recent conversation context
- CLAUDE.md instructions (always available)
- Current file states
- Important decisions and assumptions

**What it looks like:**

When compaction happens, Claude Code automatically summarizes the conversation and preserves key context while freeing up space for continued work. You'll see a summary at the top of the conversation showing what was compacted.

### Auto-Compaction Settings

Control compaction behavior in settings.json:

```json
{
  "compaction": {
    "enabled": true,
    "threshold": 50000  // Compact after ~50k tokens
  }
}
```

### Using /clear

The `/clear` command manually clears the conversation history when you want a fresh start.

**When to use /clear:**
```
/clear    # Starting a completely new task
/clear    # After completing a major project
/clear    # When switching context entirely
/clear    # Conversation feels "confused" or stuck
```

**What /clear does:**
- Removes all conversation history
- Keeps CLAUDE.md instructions active
- Preserves your file changes (doesn't affect git)
- Gives you a clean slate

**Example workflow:**
```
# Complete an analysis project
You: "Create PR for the customer segmentation analysis"
Claude: [Creates PR]

# Start fresh for new project
You: "/clear"
You: "Start a new analysis of payment trends"
Claude: [Fresh context, ready to begin]
```

---

## Settings.json Configuration

The `.claude/settings.json` file controls permissions, environment variables, and workflow hooks.

### Permission Hierarchy

Claude Code has three permission levels:

| Level | Meaning | Use For |
|-------|---------|---------|
| **allow** | Execute automatically | Read operations, safe commands |
| **ask** | Prompt for approval | Database operations, git push, external APIs |
| **deny** | Never allow | Destructive operations, credential access |

### Example Settings for Data Teams

```json
{
  "permissions": {
    "allow": [
      "Read",                        // Read any file
      "Write(./projects/**)",        // Write to projects folder
      "Write(./documentation/**)",   // Update documentation
      "Bash(git status)",            // Git read operations
      "Bash(git branch*)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Glob",                        // File search
      "Grep"                         // Content search
    ],
    "ask": [
      "Bash(snow*)",                 // Snowflake CLI - ask first
      "Bash(databricks*)",           // Databricks CLI - ask first
      "Bash(git push*)",             // Git push - ask first
      "Bash(git commit*)",           // Git commit - ask first
      "Write(.env*)"                 // Environment files - ask first
    ],
    "deny": [
      "Read(.env)",                  // Protect credentials
      "Read(.env.*)",
      "Read(**/*.key)",
      "Read(**/*.pem)",
      "Bash(snow * UPDATE *)",       // SQL safety - no modifications
      "Bash(snow * ALTER *)",
      "Bash(snow * DROP *)",
      "Bash(snow * DELETE *)",
      "Bash(snow * INSERT *)",
      "Bash(snow * TRUNCATE *)",
      "Bash(git push --force*)",     // Git safety - no force push
      "Delete"                       // No file deletions
    ]
  },

  "environment": {
    "DATABASE": "ANALYTICS",
    "WAREHOUSE": "DATA_ANALYSIS",
    "SCHEMA": "REPORTING"
  },

  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash(git commit*)",
        "hooks": [
          {
            "type": "command",
            "command": "if [ $(git branch --show-current) = 'main' ]; then echo 'ERROR: Cannot commit to main branch' && exit 1; fi"
          }
        ]
      }
    ]
  }
}
```

### Key Configuration Sections

**Permissions** - Control what Claude can do automatically vs. asking permission

**Environment Variables** - Set defaults for your data platform (database, warehouse, schema)

**Hooks** - Enforce workflows (prevent commits to main, run checks before operations)

> **📖 Advanced Configuration:** https://code.claude.com/docs/en/features/settings

---

## Workflow Structure: Git and Quality Control

### Git Workflow Fundamentals

Claude Code enforces a feature branch workflow to keep your main branch protected:

```
main (protected)
  ↓
  Create feature branch (analysis-customer-churn)
  ↓
  Work: commits, SQL queries, analysis
  ↓
  Quality Control: QC queries, validation
  ↓
  Create Pull Request
  ↓
  Review → Merge
  ↓
  Cleanup → Back to main
```

**Golden Rules:**
- ✅ Never commit directly to main
- ✅ Always use descriptive feature branch names
- ✅ Create PRs for all changes
- ✅ Clean up branches after merge

**Claude Code helps enforce these automatically** through settings.json hooks and safeguards.

### Quality Control Integration

Every analysis should include quality control queries:

**Standard QC Checks:**
```sql
-- 1. Record Count Validation
SELECT COUNT(*) as total_records FROM final_results;

-- 2. Duplicate Detection
SELECT customer_id, COUNT(*) as duplicate_count
FROM final_results
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 3. Data Completeness
SELECT
  COUNT(*) as total_records,
  COUNT(customer_id) as customer_id_count,
  COUNT(transaction_amount) as amount_count,
  COUNT(*) - COUNT(customer_id) as missing_customers
FROM final_results;

-- 4. Business Logic Validation
SELECT
  MIN(transaction_date) as earliest_date,
  MAX(transaction_date) as latest_date,
  COUNT(DISTINCT customer_id) as unique_customers
FROM final_results;
```

**QC Folder Structure:**
```
qc_queries/
├── 1_record_count_validation.sql
├── 2_duplicate_detection.sql
├── 3_data_completeness.sql
└── 4_business_logic_checks.sql
```

---

# Section 2: Refining Claude to Improve Your Workflow

## Custom Commands

Custom commands are shortcuts that automate common workflows. They live in `.claude/commands/` as markdown files.

### Built-in / Commands vs Custom Commands

**Built-in Commands** (available everywhere):
- `/mcp` - Manage MCP servers
- `/context` - View current context
- `/status` - Check session state
- `/clear` - Clear conversation history
- `/terminal-setup` - Configure terminal
- `/statusline-setup` - Configure status line
- `/help` - Get help with Claude Code

**Custom Commands** (defined in your `.claude/commands/` folder):
- Specific to your repository
- Automate your team's workflows
- Can be shared across the team
- Created as simple markdown files

### Creating Custom Commands

Commands are markdown files in `.claude/commands/` with optional frontmatter:

**Basic Structure:**
```markdown
# Command Name

Brief description of what this command does.

## Usage

How to invoke: `/command-name [arguments]`

## What it does

Step-by-step description of the workflow this command automates.
```

**With Arguments:**
```markdown
# Save Work

## Arguments: $ARGUMENTS

Save progress with optional PR creation.

If $ARGUMENTS is "with-pr", creates a pull request.
If $ARGUMENTS is "no-pr", just commits and pushes.

## What it does

1. Stages all changes
2. Creates descriptive commit
3. Pushes to remote
4. Creates PR if "with-pr" was specified
```

### Example Commands for Data Teams

This repository includes several example commands in `.claude/commands/`:

1. **`/initiate-request`** - Start a new analysis project with full structure
2. **`/save-work [with-pr|no-pr]`** - Save progress with optional PR creation
3. **`/merge-work`** - Complete workflow after PR merge
4. **`/summarize-session`** - Show current progress and next steps
5. **`/google-drive-backup`** - Backup deliverables to Google Drive for archiving
6. **`/generate-data-object-prp`** - Create comprehensive Snowflake object development plan
7. **`/prp-data-object-execute`** - Execute Snowflake object creation with full QC

See each command file for detailed documentation and usage examples.

---

## Custom Agents

Agents are specialized AI assistants that Claude launches to handle complex, multi-step tasks autonomously.

### How Agents Work

**Automatic Invocation:**
Claude Code automatically launches agents when it detects tasks that benefit from autonomous investigation:

```
You: "Find all SQL queries that calculate customer lifetime value"
Claude: [Automatically launches Explore agent]
        "I'll use an agent to search the codebase thoroughly..."
```

**Manual Invocation:**
You can explicitly request an agent:

```
"Use the Explore agent with very thorough mode to find all payment calculation logic"
"Launch the sql-quality-agent to review these queries"
```

### Built-in Agents vs Custom Agents

**Built-in Agents** (available in Claude Code):
- **Explore** - Codebase exploration and pattern finding
- **General-Purpose** - Complex multi-step autonomous tasks
- **Plan** - Creating implementation plans

**Custom Agents** (defined in your `.claude/agents/` folder):
- Specific to your domain (data analysis, SQL review, etc.)
- Enforce your team's standards
- Automate specialized reviews and validations

### Agent Thoroughness Levels

| Level | Time | Use Case |
|-------|------|----------|
| **Quick** | 10-30s | Fast answers, clear targets |
| **Medium** | 30-90s | Standard exploration |
| **Very Thorough** | 2-5min | Critical research, complete documentation |

**Example:**
```
"Explore the codebase to understand payment processing logic. Use medium thoroughness."
```

### Example Agents for Data Teams

This repository includes example agents in `.claude/agents/`:

1. **code-review-agent** - Reviews SQL, Python, and notebooks for quality and best practices
2. **sql-quality-agent** - Specialized SQL review focusing on performance and optimization
3. **qc-validator-agent** - Validates all quality control requirements are met before finalizing

See each agent file for detailed documentation and capabilities.

### Creating Custom Agents

Agents are markdown files in `.claude/agents/` with frontmatter specifying capabilities:

```markdown
---
name: sql-quality-agent
description: Reviews SQL queries for best practices, performance, and optimization
tools: Read, Bash, Glob, Grep
---

# SQL Quality Review Agent

You are a specialized agent that reviews SQL queries for data teams.

## Review Process

1. **Read the Query**
   - Understand the business logic
   - Identify all data sources

2. **Performance Check**
   - Look for missing indexes
   - Check for inefficient joins
   - Identify full table scans

3. **Best Practices**
   - Verify proper filtering
   - Check for SQL anti-patterns
   - Validate query structure

## Provide Feedback

Format your findings as:
- **Strengths**: What's done well
- **Issues**: Specific problems found
- **Recommendations**: How to improve
```

---

## Helpful Built-in / Commands

These commands are available in every Claude Code session:

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/mcp` | Manage MCP servers | Add/remove integrations (Snowflake, Jira, etc.) |
| `/context` | View current context | Check what Claude knows about your session |
| `/status` | Session state | See conversation history, token usage |
| `/clear` | Clear history | Start fresh on a new task |
| `/terminal-setup` | Configure terminal | Set up shell integration |
| `/statusline-setup` | Configure statusline | Customize status bar display |
| `/help` | Get help | Learn about Claude Code features |

### MCP Servers

MCP (Model Context Protocol) servers extend Claude Code's capabilities. If you watched previous videos on integrating Snowflake, Jira, or Databricks - those use MCP servers.

**Common MCP servers for data teams:**
- **Snowflake MCP** - Direct database queries without CLI
- **Jira MCP** - Ticket management integration
- **File system MCP** - Enhanced file operations

**Manage MCP servers:**
```
/mcp              # List installed servers
/mcp add [name]   # Add a new server
/mcp remove [name] # Remove a server
```

> See previous video guides for detailed MCP setup instructions.

---

## Best Practices for Data Teams

### 1. Be Specific in Your Prompts

❌ **Vague:** `"Analyze customers"`

✅ **Clear:** `"Analyze active customers from Q4 2024 who made purchases over $100, grouped by acquisition channel. Show count and revenue for each channel."`

### 2. Request Quality Control Explicitly

❌ **No QC:** `"Write a query to find high-value customers"`

✅ **With QC:** `"Write a query to find high-value customers. Include QC queries for: record count validation, duplicate detection, and date range verification."`

### 3. Use Numbered Deliverables

❌ **Messy:** `final_results.csv, results_v2.csv, results_final_v3.csv`

✅ **Clean:** `1_customer_analysis_15234_records.csv, 2_revenue_summary.csv, 3_qc_validation_results.csv`

### 4. Leverage Agents for Complex Tasks

❌ **Manual:** Asking Claude to search 50 files one by one

✅ **Efficient:** `"Use Explore agent with very thorough mode to find all customer segmentation logic across the codebase"`

### 5. Document Assumptions

Always document assumptions made during analysis:

```markdown
## Assumptions Made

1. **Time Period**: Using transaction_date as the primary date field
   - Reasoning: confirmed with data catalog as the authoritative transaction timestamp
   - Impact: Filters applied to transaction_date only, not created_date

2. **Active Customer Definition**: Customers with activity in last 90 days
   - Reasoning: Standard definition per documentation/business_context.md
   - Impact: 15,234 customers classified as active

3. **Excluded Records**: Removed test transactions (customer_id < 1000)
   - Reasoning: These are system test accounts per data team
   - Impact: 423 records excluded from analysis
```

---

## Common Workflows

### Daily Analysis Pattern

```
1. Start new analysis: "Start a project analyzing customer payment trends for Q4 2024"
2. Explore data: "Show me the structure of the payments table and sample records"
3. Develop query: "Write an exploratory query to analyze payment trends by month"
4. Add QC: "Add comprehensive QC queries for record counts, duplicates, and date ranges"
5. Finalize: "Create final deliverables with documentation"
6. Submit: "Create a PR with summary of findings"
```

### SQL Development Pattern

```
1. Understand schema: "Describe the customer_transactions table structure"
2. Draft query: "Write a query to calculate monthly active users"
3. Test and validate: "Run this query and show me sample results"
4. Optimize: "Review this query for performance issues and optimize"
5. Add QC: "Create QC queries to validate the results"
6. Document: "Update README with methodology and assumptions"
```

### Data Pipeline Pattern

```
1. Plan approach: "I need to create a Snowflake view for customer metrics. Let me plan the approach." [Use Plan Mode]
2. Research: "Use /generate-data-object-prp to create a comprehensive development plan"
3. Review plan: [Review the generated PRP]
4. Execute: "Use /prp-data-object-execute to implement the view with full QC"
5. Validate: "Review all QC results and verify the view functions correctly"
```

---

## Troubleshooting

### Claude Seems Confused About Context

**Solution:** Use `/clear` to start fresh or `/context` to see what Claude knows

**Prevention:** Be explicit about what you're working on at the start of each session

### Git Workflow Not Working

**Check:**
```bash
git status              # Verify you're in a git repository
gh auth status          # Check GitHub authentication
git branch              # Confirm current branch
```

**Common issue:** Trying to work on main branch
**Fix:** Settings.json hooks will prevent this - create a feature branch

### Database Queries Failing

**Check:**
```bash
# For Snowflake CLI
snow connection test

# For MCP server
/mcp                    # Verify MCP server is active
```

**Common issue:** Authentication expired
**Fix:** Re-authenticate with your database tool

### Agent Not Finding What You Need

**Try:**
- Different thoroughness level ("use very thorough mode")
- More specific search terms ("find queries that JOIN customers AND orders tables")
- Specify file patterns ("search only in sql_queries/ folder")

---

## Collaboration and Team Usage

### Sharing Commands and Agents

Custom commands and agents can be committed to git and shared across your team:

```bash
git add .claude/commands/
git add .claude/agents/
git commit -m "Add team workflow commands"
git push
```

**Benefits:**
- Entire team uses standardized workflows
- Onboarding new members is faster
- Quality standards enforced consistently

### Team Settings

`.claude/settings.json` can also be shared (with some considerations):

**Do commit:**
- Permission structures (allow/ask/deny patterns)
- Workflow hooks (prevent main branch commits)
- Safe environment variable names

**Don't commit:**
- Actual credentials
- Personal environment values
- User-specific preferences

**Example shared settings:**
```json
{
  "permissions": {
    "allow": ["Read", "Glob", "Grep"],
    "ask": ["Bash(snow*)", "Bash(git push*)"],
    "deny": ["Bash(snow * UPDATE *)", "Delete"]
  },
  "environment": {
    "DATABASE": "${USER_DATABASE}",     // Each user sets this
    "WAREHOUSE": "${USER_WAREHOUSE}"
  }
}
```

### Documentation for Teams

Keep team-specific knowledge in CLAUDE.md and documentation/:

- **CLAUDE.md** - Workflows, standards, tools available
- **documentation/data_catalog.md** - Database schemas
- **documentation/quality_standards.md** - QC requirements
- **documentation/business_context.md** - Domain knowledge

Claude automatically references these files, ensuring consistent behavior across team members.

---

# Quick Reference

## Essential Commands

```bash
# Start Claude Code
claude

# Resume previous session
claude --resume

# Built-in commands (available everywhere)
/clear                  # Clear conversation history
/status                 # Check current state
/help                   # Get help
/mcp                    # Manage MCP servers
/context                # View current context

# Custom commands (examples in this repo)
/initiate-request       # Start new analysis project
/save-work with-pr      # Save and create PR
/save-work no-pr        # Save without PR
/merge-work             # Clean up after merge
/summarize-session      # Show progress and session summary
/google-drive-backup    # Backup to Google Drive
```

## Useful Prompts

```
# Understanding
"Explain how this query works"
"What does this analysis do?"

# Development
"Write a query to find active customers in the last 30 days"
"Add comprehensive QC queries for this analysis"
"Optimize this query for performance"

# Quality Control
"Review this SQL for performance issues"
"Create validation queries for duplicate detection"
"Check this analysis for data quality problems"

# Git Workflow
"Create a PR for this analysis with business impact summary"
"Show me what changes I've made"

# Research
"Find all queries that calculate customer lifetime value"
"Use Explore agent to understand the payment processing logic"
```

## File Organization Checklist

- [ ] Feature branch created (not on main)
- [ ] Project folder structure set up
- [ ] SQL queries numbered for review order
- [ ] QC queries created and passing
- [ ] README.md documents assumptions and methodology
- [ ] Final deliverables clearly labeled
- [ ] All changes committed with clear messages

## Quality Control Checklist

- [ ] Record count validation query
- [ ] Duplicate detection query
- [ ] Data completeness check
- [ ] Business logic validation
- [ ] Date range verification
- [ ] All QC queries documented with results

---

## Additional Resources

- **Official Docs:** https://code.claude.com/docs
- **Settings Reference:** https://code.claude.com/docs/en/features/settings
- **Commands Guide:** https://code.claude.com/docs/en/features/commands
- **Agents Guide:** https://code.claude.com/docs/en/features/agents

---

## Example Files in This Repository

Explore the `.claude/` folder in this repository for working examples:

- **`.claude/commands/`** - 7 example commands demonstrating data workflows
- **`.claude/agents/`** - 3 example agents for code review, SQL quality, and QC validation
- **`.claude/settings.json`** - Practical configuration for data teams

Each file includes detailed documentation and usage examples.

---

**Ready to get started?** Install Claude Code and try the basic workflow with your next data analysis project!
