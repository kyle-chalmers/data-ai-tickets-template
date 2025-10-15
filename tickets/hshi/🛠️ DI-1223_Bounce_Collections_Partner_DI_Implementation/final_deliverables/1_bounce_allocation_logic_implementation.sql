/*
================================================================================
DI-1223: Bounce Collections Partner - Account Allocation Logic Implementation
================================================================================

PURPOSE: Implement Bounce account allocation in BI-2482_Outbound_List_Generation_for_GR.py
BUSINESS LOGIC: Allocate 25% of Happy Money back book to Bounce (characters 4-7 of payoff UID)
INTEGRATION: Add to existing SIMM logic in BI-2482 outbound list generation job

ALLOCATION BREAKDOWN:
- Happy Money Internal: 25% (chars 0-3) - REDUCED from previous 50% (chars 0-7)
- Bounce Collections: 25% (chars 4-7) - NEW partner allocation
- SIMM Collections: 50% (chars 8-F) - UNCHANGED existing allocation

IMPLEMENTATION NOTES:
- Based on existing SIMM allocation logic (lines 373-393 in BI-2482)
- Uses same business rules: DPD3-119, excludes SST portfolio
- Same suppression logic as SIMM applies to Bounce
- Risk team (Davis/Harjot) has confirmed allocation approach
- IMPORTANT: Update DELETE statement to include 'BOUNCE' in list cleanup
*/

-- ========================================
-- REQUIRED UPDATE: TABLE CLEANUP
-- ========================================
-- CRITICAL: Update the DELETE statement in BI-2482 (lines 199-203)
-- Add 'BOUNCE' to the SET_NAME list to ensure proper daily cleanup

-- OLD DELETE statement:
-- where SET_NAME in ('Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly', 'Recovery Monthly Email', 'GR Physical Mail', 'SIMM', 'SST')

-- NEW DELETE statement (REQUIRED):
-- where SET_NAME in ('Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly', 'Recovery Monthly Email', 'GR Physical Mail', 'SIMM', 'SST', 'BOUNCE')

-- ========================================
-- BOUNCE ACCOUNT ALLOCATION QUERY
-- ========================================
-- To be integrated into BI-2482_Outbound_List_Generation_for_GR.py
-- Insert after existing SIMM allocation logic (around line 393)

-- Bounce Collections Allocation (NEW)
insert into CRON_STORE.RPT_OUTBOUND_LISTS
with SST as
         (select L.LEAD_GUID as PAYOFFUID
          from ANALYTICS.VW_LOAN as L
                   inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
                              on L.LOAN_ID = LP.LOAN_ID::string
                                  and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
                                  and LP.PORTFOLIO_ID = 205)
select current_date as LOAD_DATE,
       'BOUNCE'     as SET_NAME,
       'DPD3-119'   as LIST_NAME,
       PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       ASOFDATE     as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  and substring(PAYOFFUID, 16, 1) in ('4', '5', '6', '7')  -- Bounce gets 25% (half of Happy Money's original allocation)
  and PAYOFFUID not in (select SST.PAYOFFUID from SST);   -- Exclude SST portfolio

-- ========================================
-- UPDATED HAPPY MONEY ALLOCATION
-- ========================================
-- IMPORTANT: Update existing Happy Money Internal allocation in BI-2482
-- Change line ~350 in BI-2482_Outbound_List_Generation_for_GR.py

-- OLD Happy Money allocation (50%):
-- and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')

-- NEW Happy Money allocation (25%):
-- and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3')  -- Happy Money reduced to 25%

-- ========================================
-- ALLOCATION VERIFICATION QUERY
-- ========================================
-- Run this query to verify allocation percentages after implementation

SELECT 
    CASE 
        WHEN RIGHT(PAYOFFUID, 1) IN ('0','1','2','3') THEN 'HAPPY_MONEY'
        WHEN RIGHT(PAYOFFUID, 1) IN ('4','5','6','7') THEN 'BOUNCE'
        WHEN RIGHT(PAYOFFUID, 1) IN ('8','9','A','B','C','D','E','F') THEN 'SIMM'
        ELSE 'OTHER'
    END as allocation_partner,
    COUNT(*) as account_count,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() as percentage
FROM DATA_STORE.MVW_LOAN_TAPE
WHERE not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  AND ASOFDATE = current_date
GROUP BY 1
ORDER BY 2 DESC;

-- Expected Results:
-- SIMM: ~50%
-- HAPPY_MONEY: ~25% 
-- BOUNCE: ~25%

-- ========================================
-- SAMPLE BOUNCE ACCOUNT QUERY
-- ========================================
-- Generate sample list for initial testing

select PAYOFFUID,
       'DPD3-119' as LIST_NAME,
       ASOFDATE,
       DAYSPASTDUE,
       STATUS,
       REMAININGPRINCIPAL,
       ACCRUEDINTEREST
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  and substring(PAYOFFUID, 16, 1) in ('4', '5', '6', '7')  -- Bounce allocation
  and ASOFDATE = current_date
limit 100;  -- Sample for testing