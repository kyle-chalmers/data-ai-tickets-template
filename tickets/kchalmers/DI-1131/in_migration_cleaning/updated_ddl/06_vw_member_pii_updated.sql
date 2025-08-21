/***********************************************************************************************************************
UPDATED DDL for BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII
Date: 2025-08-18
Ticket: DI-1131
Changes: Added REGEXP_REPLACE to clean IN-MIGRATION- prefix from EMAIL fields in both LP and CLS sections
Purpose: Remove invalid "IN-MIGRATION-" prefix from email addresses at the source level
***********************************************************************************************************************/

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII COMMENT='LoanPro Member PII View - Updated with IN-MIGRATION email cleaning' AS
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