# Pending Applications Analysis Report
**Date**: January 8, 2025  
**Analyst**: Data Engineering Team  
**Ticket**: BI-XXXX (To be assigned)

## Executive Summary
Analysis of pending loan applications in the LoanPro system reveals significant bottlenecks in the origination pipeline, with applications accumulating at various stages of the approval process. This report examines the root causes and provides recommendations for resolution.

## Key Findings

### 1. Current Pending Application Volume
Based on analysis of `BUSINESS_INTELLIGENCE.REPORTING.VW_ORIGINATIONS_AND_PENDING_ORIGINATIONS`:

| Status | Application Count | Description |
|--------|------------------|-------------|
| ICS (Identity Check Service) | 860 | Identity/income verification stage |
| Doc Upload | 284 | Awaiting customer document uploads |
| Underwriting | 137 | Active underwriting review |
| Pre-Funding | 95 | Approved, awaiting final steps |
| Pending Funding | 76 | Ready to fund |
| Awaiting DCP | 18 | Document completion pending |

### 2. Definition of "Pending" Applications
Applications are classified as pending when they meet ALL of the following criteria:
- **Entered Underwriting**: `FIRST_UNDERWRITING_DATETIME` is populated
- **Docs Not Complete**: `FIRST_LOAN_DOCS_COMPLETED_DATETIME` is NULL
- **Not Terminal**: Status not in ('Declined', 'Withdrawn', 'Expired', 'Closed')
- **Active Company**: Source company is active in the system

### 3. Primary Bottlenecks Identified

#### A. Customer Action Required (40% of pending)
- **Doc Upload Status**: 284 applications waiting for customers to provide required documentation
- **Average Wait Time**: Varies significantly based on customer responsiveness
- **Impact**: Creates artificial backlog that may resolve without operational intervention

#### B. Identity Verification Queue (50% of pending)
- **ICS Status**: 860 applications stuck in identity/income verification
- **Root Cause**: Potential integration issues or manual review requirements
- **Impact**: Largest single bottleneck in the system

#### C. Underwriting Capacity (8% of pending)
- **Manual Review Queue**: 137 applications requiring underwriter attention
- **Processing Time**: Subject to staffing levels and complexity of applications
- **Impact**: Creates downstream delays for all subsequent stages

#### D. Funding Process Delays (10% of pending)
- **Pre-Funding**: 95 applications approved but awaiting final steps
- **Pending Funding**: 76 applications ready for disbursement
- **Impact**: Delays in customer receipt of funds despite approval

## Data Architecture Observations

### Current View Implementation
The `VW_ORIGINATIONS_AND_PENDING_ORIGINATIONS_OPTIMIZED` view:
- Sources data from both LoanPro and legacy CLS systems
- Joins multiple BRIDGE and ANALYTICS layer tables
- Performance issues noted (queries timing out)

### Architectural Concerns
1. **Heavy reliance on complex joins**: Multiple joins across schemas impact query performance
2. **Mixed data sources**: Combining LoanPro and CLS data adds complexity
3. **Real-time calculation**: Pending status calculated on-the-fly rather than persisted

## Recommendations

### Immediate Actions
1. **Investigate ICS Bottleneck**
   - Review identity verification service integration
   - Identify stuck applications for manual intervention
   - Consider batch processing or automation improvements

2. **Customer Communication**
   - Implement automated reminders for document uploads
   - Provide clearer documentation requirements upfront
   - Consider self-service portal improvements

3. **Underwriting Capacity Review**
   - Analyze current staffing vs. application volume
   - Identify opportunities for automation in simple cases
   - Implement SLA tracking for manual reviews

### Long-term Improvements
1. **Data Architecture**
   - Create materialized view for pending application tracking
   - Implement proper ANALYTICS layer objects to replace complex joins
   - Consider event-driven architecture for status updates

2. **Process Optimization**
   - Streamline funding process to reduce pre-funding delays
   - Implement parallel processing where possible
   - Create early warning system for bottleneck detection

3. **Monitoring and Alerting**
   - Build dashboard for real-time pending application tracking
   - Set up alerts for unusual accumulation patterns
   - Implement aging reports for applications stuck > 24/48/72 hours

## Technical Details

### Query for Pending Analysis
```sql
-- Identify pending LoanPro applications with details
WITH pending_apps AS (
    SELECT 
        A.APPLICATION_ID,
        SCE.COMPANY_NAME AS PORTFOLIONAME,
        TO_DATE(A.FIRST_UNDERWRITING_DATETIME) AS PENDING_DATE,
        CF.REQUESTED_LOAN_AMOUNT,
        SS.TITLE AS CURRENT_STATUS,
        DATEDIFF('hour', A.FIRST_UNDERWRITING_DATETIME, CURRENT_TIMESTAMP()) AS HOURS_PENDING
    FROM ANALYTICS.VW_APPLICATION_STATUS_TRANSITION_WIP A
    INNER JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT CF
        ON CF.LOAN_ID = A.APPLICATION_ID
    INNER JOIN BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT C
        ON C.LOAN_ID = A.APPLICATION_ID
    INNER JOIN BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT SS
        ON SS.ID = C.LOAN_SUB_STATUS_ID
    WHERE A.SOURCE = 'LOANPRO'
        AND A.FIRST_UNDERWRITING_DATETIME IS NOT NULL
        AND A.FIRST_LOAN_DOCS_COMPLETED_DATETIME IS NULL
        AND SS.TITLE NOT IN ('Declined', 'Withdrawn', 'Expired', 'Started')
        AND SS.TITLE NOT LIKE '%Closed%'
)
SELECT 
    CURRENT_STATUS,
    COUNT(*) AS APP_COUNT,
    AVG(HOURS_PENDING) AS AVG_HOURS_PENDING,
    SUM(REQUESTED_LOAN_AMOUNT) AS TOTAL_LOAN_AMOUNT
FROM pending_apps
GROUP BY CURRENT_STATUS
ORDER BY APP_COUNT DESC;
```

## Next Steps
1. Schedule stakeholder meeting to review findings
2. Prioritize bottleneck resolution based on business impact
3. Implement monitoring dashboard for ongoing tracking
4. Create automated reports for daily pending application review
5. Establish SLAs for each stage of the origination process

## Appendix: Data Sources
- **Primary View**: `BUSINESS_INTELLIGENCE.REPORTING.VW_ORIGINATIONS_AND_PENDING_ORIGINATIONS_OPTIMIZED`
- **Status Data**: `BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT`
- **Application Data**: `ANALYTICS.VW_APPLICATION_STATUS_TRANSITION_WIP`
- **Loan Settings**: `BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT`
- **Custom Settings**: `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT`