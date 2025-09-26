/*
DI-1274: VW_LOAN_FRAUD Production Deployment Template
Based on documentation/db_deploy_template.sql pattern

This script deploys VW_LOAN_FRAUD across the 5-layer Snowflake architecture
*/

DECLARE
    -- Development databases (default for testing)
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';

    -- Production databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';

BEGIN
    -- FRESHSNOW section - Base layer with core fraud consolidation logic
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            FRAUD_INVESTIGATION_RESULTS,
            FRAUD_CONFIRMED_DATE,
            FRAUD_NOTIFICATION_RECEIVED,
            FRAUD_CONTACT_EMAIL,
            FOLLOW_UP_INFORMATION,
            EOS_CARD_DISPUTE_CODE,
            FRAUD_PORTFOLIOS,
            FRAUD_PORTFOLIO_COUNT,
            EARLIEST_FRAUD_PORTFOLIO_DATE,
            LATEST_FRAUD_PORTFOLIO_DATE,
            CURRENT_FRAUD_SUB_STATUS,
            FRAUD_SUB_STATUS_DATE,
            HAS_FRAUD_CUSTOM_FIELDS,
            HAS_FRAUD_PORTFOLIO,
            HAS_FRAUD_SUB_STATUS,
            FRAUD_DATA_SOURCE_COUNT,
            FRAUD_DATA_COMPLETENESS_FLAG,
            FRAUD_DATA_SOURCE_LIST,
            FRAUD_WORKFLOW_PROGRESSION_FLAG,
            FRAUD_DETERMINATION_CONFLICT_FLAG
        ) COPY GRANTS AS
        WITH custom_fields_source AS (
            SELECT
                cls.LOAN_ID,
                cls.LEAD_GUID,
                cls.FRAUD_INVESTIGATION_RESULTS,
                cls.FRAUD_CONFIRMED_DATE,
                cls.FRAUD_NOTIFICATION_RECEIVED,
                cls.FRAUD_CONTACT_EMAIL,
                cls.FOLLOW_UP_INFORMATION,
                cls.EOS_CARD_DISPUTE_CODE,
                ''CUSTOM_FIELDS'' as SOURCE
            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT cls
            WHERE cls.FRAUD_INVESTIGATION_RESULTS IS NOT NULL
               OR cls.FRAUD_CONFIRMED_DATE IS NOT NULL
               OR cls.FRAUD_CONTACT_EMAIL IS NOT NULL
               OR cls.FRAUD_NOTIFICATION_RECEIVED IS NOT NULL
               OR cls.EOS_CARD_DISPUTE_CODE IS NOT NULL
        ),
        portfolios_source AS (
            SELECT
                p.LOAN_ID,
                LISTAGG(DISTINCT p.PORTFOLIO_NAME, ''; '') as FRAUD_PORTFOLIOS,
                COUNT(DISTINCT p.PORTFOLIO_ID) as FRAUD_PORTFOLIO_COUNT,
                MIN(p.CREATED) as EARLIEST_FRAUD_PORTFOLIO_DATE,
                MAX(p.CREATED) as LATEST_FRAUD_PORTFOLIO_DATE,
                ''PORTFOLIOS'' as SOURCE,
                CASE
                    WHEN COUNT(CASE WHEN UPPER(p.PORTFOLIO_NAME) LIKE ''%DECLINED%'' THEN 1 END) > 0
                         AND COUNT(CASE WHEN UPPER(p.PORTFOLIO_NAME) LIKE ''%CONFIRMED%'' THEN 1 END) > 0
                    THEN TRUE ELSE FALSE
                END as HAS_WORKFLOW_PROGRESSION
            FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS p
            WHERE UPPER(p.PORTFOLIO_NAME) LIKE ''%FRAUD%''
            GROUP BY p.LOAN_ID
        ),
        sub_status_source AS (
            SELECT
                lse.LOAN_ID,
                ss.TITLE as CURRENT_FRAUD_SUB_STATUS,
                lse.LASTUPDATED as FRAUD_SUB_STATUS_DATE,
                ''SUB_STATUS'' as SOURCE
            FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lse
            JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT ss
                ON lse.LOAN_SUB_STATUS_ID = ss.ID
            WHERE UPPER(ss.TITLE) LIKE ''%FRAUD%''
                AND lse.SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
                AND ss.SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
                AND lse.DELETED = 0
        ),
        all_fraud_loans AS (
            SELECT LOAN_ID FROM custom_fields_source
            UNION
            SELECT LOAN_ID FROM portfolios_source
            UNION
            SELECT LOAN_ID FROM sub_status_source
        )
        SELECT
            afl.LOAN_ID,
            cfs.LEAD_GUID,
            cfs.FRAUD_INVESTIGATION_RESULTS,
            cfs.FRAUD_CONFIRMED_DATE,
            cfs.FRAUD_NOTIFICATION_RECEIVED,
            cfs.FRAUD_CONTACT_EMAIL,
            cfs.FOLLOW_UP_INFORMATION,
            cfs.EOS_CARD_DISPUTE_CODE,
            ps.FRAUD_PORTFOLIOS,
            ps.FRAUD_PORTFOLIO_COUNT,
            ps.EARLIEST_FRAUD_PORTFOLIO_DATE,
            ps.LATEST_FRAUD_PORTFOLIO_DATE,
            sss.CURRENT_FRAUD_SUB_STATUS,
            sss.FRAUD_SUB_STATUS_DATE,
            CASE WHEN cfs.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_CUSTOM_FIELDS,
            CASE WHEN ps.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_PORTFOLIO,
            CASE WHEN sss.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_SUB_STATUS,
            COALESCE(
                CASE WHEN cfs.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN ps.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
                CASE WHEN sss.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END,
                0
            ) as FRAUD_DATA_SOURCE_COUNT,
            CASE
                WHEN FRAUD_DATA_SOURCE_COUNT = 3 THEN ''COMPLETE''
                WHEN FRAUD_DATA_SOURCE_COUNT = 2 THEN ''PARTIAL''
                ELSE ''SINGLE_SOURCE''
            END as FRAUD_DATA_COMPLETENESS_FLAG,
            CONCAT_WS('', '',
                CASE WHEN cfs.LOAN_ID IS NOT NULL THEN ''CUSTOM_FIELDS'' END,
                CASE WHEN ps.LOAN_ID IS NOT NULL THEN ''PORTFOLIOS'' END,
                CASE WHEN sss.LOAN_ID IS NOT NULL THEN ''SUB_STATUS'' END
            ) as FRAUD_DATA_SOURCE_LIST,
            COALESCE(ps.HAS_WORKFLOW_PROGRESSION, FALSE) as FRAUD_WORKFLOW_PROGRESSION_FLAG,
            CASE
                WHEN cfs.FRAUD_INVESTIGATION_RESULTS = ''Declined''
                     AND (ps.FRAUD_PORTFOLIOS LIKE ''%Confirmed%'' OR sss.CURRENT_FRAUD_SUB_STATUS LIKE ''%Confirmed%'')
                THEN TRUE
                WHEN cfs.FRAUD_INVESTIGATION_RESULTS = ''Confirmed''
                     AND (ps.FRAUD_PORTFOLIOS LIKE ''%Declined%'' AND ps.FRAUD_PORTFOLIOS NOT LIKE ''%Confirmed%'')
                THEN TRUE
                ELSE FALSE
            END as FRAUD_DETERMINATION_CONFLICT_FLAG
        FROM all_fraud_loans afl
        LEFT JOIN custom_fields_source cfs ON afl.LOAN_ID = cfs.LOAN_ID
        LEFT JOIN portfolios_source ps ON afl.LOAN_ID = ps.LOAN_ID
        LEFT JOIN sub_status_source sss ON afl.LOAN_ID = sss.LOAN_ID
    ');

    -- ANALYTICS section (target layer for business-ready data)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            FRAUD_INVESTIGATION_RESULTS,
            FRAUD_CONFIRMED_DATE,
            FRAUD_NOTIFICATION_RECEIVED,
            FRAUD_CONTACT_EMAIL,
            FOLLOW_UP_INFORMATION,
            EOS_CARD_DISPUTE_CODE,
            FRAUD_PORTFOLIOS,
            FRAUD_PORTFOLIO_COUNT,
            EARLIEST_FRAUD_PORTFOLIO_DATE,
            LATEST_FRAUD_PORTFOLIO_DATE,
            CURRENT_FRAUD_SUB_STATUS,
            FRAUD_SUB_STATUS_DATE,
            HAS_FRAUD_CUSTOM_FIELDS,
            HAS_FRAUD_PORTFOLIO,
            HAS_FRAUD_SUB_STATUS,
            FRAUD_DATA_SOURCE_COUNT,
            FRAUD_DATA_COMPLETENESS_FLAG,
            FRAUD_DATA_SOURCE_LIST,
            FRAUD_WORKFLOW_PROGRESSION_FLAG,
            FRAUD_DETERMINATION_CONFLICT_FLAG
        ) COPY GRANTS AS
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_LOAN_FRAUD
    ');

    -- Return success message
    RETURN ''VW_LOAN_FRAUD successfully deployed to '' || v_de_db || ''.FRESHSNOW and '' || v_bi_db || ''.ANALYTICS'';
END;