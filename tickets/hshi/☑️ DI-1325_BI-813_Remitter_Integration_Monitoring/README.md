# DI-1325: BI-813 Remitter Integration Monitoring Investigation

**Ticket**: [DI-1325](https://happymoneyinc.atlassian.net/browse/DI-1325)
**Job**: BI-813_Remitter_Rewrite
**Investigation Date**: October 2025
**Status**: Investigation Complete - Awaiting Confirmation for Code Changes

## Executive Summary

Investigation of BI-813 Remitter Integration Monitoring revealed two alert issues:

1. **Remitter Inventory Exception Alert**: Non-functional - comparing stale 2023 data against current data
2. **Payment File Not Received Alert**: False alarms - assumes daily delivery when files only sent on payment days

## Issue 1: Remitter Inventory Exception Alert - NON-FUNCTIONAL

### Recommendation: **REMOVE** (Lines 347-380)

### Why This Alert Doesn't Function

#### 1. Comparing Stale Data Against Current Data

The exception detection logic relies on `PII.RPT_REMITTER_UPLOADFILE_HIST`, which:
- **Last updated**: 2023-12-15 (663 days ago as of Oct 2025)
- **Not maintained**: The current Python job doesn't write to this table
- **Result**: The alert compares 2-year-old upload data against today's inventory data

**Current query behavior**:
```sql
-- Loans marked 'void' in our upload from 2023-12-15
SELECT PAYOFFUID FROM PII.RPT_REMITTER_UPLOADFILE_HIST
WHERE ASOFDATE = '2023-12-15' AND STATUS LIKE '%void%'

EXCEPT

-- Loans marked 'Void' in Remitter's inventory from 2025-10-08
SELECT PAYOFFUID FROM CRON_STORE.RPT_REMITTER_INVENTORY_HIST
WHERE ASOFDATE = '2025-10-08' AND STATUS LIKE '%Void%'
```

This comparison is meaningless - any exceptions found are based on ancient data.

#### 2. Current Implementation Never Sends Void Status

The current BI-813 job hardcodes all uploads as `STATUS = 'awaiting payment'` (line 523):

```python
select OL.PAYOFFUID,
       'awaiting payment' as STATUS,  -- ← Hardcoded
       ...
```

Since we never send void status to Remitter, there's nothing for this alert to detect.

#### 3. Lost Functionality During Migration

The retired R job (`X_BI-813_Remitter_RETIRED.R`) had logic to send void status for loans with active Promise-to-Pay arrangements. This functionality was intentionally or unintentionally removed during the Python rewrite and has not been operational since December 2023.

### Impact Assessment

Removing this alert has **NO negative impact** because:
- ✅ The alert currently produces false positives (if any)
- ✅ We no longer send void status, so there's nothing to validate
- ✅ No one has been able to act on accurate alerts since Dec 2023
- ✅ The underlying table (`RPT_REMITTER_UPLOADFILE_HIST`) is not being maintained

### Recommended Code Change

**Remove lines 347-380** from `BI_813_Remitter_Rewrite.py`:

```python
## Remove this entire section:
query = """
    with EXCEPTION as (select PAYOFFUID
                      from PII.RPT_REMITTER_UPLOADFILE_HIST
                      where ASOFDATE = (select max(SUB.ASOFDATE) from PII.RPT_REMITTER_UPLOADFILE_HIST as SUB)
                        and STATUS like '%void%'
                      except
                      select PAYOFFUID
                      from CRON_STORE.RPT_REMITTER_INVENTORY_HIST
                      where STATUS like '%Void%'
                        and ASOFDATE = '{0}')
    select *
    from CRON_STORE.RPT_REMITTER_INVENTORY_HIST
    where PAYOFFUID in (select * from EXCEPTION)
      and ASOFDATE = '{1}'
    """.format(file_date, file_date)

    # ... exception handling and email logic ...
```

**Rationale**: This code serves no functional purpose in the current implementation and only adds confusion and maintenance burden.

---

## Issue 2: Payment File Not Received Alert - FALSE ALARM

### Recommendation: **MODIFY** Alert Logic

### Alert Logic in BI-813

**Location**: `BI_813_Remitter_Rewrite.py:499-516`

```python
## Email for no payment files
query = 'select FILENAME from CRON_STORE.RPT_REMITTER_FILE_LOG where LOADDATE = current_date'
loaded_files = query_construct.toPandas()
loaded_list = loaded_files['FILENAME'].to_list()

if True not in ['HappyMoney_payments' in x for x in loaded_list]:
  sender = 'biteam@happymoney.com'
  recipients = ['biteam@happymoney.com', 'accountingops@happymoney.com', 'goalrealignment_managers@happymoney.com']
  email_subject = 'Payment file not received from Remitter as of ' + datetime.date.today().strftime('%Y-%m-%d')
  email_body = 'Payment file not received from Remitter.'
  send_email(sender, recipients, email_subject, email_body)
```

**What it checks**: If no file containing 'HappyMoney_payments' was loaded in `CRON_STORE.RPT_REMITTER_FILE_LOG` on the current date, send an alert email.

### Why This Is a False Alert

#### Evidence from Payment History

**Related Tables**:
1. **CRON_STORE.RPT_REMITTER_FILE_LOG**
   - Tracks all files downloaded from Remitter
   - Recent payment files: Oct 1-4, Sept 27-30, Sept 23-26
   - **Pattern**: Gaps on weekends/holidays

2. **CRON_STORE.RPT_REMITTER_PAYMENTS_HIST**
   - Stores payment transaction details from Remitter
   - Recent data: Oct 1-4 (7, 3, 1, 1 payments)
   - **Pattern**: Gaps on Sept 29, 28, 24, 21-22, etc.

#### Analysis

- **Payment files show regular gaps**: Oct 5-8, Sept 29, Sept 24, Sept 21-22, etc.
- **Payment volumes vary**: 1-9 payments per day when files are sent
- **Pattern indicates**: Remitter only sends payment files when there are actual payments to report
- **Root cause**: The alert assumes Remitter should send payment files daily, but Remitter's actual behavior is to send files only on days with payment activity

### Proposed Solutions

#### Option 1: Business Day Check (Recommended)
Only alert if no file on a business day (Monday-Friday, excluding holidays):

```python
import datetime

# Check if today is a business day
today = datetime.date.today()
is_weekend = today.weekday() >= 5  # Saturday=5, Sunday=6

if not is_weekend:
    query = 'select FILENAME from CRON_STORE.RPT_REMITTER_FILE_LOG where LOADDATE = current_date'
    loaded_files = query_construct.toPandas()
    loaded_list = loaded_files['FILENAME'].to_list()

    if True not in ['HappyMoney_payments' in x for x in loaded_list]:
        # Send alert only on business days
        send_email(...)
```

#### Option 2: Grace Period
Only alert if no payment file for 3+ consecutive business days:

```python
query = '''
    SELECT COUNT(DISTINCT LOADDATE) as days_without_file
    FROM (
        SELECT DISTINCT LOADDATE
        FROM CRON_STORE.RPT_REMITTER_FILE_LOG
        WHERE LOADDATE >= CURRENT_DATE - 7
          AND FILENAME LIKE '%HappyMoney_payments%'
    )
'''

# Alert only if no files for 3+ days
if days_without_file >= 3:
    send_email(...)
```

#### Option 3: Remove Alert
If payment activity is too unpredictable and the alert provides no actionable value, consider removing it entirely.

---

## Next Steps

### Actions Required:

1. **Remove non-functional inventory exception alert**
   - Action: Remove lines 347-380 from `BI_813_Remitter_Rewrite.py`
   - Rationale: Alert is non-functional and serves no purpose

2. **Payment file alert** - No changes needed
   - Keep existing logic as-is
   - False alarms are acceptable given low volume

### Implementation Status: ✅ COMPLETE

- [x] Create branch for code changes
- [x] Remove inventory exception alert (lines 347-380)
- [x] Create PR and get code review
- [x] Deploy to production (Merged - October 9, 2025)
- [ ] Monitor for 2 weeks to ensure no issues

**Deployment Details**:
- Branch: `DI-1325/remove-inventory-exception-alert`
- Commit: 0ebb5e78
- Merged to main: October 9, 2025
- Lines removed: 35

---

## Related Files

- **Job**: `/business-intelligence-data-jobs/jobs/BI-813_Remitter/BI_813_Remitter_Rewrite.py`
- **Investigation Date**: October 6-8, 2025
- **Implementation Date**: October 9, 2025
- **Tables Analyzed**:
  - `PII.RPT_REMITTER_UPLOADFILE_HIST` (stale since 2023-12-15)
  - `CRON_STORE.RPT_REMITTER_INVENTORY_HIST`
  - `CRON_STORE.RPT_REMITTER_FILE_LOG`
  - `CRON_STORE.RPT_REMITTER_PAYMENTS_HIST`

---

*Investigation completed: October 2025*
*Implementation completed: October 9, 2025*
