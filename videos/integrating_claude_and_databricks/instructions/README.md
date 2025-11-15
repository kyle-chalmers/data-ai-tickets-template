# Databricks Setup Instructions

Quick setup guides for using Databricks with Claude Code.

## Available Guides

- **[Databricks CLI Setup](./DATABRICKS_CLI_SETUP.md)** - Command-line interface for data queries, job management, and automation
- **[Databricks MCP Setup](./DATABRICKS_MCP_SETUP.md)** - Interactive Databricks integration with Claude using MCP servers

## Which Should I Use?

See the **[CLI vs MCP Comparison](../databricks_cli_v_mcp_comparison/DATABRICKS_CLI_VS_MCP.md)** for detailed comparison.

**Quick answer:**
- **CLI** → SQL queries, job management, workspace operations, automation
- **MCP** → Interactive data exploration, Unity Catalog access, conversational analysis
- **Both** → Best results (explore with MCP, manage with CLI)

## Setup Order

1. Start with **CLI** (easier, covers most use cases)
2. Add **MCP** if you need interactive Unity Catalog exploration
3. Use both together for optimal workflow

## Prerequisites

- macOS with Homebrew installed
- Access to a Databricks workspace
- Databricks workspace URL and authentication credentials (PAT or OAuth)
