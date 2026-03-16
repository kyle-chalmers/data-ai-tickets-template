# Condensed Setup Guide

Follow these steps in order. Total time: ~15 minutes.

## Step 1: Download a Free AI IDE

Pick one:
- **Cursor**: https://cursor.com (free tier)
- **Windsurf**: https://windsurf.com (free tier)

## Step 2: Install OpenCode

Open the terminal in your IDE:

```bash
curl -fsSL https://opencode.ai/install | bash
```

## Step 3: Connect OpenCode to Free Models

1. Go to https://openrouter.ai and create a free account (no credit card)
2. Navigate to Settings > Keys and create an API key
3. Configure OpenCode with the key
4. Set model to `openrouter/free` or `qwen/qwen3-coder:free`

## Step 4: Install Git and Create a GitHub Repo

```bash
# Confirm Git is installed
git --version

# If not, ask OpenCode: "How do I install Git?"

# Create repo on GitHub (github.com > New Repository)
# Clone it locally:
git clone https://github.com/YOUR_USERNAME/free-data-analysis.git
cd free-data-analysis
```

## Step 5: Install gcloud CLI

```bash
# Mac
brew install google-cloud-sdk

# All platforms: https://cloud.google.com/sdk/docs/install

# Verify
gcloud --version
```

## Step 6: Authenticate to Google Cloud

```bash
# Log in (opens browser)
gcloud auth application-default login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID
```

## Step 7: Query BigQuery (Instant Test)

```bash
bq query --use_legacy_sql=false \
  'SELECT COUNT(*) as total
   FROM `bigquery-public-data.stackoverflow.posts_questions`'
```

If you see a number (20+ million), your connection works.

## Step 8: Install Python + BigQuery Client (Optional)

```bash
# Install Python if needed: https://python.org
pip install google-cloud-bigquery
```

Now you can write Python scripts that query BigQuery programmatically.

## You're Done

You now have:
- A free AI coding agent (OpenCode)
- A free AI IDE (Cursor/Windsurf)
- A free cloud data warehouse (BigQuery Sandbox)
- AI connected to the database via gcloud auth

Ask OpenCode to query any BigQuery public dataset. Start with:
- `bigquery-public-data.stackoverflow` (developer data)
- `bigquery-public-data.noaa_gsod` (weather data)
- `bigquery-public-data.census_bureau_acs` (US demographics)
