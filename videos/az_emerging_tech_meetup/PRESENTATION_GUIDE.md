# The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows

**Speaker:** Kyle Chalmers
**Audience:** ~123 data engineers and professionals
**Format:** ~40 min presentation + 20 min Q&A

| Section | Time | Content |
|---------|------|---------|
| Introduction | 3 min | Hook, overview |
| Foundation | 10 min | CLAUDE.md, commands, agents |
| Demo 1 | 12 min | `/initiate-request` + Snowflake |
| Demo 2 | 12 min | AWS climate analysis |
| Wrap-up | 3 min | Takeaways, resources |
| Q&A | 20 min | Open questions |

---

# SECTION 1: INTRODUCTION (3 minutes)

## Hook (60 seconds)

"What if AI could handle your entire data workflow - you just connect it to the right tools?"

**[Pause]**

"That's not hypothetical. I've been using Claude Code integrated with my data stack for the past year, and it's made me 10x more productive."

"Today I'll show you exactly how - with live demos."

---

## What We'll Cover (90 seconds)

"Here's what's different about my approach: I'm not just using AI to write SQL. I've built a framework around Claude Code that connects it to:"

- **Snowflake** - data warehousing
- **AWS** - S3 storage and Athena data lakes
- **GitHub** - version control
- **Jira/Databricks** - workflow orchestration

"But the tools aren't the magic. The magic is **context engineering** - teaching the AI about YOUR workflows, YOUR data, YOUR standards."

"By the end, you'll understand the patterns that make AI assistants effective partners."

---

## Quick Agenda (30 seconds)

1. **Foundation** - How to structure context (10 min)
2. **Demo 1** - Starting a data request from scratch (12 min)
3. **Demo 2** - AWS data lake analysis (12 min)
4. **Q&A** - Your questions (20 min)

---

# SECTION 2: FOUNDATION - CONTEXT ENGINEERING (10 minutes)

## The Key Insight (2 minutes)

"Here's the most important thing: **Claude Code is only as good as the context you give it.**"

"When I started, I'd say 'write me a query to analyze customer churn.' I got generic queries - no understanding of my schema, my SQL standards, my business logic."

"Then I discovered: Claude reads a file called `CLAUDE.md` at session start. It can use tools you connect. Once I understood that, everything changed."

"**Context engineering** is designing your repo and docs so AI automatically understands your workflows."

---

## Repository Structure (2 minutes)

**[Show terminal]**

```bash
tree -L 2 .
```

**Key structure:**
```
data-ai-tickets-template/
├── .claude/
│   ├── commands/       # Workflow shortcuts
│   ├── agents/         # Specialized reviewers
│   └── settings.json   # Safety rules
├── CLAUDE.md           # The brain
├── tickets/            # Work by ticket
│   └── [user]/[TICKET-XXX]/
│       ├── final_deliverables/  # Numbered outputs
│       └── qc_queries/          # Quality checks
└── documentation/      # Reference materials
```

"Everything organized by ticket, deliverables numbered for review order, always a `CLAUDE.md` capturing context."

"This isn't just organization - it's **teaching Claude how to work**."

---

## CLAUDE.md - The Brain (3 minutes)

**[Open CLAUDE.md]**

```bash
bat CLAUDE.md | head -80
```

"This file is ~800 lines. Key sections:"

### Role Definition
```markdown
## Assistant Role
You are a **Senior Data Engineer** specializing in Snowflake SQL,
Python analysis, quality control, and CLI automation.
```

### Operating Rules
```markdown
## Critical Operating Rules

**NO Permission Required:**
- SELECT queries, reading files, creating scripts

**EXPLICIT Permission Required:**
- Database modifications (UPDATE, ALTER, DROP)
- Git commits and pushes
```

### Available Tools
```markdown
## CLI Tools
- **Snowflake CLI (`snow`)** - Database queries
- **AWS CLI (`aws`)** - S3, Athena
- **GitHub CLI (`gh`)** - Version control
```

"Claude knows who it is, what it can do safely, and what tools it has."

---

## Custom Commands (2 minutes)

**[Show commands folder]**

```bash
ls .claude/commands/
```

"Commands are workflow shortcuts - markdown files."

| Command | Purpose |
|---------|---------|
| `/initiate-request` | Start analysis with full setup |
| `/save-work yes` | Commit, push, create PR |
| `/review-work [folder]` | Run quality agents |

**[Open one briefly]**

```bash
head -40 .claude/commands/initiate-request.md
```

"Instead of remembering 15 steps, I type one command."

---

## Custom Agents (1 minute)

```bash
ls .claude/agents/
```

"Agents are specialized reviewers Claude launches for specific tasks:"

| Agent | Specialty |
|-------|-----------|
| `code-review-agent` | SQL/Python best practices |
| `sql-quality-agent` | Performance optimization |
| `qc-validator-agent` | Quality check completeness |

"The `/review-work` command automatically runs the right agents based on folder contents."

"Pattern: **teach Claude once, benefit forever**."

---

## Transition to Demos

"That's the foundation. You've seen the structure, CLAUDE.md, commands, agents."

"Now let me show you what this looks like in practice. Two live demos - everything is real."

---

# SECTION 3: DEMO 1 - STARTING A DATA REQUEST (12 minutes)

## Quick Verification (30 seconds)

```bash
git status
snow connection list
```

---

## Step 1: Initiate the Request (2 minutes)

**[Type command]**

```
/initiate-request
```

**[Narrate as Claude responds]**

"Watch - Claude will ask what I want, create a branch, set up folders, break down the task."

**[When prompted]**

"Analyze the top 10 customers by total order value from Snowflake sample TPCH data. Include nation, total orders, and average order value."

**[Point out]**

"Notice Claude asks clarifying questions BEFORE starting. Context engineering in action."

---

## Step 2: Watch Claude Work (5 minutes)

**[Let Claude work, narrate key moments]**

"Claude is:"
1. Creating the branch
2. Setting up folders
3. Writing exploratory SQL
4. Building the main query
5. Creating QC validation

**Key moments:**
- **When it runs `snow sql`**: "Querying Snowflake directly from terminal"
- **When it creates files**: "Numbered files for review order"
- **When it asks permission**: "Following our safety rules"

---

## Step 3: Review Deliverables (2 minutes)

```bash
tree tickets/kchalmers/[created-folder]/
bat tickets/kchalmers/[folder]/final_deliverables/1_*.sql
```

"In ~5 minutes, Claude:"
- Created a feature branch
- Set up folder structure
- Wrote production SQL
- Created QC queries
- Documented assumptions

"This used to take me 30+ minutes."

---

## Step 4: Quick Agent Review (1 minute)

```
/review-work tickets/kchalmers/[folder]
```

"Running code-review, sql-quality, qc-validator in parallel."

---

## Step 5: Save Work (1 minute)

```
/save-work yes
```

"Commits, pushes, creates PR with proper description."

**Demo 1 Wrap-up:** "From nothing to reviewed PR in ~12 minutes. I didn't write the SQL - I described what I wanted, Claude wrote it, agents reviewed it."

---

# SECTION 4: DEMO 2 - AWS CLIMATE ANALYSIS (12 minutes)

## Context (30 seconds)

"End-to-end data lake workflow with S3 and Athena."

"IMF climate data - global temperature changes 1961-2024. I want to find which countries warmed most."

"Instead of clicking through AWS Console, Claude handles everything."

---

## Step 1: Start Fresh (30 seconds)

```
/clear
```

---

## Step 2: Describe the Task (1 minute)

"I have climate data in S3 at `s3://kclabs-athena-demo-2026/climate-data/`. IMF Global Surface Temperature dataset, 1961-2024.

I want to:
1. Verify data is in S3
2. Create an Athena table
3. Find top 10 countries with highest temperature change in 2024
4. Show US temperature trend from 1970 to 2024
5. Export results"

---

## Step 3: Watch S3/Athena Integration (5 minutes)

**[Let Claude work, narrate]**

**S3 check:**
"Claude verifying data exists - no console clicking."

**Table creation:**
"Handling async Athena - starts query, waits for completion, fetches results automatically."

**Analysis:**
"Top 10 countries query running."

---

## Step 4: Trend Analysis (2 minutes)

"Show me how US temperature change evolved from 1970 to 2024."

"Claude pivoting the data to show the trend over time."

---

## Step 5: Export (1 minute)

"Export results to CSV."

```bash
# Claude will download from S3
cat ./results.csv
```

---

## Demo 2 Wrap-up (1 minute)

"In ~10 minutes:"
1. Verified S3 data
2. Created Athena table
3. Ran analytical queries
4. Pivoted for trends
5. Exported CSV

"I typed plain English. Claude figured out AWS CLI commands, handled async execution, gave me results."

"**This is 10x productivity** - the work still happened, I just didn't do the mechanical parts."

---

# SECTION 5: WRAP-UP (3 minutes)

## Three Takeaways

### 1. Context is Everything
"Claude Code is only as good as the context you give it. CLAUDE.md, folder structure, documentation - that's what makes AI effective."

### 2. Teach Once, Benefit Forever
"Custom commands and agents encode your best practices. Define your workflow once, every future analysis follows automatically."

### 3. Delegation, Not Automation
"This isn't replacing data professionals. It's delegating mechanical work so you can focus on understanding data and making decisions."

---

## Resources

"Everything I showed is open-sourced:"

- **Repository**: github.com/kyle-chalmers/data-ai-tickets-template
- **Claude Code**: claude.com/download
- **My YouTube**: Detailed integration videos

---

# Q&A (20 minutes)

"Now I want to hear from you. What questions do you have?"

## Common Questions

**Security/credentials?**
"Claude uses environment variables and local CLI configs - never sees credentials directly. Settings.json has deny rules for dangerous operations."

**Sensitive data?**
"Queries run in my environment with my permissions. CLAUDE.md has rules about not outputting raw PII."

**Other databases?**
"If you have a CLI tool, Claude can use it. Pattern is the same for any tool."

**Learning curve?**
"CLAUDE.md takes an afternoon to set up well. Commands and agents develop over time as you identify patterns."

**Cost?**
"Claude Pro is ~$20/month. Productivity gain pays for itself in the first day."

---

## Closing

"Thank you for being here. If this helped you think differently about AI and data workflows, I'd love to connect."

"I'll be around after for anyone who wants to chat about implementations."

"Thanks to Arizona AI & Emerging Technology Meetup for having me!"

---

# APPENDIX: PRE-DEMO CHECKLIST

## Day Before
- [ ] `snow sql -q "SELECT 1" --format csv`
- [ ] `aws sts get-caller-identity`
- [ ] `aws s3 ls s3://kclabs-athena-demo-2026/climate-data/`
- [ ] Clean test branches

## 30 Minutes Before
- [ ] `cd /Users/kylechalmers/Development/data-ai-tickets-template`
- [ ] `git checkout main && git pull`
- [ ] `/clear` in Claude Code
- [ ] Terminal font 18-20pt
- [ ] Notifications off

## Backup Plan
1. **Snowflake fails**: Show pre-run output
2. **AWS timeout**: Have results CSV ready
3. **Claude issues**: Walk through concepts with code samples

---

# APPENDIX: DEMO PROMPTS

## Demo 1: Snowflake
```
Analyze the top 10 customers by total order value from Snowflake sample TPCH data. Include nation, total orders, and average order value.
```

## Demo 2: AWS
```
I have climate data in S3 at s3://kclabs-athena-demo-2026/climate-data/. IMF Global Surface Temperature dataset, 1961-2024.

I want to:
1. Verify data is in S3
2. Create an Athena table
3. Find top 10 countries with highest temperature change in 2024
4. Show US temperature trend from 1970 to 2024
5. Export results
```

## Trend Follow-up
```
Show me how US temperature change evolved from 1970 to 2024.
```
