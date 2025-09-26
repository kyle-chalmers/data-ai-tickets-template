create or replace view BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT COPY GRANTS as
        WITH PORTFOLIOS as (-- Portfolio source
            SELECT port.LOAN_ID,
                   COUNT(port.PORTFOLIO_ID) as SETTLEMENT_PORTFOLIO_COUNT,
                LISTAGG(DISTINCT port.PORTFOLIO_NAME, '; ') as SETTLEMENT_PORTFOLIOS,
                'PORTFOLIOS' as SOURCE
            FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
            WHERE port.PORTFOLIO_CATEGORY = 'Settlement'
            GROUP BY port.LOAN_ID)
        -- Get all loans with any settlement indicator (main population)
        ,CUSTOM_FIELDS AS (
            -- Custom fields source
            SELECT cls.LOAN_ID,
                   'CUSTOM_FIELDS' as SOURCE
            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
            WHERE (cls.SETTLEMENTSTATUS IS NOT NULL AND cls.SETTLEMENTSTATUS <> '')
               OR (cls.SETTLEMENT_AMOUNT IS NOT NULL AND cls.SETTLEMENT_AMOUNT > 0)
               OR (cls.DEBT_SETTLEMENT_COMPANY IS NOT NULL AND cls.DEBT_SETTLEMENT_COMPANY <> '')
               OR (cls.SETTLEMENTCOMPANY IS NOT NULL AND cls.SETTLEMENTCOMPANY <> '')
               OR cls.SETTLEMENTSTARTDATE IS NOT NULL
               OR cls.SETTLEMENTAGREEMENTAMOUNT IS NOT NULL
               OR cls.DEBTSETTLEMENTPAYMENTTERMS IS NOT NULL
               OR cls.EXPECTEDSETTLEMENTENDDATE IS NOT NULL
                GROUP BY cls.LOAN_ID)
        -- Sub status source
        ,SUB_STATUS AS (SELECT a.LOAN_ID,
                               'SUB_STATUS' AS SOURCE,
                               B.TITLE AS CURRENT_STATUS,
                               A.LOAN_SUB_STATUS_ID
            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT A
            INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT B
            ON A.LOAN_SUB_STATUS_ID = B.ID
            AND B.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
            where a.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
            AND A.DELETED = 0
            group by ALL)
        ,settlement_loans AS  (
            SELECT sl.LOAN_ID
            FROM CUSTOM_FIELDS sl
            UNION
            -- Portfolio source
            SELECT port.LOAN_ID
            FROM PORTFOLIOS port
            UNION
            SELECT SS.LOAN_ID
            FROM SUB_STATUS SS
            WHERE SS.LOAN_SUB_STATUS_ID = '57')
        -- Main query with efficient joins
        SELECT
            sl.LOAN_ID,
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
            COALESCE(vlclsc.DEBT_SETTLEMENT_COMPANY, vlclsc.SETTLEMENTCOMPANY) as SETTLEMENT_COMPANY,
            -- Settlement Dates
            vlclsc.SETTLEMENT_ACCEPTED_DATE,
            vlclsc.SETTLEMENTSTARTDATE as SETTLEMENT_START_DATE,
            vlclsc.SETTLEMENTCOMPLETIONDATE as SETTLEMENT_COMPLETION_DATE,
            vlclsc.EXPECTEDSETTLEMENTENDDATE as EXPECTED_SETTLEMENT_END_DATE,
            -- Settlement Terms
            vlclsc.DEBTSETTLEMENTPAYMENTTERMS as DEBT_SETTLEMENT_PAYMENT_TERMS,
            -- Portfolio Information
            sp.SETTLEMENT_PORTFOLIOS,
            sp.SETTLEMENT_PORTFOLIO_COUNT,
            -- Data Source Flags (simplified logic)
            CASE WHEN cls.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_CUSTOM_FIELDS,
            CASE WHEN sp.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_PORTFOLIO,
            CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_SUB_STATUS,
            -- Data Source Summary (simplified calculation)
            COALESCE(
                CASE WHEN cls.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN 1 ELSE 0 END,
                0
            ) as DATA_SOURCE_COUNT,
            CASE
                WHEN DATA_SOURCE_COUNT = 3 THEN 'COMPLETE'
                WHEN DATA_SOURCE_COUNT = 2 THEN 'PARTIAL'
                ELSE 'SINGLE_SOURCE'
            END as DATA_COMPLETENESS_FLAG,
            REPLACE(CONCAT_WS(', ',
                CASE WHEN cls.LOAN_ID IS NOT NULL THEN cls.SOURCE ELSE '' END,
                CASE WHEN sp.LOAN_ID IS NOT NULL THEN sp.SOURCE ELSE '' END,
                CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN sss.SOURCE ELSE '' END
            ),' , ',' ') as DATA_SOURCE_LIST
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
        -- all custom fields
        LEFT JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT vlclsc
            ON sl.LOAN_ID = vlclsc.LOAN_ID;