"""
DI-912: Updated dist_auto CTE for BI-1451 Loss Forecasting
Purpose: Replace DATA_STORE.VW_LOAN_COLLECTION with ANALYTICS/BRIDGE pattern
Author: Hongxia Shi
Date: 2025-10-01

CHANGES REQUIRED:
- File: /Users/hshi/WOW/business-intelligence-data-jobs/jobs/BI-1451_Loss_Forecasting/BI-1451_Loss_Forecasting.py
- Lines: 574-581 (dist_auto CTE definition)
"""

# ============================================================================
# ORIGINAL CODE (Lines 574-581) - TO BE REPLACED
# ============================================================================
# OLD_CODE = """
#       , dist_auto as (select PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
#                       from DATA_STORE.VW_LOAN_COLLECTION
#                            -- three loans are excluded with this condition because of duplicates or two values:
#                            -- a76f33d5-00e8-4f7e-a4d3-65d3907b383f, 4d8d470b-64de-4f3e-8857-593e7b3a4058, 4ba57978-06d4-4e70-b866-2bcfe4d235f3
#                       where PAYOFF_UID in (select PAYOFF_UID
#                                            from DATA_STORE.VW_LOAN_COLLECTION
#                                            group by 1
#                                            having count(*) < 2))
# """

# ============================================================================
# NEW CODE - ANALYTICS/BRIDGE PATTERN
# ============================================================================
NEW_CODE = """
       , dist_auto as (
            -- DI-912: Migrated from DATA_STORE.VW_LOAN_COLLECTION to ANALYTICS/BRIDGE
            -- CEASE_AND_DESIST: from VW_LOAN_CONTACT_RULES
            -- BANKRUPTCY_FLAG: from VW_LOAN_BANKRUPTCY
            -- DEBIT_BILL_AUTOMATIC: from VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT (autopay)
            select
                L.LEAD_GUID as PAYOFF_UID,
                LCR.CEASE_AND_DESIST,
                COALESCE(BK.BANKRUPTCY_FLAG, FALSE) as BANKRUPTCY_FLAG,
                IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) as DEBIT_BILL_AUTOMATIC
            from ANALYTICS.VW_LOAN as L
                left join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                    and LCR.CONTACT_RULE_END_DATE is null
                left join ANALYTICS.VW_LOAN_BANKRUPTCY as BK
                    on L.LEAD_GUID = BK.PAYOFF_UID
                    and BK.ACTIVE_RECORD_FLAG = TRUE
                left join BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as LOS
                    on L.LOAN_ID = LOS.LOAN_ID
        )
"""

# ============================================================================
# IMPLEMENTATION INSTRUCTIONS
# ============================================================================
# 1. Open file: BI-1451_Loss_Forecasting.py
# 2. Find lines 574-581 (dist_auto CTE definition)
# 3. Replace the entire CTE with NEW_CODE above
# 4. No other changes required - downstream usage remains unchanged (lines 693-696, 634-636)
# 5. Test in dev environment before deploying to production

# ============================================================================
# KEY DIFFERENCES FROM ORIGINAL
# ============================================================================
# 1. Base Table: VW_LOAN instead of VW_LOAN_COLLECTION
# 2. Join Pattern: LEFT JOIN to 3 separate tables instead of single DATA_STORE table
# 3. Duplicate Handling:
#    - OLD: Manual exclusion via "having count(*) < 2" (excluded 3 specific loans)
#    - NEW: Uses ACTIVE_RECORD_FLAG and CONTACT_RULE_END_DATE for proper filtering
# 4. Field Transformations:
#    - BANKRUPTCY_FLAG: COALESCE to FALSE for loans without bankruptcy records
#    - DEBIT_BILL_AUTOMATIC: IFF logic to convert 'yes'/'no' to TRUE/FALSE
#    - CEASE_AND_DESIST: No transformation needed (already boolean)
# 5. NULL Handling: More explicit with COALESCE and IFF for consistent boolean values

# ============================================================================
# DOWNSTREAM USAGE (NO CHANGES REQUIRED)
# ============================================================================
# Lines 693-696: Join to dist_auto
#   left join dist_auto
#       on elt.PAYOFF_UID = dist_auto.PAYOFF_UID
#
# Lines 634-636: Field usage
#   , dist_auto.DEBIT_BILL_AUTOMATIC
#   , dist_auto.CEASE_AND_DESIST
#   , dist_auto.BANKRUPTCY_FLAG
#
# These lines remain unchanged because field names and data types are identical

# ============================================================================
# TESTING CHECKLIST
# ============================================================================
# [ ] Run QC query 1_validate_analytics_tables.sql to verify tables have data
# [ ] Run QC query 2_compare_old_vs_new_pattern.sql to validate equivalence
# [ ] Compare record counts between old and new patterns (should match within 1%)
# [ ] Verify flag values match between old and new patterns
# [ ] Test full job execution in dev environment
# [ ] Compare output table (DSH_LOAN_PORTFOLIO_EXPECTATIONS) before/after
# [ ] Validate forecasting metrics remain consistent
# [ ] Deploy to production after successful validation
