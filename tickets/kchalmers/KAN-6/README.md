# KAN-6: Snowflake INFORMATION_SCHEMA Metadata Analysis

## Ticket Summary
Query Snowflake's INFORMATION_SCHEMA to analyze column counts in the SNOWFLAKE_SAMPLE_DATA database.

## Business Context
This analysis provides metadata insights into the structure of Snowflake's sample data, helping understand the complexity and schema design of the available datasets for testing and development purposes.

## Key Findings

### Total Column Count
**1,838 total columns** across all tables in SNOWFLAKE_SAMPLE_DATA (including INFORMATION_SCHEMA).

### Schema Breakdown
The database contains 7 schemas with the following distribution:

| Schema | Tables | Columns |
|--------|--------|---------|
| INFORMATION_SCHEMA | 53 | 744 |
| TPCDS_SF100TCL | 24 | 425 |
| TPCDS_SF10TCL | 24 | 425 |
| TPCH_SF1 | 8 | 61 |
| TPCH_SF10 | 8 | 61 |
| TPCH_SF100 | 8 | 61 |
| TPCH_SF1000 | 8 | 61 |
| **Total** | **133** | **1,838** |

### Dataset Types
- **INFORMATION_SCHEMA**: System metadata views with 53 tables documenting database objects, permissions, and configuration
- **TPC-DS (Transaction Processing Performance Council Decision Support)**: 2 schemas with 24 tables each, 425 columns per schema
- **TPC-H (Transaction Processing Performance Council Benchmark H)**: 4 schemas with 8 tables each, 61 columns per schema

## Deliverables

### SQL Queries (in review order)
1. **1_total_column_count.sql** - Total column count query
2. **2_columns_by_table.sql** - Detailed breakdown by table
3. **3_columns_by_schema.sql** - Summary by schema

### CSV Results
1. **1_total_column_count.csv** - Single total (1,838 columns)
2. **2_columns_by_table_133_tables.csv** - All 133 tables with column counts
3. **3_columns_by_schema_7_schemas.csv** - Schema-level summary (7 schemas)

## Methodology

### Data Source
- Database: `SNOWFLAKE_SAMPLE_DATA`
- System View: `INFORMATION_SCHEMA.COLUMNS`
- Scope: All schemas included (INFORMATION_SCHEMA + data schemas)

### Analysis Approach
1. Queried INFORMATION_SCHEMA.COLUMNS for all table metadata
2. Aggregated column counts at three levels:
   - Total database level
   - Individual table level
   - Schema summary level
3. Sorted results by schema and table name for clarity

## Assumptions Made

1. **Schema Inclusion**: INFORMATION_SCHEMA is included in the analysis as it is part of the SNOWFLAKE_SAMPLE_DATA database
   - **Reasoning**: Complete metadata analysis should include all schemas, including system views
   - **Context**: INFORMATION_SCHEMA provides valuable metadata about database structure and objects
   - **Impact**: Total count includes both data tables (TPC-DS and TPC-H) and system metadata views

2. **Column Count Definition**: Each column counted once per table, regardless of data type or constraints
   - **Reasoning**: Standard metadata analysis counts all columns equally
   - **Context**: INFORMATION_SCHEMA.COLUMNS provides comprehensive column metadata
   - **Impact**: Simple, accurate count suitable for structural analysis

## Technical Notes

### Tools Used
- Snowflake MCP Server for direct metadata queries
- Atlassian MCP Server for Jira integration
- Standard SQL queries against INFORMATION_SCHEMA

### Query Performance
All queries executed efficiently using metadata views (no data scanning required).

## Related Tickets
- **KAN-5**: CLIs - Query Snowflake INFORMATION_SCHEMA for metadata analysis (cloned from)
