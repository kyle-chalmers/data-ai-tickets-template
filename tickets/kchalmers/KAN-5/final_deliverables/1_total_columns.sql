-- KAN-5: Total number of columns in SNOWFLAKE_SAMPLE_DATA
-- This query returns the total count of all columns across all schemas and tables

SELECT COUNT(*) as total_columns
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS;

-- Result: 1,838 total columns
