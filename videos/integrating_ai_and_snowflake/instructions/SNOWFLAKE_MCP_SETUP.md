# Snowflake MCP Setup

Quick setup guide for Snowflake MCP - enables Claude to query and explore Snowflake interactively.

## Prerequisites

Before setting up the MCP server, you need:

1. **Clone the Snowflake MCP repository:**
```bash
cd ~/Development  # or your preferred directory
git clone https://github.com/Snowflake-Labs/mcp.git
cd mcp
```

2. **Install uvx (if not already installed):**
```bash
pip install uv
which uvx  # Note the full path for later
```

> **Note:** The service configuration file (`services/configuration.yaml`) is located in the cloned repository. You'll copy this to create your custom configuration.

## Quick Start (5 minutes)

```bash
# 1. Ensure you're in the MCP repository directory
cd ~/Development/mcp

# 2. Verify uvx is installed
which uvx  # Note the path

# 3. Create service configuration file
mkdir -p ~/.mcp
cp ~/Development/mcp/services/configuration.yaml ~/.mcp/snowflake_config.yaml
# Edit ~/.mcp/snowflake_config.yaml as needed (see Service Configuration File section)

# 4. Add to Claude Code at USER LEVEL (available in all projects)
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8

# 5. Verify
claude mcp list
# Should show: snowflake - ✓ Connected

# 6. Test in Claude Code
# Ask: "List all databases in Snowflake"
```

**Time:** 5-10 minutes | **Scope:** User-level (all projects)

> ⚠️ **Critical:**
> - Clone the Snowflake MCP repository first (contains required configuration template)
> - Use `--scope user` and CLI arguments (`--account`, `--user`) NOT `--connection-name`
> - Create the service configuration file before adding the MCP server

---

## Authentication Options

The Snowflake MCP server supports all authentication methods from the [Snowflake Python Connector](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector-connect). Choose the method that matches your organization's security requirements.

### 1. Private Key Authentication (Recommended for Production)

**Best for:** Production environments, automated workflows, no interactive login required

```bash
# Ensure key is unencrypted
head -1 ~/.snowflake/keys/rsa_key.p8
# Must show: -----BEGIN PRIVATE KEY-----
# NOT: -----BEGIN ENCRYPTED PRIVATE KEY-----

claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8
```

**With encrypted private key:**
```bash
# Set environment variable for key password
export SNOWFLAKE_PRIVATE_KEY_FILE_PWD="your-key-password"

claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/encrypted_key.p8 \
  --private-key-file-pwd "$SNOWFLAKE_PRIVATE_KEY_FILE_PWD"
```

### 2. Multi-Factor Authentication (MFA/2FA)

**Best for:** Enhanced security with time-based one-time passwords (TOTP)

**Option A: Passcode in Password (Most Common)**

When your Snowflake account requires MFA, append the passcode to your password:

```bash
# Format: PASSWORD + MFA_CODE (6 digits)
# Example: If password is "MyPass123" and MFA code is "987654"
# Combined value: "MyPass123987654"

claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --password "YOUR-PASSWORD123456" \
  --role YOUR-ROLE \
  --passcode-in-password
```

**Option B: Separate Passcode Parameter**

```bash
# Set MFA passcode as environment variable
export SNOWFLAKE_PASSCODE="123456"

claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --password YOUR-PASSWORD \
  --passcode "$SNOWFLAKE_PASSCODE" \
  --role YOUR-ROLE
```

**Option C: MFA with Environment Variables**

For better security, use environment variables for credentials:

```bash
# Add to ~/.zshrc or ~/.bashrc
export SNOWFLAKE_ACCOUNT="YOUR-ACCOUNT"
export SNOWFLAKE_USER="YOUR-USER"
export SNOWFLAKE_PASSWORD="YOUR-PASSWORD"
export SNOWFLAKE_PASSCODE="123456"  # Update each session
export SNOWFLAKE_ROLE="YOUR-ROLE"

# Then add MCP server without exposing credentials
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp
```

**MFA Important Notes:**
- MFA passcodes expire quickly (typically 30-60 seconds)
- You'll need to regenerate and update the passcode for each new session
- Consider using SSO or key pair authentication for long-running MCP sessions

### 3. Single Sign-On (SSO)

**Best for:** Organizations using Okta, ADFS, or other SSO providers

```bash
# For externalbrowser SSO (opens browser for authentication)
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --authenticator externalbrowser \
  --role YOUR-ROLE
```

**Supported SSO authenticators:**
- `externalbrowser` - Opens system browser for authentication
- `https://YOUR-OKTA-DOMAIN.okta.com` - Okta SSO
- `https://YOUR-ADFS-DOMAIN/adfs/services/trust` - ADFS

### 4. OAuth Authentication

**Best for:** Applications using OAuth 2.0 tokens

```bash
# Set OAuth token as environment variable
export SNOWFLAKE_OAUTH_TOKEN="your-oauth-token-here"

claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --authenticator oauth \
  --role YOUR-ROLE
```

### 5. Password Authentication (Testing Only)

**Best for:** Local development and testing (NOT recommended for production)

```bash
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --password YOUR-PASSWORD \
  --role YOUR-ROLE
```

### 6. Programmatic Access Token (PAT)

**Best for:** Service accounts and automated workflows

```bash
# PATs use the password parameter
export SNOWFLAKE_PASSWORD="your-pat-token-here"

claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --password "$SNOWFLAKE_PASSWORD" \
  --role YOUR-ROLE
```

**PAT Important Notes:**
- PATs do NOT evaluate secondary roles
- Select appropriate role when creating the PAT
- More secure than password authentication for automated workflows

---

## Service Configuration File

Create a configuration file to enable MCP tools and set SQL permissions. This file is based on the template from the cloned Snowflake MCP repository:

```bash
# Create MCP config directory
mkdir -p ~/.mcp

# Copy the template from the cloned repository and customize
cp ~/Development/mcp/services/configuration.yaml ~/.mcp/snowflake_config.yaml

# OR create a new one with these settings:
cat > ~/.mcp/snowflake_config.yaml << 'EOF'
# Enable the tools you want
other_services:
  object_manager: true    # Database/table/view management
  query_manager: true     # SQL execution
  semantic_manager: true  # Semantic views

# Set SQL permissions - CUSTOMIZE FOR YOUR SECURITY REQUIREMENTS
sql_statement_permissions:
  - Select: true          # Allow SELECT queries
  - Create: true          # Allow CREATE statements
  - Insert: true          # Allow INSERT operations
  - Update: true          # Allow UPDATE operations
  - Drop: false           # RECOMMENDED: Disable DROP for safety
  - Delete: false         # RECOMMENDED: Disable DELETE for safety
  - Alter: true           # Allow ALTER statements
  - Merge: true           # Allow MERGE operations
  - TruncateTable: false  # RECOMMENDED: Disable TRUNCATE for safety
  - Describe: true        # Allow DESCRIBE operations
  - Command: true         # Allow SHOW, GRANT, etc.
  - Comment: true         # Allow COMMENT statements
  - Commit: true          # Allow COMMIT
  - Rollback: true        # Allow ROLLBACK
  - Transaction: true     # Allow BEGIN/END
  - Use: true             # Allow USE DATABASE/SCHEMA
  - Unknown: false        # RECOMMENDED: Block unknown statement types
EOF
```

**Reference this file in your `claude mcp add` command:**
```bash
--service-config-file /Users/YOUR_USERNAME/.mcp/snowflake_config.yaml
```

**Security Best Practices:**
- Start with minimal permissions and add as needed
- Keep `Drop`, `Delete`, and `TruncateTable` set to `false` for safety
- Set `Unknown: false` to block unrecognized SQL statements
- Review the [SQL Execution documentation](https://github.com/Snowflake-Labs/mcp#sql-execution) for more details

---

## Verify Your Configuration

**Check the user-level config file:**
```bash
# Location: ~/.claude.json
cat ~/.claude.json | python3 -m json.tool | grep -A 20 '"mcpServers"'
```

**Should look like:**
```json
{
  "mcpServers": {
    "snowflake": {
      "type": "stdio",
      "command": "/Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx",
      "args": [
        "snowflake-labs-mcp",
        "--account",
        "your-account-id",
        "--user",
        "your-username",
        "--role",
        "YOUR_ROLE",
        "--private-key-file",
        "/Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8"
      ],
      "env": {}
    }
  }
}
```

**Verify connection:**
```bash
claude mcp get snowflake
# Should show:
# Scope: User config (available in all your projects)
# Status: ✓ Connected
```

---

## What MCP Does

Once set up, Claude can:
- Query Snowflake interactively
- Explore tables and schemas
- Analyze results automatically
- Remember context across questions
- Available in **all your Claude Code projects**

**Example conversation:**
```
You: "Show me the schema for ANALYTICS database"
Claude: [Lists schemas and tables]

You: "What tables have customer data?"
Claude: [Searches and finds relevant tables]

You: "Query the top 10 customers by revenue"
Claude: [Executes SQL and shows results]
```

---

## Troubleshooting

### General Connection Issues

**Connection failed:**
```bash
# Remove and re-add with correct credentials
claude mcp remove snowflake -s user
# Then re-add using the appropriate authentication command from above
```

**Find uvx path:**
```bash
which uvx
# Use the full path: /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx
```

**Test MCP server manually with inspector:**
```bash
npx @modelcontextprotocol/inspector \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file ~/.snowflake/keys/rsa_key.p8
```

### Authentication-Specific Issues

**Private Key Authentication Issues:**

Check if key is encrypted:
```bash
head -1 ~/.snowflake/keys/rsa_key.p8
# Should show: -----BEGIN PRIVATE KEY-----
# If shows: -----BEGIN ENCRYPTED PRIVATE KEY----- then decrypt it
```

Decrypt encrypted private key:
```bash
openssl rsa -in encrypted_key.p8 -out rsa_key.p8
# Enter the key password when prompted
```

Verify key format:
```bash
# Key should be in PKCS#8 format, not PKCS#1
# If conversion needed:
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt \
  -in rsa_key_pkcs1.pem -out rsa_key.p8
```

**MFA/2FA Issues:**

MFA passcode expired:
```bash
# MFA codes expire every 30-60 seconds
# Generate a new code and update your configuration
claude mcp remove snowflake -s user
# Re-add with fresh MFA code appended to password
```

Wrong passcode format:
```bash
# Passcode should be 6 digits appended to password
# Correct: "MyPassword123456" (password + 6-digit code)
# Wrong: "MyPassword 123456" (space breaks it)
```

**SSO/OAuth Issues:**

External browser not opening:
```bash
# Check if browser is blocked by firewall
# Try alternative authenticator URL format
--authenticator https://YOUR-SSO-DOMAIN.com
```

OAuth token expired:
```bash
# Regenerate OAuth token through your provider
# Update the environment variable
export SNOWFLAKE_OAUTH_TOKEN="new-token-here"
claude mcp remove snowflake -s user
# Re-add with new token
```

**Account Identifier Issues:**

SSL error with underscores in account name:
```bash
# If account has underscores: acme-marketing_test_account
# Try dashed version: acme-marketing-test-account
--account acme-marketing-test-account
```

**Permission Errors:**

Role doesn't have access:
```bash
# Verify role has necessary permissions in Snowflake
# Try a different role with broader access
--role ACCOUNTADMIN  # or another appropriate role
```

PAT not evaluating secondary roles:
```bash
# PATs only use the role specified when created
# Create a new PAT with the correct role selected
# Cannot be changed after creation
```

### Debug Logging

Enable verbose output to see detailed connection information:
```bash
# Test with verbose logging
uvx snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file ~/.snowflake/keys/rsa_key.p8 \
  --verbose
```

---

## Working Example

**Verified configuration:**
```bash
Account: fivmgcz-mab86679
User: kylechalmers
Role: ACCOUNTADMIN
Auth: JWT (private key)
Scope: User (available in all projects)
Status: ✓ Connected
```

---

## When to Use

**Use MCP for:**
- "Show me the schema"
- "Find outliers in this data"
- Interactive exploration
- Iterative analysis

**Use CLI for:**
- CSV exports
- Large datasets (>10K rows)
- Automation scripts
- Scheduled jobs

---

## Quick Reference Guide

### Authentication Method Selection

| Scenario | Recommended Method | Setup Time | Session Duration |
|----------|-------------------|------------|------------------|
| Production, no user interaction | Private Key Authentication | 10 min (initial) | Permanent |
| Company requires 2FA | MFA with Passcode in Password | 2 min | 30-60 sec |
| Organization uses SSO | SSO (externalbrowser/Okta/ADFS) | 5 min | Session-based |
| Service accounts | PAT or Private Key | 5 min | Until revoked |
| Local testing only | Password Authentication | 1 min | Session-based |
| OAuth-enabled apps | OAuth Token | 5 min | Token expiry |

### Common Command Patterns

**Add MCP server (user-level):**
```bash
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  [AUTH_PARAMETERS]
```

**Remove and re-add:**
```bash
claude mcp remove snowflake -s user
# Then add again with correct parameters
```

**Check status:**
```bash
claude mcp list              # List all MCP servers
claude mcp get snowflake     # Show details for Snowflake server
```

**Test connection:**
```bash
npx @modelcontextprotocol/inspector \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml \
  [AUTH_PARAMETERS]
```

### Authentication Parameters Quick Reference

| Method | Required Parameters | Optional Parameters |
|--------|-------------------|-------------------|
| **Private Key** | `--account`, `--user`, `--role`, `--private-key-file` | `--private-key-file-pwd`, `--warehouse` |
| **MFA/2FA** | `--account`, `--user`, `--password`, `--role`, `--passcode-in-password` | `--passcode`, `--warehouse` |
| **SSO** | `--account`, `--user`, `--authenticator`, `--role` | `--warehouse` |
| **OAuth** | `--account`, `--user`, `--authenticator oauth`, `--role` | `--warehouse` |
| **Password** | `--account`, `--user`, `--password`, `--role` | `--warehouse` |
| **PAT** | `--account`, `--user`, `--password` (PAT), `--role` | `--warehouse` |

### Environment Variables

All authentication methods can use environment variables instead of CLI arguments:

```bash
export SNOWFLAKE_ACCOUNT="your-account"
export SNOWFLAKE_USER="your-username"
export SNOWFLAKE_PASSWORD="your-password"    # For password/PAT auth
export SNOWFLAKE_PASSCODE="123456"          # For MFA
export SNOWFLAKE_ROLE="your-role"
export SNOWFLAKE_WAREHOUSE="your-warehouse"
export SNOWFLAKE_PRIVATE_KEY_FILE="~/.snowflake/keys/rsa_key.p8"
export SNOWFLAKE_PRIVATE_KEY_FILE_PWD="key-password"
export SNOWFLAKE_OAUTH_TOKEN="oauth-token"

# Then add server without explicit credentials
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --service-config-file ~/.mcp/snowflake_config.yaml
```

---

**Config File:** `~/.claude.json` (top-level `mcpServers` key)
**Repository:** https://github.com/Snowflake-Labs/mcp/tree/main
**Documentation:** https://github.com/Snowflake-Labs/mcp#readme
