-- DI-1143: Create VW_OSCILAR_PLAID_TRANSACTION Alignment View
-- This view transforms Oscilar Plaid transaction data to match historical VW_PLAID_TRANSACTION structure
--
-- BREAKTHROUGH: Transaction data IS available in Plaid Assets integration responses
-- Location: DATA:data:integrations[3]:response:items[0]:accounts[0]:transactions[]
--
-- DO NOT EXECUTE without approval - this is for review purposes only

CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION AS
(
WITH oscilar_base AS (
    SELECT
        -- Core Oscilar metadata
        DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
        DATA:data:input:oscilar:request_id::varchar AS oscilar_request_id,
        DATA:data:input:oscilar:timestamp::timestamp AS oscilar_timestamp,

        -- Entity identifiers
        DATA:data:input:payload:applicationId::varchar AS application_id,
        DATA:data:input:payload:borrowerId::varchar AS borrower_id,

        -- Extract Plaid Assets response
        DATA:data:integrations[3]:response AS plaid_assets_response,

        -- Full data for debugging
        DATA AS full_oscilar_data

    FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
    WHERE
        -- Only records with successful Plaid Assets responses
        DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
        AND DATA:data:integrations[3]:response:items IS NOT NULL
        AND ARRAY_SIZE(DATA:data:integrations[3]:response:items) > 0
),

accounts_with_transactions AS (
    SELECT
        base.*,
        item.index AS item_index,
        item.value AS item_data,
        account.index AS account_index,
        account.value AS account_data,
        -- Count transactions for this account
        ARRAY_SIZE(account.value:transactions) AS total_transactions
    FROM oscilar_base base,
    LATERAL FLATTEN(input => base.plaid_assets_response:items) item,
    LATERAL FLATTEN(input => item.value:accounts) account
    WHERE account.value:transactions IS NOT NULL
      AND ARRAY_SIZE(account.value:transactions) > 0
)

SELECT
    -- Historical VW_PLAID_TRANSACTION structure mapping

    -- Core timestamp and metadata fields
    oscilar_timestamp AS RECORD_CREATE_DATETIME,
    application_id AS LEAD_GUID,  -- Using applicationId as primary entity identifier
    NULL AS LEAD_ID,  -- ❌ NOT AVAILABLE in Oscilar
    borrower_id AS MEMBER_ID,
    oscilar_request_id AS PLAID_REQUEST_ID,
    total_transactions AS TOTAL_TRANSACTIONS,  -- ✅ NOW AVAILABLE from transaction count
    'oscilar_v1' AS SCHEMA_VERSION,  -- Identifying this as Oscilar source
    TO_TIMESTAMP(plaid_assets_response:date_generated::varchar) AS PLAID_CREATE_DATE,  -- Asset report generation date

    -- Plaid Assets specific fields
    plaid_assets_response:asset_report_id::varchar AS ASSET_REPORT_ID,
    plaid_assets_response:asset_report_token::varchar AS ASSET_REPORT_TOKEN,
    plaid_assets_response:days_requested::int AS DAYS_REQUESTED,

    -- Account identification
    account_index AS ACCOUNT_INDEX,
    account_data:account_id::varchar AS ACCOUNT_ID,
    account_data:days_available::int AS ACCOUNT_DAYS_AVAILABLE,

    -- Store raw transaction data for flattening in detail view
    account_data:transactions AS TRANSACTIONS_RAW,
    account_data AS ACCOUNT_RAW,
    item_data AS ITEM_RAW,

    -- Metadata for troubleshooting
    oscilar_record_id AS OSCILAR_RECORD_ID,
    item_index AS PLAID_ITEM_INDEX

FROM accounts_with_transactions

-- Quality filters
WHERE total_transactions > 0  -- Only include accounts with transaction data

-- Order by most recent first, then by account
ORDER BY oscilar_timestamp DESC, account_index
);

-- Add comments explaining the view
COMMENT ON VIEW DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_TRANSACTION IS
'Oscilar-to-DATA_STORE alignment view for Plaid transaction summary data.
BREAKTHROUGH: Transaction data IS available in Plaid Assets responses.
This view provides transaction summary information at the account level.
Created for DI-1143: Align Oscilar Plaid Data Structure With Historical Plaid DATA_STORE Structure';