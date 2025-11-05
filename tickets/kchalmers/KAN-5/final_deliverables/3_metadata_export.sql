-- KAN-5: Complete metadata export for all columns in SNOWFLAKE_SAMPLE_DATA
-- This query exports detailed metadata including data types, nullability, and ordinal position

SELECT
    table_catalog,
    table_schema,
    table_name,
    column_name,
    ordinal_position,
    data_type,
    is_nullable
FROM SNOWFLAKE_SAMPLE_DATA.INFORMATION_SCHEMA.COLUMNS
ORDER BY table_name, ordinal_position;

-- Provides comprehensive column metadata for all 1,838 columns
