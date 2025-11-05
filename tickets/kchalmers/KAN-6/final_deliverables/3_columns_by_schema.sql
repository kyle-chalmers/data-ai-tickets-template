-- KAN-6: Get column count summary by schema in SNOWFLAKE_SAMPLE_DATA
-- Query: Aggregated column counts by schema with table counts
-- Output: Schema-level summary with table and column totals

SELECT
    table_schema,
    COUNT(DISTINCT table_name) as table_count,
    SUM(column_count) as total_columns
FROM (
    SELECT
        table_schema,
        table_name,
        COUNT(*) as column_count
    FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema != 'INFORMATION_SCHEMA'
    GROUP BY table_schema, table_name
) subquery
GROUP BY table_schema
ORDER BY table_schema;
