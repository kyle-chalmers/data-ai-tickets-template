# Troubleshooting Guide

## Common Failure Scenarios

### Morning Issues (6:00-9:00 AM)

#### Databricks Workflow Failures (6:00 AM)
**Symptoms**:
- Workflow doesn't start at scheduled time
- Jobs fail during execution
- Partial completion with some jobs failing

**Common Causes**:
- **Cluster Startup Delays**: AWS spot instance availability issues
- **Memory Issues**: i3.xlarge cluster hitting memory limits
- **Git Sync Problems**: Repository access or branch permission issues
- **Snowflake Connection Timeouts**: Warehouse availability or connection limits

**Troubleshooting Steps**:
1. Check Databricks cluster logs for startup issues
2. Verify AWS spot instance pricing and availability
3. Confirm Git repository access and main branch status
4. Test Snowflake connectivity and warehouse status
5. Review job execution logs for specific error messages

**Recovery Actions**:
- Re-run failed jobs individually after fixing root cause
- Check cluster logs and Snowflake connectivity for complete failures
- Validate source data freshness before re-running

#### Genesis Upload Failures (8:30 AM)
**Symptoms**:
- Lists generated but not appearing in Genesis
- Partial uploads with some campaigns missing
- Upload process timing out

**Common Causes**:
- Genesis system connectivity issues
- Authentication problems
- Large data volumes exceeding timeout limits
- Configuration table inconsistencies

**Troubleshooting Steps**:
1. Contact Divya to check upload process status
2. Verify `LKP_GENESYS_LIST_AUTOMATION_CONFIG` table accuracy
3. Check Genesis system status and connectivity
4. Review upload logs for specific error messages

**Recovery Actions**:
- Divya re-triggers upload job
- Manual upload via backup Google Sheet
- Targeted re-upload of failed campaigns only

### Evening Issues (10:30 PM+)

#### Export Process Failures
**Symptoms**:
- Import completed successfully but no export results
- Volume mismatches between import and export
- Delayed export processing

**Common Causes**:
- Genesis API connectivity issues
- Kafka messaging service problems
- Campaign execution issues in Genesis
- Data processing delays

**Troubleshooting Steps**:
1. Check Tableau monitoring dashboard for alerts
2. Verify Genesis campaign execution status
3. Monitor Kafka message processing
4. Review data engineering pipeline status

**Recovery Actions**:
- Contact Divya for export process restart
- Check Genesis system for campaign execution issues
- Verify Kafka to Snowflake data flow

## Performance Optimization

### Cluster Scaling Issues
**Symptoms**:
- Jobs consistently hitting memory limits
- Long execution times beyond 45 minutes
- Auto-scaling not responding to load

**Solutions**:
- **Cluster Sizing**: Upgrade to larger instance types if consistently hitting limits
- **Worker Scaling**: Adjust min/max workers based on daily data volumes
- **Resource Allocation**: Monitor i3.xlarge cluster memory usage during peak processing

### Job Parallelization
**Symptoms**:
- Sequential job execution causing delays
- Dependencies blocking parallel execution
- Total runtime exceeding target completion time

**Solutions**:
- **Dependency Optimization**: Review and optimize dependency chains
- **Parallel Execution**: Identify jobs that can run simultaneously
- **Resource Planning**: Balance parallel jobs against cluster capacity

### Data Pipeline Performance
**Symptoms**:
- Slow data source queries
- Large table scan operations
- Inefficient join operations

**Solutions**:
- **Query Optimization**: Review and optimize SQL queries
- **Data Partitioning**: Ensure proper partitioning strategies
- **Index Usage**: Verify appropriate indexing on key tables

## Data Quality Issues

### Source Data Problems
**Symptoms**:
- Unexpected record counts
- Missing or incomplete data
- Data freshness issues

**Troubleshooting Steps**:
1. Verify loan tape data freshness and completeness
2. Check data pipeline execution status
3. Compare current counts to historical patterns
4. Validate business logic against data

**Resolution**:
- Coordinate with data engineering for source data issues
- Validate business rules if logic changes needed
- Re-run after source data correction

### Suppression Logic Issues
**Symptoms**:
- Unexpected suppression rates
- Customers appearing in wrong lists
- Suppression rules not applying correctly

**Troubleshooting Steps**:
1. Review suppression rule effectiveness
2. Check `VW_LOAN_CONTACT_RULES` for recent changes
3. Validate portfolio segmentation logic
4. Test suppression queries independently

**Resolution**:
- Update suppression rules based on business requirements
- Coordinate with compliance team for regulatory changes
- Test rule changes thoroughly before deployment

## Monitoring and Alerts

### Tableau Dashboard Issues
**Symptoms**:
- Dashboard not updating with latest data
- False positive alerts
- Missing alert notifications

**Troubleshooting Steps**:
1. Check dashboard data refresh schedule
2. Verify underlying data source connections
3. Review alert configuration settings
4. Test notification delivery mechanisms

### Email Alert Problems
**Symptoms**:
- Missing failure notifications
- Delayed alert delivery
- Incorrect alert recipients

**Resolution**:
- Verify email configuration in Databricks
- Update notification recipient lists
- Test alert delivery mechanisms
- Configure backup notification methods

## Emergency Procedures

### Complete System Failure
**If both 6:00 AM workflow and 8:30 AM upload fail**:

1. **Immediate Assessment** (7:00 AM):
   - Check Databricks system status
   - Verify Snowflake connectivity
   - Contact Divya for Genesis system status

2. **Emergency Communication** (7:30 AM):
   - Notify collections management
   - Alert stakeholders about delays
   - Provide estimated recovery timeline

3. **Recovery Process**:
   - Manual data extraction if needed
   - Backup Google Sheet upload to Genesis
   - Coordinate with teams for adjusted schedules

### Partner Communication
**For external partners (SIM, etc.)**:
- Internal team resolves issues first
- Communicate delays promptly with estimated resolution
- Provide status updates every 2 hours during outages

## Escalation Contacts

### Technical Issues
- **Databricks Problems**: BI Team (biteam@happymoney.com)
- **Genesis Integration**: Divya (Engineering)
- **Data Pipeline Issues**: Data Engineering Team

### Business Issues
- **Campaign Configuration**: Collections Management
- **Suppression Rules**: Compliance Team
- **Partner Coordination**: Goal Realignment Managers

### Emergency Contacts
- **Primary**: hshi@happymoney.com
- **Secondary**: goalrealignment_managers@happymoney.com
- **Technical Escalation**: biteam@happymoney.com