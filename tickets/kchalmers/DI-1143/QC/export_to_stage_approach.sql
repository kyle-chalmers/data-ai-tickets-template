-- Approach 5: Export data to stage for external processing
-- This avoids timeout issues by breaking into smaller chunks

-- Create a stage
CREATE OR REPLACE STAGE DEVELOPMENT.FRESHSNOW.OSCILAR_EXPORT_STAGE;

-- Export view data in chunks
COPY INTO @DEVELOPMENT.FRESHSNOW.OSCILAR_EXPORT_STAGE/oscilar_plaid_data
FROM (
    SELECT *
    FROM DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION_DETAIL
    LIMIT 10000
)
FILE_FORMAT = (TYPE = 'PARQUET')
MAX_FILE_SIZE = 100000000
HEADER = TRUE;