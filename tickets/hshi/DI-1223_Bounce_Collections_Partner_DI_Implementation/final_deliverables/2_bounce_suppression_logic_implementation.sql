/*
================================================================================
DI-1223: Bounce Collections Partner - Suppression Logic Implementation
================================================================================

PURPOSE: Implement Bounce-specific suppression logic in BI-2482_Outbound_List_Generation_for_GR.py
BUSINESS LOGIC: Exclude Bounce accounts from Happy Money internal email campaigns
INTEGRATION: Add to existing suppression logic in BI-2482 (section 3.2.8)

SUPPRESSION REQUIREMENTS:
1. Apply all global suppressions to Bounce (same as SIMM)
2. Add cross-set suppression to exclude Bounce accounts from internal email campaigns
3. Handle multi-channel suppression (Bounce handles phone, SMS, AND email)

NOTE: Scope of email campaign suppression needs clarification - marked for follow-up
*/

-- ========================================
-- GLOBAL SUPPRESSION FOR BOUNCE
-- ========================================
-- All existing global suppressions from BI-2482 apply to Bounce
-- No additional code needed - global suppressions automatically apply to all sets

-- Existing global suppressions that will apply to Bounce:
-- - Bankruptcy flags
-- - Cease & desist contact rules
-- - One-time payment (OTP) requests
-- - Loan modifications
-- - Natural disaster areas
-- - Individual manual suppressions
-- - Next workable date restrictions
-- - 3rd party placements

-- ========================================
-- BOUNCE SET-LEVEL SUPPRESSION
-- ========================================
-- Bounce handles ALL communication channels (phone, SMS, email)
-- Apply comprehensive channel suppression

-- To be added to BI-2482 suppression section (after existing set suppressions)

-- Bounce Multi-Channel Suppression
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date                          as LOAD_DATE,
       'Set'                                 as SUPPRESSION_TYPE,
       'DNC: Phone/Text/Email/Letter'       as SUPPRESSION_REASON,
       L.LEAD_GUID                          as PAYOFF_UID,
       'BOUNCE'                             as SET_NAME,
       'N/A'                                as LIST_NAME
from ANALYTICS.VW_LOAN as L
         inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                        and LCR.CONTACT_RULE_END_DATE is null
         left join CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION as SP
                   on L.LEAD_GUID = SP.PAYOFFUID
                       and SP.SUPPRESSION_TYPE = 'Global'
where (LCR.SUPPRESS_PHONE = true 
    OR LCR.SUPPRESS_TEXT = true 
    OR LCR.SUPPRESS_EMAIL = true 
    OR LCR.SUPPRESS_LETTER = true)  -- Any channel suppression excludes from Bounce
  and SP.PAYOFFUID is null;

-- ========================================
-- CROSS-SET SUPPRESSION: BOUNCE vs INTERNAL CAMPAIGNS
-- ========================================
-- CRITICAL: Prevent Bounce accounts from appearing in Happy Money internal campaigns
-- **CLARIFICATION NEEDED**: Which specific campaigns should suppress Bounce accounts?

-- Email Campaign Suppression (EXAMPLE - needs scope clarification)
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Cross Set'  as SUPPRESSION_TYPE,
       'BOUNCE'     as SUPPRESSION_REASON,
       PAYOFFUID,
       'GR Email'   as SET_NAME,    -- **TO BE CONFIRMED**: Which campaigns need suppression?
       'N/A'        as LIST_NAME
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME = 'BOUNCE';

-- **CLARIFICATION REQUIRED**: 
-- The above query suppresses Bounce accounts from 'GR Email' campaigns only.
-- Business decision needed on complete scope:
-- 
-- OPTION 1: Suppress from ALL Happy Money email campaigns
-- - GR Email (collections emails)
-- - Marketing emails  
-- - Customer engagement emails
-- - Prescreen campaigns
--
-- OPTION 2: Suppress only from collections-related email campaigns
-- - GR Email only
-- - Leave marketing/engagement emails unchanged
--
-- OPTION 3: Suppress from all internal communication channels
-- - All email campaigns
-- - Internal SMS campaigns  
-- - Internal call campaigns
--
-- **ACTION ITEM**: Document this question for business team clarification

-- ========================================
-- SUPPRESSION VERIFICATION QUERY
-- ========================================
-- Verify suppression logic is working correctly

-- Check Bounce account suppression counts
SELECT 
    SUPPRESSION_TYPE,
    SUPPRESSION_REASON,
    SET_NAME,
    COUNT(*) as suppressed_count
FROM CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
WHERE PAYOFFUID IN (
    SELECT PAYOFFUID 
    FROM CRON_STORE.RPT_OUTBOUND_LISTS 
    WHERE SET_NAME = 'BOUNCE'
)
  AND LOAD_DATE = current_date
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

-- Verify no Bounce accounts in internal email campaigns
SELECT 
    OL.SET_NAME,
    OL.LIST_NAME,
    COUNT(*) as account_count,
    COUNT(CASE WHEN bounce_check.PAYOFFUID IS NOT NULL THEN 1 END) as bounce_accounts_found
FROM CRON_STORE.RPT_OUTBOUND_LISTS OL
LEFT JOIN (
    SELECT PAYOFFUID 
    FROM CRON_STORE.RPT_OUTBOUND_LISTS 
    WHERE SET_NAME = 'BOUNCE'
      AND LOAD_DATE = current_date
) bounce_check ON OL.PAYOFFUID = bounce_check.PAYOFFUID
WHERE OL.SET_NAME LIKE '%Email%'  -- Check email campaigns
  AND OL.LOAD_DATE = current_date
  AND OL.SUPPRESSION_FLAG = false
GROUP BY 1, 2
HAVING bounce_accounts_found > 0;  -- Should return 0 rows if suppression working correctly