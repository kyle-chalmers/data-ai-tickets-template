create or replace materialized view ARCA.FRESHSNOW.MVW_HM_VERIFICATION_RESPONSES_PLAID_ASSETS(
	APPLICATION_ID,
	BORROWER_ID,
	DATA
) as SELECT application_id, borrower_id, DATA FROM (        
    SELECT 
    PARSE_JSON(data::STRING) DATA,
    DATA:data:input:payload:applicationId::VARCHAR as application_id,
    DATA:data:input:payload:borrowerId::VARCHAR as borrower_id
    FROM RAW_DATA_STORE.KAFKA.EXTERNAL_HM_Verification_Responses, 
    LATERAL FLATTEN(input => DATA:data:integrations) integration
);