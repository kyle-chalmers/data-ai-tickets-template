# Presenter Guide: The AI-Empowered Data Revolution

**For Kyle's eyes only during presentation**

---

## Quick Reference Card

| Section | Duration | Cumulative | Key Action |
|---------|:--------:|:----------:|------------|
| Introduction | 3 min | 0:03 | Hook + overview |
| Foundation | 10 min | 0:13 | Show CLAUDE.md, folder structure |
| Demo 1 | 12 min | 0:25 | Paste prompt, narrate while working |
| Demo 2 | 12 min | 0:37 | Paste prompt, highlight reasoning |
| Wrap-up | 3 min | 0:40 | Three takeaways + QR codes |
| Q&A | 20 min | 1:00 | Open questions |

**Critical Commands:**
- `/clear` - Clear Claude session between demos
- Demo prompts are in README.md (screen share file)

---

## Pre-Demo Checklist

### Day Before
- [x] `snow sql -q "SELECT 1" --format csv`
- [x] `aws sts get-caller-identity`
- [x] `aws s3 ls s3://kclabs-athena-demo-2026/`
- [x] `acli jira project list --limit 10` (verify KAN appears)
- [x] `databricks workspace list /`
- [x] Test Open-Meteo API:
  ```bash
  curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-05&daily=temperature_2m_max"
  ```
- [x] Clean test branches: `git branch -d [demo-branches]`

### 30 Minutes Before
- [ ] `cd /Users/kylechalmers/Development/data-ai-tickets-template`
- [ ] `git checkout main && git pull`
- [ ] Start Claude Code, run `/clear`
- [ ] Terminal font: **18-20pt**
- [ ] Theme: Dark with high contrast
- [ ] Notifications: **OFF**
- [ ] Second monitor: This guide open for reference

### Connection Verification Script
```bash
snow connection list
snow sql -q "SELECT 1" --format csv
aws sts get-caller-identity
acli jira project list --limit 10
databricks workspace list /
```

**Expected Results:**
- Snowflake: Shows connection list, returns "1"
- AWS: Shows account ID and user ARN
- Jira: Shows KAN project
- Databricks: Shows workspace root

---

## Terminal Setup

```
┌─────────────────────────────────────────────────────────┐
│  TERMINAL SETTINGS                                      │
├─────────────────────────────────────────────────────────┤
│  Font Size:        18-20pt (readable from back row)     │
│  Theme:            Dark background, high contrast       │
│  Notifications:    OFF (Do Not Disturb mode)            │
│  Second Monitor:   This PRESENTATION_GUIDE.md           │
│  Screen Share:     README.md (audience-facing)          │
└─────────────────────────────────────────────────────────┘
```

---

## Full Speaker Script

### SECTION 1: INTRODUCTION (3 minutes)

#### Hook (60 seconds)

**SAY:**
> "What if AI could handle your entire data workflow - you just connect it to the right tools?"

*[Pause for effect]*

> "That's not hypothetical. I've been using Claude Code integrated with my data stack for the past year, and it's made me 10x more productive."
>
> "Today I'll show you exactly how - with live demos."

#### What We'll Cover (90 seconds)

**SAY:**
> "Here's what's different about my approach: I'm not just using AI to write SQL. I've built a framework around Claude Code that connects it to:"
>
> - **Snowflake** - data warehousing
> - **AWS** - S3 storage and Athena data lakes
> - **GitHub** - version control
> - **Jira** - ticket tracking and workflow
>
> "But the tools aren't the magic. The magic is **context engineering** - teaching the AI about YOUR workflows, YOUR data, YOUR standards."
>
> "By the end, you'll understand the patterns that make AI assistants effective partners."

#### Quick Agenda (30 seconds)

**SAY:**
> 1. **Foundation** - How to structure context (10 min)
> 2. **Demo 1** - Data analysis: Jira to Snowflake (12 min)
> 3. **Demo 2** - Infrastructure: Build a Databricks job (12 min)
> 4. **Q&A** - Your questions (20 min)

---

### SECTION 2: FOUNDATION (10 minutes)

#### The Key Insight (2 minutes)

**SAY:**
> "The most important thing I've learned: **Claude Code is only as good as the context you give it.**"
>
> "Early on, I'd say 'analyze customer churn.' Generic SQL, no understanding of my schema or standards."
>
> "Then I discovered Claude reads a file called CLAUDE.md at session start. It uses CLI tools you connect. That changed everything."
>
> "**Context engineering** is designing your repo so AI automatically understands your workflows. Let me show you the three components."

#### Component 1: Folder Structure (3 minutes)

**DO:** Show terminal (already in repo directory)
```bash
ls -la
```

**SAY:**
> "Three things matter here:"
> 1. **`.claude/`** - Commands and agents live here
> 2. **`CLAUDE.md`** - The brain - 700+ lines of instructions
> 3. **`tickets/`** - Where all work goes

**DO:** Show ticket structure
```bash
ls -la tickets/kchalmers/
```

**SAY:**
> "Every ticket gets its own folder. Let's look inside one."

```bash
ls -la tickets/kchalmers/KAN-4/
```

> "Standard structure: README.md, final_deliverables folder, source_materials. Claude creates this automatically."

**DO:** Show deliverables
```bash
ls tickets/kchalmers/KAN-4/final_deliverables/
```

**SAY:**
> "Notice the numbering - `1_`, `2_`, `3_`. That's intentional. Files are numbered in review order. Human reviewers read top to bottom."
>
> "This isn't just organization. It's **teaching Claude your workflow**. When I say 'create deliverables,' Claude knows: numbered files, separate QC folder, follow the pattern."

#### Component 2: CLAUDE.md (4 minutes)

**DO:** Open CLAUDE.md
```bash
less CLAUDE.md
```

**SAY:**
> "700 lines. I'll show you three critical sections."

**DO:** Scroll to Role section (around line 37, search `/Assistant Role`)

**SAY:**
> "**First: Role definition.**"
> ```
> You are a **Senior Data Engineer and Business Intelligence Engineer**
> specializing in Snowflake SQL development, Python data analysis...
> ```
> "This sets the expertise level. Claude writes SQL like a senior engineer, not a beginner."

**DO:** Scroll to Permission Hierarchy (around line 65, search `/Permission Hierarchy`)

**SAY:**
> "**Second: Permission hierarchy.** This is critical for safety."
>
> "Claude can read and analyze freely. But before modifying production data or pushing code? It stops and asks."

**DO:** Scroll to CLI Tools (around line 205, search `/Available CLI Tools`)

**SAY:**
> "**Third: Available tools.**"
>
> "Claude knows exactly which tools it can use. In the demos, you'll see it call `snow sql`, `aws s3`, `acli jira` - all because it's documented here."

**DO:** Exit with 'q'

**SAY:**
> "Key insight: **this file is your contract with the AI**. Be specific about what it should do, and it will."

#### Component 3: Commands (1 minute)

**DO:**
```bash
ls .claude/commands/
```

**SAY:**
> "Commands are workflow shortcuts. Three you'll see in the demos:"
>
> | Command | What It Does |
> |---------|--------------|
> | `/initiate-request` | Creates branch, folders, starts analysis |
> | `/save-work yes` | Commits, pushes, creates PR |
> | `/review-work` | Runs quality agents on your code |
>
> "I won't explain them now - you'll see them in action."

#### Transition to Demos

**SAY:**
> "That's the foundation: **folder structure**, **CLAUDE.md**, **commands**."
>
> "Context engineering means teaching the AI your patterns once, then benefiting every time you work."
>
> "Let me show you what this looks like in practice. First demo: a complete data pipeline from scratch."

---

### SECTION 3: DEMO 1 (12 minutes)

#### Context (30 seconds)

**SAY:**
> "This demo shows a complete workflow: describe a request conversationally, and Claude handles everything - Jira ticket creation, data download, S3 upload, Snowflake loading, analysis, and ticket closure."
>
> "We're using CO2 emissions data from Our World in Data - 50,000 rows covering 255 countries from 1750 to 2024."
>
> "I'm going to type one prompt and let Claude figure out the approach."

#### Quick Verification (30 seconds)

**DO:**
```bash
git status
snow connection list
aws sts get-caller-identity
```

#### Step 1: Describe the Request (1 minute)

**DO:** Copy prompt from README.md (Demo 1 Prompt section)

**SAY:**
> "Notice I didn't give step-by-step commands. I described what I want. Claude has to figure out which tools to use and in what order."

#### Step 2: Watch Claude Work (7 minutes)

**NARRATE as Claude works:**

**Jira Ticket Creation (~1 min):**
> "First, Claude creates the Jira ticket. Watch - it's using `acli jira workitem create`. It understood 'KAN project' and translated that to the right CLI command."
>
> "This is the reasoning I wanted to show. Claude read our CLAUDE.md, saw that `acli` is available for Jira, and figured out the syntax."

**Data Download (~1 min):**
> "Now it's downloading the CSV. Simple curl command. But notice it's inspecting the data - checking the structure, row count."
>
> *When it shows the data:*
> "50,000 rows, 79 columns. Country, year, CO2 emissions, breakdowns by fuel type. Rich data."

**S3 Upload (~1 min):**
> "Uploading to S3 using AWS CLI. Watch for the confirmation."
>
> *When upload completes:*
> "Data is now in our cloud storage. Anyone on the team can access it."

**Snowflake Table Creation (~2 min):**
> "Here's the interesting part. Claude has to create a table schema that matches the CSV. Watch how it figures out column types."
>
> *When it creates the table:*
> "It analyzed the CSV headers, determined data types, created the DDL. Senior engineer work, done automatically."
>
> *When it loads data:*
> "COPY INTO statement - that's how you bulk load into Snowflake. Claude knew the pattern."

**Analysis Queries (~2 min):**
> "Now the fun part - actual analysis."
>
> *Top 10 emitters:*
> "There it is - [China/US] at the top with [X] million tonnes. That's [X]% of global emissions."
>
> *US trend:*
> "US emissions over time. See the decline after 2007? That's the shift away from coal. This is the kind of insight that matters to stakeholders."

#### Step 3: Ticket Closure (30 seconds)

*When Claude transitions the ticket:*

**SAY:**
> "And finally - transitioning the Jira ticket to Done. Full workflow complete."
>
> "From 'I want to analyze CO2 emissions' to 'ticket closed with results' - one conversation."

#### Demo 1 Wrap-up (30 seconds)

**SAY:**
> "In ~10 minutes, Claude:"
> 1. Created a Jira ticket
> 2. Downloaded 50K rows of climate data
> 3. Uploaded to S3
> 4. Created Snowflake table with proper schema
> 5. Loaded the data
> 6. Ran analytical queries
> 7. Closed the ticket
>
> "I typed one prompt. Claude handled the CLI tools, the data pipeline, the analysis."
>
> "**This is what I mean by 10x productivity.** The work still happened - I just didn't do the mechanical parts."

---

### SECTION 4: DEMO 2 (12 minutes)

#### TRANSITION

**DO:**
```
/clear
```

**SAY:**
> "Let me clear the session for a fresh start."

#### Context (30 seconds)

**SAY:**
> "Now something different: building infrastructure instead of analyzing data."
>
> "Demo 1 was a one-time analysis. Demo 2 is building something that runs every month - automation."
>
> "I'll describe what I need, and Claude will research APIs, write production code, deploy it, and test it."

#### Step 1: Describe the Task (1 minute)

**DO:** Copy prompt from README.md (Demo 2 Prompt section)

**SAY:**
> "Notice I asked Claude to show reasoning. This is different from Demo 1 - I want to see the thinking."

#### Step 2: Watch Claude Research (2 minutes)

**NARRATE:**

*Jira ticket creation:*
> "First, it creates a ticket. Same pattern as Demo 1."

*API research:*
> "Now watch - Claude is evaluating climate data APIs. It's looking for free access, no auth required, reliable data."

**Key insight:**
> "Claude picked Open-Meteo. Why? Free, no API key, updates daily. That's the kind of reasoning you want to see."

#### Step 3: Watch Claude Build (4 minutes)

**NARRATE:**

*Job script creation:*
> "Claude is writing Python code. Notice it's handling API errors, validating data, using logging. Senior engineer patterns."

*Scheduling reasoning:*
> "Why the 3rd of the month? Claude figured out the API has a 5-day lag. Running on the 3rd ensures complete data. That's thinking, not just coding."

*Cluster configuration:*
> "Single-node cluster for a small job. No over-provisioning. Cost-conscious decisions."

#### Step 4: Watch Deployment (2 minutes)

**NARRATE:**

*Upload to DBFS:*
> "Claude uploads the Python script to Databricks file storage."

*Create job:*
> "Now creating the scheduled job from a config file."

*Trigger test run:*
> "Let's run it manually to verify it works."

#### Step 5: Job Completion (1 minute)

*When test completes:*

**SAY:**
> "Job ran successfully. 10 Arizona cities, monthly weather stats collected."

*Ticket closure:*
> "And Claude closes the Jira ticket with a summary of what was built."

#### Demo 2 Wrap-up (1 minute)

**SAY:**
> "Different from Demo 1. This wasn't analysis - it was building infrastructure."
>
> "In ~10 minutes, Claude:"
> 1. Created a Jira ticket
> 2. Researched and selected an API
> 3. Wrote production-quality Python code
> 4. Created Databricks job configuration
> 5. Deployed to our workspace
> 6. Tested the job
> 7. Closed the ticket
>
> "I described the need. Claude handled the implementation."
>
> "**This is what I mean by delegation** - not just queries, but building systems that run themselves."

---

### SECTION 5: WRAP-UP (3 minutes)

**SAY:**
> "So we've seen two complete workflows - analysis and infrastructure. Let me leave you with three key takeaways."

#### Three Takeaways (2 minutes)

**1. Context is Everything**
> "Claude Code is only as good as the context you give it. CLAUDE.md, folder structure, documentation - that's what makes AI effective."

**2. Tools Become Seamless**
> "Natural language becomes your universal API. You just saw me orchestrate Jira, S3, Snowflake, and Databricks without memorizing CLI syntax or switching contexts."

**3. More Thinking, Less Typing**
> "Your role shifts from execution to oversight. AI handles the mechanical work while you focus on critical thinking, quality control, and decision-making."

#### Resources (1 minute)

**DO:** Show QR codes from README.md on screen

**SAY:**
> "Everything I showed is open-sourced. I've got QR codes up so you can grab these easily:"
>
> - **GitHub Repo** - All the CLAUDE.md examples, commands, agents
> - **LinkedIn** - Connect professionally
> - **YouTube** - Detailed videos on each integration

---

### Q&A (20 minutes)

**SAY:**
> "Now I want to hear from you. What questions do you have?"

#### Common Questions & Answers

**Security/credentials?**
> "Claude uses environment variables and local CLI configs - never sees credentials directly. Settings.json has deny rules for dangerous operations."

**Sensitive data?**
> "Queries run in my environment with my permissions. CLAUDE.md has rules about not outputting raw PII."

**Other databases?**
> "If you have a CLI tool, Claude can use it. Pattern is the same for any tool."

**Learning curve?**
> "CLAUDE.md takes an afternoon to set up well. Commands and agents develop over time as you identify patterns."

**Cost?**
> "Claude Pro is ~$20/month. Productivity gain pays for itself in the first day."

---

### Closing Script

**SAY:**
> "Thank you for being here tonight. If this helped you think differently about AI and data workflows, I'd love to connect."

**DO:** Keep QR codes on screen

**SAY:**
> "The QR codes are still up - LinkedIn if you want to connect professionally, YouTube for more detailed tutorials on each integration, and GitHub for all the code."
>
> "I'll be around after for anyone who wants to chat about implementations or see anything in more detail."
>
> "Thanks to Arizona AI & Emerging Technology Meetup for having me!"

---

## Backup Plans

| Issue | Action |
|-------|--------|
| **Snowflake fails** | Use pre-run CSV results, show S3 + local analysis |
| **AWS timeout** | Show S3 console, manual upload demo |
| **Databricks fails** | Walk through code, explain deployment steps |
| **Jira fails** | Skip ticket creation, focus on data pipeline |
| **Open-Meteo API down** | Use pre-cached test data or skip to job structure |
| **Claude unresponsive** | `/clear` and retry, or use backup commands below |

### Recovery Strategy
1. If Demo 1 fails mid-way, switch to Demo 2
2. If Demo 2 fails mid-way, switch to Q&A with conceptual discussion
3. If both demos fail, walk through backup commands manually

---

## Backup Commands

### Demo 1 Manual Commands

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
head -5 /tmp/owid-co2-data.csv
wc -l /tmp/owid-co2-data.csv
```

**Upload to S3:**
```bash
aws s3 cp /tmp/owid-co2-data.csv s3://kclabs-athena-demo-2026/co2-emissions/owid-co2-data.csv
aws s3 ls s3://kclabs-athena-demo-2026/co2-emissions/ --human-readable
```

**Top 10 Emitters Query:**
```sql
SELECT country, iso_code, ROUND(co2, 2) as co2_mt, ROUND(share_global_co2, 2) as pct_global
FROM DEMO_DATA.PUBLIC.CO2_EMISSIONS
WHERE year = 2024 AND iso_code IS NOT NULL AND LENGTH(iso_code) = 3 AND co2 IS NOT NULL
ORDER BY co2 DESC LIMIT 10;
```

**US Trend Query:**
```sql
SELECT year, ROUND(co2, 2) as co2_mt, ROUND(co2_per_capita, 2) as per_capita
FROM DEMO_DATA.PUBLIC.CO2_EMISSIONS
WHERE country = 'United States' AND year >= 2000
ORDER BY year;
```

**Close Ticket:**
```bash
acli jira workitem transition --key "KAN-XX" --status "Done"
```

### Demo 2 Manual Commands

**Create Jira Ticket:**
```bash
acli jira workitem create --project KAN \
  --type Task \
  --summary "Set up automated climate data collection for Arizona" \
  --description "Create Databricks job to fetch monthly weather data from Open-Meteo API."
```

**Test API:**
```bash
curl -s "https://archive-api.open-meteo.com/v1/archive?latitude=33.45&longitude=-112.07&start_date=2024-12-01&end_date=2024-12-31&daily=temperature_2m_max,temperature_2m_min&timezone=America/Phoenix" | jq '.daily'
```

**Deploy Job:**
```bash
databricks fs cp databricks_jobs/climate_data_refresh/climate_refresh.py \
  dbfs:/jobs/climate_data_refresh/climate_refresh.py databricks jobs create --json-file databricks_jobs/climate_data_refresh/job_config.json ```

**Trigger Run:**
```bash
JOB_ID=$(databricks jobs list --profile bidev | grep "Climate Data" | awk '{print $1}')
databricks jobs run-now --job-id $JOB_ID ```

**Close Ticket:**
```bash
acli jira workitem transition --key "KAN-XX" --status "Done"
```

---

## Troubleshooting Quick Reference

| Issue | Diagnostic Command | Resolution |
|-------|-------------------|------------|
| Snowflake connection | `snow connection test` | Check credentials, Duo auth |
| AWS timeout | `aws sts get-caller-identity` | Refresh credentials |
| Jira CLI | `acli jira project list` | Check token validity |
| Databricks connection | `databricks workspace list / --profile bidev` | Verify profile config |
| Claude unresponsive | `/clear` | Clear session and retry |
| Databricks job stuck | `databricks runs cancel --run-id $RUN_ID --profile bidev` | Cancel and retry |
| S3 permission denied | `aws s3 ls s3://kclabs-athena-demo-2026/ --debug 2>&1 | head -20` | Check IAM permissions |

---

## Post-Presentation Cleanup

```bash
# Return to main branch
git checkout main

# Delete demo branches
git branch -d [branch-name]

# Clean tickets folder (if created during demo)
git clean -fd tickets/

# Optional: Remove demo data from Snowflake
snow sql -q "DROP TABLE IF EXISTS DEMO_DATA.PUBLIC.CO2_EMISSIONS"
```

---

*Good luck! You've got this.*
