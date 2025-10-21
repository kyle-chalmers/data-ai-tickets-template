# Snowflake MCP Setup

Quick setup guide for Snowflake MCP - enables Claude to query and explore Snowflake interactively.

## Quick Start (5 minutes)

```bash
# 1. Install uvx
pip install uv
which uvx  # Note the path

# 2. Add to Claude Code at USER LEVEL (available in all projects)
claude mcp add --scope user --transport stdio snowflake -- \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file /Users/YOUR_USERNAME/.snowflake/keys/rsa_key.p8

# 3. Verify
claude mcp list
# Should show: snowflake - ✓ Connected

# 4. Test in Claude Code
# Ask: "List all databases in Snowflake"
```

**Time:** 5 minutes | **Scope:** User-level (all projects)

> ⚠️ **Critical:** Use `--scope user` and CLI arguments (`--account`, `--user`) NOT `--connection-name`

---

## Authentication Options

**Private Key (recommended):**
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

**Password (for testing):**
```bash
claude mcp add --scope user --transport stdio snowflake -- \
  $(which uvx) snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --password YOUR-PASSWORD \
  --role YOUR-ROLE
```

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

**Connection failed:**
```bash
# Remove and re-add with correct credentials
claude mcp remove snowflake -s user
# Then re-add using the command from Quick Start
```

**Decrypt private key (if encrypted):**
```bash
openssl rsa -in encrypted_key.p8 -out rsa_key.p8
```

**Find uvx path:**
```bash
which uvx
# Use the full path: /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx
```

**Test MCP server manually:**
```bash
npx @modelcontextprotocol/inspector \
  /Users/YOUR_USERNAME/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --role YOUR-ROLE \
  --private-key-file ~/.snowflake/keys/rsa_key.p8
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

**Config File:** `~/.claude.json` (top-level `mcpServers` key)
**Docs:** https://github.com/Snowflake-Labs/mcp
