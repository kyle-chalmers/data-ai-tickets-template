# Genesys Integration Process

## Overview
After Databricks generates outbound lists in Snowflake, they are automatically uploaded to Genesys for campaign execution. This involves daily import/export processes with comprehensive monitoring.

## Daily Import Process (8:30 AM Eastern)

### Phase 1: List Preparation (6:00-7:00 AM)
- **Source**: Lists generated in Snowflake by Databricks workflow
- **Output**: Campaign lists ready for Genesys upload
- **Configuration**: Driven by `LKP_GENESYS_LIST_AUTOMATION_CONFIG`

### Phase 2: Genesys Upload (8:30 AM)
- **Owner**: Divya (Engineering team)
- **Duration**: ~30 minutes
- **Process**: Automated system reads active campaigns and uploads to Genesys
- **Architecture**: Sets and individual lists within sets

### Phase 3: Campaign Activation (9:00 AM)
- **Status**: All lists available in Genesys
- **Teams**: Collections and marketing teams begin outbound activities
- **Channels**: Phone calls, SMS messages, emails ready for deployment

## Daily Export Process (10:30 PM Eastern)

### Results Extraction
- **Schedule**: Daily at 10:30 PM Eastern
- **Owner**: Divya (Engineering team)
- **Purpose**: Retrieve campaign execution results from Genesys

### Data Captured
- Successful outbound attempts
- Failed outbound attempts
- Campaign performance metrics
- Contact attempt outcomes

### Data Flow Architecture
1. **Genesys → Kafka**: Results extracted and sent to Kafka messaging
2. **Kafka → Snowflake**: Automated process loads data into Snowflake
3. **Analytics**: Results available for performance analysis and compliance

## Campaign Configuration Management

### Configuration Table Structure
**Location**: `LKP_GENESYS_LIST_AUTOMATION_CONFIG`

**Key Integration Points**:
- Campaign names must match `LIST_NAME` values in `RPT_OUTBOUND_LISTS`
- `CHANNEL` field determines integration type (Phone vs Text vs Email)
- `QUERY_CONDITION` enables automated list generation
- `IS_ACTIVE` controls campaign inclusion

### Segmentation Logic
- **Documentation**: Google Sheet with campaign logic
- **Structure**: Sets containing individual lists
- **Examples**:
  - **SIM Set**: Specific loan criteria for SIM campaigns
  - **Call List Set**: DPD categories (DPD3-14, DPD15-29, etc.)
- **Maintenance**: Quarterly review and updates

### Historical Tracking
- **Table**: `LKP_GENESYS_LIST_AUTOMATION_CONFIG_HIST`
- **Purpose**: Daily snapshots for audit trail
- **Process**: Job BI-2584 handles daily creation
- **Usage**: Track configuration changes over time

## Monitoring and Alerting

### Tableau Dashboard Philosophy
- **Purpose**: Monitor import/export process integrity
- **Design**: Intentionally blank when everything works correctly
- **Alert Mechanism**: Only shows data when errors occur
- **Access**: Collections team, data team, stakeholders

### Key Monitoring Metrics

#### Import/Export Volume Matching
- **Phone Lists**: Daily imported vs exported payoff UIDs
- **Text Lists**: Daily imported vs exported payoff UIDs
- **Target**: 100% match between import and export volumes
- **Alert Trigger**: Any discrepancy in counts

#### Historical Trend Analysis
- **Visual**: Line graph showing volumes over time
- **Red Lines**: Dates with volume mismatches
- **Blue/Purple Divergence**: Specific channel issues
- **Typical Issues**: Import completed but export failed, or vice versa

#### Campaign Status Monitoring
- **Active Campaign Check**: Uploaded lists have active campaigns
- **Inactive Campaign Alert**: Campaigns needing archival
- **Configuration Validation**: DPD-based segmentation verification

#### Data Quality Checks
- **Duplicate Detection**: Repeated payoff UIDs across campaigns
- **Acceptable Overlap**: First/second payment reminders vs DPD campaigns
- **New Loan Detection**: Loans in export not in import (should never happen)

### Notification Setup
- **Current Recipients**: Lisa Carney, Calvin/Kelvin (to be confirmed)
- **Triggers**:
  - Volume mismatches between import/export
  - Campaign configuration issues
  - Data quality problems
- **Delivery**: Tableau alert emails

## Failure Handling and Recovery

### Common Failure Scenarios

#### 6:00 AM Job Fails
- **Impact**: No lists generated for Genesys upload
- **Recovery**: Manual job restart, coordinate with Divya for delayed upload

#### 8:30 AM Upload Fails
- **Impact**: Lists unavailable in Genesys for execution
- **Recovery**: Divya re-triggers upload or manual upload via backup Google Sheet

#### Partial Upload Issues
- **Scenario**: Some lists upload successfully, others fail
- **Recovery**: Targeted re-upload of failed lists only

### Manual Backup Process
- **Method**: Google Sheet with formatted lists
- **Usage**: Manual upload when automated process fails
- **Access**: Data team and collections management

## Process Improvements

### Proactive Communication
- **Current Gap**: Partners contact Happy Money about missing lists
- **Enhancement**: Automated failure notifications to external partners
- **Options**:
  - Direct email notifications on job failures
  - Internal Slack notifications for faster response
  - Staged approach: Internal alerts first, then partner notifications

### Internal Notification Enhancement
- **Slack Integration**: Job failure notifications to team channels
- **Monitoring**: Focus on Genesys list generation workflow
- **Escalation**: Internal resolution before partner notifications

### Suppression Reporting
- **Waterfall Report**: Tableau dashboard showing suppression breakdown
  - Volume suppressed by global rules
  - Volume suppressed by set-level rules
  - Volume suppressed by list-level rules
  - Final approved volume for Genesys upload
- **Purpose**: Validate suppression effectiveness and optimization

### SMS Opt-out Integration
- **Current State**: Genesys handles opt-outs automatically
- **Enhancement**: Pull Genesys opt-out data to Snowflake
- **Use Cases**:
  - Customer behavior analysis (opt-out patterns)
  - Enhanced contact rules for all channels
  - Cross-campaign suppression optimization