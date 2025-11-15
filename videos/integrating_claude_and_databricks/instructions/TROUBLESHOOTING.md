# Troubleshooting Databricks CLI and MCP

Quick fixes for common Databricks CLI and MCP connection issues.

---

## Databricks CLI Issues

### Connection Failure

**Error: "Authentication failed"**

```bash
# Verify CLI version (must be v0.205+)
databricks --version

# Test authentication
databricks auth profiles
databricks auth env --profile biprod
```

**Solutions:**

1. **Regenerate OAuth token:**
```bash
databricks configure
# Follow prompts to re-authenticate
```

2. **Verify workspace URL (no trailing slash):**
```bash
# ✓ Correct
host = https://workspace.cloud.databricks.com

# ✗ Incorrect
host = https://workspace.cloud.databricks.com/
```

3. **Check config file permissions:**
```bash
chmod 600 ~/.databrickscfg
ls -l ~/.databrickscfg
# Should show: -rw-------
```

### Token Expired

**Error: "Token is invalid or expired"**

```bash
# For OAuth (recommended):
databricks configure

# For PAT - generate new token:
# 1. Databricks UI → User Settings → Developer → Access Tokens
# 2. Generate New Token
# 3. Update ~/.databrickscfg with new token
```

### Wrong CLI Version

**Error: "Command not found" or outdated version**

```bash
# Check current version
databricks --version

# Uninstall old pip-based CLI (if installed)
pip uninstall databricks-cli

# Install correct version via Homebrew
brew tap databricks/tap
brew install databricks

# Update existing installation
brew upgrade databricks
```

### Profile Not Found

**Error: "Profile not found"**

```bash
# List all profiles
databricks auth profiles

# Set default profile
export DATABRICKS_CONFIG_PROFILE=biprod

# Or always use --profile flag
databricks workspace list --profile biprod
```

### Permission Denied

**Error: "User does not have permission"**

```bash
# Verify your permissions in Databricks UI
# Workspace Settings → Users & Groups → Your User

# Common missing permissions:
# - Workspace access
# - SQL warehouse access
# - Cluster permissions

# Contact workspace admin to grant necessary permissions
```

---

## Managed MCP Issues

### Unity Catalog Not Enabled

**Error: "Unity Catalog is not enabled for this workspace"**

**Solution:**
- Managed MCP requires Unity Catalog
- Check with workspace administrator
- Verify: Workspace Settings → Catalog → Unity Catalog status
- Consider using CLI or databrickslabs MCP as alternative

### Insufficient Permissions

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

### Server URL Configuration

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

---

## databrickslabs MCP Issues

### Connection Failure

If you see "Failed to connect" when using databrickslabs MCP:

#### 1. Restart Claude Code
The simplest fix - close and reopen Claude Code terminal.

#### 2. Test MCP Manually

```bash
# Navigate to mcp repository
cd ~/Development/mcp

# Test manually
uv run unitycatalog-mcp \
  --host https://your-workspace.cloud.databricks.com \
  --token dapi_your_token_here \
  -s your_catalog.your_schema
```

If this hangs or errors, the issue is with MCP itself, not Claude Code.

#### 3. Verify Dependencies

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

#### 4. Check MCP Configuration

```bash
# View Claude Code MCP config
cat ~/.claude.json | jq '.mcpServers'

# Or list MCP servers
claude mcp list
# Should show: databricks-uc - ✓ Connected (or error message)
```

#### 5. Verify Token

```bash
# Test token works
curl -H "Authorization: Bearer dapi_your_token_here" \
  https://your-workspace.cloud.databricks.com/api/2.0/clusters/list

# Should return JSON (not 401 error)
```

#### 6. Remove and Re-add MCP

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

### Python Version Issues

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

### Repository Issues

**Error: "unitycatalog-mcp not found"**

```bash
# Clone or update repository
cd ~/Development
git clone https://github.com/databrickslabs/mcp.git
cd mcp

# Or update existing
cd ~/Development/mcp
git pull origin main

# Verify you're in correct directory when running
pwd
# Should show: /Users/YOUR_USERNAME/Development/mcp
```

### Schema Access Issues

**Error: "Schema not found" or "Access denied"**

```bash
# Verify schema exists
databricks sql execute --sql "SHOW SCHEMAS IN your_catalog"

# Check your permissions
databricks sql execute --sql "SHOW GRANT ON SCHEMA your_catalog.your_schema"

# Ensure schema name is correct in MCP config:
-s catalog_name.schema_name  # Not catalog_name/schema_name
```

### Multiple Schema Configuration

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

---

## Common Issues (All Tools)

### Network Connectivity

**Error: "Connection timeout" or "Unable to reach"**

```bash
# Test basic connectivity
ping your-workspace.cloud.databricks.com

# Test HTTPS access
curl -I https://your-workspace.cloud.databricks.com

# Check firewall/VPN settings
# Ensure ports 443 (HTTPS) is open

# If behind corporate proxy, configure:
export HTTPS_PROXY=http://proxy.company.com:8080
```

### SSL Certificate Issues

**Error: "SSL certificate verify failed"**

```bash
# Update certificates (macOS)
/Applications/Python\ 3.x/Install\ Certificates.command

# Or temporarily disable (NOT recommended for production):
export DATABRICKS_INSECURE=true

# Better solution: Update system certificates
brew install ca-certificates
```

### Environment Variables

**Verify environment setup:**

```bash
# Check all Databricks-related env vars
env | grep -i databricks

# Common variables:
DATABRICKS_CONFIG_PROFILE=biprod
DATABRICKS_HOST=https://workspace.cloud.databricks.com
DATABRICKS_TOKEN=dapi_...
```

---

## Diagnostic Commands

### CLI Health Check

```bash
# Version check
databricks --version
# Expected: v0.277.0 or newer

# List profiles
databricks auth profiles

# Test authentication
databricks auth env --profile biprod

# Test simple command
databricks workspace ls /
```

### MCP Health Check (databrickslabs)

```bash
# List configured MCP servers
claude mcp list

# Test manual execution
cd ~/Development/mcp
uv run unitycatalog-mcp --help

# Verify repository is up to date
git pull origin main
```

### Workspace Connectivity

```bash
# Test API access
curl -H "Authorization: Bearer $(cat ~/.databrickscfg | grep token | cut -d' ' -f3)" \
  https://your-workspace.cloud.databricks.com/api/2.0/clusters/list

# Should return JSON with cluster list (or empty list if no clusters)
```

---

## Fallback Options

### If MCP Fails: Use CLI Instead

CLI is more reliable and works for most use cases:

```bash
# Execute SQL queries
databricks sql execute --sql "SELECT * FROM catalog.schema.table"

# List Unity Catalog objects
databricks sql execute --sql "SHOW CATALOGS"
databricks sql execute --sql "SHOW SCHEMAS IN catalog_name"
databricks sql execute --sql "SHOW TABLES IN catalog.schema"
```

### If CLI OAuth Fails: Use PAT

```bash
# Generate Personal Access Token in UI
# User Settings → Developer → Access Tokens → Generate New Token

# Update ~/.databrickscfg:
[profile_name]
host = https://workspace.cloud.databricks.com
token = dapi_your_new_token_here

# Remove auth_type line if present
```

### If databrickslabs MCP Fails: Use Managed MCP

If you have Unity Catalog:
1. Check if workspace supports Managed MCP
2. Configure server URL instead of manual setup
3. No local dependencies required

---

## Getting Additional Help

### Databricks CLI
- Documentation: https://docs.databricks.com/dev-tools/cli/
- GitHub Issues: https://github.com/databricks/cli/issues
- Community Forums: https://community.databricks.com

### Managed MCP
- Documentation: https://docs.databricks.com/mcp/
- Support: Contact Databricks support (covered by SLA)

### databrickslabs MCP
- GitHub Issues: https://github.com/databrickslabs/mcp/issues
- Community support only (no SLA)

### Debug Mode

**Enable verbose output:**

```bash
# CLI debug mode
export DATABRICKS_DEBUG_TRUNCATE_BYTES=100000
export DATABRICKS_DEBUG_HEADERS=true

# Re-run failing command
databricks workspace list -v

# View detailed logs
```

---

## Prevention Tips

### Regular Maintenance

```bash
# Update CLI monthly
brew upgrade databricks

# Rotate tokens every 90 days
# Generate new PAT in Databricks UI
# Update ~/.databrickscfg

# Keep databrickslabs MCP updated
cd ~/Development/mcp
git pull origin main
```

### Configuration Backup

```bash
# Backup Databricks config
cp ~/.databrickscfg ~/.databrickscfg.backup

# Backup Claude MCP config
cp ~/.claude.json ~/.claude.json.backup
```

### Testing After Changes

```bash
# After updating CLI
databricks --version
databricks auth profiles

# After changing MCP config
claude mcp list
# Test in Claude Code with simple query
```

---

**Still having issues?** Check the [setup guides](./README.md) or consult Databricks documentation.
