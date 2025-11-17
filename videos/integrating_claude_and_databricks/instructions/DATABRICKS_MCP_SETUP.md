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

## Troubleshooting

### Managed MCP Issues

#### Unity Catalog Not Enabled

**Error: "Unity Catalog is not enabled for this workspace"**

**Solution:**
- Managed MCP requires Unity Catalog
- Check with workspace administrator
- Verify: Workspace Settings → Catalog → Unity Catalog status
- Consider using CLI or databrickslabs MCP as alternative

#### Insufficient Permissions

**Error: "Access denied to catalog/schema/table"**

**Required Permissions:**
```sql
-- Request these permissions from admin:
GRANT USE CATALOG ON CATALOG catalog_name TO user@email.com;
GRANT USE SCHEMA ON SCHEMA catalog_name.schema_name TO user@email.com;
GRANT SELECT ON SCHEMA catalog_name.schema_name TO user@email.com;
```

**Verify Current Permissions:**
```sql
SHOW GRANTS ON CATALOG catalog_name;
SHOW GRANTS ON SCHEMA catalog_name.schema_name;
```

#### Server URL Configuration

**Error: "Failed to connect to MCP server"**

**Verify URL format:**
```
# Correct format:
https://workspace-url.cloud.databricks.com/api/2.0/mcp/uc-functions/catalog/schema

# Common mistakes:
# ✗ Missing /api/2.0/mcp/ path
# ✗ Incorrect catalog or schema name
# ✗ Trailing slash at end
```

### databrickslabs MCP Issues

#### Connection Failure

If you see "Failed to connect" when using databrickslabs MCP:

**1. Restart Claude Code**
- Simplest fix - close and reopen Claude Code terminal

**2. Test MCP Manually**

```bash
# Navigate to mcp repository
cd ~/Development/databricks-mcp

# Test manually
uv run unitycatalog-mcp \
  --host https://your-workspace.cloud.databricks.com \
  --token dapi_your_token_here \
  -s your_catalog.your_schema
```

If this hangs or errors, the issue is with MCP itself, not Claude Code.

**3. Verify Dependencies**

```bash
# Check uv is installed
which uv
# Should show: /Users/YOUR_USERNAME/.local/bin/uv

# If not found, install:
curl -LsSf https://astral.sh/uv/install.sh | sh

# Reload shell
source ~/.zshrc  # or ~/.bashrc

# Verify Python 3.12
uv python list
# Should include python-3.12.x
```

**4. Check MCP Configuration**

```bash
# View Claude Code MCP config
cat ~/.claude.json | jq '.mcpServers'

# Or list MCP servers
claude mcp list
# Should show: databricks-uc - ✓ Connected (or error message)
```

**5. Verify Token**

```bash
# Test token works
curl -H "Authorization: Bearer dapi_your_token_here" \
  https://your-workspace.cloud.databricks.com/api/2.0/clusters/list

# Should return JSON (not 401 error)
```

**6. Remove and Re-add MCP**

```bash
# Remove existing configuration
claude mcp remove databricks-uc --scope user

# Re-add with correct configuration
claude mcp add --scope user --transport stdio databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://your-workspace.cloud.databricks.com \
  --token dapi_your_token_here \
  -s your_catalog.your_schema
```

#### Python Version Issues

**Error: "Python 3.12 not found"**

```bash
# Install Python 3.12 via uv
uv python install 3.12

# Verify installation
uv python list
# Should show: cpython-3.12.x-...

# Set as default for project
uv python pin 3.12
```

#### Repository Issues

**Error: "unitycatalog-mcp not found"**

```bash
# Clone or update repository
cd ~/Development
git clone https://github.com/databrickslabs/mcp.git databricks-mcp
cd databricks-mcp

# Or update existing
cd ~/Development/databricks-mcp
git pull origin main

# Verify you're in correct directory when running
pwd
# Should show: /Users/YOUR_USERNAME/Development/databricks-mcp
```

#### Schema Access Issues

**Error: "Schema not found" or "Access denied"**

```bash
# Verify schema exists (using CLI)
databricks sql execute --sql "SHOW SCHEMAS IN your_catalog"

# Check your permissions
databricks sql execute --sql "SHOW GRANT ON SCHEMA your_catalog.your_schema"

# Ensure schema name is correct in MCP config:
-s catalog_name.schema_name  # Not catalog_name/schema_name
```

#### Multiple Schema Configuration

**Error: "Only one schema accessible"**

```bash
# Add multiple schemas with multiple -s flags:
claude mcp add --scope user --transport stdio databricks-uc -- \
  uv run unitycatalog-mcp \
  --host https://workspace.cloud.databricks.com \
  --token dapi_token \
  -s catalog1.schema1 \
  -s catalog1.schema2 \
  -s catalog2.schema1
```

### Health Check Commands

```bash
# List configured MCP servers
claude mcp list

# Test manual execution
cd ~/Development/databricks-mcp
uv run unitycatalog-mcp --help

# Verify repository is up to date
git pull origin main
```

### Fallback Options

**If MCP Fails: Use CLI Instead**

CLI is more reliable and works for most use cases:

```bash
# List Unity Catalog objects
databricks catalogs list
databricks schemas list --catalog-name your_catalog

# Use CLI for data access
databricks workspace list /
databricks jobs list
```

**If databrickslabs MCP Fails: Use Managed MCP**

If you have Unity Catalog:
1. Check if workspace supports Managed MCP
2. Configure server URL instead of manual setup
3. No local dependencies required

### Getting Help

- **Managed MCP Documentation:** https://docs.databricks.com/mcp/
- **Managed MCP Support:** Contact Databricks support (covered by SLA)
- **databrickslabs MCP Issues:** https://github.com/databrickslabs/mcp/issues
- **Community support only** (no SLA for databrickslabs)

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
