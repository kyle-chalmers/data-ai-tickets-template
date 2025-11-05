-- KAN-5: Column count by table in SNOWFLAKE_SAMPLE_DATA
-- This query returns the number of columns for each table, grouped by schema

SELECT
    table_schema,
    table_name,
    COUNT(*) as column_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name;

-- Returns 134 tables with their respective column counts
-- Schemas included: INFORMATION_SCHEMA, TPCDS_SF100TCL, TPCDS_SF10TCL, TPCH_SF1, TPCH_SF10, TPCH_SF100, TPCH_SF1000
