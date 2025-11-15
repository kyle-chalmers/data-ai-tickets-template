# Databricks MCP Setup

Setup guide for Databricks MCP integration - enables Claude to explore Unity Catalog, query data, and interact with Genie spaces conversationally.

## MCP Options Overview

Databricks offers three MCP integration approaches:

| Type | Status | Support | Use Case |
|------|--------|---------|----------|
| **Managed MCP** | Production-ready | Fully supported | Unity Catalog access, Genie spaces |
| **External MCP** | Stable | Supported via proxy | Third-party MCP servers |
| **databrickslabs MCP** | Experimental | Community only | Development/testing |

**Recommendation:** Use **Managed MCP servers** for production workflows. They're hosted by Databricks, require minimal setup, and have official support.

---

## Option 1: Managed MCP Servers (RECOMMENDED)

Managed MCP servers are hosted by Databricks and provide ready-to-use access to Unity Catalog resources.

### Prerequisites

- Unity Catalog-enabled Databricks workspace
- Appropriate permissions on Unity Catalog resources
- MCP client (Claude Code, Claude Desktop, etc.)

### Available Managed Servers

**1. Unity Catalog Functions**
- Access registered functions with proper signatures
- Automatic schema discovery

**2. Vector Search Indexes**
- Query indexed data within Unity Catalog
- Semantic search capabilities

**3. Genie Spaces**
- Manage conversations with BI spaces
- Send questions and receive insights

### Setup

```bash
# Server URL format
server_url="https://<workspace-url>/api/2.0/mcp/<server-type>/<catalog>/<schema>"

# Examples:
# Vector Search: https://workspace.cloud.databricks.com/api/2.0/mcp/vector-search/prod/customer_support
# UC Functions: https://workspace.cloud.databricks.com/api/2.0/mcp/uc-functions/main/analytics
# Genie: https://workspace.cloud.databricks.com/api/2.0/mcp/genie/01234567890abcdef
```

**Configure in Claude Code:**

```bash
# Add managed MCP server (configuration depends on MCP client)
# For Claude Code, use the MCP configuration interface
# Provide:
# - Server URL (from above)
# - Authentication (uses your Databricks credentials)
```

**Key Features:**
- ✓ No installation required
- ✓ Automatic authentication via workspace credentials
- ✓ Permission enforcement from Unity Catalog
- ✓ Fully supported with SLAs
- ✓ Regular updates and maintenance

---

## Option 2: External MCP via Databricks Proxy

Connect to third-party MCP servers through Databricks proxy for secure access.

### Prerequisites

- Unity Catalog workspace with Serverless enabled
- CREATE CONNECTION privilege
- External MCP server URL

### Setup

```sql
-- Create connection to external MCP server
CREATE CONNECTION <connection-name>
TYPE mcp
OPTIONS (
  uri = '<external-mcp-server-url>',
  headers = '{"Authorization": "Bearer <token>"}'
);

-- Grant access
GRANT USE CONNECTION ON <connection-name> TO <principal>;
```

**Use Cases:**
- Third-party data sources
- Custom MCP implementations
- External AI services

---

## Option 3: databrickslabs MCP (Experimental)

Community-maintained Unity Catalog MCP server for development and testing.

> **⚠️ Important:** This is an experimental server with no official support or SLAs. For production use, prefer Managed MCP servers.

### Prerequisites

```bash
# Install uv (Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Python 3.12
uv python install 3.12

# Clone repository
cd ~/Development
git clone https://github.com/databrickslabs/mcp.git
cd mcp
```

### Installation

**Option A: Local Development (stdio)**

```bash
# Create configuration directory
mkdir -p ~/.mcp

# Configure for Claude Code
claude mcp add --scope user --transport stdio databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://your-workspace.cloud.databricks.com \
  --token dapi_your_token_here \
  -s your_catalog.your_schema

# Or with multiple schemas
claude mcp add --scope user --transport stdio databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://your-workspace.cloud.databricks.com \
  --token dapi_your_token_here \
  -s catalog1.schema1 \
  -s catalog2.schema2 \
  -g genie_space_id_1 \
  -g genie_space_id_2
```

**Option B: Claude Desktop Configuration**

```json
// ~/Library/Application Support/Claude/claude_desktop_config.json
{
  "mcpServers": {
    "databricks-unity-catalog": {
      "command": "uv",
      "args": [
        "run",
        "unitycatalog-mcp",
        "--host", "https://your-workspace.cloud.databricks.com",
        "--token", "dapi_your_token_here",
        "-s", "your_catalog.your_schema",
        "-g", "genie_space_id"
      ],
      "cwd": "/Users/YOUR_USERNAME/Development/mcp"
    }
  }
}
```

**Option C: Deploy to Databricks Apps**

```bash
# Via databricks bundle
databricks bundle deploy -t dev

# Via databricks apps CLI
databricks apps create databricks-uc --app-config-file app.yml
```

### Configuration Options

| Flag | Description | Example |
|------|-------------|---------|
| `--host` | Databricks workspace URL | `https://workspace.cloud.databricks.com` |
| `--token` | Personal Access Token | `dapi_abc123...` |
| `-s, --schema` | Catalog.schema to access | `-s main.analytics` |
| `-g, --genie-space-id` | Genie space ID | `-g 01abc123def456` |

### Finding Genie Space IDs

```bash
# Via Databricks UI:
# 1. Navigate to Genie space
# 2. Copy ID from URL: /genie/spaces/<space-id>

# Or extract from workspace
# Look for Genie space configuration in workspace settings
```

---

## Verification

### Test Managed MCP

```bash
# In Claude Code, ask:
"List all tables in my Unity Catalog"
"Show me the schema for the customers table"
"Query the sales_data table for last month's revenue"
```

### Test databrickslabs MCP

```bash
# Verify MCP server is running
claude mcp list
# Should show: databricks-uc - ✓ Connected

# Test in Claude Code
# Ask: "What tables are available in Unity Catalog?"
```

---

## Troubleshooting

### Managed MCP Issues

**Error: "Unity Catalog not enabled"**
```
Solution: Your workspace must have Unity Catalog enabled
Check: Workspace settings → Catalog → Unity Catalog status
```

**Error: "Insufficient permissions"**
```
Solution: Request appropriate Unity Catalog permissions
Need: SELECT on tables, EXECUTE on functions, USE on catalog/schema
```

### databrickslabs MCP Issues

**Error: "command not found: uv"**
```bash
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Reload shell or source profile
source ~/.zshrc  # or ~/.bashrc
```

**Error: "Python 3.12 not found"**
```bash
# Install Python 3.12
uv python install 3.12

# Verify
uv python list
```

**Error: "Token authentication failed"**
```bash
# Verify token is valid
curl -H "Authorization: Bearer dapi_your_token" \
  https://your-workspace.cloud.databricks.com/api/2.0/clusters/list

# Generate new token if expired
# Databricks UI → User Settings → Developer → Access Tokens
```

**Error: "Schema not found"**
```bash
# Verify schema exists and you have access
databricks sql execute --sql "SHOW SCHEMAS IN your_catalog"

# Check permissions
databricks sql execute --sql "SHOW GRANT ON SCHEMA your_catalog.your_schema"
```

---

## Comparison: Managed vs databrickslabs

| Feature | Managed MCP | databrickslabs MCP |
|---------|-------------|-------------------|
| **Installation** | None required | Manual setup |
| **Support** | Official SLA | Community only |
| **Authentication** | Workspace-integrated | Manual PAT setup |
| **Unity Catalog** | Full access | Schema-level |
| **Genie Spaces** | Full integration | Basic support |
| **Updates** | Automatic | Manual git pull |
| **Production Ready** | ✓ Yes | ✗ Experimental |

---

## Advanced: Multiple Workspaces

### Managed MCP (Multiple Catalogs)

Configure different server URLs for each catalog/workspace you need to access.

### databrickslabs MCP (Multiple Schemas)

```bash
# Add multiple schemas in single MCP server
claude mcp add --scope user --transport stdio databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://workspace.cloud.databricks.com \
  --token dapi_token \
  -s production.sales \
  -s production.marketing \
  -s development.analytics \
  -g genie_prod_123 \
  -g genie_dev_456
```

---

## Security Best Practices

### Token Management

```bash
# Use environment variables for tokens
export DATABRICKS_TOKEN="dapi_your_token"

# Reference in configuration
claude mcp add --scope user --transport stdio databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://workspace.cloud.databricks.com \
  --token "${DATABRICKS_TOKEN}" \
  -s catalog.schema
```

### Token Expiration

- Set appropriate expiration for PATs (e.g., 90 days)
- Rotate tokens regularly
- Use separate tokens for different MCP servers
- Never commit tokens to version control

### Minimal Permissions

Grant only necessary Unity Catalog permissions:
- `USE` on catalog and schema
- `SELECT` on specific tables
- `EXECUTE` on required functions
- Avoid `ALL PRIVILEGES` unless necessary

---

## Resources

- **Managed MCP Documentation:** https://docs.databricks.com/mcp/
- **databrickslabs MCP Repository:** https://github.com/databrickslabs/mcp
- **Unity Catalog Permissions:** https://docs.databricks.com/unity-catalog/manage-privileges/
- **Personal Access Tokens:** https://docs.databricks.com/dev-tools/auth.html#personal-access-tokens

---

**Next:** [Compare CLI vs MCP](../databricks_cli_v_mcp_comparison/DATABRICKS_CLI_VS_MCP.md)
