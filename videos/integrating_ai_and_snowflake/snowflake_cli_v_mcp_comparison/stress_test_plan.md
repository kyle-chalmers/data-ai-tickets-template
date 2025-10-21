# Snowflake CLI vs MCP Stress Test

Testing the practical limits of Snowflake CLI and MCP with real data.

## Available Tables (Largest First)

| Table | Rows | Size |
|-------|------|------|
| TPCDS_SF100TCL.STORE_SALES | 288.0 billion | 10.6 TB |
| TPCDS_SF100TCL.CATALOG_SALES | 144.0 billion | 9.5 TB |
| TPCDS_SF100TCL.WEB_SALES | 72.0 billion | 4.8 TB |
| TPCDS_SF10TCL.STORE_SALES | 28.8 billion | 1.2 TB |
| TPCH_SF1000.LINEITEM | 6.0 billion | 159 GB |

## Test Plan

### Test 1: Small (100 rows)
**Expected:** Both work fine

### Test 2: Medium (10,000 rows)
**Expected:** Both work, MCP might start showing context usage

### Test 3: Large (100,000 rows)
**Expected:** CLI fine, MCP approaching context limits

### Test 4: Very Large (1,000,000 rows)
**Expected:** CLI fine, MCP likely hits context limit

### Test 5: Massive (10,000,000+ rows)
**Expected:** CLI fine with streaming, MCP cannot handle

---

## Running Tests...
