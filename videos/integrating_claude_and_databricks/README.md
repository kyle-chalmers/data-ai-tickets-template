# Databricks + Claude CLI Integration

> **YouTube:** [Claude Code Makes Databricks Easy: Jobs, Notebooks, SQL & Unity Catalog (All via the CLI)](https://www.youtube.com/watch?v=5_q7j-k8DbM)

Complete guide for integrating Databricks with Claude Code using the Databricks CLI.

---

## Video Goals

Enable Claude to:
1. **Access Databricks data** - Query Unity Catalog, explore schemas, run SQL conversationally
2. **Create notebooks and jobs** - Generate analysis code, manage job configurations, automate workflows
3. **Troubleshoot and optimize** - Debug failures, analyze clusters, optimize queries, manage resources

---

## MCP Investigation Summary

We investigated two MCP (Model Context Protocol) options:
- **[Databricks Managed MCP](https://docs.databricks.com/aws/en/generative-ai/mcp/managed-mcp)** - Hosted MCP servers by Databricks
- **[databrickslabs/mcp](https://github.com/databrickslabs/mcp)** - Community MCP implementation

**Decision: CLI-Only**

Reasons:
- Managed MCP requires full Databricks (currently on trial)
- databrickslabs/mcp repository deprecated
- All MCP functionality available through CLI
- Claude Desktop connector had connection issues

---

## CLI Capabilities

| Feature | Support |
|---------|---------|
| SQL Queries | ✅ Direct execution |
| Job Management | ✅ Full control |
| Workspace Operations | ✅ Complete access |
| Unity Catalog | ⚠️ Manual queries |
| Production Support | ✅ Official |
| Setup Time | 5 minutes |
| Authentication | OAuth/PAT |

**Primary Use Cases:**
- Workspace & job management, DevOps automation, job scheduling
- Notebook version control, production deployments
- Multi-workspace administration

**Primary Constraints:**
- Unity Catalog: Manual queries (no auto-discovery)
- Genie Spaces: Not supported
- Vector Search: SQL only
- Claude Desktop: Not compatible (Claude Code only)

---

## Quick Start

```bash
# Install
brew tap databricks/tap && brew install databricks

# Configure
databricks configure  # Follow prompts for OAuth

# Test
databricks workspace list
```

Full setup guide: [DATABRICKS_CLI_SETUP.md](./instructions/DATABRICKS_CLI_SETUP.md)

---

## Common Commands

```bash
# SQL queries
databricks sql execute --sql "SELECT * FROM catalog.schema.table LIMIT 10"

# Job management
databricks jobs list
databricks jobs run-now --job-id 12345

# Notebook operations
databricks workspace export /path/to/notebook output.ipynb

# Cluster management
databricks clusters list
databricks clusters start --cluster-id abc-123

# Unity Catalog exploration
databricks catalogs list
databricks schemas list --catalog-name your_catalog
databricks tables list --catalog-name your_catalog --schema-name your_schema
```

**Claude Code Integration Examples:**
- "Show me all tables in the Unity Catalog"
- "Query sales data and save results to CSV"
- "List all running jobs and their status"
- "Export the customer_analysis notebook"

---

## Prerequisites

- macOS with Homebrew
- Databricks workspace access
- Workspace URL: `https://your-workspace.cloud.databricks.com`
- Authentication: OAuth (interactive) or Personal Access Token (automation)

**Generate PAT:** User Settings → Developer → Access Tokens → Generate New Token

## Security Best Practices

**Token Management:**
- Use OAuth for interactive, PAT for automation
- Set 90-day expiration, rotate regularly
- Never commit tokens to version control

**Configuration Security:**
```bash
chmod 600 ~/.databrickscfg
ls -l ~/.databrickscfg  # Should show: -rw-------
```

---

## Next Steps

1. [Install CLI](./instructions/DATABRICKS_CLI_SETUP.md)
2. Configure authentication (OAuth or PAT)
3. Test connection
4. Explore Unity Catalog
5. [Try example workflow](./example_workflow/)

---

## Resources

**Official Documentation:**
- Databricks CLI: https://docs.databricks.com/dev-tools/cli/
- Unity Catalog: https://docs.databricks.com/unity-catalog/
- Databricks SQL: https://docs.databricks.com/sql/

**Getting Help:**
- [CLI Setup Guide Troubleshooting](./instructions/DATABRICKS_CLI_SETUP.md#troubleshooting)
- Databricks CLI documentation
- Databricks community forums
