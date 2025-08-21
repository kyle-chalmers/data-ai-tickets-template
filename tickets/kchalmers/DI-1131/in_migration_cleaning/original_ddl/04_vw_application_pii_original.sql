/***********************************************************************************************************************
ORIGINAL DDL for BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_APPLICATION_PII
Retrieved: 2025-08-18
Purpose: Backup of original view definition before applying IN-MIGRATION cleaning
***********************************************************************************************************************/

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_APPLICATION_PII AS
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
       CLS.EMAIL                  as EMAIL,
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
       EMAIL,
       DATE_OF_BIRTH,
       SSN,
       'CLS'     as SOURCE
FROM ARCA.FRESHSNOW.VW_CLS_APPLICATION_PII;