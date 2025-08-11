# Job: Pending Applications Analysis
**Ticket**: BI-XXXX (To be assigned)  
**Purpose**: Analyze and monitor pending loan applications in the origination pipeline  
**Schedule**: Ad-hoc analysis / Daily monitoring  
**Business Owner**: Loan Operations Team  

## Data Sources
- Primary: `BUSINESS_INTELLIGENCE.REPORTING.VW_ORIGINATIONS_AND_PENDING_ORIGINATIONS_OPTIMIZED`
- Dependencies: 
  - `ANALYTICS.VW_APPLICATION_STATUS_TRANSITION_WIP`
  - `BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT`
  - `BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT`
  - `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT`

## External Integrations
- None (Internal analysis only)

## Business Logic
### Pending Application Definition
Applications are considered "pending" when:
1. They have entered underwriting (`FIRST_UNDERWRITING_DATETIME` is not null)
2. Loan documents are not completed (`FIRST_LOAN_DOCS_COMPLETED_DATETIME` is null)
3. Status is not terminal (not in 'Declined', 'Withdrawn', 'Expired', 'Closed')
4. Source is LoanPro system (excluding legacy CLS applications)

### Key Status Categories
- **ICS**: Identity Check Service - identity/income verification
- **Doc Upload**: Awaiting customer document uploads
- **Underwriting**: Manual underwriting review
- **Pre-Funding**: Approved, awaiting final steps
- **Pending Funding**: Ready for disbursement
- **Awaiting DCP**: Document completion pending

## Known Issues
### Performance Concerns
- Complex view with multiple joins causes query timeouts
- Real-time calculation of pending status impacts performance
- Heavy reliance on `VW_ORIGINATIONS_AND_PENDING_ORIGINATIONS` views

### Data Architecture Issues
- View combines LoanPro and legacy CLS data, adding complexity
- Pending status calculated on-the-fly rather than persisted
- Multiple schema dependencies (ANALYTICS, BRIDGE, REPORTING)

### Business Process Issues
- Identity verification (ICS) represents 50% of bottleneck
- Document upload delays due to customer response time
- Manual underwriting capacity constraints
- Funding process delays despite approval

## Analysis Outputs
### Documents Generated
1. **pending_applications_analysis.md**: Comprehensive analysis of current pending state
2. **august_7_2025_analysis.md**: Deep dive into specific date pattern (44 applications)
3. **claude.md**: This documentation file

### Key Metrics Tracked
- Total pending applications by status
- Average time in pending state
- Conversion rates from pending to funded
- Daily accumulation patterns
- Risk tier distribution

## Recommendations Summary
### Immediate Actions
1. Investigate ICS (Identity Check Service) bottleneck - largest source of delays
2. Implement automated customer reminders for document uploads
3. Review underwriting capacity vs. application volume

### Long-term Improvements
1. Create materialized view for pending application tracking
2. Implement event-driven architecture for status updates
3. Build real-time monitoring dashboard
4. Establish SLAs for each origination stage

## SQL Queries for Analysis
```sql
-- Current pending applications by status
SELECT 
    SS.TITLE AS STATUS,
    COUNT(DISTINCT C.LOAN_ID) AS COUNT
FROM BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT C
INNER JOIN BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT SS
    ON SS.ID = C.LOAN_SUB_STATUS_ID
WHERE SS.TITLE IN ('ICS', 'Doc Upload', 'Underwriting', 
                   'Pre-Funding', 'Pending Funding', 'Awaiting DCP')
GROUP BY SS.TITLE
ORDER BY COUNT DESC;

-- Aging analysis of pending applications
SELECT 
    CASE 
        WHEN HOURS_PENDING <= 24 THEN '0-24 hours'
        WHEN HOURS_PENDING <= 48 THEN '24-48 hours'
        WHEN HOURS_PENDING <= 72 THEN '48-72 hours'
        ELSE '72+ hours'
    END AS AGE_BUCKET,
    COUNT(*) AS APPLICATION_COUNT
FROM (
    SELECT 
        APPLICATION_ID,
        DATEDIFF('hour', FIRST_UNDERWRITING_DATETIME, CURRENT_TIMESTAMP()) AS HOURS_PENDING
    FROM ANALYTICS.VW_APPLICATION_STATUS_TRANSITION_WIP
    WHERE SOURCE = 'LOANPRO'
        AND FIRST_UNDERWRITING_DATETIME IS NOT NULL
        AND FIRST_LOAN_DOCS_COMPLETED_DATETIME IS NULL
)
GROUP BY AGE_BUCKET
ORDER BY AGE_BUCKET;
```

## Monitoring and Alerting
### Proposed Alerts
- Pending applications > 100 (daily check)
- Average pending time > 48 hours (hourly check)
- ICS queue > 500 applications (real-time)
- Conversion rate < 60% (weekly trend)

### Dashboard Requirements
- Real-time pending count by status
- Trend analysis (7-day, 30-day)
- Conversion funnel visualization
- Bottleneck identification heat map
- SLA compliance tracking

## Related Jobs
- `BI-2482_Outbound_List_Generation_for_GR/`: Uses origination data for marketing
- `DI-926_Rearrange_Application_Flow_ETL_Architecture/`: Application flow ETL
- Various affiliate reporting jobs that track origination metrics

## Future Enhancements
1. Machine learning model for predicting processing time
2. Automated bottleneck detection and alerting
3. Dynamic resource allocation based on queue depth
4. Customer self-service portal improvements
5. API integration for real-time verification services