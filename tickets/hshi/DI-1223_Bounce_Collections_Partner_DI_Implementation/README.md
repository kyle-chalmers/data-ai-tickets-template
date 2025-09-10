# DI-1223: Bounce Collections Partner - DI Team Implementation

## Project Overview

**Ticket**: [DI-1223](https://happymoneyinc.atlassian.net/browse/DI-1223)  
**Target Go-Live**: October 14, 2025  
**Business Owner**: Lisa Carney (Collections), Maria Mosolova (Strategy)  
**DI Implementation**: Hongxia Shi  

## Business Context

Deploy Bounce as a new first-party collections partner alongside existing SIM partnership to create a three-way test:
- **SIM Collections**: 50% of back book (existing, unchanged)
- **Bounce Collections**: 25% of back book (NEW implementation)  
- **Happy Money Internal**: 25% of back book (reduced from 50%)

### Key Business Differences
- **SIM**: Phone/SMS only, uses Happy Money systems
- **Bounce**: Phone/SMS/EMAIL, uses their own systems and portal
- **Approach**: Bounce is more AI-driven and quantitative

## Implementation Summary

### ✅ Completed Deliverables

1. **Account Allocation Logic** (`1_bounce_allocation_logic_implementation.sql`)
   - Characters 4-7 allocated to Bounce (25% of back book)
   - Characters 0-3 for Happy Money Internal (reduced from 0-7)
   - Characters 8-F remain with SIMM (unchanged)

2. **Suppression Logic** (`2_bounce_suppression_logic_implementation.sql`)
   - All global suppressions apply to Bounce
   - Cross-set suppression to prevent overlap with internal campaigns
   - Multi-channel suppression handling for Bounce

3. **SFTP File Upload Job** (`3_DI-862_BOUNCE_File_Upload.py`)
   - Databricks notebook for daily file generation
   - Uses existing Bounce SFTP credentials (sftp.finbounce.com)
   - Same file format as SIMM for compatibility

4. **Sample Account List** (`4_bounce_sample_account_list.csv`)
   - 25 sample Bounce accounts for testing
   - Validates allocation logic working correctly

5. **Business Clarification Document** (`5_suppression_scope_clarification_needed.md`)
   - Documents scope question for suppression logic
   - Provides options for business team decision

## Technical Implementation Details

### Database Changes Required

#### 1. Update BI-2482_Outbound_List_Generation_for_GR.py

**Location**: `/jobs/BI-2482_Outbound_List_Generation_for_GR/BI-2482_Outbound_List_Generation_for_GR.py`

**Changes Needed**:

1. **Add Bounce Allocation Logic** (after existing SIMM logic ~line 393):
```python
# Bounce Collections Allocation (NEW)
insert into CRON_STORE.RPT_OUTBOUND_LISTS
with SST as (
    select L.LEAD_GUID as PAYOFFUID
    from ANALYTICS.VW_LOAN as L
    inner join BRIDGE.VW_LOAN_PORTFOLIO_CURRENT as LP
        on L.LOAN_ID = LP.LOAN_ID::string
        and LP.SCHEMA_NAME = CONFIG.LMS_SCHEMA()
        and LP.PORTFOLIO_ID = 205
)
select current_date as LOAD_DATE,
       'BOUNCE'     as SET_NAME,
       'DPD3-119'   as LIST_NAME,
       PAYOFFUID,
       false        as SUPPRESSION_FLAG,
       ASOFDATE     as LOAN_TAPE_ASOFDATE
from DATA_STORE.MVW_LOAN_TAPE
where not ((STATUS = 'Current' and DAYSPASTDUE < 3) or STATUS in ('Paid in Full', 'Sold', 'Charge off'))
  and substring(PAYOFFUID, 16, 1) in ('4', '5', '6', '7')
  and PAYOFFUID not in (select SST.PAYOFFUID from SST);
```

2. **Update Happy Money Internal Logic** (~line 350):
```python
# Change from:
and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3', '4', '5', '6', '7')

# Change to:
and substring(PAYOFFUID, 16, 1) in ('0', '1', '2', '3')  # Reduced allocation
```

3. **Add Bounce Suppression Logic** (in suppression section ~line 600):
```python
# Bounce Multi-Channel Suppression
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Set'        as SUPPRESSION_TYPE,
       'DNC: Phone/Text/Email/Letter' as SUPPRESSION_REASON,
       L.LEAD_GUID  as PAYOFF_UID,
       'BOUNCE'     as SET_NAME,
       'N/A'        as LIST_NAME
from ANALYTICS.VW_LOAN as L
inner join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
    on L.LOAN_ID = LCR.LOAN_ID
    and LCR.CONTACT_RULE_END_DATE is null
where (LCR.SUPPRESS_PHONE = true 
    OR LCR.SUPPRESS_TEXT = true 
    OR LCR.SUPPRESS_EMAIL = true 
    OR LCR.SUPPRESS_LETTER = true);

# Cross-Set Suppression (scope to be confirmed)
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
select current_date as LOAD_DATE,
       'Cross Set'  as SUPPRESSION_TYPE,
       'BOUNCE'     as SUPPRESSION_REASON,
       PAYOFFUID,
       'GR Email'   as SET_NAME,  -- **UPDATE based on business decision**
       'N/A'        as LIST_NAME
from CRON_STORE.RPT_OUTBOUND_LISTS
where SET_NAME = 'BOUNCE';
```

#### 2. Add DI-862_BOUNCE_File_Upload Job

**Location**: Create new folder `/jobs/DI-862_BOUNCE_File_Upload/`

**Dependencies**:
- Must run after BI-2482_Outbound_List_Generation_for_GR
- Requires Bounce SFTP SSH key in DBFS
- Uses existing `snowflake_bi_pii` secret scope

**Integration**: Add to BI-2482_Outbound_List_Generation workflow as parallel job alongside DI-862_SIMM_File_Upload

### SFTP Configuration

**Server**: sftp.finbounce.com  
**Username**: happy-money  
**Authentication**: SSH key (same as debt sales)  
**Remote Path**: /lendercsvbucket/happy-money/  
**File Pattern**: Happy_Money_Bounce_DPD3-119_YYYYMMDD.csv  

**Key Storage**: SSH private key needs to be stored in DBFS at `/dbfs/FileStore/shared_uploads/bounce_sftp_key`

### File Format

Uses identical format to SIMM for Bounce compatibility:
- Same column structure as DI-862_SIMM_File_Upload
- Same business logic and data sources
- Only difference: filters for SET_NAME = 'BOUNCE'

## Assumptions Made

1. **Risk Team Approval**: Davis confirmed 16th character allocation approach is acceptable
2. **SFTP Access**: Same server/credentials as debt sales can be used for collections 
3. **File Format**: Bounce approved existing SIMM file format
4. **Schedule**: Daily file generation same timing as SIMM
5. **Suppression Scope**: Placeholder implementation pending business clarification
6. **Architecture**: Implementation uses existing DATA_STORE patterns to maintain consistency with current jobs

## Dependencies and Coordination

### ✅ Completed
- Risk team confirmation (Davis/Harjot): **APPROVED**
- SFTP access confirmation: **CONFIRMED** (use existing setup)
- File format approval: **CONFIRMED** (same as SIMM)

### ⚠️ Pending Business Decisions
- **Suppression Scope**: Which campaigns should suppress Bounce accounts?
  - Options documented in `5_suppression_scope_clarification_needed.md`
  - Decision needed from Collections and Marketing teams

### 🔧 Engineering Tasks Remaining
- Update BI-2482_Outbound_List_Generation_for_GR.py with allocation and suppression logic
- Create DI-862_BOUNCE_File_Upload job in Databricks
- Add job to BI-2482_Outbound_List_Generation workflow 
- Store Bounce SFTP SSH key in DBFS
- Test complete workflow end-to-end

## Testing and Validation

### Pre-Deployment Testing
1. **Allocation Verification**: Run allocation verification query to confirm 25%/25%/50% split
2. **Suppression Testing**: Validate no Bounce accounts appear in internal campaigns
3. **File Generation**: Test complete file generation and SFTP upload process
4. **SFTP Connectivity**: Confirm file successfully uploads to Bounce server

### Sample Data Available
- `4_bounce_sample_account_list.csv`: 25 sample accounts meeting Bounce criteria
- Includes various DPD ranges and statuses for comprehensive testing

## Timeline and Milestones

- **September 11**: ✅ Risk team confirms allocation logic  
- **September 18**: SFTP access established  
- **September 25**: Sample list generated and tested  
- **October 1**: Daily list generation implemented  
- **October 8**: Final testing and validation  
- **October 14**: **GO-LIVE**  

## Monitoring and Support

### Key Metrics to Monitor
- Daily file generation success rate
- Account allocation percentages (should maintain 25%/25%/50%)
- SFTP upload success rate  
- Suppression rule effectiveness
- File size and record counts vs expected volumes

### Alert Triggers
- BI-2482 job failures (impacts both SIMM and Bounce)
- SFTP upload failures
- Allocation percentage drift
- Suppression logic failures

## Contact Information

**Business Owners**:
- Lisa Carney (Collections Project Lead)
- Maria Mosolova (Collections Strategy)
- Kelvin Marin-Solis (Collections Expert)

**Technical Implementation**:
- Hongxia Shi (Data Intelligence)
- Divya (Engineering - Genesis integration)

**Dependencies**:
- Davis Mahony & Harjot Dadial (Risk Team)
- Jenny Kohrumel (Product/Servicing)
- Steve Bowe (Legal/Compliance)

---

*Implementation completed: September 10, 2025*  
*Ready for engineering deployment and business decision on suppression scope*