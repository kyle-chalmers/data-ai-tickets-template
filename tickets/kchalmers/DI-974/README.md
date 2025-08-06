# DI-974: Add in SIMM Placement Flag Into Intra Month Roll Rate Dashboard

## Ticket Summary
Add a flag to indicate whether a loan is placed with SIMM in the Intra-month roll rate dashboard. The flag should be created using the RPT_OUTBOUND_LISTS_HIST table filtered for SIMM placements and joined to the dashboard data based on LoanID and Date.

## Problem Description
The Intra-month roll rate dashboard currently lacks visibility into which loans are placed with SIMM (presumably a collections agency or service provider). This information is needed to better analyze roll rates and performance metrics for SIMM-placed loans.

## Solution Approach
1. Explore the RPT_OUTBOUND_LISTS_HIST table to understand SIMM placement data structure
2. Identify the Intra-month roll rate dashboard data source and structure
3. Determine the correct join fields and logic for matching SIMM placements
4. **Modify the underlying database objects** to include SIMM placement flag
5. Create ALTER statements for both dynamic table and view
6. Save original code definitions for rollback capability

## Work Log

### Data Exploration Findings

#### SIMM Placement Data (RPT_OUTBOUND_LISTS_HIST)
- Table: `BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST`
- Filter: `SET_NAME = 'SIMM'`
- Key Fields:
  - `PAYOFFUID`: Maps to LEAD_GUID for loan identification
  - `LOAN_TAPE_ASOFDATE`: Date when loan was placed with SIMM
  - `SUPPRESSION_FLAG`: Should be FALSE for active placements
- Data Range: 2025-05-02 to 2025-07-31
- Unique Loans: 6,296

#### Intra-month Roll Rate Dashboard Data (DSH_GR_DAILY_ROLL_TRANSITION)
- Table: `BUSINESS_INTELLIGENCE.CRON_STORE.DSH_GR_DAILY_ROLL_TRANSITION`
- Key Fields:
  - `PAYOFFUID`: Direct match with SIMM data
  - `ASOFDATE`: Daily snapshot date
  - `CURRENT_DPD`: Current days past due
  - `ROLL_STATUS`: Roll status classification
  - Contains daily loan performance metrics for intra-month analysis
- Latest Data: Through 2025-07-30 (daily snapshots)

Note: The monthly roll rate view (VW_DSH_MONTHLY_ROLL_RATE_MONITORING) can also be used with the same join logic.

### Implementation Solution

Created SQL files for both daily and monthly implementations:

**Database Object Modifications (Primary Solution):**
1. **alter_dynamic_table_add_simm_flag.sql**: ALTER statement for DSH_GR_DAILY_ROLL_TRANSITION
2. **alter_view_add_simm_flag.sql**: ALTER statement for VW_DSH_MONTHLY_ROLL_RATE_MONITORING
3. **implementation_guide.md**: Step-by-step implementation instructions

**Original Code Backup:**
4. **original_code/original_dynamic_table_ddl.sql**: Original dynamic table definition
5. **original_code/original_view_ddl.sql**: Original view definition

**Alternative Query Approaches:**
6. **add_simm_flag_to_daily_roll_rate.sql**: Complete query for daily roll transitions
7. **add_simm_flag_to_monthly_roll_rate.sql**: Complete query for monthly roll rates
8. **simm_flag_simple.sql**: Simplified code snippets for dashboard integration

### Key Findings

#### Overall SIMM Placement
- SIMM placement rate: ~1.26% (May 2025) to 1.52% (June 2025) of all loans
- SIMM-placed loans have significantly higher DPD (18-21 days) vs non-SIMM (0.3 days)
- SIMM placement data available from May 2025 onwards

#### Delinquent Loan Analysis (3-119 DPD, not charged off/paid in full)
- **47% of delinquent loans are placed with SIMM** - a much higher concentration than overall
- SIMM manages approximately $21.8M in delinquent principal (out of $45.7M total)
- DPD distribution of SIMM placements:
  - 3-30 DPD: ~48% of loans in this bucket have SIMM placement
  - 31-60 DPD: ~48% SIMM placement
  - 61-90 DPD: ~45% SIMM placement  
  - 91-119 DPD: ~49% SIMM placement
- Join logic: Match on PAYOFFUID where ASOFDATE >= first SIMM placement date

## Results and Outcomes

Successfully created ALTER statements to modify the underlying database objects and add SIMM placement flags to both dashboards:

### Primary Implementation (Database Modifications)
- **Dynamic Table**: `DSH_GR_DAILY_ROLL_TRANSITION` modified to include SIMM_PLACEMENT_FLAG and FIRST_SIMM_DATE
- **View**: `VW_DSH_MONTHLY_ROLL_RATE_MONITORING` modified with same SIMM columns
- **Join Logic**: Corrected to match on PAYOFFUID with proper date logic for daily snapshots
- **Backup**: Original definitions saved for rollback capability

### Key Technical Corrections
- **Daily Join Logic**: Fixed to join on both PAYOFFUID and ASOFDATE >= LOAN_TAPE_ASOFDATE for accurate daily tracking
- **Monthly Join Logic**: Maintains existing logic while adding SIMM placement context
- **Data Integrity**: Preserves all existing functionality while adding new SIMM fields

### Business Impact
The modifications enable direct filtering and analysis of SIMM vs non-SIMM loans within both dashboards, supporting data-driven collection strategy decisions with 47% of delinquent loans under SIMM management.