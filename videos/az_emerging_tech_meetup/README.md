<div align="center">

# The AI-Empowered Data Revolution

### Hands-On Demos to 10X Your Data Workflows

[![Claude Code](https://img.shields.io/badge/Claude_Code-AI_Assistant-blueviolet?style=for-the-badge&logo=anthropic)](https://claude.ai/download)
[![Snowflake](https://img.shields.io/badge/Snowflake-Data_Warehouse-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![AWS](https://img.shields.io/badge/AWS-S3_Storage-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)](https://aws.amazon.com/)
[![Databricks](https://img.shields.io/badge/Databricks-Jobs-FF3621?style=for-the-badge&logo=databricks&logoColor=white)](https://www.databricks.com/)

---

| 📅 **Date** | 📍 **Venue** | 👤 **Presenter** |
|:---:|:---:|:---:|
| Wed, Jan 21, 2026 | 1951@SkySong, Scottsdale | Kyle Chalmers |
| 6:00 - 7:00 PM MST | Room 151 | Arizona AI & Emerging Tech Meetup |

---

| 🔗 **LinkedIn** | 📺 **YouTube** | 💻 **GitHub Repo** |
|:---:|:---:|:---:|
| <img src="./qr_codes/linkedin_qr.png" width="150"> | <img src="./qr_codes/youtube_qr.png" width="150"> | <img src="./qr_codes/repo_qr.png" width="150"> |
| [Connect](https://www.linkedin.com/in/kylechalmers/) | [Subscribe](https://www.youtube.com/channel/UCkRi29nXFxNBuPhjseoB6AQ) | [Star ⭐](https://github.com/kyle-chalmers/data-ai-tickets-template) |

</div>

---

## Session Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SESSION OVERVIEW (60 min)                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌───────────┐   ┌─────────────┐   ┌──────────────┐   ┌──────────────┐      │
│  │   Intro   │──▶│  Foundation │──▶│   Demo 1     │──▶│   Demo 2     │      │
│  │  (3 min)  │   │  (10 min)   │   │  (12 min)    │   │  (12 min)    │      │
│  └───────────┘   └─────────────┘   └──────────────┘   └──────────────┘      │
│                                                                        │    │
│                  Context          Jira → S3 →       Jira → Research →  │    │
│                  Engineering      Snowflake         Databricks Job     │    │
│                                                                        │    │
│         ┌──────────────────────────────────────────────────────────────┘    │
│         ▼                                                                   │
│  ┌───────────┐   ┌─────────────────────────────────────────────────────┐    │
│  │  Wrap-up  │──▶│                    Q&A (20 min)                     │    │
│  │  (3 min)  │   │              Open questions from audience           │    │
│  └───────────┘   └─────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Foundation: Context Engineering

> [!IMPORTANT]
> **The Key Insight:** Claude Code is only as good as the context you give it.

| Component | Purpose |
|:----------|:--------|
| 📁 **Folder Structure** | Standardized `tickets/` organization teaches AI your workflow patterns |
| 📄 **CLAUDE.md** | 700+ lines of instructions defining role, permissions, tools, and standards |
| ⚡ **Custom Commands** | Workflow shortcuts like <kbd>/initiate-request</kbd> <kbd>/save-work</kbd> <kbd>/review-work</kbd> |

---

## Demo 1: Complete Data Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    DEMO 1: Jira → S3 → Snowflake                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    📝 Jira           📥 Download        ☁️ S3             ❄️ Snowflake        │
│   Create    ──────▶   CSV Data   ──────▶  Upload   ──────▶  Load &          │
│   Ticket             (50K rows)                            Analyze          │
│                                                                 │           │
│                                                                 ▼           │
│                                              📊 Results      ✅ Close        │
│                                              Top emitters,   Ticket         │
│                                              US trends                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

<table>
<tr>
<td width="50%">

**📊 Dataset Details**

| Attribute | Value |
|:----------|:------|
| Source | Our World in Data |
| Time Range | 1750 - 2024 |
| Countries | 255 |
| Columns | 79 |
| License | CC BY 4.0 |

</td>
<td width="50%">

**🎯 Analysis Goals**

- [x] Top 10 emitting countries (2024)
- [x] US emissions trend since 2000
- [x] Full audit trail in Jira

</td>
</tr>
</table>

<details>
<summary><b>📋 Demo 1 Prompt</b> <sup>(click to expand)</sup></summary>

```text
I need help with a data analysis project. Here's what I'm thinking:

We should analyze global CO2 emissions to understand which countries are the biggest emitters
and how that's changed over time. I found a dataset from Our World in Data that has emissions
by country from 1750 to 2024.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Download the data from https://owid-public.owid.io/data/co2/owid-co2-data.csv
3. Upload it to our S3 bucket at kclabs-athena-demo-2026
4. Load it into Snowflake so we can query it
5. Find the top 10 emitting countries in 2024
6. Show how US emissions have changed since 2000

Once we have results, mark the ticket as done.
```

</details>

---

## Demo 2: Databricks Infrastructure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                 DEMO 2: Jira → Research → Databricks Job                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│    📝 Jira          🔍 Research         🐍 Python          ⚡ Databricks      │
│   Create    ──────▶   Climate    ──────▶   Job     ──────▶   Deploy &       │
│   Ticket              APIs              Script             Test             │
│                         │                                       │           │
│                         ▼                                       ▼           │
│                    Open-Meteo                              ✅ Close         │
│                    (Free, No Auth)                         Ticket           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

<table>
<tr>
<td width="50%">

**⚙️ Job Configuration**

| Setting | Value |
|:--------|:------|
| Schedule | 3rd of each month |
| Cities | 10 Arizona locations |
| Data | Previous month's weather |
| API | Open-Meteo (free) |

</td>
<td width="50%">

**🎯 Deliverables**

- [x] Production Python script
- [x] Scheduled Databricks job
- [x] Automated monthly execution
- [x] Full documentation in Jira

</td>
</tr>
</table>

<details>
<summary><b>📋 Demo 2 Prompt</b> <sup>(click to expand)</sup></summary>

```text
I need to set up automated climate data collection for Arizona. Here's what I'm thinking:

Our team wants to track weather patterns across Arizona cities for climate analysis.
We need a scheduled job that pulls weather data monthly and stores it somewhere we can query.

Can you help me:
1. Create a Jira ticket to track this work (use the KAN project)
2. Research what free climate data APIs are available
3. Create a Databricks job that fetches monthly weather data for Arizona cities
4. The job should run on the 3rd of each month and pull the previous month's data
5. Deploy it to our Databricks workspace
6. Run a test to make sure it works
7. Close the ticket with a summary of what was built

I want to see your reasoning on what API to use and how to handle scheduling.
```

</details>

---

## Key Tools Demonstrated

<div align="center">

| Tool | Purpose | Command |
|:----:|:--------|:--------|
| ![Claude](https://img.shields.io/badge/-Claude_Code-blueviolet?style=flat-square) | AI-powered CLI assistant | <kbd>claude</kbd> |
| ![Snowflake](https://img.shields.io/badge/-Snowflake-29B5E8?style=flat-square) | Data warehouse queries | <kbd>snow sql -q "..."</kbd> |
| ![AWS](https://img.shields.io/badge/-AWS_S3-FF9900?style=flat-square) | Cloud storage operations | <kbd>aws s3 cp ...</kbd> |
| ![Databricks](https://img.shields.io/badge/-Databricks-FF3621?style=flat-square) | Job deployment | <kbd>databricks jobs create ...</kbd> |
| ![Jira](https://img.shields.io/badge/-Jira-0052CC?style=flat-square) | Ticket tracking | <kbd>acli jira workitem ...</kbd> |

</div>

---

## Three Takeaways

<table>
<tr>
<td width="33%" align="center">

### 1️⃣ Context is Everything

Claude Code is only as good as the context you give it. CLAUDE.md, folder structure, and documentation make AI effective.

</td>
<td width="33%" align="center">

### 2️⃣ Tools Become Seamless

Natural language becomes your universal API. Orchestrate Jira, S3, Snowflake, and Databricks without memorizing CLI syntax.

</td>
<td width="33%" align="center">

### 3️⃣ More Thinking, Less Typing

Your role shifts from execution to oversight. AI handles mechanical work while you focus on critical thinking and QC.

</td>
</tr>
</table>

---

## Get Started

<div align="center">

| | Resource | Link |
|:--:|:---------|:-----|
| 🤖 | **Claude Code** | [claude.ai/download](https://claude.ai/download) |
| 📦 | **This Repository** | [github.com/kyle-chalmers/data-ai-tickets-template](https://github.com/kyle-chalmers/data-ai-tickets-template) |
| 🌍 | **Our World in Data** | [github.com/owid/co2-data](https://github.com/owid/co2-data) |
| 🌤️ | **Open-Meteo API** | [open-meteo.com/en/docs/historical-weather-api](https://open-meteo.com/en/docs/historical-weather-api) |
| 📚 | **Databricks CLI Docs** | [docs.databricks.com/dev-tools/cli](https://docs.databricks.com/dev-tools/cli/) |

</div>

---

<div align="center">

## 📺 More From KC Labs AI

</div>

<details>
<summary><b>🎬 Video Tutorials</b> <sup>(click to expand)</sup></summary>

| Video | Description | |
|:------|:------------|:---:|
| **FUTURE PROOF Your Data Career with this Claude Code Deep Dive** | Complete guide to Claude Code for data teams | [▶️ Watch](https://www.youtube.com/watch?v=g4g4yBcBNuE) |
| **UPDATE to settings.json Chapter** | Settings.json updates from the Deep Dive | [▶️ Watch](https://youtu.be/WKt28ytMl3c) |
| **The AI Integration Every Data Professional Needs** | Using Claude Code with Snowflake | [▶️ Watch](https://www.youtube.com/watch?v=q1y7M5mZkkE) |
| **Claude Code Makes Databricks Easy** | Jobs, notebooks, SQL & Unity Catalog | [▶️ Watch](https://www.youtube.com/watch?v=5_q7j-k8DbM) |
| **Integrate Claude in Your Jira Workflow** | Jira/Confluence integration guide | [▶️ Watch](https://www.youtube.com/watch?v=WRvgMzYaIVo) |
| **Skip S3 and Athena in the AWS Console** | CLI + Claude Code for AWS data lakes | [▶️ Watch](https://www.youtube.com/watch?v=kCUTStWwErg) |
| **Use AI to Build Better Data Infrastructure** | Context Engineering with PRP Framework | [▶️ Watch](https://youtu.be/DUK39XqEVm0) |

</details>

---

<div align="center">

### Scan to Connect

| 🔗 **LinkedIn** | 📺 **YouTube** | 💻 **GitHub** |
|:---:|:---:|:---:|
| <img src="./qr_codes/linkedin_qr.png" width="150"> | <img src="./qr_codes/youtube_qr.png" width="150"> | <img src="./qr_codes/repo_qr.png" width="150"> |

---

*Thank you for attending! Questions? Find me after the session or connect on LinkedIn.*

<sub>Made with ❤️ and Claude Code</sub>

</div>
