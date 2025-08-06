-- Bank Account Information Views Deployment Script
-- Creates LMS-filtered views in FRESHSNOW and BRIDGE schemas
-- Based on existing VW_BANK_INFO structure

DECLARE
    -- dev databases
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    v_rds_db varchar default 'DEVELOPMENT';
    
    -- prod databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    -- v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN
    -- FRESHSNOW section - Bank Account Information filtered to LMS
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_BANK_ACCOUNT_LMS(
            LOAN_ID COMMENT ''Loan identifier from loan_entity'',
            ACCOUNT_TYPE COMMENT ''Type of bank account'',
            ACCOUNT_NUMBER COMMENT ''Bank account number'',
            ROUTING_NUMBER COMMENT ''Bank routing number'',
            CUSTOMER_ID COMMENT ''Customer identifier'',
            CUSTOMER_NAME COMMENT ''Customer full name'',
            IS_PRIMARY_ACCOUNT COMMENT ''Flag indicating if this is the primary payment account'',
            ACCOUNT_ACTIVE COMMENT ''Flag indicating if the account is active'',
            CREATED_AT COMMENT ''Timestamp when account was created'',
            UPDATED_AT COMMENT ''Timestamp when account was last updated''
        ) COPY GRANTS AS 
        SELECT 
            le.id AS loan_id,
            cae.ACCOUNT_TYPE,
            cae.ACCOUNT_NUMBER,
            cae.ROUTING_NUMBER,
            ce.id AS customer_id,
            CONCAT(ce.FIRST_NAME, '' '', ce.LAST_NAME) AS customer_name,
            pae.is_primary AS is_primary_account,
            pae.active AS account_active,
            cae.CREATED AS created_at,
            cae.LASTUPDATED AS updated_at
        FROM ' || v_de_db || '.FRESHSNOW.loan_entity_current le
        JOIN ' || v_de_db || '.FRESHSNOW.loan_settings_entity_current lse 
            ON le.settings_id = lse.id
            AND lse.SCHEMA_NAME = ' || v_de_db || '.config.lms_schema()
        JOIN ' || v_de_db || '.FRESHSNOW.loan_customer_current lc 
            ON lc.loan_id = le.id 
            AND lc.customer_role = ''loan.customerRole.primary''
            AND lc.SCHEMA_NAME = ' || v_de_db || '.config.lms_schema()
        JOIN ' || v_de_db || '.pii.customer_entity_current ce 
            ON ce.id = lc.customer_id
            AND ce.SCHEMA_NAME = ' || v_de_db || '.config.lms_schema()
        LEFT JOIN ' || v_de_db || '.FRESHSNOW.payment_account_entity_current pae 
            ON ce.id = pae.entity_id 
            AND pae.SCHEMA_NAME = ' || v_de_db || '.config.lms_schema()
        LEFT JOIN ' || v_de_db || '.FRESHSNOW.checking_account_entity_current cae 
            ON pae.checking_account_id = cae.id
            AND cae.SCHEMA_NAME = ' || v_de_db || '.config.lms_schema()
        WHERE le.SCHEMA_NAME = ' || v_de_db || '.config.lms_schema()
    ');

    -- BRIDGE section - Pass-through from FRESHSNOW
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_BANK_ACCOUNT_LMS(
            LOAN_ID,
            ACCOUNT_TYPE,
            ACCOUNT_NUMBER,
            ROUTING_NUMBER,
            CUSTOMER_ID,
            CUSTOMER_NAME,
            IS_PRIMARY_ACCOUNT,
            ACCOUNT_ACTIVE,
            CREATED_AT,
            UPDATED_AT
        ) COPY GRANTS AS 
        SELECT 
            LOAN_ID,
            ACCOUNT_TYPE,
            ACCOUNT_NUMBER,
            ROUTING_NUMBER,
            CUSTOMER_ID,
            CUSTOMER_NAME,
            IS_PRIMARY_ACCOUNT,
            ACCOUNT_ACTIVE,
            CREATED_AT,
            UPDATED_AT
        FROM ' || v_de_db || '.FRESHSNOW.VW_BANK_ACCOUNT_LMS
    ');
    
    -- Optional: ANALYTICS section (uncomment if needed)
    -- EXECUTE IMMEDIATE (''
    --     CREATE OR REPLACE VIEW '' || v_bi_db || ''.ANALYTICS.VW_BANK_ACCOUNT_LMS(
    --         LOAN_ID,
    --         ACCOUNT_TYPE,
    --         ACCOUNT_NUMBER,
    --         ROUTING_NUMBER,
    --         CUSTOMER_ID,
    --         CUSTOMER_NAME,
    --         IS_PRIMARY_ACCOUNT,
    --         ACCOUNT_ACTIVE,
    --         CREATED_AT,
    --         UPDATED_AT
    --     ) COPY GRANTS AS 
    --     SELECT * FROM '' || v_bi_db || ''.BRIDGE.VW_BANK_ACCOUNT_LMS
    -- '');
    
    RETURN 'Bank Account LMS views successfully deployed to FRESHSNOW and BRIDGE schemas';
END;