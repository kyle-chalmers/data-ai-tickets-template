# Outbound List Generation Instructions

## Overview

This document provides comprehensive instructions for creating and maintaining outbound lists based on the unified outbound list generation workflow. The system consists of two primary jobs running within a single Databricks workflow:
- **BI-2482**: Outbound List Generation for GR (Goal Realignment) - Collections & Recovery
- **DI-986**: Outbound List Generation for Funnel - Marketing & Customer Engagement

**Current Workflow Structure**: Both jobs run as part of the unified `BI-2482_Outbound_List_Generation` Databricks workflow, with BI-2482 executing first, followed by DI-986 and their dependent jobs.

## BI-2482: Outbound List Generation for GR (Goal Realignment)

### Purpose
This job focuses on **collections and recovery** campaigns, generating daily outbound contact lists for Goal Realignment (GR) collections and recovery efforts.

### List Types Generated

#### 1. Call Lists
- **DPD3-14**: Loans 3-14 days past due
- **DPD15-29**: Loans 15-29 days past due  
- **DPD30-59**: Loans 30-59 days past due
- **DPD60-89**: Loans 60-89 days past due
- **DPD90+**: Loans 90+ days past due
- **Blue**: Blue Federal Credit Union portfolio (DPD < 90)
- **Due Diligence DPD3-89**: USAlliance and MSU FCU portfolios (DPD 3-89)

#### 2. SMS Campaigns
- **Payment Reminder**: 4 days before payment due
- **Due Date**: 1 day before payment due
- **DPD-based campaigns**: 3, 6, 8, 11, 15, 17, 21, 23, 25, 28, 33, 38, 44 days past due
- **TruStage campaigns**: DPD17 and DPD33 for TruStage portfolio

#### 3. Email Campaigns
- **GR Email**: General email campaigns for delinquent accounts

#### 4. Physical Mail
- **DPD15 Control/Test**: 15 days past due with A/B testing
- **DPD75 Control/Test**: 75 days past due with A/B testing

#### 5. Recovery Campaigns
- **Recovery Weekly**: Charge-off accounts within 7 days (runs every Tuesday)
- **Recovery Monthly Email**: Charge-off accounts with state-specific limitations (first Tuesday of month)

#### 6. Special Portfolios
- **SIMM**: DPD3-119 for specific portfolio segment
- **SST**: DPD3-119 for SST portfolio (Portfolio ID 205)

### Suppression Rules

#### Global Suppression
- **Bankruptcy**: Accounts with active bankruptcy flags
- **Cease & Desist**: Accounts with cease and desist contact rules (via `VW_LOAN_CONTACT_RULES`)
- **One-Time Payment (OTP)**: Accounts with pending payment requests
- **Loan Modification**: Accounts with recent modification requests
- **Natural Disaster**: ZIP codes in disaster-affected areas
- **Individual Suppression**: Manually suppressed accounts
- **Next Workable Date**: Accounts with future contact restrictions
- **3rd Party Placement**: Charge-off accounts placed with collection agencies

**Note**: `VW_LOAN_CONTACT_RULES` has been expanded beyond the original `BRIDGE.VW_LOAN_CONTACT_RULES` to include SMS opt-out information from the LoanPro system via `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT` (where `SMS_CONSENT_LS = 'NO'` sets `SUPPRESS_TEXT = TRUE` with `SOURCE = 'LOANPRO'`).

#### Set-Level Suppression
- **State Regulations**: Minnesota, Massachusetts, DC compliance restrictions
- **Do Not Contact**: Phone, text, letter, and email preferences
- **Delinquent Amount Zero**: Accounts with zero outstanding balances

#### List-Level Suppression
- **Phone Test**: Test accounts excluded from production calls
- **Autopay**: Accounts with automatic payment arrangements
- **Remitter**: Accounts in remitter campaigns

---

## DI-986: Outbound List Generation for Funnel

### Purpose
This job focuses on **marketing and customer engagement** campaigns, generating daily outbound marketing lists for various funnel communication campaigns.

### List Types Generated

#### 1. Email Non-Opener SMS Campaigns
- **Purpose**: Target customers who haven't opened emails with SMS communication
- **Source**: `cron_store.TMP_Email_Non_Openers_DI_749`
- **Lists**: Various journey-based lists (AppAbandon, OfferShown, OfferSelected, DocUpload, ESign)

#### 2. Allocated Capital Partner Reminder
- **Purpose**: Send reminders to partners about allocated capital
- **Trigger**: Daily execution
- **Criteria**: Applications with loan sub-status ID 123
- **List**: PartnerAllocated

#### 3. Prescreen Email Campaign
- **Purpose**: Email marketing for prescreen campaigns
- **Trigger**: Based on Google Sheets schedule (`Prescreen_DM/Email`)
- **Source**: IWCO data joined with application and PII data
- **Criteria**: Campaign-specific UTM parameters and valid email addresses

#### 4. PIF (Paid in Full) Email Campaign
- **Purpose**: Target customers with recently paid-off loans
- **Trigger**: Monthly (1st of each month)
- **Criteria**: Loans paid in full within last 12 months, active members

#### 5. 6M to PIF Email Campaign
- **Purpose**: Target customers approaching loan payoff
- **Trigger**: Monthly (1st of each month)
- **Criteria**: Current loans with ≤6 months remaining, active members

#### 6. SMS Funnel Communication Campaigns
- **Purpose**: Multi-stage SMS campaigns based on application status
- **Cadence**: Daily or every 2-3 days depending on application ID
- **Statuses Covered**:
  - Started
  - Credit Freeze
  - Offers Shown
  - Offer Selected
  - Doc Upload
  - Underwriting
  - Allocated
  - Loan Docs Ready

#### 7. AutoPay SMS Campaigns
- **Purpose**: Encourage AutoPay enrollment
- **Triggers**:
  - 7 days after loan origination
  - 7 days after first scheduled payment
  - 7 days + 1 month after first scheduled payment
- **Criteria**: Active loans without AutoPay opt-in

### Suppression Rules

#### Set-Level Suppression
- **DNC (Do Not Contact)**: Text and email opt-outs
- **State Exclusions**: NV, IA, MA for credit union campaigns
- **Credit Policy**: Decline decisions and non-tier 1-3 customers
- **Account Level**: Email opt-outs, unsubscribes, delinquency, charge-offs
- **Customer Level**: Recent applications, active accounts, delinquency history

#### List-Level Suppression
- Campaign-specific suppression rules
- Cross-set and cross-list exclusions

---

## General Instructions for Creating New Lists

### 1. Data Structure Requirements

#### Main Output Table
- **Table**: `CRON_STORE.RPT_OUTBOUND_LISTS`
- **Required Fields**:
  - `LOAD_DATE`: Date of list generation
  - `SET_NAME`: Campaign set identifier
  - `LIST_NAME`: Specific list name
  - `PAYOFFUID`: Customer identifier
  - `SUPPRESSION_FLAG`: Whether customer is suppressed
  - `LOAN_TAPE_ASOFDATE`: Loan data as-of date

#### Suppression Table
- **Table**: `CRON_STORE.RPT_OUTBOUND_LISTS_SUPPRESSION`
- **Required Fields**:
  - `LOAD_DATE`: Date of suppression
  - `SUPPRESSION_TYPE`: Global, Set, List, Cross Set, Cross List
  - `SUPPRESSION_REASON`: Specific reason for suppression
  - `PAYOFF_UID`: Customer identifier
  - `SET_NAME`: Campaign set (if applicable)
  - `LIST_NAME`: Specific list (if applicable)

### 2. Suppression Logic Hierarchy

#### 1. Global Suppression
- Applies to all campaigns
- Examples: Bankruptcy, cease & desist, OTP, loan modifications, natural disasters
- **Note**: CEASE_AND_DESIST logic uses `VW_LOAN_CONTACT_RULES` with specific suppress_* fields for different contact types

#### 2. Set-Level Suppression
- Applies to specific campaign sets
- Examples: DNC preferences, state regulations, credit policy restrictions
- Can be split by contact type (email vs text vs call) using available suppress_* fields

#### 3. List-Level Suppression
- Applies to specific lists within sets
- Examples: Phone testing, autopay exclusions, campaign-specific rules

#### 4. Cross-Set/Cross-List Suppression
- Prevents overlap between different campaigns
- Examples: Remitter campaigns suppressing SMS and email campaigns

### 3. Technical Implementation

#### Databricks Workflow Architecture
The outbound list generation system runs as a comprehensive Databricks workflow with the following structure:

**Workflow Name**: `BI-2482_Outbound_List_Generation` (Note: Contains both BI-2482 and DI-986 jobs)
**Schedule**: Daily at 6:00 AM EST (Quartz Cron: `14 0 6 * * ?`)
**Timezone**: America/New_York
**Status**: Active (UNPAUSED)

#### Workflow Dependencies and Execution Order
```
1. BI-2482_Outbound_List_Generation_for_GR (Main List Generation)
   ↓
2. Parallel Execution:
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

#### Infrastructure Configuration
- **Cluster Type**: Job Cluster with auto-scaling (2-8 workers)
- **Instance Type**: i3.xlarge
- **Spark Version**: 13.3.x-scala2.12
- **Runtime Engine**: PHOTON (optimized for performance)
- **AWS Configuration**:
  - Availability: SPOT_WITH_FALLBACK
  - Zone: us-east-1a
  - Instance Profile: databricks_bi_profile
  - Spot Bid Price: 100%

#### Notification System
- **Email Notifications**: hshi@happymoney.com (on failure)
- **Webhook Notifications**: ID 9bf8811d-0cc9-4006-9416-f9be857bcb67 (on failure)

#### Individual Job Descriptions

**Core List Generation Jobs:**
- **BI-2482_Outbound_List_Generation_for_GR**: Main job that generates all outbound lists for Goal Realignment campaigns
- **DI-986_Outbound_List_Generation_for_funnel**: Generates marketing and engagement lists for funnel campaigns

**Supporting Jobs:**
- **BI-2584_LKP_GENESYS_LIST_AUTOMATION_CONFIG_HIST_Table**: Creates daily snapshots of Genesys campaign configuration
- **BI-2609_GR_Email_High_Risk_Letter_Upload**: Handles high-risk letter uploads for GR campaigns
- **BI-737_GR_Call_List**: Processes and formats call lists for GR campaigns
- **BI-813_Remitter**: Manages remitter campaign lists
- **DI-862_SIMM_File_Upload**: Handles SIMM portfolio file uploads
- **Outbound_list_for_funnel_DI-749_Email_Non_Openers_from_SFTP**: Processes email non-opener data from SFTP
- **BI-820_GR_text_eligible**: Determines text eligibility for GR campaigns
- **DI-1049_PIF_list_to_SFMC_SFTP**: Manages PIF (Paid in Full) lists for SFMC via SFTP
- **DI-977_prescreen_email_list_upload**: Handles prescreen email list uploads

**Job Types:**
- **Notebook Tasks**: Run Python/SQL notebooks from Git repository
- **Run Job Tasks**: Execute other Databricks jobs with parameters
- **Git Integration**: All notebook tasks pull from `business-intelligence-data-jobs` repository on main branch

#### Environment Setup
- Use Databricks widgets for environment selection (dev/prod)
- Configure Snowflake connections with appropriate roles and warehouses
- Set up email notification systems for alerts

#### Primary Data Sources
- `DATA_STORE.MVW_LOAN_TAPE`: Primary loan data source *(Reliable and stable for campaign generation)*
- `DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY`: Historical loan snapshots *(Proven data source for historical analysis)*  
- `DATA_STORE.MVW_LOAN_TAPE_MONTHLY`: Monthly loan snapshots *(Established source for monthly reporting)*
- `ANALYTICS.VW_LOAN`: Loan master data
- `ANALYTICS_PII.VW_MEMBER_PII`: Member contact information
- `ANALYTICS_PII.VW_LEAD_PII`: Lead contact information
- `BRIDGE.VW_LOAN_PORTFOLIO_CURRENT`: Portfolio assignments
- `CRON_STORE.LKP_***`: Lookup tables for business rules

#### Output Integration
- Update `PII.RPT_GENESYS_CAMPAIGN_LISTS` for contact center integration
- Include customer contact information and campaign-specific data
- Provide portfolio and delinquency information for agents

#### Genesys Campaign Configuration
- **Table**: `BUSINESS_INTELLIGENCE.CRON_STORE.LKP_GENESYS_LIST_AUTOMATION_CONFIG`
- **Purpose**: Configuration table for Genesys campaign automation
- **Key Fields**:
  - `GENESYS_CAMPAIGN_NAME`: Name of the campaign in Genesys
  - `GENESYS_CAMPAIGN_ID`: Unique identifier for the campaign in Genesys
  - `GENESYS_LIST_NAME`: Name of the list in Genesys
  - `GENESYS_LIST_ID`: Unique identifier for the list in Genesys
  - `QUERY_CONDITION`: SQL condition for list generation
  - `CHANNEL`: Communication channel (Phone, Text, Email)
  - `CAMPAIGN`: Internal campaign identifier
  - `IS_ACTIVE`: Boolean flag for active/inactive campaigns
  - `LOAD_DATE`: Date when configuration was loaded

**Important**: When adding or retiring campaigns in Genesys, this table must be updated to reflect the changes. The table is used for:
- Campaign automation configuration
- List generation automation
- Historical tracking via `LKP_GENESYS_LIST_AUTOMATION_CONFIG_HIST`

#### Historical Tracking
- Save to `RPT_OUTBOUND_LISTS_HIST` for audit trail
- Save to `RPT_OUTBOUND_LISTS_SUPPRESSION_HIST` for compliance tracking

### 4. Business Rules to Consider

#### Portfolio Segmentation
- Different rules for different portfolio types (Blue FCU, USAlliance, SST, etc.)
- Special handling for decline and OFAC portfolios
- Portfolio-specific suppression rules

#### Contact Timing
- Respect DNC preferences and state regulations
- Consider time-of-day and day-of-week restrictions
- Implement appropriate cadence for different campaign types

#### A/B Testing
- Use account ID-based segmentation for testing
- Implement 50/50 splits based on PAYOFFUID characteristics
- Track test vs control groups separately

#### Compliance
- Ensure all suppression rules are properly applied
- Maintain audit trail of all list generations
- Respect customer preferences and regulatory requirements

### 5. Monitoring and Maintenance

#### Workflow Monitoring
- **Execution Time**: Monitor daily workflow completion time (target: before 8:00 AM EST)
- **Failure Points**: Track which jobs fail most frequently
- **Resource Usage**: Monitor cluster utilization and auto-scaling behavior
- **Dependency Issues**: Watch for jobs that consistently wait for dependencies

#### Data Quality Checks
- Validate loan tape freshness and data completeness
- Check for data pipeline execution issues
- Monitor portfolio-specific alerts (e.g., SST portfolio)
- Verify list generation counts match expected volumes

#### Email Alerts
- Send notifications for data quality issues
- Alert on failed executions
- Provide campaign performance summaries

#### Historical Tracking
- Maintain audit trail of all list generations and suppressions
- Track suppression reason effectiveness
- Monitor campaign performance metrics

#### Regular Tasks
- Monitor suppression rule effectiveness
- Review portfolio segmentation logic
- Validate business rule accuracy
- Update contact preferences and regulations

#### Workflow Troubleshooting

**Common Issues:**
- **Cluster Startup Delays**: Check AWS spot instance availability and pricing
- **Memory Issues**: Monitor i3.xlarge cluster memory usage during peak processing
- **Git Sync Problems**: Verify repository access and branch permissions
- **Snowflake Connection Timeouts**: Check warehouse availability and connection limits

**Failure Recovery:**
- **Partial Failures**: Re-run failed jobs individually after fixing root cause
- **Complete Workflow Failure**: Check cluster logs and Snowflake connectivity
- **Data Quality Issues**: Validate source data freshness before re-running

**Performance Optimization:**
- **Cluster Scaling**: Adjust min/max workers based on daily data volumes
- **Job Parallelization**: Optimize dependency chains to reduce total runtime
- **Resource Allocation**: Consider upgrading to larger instance types if consistently hitting limits

### 6. Genesys Campaign Management

#### Adding New Campaigns
When adding a new campaign to Genesys, update the `LKP_GENESYS_LIST_AUTOMATION_CONFIG` table with:
1. **Campaign Information**:
   - `GENESYS_CAMPAIGN_NAME`: Official campaign name in Genesys
   - `GENESYS_CAMPAIGN_ID`: Unique campaign identifier from Genesys
   - `GENESYS_LIST_NAME`: List name in Genesys
   - `GENESYS_LIST_ID`: Unique list identifier from Genesys

2. **Configuration Details**:
   - `QUERY_CONDITION`: SQL condition for list generation
   - `CHANNEL`: Communication channel (Phone, Text, Email)
   - `CAMPAIGN`: Internal campaign identifier (matches LIST_NAME in outbound lists)
   - `IS_ACTIVE`: Set to `true` for active campaigns
   - `LOAD_DATE`: Current date

#### Retiring Campaigns
When retiring a campaign:
1. Set `IS_ACTIVE` to `false` in the configuration table
2. Update `LOAD_DATE` to current date
3. Ensure the campaign is removed from active list generation jobs
4. Update any hardcoded campaign lists in the outbound list generation scripts

#### Historical Tracking
- The `LKP_GENESYS_LIST_AUTOMATION_CONFIG_HIST` table automatically tracks daily snapshots
- Use this table to audit campaign configuration changes over time
- Job BI-2584 handles the daily historical snapshot creation

#### Integration Points
- Campaign names in `LKP_GENESYS_LIST_AUTOMATION_CONFIG.CAMPAIGN` must match `LIST_NAME` values in `RPT_OUTBOUND_LISTS`
- The `CHANNEL` field determines which Genesys integration is used (Phone vs Text vs Email)
- `QUERY_CONDITION` can be used for automated list generation based on business rules

### 7. Change Management

#### Adding New Jobs to the Workflow
When adding a new job to the Databricks workflow:

1. **Determine Dependencies**:
   - Identify which existing jobs must complete first
   - Consider data dependencies and timing requirements
   - Plan for parallel execution where possible

2. **Job Configuration**:
   - **Notebook Tasks**: Add to Git repository and reference by path
   - **Run Job Tasks**: Reference existing job IDs
   - **Parameters**: Configure environment and other required parameters
   - **Cluster**: Use existing job cluster or create new one if needed

3. **Workflow Updates**:
   - Add job to workflow YAML configuration
   - Define dependencies using `depends_on` section
   - Configure notifications and error handling
   - Test in development environment first

4. **Deployment Process**:
   - Update workflow configuration in Databricks
   - Validate job execution in test environment
   - Monitor first few production runs closely
   - Document new job in this instruction guide

#### Testing
- Test changes in non-production environments first
- Validate business rule modifications
- Coordinate with collections and compliance teams
- Test Genesys campaign configuration changes in dev environment
- Test new workflow jobs with sample data

#### Documentation
- Document rule changes and rationale
- Update this instruction document as needed
- Maintain clear change logs
- Document Genesys campaign configuration changes

#### Coordination
- Work with collections and compliance teams
- Coordinate with Genesys administrators for campaign setup
- Ensure proper stakeholder communication
- Follow established change management processes

---

## Genesis Integration Process

### Overview
After the Databricks workflows generate outbound lists in Snowflake, the lists are automatically uploaded to the Genesis system for campaign execution. This integration involves daily import/export processes and comprehensive monitoring.

### Daily Process Flow

#### Complete Daily Timeline (Eastern Time)
1. **6:00 AM Eastern**: Databricks workflow generates lists in Snowflake (30-45 minutes)
2. **8:30 AM Eastern**: Divya's engineering job uploads lists to Genesis (~30 minutes) 
3. **9:00 AM Eastern**: Lists ready for execution in Genesis
4. **10:30 PM Eastern**: Export process retrieves results from Genesis
5. **After 10:30 PM**: Results processed through Kafka to Snowflake

### Daily Import Process (6:00 AM - 9:00 AM Eastern)

#### Phase 1: List Generation (6:00 AM Eastern)
- **Duration**: 30-45 minutes (typically closer to 30 minutes)
- **Process**: Databricks workflows generate lists in Snowflake based on campaign configuration table
- **Output**: Lists stored in Snowflake with suppression logic applied
- **Status**: Lists marked as ready for Genesis upload

#### Phase 2: Genesis Upload (8:30 AM Eastern) 
- **Owner**: Divya (Engineering team)
- **Duration**: ~30 minutes
- **Process**: Automated system reads active campaigns from Snowflake and uploads to Genesis
- **Architecture**: 
  - Sets and individual lists within sets
  - Campaign configuration drives which lists get uploaded
  - Active campaign filtering based on `LKP_GENESYS_LIST_AUTOMATION_CONFIG`

#### Phase 3: Ready for Execution (9:00 AM Eastern)
- **Status**: All lists available in Genesis for campaign execution
- **Teams**: Collections and marketing teams can begin outbound activities
- **Channels**: Phone calls, SMS messages, emails ready for deployment

### Daily Export Process (10:30 PM Eastern)

#### Results Extraction
- **Schedule**: Daily at 10:30 PM Eastern
- **Owner**: Divya (Engineering team)
- **Purpose**: Retrieve campaign execution results from Genesis
- **Data Captured**:
  - Successful outbound attempts
  - Failed outbound attempts  
  - Campaign performance metrics
  - Contact attempt outcomes

#### Data Flow Architecture
1. **Genesis → Kafka**: Results extracted from Genesis and sent to Kafka messaging service
2. **Kafka → Snowflake**: Data engineering team's automated process listens to Kafka and loads data into Snowflake
3. **Analytics**: Results available for campaign performance analysis and compliance reporting

### Campaign Configuration Management

#### Segmentation Logic Documentation
- **Location**: Google Sheet with campaign segmentation logic
- **Structure**: Sets and individual lists within sets
- **Examples**:
  - **SIM Set**: Contains specific loan criteria for SIM campaigns
  - **Call List Set**: Contains different categories of call lists (DPD3-14, DPD15-29, etc.)
- **Maintenance**: Requires quarterly review and updates

#### Suppression Rules Documentation  
- **Global Suppressions**: Bankruptcy, cease & desist, agent holds, natural disasters
- **Set-Level Suppressions**: State regulations, Do Not Contact preferences  
- **List-Level Suppressions**: Mutual exclusivity rules (e.g., SIM vs internal lists, Remitter vs SMS campaigns)
- **Review Schedule**: Quarterly updates recommended (especially for regulatory changes)

### Failure Handling and Recovery

#### Common Failure Scenarios
1. **6:00 AM Job Fails**: Databricks workflow failure
   - **Impact**: No lists generated for Genesis upload
   - **Recovery**: Manual job restart, coordinate with Divya for delayed upload

2. **8:30 AM Upload Fails**: Genesis upload process failure  
   - **Impact**: Lists unavailable in Genesis for campaign execution
   - **Recovery**: Divya re-triggers upload job or manual upload via backup Google Sheet

3. **Partial Upload Issues**: Some lists upload successfully, others fail
   - **Recovery**: Targeted re-upload of failed lists only

#### Manual Backup Process
- **Backup Method**: Google Sheet with formatted lists
- **Usage**: Manual upload to Genesis when automated process fails
- **Access**: Available to data team and collections management

### Monitoring and Alerting

#### Tableau Dashboard Overview
- **Purpose**: Monitor Genesis campaign import/export process integrity
- **Access**: Available to collections team, data team, and stakeholders
- **Philosophy**: Dashboard intentionally blank when everything works correctly
- **Alert Mechanism**: Only populates data when errors occur

#### Key Monitoring Metrics

##### Import/Export Volume Matching
- **Phone Lists**: Daily count of imported payoff UIDs vs exported results
- **Text Lists**: Daily count of imported payoff UIDs vs exported results  
- **Target**: 100% match between imported and exported volumes
- **Alert Trigger**: Any discrepancy between import and export counts

##### Historical Trend Analysis
- **Visual**: Line graph showing import vs export volumes over time
- **Red Line Indicators**: Show dates with volume mismatches
- **Blue/Purple Divergence**: Indicates specific channel issues
- **Typical Issues**: Import completed but export failed, or vice versa

#### Campaign Status Monitoring
- **Active Campaign Check**: Ensures all uploaded lists have corresponding active campaigns in Genesis
- **Inactive Campaign Alert**: Flags campaigns that should be archived
- **Campaign Configuration Validation**: Verifies DPD-based campaign segmentation

#### Data Quality Checks
- **Duplicate Detection**: Monitors for repeated payoff UIDs across campaigns
- **Note**: Some overlap acceptable for first/second payment reminders vs DPD campaigns
- **New Loan Detection**: Alerts if loans appear in export that weren't in import (should never happen)

#### Notification Setup
- **Current Recipients**: Lisa Carney, Calvin/Kelvin (to be confirmed)
- **Notification Triggers**: 
  - Volume mismatches between import/export
  - Campaign configuration issues
  - Data quality problems
- **Delivery Method**: Tableau alert emails

### Process Improvements

#### Proactive Partner Communication
- **Current Gap**: Partners (like SIM) sometimes contact Happy Money about missing lists
- **Proposed Enhancement**: Automated failure notifications to external partners
- **Implementation Options**:
  - Direct email notifications on job failures
  - Internal Slack notifications for faster response
  - Staged approach: Internal alerts first, then partner notifications

#### Internal Notification Enhancement
- **Slack Integration**: Job failure notifications to team channels
- **Specific Job Monitoring**: Focus on Genesis list generation workflow
- **Escalation Process**: Internal team resolves before notifying partners

#### Suppression Reporting
- **Waterfall Report**: Tableau dashboard showing suppression breakdown
  - Volume suppressed by global rules
  - Volume suppressed by set-level rules  
  - Volume suppressed by list-level rules
  - Final approved volume for Genesis upload
- **Purpose**: Validate suppression rule effectiveness and identify optimization opportunities

#### SMS Opt-out Integration
- **Current State**: Genesis handles opt-outs automatically (customers won't receive texts if previously opted out)
- **Enhancement Opportunity**: Pull Genesis opt-out data back to Snowflake for centralized suppression
- **Use Cases**: 
  - Customer behavior analysis (opt-out timing patterns)
  - Enhanced contact rules table for all communication channels
  - Cross-campaign suppression optimization

### Documentation Maintenance

#### Quarterly Review Process
- **Suppression Rules**: Review and update based on regulatory changes
- **Campaign Configuration**: Validate active campaigns and retire unused ones
- **Partner Requirements**: Confirm ongoing suppression needs (e.g., FTCU charge-off handling)
- **Process Efficiency**: Identify automation opportunities and failure point improvements

#### Contact Rules Table Enhancement
- **Current Scope**: Loan-level contact suppression rules
- **Expansion Plan**: Include application-level suppression for comprehensive contact management
- **Data Sources**: 
  - LoanPro SMS opt-out information
  - Genesis opt-out data
  - Email unsubscribe preferences
- **Goal**: Single source of truth for all outbound contact suppression rules

---

## Key Differences Between Jobs

| Aspect | BI-2482 (GR) | DI-986 (Funnel) |
|--------|--------------|-----------------|
| **Purpose** | Collections & Recovery | Marketing & Engagement |
| **Primary Focus** | Delinquent accounts | Application funnel |
| **Suppression Complexity** | High (regulatory compliance) | Medium (marketing preferences) |
| **Campaign Types** | DPD-based, recovery-focused | Journey-based, engagement-focused |
| **Data Sources** | Loan tape, collections data | Application data, marketing data |
| **Compliance Requirements** | Strict (state regulations) | Moderate (marketing regulations) |

---

## Contact Information

For questions or issues related to outbound list generation:
- **BI Team**: biteam@happymoney.com
- **Collections Management**: hshi@happymoney.com
- **Goal Realignment Managers**: goalrealignment_managers@happymoney.com

---

*Last Updated: September 8, 2025*
*Version: 2.0*
*Maintained by: Business Intelligence Team*
