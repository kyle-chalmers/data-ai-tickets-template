-- Approach 4: Create a simplified view for QC purposes
-- Only include essential fields and limit JSON parsing

CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_OSCILAR_PLAID_SIMPLE AS
SELECT 
    -- Core identifiers
    DATA:data:input:oscilar:record_id::varchar AS oscilar_record_id,
    DATA:data:input:payload:applicationId::varchar AS lead_guid,
    DATA:data:input:payload:borrowerId::varchar AS member_id,
    DATA:data:input:oscilar:timestamp::timestamp AS record_timestamp,
    
    -- Basic Plaid info without deep parsing
    DATA:data:integrations[3]:response:date_generated::varchar AS plaid_date,
    ARRAY_SIZE(DATA:data:integrations[3]:response:items) AS item_count,
    
    -- Sample one account for testing
    DATA:data:integrations[3]:response:items[0]:accounts[0]:account_id::varchar AS sample_account_id,
    DATA:data:integrations[3]:response:items[0]:accounts[0]:name::varchar AS sample_account_name,
    ARRAY_SIZE(DATA:data:integrations[3]:response:items[0]:accounts[0]:transactions) AS sample_transaction_count

FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS
WHERE DATA:data:integrations[3]:name::varchar = 'Plaid_Assets'
  AND DATA:data:integrations[3]:response:items IS NOT NULL;