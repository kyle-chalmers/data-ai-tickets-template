# KAN-4: Query Snowflake INFORMATION_SCHEMA for Metadata Analysis

## Ticket Summary

Query Snowflake's INFORMATION_SCHEMA to analyze column metadata in the SNOWFLAKE_SAMPLE_DATA database.

**Requirements:**
- Total number of columns across all tables
- Column count breakdown by table

---

## Results

### Summary Statistics

- **Total Columns:** 1,838
- **Total Tables:** 133

### Top Tables by Column Count

1. INFORMATION_SCHEMA.COLUMNS - 44 columns
2. INFORMATION_SCHEMA.FUNCTIONS - 37 columns
3. TPCDS_SF100TCL.CATALOG_SALES - 34 columns
4. TPCDS_SF100TCL.WEB_SALES - 34 columns
5. TPCDS_SF10TCL.CATALOG_SALES - 34 columns
6. TPCDS_SF10TCL.WEB_SALES - 34 columns

### Schema Distribution

The SNOWFLAKE_SAMPLE_DATA database contains tables across multiple schemas:
- **INFORMATION_SCHEMA** - System metadata tables
- **TPCDS_SF10TCL** - TPC-DS benchmark dataset (10GB scale)
- **TPCDS_SF100TCL** - TPC-DS benchmark dataset (100GB scale)
- **TPCH_SF1** - TPC-H benchmark dataset (1GB scale)
- **TPCH_SF10** - TPC-H benchmark dataset (10GB scale)
- **TPCH_SF100** - TPC-H benchmark dataset (100GB scale)
- **TPCH_SF1000** - TPC-H benchmark dataset (1TB scale)

---

## Queries Used

Two main queries were executed:

### 1. Total Statistics Query
```sql
SELECT
    COUNT(*) as total_columns,
    COUNT(DISTINCT table_catalog || '.' || table_schema || '.' || table_name) as total_tables
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
```

### 2. Column Count by Table Query
```sql
SELECT
    table_catalog || '.' || table_schema || '.' || table_name as full_table_name,
    table_schema,
    table_name,
    COUNT(*) as column_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
GROUP BY table_catalog, table_schema, table_name
ORDER BY column_count DESC, table_schema, table_name
```

---

## Deliverables

- **Query Results:** Posted to ticket as comment
- **Full Table List:** 133 tables with column counts (see final_deliverables/)
- **Summary Statistics:** Total columns and table count

---

## Status

✅ **Completed** - Analysis delivered to stakeholder
