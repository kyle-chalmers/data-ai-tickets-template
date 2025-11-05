-- KAN-6: Get total column count across all tables in SNOWFLAKE_SAMPLE_DATA
-- Query: Total columns in database (excluding INFORMATION_SCHEMA)
-- Output: Single row with total column count

SELECT
    COUNT(*) as total_columns
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
WHERE table_schema != 'INFORMATION_SCHEMA';
