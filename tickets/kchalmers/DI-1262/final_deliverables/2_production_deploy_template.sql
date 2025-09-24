/*
DI-1262: LOAN_DEBT_SETTLEMENT Production Deployment Template
Multi-environment deployment following architectural standards

DEPLOYMENT PROCESS:
1. Review and approve development results
2. Execute this script in production environment
3. Validate production deployment with QC checks

Based on: documentation/db_deploy_template.sql
*/

USE WAREHOUSE BUSINESS_INTELLIGENCE;
USE ROLE BUSINESS_INTELLIGENCE;

DECLARE
    -- dev databases
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    v_rds_db varchar default 'RAW_DATA_STORE';

    -- prod databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    -- v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN
    -- ANALYTICS section (Final deployment target)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
        COPY GRANTS AS
        WITH custom_settings_source AS (
            -- All loans with settlement indicators in custom fields
            SELECT
                CAST(cls.LOAN_ID AS VARCHAR) as LOAN_ID,
                cls.LEAD_GUID,

                -- Settlement Status Information
                cls.SETTLEMENTSTATUS,

                -- Settlement Financial Information
                cls.SETTLEMENT_AMOUNT,
                cls.SETTLEMENT_AMOUNT_PAID,
                cls.SETTLEMENTAGREEMENTAMOUNT,
                cls.TOTAL_PAID_AT_TIME_OF_SETTLEMENT,
                cls.PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT,
                cls.AMOUNT_FORGIVEN,
                CASE
                    WHEN cls.SETTLEMENTCOMPLETIONPERCENTAGE IS NOT NULL
                    THEN cls.SETTLEMENTCOMPLETIONPERCENTAGE
                    WHEN cls.SETTLEMENT_AMOUNT IS NOT NULL AND cls.SETTLEMENT_AMOUNT > 0
                         AND cls.SETTLEMENT_AMOUNT_PAID IS NOT NULL
                    THEN ROUND((cls.SETTLEMENT_AMOUNT_PAID / cls.SETTLEMENT_AMOUNT) * 100, 2)
                    ELSE NULL
                END as SETTLEMENT_COMPLETION_PERCENTAGE,

                -- Settlement Company Information
                cls.SETTLEMENTCOMPANY,
                cls.DEBT_SETTLEMENT_COMPANY,

                -- Settlement Dates
                cls.SETTLEMENT_ACCEPTED_DATE,
                cls.SETTLEMENTSTARTDATE as SETTLEMENT_START_DATE,
                cls.SETTLEMENTCOMPLETIONDATE as SETTLEMENT_COMPLETION_DATE,
                cls.EXPECTEDSETTLEMENTENDDATE as EXPECTED_SETTLEMENT_END_DATE,

                -- Settlement Terms and Conditions
                cls.DEBTSETTLEMENTPAYMENTTERMS as DEBT_SETTLEMENT_PAYMENT_TERMS,

                -- Data Source Tracking
                ''CUSTOM_FIELDS'' as DATA_SOURCE,
                CASE
                    WHEN cls.SETTLEMENTSTATUS IS NOT NULL
                         OR cls.SETTLEMENT_AMOUNT IS NOT NULL
                         OR cls.DEBT_SETTLEMENT_COMPANY IS NOT NULL
                    THEN TRUE
                    ELSE FALSE
                END as HAS_CUSTOM_FIELDS,

                CONVERT_TIMEZONE(''UTC'', ''America/Los_Angeles'', CURRENT_TIMESTAMP) as CREATED_DATE_PT,
                CONVERT_TIMEZONE(''UTC'', ''America/Los_Angeles'', CURRENT_TIMESTAMP) as LAST_UPDATED_DATE_PT

            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
            WHERE (cls.SETTLEMENTSTATUS IS NOT NULL AND cls.SETTLEMENTSTATUS <> '''')
               OR (cls.SETTLEMENT_AMOUNT IS NOT NULL AND cls.SETTLEMENT_AMOUNT > 0)
               OR (cls.DEBT_SETTLEMENT_COMPANY IS NOT NULL AND cls.DEBT_SETTLEMENT_COMPANY <> '''')
               OR (cls.SETTLEMENTCOMPANY IS NOT NULL AND cls.SETTLEMENTCOMPANY <> '''')
               OR cls.SETTLEMENTSTARTDATE IS NOT NULL
               OR cls.SETTLEMENTAGREEMENTAMOUNT IS NOT NULL
               OR cls.DEBTSETTLEMENTPAYMENTTERMS IS NOT NULL
               OR cls.EXPECTEDSETTLEMENTENDDATE IS NOT NULL
        ),

        portfolio_source AS (
            -- All loans with settlement portfolio assignments
            SELECT DISTINCT
                CAST(port.LOAN_ID AS VARCHAR) as LOAN_ID,
                NULL as LEAD_GUID,

                -- Settlement fields (NULL for portfolio-only loans)
                NULL as SETTLEMENTSTATUS,
                NULL as SETTLEMENT_AMOUNT,
                NULL as SETTLEMENT_AMOUNT_PAID,
                NULL as SETTLEMENTAGREEMENTAMOUNT,
                NULL as TOTAL_PAID_AT_TIME_OF_SETTLEMENT,
                NULL as PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT,
                NULL as AMOUNT_FORGIVEN,
                NULL as SETTLEMENT_COMPLETION_PERCENTAGE,
                NULL as SETTLEMENTCOMPANY,
                NULL as DEBT_SETTLEMENT_COMPANY,
                NULL as SETTLEMENT_ACCEPTED_DATE,
                NULL as SETTLEMENT_START_DATE,
                NULL as SETTLEMENT_COMPLETION_DATE,
                NULL as EXPECTED_SETTLEMENT_END_DATE,
                NULL as DEBT_SETTLEMENT_PAYMENT_TERMS,

                -- Data Source Tracking
                ''PORTFOLIO'' as DATA_SOURCE,
                FALSE as HAS_CUSTOM_FIELDS,
                CONVERT_TIMEZONE(''UTC'', ''America/Los_Angeles'', port.CREATED) as CREATED_DATE_PT,
                CONVERT_TIMEZONE(''UTC'', ''America/Los_Angeles'', port.LASTUPDATED) as LAST_UPDATED_DATE_PT

            FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
            WHERE port.PORTFOLIO_CATEGORY = ''Settlement''
              AND port.LOAN_ID NOT IN (SELECT LOAN_ID FROM custom_settings_source)
        ),

        sub_status_source AS (
            -- All loans with settlement sub status (current only) - FIXED: Proper deduplication
            SELECT
                CAST(lsac.LOAN_ID AS VARCHAR) as LOAN_ID,
                NULL as LEAD_GUID,

                -- Settlement fields (NULL for sub status-only loans)
                NULL as SETTLEMENTSTATUS,
                NULL as SETTLEMENT_AMOUNT,
                NULL as SETTLEMENT_AMOUNT_PAID,
                NULL as SETTLEMENTAGREEMENTAMOUNT,
                NULL as TOTAL_PAID_AT_TIME_OF_SETTLEMENT,
                NULL as PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT,
                NULL as AMOUNT_FORGIVEN,
                NULL as SETTLEMENT_COMPLETION_PERCENTAGE,
                NULL as SETTLEMENTCOMPANY,
                NULL as DEBT_SETTLEMENT_COMPANY,
                NULL as SETTLEMENT_ACCEPTED_DATE,
                NULL as SETTLEMENT_START_DATE,
                NULL as SETTLEMENT_COMPLETION_DATE,
                NULL as EXPECTED_SETTLEMENT_END_DATE,
                NULL as DEBT_SETTLEMENT_PAYMENT_TERMS,

                -- Data Source Tracking
                ''SUB_STATUS'' as DATA_SOURCE,
                FALSE as HAS_CUSTOM_FIELDS,
                CONVERT_TIMEZONE(''UTC'', ''America/Los_Angeles'', lsac.DATE) as CREATED_DATE_PT,
                CONVERT_TIMEZONE(''UTC'', ''America/Los_Angeles'', lsac.LASTUPDATED) as LAST_UPDATED_DATE_PT

            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT lsac
            WHERE lsac.LOAN_SUB_STATUS_TEXT = ''Closed - Settled in Full''
              AND lsac.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
              AND lsac.LOAN_ID NOT IN (SELECT LOAN_ID FROM custom_settings_source)
              AND lsac.LOAN_ID NOT IN (SELECT LOAN_ID FROM portfolio_source)
            QUALIFY ROW_NUMBER() OVER (PARTITION BY lsac.LOAN_ID ORDER BY lsac.DATE DESC, lsac.LASTUPDATED DESC) = 1
        ),

        settlement_portfolios AS (
            -- Portfolio aggregation following VW_LOAN_BANKRUPTCY pattern
            SELECT
                CAST(port.LOAN_ID AS VARCHAR) as LOAN_ID,
                LISTAGG(DISTINCT port.PORTFOLIO_NAME, ''; '') as SETTLEMENT_PORTFOLIOS,
                COUNT(DISTINCT port.PORTFOLIO_NAME) as SETTLEMENT_PORTFOLIO_COUNT
            FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
            WHERE port.PORTFOLIO_CATEGORY = ''Settlement''
            GROUP BY port.LOAN_ID
        ),

        settlement_sub_status AS (
            -- Current settlement sub status for each loan
            SELECT
                CAST(lsac.LOAN_ID AS VARCHAR) as LOAN_ID,
                lsac.LOAN_SUB_STATUS_TEXT as CURRENT_SUB_STATUS_TEXT,
                lsac.DATE as SUB_STATUS_DATE
            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_STATUS_ARCHIVE_CURRENT lsac
            WHERE lsac.LOAN_SUB_STATUS_TEXT = ''Closed - Settled in Full''
              AND lsac.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
            QUALIFY ROW_NUMBER() OVER (PARTITION BY lsac.LOAN_ID ORDER BY lsac.DATE DESC) = 1
        ),

        all_settlement_loans AS (
            -- Union all three sources
            SELECT * FROM custom_settings_source
            UNION ALL
            SELECT * FROM portfolio_source
            UNION ALL
            SELECT * FROM sub_status_source
        )

        -- Final consolidation with all data sources
        SELECT
            CAST(a.LOAN_ID AS VARCHAR) as LOAN_ID,
            a.LEAD_GUID,

            -- Settlement Status Information
            a.SETTLEMENTSTATUS,
            sss.CURRENT_SUB_STATUS_TEXT,
            sss.SUB_STATUS_DATE,

            -- Settlement Financial Information
            a.SETTLEMENT_AMOUNT,
            a.SETTLEMENT_AMOUNT_PAID,
            a.SETTLEMENTAGREEMENTAMOUNT,
            a.TOTAL_PAID_AT_TIME_OF_SETTLEMENT,
            a.PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT,
            a.AMOUNT_FORGIVEN,
            a.SETTLEMENT_COMPLETION_PERCENTAGE,

            -- Settlement Company Information
            a.SETTLEMENTCOMPANY,
            a.DEBT_SETTLEMENT_COMPANY,

            -- Settlement Dates
            a.SETTLEMENT_ACCEPTED_DATE,
            a.SETTLEMENT_START_DATE,
            a.SETTLEMENT_COMPLETION_DATE,
            a.EXPECTED_SETTLEMENT_END_DATE,

            -- Settlement Terms
            a.DEBT_SETTLEMENT_PAYMENT_TERMS,

            -- Portfolio Information (following VW_LOAN_BANKRUPTCY pattern)
            sp.SETTLEMENT_PORTFOLIOS,
            sp.SETTLEMENT_PORTFOLIO_COUNT,
            CASE WHEN sp.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_PORTFOLIO,

            -- Data Source Tracking
            a.DATA_SOURCE as PRIMARY_DATA_SOURCE,
            a.HAS_CUSTOM_FIELDS,
            CASE WHEN sp.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_PORTFOLIO_FLAG,
            CASE WHEN sss.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_SUB_STATUS,

            -- Data Source Summary
            CASE
                WHEN a.HAS_CUSTOM_FIELDS = TRUE
                     AND sp.LOAN_ID IS NOT NULL
                     AND sss.LOAN_ID IS NOT NULL THEN 3
                WHEN (a.HAS_CUSTOM_FIELDS = TRUE AND sp.LOAN_ID IS NOT NULL)
                     OR (a.HAS_CUSTOM_FIELDS = TRUE AND sss.LOAN_ID IS NOT NULL)
                     OR (sp.LOAN_ID IS NOT NULL AND sss.LOAN_ID IS NOT NULL) THEN 2
                ELSE 1
            END as DATA_SOURCE_COUNT,

            CASE
                WHEN a.HAS_CUSTOM_FIELDS = TRUE
                     AND sp.LOAN_ID IS NOT NULL
                     AND sss.LOAN_ID IS NOT NULL THEN ''COMPLETE''
                WHEN CASE
                        WHEN a.HAS_CUSTOM_FIELDS = TRUE THEN 1 ELSE 0 END +
                     CASE
                        WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
                     CASE
                        WHEN sss.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END >= 2 THEN ''PARTIAL''
                ELSE ''SINGLE_SOURCE''
            END as DATA_COMPLETENESS_FLAG,

            CONCAT_WS('', '',
                CASE WHEN a.HAS_CUSTOM_FIELDS = TRUE THEN ''CUSTOM_FIELDS'' END,
                CASE WHEN sp.LOAN_ID IS NOT NULL THEN ''PORTFOLIO'' END,
                CASE WHEN sss.LOAN_ID IS NOT NULL THEN ''SUB_STATUS'' END
            ) as DATA_SOURCE_LIST,

            -- Metadata
            a.CREATED_DATE_PT,
            a.LAST_UPDATED_DATE_PT

        FROM all_settlement_loans a
        LEFT JOIN settlement_portfolios sp ON a.LOAN_ID = sp.LOAN_ID
        LEFT JOIN settlement_sub_status sss ON a.LOAN_ID = sss.LOAN_ID
    ');

END;

-- ============================================
-- POST-DEPLOYMENT VALIDATION
-- ============================================

-- Validate deployment success
SELECT 'Deployment Validation' as step, 'Checking object existence' as status;

-- Check ANALYTICS view exists
SHOW VIEWS LIKE 'VW_LOAN_DEBT_SETTLEMENT' IN SCHEMA BUSINESS_INTELLIGENCE.ANALYTICS;

-- Validate record counts
SELECT 'Record Count Validation' as step,
       COUNT(*) as record_count,
       'Expected: ~14,068 loans' as expected
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT;

-- Validate data source tracking
SELECT 'Data Source Distribution' as step,
       DATA_COMPLETENESS_FLAG,
       COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
GROUP BY DATA_COMPLETENESS_FLAG
ORDER BY loan_count DESC;