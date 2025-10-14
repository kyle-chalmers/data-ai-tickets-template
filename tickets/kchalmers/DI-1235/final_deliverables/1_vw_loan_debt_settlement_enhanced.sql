-- Enhanced VW_LOAN_DEBT_SETTLEMENT with ACTIONS and CHECKLIST_ITEMS sources
-- DI-1235: Add two new settlement data sources to existing view
-- Deployment Target: BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT (development first)
-- Production Target: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT (after user review)

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT COPY GRANTS AS
WITH PORTFOLIOS as (
    -- Portfolio source (EXISTING - unchanged)
    SELECT port.LOAN_ID::VARCHAR                                                  AS LOAN_ID,
           MAX(IFF(PORTFOLIO_NAME = 'Settlement Setup', port.CREATED, NULL))      AS SETTLEMENT_SETUP_PORTFOLIO_DATE,
           MAX(IFF(PORTFOLIO_NAME = 'Settlement Successful', port.CREATED, NULL)) AS SETTLEMENT_SUCCESSFUL_PORTFOLIO_DATE,
           MAX(IFF(PORTFOLIO_NAME = 'Settlement Failed', port.CREATED, NULL))     AS SETTLEMENT_FAILED_PORTFOLIO_DATE,
           COUNT(port.PORTFOLIO_ID)                                               as SETTLEMENT_PORTFOLIO_COUNT,
           LISTAGG(DISTINCT port.PORTFOLIO_NAME, '; ')                            as SETTLEMENT_PORTFOLIOS,
           'PORTFOLIOS'                                                           as SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
    WHERE port.PORTFOLIO_CATEGORY = 'Settlement'
    GROUP BY LOAN_ID
)
   , CUSTOM_FIELDS AS (
    -- Custom fields source (EXISTING - unchanged)
    SELECT cls.LOAN_ID::VARCHAR AS LOAN_ID,
           'CUSTOM_FIELDS'      as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    WHERE (cls.SETTLEMENTSTATUS IS NOT NULL AND cls.SETTLEMENTSTATUS <> '')
       OR (cls.SETTLEMENT_AMOUNT IS NOT NULL AND cls.SETTLEMENT_AMOUNT > 0)
       OR (cls.DEBT_SETTLEMENT_COMPANY IS NOT NULL AND cls.DEBT_SETTLEMENT_COMPANY <> '')
       OR (cls.SETTLEMENTCOMPANY IS NOT NULL AND cls.SETTLEMENTCOMPANY <> '')
       OR cls.SETTLEMENTSTARTDATE IS NOT NULL
       OR cls.SETTLEMENTAGREEMENTAMOUNT IS NOT NULL
       OR cls.DEBTSETTLEMENTPAYMENTTERMS IS NOT NULL
       OR cls.NUMBEROFDEBTSETTLEMENTPAYMENTSEXPECTED IS NOT NULL
       OR cls.EXPECTEDSETTLEMENTENDDATE IS NOT NULL
    GROUP BY cls.LOAN_ID
)
   , SUB_STATUS AS (
    -- Sub status source (EXISTING - unchanged)
    SELECT a.LOAN_ID::VARCHAR AS LOAN_ID,
           'SUB_STATUS'       AS SOURCE,
           B.TITLE            AS CURRENT_STATUS,
           A.LOAN_SUB_STATUS_ID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT A
             INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT B
                        ON A.LOAN_SUB_STATUS_ID = B.ID
                            AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    WHERE a.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
      AND A.DELETED = 0
    GROUP BY ALL
)
   , DOCUMENTS AS (
    -- Documents source (EXISTING - unchanged)
    SELECT LD.LOAN_ID,
           DATE(MAX(ld.LASTUPDATED_TS))           AS LATEST_SETTLEMENT_DOCUMENT_UPDATE_DATE,
           MAX_BY(LD.FILENAME, LD.LASTUPDATED_TS) AS LATEST_SETTLEMENT_DOCUMENT,
           COUNT(LD.ID)                           as SETTLEMENT_DOCUMENTS_COUNT,
           LISTAGG(LD.FILENAME, '; ')             as SETTLEMENT_DOCUMENTS,
           'DOCUMENTS'                            as SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.LOAN_DOCUMENTS LD
    WHERE LD.SECTION_TITLE = 'Settlements'
    GROUP BY LD.LOAN_ID
)
   , ACTIONS AS (
    -- Settlement actions source (NEW - DI-1235)
    -- Aggregates settlement action history from VW_LOAN_ACTION_AND_RESULTS
    -- Handles many:1 relationship (some loans have multiple settlement actions)
    SELECT
        LOAN_ID::VARCHAR                                           AS LOAN_ID,
        MIN(ACTION_RESULT_TS)                                      AS EARLIEST_SETTLEMENT_ACTION_DATE,
        MAX(ACTION_RESULT_TS)                                      AS LATEST_SETTLEMENT_ACTION_DATE,
        COUNT(*)                                                   AS SETTLEMENT_ACTION_COUNT,
        MAX_BY(AGENT_NAME, ACTION_RESULT_TS)                       AS LATEST_SETTLEMENT_ACTION_AGENT,
        MAX_BY(NOTE, ACTION_RESULT_TS)                             AS LATEST_SETTLEMENT_ACTION_NOTE,
        'ACTIONS'                                                  AS SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS
    -- This was the only settlement-related result found in VW_LOAN_ACTION_AND_RESULTS
    WHERE RESULT_TEXT = 'Settlement Payment Plan Set up'
    GROUP BY LOAN_ID
)
   , CHECKLIST_ITEMS AS (
    -- Checklist items source (NEW - DI-1235, ACTIVATED)
    -- Captures loans with Settlement Accepted or Settlement Failed checklist items
    SELECT
        LOAN_ID::VARCHAR                                AS LOAN_ID,
        COUNT(DISTINCT CHECKLIST_ITEM_NAME)             as SETTLEMENT_CHECKLIST_COUNT,
        LISTAGG(DISTINCT CHECKLIST_ITEM_NAME, '; ')     as SETTLEMENT_CHECKLISTS,
        MAX(LASTUPDATED)                                as LATEST_CHECKLIST_UPDATE,
        'CHECKLIST_ITEMS'                               as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT
    WHERE CHECKLIST_ITEM_NAME IN ('Settlement Accepted', 'Settlement Failed')
      AND CHECKLIST_ITEM_VALUE = 1  -- Only include checked items
    GROUP BY LOAN_ID
)
   , settlement_loans AS (
    -- Get all loans with any settlement indicator (main population)
    -- UPDATED: Added ACTIONS and CHECKLIST_ITEMS sources (DI-1235)
    SELECT LOAN_ID FROM CUSTOM_FIELDS
    UNION
    SELECT LOAN_ID FROM PORTFOLIOS
    UNION
    SELECT LOAN_ID FROM SUB_STATUS WHERE LOAN_SUB_STATUS_ID = '57'
    UNION
    SELECT LOAN_ID FROM DOCUMENTS
    UNION
    SELECT LOAN_ID FROM ACTIONS
    UNION
    SELECT LOAN_ID FROM CHECKLIST_ITEMS  -- ACTIVATED: DI-1235
)
-- Main query with efficient joins (UPDATED: New columns and tracking for 6 sources)
SELECT sl.LOAN_ID,
       vlclsc.LEAD_GUID,

       -- Settlement Status Information (EXISTING - unchanged)
       vlclsc.SETTLEMENTSTATUS,
       sss.CURRENT_STATUS,

       -- Settlement Financial Information (EXISTING - unchanged)
       vlclsc.SETTLEMENT_AMOUNT,
       vlclsc.SETTLEMENT_AMOUNT_PAID,
       vlclsc.SETTLEMENTAGREEMENTAMOUNT,
       vlclsc.TOTAL_PAID_AT_TIME_OF_SETTLEMENT,
       vlclsc.PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT,
       vlclsc.AMOUNT_FORGIVEN,

       -- Settlement Company Information (EXISTING - unchanged)
       COALESCE(vlclsc.DEBT_SETTLEMENT_COMPANY, vlclsc.SETTLEMENTCOMPANY)                                             as SETTLEMENT_COMPANY,

       -- Settlement Dates (EXISTING - unchanged)
       vlclsc.SETTLEMENT_ACCEPTED_DATE,
       vlclsc.SETTLEMENTSTARTDATE                                                                                     as SETTLEMENT_START_DATE,
       vlclsc.SETTLEMENTCOMPLETIONDATE                                                                                as SETTLEMENT_COMPLETION_DATE,
       vlclsc.EXPECTEDSETTLEMENTENDDATE                                                                               as EXPECTED_SETTLEMENT_END_DATE,

       -- Settlement Terms (EXISTING - unchanged)
       vlclsc.DEBTSETTLEMENTPAYMENTTERMS                                                                              as DEBT_SETTLEMENT_PAYMENT_TERMS,
       vlclsc.NUMBEROFDEBTSETTLEMENTPAYMENTSEXPECTED                                                                  as NUMBER_OF_DEBT_SETTLEMENT_PAYMENTS_EXPECTED,

       -- Portfolio Information (EXISTING - unchanged)
       sp.SETTLEMENT_PORTFOLIOS,
       sp.SETTLEMENT_PORTFOLIO_COUNT,
       sp.SETTLEMENT_SETUP_PORTFOLIO_DATE,
       sp.SETTLEMENT_SUCCESSFUL_PORTFOLIO_DATE,
       sp.SETTLEMENT_FAILED_PORTFOLIO_DATE,

       -- Documents Information (EXISTING - unchanged)
       d.SETTLEMENT_DOCUMENTS,
       d.SETTLEMENT_DOCUMENTS_COUNT,
       d.LATEST_SETTLEMENT_DOCUMENT,
       d.LATEST_SETTLEMENT_DOCUMENT_UPDATE_DATE,

       -- Settlement Action Information (NEW - DI-1235)
       act.EARLIEST_SETTLEMENT_ACTION_DATE,
       act.LATEST_SETTLEMENT_ACTION_DATE,
       act.SETTLEMENT_ACTION_COUNT,
       act.LATEST_SETTLEMENT_ACTION_AGENT,
       act.LATEST_SETTLEMENT_ACTION_NOTE,

       -- Settlement Checklist Information (NEW - DI-1235, ACTIVATED)
       chk.SETTLEMENT_CHECKLIST_COUNT,
       chk.SETTLEMENT_CHECKLISTS,
       chk.LATEST_CHECKLIST_UPDATE,

       -- Data Source Flags (UPDATED: All 6 sources active - DI-1235)
       CASE WHEN cls.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                     as HAS_CUSTOM_FIELDS,
       CASE WHEN sp.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                      as HAS_SETTLEMENT_PORTFOLIO,
       CASE WHEN d.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                       as HAS_SETTLEMENT_DOCUMENT,
       CASE
           WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN TRUE
           ELSE FALSE END                                                                                             as HAS_SETTLEMENT_SUB_STATUS,
       CASE WHEN act.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                     as HAS_SETTLEMENT_ACTION,
       CASE WHEN chk.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                     as HAS_SETTLEMENT_CHECKLIST,  -- ACTIVATED

       -- Data Source Summary (UPDATED: All 6 sources active - DI-1235)
       (
               CASE WHEN cls.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN d.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN 1 ELSE 0 END +
               CASE WHEN act.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN chk.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END
       )                                                                                                              as DATA_SOURCE_COUNT,

       -- Data Completeness Flag (UPDATED: Thresholds adjusted for 6 sources)
       CASE
           WHEN DATA_SOURCE_COUNT >= 5 THEN 'COMPLETE'      -- 5-6 sources
           WHEN DATA_SOURCE_COUNT >= 2 THEN 'PARTIAL'        -- 2-4 sources
           ELSE 'SINGLE_SOURCE'                              -- 1 source
           END                                                                                                        as DATA_COMPLETENESS_FLAG,

       -- Data Source List (UPDATED: All 6 sources active)
       ARRAY_TO_STRING(
               ARRAY_COMPACT(ARRAY_CONSTRUCT(
                       CASE WHEN cls.LOAN_ID IS NOT NULL THEN cls.SOURCE END,
                       CASE WHEN sp.LOAN_ID IS NOT NULL THEN sp.SOURCE END,
                       CASE WHEN d.LOAN_ID IS NOT NULL THEN d.SOURCE END,
                       CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN sss.SOURCE END,
                       CASE WHEN act.LOAN_ID IS NOT NULL THEN act.SOURCE END,
                       CASE WHEN chk.LOAN_ID IS NOT NULL THEN chk.SOURCE END
                             )),
               ', '
       )                                                                                                              as DATA_SOURCE_LIST

FROM settlement_loans sl
         -- Settlement custom fields (EXISTING - unchanged)
         LEFT JOIN CUSTOM_FIELDS cls
                   ON sl.LOAN_ID = cls.LOAN_ID
         -- Portfolio data (EXISTING - unchanged)
         LEFT JOIN PORTFOLIOS sp
                   ON sl.LOAN_ID = sp.LOAN_ID
         -- Sub status data (EXISTING - unchanged)
         LEFT JOIN SUB_STATUS sss
                   ON sl.LOAN_ID = sss.LOAN_ID
         -- Documents data (EXISTING - unchanged)
         LEFT JOIN DOCUMENTS d
                   ON sl.LOAN_ID = d.LOAN_ID
         -- Settlement actions data (NEW - DI-1235)
         LEFT JOIN ACTIONS act
                   ON sl.LOAN_ID = act.LOAN_ID
         -- Settlement checklist data (NEW - DI-1235, ACTIVATED)
         LEFT JOIN CHECKLIST_ITEMS chk
                   ON sl.LOAN_ID = chk.LOAN_ID
         -- All custom fields (EXISTING - unchanged)
         INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT vlclsc
                    ON sl.LOAN_ID = vlclsc.LOAN_ID;
