-- VW_LOAN_BANKRUPTCY - Comprehensive Bankruptcy Data Object
-- Replaces VW_LOAN_COLLECTION dependency in BI-2482 outbound list generation
-- Ticket: DI-1239 | Created: 2025-01-09 | Updated: Added all available columns with PT timezone

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY AS
WITH bankruptcy_entity AS (
    SELECT 
        be.LOAN_ID,
        be.ID as BANKRUPTCY_ID,
        be.CASE_NUMBER,
        be.FILING_DATE,
        be.NOTICE_RECEIVED_DATE,
        be.AUTOMATIC_STAY_STATUS,
        be.CUSTOMER_ID,
        be.BANKRUPTCY_DISTRICT,
        REPLACE(be.PETITION_TYPE, 'loan.bankruptcyPetitionType.', '') as PETITION_TYPE,
        be.DISMISSED_DATE,
        be.CLOSED_REASON,
        -- Additional columns from entity table (cleaned of system prefixes)
        be.CITY,
        REPLACE(be.STATE, 'geo.state.', '') as STATE,
        be.PROOF_OF_CLAIM_DEADLINE_DATE,
        be.MEETING_OF_CREDITORS_DATE,
        be.OBJECTION_DEADLINE_DATE,
        REPLACE(be.OBJECTION_STATUS, 'loan.bankruptcyObjectionStatus.', '') as OBJECTION_STATUS,
        be.LIENED_PROPERTY_STATUS,
        REPLACE(be.PROOF_OF_CLAIM_FILED_STATUS, 'loan.bankruptcyProofOfClaimFiledStatus.', '') as PROOF_OF_CLAIM_FILED_STATUS,
        be.PROOF_OF_CLAIM_FILED_DATE,
        -- Active status
        be.ACTIVE,
        -- Timestamp conversions to PT
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', be.CREATED) as CREATED_DATE_PT,
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', be.LASTUPDATED) as LAST_UPDATED_DATE_PT,
        -- Status normalization
        CASE 
            WHEN be.CHAPTER LIKE '%chapter13%' THEN 'Chapter 13'
            WHEN be.CHAPTER LIKE '%chapter7%' THEN 'Chapter 7' 
            WHEN be.CHAPTER LIKE '%chapter11%' THEN 'Chapter 11'
            ELSE be.CHAPTER 
        END as BANKRUPTCY_CHAPTER,
        CASE 
            WHEN be.PETITION_STATUS LIKE '%planConfirmed%' THEN 'Plan Confirmed'
            WHEN be.PETITION_STATUS LIKE '%petitionFiled%' THEN 'Petition Filed'
            WHEN be.PETITION_STATUS LIKE '%discharged%' THEN 'Discharged'
            WHEN be.PETITION_STATUS LIKE '%dismissed%' THEN 'Dismissed'
            ELSE be.PETITION_STATUS 
        END as PETITION_STATUS,
        CASE 
            WHEN be.PROCESS_STATUS LIKE '%planConfirmed%' THEN 'Plan Confirmed'
            WHEN be.PROCESS_STATUS LIKE '%petitionFiledVerified%' THEN 'Petition Filed Verified'
            WHEN be.PROCESS_STATUS LIKE '%noticeReceived%' THEN 'Notice Received'
            WHEN be.PROCESS_STATUS LIKE '%discharged%' THEN 'Discharged'
            WHEN be.PROCESS_STATUS LIKE '%dismissed%' THEN 'Dismissed'
            WHEN be.PROCESS_STATUS LIKE '%claimFiled%' THEN 'Claim Filed'
            ELSE REPLACE(be.PROCESS_STATUS, 'loan.bankruptcyProcessStatus.', '') 
        END as PROCESS_STATUS,
        'BANKRUPTCY_ENTITY' as DATA_SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANKRUPTCY_ENTITY_CURRENT be
    WHERE be.DELETED = 0
),

custom_settings AS (
    SELECT 
        cls.LOAN_ID,
        NULL as BANKRUPTCY_ID,
        cls.BANKRUPTCY_CASE_NUMBER as CASE_NUMBER,
        cls.BANKRUPTCY_FILING_DATE as FILING_DATE,
        cls.BANKRUPTCY_NOTIFICATION_RECEIVED_DATE as NOTICE_RECEIVED_DATE,
        NULL as AUTOMATIC_STAY_STATUS,
        NULL as CUSTOMER_ID,
        cls.BANKRUPTCY_COURT_DISTRICT as BANKRUPTCY_DISTRICT,
        NULL as PETITION_TYPE,
        cls.DISMISSAL_DATE as DISMISSED_DATE,
        NULL as CLOSED_REASON,
        -- Additional columns with custom settings equivalents
        NULL as CITY, -- No direct equivalent
        NULL as STATE, -- No bankruptcy-specific state in custom settings
        NULL as PROOF_OF_CLAIM_DEADLINE_DATE, -- No equivalent
        NULL as MEETING_OF_CREDITORS_DATE, -- No equivalent
        NULL as OBJECTION_DEADLINE_DATE, -- No equivalent
        NULL as OBJECTION_STATUS, -- No equivalent
        NULL as LIENED_PROPERTY_STATUS, -- No equivalent
        CASE WHEN cls.PROOFOFCLAIMREQUIRED = 1 THEN 'Required' WHEN cls.PROOFOFCLAIMREQUIRED = 0 THEN 'Not Required' ELSE NULL END as PROOF_OF_CLAIM_FILED_STATUS,
        NULL as PROOF_OF_CLAIM_FILED_DATE, -- No equivalent
        -- Active status (default to 1 for custom settings)
        1 as ACTIVE,
        -- Timestamp conversions to PT
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', CURRENT_TIMESTAMP) as CREATED_DATE_PT,
        CONVERT_TIMEZONE('UTC', 'America/Los_Angeles', CURRENT_TIMESTAMP) as LAST_UPDATED_DATE_PT,
        CASE 
            WHEN cls.BANKRUPTCY_CHAPTER LIKE '%13%' THEN 'Chapter 13'
            WHEN cls.BANKRUPTCY_CHAPTER LIKE '%7%' THEN 'Chapter 7' 
            ELSE cls.BANKRUPTCY_CHAPTER 
        END as BANKRUPTCY_CHAPTER,
        cls.BANKRUPTCY_STATUS as PETITION_STATUS,
        NULL as PROCESS_STATUS,
        'CUSTOM_SETTINGS' as DATA_SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE cls.BANKRUPTCY_CASE_NUMBER IS NOT NULL
      AND cls.LOAN_ID NOT IN (SELECT LOAN_ID FROM bankruptcy_entity)
),

-- Portfolio assignments for context (to be joined, not unioned)
bankruptcy_portfolios AS (
    SELECT 
        port.LOAN_ID,
        LISTAGG(DISTINCT port.PORTFOLIO_NAME, '; ') as BANKRUPTCY_PORTFOLIOS,
        COUNT(DISTINCT port.PORTFOLIO_NAME) as PORTFOLIO_COUNT
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
    WHERE port.PORTFOLIO_NAME LIKE '%Bankrupt%'
      AND port.PORTFOLIO_NAME != 'BankruptcyWatch Integration'
    GROUP BY port.LOAN_ID
),

-- Duplicate case number analysis using window functions
all_bankruptcies AS (
    SELECT * FROM bankruptcy_entity
    UNION ALL
    SELECT * FROM custom_settings  
),

duplicate_logic AS (
    SELECT 
        *,
        -- Count case numbers across different loans
        COUNT(DISTINCT LOAN_ID) OVER (PARTITION BY CASE_NUMBER) as case_number_loan_count,
        -- Count sources for same loan and case number
        COUNT(DISTINCT DATA_SOURCE) OVER (PARTITION BY LOAN_ID, CASE_NUMBER) as loan_case_source_count,
        -- Count records for same loan from bankruptcy entity
        COUNT(*) OVER (PARTITION BY LOAN_ID, DATA_SOURCE) as loan_source_record_count,
        -- Rank by most recent for same loan in entity data
        ROW_NUMBER() OVER (PARTITION BY LOAN_ID, DATA_SOURCE ORDER BY COALESCE(LAST_UPDATED_DATE_PT, CREATED_DATE_PT) DESC) as recency_rank
    FROM all_bankruptcies
),

final_duplicate_logic AS (
    SELECT 
        *,
        -- Mark duplicates based on simplified logic
        CASE 
            -- If case number appears on multiple loans, mark as not duplicate
            WHEN CASE_NUMBER IS NOT NULL AND case_number_loan_count > 1 THEN FALSE
            
            -- For same loan with same case number from both sources, mark entity as false, custom as true
            WHEN CASE_NUMBER IS NOT NULL AND loan_case_source_count > 1 AND DATA_SOURCE = 'BANKRUPTCY_ENTITY' THEN FALSE
            WHEN CASE_NUMBER IS NOT NULL AND loan_case_source_count > 1 AND DATA_SOURCE = 'CUSTOM_SETTINGS' THEN TRUE
            
            -- For multiple entity records for same loan, mark most recent as false, others as true
            WHEN DATA_SOURCE = 'BANKRUPTCY_ENTITY' AND loan_source_record_count > 1 AND recency_rank > 1 THEN TRUE
            
            -- Default to false (not a duplicate)
            ELSE FALSE
        END as DUPE_CASE_NUMBER
    FROM duplicate_logic
),

-- Add most recent active bankruptcy logic
final_with_most_recent AS (
    SELECT 
        *,
        -- Calculate most recent active bankruptcy rank
        CASE 
            WHEN ACTIVE = 1 AND DUPE_CASE_NUMBER = FALSE THEN 
                ROW_NUMBER() OVER (PARTITION BY LOAN_ID ORDER BY COALESCE(LAST_UPDATED_DATE_PT, CREATED_DATE_PT) DESC)
            ELSE NULL 
        END as most_recent_active_rank,
        -- Calculate most recent bankruptcy rank (regardless of active status)
        CASE 
            WHEN DUPE_CASE_NUMBER = FALSE THEN 
                ROW_NUMBER() OVER (PARTITION BY LOAN_ID ORDER BY COALESCE(LAST_UPDATED_DATE_PT, CREATED_DATE_PT) DESC)
            ELSE NULL 
        END as most_recent_rank
    FROM final_duplicate_logic
)

SELECT 
    CAST(a.LOAN_ID AS VARCHAR) as LOAN_ID,
    a.BANKRUPTCY_ID,
    a.CASE_NUMBER,
    a.BANKRUPTCY_CHAPTER,
    a.PETITION_STATUS,
    a.PROCESS_STATUS,
    a.FILING_DATE,
    a.NOTICE_RECEIVED_DATE,
    a.AUTOMATIC_STAY_STATUS,
    a.CUSTOMER_ID,
    a.BANKRUPTCY_DISTRICT,
    a.PETITION_TYPE,
    a.DISMISSED_DATE,
    a.CLOSED_REASON,
    -- Additional bankruptcy details
    a.CITY,
    a.STATE,
    a.PROOF_OF_CLAIM_DEADLINE_DATE,
    a.MEETING_OF_CREDITORS_DATE,
    a.OBJECTION_DEADLINE_DATE,
    a.OBJECTION_STATUS,
    a.LIENED_PROPERTY_STATUS,
    a.PROOF_OF_CLAIM_FILED_STATUS,
    a.PROOF_OF_CLAIM_FILED_DATE,
    -- Active status and duplicate flag
    a.ACTIVE,
    a.DUPE_CASE_NUMBER,
    -- Most recent active bankruptcy flag
    CASE WHEN a.most_recent_active_rank = 1 THEN 'Y' ELSE 'N' END as MOST_RECENT_ACTIVE_BANKRUPTCY,
    -- Most recent bankruptcy flag (regardless of active status)
    CASE WHEN a.most_recent_rank = 1 THEN 'Y' ELSE 'N' END as MOST_RECENT_BANKRUPTCY,
    a.DATA_SOURCE,
    a.CREATED_DATE_PT,
    a.LAST_UPDATED_DATE_PT,
    -- Portfolio context (joined data)
    bp.BANKRUPTCY_PORTFOLIOS,
    bp.PORTFOLIO_COUNT,
    CASE WHEN bp.LOAN_ID IS NOT NULL THEN 'Y' ELSE 'N' END as HAS_BANKRUPTCY_PORTFOLIO
FROM final_with_most_recent a
LEFT JOIN bankruptcy_portfolios bp ON a.LOAN_ID = bp.LOAN_ID;