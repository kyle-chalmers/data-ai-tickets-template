# Getting Started with AI for Data Analysis for Free

> **YouTube:** [Getting Started with AI for Data Analysis for Free](https://youtu.be/bWEs8Umnrwo)

Complete guide for setting up a free AI-powered data analysis environment from scratch. Uses OpenCode (free AI coding agent), BigQuery Sandbox (free cloud data warehouse), and Cursor/Windsurf (free AI IDE).

---

## The Value Proposition

AI-assisted data analysis is becoming the standard. But most tools cost $20-200/month. This video shows you can get started with a complete setup for $0:

- **Free AI coding agent** (OpenCode) writes SQL and Python for you
- **Free cloud database** (BigQuery Sandbox) with millions of rows of public data already loaded
- **Free AI IDE** (Cursor or Windsurf) with built-in code assistance
- **No credit card required** for any of it

### Video Goals

Enable viewers to:
1. **Install a free AI coding agent** (OpenCode) and connect it to free models via OpenRouter
2. **Set up a local development environment** (GitHub, Git, Cursor/Windsurf)
3. **Connect AI to BigQuery** using gcloud CLI authentication (the step nobody else teaches)
4. **Run AI-assisted data analysis** against real public datasets
5. **Understand the universal pattern** (install CLI, authenticate, AI queries) that works for any cloud

---

## Key Terms / Glossary

| Term | Definition |
|------|------------|
| **OpenCode** | A free, open-source AI coding agent that runs in your terminal. It can write code, run commands, and help you build projects. 95K+ GitHub stars. |
| **BigQuery** | Google's cloud data warehouse. A giant database in the cloud where you can store and query massive amounts of data using SQL. |
| **BigQuery Sandbox** | The free tier of BigQuery. 10 GB storage, 1 TB of queries per month. No credit card needed. |
| **gcloud CLI** | Google's command-line tool for interacting with Google Cloud services. Free to install. |
| **Application Default Credentials (ADC)** | A way for tools on your computer to automatically authenticate to Google Cloud. Set it up once and everything just works. |
| **OpenRouter** | A service that gives you access to many AI models through one API. 29 free models as of March 2026. |
| **AGENTS.md** | A file in your project that teaches AI assistants how to work with your code. Like an onboarding doc for your AI co-pilot. |
| **SQL** | Structured Query Language. The standard language for querying databases. |
| **bq** | BigQuery's command-line tool, bundled with the gcloud SDK. Query BigQuery directly from the terminal. |

---

## Prerequisites

- A computer (Mac, Windows, or Linux)
- An internet connection
- A Google account (for BigQuery Sandbox)
- A GitHub account (created during the video if needed)

No credit card required. No paid subscriptions. No prior experience necessary.

---

## Quick Start / Setup

### 1. Install a Free AI IDE

Download one of these (both are free VS Code forks with built-in AI):
- **Cursor**: https://cursor.com
- **Windsurf**: https://windsurf.com

### 2. Install OpenCode (Free AI Coding Agent)

Open the terminal inside your IDE and run:

```bash
curl -fsSL https://opencode.ai/install | bash
```

Alternatives: `brew install anomalyco/tap/opencode` (Mac), `choco install opencode` (Windows)

### 3. Connect OpenCode to Free Models

1. Create a free account at https://openrouter.ai (no credit card)
2. Go to Settings > Keys and create an API key
3. Configure OpenCode with the key
4. Use model: `openrouter/free` (auto-selects available model) or `qwen/qwen3-coder:free`

### 4. Set Up GitHub and Git

```bash
# Install Git (if not already installed)
# Ask OpenCode: "How do I install Git on my machine?"

git --version  # Confirm installation

# Create a repo on GitHub, then clone it:
git clone https://github.com/YOUR_USERNAME/free-data-analysis.git
cd free-data-analysis
```

### 5. Create an AGENTS.md

Ask OpenCode: "Create an AGENTS.md file for this project. It is a data analysis project using BigQuery and Python."

See [example AGENTS.md](./example_workflow/AGENTS.md) in this folder.

### 6. Install gcloud CLI and Authenticate

```bash
# Install gcloud SDK (includes bq tool)
# Mac: brew install google-cloud-sdk
# All platforms: https://cloud.google.com/sdk/docs/install

gcloud --version  # Confirm installation

# Authenticate (opens browser)
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID
```

### 7. Query BigQuery (Instant Test)

```bash
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) as total_questions
   FROM `bigquery-public-data.stackoverflow.posts_questions`'
```

### 8. Level Up to Python

```bash
# Install Python if needed: https://python.org
pip install google-cloud-bigquery
```

Then ask OpenCode to write analysis scripts for you.

---

## Free Tools Referenced

### AI Coding Agents
| Tool | Cost | Link |
|------|------|------|
| OpenCode | Free (open source, 95K+ GitHub stars) | https://opencode.ai |
| GitHub Copilot Free | Free (2,000 completions/month) | https://github.com/features/copilot/plans |
| Aider | Free (open source, 39K+ GitHub stars) | https://aider.chat |
| Ollama | Free (run models locally, 8-16 GB RAM) | https://ollama.com |

### AI IDEs
| Tool | Free Tier | Link |
|------|-----------|------|
| Cursor | Limited completions + agent requests | https://cursor.com |
| Windsurf | 25 credits/month + unlimited autocomplete | https://windsurf.com |
| GitHub Codespaces | 60 hrs/month, runs in browser | https://github.com/features/codespaces |

### Free AI Models
| Provider | Free Tier | Link |
|----------|-----------|------|
| OpenRouter | 29 free models, 50 req/day, no credit card | https://openrouter.ai/collections/free-models |
| Ollama | Unlimited (local, offline capable) | https://ollama.com |

### Free Databases (Permanent)
| Database | Free Tier | Link |
|----------|-----------|------|
| BigQuery Sandbox | 10 GB + 1 TB queries/month* | https://cloud.google.com/bigquery/pricing |
| Databricks Free Edition | Serverless SQL + Python, Genie AI | https://www.databricks.com/learn/free-edition |
| Azure SQL Database | 32 GB, always free | https://learn.microsoft.com/en-us/azure/azure-sql/database/free-offer |
| DuckDB | Unlimited (local) | https://duckdb.org |
| MotherDuck | 10 GB + 10 hrs/month | https://motherduck.com/product/pricing/ |
| Supabase | 500 MB PostgreSQL | https://supabase.com/pricing |
| Neon | 0.5 GB + 100 compute hrs/month | https://neon.com/pricing |
| Google Sheets | 15 GB shared across Drive | https://sheets.google.com |

*BigQuery Sandbox tables expire after 60 days. Enable billing (free tier still applies) to remove this limit.

### Free Databases (Trials)
| Database | Credits | Duration | Link |
|----------|---------|----------|------|
| Snowflake | $400 | 30 days | https://docs.snowflake.com/en/user-guide/admin-trial-account |
| AWS Redshift Serverless | $300 | 90 days | https://aws.amazon.com/redshift/pricing/ |

### Paid Options (What Kyle Uses)
| Tool | Cost | Link |
|------|------|------|
| Claude Code | $20-200/month | https://claude.com/pricing |
| Cursor Pro | $20/month | https://cursor.com/pricing |
| Windsurf Pro | $15/month | https://windsurf.com/pricing |

---

## The Universal Connection Pattern

Every cloud follows the same three steps:

```
1. Install the CLI
2. Authenticate
3. AI queries the database
```

| Cloud | CLI | Auth Command | Database |
|-------|-----|-------------|----------|
| Google | gcloud | `gcloud auth application-default login` | BigQuery Sandbox |
| Azure | az | `az login` | Azure SQL free tier |
| AWS | aws | `aws configure` | Athena / Redshift |
| Snowflake | snowsql | Config file | Snowflake trial |
| Local | none | N/A | DuckDB |

---

## BigQuery Public Datasets (Analysis Ideas)

These are already loaded in BigQuery. No download needed.

| Dataset | BigQuery Path | Sample Question |
|---------|--------------|-----------------|
| Stack Overflow | `bigquery-public-data.stackoverflow` | Which languages correlate with highest salaries? |
| GitHub Archive | `bigquery-public-data.github_repos` | What are the fastest-growing open source projects? |
| NOAA Weather | `bigquery-public-data.noaa_gsod` | Is my city getting hotter over the last 50 years? |
| US Census | `bigquery-public-data.census_bureau_acs` | Which US cities grew fastest in the last decade? |
| NYC Taxi | `bigquery-public-data.new_york_taxi_trips` | What are the busiest pickup locations by time of day? |

### Downloadable Datasets

For local analysis with DuckDB or any database:

| Source | Description | Link |
|--------|-------------|------|
| Kaggle | Thousands of curated datasets on every topic | https://www.kaggle.com/datasets |
| World Bank Open Data | Global economic and development indicators | https://data.worldbank.org/ |
| Data.gov | US government open data | https://data.gov |
| Your own data | Export CSV from your bank, LinkedIn, etc. | N/A |

---

## Kyle's Related Videos and Repos

| Video | Repo |
|-------|------|
| YouTube BigQuery Pipeline (video 12) | https://github.com/kyle-chalmers/youtube-bigquery-pipeline |
| Azure SQL Patent Pipeline (video 13) | https://github.com/kyle-chalmers/azure-sql-patent-intelligence |
| AWS S3 + Athena (video 8) | https://github.com/kyle-chalmers/data-ai-tickets-template |
| Snowflake + Claude Code (video 2) | https://github.com/kyle-chalmers/data-ai-tickets-template |
| dbt and AI (video 15) | https://github.com/kyle-chalmers/dbt-agentic-development |

---

## Project Structure

```
free_ai_data_analysis/
├── README.md                     # This file (public guide)
├── CLAUDE.md                     # AI context for this video project
├── .internal/
│   ├── OWNER_CONFIG.md           # Kyle's concrete values (gitignored)
│   ├── RECORDING_NOTES.md        # Private recording prep (gitignored)
│   └── OPENCODE_PROMPTS.md       # Prompts to use with OpenCode during live demo
├── example_workflow/
│   └── AGENTS.md                 # Sample AGENTS.md to reference during demo
├── images/
│   ├── diagram-setup.excalidraw  # Setup overview diagram
│   ├── diagram-setup.png         # Rendered setup diagram
│   ├── diagram-connection.excalidraw  # Connection chain diagram
│   └── diagram-connection.png    # Rendered connection diagram
└── instructions/
    └── setup_guide.md            # Step-by-step condensed guide
```
