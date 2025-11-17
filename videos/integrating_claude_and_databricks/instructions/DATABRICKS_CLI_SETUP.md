# Databricks CLI Setup

Quick setup guide for the Databricks CLI (`databricks`) - the official way to manage workspaces, run SQL queries, and automate Databricks operations.

## Quick Start

```bash
# Install
brew tap databricks/tap
brew install databricks

# Verify installation
databricks --version
# Output: Databricks CLI v0.277.0

# Configure (OAuth - recommended)
databricks configure

# Test connection
databricks auth profiles
databricks workspace list

# Use it
databricks sql execute --sql "SELECT CURRENT_USER()"
databricks jobs list
databricks clusters list
```

**Time:** 5 minutes | **Use for:** SQL queries, job management, workspace operations, automation

---

## Authentication Options

**Choose one:**

| Method | Setup Command | Best For |
|--------|---------------|----------|
| **OAuth** (recommended) | `databricks configure` | Interactive workflows, modern auth |
| **Personal Access Token (PAT)** | Manual `~/.databrickscfg` edit | Automation, CI/CD pipelines |

### OAuth Setup (Recommended)

```bash
# Interactive configuration
databricks configure

# Follow prompts:
# 1. Enter workspace URL: https://your-workspace.cloud.databricks.com
# 2. Choose "OAuth" for auth type
# 3. Browser window opens for authentication
# 4. Configuration saved to ~/.databrickscfg
```

### Personal Access Token Setup

```bash
# Create ~/.databrickscfg manually
cat > ~/.databrickscfg << 'EOF'
[DEFAULT]
host = https://your-workspace.cloud.databricks.com
token = dapi1234567890abcdef

[biprod]
host = https://prod-workspace.cloud.databricks.com
token = dapi_prod_token_here

[bidev]
host = https://dev-workspace.cloud.databricks.com
token = dapi_dev_token_here
EOF

# Secure the config file
chmod 600 ~/.databrickscfg
```

**Generate PAT in Databricks:**
1. User Settings → Developer → Access Tokens
2. Click "Generate New Token"
3. Set expiration and comment
4. Copy token (only shown once!)

---

## Profile Management

```bash
# List all configured profiles
databricks auth profiles

# Test a specific profile
databricks auth env --profile biprod

# Set environment variable to use specific profile
export DATABRICKS_CONFIG_PROFILE=biprod

# Or use --profile flag with each command
databricks workspace list --profile biprod
```

---

## Common Commands

### SQL Queries

```bash
# Execute SQL query
databricks sql execute --sql "SELECT * FROM catalog.schema.table LIMIT 10"

# Execute with specific profile
databricks sql execute --profile biprod \
  --sql "SELECT COUNT(*) FROM sales_data"

# List SQL warehouses
databricks sql warehouses list

# Get warehouse details
databricks sql warehouses get --warehouse-id abc123
```

### Workspace Management

```bash
# List workspace contents
databricks workspace list /Workspace/Users

# Export notebook
databricks workspace export /path/to/notebook output.ipynb

# Import notebook
databricks workspace import local_notebook.py /Workspace/path/to/notebook

# List all workspace objects
databricks workspace ls /
```

### Job Management

```bash
# List all jobs
databricks jobs list

# Get job details
databricks jobs get --job-id 12345

# Run a job now
databricks jobs run-now --job-id 12345

# Create job from JSON config
databricks jobs create --json-file job_config.json

# Delete a job
databricks jobs delete --job-id 12345
```

### Cluster Operations

```bash
# List clusters
databricks clusters list

# Get cluster details
databricks clusters get --cluster-id abc-123-def456

# Start a cluster
databricks clusters start --cluster-id abc-123-def456

# Stop a cluster
databricks clusters delete --cluster-id abc-123-def456
```

### File System (DBFS)

```bash
# List files in DBFS
databricks fs ls dbfs:/mnt/data

# Copy local file to DBFS
databricks fs cp local-file.csv dbfs:/mnt/data/

# Download file from DBFS
databricks fs cp dbfs:/mnt/data/file.csv ./local-file.csv

# Read file contents
databricks fs cat dbfs:/mnt/data/file.txt
```

---

## Configuration File Location

```bash
# View configuration file
cat ~/.databrickscfg

# Example format:
# [DEFAULT]
# host = https://workspace.cloud.databricks.com
# token = dapi1234567890

# [biprod]
# host = https://prod.cloud.databricks.com
# auth_type = oauth

# [bidev]
# host = https://dev.cloud.databricks.com
# auth_type = oauth
```

---

## Troubleshooting

### Authentication Errors

**Error: "Authentication failed"**

```bash
# Verify CLI version (must be v0.205+)
databricks --version

# Test authentication
databricks auth profiles
databricks auth env --profile biprod

# Solution 1: Regenerate OAuth token
databricks configure

# Solution 2: Verify workspace URL (no trailing slash)
# ✓ Correct: https://workspace.cloud.databricks.com
# ✗ Incorrect: https://workspace.cloud.databricks.com/

# Solution 3: Check config file permissions
chmod 600 ~/.databrickscfg
ls -l ~/.databrickscfg  # Should show: -rw-------
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

### Network Issues

**Error: "Connection timeout" or "Unable to reach"**

```bash
# Test basic connectivity
ping your-workspace.cloud.databricks.com

# Test HTTPS access
curl -I https://your-workspace.cloud.databricks.com

# If behind corporate proxy:
export HTTPS_PROXY=http://proxy.company.com:8080
```

### SSL Certificate Errors

**Error: "SSL certificate verify failed"**

```bash
# Update certificates (macOS)
/Applications/Python\ 3.x/Install\ Certificates.command

# Or update system certificates
brew install ca-certificates

# Temporary workaround (NOT recommended for production):
export DATABRICKS_INSECURE=true
```

### Finding Your Workspace URL

1. Log into Databricks web UI
2. Copy URL from browser (e.g., `https://adb-1234567890.12.azuredatabricks.net`)
3. Remove any path after `.net` or `.com`
4. Use this as your `host` value

### Health Check Commands

```bash
# Version check
databricks --version  # Expected: v0.277.0 or newer

# List profiles
databricks auth profiles

# Test authentication
databricks auth env --profile biprod

# Test simple command
databricks workspace ls /
```

### Debug Mode

```bash
# Enable verbose output
export DATABRICKS_DEBUG_TRUNCATE_BYTES=100000
export DATABRICKS_DEBUG_HEADERS=true

# Re-run failing command with verbose flag
databricks workspace list -v
```

### Regular Maintenance

```bash
# Update CLI monthly
brew upgrade databricks

# Verify updated version
databricks --version

# Rotate tokens every 90 days
# 1. Generate new PAT in Databricks UI
# 2. Update ~/.databrickscfg

# Backup configuration
cp ~/.databrickscfg ~/.databrickscfg.backup
```

---

## Advanced: Databricks SQL CLI

For dedicated SQL operations, consider the `databricks-sql-cli` tool:

```bash
# Install (separate tool)
pip install databricks-sql-cli

# Execute SQL with OAuth
dbsqlcli \
  -e "SELECT * FROM default.diamonds LIMIT 10" \
  --hostname "your-workspace.cloud.databricks.com" \
  --http-path "/sql/1.0/warehouses/abc123" \
  --oauth

# Get http-path from: SQL → Warehouses → Connection Details
```

---

## Important Notes

### Current vs Legacy CLI

**IMPORTANT:** Use the current CLI (v0.205+) installed via Homebrew, NOT the deprecated `pip install databricks-cli` (v0.18).

| CLI | Version | Installation | Status |
|-----|---------|--------------|--------|
| **Current** | v0.277.0+ | `brew install databricks` | ✓ Supported |
| **Legacy** | v0.18.x | `pip install databricks-cli` | ✗ Deprecated |

### Token Expiration

- OAuth tokens: Expire after 1 hour, auto-refresh with CLI
- Personal Access Tokens: Set expiration when creating (max 90 days for some orgs)
- CLI handles OAuth refresh automatically for interactive commands

### Profile Safety

Always use `--profile` flag for production operations to avoid accidental operations on wrong workspace:

```bash
# Safe - explicit profile
databricks jobs delete --job-id 123 --profile biprod

# Risky - uses DEFAULT profile
databricks jobs delete --job-id 123
```

---

**Next:** [Compare CLI vs MCP](../databricks_cli_v_mcp_comparison/DATABRICKS_CLI_VS_MCP.md) | **Docs:** https://docs.databricks.com/dev-tools/cli/
