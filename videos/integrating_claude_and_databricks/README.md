# Databricks + Claude Integration

Complete guide for integrating Databricks with Claude Code and Claude Desktop.

---

## Video Goals

This integration enables you to:

1. **Give Claude access to all of the data stored within Databricks**
   - Query Unity Catalog tables interactively
   - Explore schemas and data structures
   - Run SQL queries conversationally

2. **Have Claude create Databricks workbooks and jobs**
   - Generate notebooks with analysis code
   - Create and manage job configurations
   - Automate workflow creation

3. **Have Claude troubleshoot different issues with jobs and be able to help with most Databricks functions**
   - Debug job failures and errors
   - Analyze cluster configurations
   - Optimize query performance
   - Manage workspace resources

---

## What's Covered

1. **How to connect Databricks MCP to Claude Desktop**
   - Managed MCP servers (production-ready)
   - Community databrickslabs MCP (experimental)

2. **How to connect the Databricks MCP and Databricks CLI with Claude Code**
   - CLI installation and configuration
   - MCP server setup for Claude Code
   - Profile management for multiple workspaces

3. **How you can utilize this integration to have gen AI work with Databricks**
   - Creating notebooks and jobs
   - Querying and analyzing data
   - Managing clusters and workflows
   - Troubleshooting and optimization

---

## Quick Start Guides

### 1. Choose Your Tool

| Tool | Best For | Setup Time |
|------|----------|------------|
| **[Databricks CLI](./instructions/DATABRICKS_CLI_SETUP.md)** | SQL queries, job management, automation | 5 minutes |
| **[Databricks MCP](./instructions/DATABRICKS_MCP_SETUP.md)** | Interactive exploration, Unity Catalog access | 10-15 minutes |

**Recommendation:** Start with CLI for immediate productivity, add MCP for interactive data exploration.

### 2. Installation

**Databricks CLI:**
```bash
# Install via Homebrew
brew tap databricks/tap
brew install databricks

# Verify
databricks --version
```

**Databricks MCP Options:**
- **Managed MCP** (recommended) - Hosted by Databricks, ready to use
- **databrickslabs MCP** (experimental) - Community server for testing

See full setup instructions in the [instructions folder](./instructions/).

---

## Documentation

### Setup Guides

- **[Instructions Overview](./instructions/README.md)** - Quick navigation and decision guide
- **[CLI Setup Guide](./instructions/DATABRICKS_CLI_SETUP.md)** - Complete CLI installation and configuration
- **[MCP Setup Guide](./instructions/DATABRICKS_MCP_SETUP.md)** - All three MCP options explained
- **[Troubleshooting Guide](./instructions/TROUBLESHOOTING.md)** - Common issues and solutions

### Comparison & Examples

- **[CLI vs MCP Comparison](./databricks_cli_v_mcp_comparison/DATABRICKS_CLI_VS_MCP.md)** - Detailed feature comparison
- **[Example Workflow](./example_workflow/)** - Practical use case with sample queries and results

---

## Use Cases

### With CLI

```bash
# Execute SQL queries
databricks sql execute --sql "SELECT * FROM catalog.schema.table LIMIT 10"

# List all jobs
databricks jobs list --profile biprod

# Export notebook
databricks workspace export /path/to/notebook output.ipynb

# Manage clusters
databricks clusters list
databricks clusters start --cluster-id abc-123
```

### With MCP

Ask Claude directly:
- "List all tables in my Unity Catalog"
- "Show me the schema for the customers table"
- "Query sales data for Q4 2024"
- "Create a notebook to analyze customer churn"
- "Help me debug job ID 12345"

### Combined Approach

1. **Explore with MCP** - Ask Claude to explore data structure and understand schema
2. **Execute with CLI** - Run production queries and manage jobs
3. **Automate** - Create scripts using CLI commands for scheduled tasks

---

## Prerequisites

- macOS with Homebrew installed
- Databricks workspace access
- Workspace URL (e.g., `https://your-workspace.cloud.databricks.com`)
- Authentication credentials:
  - **OAuth** (recommended for CLI and managed MCP)
  - **Personal Access Token** (for automation and databrickslabs MCP)

### Generating Personal Access Tokens

1. Log into Databricks workspace
2. Go to **User Settings** → **Developer** → **Access Tokens**
3. Click **Generate New Token**
4. Set expiration period and add comment
5. Copy token (shown only once!)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Claude Code / Desktop               │
│                                                      │
│  ┌──────────────────┐      ┌────────────────────┐  │
│  │  Databricks CLI  │      │  Databricks MCP    │  │
│  │  - SQL queries   │      │  - Unity Catalog   │  │
│  │  - Job mgmt      │      │  - Genie spaces    │  │
│  │  - Workspace ops │      │  - Vector search   │  │
│  └────────┬─────────┘      └─────────┬──────────┘  │
│           │                          │             │
└───────────┼──────────────────────────┼─────────────┘
            │                          │
            └──────────┬───────────────┘
                       │
                       ▼
            ┌──────────────────────┐
            │  Databricks Workspace│
            │                      │
            │  - Unity Catalog     │
            │  - SQL Warehouses    │
            │  - Jobs & Clusters   │
            │  - Notebooks         │
            └──────────────────────┘
```

---

## Security Best Practices

### Token Management

- Use OAuth for interactive workflows (CLI and managed MCP)
- Use Personal Access Tokens for automation and CI/CD
- Set appropriate expiration periods (e.g., 90 days)
- Rotate tokens regularly
- Never commit tokens to version control
- Store tokens in environment variables or secure vaults

### Permission Management

Grant minimal necessary permissions:
- `USE` on catalog and schema
- `SELECT` on required tables
- `EXECUTE` on specific functions
- Avoid `ALL PRIVILEGES` unless necessary

### Configuration File Security

```bash
# Secure Databricks config file
chmod 600 ~/.databrickscfg

# Check permissions
ls -l ~/.databrickscfg
# Should show: -rw-------
```

---

## Next Steps

1. **Install CLI** - Follow [CLI Setup Guide](./instructions/DATABRICKS_CLI_SETUP.md)
2. **Configure Authentication** - Set up OAuth or PAT
3. **Test Connection** - Verify with simple queries
4. **Explore MCP** (optional) - Add interactive capabilities
5. **Try Example Workflow** - See practical use case in [example_workflow/](./example_workflow/)

---

## Resources

### Official Documentation

- **Databricks CLI:** https://docs.databricks.com/dev-tools/cli/
- **Databricks MCP:** https://docs.databricks.com/mcp/
- **Unity Catalog:** https://docs.databricks.com/unity-catalog/
- **Databricks SQL:** https://docs.databricks.com/sql/

### Community Resources

- **databrickslabs MCP Repository:** https://github.com/databrickslabs/mcp
- **Claude Code Documentation:** https://docs.claude.com/claude-code
- **MCP Protocol Specification:** https://modelcontextprotocol.io

### Getting Help

- Check [Troubleshooting Guide](./instructions/TROUBLESHOOTING.md)
- Review [CLI vs MCP Comparison](./databricks_cli_v_mcp_comparison/DATABRICKS_CLI_VS_MCP.md)
- Consult Databricks documentation
- Ask in Databricks community forums

---

## Video Sections

### Part 1: Introduction (2 min)
- What we'll build
- Use cases and benefits
- Prerequisites overview

### Part 2: CLI Setup (5 min)
- Homebrew installation
- Authentication configuration
- Testing connection
- Common commands demo

### Part 3: MCP Setup (8 min)
- Managed MCP overview
- databrickslabs MCP installation
- Configuration for Claude Code
- Testing MCP connection

### Part 4: Practical Examples (10 min)
- Exploring data with MCP
- Creating notebooks with Claude
- Managing jobs via CLI
- Combined workflow demo

### Part 5: Advanced Topics (5 min)
- Security best practices
- Multiple workspace management
- Troubleshooting tips
- Next steps

---

**Total Video Length:** ~30 minutes

**Skill Level:** Beginner to Intermediate

**Last Updated:** 2025-01-14
