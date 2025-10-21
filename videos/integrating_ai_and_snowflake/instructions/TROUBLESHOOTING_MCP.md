# Troubleshooting Snowflake MCP

Quick fixes for common MCP connection issues.

## Connection Failure

If you see "Failed to connect" when running `/mcp`:

### 1. Restart Claude Code
The simplest fix - close and reopen Claude Code terminal.

### 2. Test MCP Manually
```bash
/Users/kylechalmers/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --account fivmgcz-mab86679 \
  --user kylechalmers \
  --role ACCOUNTADMIN \
  --private-key-file ~/.snowflake/keys/rsa_key.p8
```

If this hangs or errors, the issue is with MCP itself, not Claude Code.

### 3. Verify Private Key
```bash
head -1 ~/.snowflake/keys/rsa_key.p8
# Must show: -----BEGIN PRIVATE KEY-----
```

### 4. Check MCP Config
```bash
cat ~/.claude.json | grep -A 15 mcpServers
```

Should show your Snowflake MCP config with CLI arguments.

### 5. Remove and Re-add
```bash
claude mcp remove snowflake -s user
claude mcp add --transport stdio snowflake -s user -- \
  /Users/kylechalmers/Library/Python/3.9/bin/uvx snowflake-labs-mcp \
  --account fivmgcz-mab86679 \
  --user kylechalmers \
  --role ACCOUNTADMIN \
  --private-key-file ~/.snowflake/keys/rsa_key.p8
```

## Fallback: Use CLI Instead

If MCP continues to fail, you can still use Snowflake CLI:

```bash
snow sql -q "SELECT CURRENT_USER()"
```

CLI is more reliable and handles larger datasets anyway!

---

**Your Config Location:** `~/.claude.json` (global, works in all repos)
