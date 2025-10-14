# Data Object Request

## Request Type
- **Operation:** ALTER_EXISTING
- **Scope:** SINGLE_OBJECT

## Object Definition(s)
- **Primary Object Name:** VW_LOAN_DEBT_SETTLEMENT
- **Object Type:** VIEW  
- **Target Schema Layer:** ANALYTICS

## Existing Object Context (if ALTER_EXISTING)
- **Current Object(s):** BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
- **Current Object DDL:** create or replace view BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT COPY GRANTS as
WITH PORTFOLIOS as (-- Portfolio source
    SELECT port.LOAN_ID::VARCHAR                                                  AS LOAN_ID,
           MAX(IFF(PORTFOLIO_NAME = 'Settlement Setup', port.CREATED, NULL))      AS SETTLEMENT_SETUP_PORTFOLIO_DATE,
           MAX(IFF(PORTFOLIO_NAME = 'Settlement Successful', port.CREATED, NULL)) AS SETTLEMENT_SUCCESSFUL_PORTFOLIO_DATE,
           MAX(IFF(PORTFOLIO_NAME = 'Settlement Failed', port.CREATED, NULL))     AS SETTLEMENT_FAILED_PORTFOLIO_DATE,
           COUNT(port.PORTFOLIO_ID)                                               as SETTLEMENT_PORTFOLIO_COUNT,
           LISTAGG(DISTINCT port.PORTFOLIO_NAME, '; ')                            as SETTLEMENT_PORTFOLIOS,
           'PORTFOLIOS'                                                           as SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
    WHERE port.PORTFOLIO_CATEGORY = 'Settlement'
    GROUP BY LOAN_ID)
   -- Get all loans with any settlement indicator (main population)
   , CUSTOM_FIELDS AS (
    -- Custom fields source
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
    GROUP BY cls.LOAN_ID)
   -- Sub status source
   , SUB_STATUS AS (SELECT a.LOAN_ID::VARCHAR AS LOAN_ID,
                           'SUB_STATUS'       AS SOURCE,
                           B.TITLE            AS CURRENT_STATUS,
                           A.LOAN_SUB_STATUS_ID
                    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT A
                             INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT B
                                        ON A.LOAN_SUB_STATUS_ID = B.ID
                                            AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
                    where a.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
                      AND A.DELETED = 0
                    group by ALL)
   , DOCUMENTS AS (SELECT LD.LOAN_ID,
                          DATE(MAX(ld.LASTUPDATED_TS))           AS LATEST_SETTLEMENT_DOCUMENT_UPDATE_DATE,
                          MAX_BY(LD.FILENAME, LD.LASTUPDATED_TS) AS LATEST_SETTLEMENT_DOCUMENT,
                          COUNT(LD.ID)                           as SETTLEMENT_DOCUMENTS_COUNT,
                          LISTAGG(LD.FILENAME, '; ')             as SETTLEMENT_DOCUMENTS,
                          'DOCUMENTS'                            as SOURCE
                   FROM BUSINESS_INTELLIGENCE.ANALYTICS.LOAN_DOCUMENTS LD
                   WHERE LD.SECTION_TITLE = 'Settlements'
                   GROUP BY LD.LOAN_ID)
   , settlement_loans AS (SELECT sl.LOAN_ID
                          FROM CUSTOM_FIELDS sl
                          UNION
                          -- Portfolio source
                          SELECT port.LOAN_ID
                          FROM PORTFOLIOS port
                          UNION
                          -- Sub Status Source
                          SELECT SS.LOAN_ID
                          FROM SUB_STATUS SS
                          WHERE SS.LOAN_SUB_STATUS_ID = '57'
                          UNION
                          -- Sub Status Source
                          SELECT D.LOAN_ID
                          FROM DOCUMENTS D)
-- Main query with efficient joins
SELECT sl.LOAN_ID,
       vlclsc.LEAD_GUID,
       -- Settlement Status Information
       vlclsc.SETTLEMENTSTATUS,
       sss.CURRENT_STATUS,
       -- Settlement Financial Information
       vlclsc.SETTLEMENT_AMOUNT,
       vlclsc.SETTLEMENT_AMOUNT_PAID,
       vlclsc.SETTLEMENTAGREEMENTAMOUNT,
       vlclsc.TOTAL_PAID_AT_TIME_OF_SETTLEMENT,
       vlclsc.PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT,
       vlclsc.AMOUNT_FORGIVEN,
       -- Settlement Company Information (consolidated for better data quality)
       COALESCE(vlclsc.DEBT_SETTLEMENT_COMPANY, vlclsc.SETTLEMENTCOMPANY)                                             as SETTLEMENT_COMPANY,
       -- Settlement Dates
       vlclsc.SETTLEMENT_ACCEPTED_DATE,
       vlclsc.SETTLEMENTSTARTDATE                                                                                     as SETTLEMENT_START_DATE,
       vlclsc.SETTLEMENTCOMPLETIONDATE                                                                                as SETTLEMENT_COMPLETION_DATE,
       vlclsc.EXPECTEDSETTLEMENTENDDATE                                                                               as EXPECTED_SETTLEMENT_END_DATE,
       -- Settlement Terms
       vlclsc.DEBTSETTLEMENTPAYMENTTERMS                                                                              as DEBT_SETTLEMENT_PAYMENT_TERMS,
       vlclsc.NUMBEROFDEBTSETTLEMENTPAYMENTSEXPECTED                                                                  as NUMBER_OF_DEBT_SETTLEMENT_PAYMENTS_EXPECTED,
       -- Portfolio Information
       sp.SETTLEMENT_PORTFOLIOS,
       sp.SETTLEMENT_PORTFOLIO_COUNT,
       sp.SETTLEMENT_SETUP_PORTFOLIO_DATE,
       sp.SETTLEMENT_SUCCESSFUL_PORTFOLIO_DATE,
       sp.SETTLEMENT_FAILED_PORTFOLIO_DATE,
       -- Documents Information
       d.SETTLEMENT_DOCUMENTS,
       d.SETTLEMENT_DOCUMENTS_COUNT,
       d.LATEST_SETTLEMENT_DOCUMENT,
       d.LATEST_SETTLEMENT_DOCUMENT_UPDATE_DATE,
       -- Data Source Flags (simplified logic)
       CASE WHEN cls.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                     as HAS_CUSTOM_FIELDS,
       CASE WHEN sp.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                      as HAS_SETTLEMENT_PORTFOLIO,
       CASE WHEN d.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END                                                       as HAS_SETTLEMENT_DOCUMENT,
       CASE
           WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN TRUE
           ELSE FALSE END                                                                                             as HAS_SETTLEMENT_SUB_STATUS,
       -- Data Source Summary (simplified calculation)
       COALESCE(
               CASE WHEN cls.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN d.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
               CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN 1 ELSE 0 END,
               0
       )                                                                                                              as DATA_SOURCE_COUNT,
       CASE
           WHEN DATA_SOURCE_COUNT = 4 THEN 'COMPLETE'
           WHEN DATA_SOURCE_COUNT = 2 OR DATA_SOURCE_COUNT = 3 THEN 'PARTIAL'
           ELSE 'SINGLE_SOURCE'
           END                                                                                                        as DATA_COMPLETENESS_FLAG,
       ARRAY_TO_STRING(
               ARRAY_COMPACT(ARRAY_CONSTRUCT(
                       CASE
                           WHEN cls.LOAN_ID IS NOT NULL THEN cls.SOURCE END,
                       CASE
                           WHEN sp.LOAN_ID IS NOT NULL THEN sp.SOURCE END,
                       CASE
                           WHEN d.LOAN_ID IS NOT NULL THEN d.SOURCE END,
                       CASE
                           WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS
                               = 'Closed - Settled in Full'
                               THEN sss.SOURCE END
                             )),
               ', '
       )                                                                                                              as DATA_SOURCE_LIST
FROM settlement_loans sl
         -- Settlement custom fields
         LEFT JOIN CUSTOM_FIELDS cls
                   ON sl.LOAN_ID = cls.LOAN_ID
    -- Portfolio data
         LEFT JOIN PORTFOLIOS sp
                   ON sl.LOAN_ID = sp.LOAN_ID
    -- sub status data
         LEFT JOIN SUB_STATUS sss
                   ON sl.LOAN_ID = sss.LOAN_ID
    -- documents data
         LEFT JOIN DOCUMENTS d
                   ON sl.LOAN_ID = d.LOAN_ID
    -- all custom fields
         INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT vlclsc
                    ON sl.LOAN_ID = vlclsc.LOAN_ID;
- **Existing Dependencies:** See DDL
- **Expected Changes:** We will add in two more data sources - business_intelligence.analytics.vw_loan_action_and_results and BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT. Search for the settlement related data in both of those sources and integrate them into the current view logic we have, first deploying it to dev for my review.
- **Backward Compatibility:** MAINTAIN
- **Source Migration:** No source migration needed, just two additional sources needed

## Data Grain & Aggregation
- **Grain:** One row per loan
- **Time Period:** All time
- **Key Dimensions:** loan_id

## Business Context
**Business Purpose:** This is an enhancement to the current BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT view to include 2 additional data sources that may contain debt settlement data. The two data sources are business_intelligence.analytics.vw_loan_action_and_results and BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT. 

**Primary Use Cases:** 
- Same as here: /Users/kchalmers/Development/data-intelligence-tickets/PRPs/debt_settlement_object_creation/INITIAL.md

**Key Metrics/KPIs:** Same as /Users/kchalmers/Development/data-intelligence-tickets/PRPs/debt_settlement_object_creation/INITIAL.md

## Data Sources
**New/Target Sources:** 
- See DDL above for how the current primary sources are joined
- business_intelligence.analytics.vw_loan_action_and_results
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT

**Expected Relationships:** loan_id

**Data Quality Considerations:** Some data may be missing from the new data sources, but it is expected that the data will be added in over time. The data from those sources may have a many : 1 relationship with loan_id, so we will need to handle that in the view logic.

**Expected Data Differences:** Additional loans may be added into the view as a result of the addition of these two data sources. These sources should be integrated as additional columns (JOIN), and then they should also be cited in the data source columns.

**Data Structure:** Will supporting data be integrated as additional columns (JOIN), and then also unioned in the settlement_loans cte

## Requirements
- **Performance:** as fast as possible
- **Data Retention:** all time

## Ticket Information
- **Existing Jira Ticket:** This is a part of the needs for https://happymoneyinc.atlassian.net/browse/DI-1235, so add a concise comment in here describing what we are doing
- **Stakeholders:** Kyle Chalmers

## Additional Context
Not that what we had originally built as a result of /Users/kchalmers/Development/data-intelligence-tickets/PRPs/debt_settlement_object_creation and https://happymoneyinc.atlassian.net/browse/DI-1262 has changed with the addition of the documentation data source. The current DDL is CORRECT. You can update a comment on DI-1262 and the readme.md and claude.md in that folder with the detail on these new changes as well.