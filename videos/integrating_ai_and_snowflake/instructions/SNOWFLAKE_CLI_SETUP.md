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

## Setting Up PII Schemas (Optional)

If your Snowflake environment doesn't already have dedicated schemas for sensitive data, a common pattern uses two: `RAW_PII` for actual sensitive values (data engineering only), and `CURATED_PII` for masked or anonymized versions safe for analyst access.

```bash
# Create the schemas
snow sql -q "CREATE SCHEMA IF NOT EXISTS YOUR_DATABASE.RAW_PII COMMENT = 'Raw PII values, restricted access only'"
snow sql -q "CREATE SCHEMA IF NOT EXISTS YOUR_DATABASE.CURATED_PII COMMENT = 'Masked PII, safe for analyst access'"

# Lock down RAW_PII to data engineering
snow sql -q "GRANT USAGE ON SCHEMA YOUR_DATABASE.RAW_PII TO ROLE DATA_ENGINEERING_ROLE"
snow sql -q "GRANT SELECT ON ALL TABLES IN SCHEMA YOUR_DATABASE.RAW_PII TO ROLE DATA_ENGINEERING_ROLE"
snow sql -q "GRANT SELECT ON FUTURE TABLES IN SCHEMA YOUR_DATABASE.RAW_PII TO ROLE DATA_ENGINEERING_ROLE"

# Grant analysts read access to CURATED_PII
snow sql -q "GRANT USAGE ON SCHEMA YOUR_DATABASE.CURATED_PII TO ROLE ANALYST_ROLE"
snow sql -q "GRANT SELECT ON ALL TABLES IN SCHEMA YOUR_DATABASE.CURATED_PII TO ROLE ANALYST_ROLE"
snow sql -q "GRANT SELECT ON FUTURE TABLES IN SCHEMA YOUR_DATABASE.CURATED_PII TO ROLE ANALYST_ROLE"

# Verify both schemas
snow sql -q "SHOW SCHEMAS IN DATABASE YOUR_DATABASE" --format csv
```

`RAW_PII` holds real values for data engineering. `CURATED_PII` holds masked values for analysts. The `FUTURE TABLES` grants ensure new tables added later inherit the same access rules.

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
