-- KAN-7: Column counts in SNOWFLAKE_SAMPLE_DATA (excluding INFORMATION_SCHEMA)

-- Total columns
SELECT COUNT(*) as total_columns
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema <> 'INFORMATION_SCHEMA';

-- Columns by table
SELECT
    table_schema,
    table_name,
    COUNT(*) as column_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema != 'INFORMATION_SCHEMA'
GROUP BY table_schema, table_name
ORDER BY table_schema, table_name;
