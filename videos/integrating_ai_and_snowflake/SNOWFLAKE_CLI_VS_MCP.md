# Snowflake CLI vs MCP

Quick guide to choosing between Snowflake CLI and MCP.

## Quick Decision

```
Need CSV export? → Use CLI
Large dataset (>10K rows)? → Use CLI
Automation/scripts? → Use CLI
Interactive exploration? → Use MCP
Iterative analysis? → Use MCP
```

## Key Differences

| Feature | CLI | MCP |
|---------|-----|-----|
| **How it works** | Claude runs bash commands | Claude uses native tools |
| **CSV export** | ✅ Built-in `--format csv` | ⚠️ Needs conversion |
| **Large datasets** | ✅ Tested: 10M+ rows, 1.4GB | ❌ Limit: ~10K rows max |
| **Interactive** | ⚠️ One-off queries | ✅ Remembers context |
| **Automation** | ✅ Scripts, cron jobs | ❌ Not for automation |
| **Setup** | 2 minutes | 5 minutes |

## When to Use Each

### Use CLI

| Use Case | Example |
|----------|---------|
| **Export data** | `snow sql -q "SELECT * FROM customers" --format csv > data.csv` |
| **Large dataset** | Export 1M+ rows |
| **Scheduled task** | Daily reports via cron |
| **Reproducible** | SQL files in git |

### Use MCP

| Use Case | Example |
|----------|---------|
| **Explore data** | "Show me the top customers" |
| **Follow-up questions** | "Find outliers" → "Analyze their patterns" |
| **Learn schema** | "What tables exist?" |
| **Quick insights** | Claude interprets automatically |

## Examples

### Export Customer Data

**CLI:**
```bash
snow sql -q "SELECT * FROM customers WHERE country = 'US'" --format csv > us_customers.csv
```
✅ Direct CSV, ready to use

**MCP:**
```
"Query US customers and analyze their purchase patterns"
```
✅ Automatic analysis, but no direct CSV

### Monthly Report

**CLI:**
```bash
snow sql -f monthly_report.sql --format csv > report.csv
```
✅ Schedulable, reproducible

**MCP:**
```
"Generate a sales report for last month"
```
✅ Interactive, but can't schedule

## Recommended Workflow

Use **both** together:

| Step | Tool | Why |
|------|------|-----|
| 1. Explore | MCP | "What data is available?" |
| 2. Refine | MCP | "Show me recent sales data" |
| 3. Export | CLI | `snow sql -f query.sql --format csv > data.csv` |
| 4. Analyze | MCP | "Find trends in data.csv" |

**Best practice:** Explore with MCP → Export with CLI → Analyze with MCP

## Cost

| Aspect | CLI | MCP |
|--------|-----|-----|
| Snowflake compute | Same | Same |
| Claude tokens | ~100 (output only) | ~500-5000 (data + analysis) |

## Setup

**CLI:**
```bash
brew install snowflake-cli
snow connection add ...
snow connection test
```

**MCP:**
```bash
pip install uv
claude mcp add --transport stdio snowflake -- $(which uvx) snowflake-labs-mcp ...
claude mcp list
```

## Bottom Line

- **CLI (80% of cases):** Data exports, automation, large datasets
- **MCP (20% of cases):** Exploration, ad-hoc questions
- **Use both:** They complement each other perfectly

---

**Related:**
- [CLI Setup](./instructions/SNOWFLAKE_CLI_SETUP.md)
- [MCP Setup](./instructions/SNOWFLAKE_MCP_SETUP.md)
- [Stress Test Results](./STRESS_TEST_RESULTS.md) - Real performance data with 10M+ rows
