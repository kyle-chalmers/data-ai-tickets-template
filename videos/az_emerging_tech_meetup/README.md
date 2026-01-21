# The AI-Empowered Data Revolution
## Hands-On Demos to 10X Your Data Workflows

---

|  |  |
|:---:|:---|
| **Event** | Arizona AI & Emerging Technology Meetup |
| **Date** | Wednesday, January 21, 2026 \| 6:00 PM - 7:00 PM MST |
| **Venue** | 1951@SkySong, 1475 N. Scottsdale Road, Room 151, Scottsdale, AZ |
| **Presenter** | Kyle Chalmers |

---

## Scan to Connect

| 🔗 **LinkedIn** | 📺 **YouTube** | 💻 **GitHub Repo** |
|:---:|:---:|:---:|
| ![LinkedIn](./qr_codes/linkedin_qr.png) | ![YouTube](./qr_codes/youtube_qr.png) | ![GitHub](./qr_codes/repo_qr.png) |
| [linkedin.com/in/kylechalmers](https://www.linkedin.com/in/kylechalmers/) | [KC Labs AI Channel](https://www.youtube.com/channel/UCkRi29nXFxNBuPhjseoB6AQ) | [data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template) |

---

## Session Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SESSION OVERVIEW (60 min)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────┐   ┌─────────────┐   ┌──────────────┐   ┌──────────────┐     │
│  │   Intro   │──▶│  Foundation │──▶│   Demo 1     │──▶│   Demo 2     │     │
│  │  (3 min)  │   │  (10 min)   │   │  (12 min)    │   │  (12 min)    │     │
│  └───────────┘   └─────────────┘   └──────────────┘   └──────────────┘     │
│                                                                        │    │
│                  Context          Jira → S3 →       Jira → Research →  │    │
│                  Engineering      Snowflake         Databricks Job     │    │
│                                                                        │    │
│         ┌──────────────────────────────────────────────────────────────┘    │
│         ▼                                                                   │
│  ┌───────────┐   ┌─────────────────────────────────────────────────────┐   │
│  │  Wrap-up  │──▶│                    Q&A (20 min)                     │   │
│  │  (3 min)  │   │              Open questions from audience           │   │
│  └───────────┘   └─────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Foundation: Context Engineering

> **The Key Insight:** Claude Code is only as good as the context you give it.

| Component | Purpose |
|-----------|---------|
| **Folder Structure** | Standardized `tickets/` organization teaches AI your workflow patterns |
| **CLAUDE.md** | 700+ lines of instructions defining role, permissions, tools, and standards |
| **Custom Commands** | Workflow shortcuts like `/initiate-request`, `/save-work`, `/review-work` |

---

## Demo 1: Complete Data Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DEMO 1: Jira → S3 → Snowflake                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    📝 Jira           📥 Download        ☁️ S3             ❄️ Snowflake     │
│   Create    ──────▶   CSV Data   ──────▶  Upload   ──────▶  Load &        │
│   Ticket             (50K rows)                            Analyze         │
│                                                                 │          │
│                                                                 ▼          │
│                                              📊 Results      ✅ Close      │
│                                              Top emitters,   Ticket        │
│                                              US trends                     │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Dataset: Our World in Data CO2 Emissions (1750-2024)                       │
│  Countries: 255  |  Columns: 79  |  License: CC BY 4.0                      │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Demo 1 Prompt

```text
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

---

## Demo 2: Databricks Infrastructure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 DEMO 2: Jira → Research → Databricks Job                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    📝 Jira          🔍 Research         🐍 Python          ⚡ Databricks   │
│   Create    ──────▶   Climate    ──────▶   Job     ──────▶   Deploy &     │
│   Ticket              APIs              Script             Test           │
│                         │                                       │          │
│                         ▼                                       ▼          │
│                    Open-Meteo                              ✅ Close        │
│                    (Free, No Auth)                         Ticket          │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  Output: Monthly scheduled job collecting Arizona weather data              │
│  Cities: 10 AZ cities  |  Schedule: 3rd of each month  |  Profile: bidev   │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Demo 2 Prompt

```text
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

---

## Key Tools Demonstrated

| Tool | Purpose | CLI Command |
|------|---------|-------------|
| **Claude Code** | AI-powered CLI assistant | `claude` |
| **Snowflake CLI** | Data warehouse queries | `snow sql -q "..."` |
| **AWS CLI** | S3 storage operations | `aws s3 cp ...` |
| **Databricks CLI** | Job deployment | `databricks jobs create ...` |
| **Jira CLI** | Ticket tracking | `acli jira workitem ...` |
| **Custom Commands** | Workflow automation | `/initiate-request`, `/save-work` |

---

## Three Takeaways

> ### 1. Context is Everything
> Claude Code is only as good as the context you give it. CLAUDE.md, folder structure, and documentation make AI effective.

> ### 2. Teach Once, Benefit Forever
> Custom commands and agents encode your best practices. Define your workflow once, every future analysis follows automatically.

> ### 3. Delegation, Not Automation
> This isn't replacing data professionals. It's delegating mechanical work so you can focus on understanding data and making decisions.

---

## Get Started

| Resource | Link |
|----------|------|
| **Claude Code** | [claude.ai/download](https://claude.ai/download) |
| **This Repository** | [github.com/kyle-chalmers/data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template) |
| **Our World in Data** | [github.com/owid/co2-data](https://github.com/owid/co2-data) |
| **Open-Meteo API** | [open-meteo.com/en/docs/historical-weather-api](https://open-meteo.com/en/docs/historical-weather-api) |
| **Databricks CLI Docs** | [docs.databricks.com/dev-tools/cli](https://docs.databricks.com/dev-tools/cli/) |

---

## Scan to Connect

| 🔗 **LinkedIn** | 📺 **YouTube** | 💻 **GitHub Repo** |
|:---:|:---:|:---:|
| ![LinkedIn](./qr_codes/linkedin_qr.png) | ![YouTube](./qr_codes/youtube_qr.png) | ![GitHub](./qr_codes/repo_qr.png) |
| [linkedin.com/in/kylechalmers](https://www.linkedin.com/in/kylechalmers/) | [KC Labs AI Channel](https://www.youtube.com/channel/UCkRi29nXFxNBuPhjseoB6AQ) | [data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template) |

---

## 📺 More From KC Labs AI

Explore detailed tutorials on each integration demonstrated today:

| Video | Description | Link |
|-------|-------------|:----:|
| **FUTURE PROOF Your Data Career with this Claude Code Deep Dive** | Complete guide to Claude Code for data teams - installation, CLAUDE.md, commands, agents | [Watch](https://www.youtube.com/watch?v=g4g4yBcBNuE) |
| **UPDATE to settings.json Chapter** | Settings.json updates from the Claude Code Deep Dive | [Watch](https://youtu.be/WKt28ytMl3c) |
| **The AI Integration Every Data Professional Needs (Snowflake Workflow)** | Using Claude Code with Snowflake for data analysis | [Watch](https://www.youtube.com/watch?v=q1y7M5mZkkE) |
| **Claude Code Makes Databricks Easy** | Jobs, notebooks, SQL & Unity Catalog via CLI | [Watch](https://www.youtube.com/watch?v=5_q7j-k8DbM) |
| **How to SUCCESSFULLY Integrate Claude in Your Team's Jira Ticket Workflow** | Jira/Confluence integration guide | [Watch](https://www.youtube.com/watch?v=WRvgMzYaIVo) |
| **Skip S3 and Athena in the AWS Console** | CLI + Claude Code Workflow for AWS data lakes | [Watch](https://www.youtube.com/watch?v=kCUTStWwErg) |
| **Stop Waiting: Use AI to Build Better Data Infrastructure (PRP Framework)** | Context Engineering framework for Snowflake data objects | [Watch](https://youtu.be/DUK39XqEVm0) |

---

*Thank you for attending! Questions? Find me after the session or connect on LinkedIn.*
