# Current Implementation Analysis: BI-1931

## Current BI-1931 Implementation

### What It Does ✅
1. **Data Query**: Selects newly funded customers (14 and 25 days post-funding) who haven't made first payment
2. **File Generation**: Creates `new_member_first_payment_list_YYYY_MM_DD.csv` with required fields
3. **S3 Upload**: Saves file to `s3://hm-rstudio-datascience-cron/secrets/prod/DI-917/`

### What It's Missing ❌
- **SFMC SFTP Upload**: No upload to SFMC SFTP server for email campaigns

### Current File Structure
```csv
PayoffUID,FirstName,ChosenName,LastName,Email,FUNDED_DATE,FIRSTSCHEDULEDPAYMENTDATE,PAYMENT_AMOUNT,ACH_ON
```

## SFMC Upload Pattern from BI-2609

### Required Components
1. **Dependencies**: `paramiko` library for SFTP
2. **Authentication**: Uses `SFMC` secret scope
3. **Connection Details**:
   - Host: `mc9bltz8jrt0t97x71rmj4m56pv8.ftp.marketingcloudops.com`
   - Port: 22
   - Auth: Username/password from secrets
4. **Upload Path**: `/Import/[filename]`
5. **Error Handling**: Try/finally block with connection cleanup

### BI-2609 SFMC Upload Code Pattern
```python
# SFMC upload section
if ENV == 'prod':
    host = 'mc9bltz8jrt0t97x71rmj4m56pv8.ftp.marketingcloudops.com'
    username = dbutils.secrets.get("SFMC", "username")
    password = dbutils.secrets.get("SFMC", "password")
    remote_path = '/Import/' + '[filename]'

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    try:
        ssh.connect(hostname=host, username=username, password=password, port=22)
        sftp = ssh.open_sftp()
        print("Connection successful")

        sftp.put(local_dir, remote_path)
        sftp.close()
    finally:
        ssh.close()
```

## Implementation Plan

### Phase 1: Add Dependencies
- Add `paramiko` library installation: `pip install paramiko`

### Phase 2: Add SFMC Upload Section
- Insert SFMC upload code after current S3 upload
- Use same file that's already generated for S3
- Target path: `/Import/new_member_first_payment_list_YYYY_MM_DD.csv`

### Phase 3: Maintain Existing Functionality
- Keep all current S3 upload functionality
- Preserve existing file format and naming
- Maintain error handling for both S3 and SFMC uploads

## Key Differences from BI-2609

| Aspect | BI-2609 | BI-1931 Current | BI-1931 Target |
|--------|---------|-----------------|-----------------|
| **Data Source** | CRON_STORE.RPT_OUTBOUND_LISTS | Direct ANALYTICS query | Keep current |
| **File Format** | Extended with loan details | Customer payment info | Keep current |
| **S3 Path** | `BI-2609_GR_Email_High_Risk_Letter_Upload/` | `DI-917/` | Keep current |
| **SFMC Path** | `/Import/GR_outreach_campaign_upload_` | N/A | `/Import/new_member_first_payment_list_` |
| **Environment** | Production only | All environments | Production only for SFMC |

## Risk Assessment

### Low Risk ✅
- Adding SFMC upload is non-destructive
- Existing S3 functionality remains unchanged
- Standard SFMC upload pattern already proven in BI-2609

### Considerations ⚠️
- Test SFMC credentials and access
- Verify file format compatibility with existing SFMC campaign
- Monitor first upload for any issues

## Implementation Requirements

### Code Changes
1. Add paramiko import and installation
2. Add SFMC upload section after S3 upload
3. Use production environment check (`if ENV == 'prod':`)
4. Maintain existing error handling patterns

### Testing Plan
1. Test in development environment (S3 only)
2. Verify file generation still works correctly
3. Test production SFMC upload manually
4. Monitor automated upload on next schedule run

---

*Analysis completed: 2025-09-23*