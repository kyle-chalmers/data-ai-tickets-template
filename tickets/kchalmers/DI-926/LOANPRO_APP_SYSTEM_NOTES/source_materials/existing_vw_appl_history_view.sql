-- EXISTING: ARCA.FRESHSNOW.VW_APPL_HISTORY (View)
-- Source: Retrieved 2025-01-22 for dependency analysis

create or replace view VW_APPL_HISTORY(
	ENTITY_ID,
	NOTE_TITLE,
	NOTE_DATA,
	REFERENCE_TYPE,
	OPERATION_TYPE,
	OPERATION_SUB_TYPE,
	ROW_EVENT_TYPE,
	CREATE_USER,
	CREATE_USER_NAME,
	CREATED,
	LASTUPDATED,
	DELETED,
	IS_HARD_DELETED,
	BEFORE_VALUES,
	NEWVALUE,
	OLDVALUE,
	NOTE_TITLE_DETAIL
) as
WITH initial_pull AS (
    SELECT 
        A.ENTITY_ID AS LOANID,
        A.NOTE_TITLE,
        -- Ensure JSON parsing does not return '[]', 'null', or empty string
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(A.NOTE_DATA), '[]'), 'null'), '') AS json_values,

        COALESCE(
            REGEXP_SUBSTR(A.NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1),  
            CASE 
                WHEN json_values:"loanSubStatusId" IS NOT NULL 
                 AND json_values:"loanStatusId" IS NOT NULL THEN 'Loan Status - Loan Sub Status'
                WHEN json_values:"loanSubStatusId" IS NOT NULL THEN 'Loan Sub Status'
                WHEN json_values:"sourceCompany" IS NOT NULL THEN 'Source Company'
                WHEN json_values:"agent" IS NOT NULL THEN 'Agent'
                WHEN json_values:"PortfoliosAdded" IS NOT NULL THEN 'Portfolios Added'
                WHEN json_values:"applyDefaultFieldMap" IS NOT NULL THEN 'Apply Default Field Map'
                WHEN json_values:"followUpDate" IS NOT NULL THEN 'FollowUp Date'
                WHEN json_values:"eBilling" IS NOT NULL THEN 'eBilling'
                WHEN json_values:"creditBureau" IS NOT NULL THEN 'Credit Bureau'
                WHEN json_values:"autopayEnabled" IS NOT NULL THEN 'Autopay Enabled'
            END
        ) AS NOTE_TITLE_DETAIL,
        A.REFERENCE_TYPE,
        A.OPERATION_TYPE,
        A.OPERATION_SUB_TYPE,
        A.ROW_EVENT_TYPE,
        A.CREATE_USER,
        A.CREATE_USER_NAME,
        A.CREATED,
        A.LASTUPDATED,
        A.DELETED,
        A.IS_HARD_DELETED,
        A.BEFORE_VALUES,
        A.DSS_LOAD_DATE,
        A.DSS_RECORD_SOURCE,
        
        ---- loan status , sub status and company values 
        JSON_VALUES:loanStatusId:newValue::int AS new_loan_status,
        JSON_VALUES:loanSubStatusId:newValue::int AS new_loan_sub_status,
        JSON_VALUES:sourceCompany:newValue::int AS new_source_company,
        
        --- sub old values for above 3
        JSON_VALUES:loanStatusId:oldValue::int AS old_loan_status,
        JSON_VALUES:loanSubStatusId:oldValue::int AS old_loan_sub_status,
        JSON_VALUES:sourceCompany:oldValue::int AS old_source_company,

        -- loan_status , sub status string values for join condition filters
        JSON_VALUES:loanStatusId::STRING AS loan_status_string,
        JSON_VALUES:loanSubStatusId::STRING AS loan_sub_status_string,
        JSON_VALUES:sourceCompany::STRING AS source_company_string,
        
        -- others new values 
        JSON_VALUES:customFieldValue:newValue::STRING AS new_custom_field_value,
        JSON_VALUES:CustomFieldValues:newValue::STRING AS new_custom_field_values,
        JSON_VALUES:applyDefaultFieldMap:newValue::STRING AS new_apply_default_field_map,
        JSON_VALUES:agent:newValue::STRING AS new_agent,
        JSON_VALUES:followUpDate:newValue::STRING AS new_follow_up_date,
        JSON_VALUES:eBilling:newValue::STRING AS new_e_billing,
        JSON_VALUES:creditBureau:newValue::STRING AS new_credit_bureau,
        JSON_VALUES:autopayEnabled:newValue::STRING AS new_autopay_enabled,
        JSON_VALUES:title::STRING AS new_title,

        -- others old values 
        JSON_VALUES:customFieldValue:oldValue::STRING AS old_custom_field_value,
        JSON_VALUES:CustomFieldValues:oldValue::STRING AS old_custom_field_values,
        JSON_VALUES:applyDefaultFieldMap:oldValue::STRING AS old_apply_default_field_map,
        JSON_VALUES:agent:oldValue::STRING AS old_agent,
        JSON_VALUES:followUpDate:oldValue::STRING AS old_follow_up_date,
        JSON_VALUES:eBilling:oldValue::STRING AS old_e_billing,
        JSON_VALUES:creditBureau:oldValue::STRING AS old_credit_bureau,
        JSON_VALUES:autopayEnabled:oldValue::STRING AS old_autopay_enabled,
        JSON_VALUES:title::STRING AS old_title,
        
    FROM RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY A
    WHERE A.SCHEMA_NAME = CONFIG.LOS_SCHEMA()
      AND A.REFERENCE_TYPE IN ('Entity.LoanSettings') 
      AND A.NOTE_TITLE NOT IN ('Loan settings were created')
      -- and entity_id = 229521 
)
-- [Complex CTE logic continues...]