-- DI-1293: Update VW_LOAN_CONTACT_RULES to Remove Application Data
-- Purpose: Remove sms_consent CTE and APPLICATION_GUID - application data now in VW_APP_CONTACT_RULES
-- This view will now be a simple pass-through from BRIDGE layer (loan-level data only)
-- Date: 2025-09-30

CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES
COMMENT = 'Loan-level contact suppression rules. Application-level rules moved to VW_APP_CONTACT_RULES per DI-1293.'
AS
SELECT * FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CONTACT_RULES;