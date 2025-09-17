# Technical Implementation

## Databricks Workflow Architecture

### Primary Workflow Configuration
- **Name**: `BI-2482_Outbound_List_Generation`
- **Schedule**: Daily at 6:00 AM EST (`14 0 6 * * ?`)
- **Timezone**: America/New_York
- **Status**: Active (UNPAUSED)

### Infrastructure Configuration

#### Cluster Setup
- **Type**: Job Cluster with auto-scaling (2-8 workers)
- **Instance Type**: i3.xlarge
- **Spark Version**: 13.3.x-scala2.12
- **Runtime Engine**: PHOTON (optimized performance)

#### AWS Configuration
- **Availability**: SPOT_WITH_FALLBACK
- **Zone**: us-east-1a
- **Instance Profile**: databricks_bi_profile
- **Spot Bid Price**: 100%

#### Notification System
- **Email**: hshi@happymoney.com (on failure)
- **Webhook**: ID 9bf8811d-0cc9-4006-9416-f9be857bcb67 (on failure)

### Job Types and Integration

#### Notebook Tasks
- **Source**: Git repository `business-intelligence-data-jobs`
- **Branch**: main
- **Language**: Python/SQL notebooks

#### Run Job Tasks
- **Purpose**: Execute other Databricks jobs with parameters
- **Dependencies**: Managed through workflow configuration

#### Environment Setup
- **Widgets**: Environment selection (dev/prod)
- **Connections**: Snowflake with appropriate roles/warehouses
- **Alerts**: Email notification systems

---

## Data Architecture

### Primary Data Sources
- `DATA_STORE.MVW_LOAN_TAPE`: Primary loan data *(Reliable for campaigns)*
- `DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY`: Historical snapshots
- `DATA_STORE.MVW_LOAN_TAPE_MONTHLY`: Monthly snapshots
- `ANALYTICS.VW_LOAN`: Loan master data
- `ANALYTICS_PII.VW_MEMBER_PII`: Member contact information
- `ANALYTICS_PII.VW_LEAD_PII`: Lead contact information
- `BRIDGE.VW_LOAN_PORTFOLIO_CURRENT`: Portfolio assignments
- `CRON_STORE.LKP_***`: Lookup tables for business rules

### Output Tables

#### Main Output
**Table**: `CRON_STORE.RPT_OUTBOUND_LISTS`

**Required Fields**:
- `LOAD_DATE`: Date of list generation
- `SET_NAME`: Campaign set identifier
- `LIST_NAME`: Specific list name
- `PAYOFFUID`: Customer identifier
- `SUPPRESSION_FLAG`: Whether customer is suppressed
- `LOAN_TAPE_ASOFDATE`: Loan data as-of date

#### Suppression Tracking
**Table**: `CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION`

**Required Fields**:
- `LOAD_DATE`: Date of suppression
- `SUPPRESSION_TYPE`: Global, Set, List, Cross Set, Cross List
- `SUPPRESSION_REASON`: Specific reason for suppression
- `PAYOFF_UID`: Customer identifier
- `SET_NAME`: Campaign set (if applicable)
- `LIST_NAME`: Specific list (if applicable)

### Integration Points

#### Genesys Integration
**Output**: `PII.RPT_GENESYS_CAMPAIGN_LISTS`
- Customer contact information
- Campaign-specific data
- Portfolio and delinquency information for agents

#### Genesys Configuration Table
**Table**: `BUSINESS_INTELLIGENCE.CRON_STORE.LKP_GENESYS_LIST_AUTOMATION_CONFIG`

**Key Fields**:
- `GENESYS_CAMPAIGN_NAME`: Campaign name in Genesys
- `GENESYS_CAMPAIGN_ID`: Unique campaign identifier
- `GENESYS_LIST_NAME`: List name in Genesys
- `GENESYS_LIST_ID`: Unique list identifier
- `QUERY_CONDITION`: SQL condition for list generation
- `CHANNEL`: Communication channel (Phone, Text, Email)
- `CAMPAIGN`: Internal campaign identifier
- `IS_ACTIVE`: Boolean flag for active/inactive campaigns

#### Historical Tracking
- `RPT_OUTBOUND_LISTS_HIST`: Audit trail
- `RPT_OUTBOUND_LISTS_SUPPRESSION_HIST`: Compliance tracking
- `LKP_GENESYS_LIST_AUTOMATION_CONFIG_HIST`: Daily configuration snapshots

---

## Development Standards

### Data Structure Requirements
When creating new lists, ensure proper structure with required fields and follow the suppression hierarchy:

1. **Global Suppression**: Applies to all campaigns
2. **Set-Level Suppression**: Applies to specific campaign sets
3. **List-Level Suppression**: Applies to specific lists
4. **Cross-Set/Cross-List Suppression**: Prevents campaign overlap

### Business Rules Implementation

#### Portfolio Segmentation
- Different rules for portfolio types (Blue FCU, USAlliance, SST)
- Special handling for decline and OFAC portfolios
- Portfolio-specific suppression rules

#### Contact Timing
- Respect DNC preferences and state regulations
- Time-of-day and day-of-week restrictions
- Appropriate cadence for campaign types

#### A/B Testing
- Account ID-based segmentation for testing
- 50/50 splits based on PAYOFFUID characteristics
- Separate tracking for test vs control groups

#### Compliance
- Proper suppression rule application
- Audit trail maintenance
- Customer preference and regulatory compliance

### Performance Optimization

#### Query Development
- Use parameterized values as variables
- Include comprehensive commenting
- Apply appropriate filters and limits
- Handle missing data gracefully

#### Resource Management
- Monitor cluster utilization
- Optimize auto-scaling behavior
- Track execution times and performance
- Use PHOTON engine for enhanced performance