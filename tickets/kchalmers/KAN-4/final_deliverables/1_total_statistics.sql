-- KAN-4: Total Column and Table Statistics
-- Query Snowflake INFORMATION_SCHEMA for metadata analysis

SELECT
    COUNT(*) as total_columns,
    COUNT(DISTINCT table_catalog || '.' || table_schema || '.' || table_name) as total_tables
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS;

-- Results:
-- Total Columns: 1,838
-- Total Tables: 133
