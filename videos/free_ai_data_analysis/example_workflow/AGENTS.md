# AI Agent Instructions: Free Data Analysis Project

## Project Overview

This is a data analysis project using BigQuery and Python. The goal is to explore public datasets and answer interesting questions using AI-assisted SQL and Python scripts.

## Available Tools

### BigQuery (Primary Database)
- **Console**: https://console.cloud.google.com/bigquery
- **CLI**: `bq query --use_legacy_sql=false 'YOUR SQL HERE'`
- **Python**: `google.cloud.bigquery.Client()` with Application Default Credentials
- **Public datasets**: All datasets under `bigquery-public-data.*` are available

### OpenCode (AI Coding Agent)
- Runs in the terminal
- Can write SQL, Python, and shell commands
- Use plan mode to explore data before executing

## Conventions

- Use BigQuery Standard SQL (not legacy SQL)
- Always use backtick-quoted table names: `` `bigquery-public-data.stackoverflow.posts_questions` ``
- Use `ref()` style references when describing data lineage
- Add comments to SQL explaining what each CTE or subquery does
- Save analysis scripts in the `sql/` directory

## Datasets in Use

- `bigquery-public-data.stackoverflow` (posts, users, tags, votes)
- `bigquery-public-data.noaa_gsod` (global weather stations)
- `bigquery-public-data.census_bureau_acs` (US demographics)

## How to Help

When asked to analyze data:
1. First explore the schema (INFORMATION_SCHEMA or bq show)
2. Suggest an analysis approach before writing queries
3. Write clear, commented SQL
4. Explain what the results mean in plain language
