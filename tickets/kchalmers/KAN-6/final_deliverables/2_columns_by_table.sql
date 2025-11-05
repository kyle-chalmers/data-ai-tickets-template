-- KAN-6: Get column count by table in SNOWFLAKE_SAMPLE_DATA
-- Query: Column counts grouped by schema and table
-- Output: Detailed breakdown showing each table's column count

SELECT
    table_schema,
    table_name,
    COUNT(*) as column_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema != 'INFORMATION_SCHEMA'
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name;
