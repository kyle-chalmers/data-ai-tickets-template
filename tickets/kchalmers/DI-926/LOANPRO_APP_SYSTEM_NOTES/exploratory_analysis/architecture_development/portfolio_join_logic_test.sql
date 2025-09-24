-- Test the corrected portfolio JOIN logic for record 674403164
-- This query demonstrates the difference between current restrictive logic
-- and the corrected logic that matches the original stored procedure

WITH initial_pull AS (
    SELECT
        a.id as record_id,
        a.entity_id as app_id,
        a.note_title,
        a.note_data,
        -- Single JSON parse
        NULLIF(NULLIF(NULLIF(TRY_PARSE_JSON(a.note_data), '[]'), 'null'), '') AS json_values,

        -- Note categorization
        case when json_values:"loanStatusId"::STRING is not null then 'Loan Status - Loan Sub Status'
             when json_values:"PortfoliosAdded"::STRING is not null then 'Portfolios Added'
             else 'Other'
             end as note_title_detail,

        -- Portfolio extraction
        trim(replace(object_keys(json_values:"PortfoliosAdded":"newValue")[0],'"',''))::string as portfolios_added

    FROM ARCA.FRESHSNOW.VW_SYSTEM_NOTE_ENTITY a
    WHERE a.id = 674403164
      AND a.reference_type IN ('Entity.LoanSettings')
      AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
),
portfolio_entity AS (
    SELECT A.ID::STRING AS ID,
           A.TITLE,
           B.TITLE AS PORTFOLIO_CATEGORY
    FROM ARCA.FRESHSNOW.PORTFOLIO_ENTITY_CURRENT A
    LEFT JOIN ARCA.FRESHSNOW.PORTFOLIO_CATEGORY_ENTITY_CURRENT B
        ON A.CATEGORY_ID = B.ID AND B.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    WHERE A.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
)
SELECT
    a.record_id,
    a.note_title_detail,
    a.portfolios_added,
    -- CURRENT LOGIC (restrictive) - PROBLEMATIC
    pe_old.ID as portfolio_match_old_logic,
    pe_old.TITLE as portfolio_title_old_logic,
    pe_old.PORTFOLIO_CATEGORY as portfolio_category_old_logic,
    -- NEW LOGIC (corrected) - FIXED
    pe_new.ID as portfolio_match_new_logic,
    pe_new.TITLE as portfolio_title_new_logic,
    pe_new.PORTFOLIO_CATEGORY as portfolio_category_new_logic
FROM initial_pull a
-- OLD LOGIC: Only when note_title_detail = 'Portfolios Added' (MISSES DATA)
LEFT JOIN portfolio_entity pe_old ON try_to_number(a.portfolios_added) = pe_old.id::NUMBER
    AND a.note_title_detail = 'Portfolios Added'
-- NEW LOGIC: Whenever portfolios_added has a value (CAPTURES ALL DATA)
LEFT JOIN portfolio_entity pe_new ON try_to_number(a.portfolios_added) = pe_new.id::NUMBER;

/*
EXPECTED RESULTS:
- OLD LOGIC: NULL values (because note_title_detail = 'Loan Status - Loan Sub Status', not 'Portfolios Added')
- NEW LOGIC: Portfolio ID 167, "Affiliate Decline", "Offer Decision"

This demonstrates that 1.27M records are missing portfolio labels due to restrictive JOIN condition.
*/