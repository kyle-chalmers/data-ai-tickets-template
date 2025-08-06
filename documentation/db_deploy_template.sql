/* 
Deploy script template
*/

DECLARE
    -- dev databases
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    v_rds_db varchar default 'DEVELOPMENT';
    
    -- prod databases
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
    -- v_rds_db varchar default 'RAW_DATA_STORE';

BEGIN

-- FRESHNOW section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_APPL_HISTORY_TEST(
        	ENTITY_ID,
        	REFERENCE_TYPE
        ) COPY GRANTS AS 
            SELECT 
                ENTITY_ID,
            	REFERENCE_TYPE
            FROM ' || v_rds_db ||'.LOANPRO.SYSTEM_NOTE_ENTITY
    ');

-- BRIDGE section    
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_APPL_HISTORY(
        	ENTITY_ID,
        	REFERENCE_TYPE
        ) COPY GRANTS AS 
            SELECT 
                ENTITY_ID,
            	REFERENCE_TYPE
            FROM ' || v_de_db ||'.FRESHSNOW.VW_APPL_HISTORY
    ');
    
-- ANALYTICS section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_APPL_HISTORY(
        	ENTITY_ID,
        	REFERENCE_TYPE
        ) COPY GRANTS AS 
            SELECT 
                ENTITY_ID,
            	REFERENCE_TYPE
            FROM ' || v_bi_db ||'.BRIDGE.VW_APPL_HISTORY
    ');
   
END;


    