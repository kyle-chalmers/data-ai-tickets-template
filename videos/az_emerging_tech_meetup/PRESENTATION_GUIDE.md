# The AI-Empowered Data Revolution: Hands-On Demos to 10X Your Data Workflows

**Speaker:** Kyle Chalmers
**Event:** Arizona AI & Emerging Technology Meetup
**Date:** Tuesday, January 21, 2026, 6:00 PM MST
**Format:** ~40 min presentation + 20 min Q&A

| Section | Time | Cumulative | Content |
|---------|------|------------|---------|
| Introduction | 3 min | 0:03 | Hook, overview |
| Foundation | 10 min | 0:13 | CLAUDE.md, commands, agents |
| Demo 1 | 12 min | 0:25 | Jira -> S3 -> Snowflake (CO2 data) |
| Demo 2 | 12 min | 0:37 | Jira -> Databricks job (Arizona weather) |
| Wrap-up | 3 min | 0:40 | Takeaways, resources |
| Q&A | 20 min | 1:00 | Open questions |

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
- **Jira** - ticket tracking and workflow

"But the tools aren't the magic. The magic is **context engineering** - teaching the AI about YOUR workflows, YOUR data, YOUR standards."

"By the end, you'll understand the patterns that make AI assistants effective partners."

---

## Quick Agenda (30 seconds)

1. **Foundation** - How to structure context (10 min)
2. **Demo 1** - Data analysis: Jira to Snowflake (12 min)
3. **Demo 2** - Infrastructure: Build a Databricks job (12 min)
4. **Q&A** - Your questions (20 min)

---

# SECTION 2: FOUNDATION - CONTEXT ENGINEERING (10 minutes)

## The Key Insight (2 minutes)

"The most important thing I've learned: **Claude Code is only as good as the context you give it.**"

"Early on, I'd say 'analyze customer churn.' Generic SQL, no understanding of my schema or standards."

"Then I discovered Claude reads a file called CLAUDE.md at session start. It uses CLI tools you connect. That changed everything."

"**Context engineering** is designing your repo so AI automatically understands your workflows. Let me show you the three components."

---

## Component 1: Folder Structure (3 minutes)

**[Show terminal - already in repo directory]**

```bash
ls -la
```

**[Point to key folders]**

"Three things matter here:"

1. **`.claude/`** - Commands and agents live here
2. **`CLAUDE.md`** - The brain - 700+ lines of instructions
3. **`tickets/`** - Where all work goes

**[Show ticket structure]**

```bash
ls -la tickets/kchalmers/
```

"Every ticket gets its own folder. Let's look inside one."

```bash
ls -la tickets/kchalmers/KAN-4/
```

"Standard structure: README.md, final_deliverables folder, source_materials. Claude creates this automatically."

**[Show deliverables]**

```bash
ls tickets/kchalmers/KAN-4/final_deliverables/
```

"Notice the numbering - `1_`, `2_`, `3_`. That's intentional. Files are numbered in review order. Human reviewers read top to bottom."

"This isn't just organization. It's **teaching Claude your workflow**. When I say 'create deliverables,' Claude knows: numbered files, separate QC folder, follow the pattern."

---

## Component 2: CLAUDE.md - The Brain (4 minutes)

**[Open CLAUDE.md in editor or use less]**

```bash
less CLAUDE.md
```

"700 lines. I'll show you three critical sections."

**[Scroll to Role section - around line 37]**

"**First: Role definition.**"

```markdown
You are a **Senior Data Engineer and Business Intelligence Engineer**
specializing in Snowflake SQL development, Python data analysis,
data architecture, quality control, ticket resolution, and CLI automation.
```

"This sets the expertise level. Claude writes SQL like a senior engineer, not a beginner."

**[Scroll to Permission Hierarchy - around line 65]**

"**Second: Permission hierarchy.** This is critical for safety."

```markdown
**NO Permission Required (Internal to Repository):**
- SELECT queries and data exploration in Snowflake
- Reading files, searching, analyzing existing code
- Writing/editing files within the repository

**EXPLICIT Permission Required (External Operations):**
- Database modifications (UPDATE, ALTER, DROP)
- Git commits and pushes
```

"Claude can read and analyze freely. But before modifying production data or pushing code? It stops and asks."

**[Scroll to CLI Tools - around line 205]**

"**Third: Available tools.**"

```markdown
## Available CLI Tools

- **Snowflake CLI (`snow`)** - Database queries and management
- **AWS CLI (`aws`)** - Cloud services management (S3, Athena)
- **GitHub CLI (`gh`)** - Repository and issue management
- **Jira CLI (`acli`)** - Ticket tracking and workflow
```

"Claude knows exactly which tools it can use. In the demos, you'll see it call `snow sql`, `aws s3`, `acli jira` - all because it's documented here."

**[Exit less with 'q']**

"Key insight: **this file is your contract with the AI**. Be specific about what it should do, and it will."

---

## Component 3: Commands (1 minute)

```bash
ls .claude/commands/
```

"Commands are workflow shortcuts. Three you'll see in the demos:"

| Command | What It Does |
|---------|--------------|
| `/initiate-request` | Creates branch, folders, starts analysis |
| `/save-work yes` | Commits, pushes, creates PR |
| `/review-work` | Runs quality agents on your code |

"I won't explain them now - you'll see them in action."

---

## Transition to Demos

"That's the foundation: **folder structure**, **CLAUDE.md**, **commands**."

"Context engineering means teaching the AI your patterns once, then benefiting every time you work."

"Let me show you what this looks like in practice. First demo: a complete data pipeline from scratch."

---

# SECTION 3: DEMO 1 - COMPLETE DATA PIPELINE (12 minutes)

## Context (30 seconds)

"This demo shows a complete workflow: describe a request conversationally, and Claude handles everything - Jira ticket creation, data download, S3 upload, Snowflake loading, analysis, and ticket closure."

"We're using CO2 emissions data from Our World in Data - 50,000 rows covering 255 countries from 1750 to 2024."

"I'm going to type one prompt and let Claude figure out the approach."

---

## Quick Verification (30 seconds)

```bash
git status
snow connection list
aws sts get-caller-identity
```

---

## Step 1: Describe the Request (1 minute)

**[Type this prompt - conversational, not step-by-step]**

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

**[Point out]**

"Notice I didn't give step-by-step commands. I described what I want. Claude has to figure out which tools to use and in what order."

---

## Step 2: Watch Claude Work (7 minutes)

**[Let Claude work, narrate key moments]**

### Jira Ticket Creation (~1 min)

"First, Claude creates the Jira ticket. Watch - it's using `acli jira workitem create`. It understood 'KAN project' and translated that to the right CLI command."

**Key insight to mention:**
"This is the reasoning I wanted to show. Claude read our CLAUDE.md, saw that `acli` is available for Jira, and figured out the syntax."

### Data Download (~1 min)

"Now it's downloading the CSV. Simple curl command. But notice it's inspecting the data - checking the structure, row count."

**When it shows the data:**
"50,000 rows, 79 columns. Country, year, CO2 emissions, breakdowns by fuel type. Rich data."

### S3 Upload (~1 min)

"Uploading to S3 using AWS CLI. Watch for the confirmation."

**When upload completes:**
"Data is now in our cloud storage. Anyone on the team can access it."

### Snowflake Table Creation (~2 min)

"Here's the interesting part. Claude has to create a table schema that matches the CSV. Watch how it figures out column types."

**When it creates the table:**
"It analyzed the CSV headers, determined data types, created the DDL. Senior engineer work, done automatically."

**When it loads data:**
"COPY INTO statement - that's how you bulk load into Snowflake. Claude knew the pattern."

### Analysis Queries (~2 min)

"Now the fun part - actual analysis."

**Top 10 emitters:**
"There it is - [China/US] at the top with [X] million tonnes. That's [X]% of global emissions."

**US trend:**
"US emissions over time. See the decline after 2007? That's the shift away from coal. This is the kind of insight that matters to stakeholders."

---

## Step 3: Ticket Closure (30 seconds)

**[When Claude transitions the ticket]**

"And finally - transitioning the Jira ticket to Done. Full workflow complete."

"From 'I want to analyze CO2 emissions' to 'ticket closed with results' - one conversation."

---

## Demo 1 Wrap-up (30 seconds)

"In ~10 minutes, Claude:"
1. Created a Jira ticket
2. Downloaded 50K rows of climate data
3. Uploaded to S3
4. Created Snowflake table with proper schema
5. Loaded the data
6. Ran analytical queries
7. Closed the ticket

"I typed one prompt. Claude handled the CLI tools, the data pipeline, the analysis."

"**This is what I mean by 10x productivity.** The work still happened - I just didn't do the mechanical parts."

---

# SECTION 4: DEMO 2 - DATABRICKS JOB CREATION (12 minutes)

**[TRANSITION - Clear Claude session before Demo 2]**

```
/clear
```

"Let me clear the session for a fresh start."

## Context (30 seconds)

"Now something different: building infrastructure instead of analyzing data."

"Demo 1 was a one-time analysis. Demo 2 is building something that runs every month - automation."

"I'll describe what I need, and Claude will research APIs, write production code, deploy it, and test it."

---

## Step 1: Describe the Task (1 minute)

**[Type the prompt]**

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

**Point out:**
"Notice I asked Claude to show reasoning. This is different from Demo 1 - I want to see the thinking."

---

## Step 2: Watch Claude Research (2 minutes)

**[Let Claude work, narrate]**

**Jira ticket creation:**
"First, it creates a ticket. Same pattern as Demo 1."

**API research:**
"Now watch - Claude is evaluating climate data APIs. It's looking for free access, no auth required, reliable data."

**Key insight:**
"Claude picked Open-Meteo. Why? Free, no API key, updates daily. That's the kind of reasoning you want to see."

---

## Step 3: Watch Claude Build (4 minutes)

**[Narrate as Claude creates files]**

**Job script creation:**
"Claude is writing Python code. Notice it's handling API errors, validating data, using logging. Senior engineer patterns."

**Scheduling reasoning:**
"Why the 3rd of the month? Claude figured out the API has a 5-day lag. Running on the 3rd ensures complete data. That's thinking, not just coding."

**Cluster configuration:**
"Single-node cluster for a small job. No over-provisioning. Cost-conscious decisions."

---

## Step 4: Watch Deployment (2 minutes)

**[Narrate deployment steps]**

**Upload to DBFS:**
"Claude uploads the Python script to Databricks file storage."

**Create job:**
"Now creating the scheduled job from a config file."

**Trigger test run:**
"Let's run it manually to verify it works."

---

## Step 5: Job Completion (1 minute)

**[When test completes]**

"Job ran successfully. 10 Arizona cities, monthly weather stats collected."

**Ticket closure:**
"And Claude closes the Jira ticket with a summary of what was built."

---

## Demo 2 Wrap-up (1 minute)

"Different from Demo 1. This wasn't analysis - it was building infrastructure."

"In ~10 minutes, Claude:"
1. Created a Jira ticket
2. Researched and selected an API
3. Wrote production-quality Python code
4. Created Databricks job configuration
5. Deployed to our workspace
6. Tested the job
7. Closed the ticket

"I described the need. Claude handled the implementation."

"**This is what I mean by delegation** - not just queries, but building systems that run themselves."

---

# SECTION 5: WRAP-UP (3 minutes)

**[TRANSITION]**

"So we've seen two complete workflows - analysis and infrastructure. Let me leave you with three key takeaways."

## Three Takeaways (2 minutes)

### 1. Context is Everything
"Claude Code is only as good as the context you give it. CLAUDE.md, folder structure, documentation - that's what makes AI effective."

### 2. Teach Once, Benefit Forever
"Custom commands and agents encode your best practices. Define your workflow once, every future analysis follows automatically."

### 3. Delegation, Not Automation
"This isn't replacing data professionals. It's delegating mechanical work so you can focus on understanding data and making decisions."

---

## Resources (1 minute)

"Everything I showed is open-sourced:"

- **Repository**: github.com/kyle-chalmers/data-ai-tickets-template
- **Claude Code**: claude.com/download
- **My YouTube**: KC Labs AI - Detailed integration videos

"The repo has all the CLAUDE.md examples, commands, agents, and the Databricks job we just created."

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
- [ ] `aws s3 ls s3://kclabs-athena-demo-2026/`
- [ ] `acli jira project list --filter KAN`
- [ ] `databricks workspace list / --profile bidev`
- [ ] Test Open-Meteo API: `curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-05&daily=temperature_2m_max"`
- [ ] Clean test branches

## 30 Minutes Before
- [ ] `cd /Users/kylechalmers/Development/data-ai-tickets-template`
- [ ] `git checkout main && git pull`
- [ ] `/clear` in Claude Code
- [ ] Terminal font 18-20pt
- [ ] Notifications off

## Backup Plan
1. **Jira fails**: Skip ticket creation, show data pipeline only
2. **Snowflake fails**: Demo 1 can work with just S3 + local analysis
3. **Databricks fails**: Show the job code walkthrough, explain what deployment would do
4. **Open-Meteo API down**: Use cached test data from local run
5. **Claude issues**: Walk through concepts with code samples

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
