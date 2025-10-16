-- DI-1293: Create VW_APP_CONTACT_RULES for Application-Level Contact Suppressions
-- Purpose: Separate application contact rules from loan contact rules following Kyle's architecture recommendation
-- Date: 2025-09-30

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS.VW_APP_CONTACT_RULES
COMMENT = 'Application-level contact suppression rules from LoanPro LOS. Separated from VW_LOAN_CONTACT_RULES per DI-1293.'
AS
SELECT
    APPLICATION_GUID,
    CASE
        WHEN SMS_CONSENT_LS = 'NO' THEN TRUE
        ELSE FALSE
    END AS SUPPRESS_TEXT,
    SMS_CONSENT_DATE_LS AS CONTACT_RULE_START_DATE,
    NULL AS CONTACT_RULE_END_DATE,
    'LOANPRO' AS SOURCE
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT
WHERE SMS_CONSENT_LS = 'NO';
