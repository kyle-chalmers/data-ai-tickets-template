# Testing and Validation Plan for DI-1260

## Testing Overview

This document outlines the testing approach for validating the SFMC SFTP upload functionality added to BI-1931.

## Pre-Deployment Testing

### 1. Code Review ✅
- [x] Implementation follows BI-2609 SFMC upload pattern
- [x] Proper error handling with try/except/finally
- [x] Production environment check for SFMC upload
- [x] Maintains existing S3 backup functionality
- [x] Added paramiko dependency correctly

### 2. Development Environment Testing
**Objective**: Verify job runs successfully without SFMC upload

**Test Steps**:
1. Deploy code to development environment
2. Run job manually with `env = "dev"`
3. Verify S3 upload still works correctly
4. Confirm SFMC upload is skipped with appropriate logging

**Expected Results**:
- Job completes successfully
- S3 file created: `s3://hm-rstudio-datascience-cron/secrets/dev/DI-917/new_member_first_payment_list_YYYY_MM_DD.csv`
- Log message: `ℹ️ SFMC upload skipped (non-production environment: dev)`

### 3. Production Environment Testing
**Objective**: Validate SFMC SFTP upload works correctly

**Test Steps**:
1. Deploy code to production environment
2. Run job manually or wait for scheduled execution
3. Monitor job logs for SFMC upload success
4. Verify file appears in SFMC SFTP directory

**Expected Results**:
- Job completes successfully
- S3 file created as before (existing functionality preserved)
- SFMC SFTP upload succeeds
- Log messages show:
  - `✅ SFMC SFTP connection successful`
  - `✅ File uploaded to SFMC: /Import/new_member_first_payment_list_YYYY_MM_DD.csv`
  - `✅ New Member First Payment List successfully uploaded to SFMC for email campaigns`

## Production Deployment and Monitoring

### Phase 1: Initial Deployment
1. **Merge branch**: Merge DI-1260-sfmc-upload-fix to main
2. **Deploy to production**: Code automatically deployed via git integration
3. **Monitor next scheduled run**: Job runs daily at 4:30 PM UTC

### Phase 2: Validation Monitoring
1. **First Upload Validation** (Critical within 24 hours)
   - Monitor job execution logs
   - Verify SFMC SFTP upload success
   - Check file appears in SFMC /Import/ directory

2. **Campaign Data Flow Validation** (Within 48 hours)
   - Confirm SFMC campaigns can access uploaded data
   - Verify email campaigns start receiving data again
   - Monitor for any campaign processing errors

3. **Volume and Data Quality Validation** (Within 1 week)
   - Compare file record counts to historical S3 uploads
   - Verify data quality matches expected customer segments
   - Confirm business logic still operates correctly

## Test Cases

### Test Case 1: Development Environment Execution
```
Environment: dev
Expected File: s3://hm-rstudio-datascience-cron/secrets/dev/DI-917/new_member_first_payment_list_YYYY_MM_DD.csv
Expected Log: "SFMC upload skipped (non-production environment: dev)"
Expected Result: SUCCESS (S3 only)
```

### Test Case 2: Production Environment Execution
```
Environment: prod
Expected S3 File: s3://hm-rstudio-datascience-cron/secrets/prod/DI-917/new_member_first_payment_list_YYYY_MM_DD.csv
Expected SFMC File: /Import/new_member_first_payment_list_YYYY_MM_DD.csv
Expected Logs: "SFMC SFTP connection successful", "File uploaded to SFMC"
Expected Result: SUCCESS (Both S3 and SFMC)
```

### Test Case 3: SFMC Connection Failure Handling
```
Scenario: SFMC SFTP server unavailable or credentials invalid
Expected Behavior: Job fails with clear error message
Expected Log: "❌ SFMC upload failed: [error details]"
Expected Result: FAILURE (preserves S3 upload, fails on SFMC issue)
```

## Success Criteria

### ✅ Functional Requirements
- [ ] SFMC SFTP upload works in production
- [ ] S3 backup functionality unchanged
- [ ] Development environment skips SFMC upload
- [ ] Error handling prevents silent failures

### ✅ Business Requirements
- [ ] SFMC email campaigns receive daily data
- [ ] Customer segments match expected criteria (14 and 25 day post-funding)
- [ ] File format compatible with existing SFMC campaign setup
- [ ] No disruption to existing business processes

### ✅ Technical Requirements
- [ ] Job execution time remains acceptable
- [ ] No resource contention or performance issues
- [ ] Proper logging for monitoring and troubleshooting
- [ ] Follows established code patterns and standards

## Rollback Plan

### If SFMC Upload Fails
1. **Immediate**: SFMC-specific error won't affect S3 upload (job designed to fail fast)
2. **Short-term**: Fix SFMC connection issues (credentials, network, server)
3. **Long-term**: If needed, revert to previous version and investigate

### If Job Performance Degrades
1. **Monitor**: Job execution time and resource usage
2. **Investigate**: Whether paramiko/SFTP operations cause delays
3. **Optimize**: If needed, implement async upload or separate job

### If Data Quality Issues
1. **Validate**: Compare new uploads to historical S3 files
2. **Investigate**: Any changes in customer segmentation or data quality
3. **Fix**: Address any logic issues in implementation

## Post-Deployment Monitoring Schedule

### Week 1: Daily Monitoring
- Monitor every job execution
- Verify SFMC upload success
- Check for any error patterns

### Week 2-4: Bi-daily Monitoring
- Monitor job execution twice daily
- Spot-check SFMC file delivery
- Monitor campaign performance metrics

### Month 2+: Regular Monitoring
- Weekly verification of job success
- Monthly review of campaign data flow
- Quarterly review of file delivery patterns

## ✅ Validation Results

### Production Testing Complete
**Date**: 2025-09-23
**Result**: ✅ SUCCESS

**Validation Confirmed**:
- SFMC SFTP upload working correctly in production
- Job execution successful with no errors
- Data flow to email campaigns restored
- S3 backup functionality preserved unchanged

### Success Criteria Met
All functional, business, and technical requirements validated successfully.

---

*Testing completed: 2025-09-23*
*Production validation: SUCCESS*