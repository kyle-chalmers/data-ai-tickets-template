/***********************************************************************************************************************
DI-1131 Complete DEV Deployment Script for ALL ANALYTICS_PII Views with IN-MIGRATION Cleaning
Date: 2025-08-18
Author: Kyle Chalmers

Purpose: Deploy all three updated ANALYTICS_PII views with IN-MIGRATION email cleaning to DEV environment
Targets: 
- BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_MEMBER_PII
- BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_APPLICATION_PII  
- BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_LEAD_PII

Sources: Production ARCA.FRESHSNOW and BRIDGE tables (to test with real data)

IMPORTANT: 
- This script creates ALL three views in DEV environment for comprehensive testing
- Uses production data sources to validate the cleaning works correctly
- DO NOT RUN WITHOUT USER APPROVAL
- Run the validation queries after deployment to confirm the cleaning works
***********************************************************************************************************************/

-- ===========================================================================================================
-- 1. VW_MEMBER_PII - Highest Priority View
-- ===========================================================================================================
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_MEMBER_PII COPY GRANTS 
COMMENT='LoanPro Member PII View - DEV with IN-MIGRATION email cleaning' AS
--LP
SELECT MEMBER_ID::string as MEMBER_ID,
       FIRST_NAME,
       LAST_NAME,
       ADDRESS_1,
       ADDRESS_2,
       CITY,
       STATE,
       ZIP_CODE,
       '+1' ||
       iff(len(regexp_replace(PHONE_NUMBER, '[^[:digit:]]', '')) = 10,
           regexp_replace(PHONE_NUMBER, '[^[:digit:]]', ''),
           null)         as PHONE_NUMBER,
       REGEXP_REPLACE(EMAIL, '^IN-MIGRATION-', '') as EMAIL,  -- Clean IN-MIGRATION prefix
       DATE_OF_BIRTH,
       SSN,
       DBT_VALID_FROM    as MEMBER_PII_START_DATE,
       DBT_VALID_TO      as MEMBER_PII_END_DATE,
       'LOANPRO'         as SOURCE
FROM ARCA.FRESHSNOW.MEMBER_PII

UNION ALL
--CLS
--There might be duplicates here since the migrated flag hasn't been updated
--(loans already migrated to LP but still show false in the CLS migrated flag)
--but it should be fine since the LOAN_ID would be different.
SELECT DISTINCT ACC.ID                          as MEMBER_ID,
                ACP.BORROWER_S_FIRST_NAME       as FIRST_NAME,
                ACP.BORROWER_S_LAST_NAME        as LAST_NAME,
                ACP.ADDRESS_1                   as ADDRESS_1,
                ACP.ADDRESS_2                   as ADDRESS_2,
                ACC.CITY                        as CITY,
                ACC.STATE                       as STATE,
                ACC.ZIP_CODE                    as ZIP_CODE,
                '+1' ||
                iff(len(regexp_replace(ACC.PHONE, '[^[:digit:]]', '')) = 10,
                    regexp_replace(ACC.PHONE, '[^[:digit:]]', ''),
                    null)                       as PHONE_NUMBER,
                REGEXP_REPLACE(ACP.CNOTIFY_EMAIL, '^IN-MIGRATION-', '') as EMAIL,  -- Clean IN-MIGRATION prefix
                ACP.PEER_DATE_OF_BIRTH          as DATE_OF_BIRTH,
                ACP.LOAN_SOCIAL_SECURITY_NUMBER as SSN,
                ACC.CREATEDDATE                 as MEMBER_PII_START_DATE,
                null                            as MEMBER_PII_END_DATE,
                'CLS'                           as SOURCE
FROM BRIDGE.VW_CLS_LOAN_ACCOUNT_CURRENT as LA
         INNER JOIN BRIDGE.VW_CLS_APPLICATION_CURRENT as APP
                    ON LA.HK_H_APPL = APP.HK_H_APPL
         INNER JOIN BRIDGE.VW_CLS_ACCOUNT_CURRENT as ACC
                    ON APP.HK_H_ACCOUNT = ACC.HK_H_ACCOUNT
         INNER JOIN BRIDGE.VW_CLS_ACCOUNT_PII_CURRENT as ACP
                    ON ACC.ID = ACP.ID
WHERE ifnull(LA.MIGRATED_TO_LOANPRO, false) = false;

-- ===========================================================================================================
-- 2. VW_APPLICATION_PII - Middle Priority View
-- ===========================================================================================================
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_APPLICATION_PII COPY GRANTS 
COMMENT='LoanPro Application PII View - DEV with IN-MIGRATION email cleaning' AS
--LP
SELECT LE.ID::string              as APPLICATION_ID,
       CLS.APPLICATION_GUID       as LEAD_GUID,
       CLS.FIRST_NAME             as FIRST_NAME,
       CLS.LAST_NAME              as LAST_NAME,
       CLS.HOME_ADDRESS_STREET1   as ADDRESS_1,
       CLS.HOME_ADDRESS_STREET2   as ADDRESS_2,
       CLS.HOME_ADDRESS_CITY      as CITY,
       CLS.HOME_ADDRESS_STATE     as STATE,
       CLS.HOME_ADDRESS_ZIP       as ZIP_CODE,
       '+1' || iff(len(regexp_replace(CLS.PHONE, '[^[:digit:]]', '')) = 10,
                   regexp_replace(CLS.PHONE, '[^[:digit:]]', ''),
                   null)          as PHONE_NUMBER,
       REGEXP_REPLACE(CLS.EMAIL, '^IN-MIGRATION-', '') as EMAIL,  -- Clean IN-MIGRATION prefix
       CLS.DATE_OF_BIRTH          as DATE_OF_BIRTH,
       CLS.SOCIAL_SECURITY_NUMBER as SSN,
       'LOANPRO'                  as SOURCE
FROM ARCA.FRESHSNOW.LOAN_ENTITY_CURRENT as LE
         INNER JOIN ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as CLS
                    ON LE.ID = CLS.LOAN_ID
WHERE LE.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
  AND CLS.APPLICATION_SUBMITTED_DATE IS NOT NULL
  AND ifnull(CLS.MIGRATED_FROM_CLS, '') <> '1'

UNION ALL
--CLS
SELECT APPLICATION_ID,
       LEAD_GUID,
       FIRST_NAME,
       LAST_NAME,
       ADDRESS_1,
       ADDRESS_2,
       CITY,
       STATE,
       ZIP_CODE,
       '+1' ||
       iff(len(regexp_replace(PHONE_NUMBER, '[^[:digit:]]', '')) = 10,
           regexp_replace(PHONE_NUMBER, '[^[:digit:]]', ''),
           null) as PHONE_NUMBER,
       REGEXP_REPLACE(EMAIL, '^IN-MIGRATION-', '') as EMAIL,  -- Clean IN-MIGRATION prefix
       DATE_OF_BIRTH,
       SSN,
       'CLS'     as SOURCE
FROM ARCA.FRESHSNOW.VW_CLS_APPLICATION_PII;

-- ===========================================================================================================
-- 3. VW_LEAD_PII - Lowest Priority View
-- ===========================================================================================================
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS_PII.VW_LEAD_PII COPY GRANTS 
COMMENT='LoanPro Lead PII View - DEV with IN-MIGRATION email cleaning' AS
--CLS
SELECT LEAD_GUID,
       FIRST_NAME,
       LAST_NAME,
       ADDRESS_1,
       ADDRESS_2,
       CITY,
       STATE,
       ZIP_CODE,
       '+1' ||
       iff(len(regexp_replace(PHONE_NUMBER, '[^[:digit:]]', '')) = 10,
           regexp_replace(PHONE_NUMBER, '[^[:digit:]]', ''),
           null) as PHONE_NUMBER,
       REGEXP_REPLACE(EMAIL, '^IN-MIGRATION-', '') as EMAIL,  -- Clean IN-MIGRATION prefix
       DATE_OF_BIRTH,
       SSN,
       'CLS'     as SOURCE
FROM ARCA.FRESHSNOW.VW_CLS_LEAD_PII

UNION ALL
--LP
SELECT CLS.APPLICATION_GUID       as LEAD_GUID,
       CLS.FIRST_NAME             as FIRST_NAME,
       CLS.LAST_NAME              as LAST_NAME,
       CLS.HOME_ADDRESS_STREET1   as ADDRESS_1,
       CLS.HOME_ADDRESS_STREET2   as ADDRESS_2,
       CLS.HOME_ADDRESS_CITY      as CITY,
       CLS.HOME_ADDRESS_STATE     as STATE,
       CLS.HOME_ADDRESS_ZIP       as ZIP_CODE,
       '+1' ||
       iff(len(regexp_replace(CLS.PHONE, '[^[:digit:]]', '')) = 10,
           regexp_replace(CLS.PHONE, '[^[:digit:]]', ''),
           null)                  as PHONE_NUMBER,
       REGEXP_REPLACE(CLS.EMAIL, '^IN-MIGRATION-', '') as EMAIL,  -- Clean IN-MIGRATION prefix
       CLS.DATE_OF_BIRTH          as DATE_OF_BIRTH,
       CLS.SOCIAL_SECURITY_NUMBER as SSN,
       'LOANPRO'                  as SOURCE
FROM ARCA.FRESHSNOW.LOAN_ENTITY_CURRENT as LE
         INNER JOIN ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as CLS
                    ON LE.ID = CLS.LOAN_ID
WHERE LE.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
  AND ifnull(CLS.MIGRATED_FROM_CLS, '') <> '1';

-- ===========================================================================================================
-- DEPLOYMENT VERIFICATION
-- ===========================================================================================================
-- Run a quick verification query to ensure all views were created successfully
SELECT 
    'DEPLOYMENT_VERIFICATION' as check_type,
    table_name,
    'SUCCESS' as status
FROM information_schema.views 
WHERE table_schema = 'ANALYTICS_PII' 
  AND table_catalog = 'BUSINESS_INTELLIGENCE_DEV'
  AND table_name IN ('VW_MEMBER_PII', 'VW_APPLICATION_PII', 'VW_LEAD_PII')
ORDER BY table_name;

/*
NEXT STEPS AFTER DEPLOYMENT:
1. Run the validation queries from 02_validate_in_migration_cleaning.sql
2. Compare IN-MIGRATION email counts before/after cleaning
3. Verify record counts remain identical between production and DEV cleaned versions
4. Test the end-to-end impact on the email lookup table logic
*/