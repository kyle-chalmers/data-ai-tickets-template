-- FRESHSNOW Layer: Raw system note data with JSON parsing
-- Extracts and processes system note data from LoanPro

SELECT 
    entity_id as app_id,
    convert_timezone('UTC','America/Los_Angeles',created) as created_ts,
    convert_timezone('UTC','America/Los_Angeles',lastupdated) as lastupdated_ts,
    
    -- Loan Status ID extraction
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanStatusId"::STRING 
         else parse_json(note_data):"loanStatusId":"newValue"::STRING 
         end as loan_status_new_id,
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanStatusId"::STRING 
         else parse_json(note_data):"loanStatusId":"oldValue"::STRING 
         end as loan_status_old_id,
         
    -- New Value extraction (complex nested JSON parsing)
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanSubStatusId"::STRING 
         when parse_json(note_data):"loanSubStatusId"::STRING is not null then parse_json(note_data):"loanSubStatusId":"newValue"::STRING
         when parse_json(note_data):"agent"::STRING is not null then parse_json(note_data):"agent":"newValue"::string
         when parse_json(note_data):"sourceCompany"::STRING is not null then parse_json(note_data):"sourceCompany":"newValue"::string
         when parse_json(note_data):"PortfoliosAdded"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosAdded":"newValue")[0],'"',''))::string
         when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosRemoved":"newValue")[0],'"',''))::string
         when note_data like '%applyDefaultFieldMap%' then parse_json(note_data):"applyDefaultFieldMap":"newValue"::STRING 
         else parse_json(note_data):"customFieldValue":"newValue"::STRING 
         end as note_new_value,
         
    -- Old Value extraction (complex nested JSON parsing)
    case when note_title = 'Loan settings were created' then parse_json(note_data):"loanSubStatusId"::STRING 
         when parse_json(note_data):"loanSubStatusId"::STRING is not null then parse_json(note_data):"loanSubStatusId":"oldValue"::STRING
         when parse_json(note_data):"agent"::STRING is not null then parse_json(note_data):"agent":"oldValue"::string
         when parse_json(note_data):"sourceCompany"::STRING is not null then parse_json(note_data):"sourceCompany":"oldValue"::string
         when parse_json(note_data):"PortfoliosAdded"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosAdded":"oldValue")[0],'"',''))::string
         when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then trim(replace(object_keys(parse_json(note_data):"PortfoliosRemoved":"oldValue")[0],'"',''))::string
         when note_data like '%applyDefaultFieldMap%' then parse_json(note_data):"applyDefaultFieldMap":"oldValue"::STRING 
         else parse_json(note_data):"customFieldValue":"oldValue"::STRING     
         end as note_old_value,
         
    -- Note title categorization
    case when REGEXP_SUBSTR(note_title, '\\((.*?)\\)', 1, 1, 'e', 1) is null then 
              case when TRY_PARSE_JSON(note_data) is null then null								
                  else 
                      case when parse_json(note_data):"loanStatusId"::STRING is not null then 'Loan Status - Loan Sub Status'
                           when parse_json(note_data):"loanSubStatusId"::STRING is not null then 'Loan Sub Status'
                           when parse_json(note_data):"sourceCompany"::STRING is not null then 'Source Company'
                           when parse_json(note_data):"agent"::STRING is not null then 'Agent'
                           when parse_json(note_data):"PortfoliosAdded"::STRING is not null then 'Portfolios Added'
                           when parse_json(note_data):"PortfoliosRemoved"::STRING is not null then 'Portfolios Removed'
                           when parse_json(note_data):"applyDefaultFieldMap"::STRING is not null then 'Apply Default Field Map'
                           when parse_json(note_data):"followUpDate"::STRING is not null then 'FollowUp Date'
                           when parse_json(note_data):"eBilling"::STRING is not null then 'eBilling'
                           when parse_json(note_data):"creditBureau"::STRING is not null then 'Credit Bureau'
                           when parse_json(note_data):"autopayEnabled"::STRING is not null then 'Autopay Enabled'
                      end
              end
        else REGEXP_SUBSTR(NOTE_TITLE, '\\((.*?)\\)', 1, 1, 'e', 1)  
        end as note_title_detail,
        
    note_title,
    note_data,
    deleted,
    is_hard_deleted
    
FROM raw_data_store.loanpro.system_note_entity
WHERE schema_name = ARCA.CONFIG.LOS_SCHEMA()  -- LoanPro application schema filter                                                           
    AND reference_type IN ('Entity.LoanSettings') 
    AND deleted = 0  -- Only active records
    AND is_hard_deleted = FALSE