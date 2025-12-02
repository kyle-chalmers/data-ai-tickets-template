-- KAN-7: Table counts in SNOWFLAKE_SAMPLE_DATA (excluding INFORMATION_SCHEMA)

-- Total tables
SELECT COUNT(*) as total_tables
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.TABLES
WHERE table_schema <> 'INFORMATION_SCHEMA';

-- Tables by schema
SELECT
    table_schema,
    COUNT(*) as table_count
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.TABLES
WHERE table_schema != 'INFORMATION_SCHEMA'
GROUP BY table_schema
ORDER BY table_schema;
