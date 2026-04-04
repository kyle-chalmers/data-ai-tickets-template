# AZ Tech Week Workshop: The Practical AI Playbook

## Overview

**Event:** The Practical AI Playbook Workshop at AZ Tech Week
**Date:** Wednesday, April 8, 2026, 5:30 PM - 8:00 PM MST
**Venue:** 1951 @ SkySong, 1475 N Scottsdale Rd, Scottsdale, AZ 85257
**Role:** Kyle Chalmers — sole presenter and facilitator
**Audience:** ~30-40 attendees, mixed levels (practitioners, founders, leaders, students), all motivated to learn about AI tools
**Event page:** [https://partiful.com/e/VPy2EpNYQFppO6ZQA17n](https://partiful.com/e/VPy2EpNYQFppO6ZQA17n)

## Design: Context Engineering Playbook — Framework + Audience-Driven Demo + Personalized Exercise

Three-act structure delivering three takeaways:

1. Attendees install and use an AI coding tool (enabled by prerequisite video)
2. They understand the Context Engineering framework and can apply it to their own work
3. They leave with a playbook template and their own started project

---

## Workshop Agenda

| Block                          | Time       | Duration | Description                                                                                                                                                                 |
| ------------------------------ | ---------- | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Doors & Settle                 | 5:30-5:45  | 15 min   | Arrive, connect to wifi, open laptops                                                                                                                                       |
| Welcome & Framing              | 5:45-6:00  | 15 min   | Kyle's intro, audience pulse check, quick Context Engineering overview (name the 4 layers visually, don't deep-dive)                                                        |
| Live Demo (audience-polled)    | 6:00-6:35  | 35 min   | Audience votes on which archetype to demo. Kyle builds the Context Engineering playbook live, calling out framework layers as they appear. Includes a real tool connection.  |
| Guided Exercise                | 6:35-7:05  | 30 min   | Attendees pick an archetype and apply the playbook template to their own business problem                                                                                   |
| Wrap & Resources               | 7:05-7:10  | 5 min    | Key takeaways, QR codes on screen, transition to open time                                                                                                                  |
| Open Time & Networking         | 7:10-8:00+ | 50+ min  | Volunteer shares ("who wants to show what they built?"), 1-on-1 help, install assistance, networking                                                                        |

**Design principle:** 1h25m of structured programming (5:45-7:10), then 50+ minutes of unstructured open time for networking, 1-on-1 help, and organic sharing. The open time is where much of the real value happens for attendees — individual questions, Kyle helping with specific problems, connections forming.

---

## Welcome & Framing (5:45-6:00)

### Audience Pulse Check (first 2-3 minutes)

Open with three questions to calibrate the session:

1. "How many of you watched the prerequisite video and got a tool installed?" (show of hands)
2. "How many are using Claude Code? OpenCode? Something else like Cursor or Copilot?"
3. "How many have never used an AI coding tool before today?"

**What this tells Kyle:**
- How much setup help is needed during the exercise
- The tool distribution in the room (useful when walking the room later)
- An icebreaker that gets hands in the air early

**No-tool fallback:** If people don't have a tool installed, project the quick install commands on screen (same ones from the prework video) and point them to the companion repo README. They can install during the framework overview or the first part of the demo. The install is two terminal commands — it can happen in the background.

### Context Engineering Overview (remaining time)

**Goal:** Give attendees the mental map before the demo shows the territory.

- "Why does AI feel like magic sometimes and useless other times? The difference is context."
- Show the 4 layers visually — one slide or diagram with a one-sentence definition each:
  1. **Instructions** — Defining the AI's role, expertise, rules, and standards
  2. **Structure** — Organizing your project so the AI can navigate it
  3. **Tools** — Connecting the AI to your actual work systems (CLIs, APIs, MCP servers)
  4. **Workflows** — Custom commands and repeatable patterns that encode your processes
- "You're about to see all 4 in action, and then you'll apply them yourself."

This is a 5-minute high-level pass — not a deep dive. The demo brings each layer to life concretely.

### Real-World Proof Points

During the framing or woven naturally into the session, Kyle can reference three projects he built entirely with AI to demonstrate the breadth of what's possible:

| Project | What It Is | Use Case | Tech |
|---------|-----------|----------|------|
| [curiousquestions.life](https://curiousquestions.life) | Weekly SMS service sending thought-provoking questions | Consumer product — AI walked Kyle through every step of building it | Next.js, Supabase, Twilio, Vercel |
| [kclabs.ai](https://kclabs.ai) | Professional consultancy website with portfolio, courses, contact forms | Business website — built entirely with AI | Next.js, Tailwind, Framer Motion, Vercel |
| Video production pipeline | 8 custom AI skills automating the full YouTube workflow (brainstorm → research → script → code setup → description → marketing) | Workflow automation — not an app, but a repeatable process | Claude Code custom skills, MCP integrations, Google Drive |

**Why this matters for the workshop:** These three projects span apps, websites, and workflow automation — completely different domains, all built with the same Context Engineering approach being taught. It directly answers "what can I actually build with this?" and shows that the framework applies far beyond coding.

The QR codes for curiousquestions.life and kclabs.ai are included in the README so attendees can see the finished products.

---

## Live Demo — Audience-Polled (6:00-6:35)

**Concept:** Instead of a pre-scripted demo, Kyle polls the room on which business problem to solve live. This makes the demo dynamic, proves the framework works on real problems (not rehearsed tricks), and gives the audience ownership.

### The Poll

Project 4 archetype options + a wild card on screen. Audience votes by show of hands or applause:

1. **Automate a recurring report** — "Every Monday I manually pull numbers from a spreadsheet and email a summary"
2. **Triage incoming requests** — "I have 40 unread support tickets and need to categorize by urgency and route them"
3. **Build a simple app or tool** — "I need an internal calculator, form, or dashboard for my team"
4. **Build or optimize a website** — "I need to create a landing page or improve my existing site's performance"
5. **Wild card — suggest your own** — Someone describes their real problem in 30 seconds

### Demo Flow

1. **Audience votes** on which archetype (or wild card)
2. **Kyle asks for specifics** — "We're doing [winning archetype]. Who has a real version of this? What data, what format, who gets it?"
3. **Build the Context Engineering playbook live:**
   - Define the AI's role for this task (Instructions layer)
   - Describe the problem with the audience's details (Structure layer)
   - Connect to a real tool — MCP server or CLI (Tools layer)
   - Show how this becomes a repeatable pattern (Workflows layer)
4. **Run it live** — AI processes the problem and produces output
5. **Refine with follow-up prompts** — show iteration and human-in-the-loop refinement
6. **Call out the framework** — "Notice what just happened? We used all 4 layers."

### Guaranteed Tool Connection

**Every archetype has at least one mapped tool connection** so the "Tools" layer is always demonstrated live, not just discussed:

| Archetype | Primary Tool Connection | Backup |
|-----------|------------------------|--------|
| Automate a recurring report | Google Sheets MCP (pull data live) | bq CLI (BigQuery query) |
| Triage incoming requests | Atlassian/Jira MCP (read tickets) | Slack MCP |
| Build a simple app or tool | GitHub CLI + filesystem | Vercel CLI for deploy |
| Build or optimize a website | GitHub CLI + Vercel CLI | filesystem + localhost |
| Wild card | Kyle picks the most relevant available tool | filesystem fallback |

**Prep required:** Kyle needs lightweight materials for each archetype — a sample scenario, a few context bullet points, and a tested tool connection. Not a full scripted demo, but enough to have a starting point if the audience details are thin.

### Backup Demo

If the audience-polled demo goes sideways (tool connection fails, wild card is too complex, time is running short), **Archetype 1 (Automate a recurring report / Google Sheets)** is the designated fallback. It's the most universally relatable, has the strongest "wow moment" (AI reading a live Google Sheet), and will be the most rehearsed.

### Why Not "Draft Communications"?

The exercise archetype "Draft communications from raw info" is excluded from the demo poll because its output is just text — less visually compelling on stage. It works well as an exercise option but doesn't demo as strongly.

---

## Guided Exercise (6:35-7:05)

**Goal:** Every attendee applies the Context Engineering framework to their own business problem.

### The 5 Archetypes

Attendees pick the archetype closest to their work. Each is a business problem pattern with example tools — attendees mentally map it to whatever they actually use.

| # | Archetype | Example Problem | Example Tools |
|---|-----------|----------------|---------------|
| 1 | **Automate a recurring report** | "Every Monday I manually pull sales numbers and email a summary to leadership" | Google Sheets, SQL/BigQuery, Excel, CLI data tools |
| 2 | **Triage incoming requests** | "I have 40 unread support tickets and need to categorize by urgency and route to the right team" | Jira, Linear, HubSpot, Slack, email |
| 3 | **Build a simple app or tool** | "I need an internal calculator, intake form, or dashboard for my team" | Claude Code, Next.js, Python, Vercel, GitHub CLI |
| 4 | **Draft communications from raw info** | "Turn my meeting notes and project data into a polished stakeholder update email" | Notion, Google Docs, Slack, email CLI |
| 5 | **Build or optimize a website** | "I need to create a landing page for my product, or improve the performance of my existing site" | Next.js, HTML/CSS, Vercel, GitHub CLI |

### The Playbook Template

Provided as a markdown file in the companion repo. Attendees work through these steps:

0. **Pick your scenario** — Choose the archetype closest to your work (or bring your own)
1. **Define your AI assistant's role** — "You are a [role] who specializes in [domain]. You help with [tasks]." (mirrors CLAUDE.md role section)
2. **Describe your business problem** — What's the input? What does "done" look like? What constraints matter?
3. **Give it context** — What files, data, examples, or rules does the AI need? (This is the "aha" moment)
4. **Run it** — Paste context + problem into their AI tool and see what happens. Iterate.

### Exercise Format

- **Prompt-based, no auth required** — Attendees describe their scenario and apply the framework. No tool installation or API authentication needed during the exercise itself.
- **Tool installed:** Work through all steps live
- **No tool installed:** Complete steps 0-3 (the most valuable thinking exercise), run it after the workshop or during open time with Kyle's help
- **Advanced users:** Extend with a real tool connection (MCP or CLI) during open time

### Facilitation

- Project the 5 archetypes on screen for selection
- Walk the room and help individuals
- Checkpoint at ~15 minutes — quick pulse check to keep momentum
- The archetype gives Kyle a shared vocabulary for helping: "Oh you picked #2, triage? Here's how I'd structure the context for that..."

### Connection to Prework

The prerequisite video already asks attendees to think about: "What task do you do repeatedly? What report do you wish someone else could draft? What tool integration would save you time?" Many attendees will arrive with a problem already in mind and will recognize it in the archetypes.

---

## Wrap & Resources (7:05-7:10)

Quick 5-minute close:

- Key takeaways: "The framework is 4 layers — Instructions, Structure, Tools, Workflows. You now have a playbook template to apply this to any problem."
- QR codes on screen: all 6 (LinkedIn, YouTube, repo, Saturday hike, kclabs.ai, curiousquestions.life)
- **Stay connected:** "Subscribe on YouTube, connect on LinkedIn, DM me if you want to keep going with this."
- **Saturday hike plug:** "If you want to keep the conversation going, I'm hosting a morning hike and coffee this Saturday at Phoenix Mountain Preserve — QR code is on screen."
- **Zoom:** A Zoom link will be shared for remote attendees who want to join the session live.
- Transition: "We're moving into open time now. Who wants to share what they built? I'll also be walking around to help anyone who wants to go deeper."

---

## Open Time & Networking (7:10-8:00+)

**Unstructured by design.** This is where much of the real value happens:

- **Volunteer shares** — "Who wants to show what they built?" as the first organic activity. No time limit, no formal structure.
- **1-on-1 help** — Kyle helps individuals with their specific problems, tool setup, or extending their exercise with real tool connections
- **Install assistance** — Help anyone who still needs to get a tool working
- **Networking** — Attendees connect with each other
- **Remote participants** — Zoom attendees can ask questions and share their work

---

## Recording

This session will be recorded and published on the [KC Labs AI YouTube channel](https://www.youtube.com/@kylechalmersdataai). All companion materials in the repo should be public-facing and contain no sensitive information.

---

## Companion Materials

### Repository Location

`videos/az_tech_week_workshop/` in this repo (`data-ai-tickets-template`)

**Rationale:** This repo IS the Context Engineering reference implementation. It has the CLAUDE.md, folder structure, custom commands, and the January meetup materials. Attendees who star/clone it get the playbook template AND a working example of everything taught.

### README.md as Presentation Material

**The README.md IS the main presentation material** — not a separate slide deck. It follows the January meetup README pattern (`videos/az_emerging_tech_meetup/README.md`):

- Centered header with badges for key tools
- Event details table (date, venue, presenter)
- QR codes embedded inline (displayed during presentation)
- ASCII flow diagrams for session overview and demo flows
- Collapsible `<details>` blocks for prompts (click to expand)
- Side-by-side tables for dataset details and goals
- Tools demonstrated section with badge icons
- Key takeaways in a 3-column table
- Resources and video links section

Kyle presents by scrolling through the README on screen — it serves as both the live presentation and the post-event reference for attendees who clone the repo.

### QR Codes (6 total)

| QR Code | URL | Label |
|---------|-----|-------|
| LinkedIn | linkedin.com/in/kylechalmers | Connect |
| YouTube | youtube.com/@kylechalmersdataai | Subscribe |
| GitHub Repo | github.com/kyle-chalmers/data-ai-tickets-template | Star |
| Sat. Hike & Coffee | partiful.com/e/vMiPKyrTML8yf8Gnf618 | RSVP — Sat. April 11 |
| KC Labs AI | kclabs.ai | Website |
| Curious Questions | curiousquestions.life | Try It — Built with AI |

**Curious Questions** is Kyle's side project, built entirely with AI coding tools — the AI walked him through every step of building it. It's a tangible proof point for the workshop's message: you don't need to be a developer to build real products with these tools. Mention it during the session as a real example of what Context Engineering + AI can produce. Include in the QR codes section with a note like "Built entirely with AI."

The Saturday event is a **morning hike, networking & coffee** (April 11, 8:30-11:00 AM, Phoenix Mountain Preserve) — a casual community event Kyle is hosting during AZ Tech Week. Include in the README as a "More from AZ Tech Week" section.

### Folder Structure

Mirrors the January meetup pattern (`videos/az_emerging_tech_meetup/`):

```
videos/az_tech_week_workshop/
├── README.md                    # MAIN PRESENTATION MATERIAL — workshop flow, demos, QR codes
├── PRESENTATION_GUIDE.md        # Speaker notes, timing cues, facilitation tips (not shown on screen)
├── playbook_template.md         # The 5-archetype exercise template
├── datasets/                    # Public demo datasets (committed to repo)
│   ├── coffee_shop_sales.csv    # Maven Analytics — archetype 1
│   ├── support_tickets.csv      # Kaggle — archetype 2
│   └── README.md                # Dataset descriptions, sources, and licenses
├── linkedin_data/               # GITIGNORED — Kyle's personal LinkedIn export
│   ├── Connections.csv           # 3,723 connections — network analysis
│   ├── messages.csv              # Inbox — triage/categorization demo
│   ├── Endorsement_Received_Info.csv  # 324 endorsements — skills analysis
│   ├── Learning.csv              # 221 courses — learning summary
│   ├── Company Follows.csv       # 221 companies — industry interests
│   ├── Invitations.csv           # 205 invitations — networking patterns
│   └── Rich_Media.csv            # 57 posts — posting pattern analysis
├── demo_prompts/                # Pre-built prompts for tool setup & demo execution
│   ├── tool_setup_prompts.md    # Prompts to install/configure each MCP & CLI tool
│   └── archetype_prompts.md     # Starter prompts for each demo archetype
├── qr_codes/                    # 6 QR codes
│   ├── linkedin_qr.png
│   ├── youtube_qr.png
│   ├── repo_qr.png
│   ├── saturday_hike_qr.png
│   ├── kclabs_qr.png
│   └── curious_questions_qr.png
└── images/                      # Diagrams (framework overview, architecture)
```

**IMPORTANT:** `linkedin_data/` is gitignored — contains personal data (names, messages, connections). Never committed to the public repo. Added to `.gitignore` during folder setup.

### Demo Datasets

Two types of datasets: public prepared datasets (committed to repo) and personal LinkedIn data (gitignored, local only).

#### Public Datasets (in `datasets/`, committed to repo)

| Archetype | Dataset | Rows | Source | License | Why |
|-----------|---------|------|--------|---------|-----|
| 1. Automate a report | Coffee Shop Sales | 149K | [Maven Analytics](https://mavenanalytics.io/data-playground/coffee-shop-sales) | Free | NYC coffee shop transactions — universally relatable, great for weekly summary reports |
| 2. Triage requests | Customer Support Tickets | ~8.5K | [Kaggle](https://www.kaggle.com/datasets/suraj520/customer-support-ticket-dataset) | CC0 | Tech support tickets with free-text descriptions, priority, status — perfect for AI categorization |
| 3. Build an app | N/A | — | — | — | Code-focused, AI generates from description |
| 5. Build a website | N/A | — | — | — | Code-focused, start from template |

#### Personal LinkedIn Data (in `linkedin_data/`, gitignored)

Kyle's LinkedIn export adds a personal, relatable dimension — especially for archetypes 1, 2, and 4:

| File | Rows | Workshop Use |
|------|------|-------------|
| **Connections.csv** | 3,723 | Archetype 1: network growth over time, industry clusters, company distribution. Load into Google Sheets for live MCP demo. |
| **messages.csv** | Large | Archetype 2: triage LinkedIn inbox — categorize by type, identify high-priority messages |
| **Endorsement_Received_Info.csv** | 324 | Archetype 1: "What skills does my network associate with me?" — skill trends and clusters |
| **Learning.csv** | 221 | Archetype 1 or 4: "Summarize my learning and recommend what's next" |
| **Company Follows.csv** | 221 | Archetype 1: industry interest analysis — supplementary to connections |
| **Invitations.csv** | 205 | Archetype 1: networking activity patterns — outbound vs inbound |
| **Rich_Media.csv** | 57 | Archetype 1: posting patterns and content analysis |

**Why LinkedIn data is powerful for this workshop:**
- Everyone in the room HAS LinkedIn — they can download their own export and replicate this at home
- It's personal and immediately relatable — "this is YOUR data"
- Multiple CSVs can be combined for richer analysis (connections + endorsements + company follows)
- It demonstrates "your data + AI" — not an abstract dataset
- During the exercise: "If you want to try this with your own data, you can request your LinkedIn export — it takes about 24 hours, but here's what it looks like with mine."

**Privacy note:** Kyle can demo his own data live (he's the presenter). Mention to attendees that they should be thoughtful about sharing their own personal data exports.

### Pre-Built Prompts

Ready-to-paste prompts so Kyle can run tool setup and demos quickly without writing from scratch:

**Tool Setup Prompts** (`demo_prompts/tool_setup_prompts.md`):
- Google Sheets MCP: install, configure, verify connection
- Atlassian/Jira MCP: install, authenticate, verify connection
- BigQuery CLI (bq): verify auth, test query
- DuckDB CLI: install, verify with a local CSV
- GitHub CLI: verify auth
- Vercel CLI: verify auth, test deploy

**Archetype Demo Prompts** (`demo_prompts/archetype_prompts.md`):
- One starter prompt per archetype that applies the Context Engineering framework
- Each prompt defines the role, describes the problem, references the dataset, and includes a tool connection step
- Designed to be adapted live based on audience input — not rigid scripts

---

## Tool Verification

Before the workshop, every tool connection must be verified working end-to-end:

| Tool | Type | Status | Verification |
|------|------|--------|-------------|
| Google Sheets MCP | MCP Server | Needs setup | Read a sheet, return data |
| Atlassian/Jira MCP | MCP Server | Setup docs exist | Read tickets from a test project |
| BigQuery CLI (bq) | CLI | Needs verification | Run a query, return results |
| DuckDB CLI | CLI | Needs verification | Query a local CSV, return results |
| GitHub CLI (gh) | CLI | Installed | Create a repo, push code |
| Vercel CLI | CLI | Installed | Deploy a project, return URL |

**Pre-built prompts for tool setup** will be created so Kyle can run each setup through Claude Code with a single paste — install, configure, and verify in one shot.

---

## Prerequisite Video

**Published:** [Get Set Up with AI Coding Tools in Under 10 Minutes](https://youtube.com/watch?v=C0HtKPrUhGk)
**Companion folder:** `videos/ai_coding_tools_setup/`

**What the video covers (relevant to workshop):**
- Install Claude Code (paid) and OpenCode (free)
- GitHub & Git setup
- Brief Context Engineering introduction
- "Think about the business problem to bring" — primes attendees for archetype selection

---

## Relationship to January Meetup

The January event (`videos/az_emerging_tech_meetup/`) was a 60-minute demo-focused presentation for a data-oriented audience. This workshop differs:

| Aspect      | January Meetup                                | April Workshop                                                  |
| ----------- | --------------------------------------------- | --------------------------------------------------------------- |
| Format      | Presentation + scripted demos                 | Framework teach + audience-driven demo + hands-on exercise      |
| Duration    | 60 min                                        | 2.5 hours (1h25m structured + 50m+ open)                       |
| Audience    | Data professionals                            | Mixed (practitioners, founders, leaders, students)              |
| Takeaway    | "This is cool"                                | Playbook template + started project                             |
| Depth       | Context Engineering intro + 2 technical demos | Full framework + live audience-polled demo + personalized exercise |
| Tools shown | Claude Code + Snowflake/AWS/Databricks/Jira   | Tool-agnostic framework + audience-chosen tool integration      |
| Demo style  | Pre-built, rehearsed                          | Audience-polled, built live                                     |

---

## Open Items

### Folder & Materials Setup
- Create `videos/az_tech_week_workshop/` folder structure (mirror January meetup pattern)
- Create `README.md` with event overview and setup instructions
- Create `playbook_template.md` with 5 archetypes
- Create `PRESENTATION_GUIDE.md` with speaker flow and timing
- Create/update QR codes

### Demo Datasets
- Generate synthetic customer feedback dataset (~50 rows) and load into a Google Sheet
- Generate synthetic support tickets dataset (~40 rows)
- Generate synthetic sales data dataset (~200 rows)
- Load datasets into appropriate tools (Google Sheet, Jira test project, BigQuery)

### Tool Setup & Verification
- Set up and verify Google Sheets MCP connection
- Set up and verify Atlassian/Jira MCP connection
- Verify BigQuery CLI (bq) auth and test query
- Verify DuckDB CLI install and local CSV query
- Verify GitHub CLI auth
- Verify Vercel CLI auth and test deploy

### Pre-Built Prompts
- Write tool setup prompts (one per tool — install, configure, verify)
- Write archetype demo prompts (one per archetype — role, problem, context, tool connection)
- Test each prompt end-to-end in Claude Code

### Workshop Prep
- Build framework overview slide or diagram (4 layers visual)
- Decide on audience polling mechanism (show of hands vs. live poll tool)
- End-to-end rehearsal: run through each archetype cold to verify Kyle can handle any poll result
