# AI Agent Instructions: Free AI Data Analysis Video

> IMPORTANT: Everything in this repo is public-facing, so do not place any sensitive info here. If there is information that AI tools need across sessions but should not be published, put it in the `.internal/` folder which is ignored by git per the `.gitignore`.

## Project Overview

This is a demo folder for **KC Labs AI YouTube video #16**: a practical tutorial showing how to set up a complete AI-powered data analysis environment using entirely free tools.

**Audience**: Beginners through experienced data professionals
**Demo Subject**: OpenCode + BigQuery Sandbox + Cursor/Windsurf, all free
**Primary Database**: BigQuery Sandbox (free, no credit card, public datasets pre-loaded)

> If `.internal/OWNER_CONFIG.md` exists, read it at the start of each session and use those concrete values.

## Available Tools

### OpenCode (Free AI Coding Agent)
- **Install**: `curl -fsSL https://opencode.ai/install | bash`
- **Alternatives**: `brew install anomalyco/tap/opencode` (Mac), `choco install opencode` (Windows)
- **Model**: Connect to OpenRouter free models (29 available, no credit card)
- **Usage**: Terminal AI agent that writes code, runs commands, reads files

### gcloud CLI + bq Tool
- **Install**: `brew install google-cloud-sdk` or https://cloud.google.com/sdk/docs/install
- **Auth**: `gcloud auth application-default login`
- **Set project**: `gcloud config set project [PROJECT_ID]`
- **Query**: `bq query --use_legacy_sql=false 'SELECT ...'`

### BigQuery Sandbox
- **Console**: https://console.cloud.google.com/bigquery
- **Free tier**: 10 GB storage, 1 TB queries/month, no credit card
- **Public datasets**: `bigquery-public-data.*` (Stack Overflow, GitHub, NOAA, Census, NYC Taxi)

### Python + BigQuery Client (for advanced analysis)
- **Install**: `pip install google-cloud-bigquery`
- **Auth**: Uses ADC from gcloud auth automatically
- **Usage**: Write analysis scripts that query BigQuery programmatically

## Demo Flow

1. **Install Cursor/Windsurf** (free AI IDE)
2. **Install OpenCode** in the IDE terminal, connect to OpenRouter free models
3. **Create GitHub repo**, install Git, create AGENTS.md
4. **Open BigQuery Sandbox**, show public datasets
5. **Install gcloud CLI**, authenticate with `gcloud auth application-default login`
6. **Test with bq query** (instant result, no Python needed)
7. **Level up to Python**: install BigQuery client, use plan mode then build mode
8. **Run analysis queries** against Stack Overflow and NOAA public datasets
9. **Save work**: commit and push to GitHub
10. **Show alternatives**: other free databases, other terminal agents

## Code Conventions

- SQL files in `sql/` use BigQuery Standard SQL (not legacy)
- Python scripts use `google.cloud.bigquery.Client()` with ADC (no explicit credentials)
- All queries target `bigquery-public-data.*` datasets (no private data)

## Operating Principles

- Show reasoning: announce what you are about to do and why
- Verify work: after every query, confirm results make sense
- Be honest about limitations: rate limits, free tier changes, when to upgrade
- Protect data: never print API keys or credentials in terminal output
