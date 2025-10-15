# Campaign Grooming and Archive - SFMC/SFTP Campaigns
**Ticket**: DI-1255
**Date**: 2025-09-22
**Status**: Recommendation Report

## Business Context
During Bounce project implementation, identified that some campaigns are deactivated but their associated jobs are still executing. Need to clean up to reduce unnecessary processing and maintain system efficiency.

## Campaign Analysis Results

### Active Campaigns (Keep)
1. **GR Email** - Confirmed active
2. **Recovery Weekly** - Confirmed active

### Inactive Campaigns (Recommended for Archival)
1. **GR Physical Mail** ✅ Confirmed inactive
2. **Recovery Monthly Email** ✅ Confirmed inactive

## Code Modifications Required in BI-2482

### 1. Campaign Generation (Remove)
**Lines to Comment/Remove:**

**GR Physical Mail (Lines 311-331):**
```python
## 2.5 GR Physical Mail
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS
select current_date       as LOAD_DATE,
       'GR Physical Mail' as SET_NAME,
       # ... rest of query
''')
```

**Recovery Monthly Email (Lines 349-371):**
```python
## 2.7 Recovery Monthly Email (first Tuesday of every month)
if date.today().weekday() == 1 and date.today().day <= 7:
  sfUtils.runQuery(sf_options, '''
  insert into CRON_STORE.RPT_OUTBOUND_LISTS
  select current_date             as LOAD_DATE,
        'Recovery Monthly Email' as SET_NAME,
        # ... rest of query
  ''')
```

### 2. Suppression Logic (Remove)
**Lines to Comment/Remove:**

**GR Physical Mail Suppression (Lines 814-833):**
```python
## 3.2.4 Set: GR Physical Mail
# DNC: Letter
sfUtils.runQuery(sf_options, '''
insert into CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION
# ... suppression logic for GR Physical Mail
''')
```

**Recovery Monthly Email Suppression (Lines 858-897):**
```python
## 3.2.6 Set: Recovery Monthly Email
# DNC: Email, Letter
if date.today().weekday() == 1 and date.today().day <= 7:
  # Two suppression queries for Email and Letter
  # ... both queries to be removed
```

### 3. Delete/Cleanup Statements (Update)
**Line 202 - Campaign Deletion:**
```python
# FROM:
where SET_NAME in ('Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly', 'Recovery Monthly Email', 'GR Physical Mail', 'SIMM', 'SST')

# TO:
where SET_NAME in ('Call List', 'Remitter', 'SMS', 'GR Email', 'High Risk Mail', 'Recovery Weekly', 'SIMM', 'SST')
```

**Line 1148 - History Deletion:**
```python
# FROM:
'Recovery Monthly Email', 'GR Physical Mail', 'SIMM', 'SST'

# TO:
'SIMM', 'SST'
```

**Line 1157 - History Insertion:**
```python
# FROM:
'Recovery Monthly Email', 'GR Physical Mail', 'SIMM', 'SST'

# TO:
'SIMM', 'SST'
```

## Impact Assessment

### Processing Efficiency Gains
- **Reduced Daily Processing**: Eliminates unnecessary campaign generation for inactive campaigns
- **Reduced Suppression Logic**: Removes 3 suppression queries (1 for GR Physical Mail, 2 for Recovery Monthly Email)
- **Cleaner Data**: Removes inactive campaign data from outbound lists tables

### Data Continuity
- **Historical Data**: Existing historical data preserved in `_HIST` tables
- **No Active Dependencies**: Confirmed no downstream systems actively using these campaigns

## Related Jobs Confirmed for Archival

### BI-2609: GR Email + High Risk Letter Upload ✅ CONFIRMED INACTIVE
**Purpose**: Uploads GR Email and GR Physical Mail lists to SFMC
**Dependencies**:
- **GR Email**: Still active (keep this section)
- **GR Physical Mail**: ❌ INACTIVE - uploads 'DPD15 Test' and 'DPD75 Test' lists
**Action**: Keep GR Email section, remove GR Physical Mail sections (lines 115-251)

### BI-2108: Monthly Recovery Email ✅ CONFIRMED INACTIVE
**Purpose**: Uploads Recovery Monthly Email lists to SFMC
**Dependencies**:
- Directly depends on 'Recovery Monthly Email' from BI-2482 (line 59)
- Uploads to SFMC via SFTP
**Action**: Move entire job to `retired_jobs/` folder

## Recommended Implementation Steps

1. **Stakeholder Approval**: Get final confirmation from campaign owners
2. **Code Backup**: Create backup of current jobs before modifications
3. **Job Modifications**:
   - **BI-2482**: Remove GR Physical Mail and Recovery Monthly Email campaign generation
   - **BI-2609**: Remove GR Physical Mail upload sections (keep GR Email)
   - **BI-2108**: Move entire job folder to `retired_jobs/BI-2108_Monthly_Recovery_Email/`
   - **Databricks configs**: Remove/deactivate BI-2108 job definitions in dev/prod
4. **Staged Rollout**:
   - Test changes in dev environment
   - Deploy to production during low-usage period
5. **Monitoring**: Monitor job execution time improvements post-deployment

## Risk Assessment
- **LOW RISK**: Campaigns confirmed inactive by business stakeholders
- **Reversible**: Changes can be easily reversed if needed
- **No Breaking Changes**: Only removes unused functionality

## Next Steps
1. Final stakeholder sign-off
2. Schedule maintenance window for deployment
3. Update job documentation to reflect changes
4. Archive this report for future reference

---
**Prepared by**: Data Intelligence Team
**Review Required**: Business stakeholders, Collections team