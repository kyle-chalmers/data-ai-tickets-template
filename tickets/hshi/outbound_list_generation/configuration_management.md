# Configuration Management

## Adding New Campaigns

### Step 1: Genesys Campaign Setup
**Before updating configuration table**:
1. Create campaign in Genesys system
2. Obtain campaign ID and list ID from Genesys
3. Confirm campaign name and channel type
4. Test campaign configuration in Genesys

### Step 2: Update Configuration Table
**Table**: `LKP_GENESYS_LIST_AUTOMATION_CONFIG`

**Required Fields**:
```sql
INSERT INTO LKP_GENESYS_LIST_AUTOMATION_CONFIG VALUES (
    'Campaign_Name_In_Genesys',          -- GENESYS_CAMPAIGN_NAME
    'CAMP_ID_12345',                     -- GENESYS_CAMPAIGN_ID
    'List_Name_In_Genesys',              -- GENESYS_LIST_NAME
    'LIST_ID_67890',                     -- GENESYS_LIST_ID
    'DPD_RANGE = ''3-14''',              -- QUERY_CONDITION
    'Phone',                             -- CHANNEL (Phone/Text/Email)
    'DPD3_14_CALLS',                     -- CAMPAIGN (matches LIST_NAME)
    TRUE,                                -- IS_ACTIVE
    CURRENT_DATE()                       -- LOAD_DATE
);
```

**Key Requirements**:
- `CAMPAIGN` field must match `LIST_NAME` in `RPT_OUTBOUND_LISTS`
- `CHANNEL` determines which Genesys integration is used
- `QUERY_CONDITION` can be used for automated list generation
- `IS_ACTIVE` must be `true` for active campaigns

### Step 3: Update List Generation Code
**Modify appropriate job**:
- **BI-2482**: For collections and recovery campaigns
- **DI-986**: For marketing and funnel campaigns

**Add campaign logic**:
```sql
-- Example: Add new DPD campaign
WHEN 'DPD3_14_CALLS' THEN (
    SELECT PAYOFFUID
    FROM loan_data
    WHERE days_past_due BETWEEN 3 AND 14
    AND portfolio_type = 'STANDARD'
    -- Apply appropriate suppression rules
)
```

### Step 4: Testing and Validation
1. **Development Environment**: Test new campaign in dev first
2. **Data Validation**: Verify correct record counts and business logic
3. **Suppression Testing**: Ensure proper suppression rules apply
4. **Genesys Integration**: Confirm upload and activation work correctly

### Step 5: Production Deployment
1. **Code Deployment**: Deploy tested code to production
2. **Configuration Activation**: Ensure `IS_ACTIVE = true` in config table
3. **Monitoring**: Watch first few executions closely
4. **Documentation**: Update campaign documentation

## Retiring Campaigns

### Step 1: Deactivate Configuration
```sql
UPDATE LKP_GENESYS_LIST_AUTOMATION_CONFIG
SET IS_ACTIVE = false,
    LOAD_DATE = CURRENT_DATE()
WHERE CAMPAIGN = 'Campaign_To_Retire';
```

### Step 2: Remove from List Generation
- Comment out or remove campaign logic from job code
- Ensure no hardcoded references remain
- Update any dependent campaigns that reference this one

### Step 3: Genesys Cleanup
- Archive campaign in Genesys system
- Preserve historical data for compliance
- Update campaign status documentation

### Step 4: Documentation Updates
- Update campaign type documentation
- Remove from active campaign lists
- Archive in historical tracking

## Suppression Rule Management

### Global Suppression Updates
**Common Updates**:
- **Regulatory Changes**: New state restrictions or compliance requirements
- **Business Policy Changes**: Updated contact preferences or timing rules
- **Data Source Changes**: New suppression data sources or field changes

**Update Process**:
1. **Impact Assessment**: Identify affected campaigns and volumes
2. **Testing**: Validate new rules in development environment
3. **Stakeholder Review**: Get approval from compliance and business teams
4. **Phased Rollout**: Deploy gradually with monitoring

### Set-Level Suppression Changes
**Typical Scenarios**:
- **Portfolio-Specific Rules**: New portfolio requirements or restrictions
- **Channel-Specific Updates**: Different rules for phone, text, email
- **State Regulation Changes**: Updated compliance requirements by state

**Implementation**:
```sql
-- Example: Add new state restriction
CASE WHEN state_code IN ('NY', 'CA')
     AND campaign_type = 'COLLECTIONS'
     THEN 'SUPPRESSED_STATE_REGULATION'
     ELSE 'ELIGIBLE'
END
```

### List-Level Suppression Updates
**Common Changes**:
- **Campaign Mutual Exclusivity**: Prevent overlap between specific campaigns
- **A/B Testing Rules**: Update testing segmentation logic
- **Special Portfolio Handling**: Unique rules for specific portfolios

## Change Management Process

### Development Workflow
1. **Branch Creation**: Create feature branch for changes
2. **Development**: Make changes in development environment
3. **Testing**: Comprehensive testing with sample data
4. **Code Review**: Peer review of changes
5. **Staging**: Deploy to staging environment for validation
6. **Production**: Deploy to production with monitoring

### Approval Requirements
**Business Changes**:
- Collections management approval for GR campaigns
- Marketing team approval for funnel campaigns
- Compliance team approval for suppression rule changes

**Technical Changes**:
- BI team review for code changes
- Data engineering review for data pipeline impacts
- Infrastructure team review for performance impacts

### Documentation Requirements
**For Each Change**:
- **Business Justification**: Why the change is needed
- **Technical Specification**: What exactly is being changed
- **Impact Assessment**: Which campaigns and volumes are affected
- **Testing Results**: Validation of change effectiveness
- **Rollback Plan**: How to revert if issues arise

### Testing Standards

#### Campaign Testing
- **Data Validation**: Verify correct records selected
- **Volume Testing**: Confirm expected list sizes
- **Suppression Testing**: Validate all suppression rules apply
- **Integration Testing**: Ensure Genesys upload works correctly

#### Performance Testing
- **Execution Time**: Measure impact on workflow duration
- **Resource Usage**: Monitor cluster utilization changes
- **Data Quality**: Validate output data quality maintained

#### Regression Testing
- **Existing Campaigns**: Ensure no impact on current campaigns
- **Historical Comparison**: Compare new results to historical patterns
- **Cross-Campaign Impact**: Verify no unintended interactions

## Workflow Job Management

### Adding New Jobs to Workflow
**Planning Phase**:
1. **Determine Dependencies**: Identify prerequisite jobs
2. **Resource Planning**: Estimate compute and timing requirements
3. **Integration Points**: Plan data inputs and outputs
4. **Testing Strategy**: Define validation approach

**Implementation Phase**:
1. **Job Configuration**:
   - Notebook tasks: Add to Git repository
   - Run job tasks: Reference existing job IDs
   - Parameters: Configure environment settings
   - Cluster: Use existing or create new cluster

2. **Workflow Updates**:
   - Add job to workflow YAML configuration
   - Define dependencies using `depends_on` section
   - Configure notifications and error handling

3. **Deployment Process**:
   - Test in development environment
   - Validate job execution with sample data
   - Deploy to production with monitoring
   - Document new job in operational guides

### Job Dependency Management
**Best Practices**:
- **Minimize Dependencies**: Reduce complexity where possible
- **Parallel Execution**: Enable parallel jobs where data allows
- **Error Isolation**: Prevent single job failures from cascading
- **Resource Balancing**: Distribute load across available resources

## Campaign Retirement Process

### Recent Campaign Archival: DI-1255 (September 2025)

**Archived Campaigns**:
- **GR Physical Mail**: Confirmed inactive by business stakeholders
  - Removed from BI-2482 campaign generation
  - Archived BI-2609 upload job sections
- **Recovery Monthly Email**: Confirmed inactive by business stakeholders
  - Removed from BI-2482 campaign generation
  - Retired BI-2108 job to `retired_jobs/`

**Process Followed**:
1. **Business Validation**: Confirmed with Collections team that campaigns were inactive
2. **Impact Analysis**: Verified no active dependencies or downstream systems
3. **Code Modification**:
   - Removed campaign generation logic
   - Removed associated suppression queries
   - Updated history table references
   - Preserved all active campaigns and critical suppression logic
4. **Documentation**: Updated all relevant documentation and job descriptions
5. **Testing**: Verified active campaigns continue to function normally

**Business Impact**:
- Reduced daily processing overhead
- Eliminated 3 unnecessary suppression queries
- Cleaner outbound lists data
- Improved code maintainability

### Standard Retirement Process

**For future campaign retirements**:
1. **Business Confirmation**: Verify with stakeholders that campaign is truly inactive
2. **Dependency Analysis**: Check for downstream jobs and systems
3. **Code Changes**: Remove generation/suppression logic, preserve active functionality
4. **Job Retirement**: Move entire jobs to `retired_jobs/` if fully dependent on archived campaign
5. **Documentation**: Update all relevant guides and documentation
6. **Monitoring**: Verify no errors from removed references

## Quarterly Review Process

### Suppression Rules Review
**Schedule**: Quarterly (every 3 months)
**Focus Areas**:
- **Regulatory Updates**: New state or federal regulations
- **Business Policy Changes**: Updated contact preferences
- **Effectiveness Analysis**: Review suppression rule performance
- **Optimization Opportunities**: Identify improvements

### Campaign Configuration Review
**Schedule**: Quarterly
**Activities**:
- **Active Campaign Validation**: Confirm all active campaigns still needed
- **Inactive Campaign Cleanup**: Archive unused campaigns
- **Performance Analysis**: Review campaign effectiveness
- **Partner Requirements**: Confirm ongoing suppression needs

### Process Efficiency Review
**Schedule**: Quarterly
**Areas**:
- **Automation Opportunities**: Identify manual processes to automate
- **Failure Point Analysis**: Review common failure scenarios
- **Performance Optimization**: Identify bottlenecks and improvements
- **Documentation Updates**: Update guides and procedures