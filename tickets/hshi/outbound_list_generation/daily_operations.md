# Daily Operations Guide

## Daily Timeline (Eastern Time)

### 6:00 AM - List Generation Begins
**Databricks Workflow**: `BI-2482_Outbound_List_Generation`
- **Duration**: 30-45 minutes
- **Process**: Generate all outbound lists in Snowflake
- **Output**: Lists ready in `CRON_STORE.RPT_OUTBOUND_LISTS`

### 8:30 AM - Genesis Upload
**Owner**: Divya (Engineering team)
- **Duration**: ~30 minutes
- **Process**: Upload lists to Genesis system
- **Status**: Lists available for campaign execution

### 9:00 AM - Ready for Execution
- Collections team can begin outbound activities
- Marketing campaigns ready for deployment
- All channels (phone, SMS, email) active

### 10:30 PM - Results Export
**Owner**: Divya (Engineering team)
- **Process**: Extract campaign results from Genesis
- **Data Flow**: Genesis → Kafka → Snowflake
- **Output**: Campaign performance data available for analysis

## Workflow Dependencies

```
BI-2482_Outbound_List_Generation_for_GR (Main Job)
↓
Parallel Execution:
├── BI-2584_LKP_GENESYS_LIST_AUTOMATION_CONFIG_HIST_Table
├── BI-2609_GR_Email_High_Risk_Letter_Upload
├── BI-737_GR_Call_List
├── BI-813_Remitter
├── DI-862_SIMM_File_Upload
└── Outbound_list_for_funnel_DI-749_Email_Non_Openers_from_SFTP
    ↓
    DI-986_Outbound_List_Generation_for_funnel
        ↓
        Parallel Execution:
        ├── BI-820_GR_text_eligible
        ├── DI-1049_PIF_list_to_SFMC_SFTP
        └── DI-977_prescreen_email_list_upload
```

## Daily Monitoring Checklist

### 6:30 AM - Workflow Status Check
- [ ] Verify BI-2482 completed successfully
- [ ] Check for any job failures in Databricks
- [ ] Validate list generation counts

### 9:00 AM - Genesis Integration Check
- [ ] Confirm lists uploaded to Genesis
- [ ] Verify campaign activation status
- [ ] Check Tableau monitoring dashboard

### End of Day - Results Validation
- [ ] Verify 10:30 PM export completed
- [ ] Check import/export volume matching
- [ ] Review any alerts or anomalies

## Key Monitoring Points

### Data Quality Checks
- **Loan Tape Freshness**: Ensure current data
- **Record Counts**: Validate expected volumes
- **Suppression Logic**: Verify rules applied correctly

### Performance Monitoring
- **Execution Time**: Target completion before 8:00 AM
- **Cluster Utilization**: Monitor auto-scaling behavior
- **Resource Usage**: Track i3.xlarge performance

### Alert Conditions
- **Job Failures**: Immediate notification to hshi@happymoney.com
- **Volume Mismatches**: Import vs export discrepancies
- **Data Quality Issues**: Missing or corrupted data

## Common Daily Issues

### Morning Issues (6:00-9:00 AM)
- **Cluster Startup Delays**: Check AWS spot pricing
- **Memory Issues**: Monitor cluster scaling
- **Data Pipeline Delays**: Verify source data availability

### Evening Issues (10:30 PM+)
- **Export Failures**: Check Genesis connectivity
- **Volume Mismatches**: Validate campaign execution
- **Kafka Processing**: Monitor data flow to Snowflake