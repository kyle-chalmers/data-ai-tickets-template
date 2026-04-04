# Tool Setup Prompts

Ready-to-paste prompts for Claude Code to install, configure, and verify each tool connection used in the workshop demo.

---

## Google Sheets MCP

**Status:** Needs setup

```text
I need to set up a Google Sheets MCP server so I can read data from Google Sheets
directly in Claude Code. Please help me:

1. Research the available Google Sheets MCP server options
2. Install the recommended one
3. Configure it at the user level (~/.claude.json) so it's available across projects
4. Verify it works by reading a test Google Sheet

I want to be able to pull data from a Google Sheet during a live workshop demo,
so reliability is critical. Walk me through each step.
```

---

## Atlassian/Jira MCP

**Status:** Configured globally (SSE at mcp.atlassian.com)

```text
I have the Atlassian MCP server configured. Please verify it's working by:

1. Authenticating the MCP connection (it uses OAuth — I may need to approve in browser)
2. Listing available Jira projects
3. Reading a few tickets from the KAN project
4. Confirming I can read ticket details (subject, description, status, priority)

I need this working reliably for a live workshop demo where I'll triage tickets.
```

---

## BigQuery CLI (bq)

**Status:** Installed

```text
I have the bq CLI installed. Please verify it's working by:

1. Checking my current gcloud auth status
2. Running a simple query against a BigQuery public dataset:
   bq query --use_legacy_sql=false 'SELECT COUNT(*) as total FROM `bigquery-public-data.samples.shakespeare`'
3. Confirming I can query and get results back

If auth is expired, walk me through re-authenticating with gcloud.
I need this for a live workshop demo.
```

---

## DuckDB CLI

**Status:** Installed

```text
I have DuckDB installed. Please verify it works by:

1. Running duckdb with a simple in-memory query
2. Loading a local CSV file and querying it:
   duckdb -c "SELECT COUNT(*) FROM read_csv_auto('path/to/file.csv')"
3. Running a basic aggregation query on the CSV

Test with one of the CSV files in videos/az_tech_week_workshop/datasets/ or
videos/az_tech_week_workshop/linkedin_data/Connections.csv
```

---

## GitHub CLI (gh)

**Status:** Installed and authenticated

```text
Please verify the GitHub CLI is working by:

1. Running gh auth status
2. Listing my recent repos: gh repo list --limit 5
3. Confirming I can create repos and push code

I need this for a live workshop demo where I might create a project from scratch.
```

---

## Vercel CLI

**Status:** Installed and authenticated

```text
Please verify the Vercel CLI is working by:

1. Running vercel whoami
2. Listing my recent projects: vercel project list
3. Confirming I can deploy a project

I need this for a live workshop demo where I might deploy a website or app.
Note: the CLI version may be outdated — check if an update is needed.
```

---

## Quick Verification (All Tools at Once)

```text
I'm preparing for a live workshop demo and need to verify all my tool connections
are working. Please check each of these in order:

1. GitHub CLI (gh) — run gh auth status
2. Vercel CLI — run vercel whoami
3. BigQuery CLI (bq) — run a test query against a public dataset
4. DuckDB — run a test query on a local CSV
5. Atlassian MCP — check if the MCP connection is active
6. Google Sheets MCP — check if configured, and if not, flag it

For any that fail, tell me what's wrong and how to fix it.
Report the status of each as PASS or FAIL.
```
