# DI-1261: DMS Vendor Weekly Data Feed Setup

**Status**: ⏳ DEVELOPMENT COMPLETE - PENDING DEPLOYMENT
**Last Updated**: October 9, 2025
**Jira**: [DI-1261](https://happymoneyinc.atlassian.net/browse/DI-1261)

---

## Project Summary

Successfully designed and developed automated weekly data feed system for DMS (Data Management Services) vendor to support direct mail marketing operations.

### Deliverables

✅ **3 Data Feeds** (Application, Loan, Suppression)
✅ **DI-1309 Compliant Queries** (migrated to new standardized views)
✅ **Databricks Job** with SSH key-based SFTP upload
✅ **Complete Documentation**

---

## Production Job Location

**Repository**: `/Users/hshi/WOW/business-intelligence-data-jobs/jobs/DI-1261_Weekly_Data_Feeds_for_DMS/`

Files:
- `DI-1261_Weekly_Data_Feeds_for_DMS.py` - Main job file
- `README.md` - Job documentation

---

## Key Achievements

### 1. DI-1309 View Migration
Successfully migrated all legacy application views to new standardized tables:
- `VW_APPL_STATUS_HISTORY` → `VW_APP_STATUS_TRANSITION` (with UNPIVOT logic for 46 status types)
- `VW_APPLICATION` → `VW_APP_LOAN_PRODUCTION`
- `VW_APPLICATION_PII` → `VW_APP_PII`

All queries tested and validated in Snowflake before integration.

### 2. SSH Key Authentication
Implemented secure SSH key-based SFTP authentication:
- **Private Key**: `/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem`
- **Public Key**: Added to DMS server
- **Method**: paramiko library (industry best practice)
- **Benefit**: No password storage required, more secure than password-based auth

### 3. SFTP Implementation Research
Analyzed multiple SFTP authentication patterns across existing jobs:
- DI-1223 (Bounce): SSH key with paramiko
- DI-566 (Experian): SSH key downloaded from S3
- DI-916 (Credit Karma): SSH key with passphrase
- DI-760 (IWCO): Password-based with sshpass

Selected SSH key approach for best security and maintainability.

---

## Technical Details

### SFTP Connection
- **Host**: ftp-01.teamdms.com
- **Port**: 22
- **Username**: hshi@happymoney.com
- **Authentication**: SSH Private Key (paramiko)
- **Key Path**: `/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem`

### Files Generated Weekly
1. `HM_Applications_YYYYMMDD.csv` (~195k records)
2. `HM_Loans_20170101_thru_YYYYMMDD.csv` (~50k records)
3. `HM_Suppressions_YYYYMMDD.csv` (~25k records)

### Data Sources
- **Snowflake** (PII-enabled connection)
  - ANALYTICS.VW_APP_LOAN_PRODUCTION
  - ANALYTICS.VW_APP_STATUS_TRANSITION
  - ANALYTICS_PII.VW_APP_PII
  - ANALYTICS.VW_LOAN
  - ANALYTICS_PII.VW_MEMBER_PII
  - ANALYTICS.VW_LOAN_CONTACT_RULES

### Storage & Delivery
- **Local**: `/dbfs/mnt/rstudio/cron/secrets/{env}/DI-1261_Data_Feeds_for_DMS/`
- **S3 Backup**: `s3://happymoney-cron-store-{env}/DI-1261_DMS_Data_Feeds/`
- **SFTP**: ftp-01.teamdms.com (`/HappyMoney/To_DMS/` directory)

---

## Testing & Validation

### Query Testing
- ✅ Application data query: Tested in Snowflake, ~195k records
- ✅ Loan data query: Tested in Snowflake, ~50k records
- ✅ Suppression data query: Tested in Snowflake, ~25k records
- ✅ UNPIVOT logic: Validated for all 46 status types

### Error Resolutions
1. **DECLINE_MANUAL_REVIEW_MAX_TS** - Removed (doesn't exist in new view)
2. **Source filter** - Removed (VW_APP_LOAN_PRODUCTION already filtered)

---

## Deployment Checklist

### ✅ Completed
- [x] SSH key pair generated
- [x] Public key uploaded to DMS server
- [x] Private key uploaded to S3 and mounted in Databricks
- [x] Queries migrated to DI-1309 views
- [x] Queries tested in Snowflake
- [x] Job code completed with SSH key authentication
- [x] Job copied to business-intelligence-data-jobs repo
- [x] Documentation completed

### ⏳ Next Steps (Deployment Team)
- [ ] Get Databricks workspace IP addresses for whitelisting
- [ ] Request DMS to whitelist Databricks IPs
- [ ] Upload job to Databricks workspace
- [ ] Test in dev environment (`env=dev`)
- [ ] Verify SSH key connection from Databricks
- [ ] Test end-to-end file generation
- [ ] Deploy to production (`env=prod`)
- [ ] Schedule weekly job (Wednesday mornings)

---

## Business Impact

### DMS Use Cases
1. **Customer Separations**: S801-S807 separations on TransUnion universe file
2. **Suppression Management**: Mail opt-outs, TCPA compliance, recent declines
3. **Active Customer Targeting**: Current loan holders for retention campaigns
4. **Quality Control**: Filter bad loans, declines, recent applications

### Suppression Categories
- LoanPro declines (past 20 days)
- CLS declines (past 20 days)
- Recent applications (past 20 days)
- TCPA suppressions (do not call/email)
- Mail opt-outs (from contact rules)

---

## Project Timeline

- **Sep 23, 2025**: Project initiated
- **Oct 6, 2025**: Query migration completed (DI-1309 compliance)
- **Oct 6, 2025**: Initial job created
- **Oct 7, 2025**: SSH key authentication implemented
- **Oct 7, 2025**: ✅ **DEVELOPMENT COMPLETE**

---

## References

### Similar Jobs
- **DI-760**: IWCO data feeds (similar structure)
- **DI-1223**: Bounce collections (SSH key reference)
- **DI-566**: Experian reporting (SSH key reference)

### Related Projects
- **DI-1309**: VW_APPLICATION migration project (parent initiative)
- **DI-497**: CRB Fortress Reporting (DI-1309 migration)
- **BI-1451**: Loss Forecasting (DI-1309 migration)

---

## Contact

- **Developer**: Hongxia Shi
- **Business Owner**: Marketing/Direct Mail Team
- **Vendor**: DMS (ftp-01.teamdms.com)
- **Stakeholders**: Steve Richardson, Tin Nguyen

---

**Project Status**: ⏳ Development Complete - Pending Databricks IP Whitelisting and Deployment
**Last Updated**: October 9, 2025
