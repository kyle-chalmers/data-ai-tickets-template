# KAN-7: Snowflake INFORMATION_SCHEMA Metadata Analysis Part 2

## Ticket Summary
Query Snowflake's INFORMATION_SCHEMA to analyze metadata in the SNOWFLAKE_SAMPLE_DATA database, excluding INFORMATION_SCHEMA.

## Business Impact
Provides comprehensive understanding of the SNOWFLAKE_SAMPLE_DATA database structure for data discovery and schema documentation, focusing on actual data schemas (TPC-DS, TPC-H benchmarks).

## Key Findings

### Summary (excluding INFORMATION_SCHEMA)
| Metric | Count |
|--------|-------|
| Total Schemas | 6 |
| Total Tables | 80 |
| Total Columns | 1,094 |

### Schema Breakdown
| Schema | Tables | Description |
|--------|--------|-------------|
| TPCDS_SF100TCL | 24 | TPC-DS 100GB scale |
| TPCDS_SF10TCL | 24 | TPC-DS 10GB scale |
| TPCH_SF1 | 8 | TPC-H 1GB scale |
| TPCH_SF10 | 8 | TPC-H 10GB scale |
| TPCH_SF100 | 8 | TPC-H 100GB scale |
| TPCH_SF1000 | 8 | TPC-H 1000GB scale |

### Comparison with KAN-5 (which included INFORMATION_SCHEMA)
| Metric | KAN-5 (with INFO_SCHEMA) | KAN-7 (without) | Difference |
|--------|--------------------------|-----------------|------------|
| Schemas | 7 | 6 | -1 |
| Tables | 134 | 80 | -54 |
| Columns | 1,838 | 1,094 | -744 |

## Deliverables

### Final SQL Queries (numbered for review order)
1. `1_schema_count.sql` - Total schema count
2. `2_table_counts.sql` - Total tables and tables by schema
3. `3_column_counts.sql` - Total columns and columns by table

### Final Results (CSV outputs)
1. `1_schema_count.csv` - Total schemas (6)
2. `2_table_counts.csv` - Tables by schema (80 total)
3. `3_column_counts.csv` - Columns by table (1,094 total)

## Methodology

1. **Connected to Snowflake** using JWT authentication via Snowflake CLI
2. **Queried INFORMATION_SCHEMA.TABLES** for schema and table counts
3. **Queried INFORMATION_SCHEMA.COLUMNS** for column counts
4. **Filtered out INFORMATION_SCHEMA** using `WHERE table_schema <> 'INFORMATION_SCHEMA'`
5. **Exported results** to CSV format

## Technical Notes

- Database: SNOWFLAKE_SAMPLE_DATA
- Authentication: SNOWFLAKE_JWT (RSA key-based)
- Output Format: CSV with headers
- Tool: Snowflake CLI (`snow sql`)

## Assumptions

1. **INFORMATION_SCHEMA Exclusion**: Interpreted "Do not include the info schema" as excluding `table_schema = 'INFORMATION_SCHEMA'`
   - **Reasoning**: Ticket explicitly requested exclusion
   - **Impact**: Results show only TPC-DS and TPC-H benchmark data schemas

2. **Scope**: Analysis limited to SNOWFLAKE_SAMPLE_DATA database only
   - **Reasoning**: Ticket specified "Snowflake Sample Data database"
   - **Impact**: Results represent only this database, not the entire Snowflake account

3. **Metrics Included**: All three levels of metadata (schemas, tables, columns)
   - **Reasoning**: Ticket mentioned "tables and schemas" but also columns
   - **Impact**: Comprehensive metadata view at all levels

## Quality Control

- [x] Verified CSV outputs contain proper headers
- [x] Confirmed total column count (1,094) matches sum of per-table counts
- [x] Confirmed total table count (80) matches sum of per-schema counts: 24+24+8+8+8+8=80
- [x] Validated INFORMATION_SCHEMA is excluded from all results
- [x] All SQL queries tested and executable

## Files Organization

```
KAN-7/
├── README.md (this file)
├── final_deliverables/
│   ├── 1_schema_count.sql
│   ├── 1_schema_count.csv
│   ├── 2_table_counts.sql
│   ├── 2_table_counts.csv
│   ├── 3_column_counts.sql
│   └── 3_column_counts.csv
├── exploratory_analysis/
└── source_materials/
```
