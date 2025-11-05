# KAN-5: Snowflake INFORMATION_SCHEMA Metadata Analysis

## Ticket Summary
Query Snowflake's INFORMATION_SCHEMA to analyze column metadata in the SNOWFLAKE_SAMPLE_DATA database.

## Business Impact
Provides comprehensive understanding of the SNOWFLAKE_SAMPLE_DATA database structure, enabling better data discovery and schema documentation.

## Key Findings

### Total Columns
- **1,838 total columns** across all schemas and tables in SNOWFLAKE_SAMPLE_DATA

### Schema Breakdown
- **INFORMATION_SCHEMA**: 54 tables (metadata tables)
- **TPCDS_SF100TCL**: 24 tables (TPC-DS 100GB scale)
- **TPCDS_SF10TCL**: 24 tables (TPC-DS 10GB scale)
- **TPCH_SF1**: 8 tables (TPC-H 1GB scale)
- **TPCH_SF10**: 8 tables (TPC-H 10GB scale)
- **TPCH_SF100**: 8 tables (TPC-H 100GB scale)
- **TPCH_SF1000**: 8 tables (TPC-H 1000GB scale)

## Deliverables

### Final SQL Queries (numbered for review order)
1. `1_total_columns.sql` - Total column count query
2. `2_columns_by_table.sql` - Column count grouped by schema and table
3. `3_metadata_export.sql` - Complete metadata export with data types

### Final Results (CSV outputs)
1. `1_total_columns.csv` - Total count result (1,838 columns)
2. `2_columns_by_table.csv` - Breakdown by table (134 tables)

### Exploratory Analysis
- `column_metadata.csv` - Raw metadata export from INFORMATION_SCHEMA

## Methodology

1. **Connected to Snowflake** using JWT authentication via Snowflake CLI
2. **Queried INFORMATION_SCHEMA.COLUMNS** for comprehensive column metadata
3. **Aggregated results** to calculate total columns and columns by table
4. **Exported results** to CSV format for easy review

## Technical Notes

- Database: SNOWFLAKE_SAMPLE_DATA
- Authentication: SNOWFLAKE_JWT (RSA key-based)
- Output Format: CSV with headers
- Tool: Snowflake CLI (`snow sql`)

## Assumptions

1. **Scope**: Analysis limited to SNOWFLAKE_SAMPLE_DATA database only
   - **Reasoning**: Ticket specified "Snowflake Sample Data database"
   - **Context**: SNOWFLAKE_SAMPLE_DATA is a standard Snowflake sample database
   - **Impact**: Results represent only this database, not the entire Snowflake account

2. **Schema Inclusion**: All schemas within SNOWFLAKE_SAMPLE_DATA included
   - **Reasoning**: No schema-level filters specified in requirements
   - **Context**: Includes both INFORMATION_SCHEMA and data schemas (TPC-DS, TPC-H)
   - **Impact**: Comprehensive view of all available schemas

## Quality Control

- Verified CSV outputs contain proper headers
- Confirmed total column count matches detailed breakdown
- Validated query syntax and results
- All SQL queries tested and executable

## Files Organization

```
KAN-5/
├── README.md (this file)
├── CLAUDE.md (analysis context)
├── final_deliverables/
│   ├── 1_total_columns.sql
│   ├── 1_total_columns.csv
│   ├── 2_columns_by_table.sql
│   ├── 2_columns_by_table.csv
│   └── 3_metadata_export.sql
├── exploratory_analysis/
│   └── column_metadata.csv
└── source_materials/
    (empty - no source files provided)
```
