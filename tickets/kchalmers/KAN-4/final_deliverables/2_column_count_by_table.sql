-- KAN-4: Column Count by Table
-- Get detailed breakdown of columns per table in SNOWFLAKE_SAMPLE_DATA

SELECT
    table_catalog || '.' || table_schema || '.' || table_name as full_table_name,
    table_schema,
    table_name,
    COUNT(*) as column_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
GROUP BY table_catalog, table_schema, table_name
ORDER BY column_count DESC, table_schema, table_name;

-- Returns 133 rows showing all tables with their column counts
-- Ordered by: column_count (descending), then schema and table name
