# Snowflake CLI vs MCP: Quick Decision Guide

Fast reference for choosing between Snowflake CLI and MCP.

---

## TL;DR

```
Need CSV export? → Use CLI
Dataset > 240 rows? → Use CLI (MCP hits limit)
Automation/scripts? → Use CLI
Interactive exploration (< 200 rows)? → Use MCP
Quick schema questions? → Use MCP
```

**Reality Check:** CLI handles **41,666x more data** than MCP (10M vs 240 rows tested)

---

## Key Differences

| Feature | CLI | MCP |
|---------|-----|-----|
| **How it works** | Bash commands | Native MCP tools |
| **CSV export** | ✅ Built-in `--format csv` | ⚠️ Needs conversion |
| **Max rows tested** | ✅ 10,000,000 | ❌ 240 (hard limit) |
| **Interactive** | ⚠️ One-off queries | ✅ Remembers context |
| **Automation** | ✅ Scripts, cron jobs | ❌ Not for automation |
| **Natural language** | ❌ SQL only | ✅ Plain English |
| **Setup time** | 2 minutes | 5 minutes |

---

## When to Use Each

### Use CLI For:

| Use Case | Why |
|----------|-----|
| **Any dataset > 240 rows** | MCP hits 25K token limit |
| **CSV export** | Native support, any size |
| **Production reports** | Reliable, reproducible |
| **Automation** | Scripts, scheduled jobs |
| **Large datasets** | Tested successfully to 10M rows |

**Example:**
```bash
snow sql -q "SELECT * FROM customers WHERE country = 'US'" --format csv > data.csv
```

### Use MCP For:

| Use Case | Why |
|----------|-----|
| **Small datasets (< 200 rows)** | Interactive analysis |
| **Schema exploration** | "What tables exist?" |
| **Follow-up questions** | Remembers context |
| **Ad-hoc queries** | No SQL required |
| **Quick insights** | Automatic interpretation |

**Example:**
```
"Show me top 50 customers by revenue and analyze their patterns"
```

---

## Quick Decision Matrix

```
Dataset Size → Recommended Tool

< 100 rows         → Either (both tested)
100 - 200 rows     → MCP for interactive, CLI for export
200 - 240 rows     → MCP at limit, CLI safer
240+ rows          → CLI only (MCP fails)
1,000+ rows        → CLI only
10,000+ rows       → CLI only
1M+ rows           → CLI only (tested ✅)
```

---

## Recommended Workflow

Use **both** together:

| Step | Tool | Action |
|------|------|--------|
| 1. Explore | MCP | "What data exists?" (< 200 rows) |
| 2. Refine | MCP | "Show recent sales" (< 200 rows) |
| 3. Export | CLI | `snow sql -f query.sql --format csv` |
| 4. Analyze | Python/Excel | Work with full dataset |

**Best Practice:** Explore with MCP → Export with CLI

---

## Real-World Example

**Scenario:** Analyze 700K customer transactions

**Wrong Approach:**
- ❌ Try MCP → Hits 240 row limit immediately
- ❌ Cannot complete analysis

**Right Approach:**
- ✅ Sample 100 rows with MCP (explore structure)
- ✅ Export full 700K rows with CLI
- ✅ Analyze complete dataset with Python/Excel
- ✅ Success in minutes

---

## Cost Comparison

| Aspect | CLI | MCP |
|--------|-----|-----|
| **Snowflake compute** | Same | Same |
| **Claude tokens** | ~100 (output only) | ~500-5,000+ (data in context) |

**Note:** Large MCP queries consume many tokens due to data being loaded into context.

---

## Setup

### CLI (2 minutes)

```bash
brew install snowflake-cli
snow connection add --connection-name prod ...
snow connection test
```

[Full CLI Setup Guide](../instructions/SNOWFLAKE_CLI_SETUP.md)

### MCP (5 minutes)

```bash
pip install uv
claude mcp add --transport stdio snowflake -- $(which uvx) snowflake-labs-mcp ...
claude mcp list
```

[Full MCP Setup Guide](../instructions/SNOWFLAKE_MCP_SETUP.md)

---

## Bottom Line

**CLI (Use 80%+ of the time):**
- Production-ready
- Unlimited scale (tested to 10M rows)
- CSV export native
- Automation-friendly

**MCP (Use < 20% of the time):**
- Exploration only
- Hard limit: 240 rows
- Great for discovery
- No automation

**Together:** They complement each other perfectly for the complete workflow.

---

**For complete test results:** See [Stress Test Plan and Results](./stress_test_plan_and_results.md)

**Setup guides:**
- [Snowflake CLI Setup](../instructions/SNOWFLAKE_CLI_SETUP.md)
- [Snowflake MCP Setup](../instructions/SNOWFLAKE_MCP_SETUP.md)
- [MCP Troubleshooting](../instructions/TROUBLESHOOTING_MCP.md)
