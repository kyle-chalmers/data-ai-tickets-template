# Snowflake CLI Setup

Quick setup guide for the Snowflake CLI (`snow`) - the simplest way to query Snowflake and export data.

## Quick Start

```bash
# Install
brew install snowflake-cli

# Configure (password auth - easiest)
snow connection add \
  --connection-name prod \
  --account YOUR-ACCOUNT \
  --user YOUR-USER \
  --password \
  --role YOUR-ROLE

# Test
snow connection test -c prod

# Use it
snow sql -q "SELECT CURRENT_USER()"
snow sql -q "SELECT * FROM customers" --format csv > data.csv
```

**Time:** 2 minutes | **Use for:** CSV exports, large datasets, automation

---

## Authentication Options

**Choose one:**

| Method | Command | Best For |
|--------|---------|----------|
| **Password** (easiest) | `snow connection add --connection-name prod --account X --user Y --password --role Z` | Getting started |
| **Private Key** | Add `--authenticator SNOWFLAKE_JWT --private-key-path ~/.snowflake/keys/rsa_key.p8` | Production |
| **SSO** | Add `--authenticator externalbrowser` | SSO orgs |

---

## Common Commands

```bash
# Export to CSV
snow sql -q "SELECT * FROM table" --format csv > data.csv

# Run SQL file
snow sql -f query.sql --format csv > results.csv

# Interactive SQL
snow sql

# Connection management
snow connection list
snow connection test -c prod
snow connection set-default prod
```

---

## Troubleshooting

**Connection fails:**
```bash
snow connection test -c prod --verbose
```

**Private key encrypted:**
```bash
openssl rsa -in encrypted_key.p8 -out rsa_key.p8
```

**See all connections:**
```bash
cat ~/.snowflake/config.toml
```

---

**Next:** [Compare CLI vs MCP](../SNOWFLAKE_CLI_VS_MCP.md) | **Docs:** https://docs.snowflake.com/cli
