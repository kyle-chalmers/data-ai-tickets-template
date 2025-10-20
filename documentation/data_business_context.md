# Data Business Context

## Overview

This document contains business context and domain knowledge learned from ticket work. Each entry includes relevant data objects to help Claude understand how business concepts relate to actual data structures. New insights from tickets should be added here when they provide reusable business understanding.

## Loan Status Definitions

### Delinquent Loans
Loans that are 3-119 Days Past Due (DPD) and NOT charged off or paid in full.

- **Early Stage (3-30 DPD)**: Recently delinquent, highest recovery potential
- **Critical Stage (91-119 DPD)**: Near charge-off, intensive collection efforts

**Data Objects**: 
- `VW_LOAN_STATUS_ARCHIVE_CURRENT.DPD` (days past due calculation)
- `VW_LOAN_SUB_STATUS_ENTITY_CURRENT.LOAN_SUB_STATUS_TEXT` (status text)

**SQL Pattern**: 
```sql
WHERE DPD BETWEEN 3 AND 119 
AND STATUS NOT IN ('CHARGED_OFF', 'PAID_IN_FULL')
```

### Current Loans
0-2 Days Past Due, considered in good standing.

**Data Objects**: `VW_LOAN_STATUS_ARCHIVE_CURRENT.DPD`

### Charged Off Loans
Written off as uncollectible (typically 120+ DPD).

**Data Objects**: 
- `VW_LOAN_STATUS_ARCHIVE_CURRENT.LOAN_STATUS_TEXT = 'Charged-Off (120+)'`
- `VW_LOAN_SUB_STATUS_ENTITY_CURRENT.LOAN_SUB_STATUS_TEXT`

## Collections and Placements

### SIMM Placement
Third-party collections agency placement.

- **Coverage**: ~47% of delinquent loans
- **Available From**: May 2025 onwards

**Data Objects**:
- **Primary Source**: `RPT_OUTBOUND_LISTS_HIST` where `SET_NAME = 'SIMM'`
- **Join Key**: `LEAD_GUID`
- **Dashboard Views**: Roll rate dashboards with SIMM placement flags

**SQL Pattern**:
```sql
SELECT * FROM RPT_OUTBOUND_LISTS_HIST 
WHERE SET_NAME = 'SIMM'
AND PLACEMENT_DATE >= '2025-05-01'
```

## Roll Rate Analysis

Track loan movement between delinquency stages over time.

- **Roll Forward**: Loans becoming more delinquent
- **Roll Back**: Loans curing (becoming less delinquent)
- **Roll to Charge-off**: Loans reaching charge-off status

**Data Objects**:
- `VW_LOAN_STATUS_ARCHIVE_CURRENT` (point-in-time status snapshots)
- `RPT_OUTBOUND_LISTS_HIST` (SIMM placement tracking)
- Roll rate dashboard views (contain month-over-month transition logic)

## Fraud Analysis Best Practices

### Multi-Source Detection Approach
Use inclusive OR conditions across multiple fraud indicators for comprehensive detection.

**Data Objects**:
1. **Portfolio Assignment**: `VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS` where `CATEGORY = 'Fraud'`
2. **Investigation Results**: `VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT.FRAUD_INVESTIGATION_RESULTS`
3. **Status Text**: `VW_LOAN_SUB_STATUS_ENTITY_CURRENT.LOAN_SUB_STATUS_TEXT LIKE '%fraud%'`
4. **Application Tags**: `VW_APPL_TAGS` where `TAG_NAME = 'Confirmed Fraud'`
5. **Centralized View**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS`

**SQL Pattern**:
```sql
-- Use OR logic to capture any fraud indicator
WHERE portfolio_category = 'Fraud'
   OR fraud_investigation_results IS NOT NULL
   OR LOWER(loan_sub_status_text) LIKE '%fraud%'
   OR tag_name = 'Confirmed Fraud'
```

### Fraud Detection Exclusions
- **Deceased**: Handled separately, not included in fraud views
- **SCRA (Servicemembers Civil Relief Act)**: Military protection, not fraud

## Debt Sale Process

### Portfolio Selection Criteria
**Data Objects**:
- `VW_LOAN_STATUS_ARCHIVE_CURRENT` (loan status)
- `VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS` (portfolio assignments)
- Settlement tracking views

### Required Deliverables
1. **Marketing Goodbye Letters**: Customer notification requirements
2. **Credit Reporting Files**: Bureau reporting updates
3. **Bulk Upload Files**: loan_management_system placement updates

**Data Objects**:
- Customer PII views for contact information
- Payment history views for account details
- Portfolio assignment tables for selection

## Multi-Loan Customer Considerations

### PII Lookup Challenges
Customers with multiple loans require careful PayoffUID matching.

**Data Objects**:
- **Current PII**: `BUSINESS_INTELLIGENCE.ANALYTICS_PII` schema tables
- **Legacy PII**: `BUSINESS_INTELLIGENCE.PII` schema (outdated, avoid)
- **Lookup Tables**: `DT_LKP_EMAIL_TO_PAYOFFUID_MATCH`

**Best Practice**: Always use ANALYTICS_PII schema for current customer information.

## Application Analysis

### Fair Lending Classifications
Not all application starts are considered formal applications.

**Application Types**:
- **True Applications**: `APPLIED_COUNT >= 1` (include in Fair Lending)
- **Pricing Inquiries**: `NO_TIMES_IN_OFFER_SHOWN >= 1` (exclude)
- **Started Only**: No progression beyond start (exclude)

**Data Objects**:
- `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_APPL_STATUS_TRANSITION`
- Application funnel transition tables

## loan_management_system Platform Specifics

### Schema Filtering
Critical for avoiding duplicate data from multiple loan_management_system instances.

**Functions**:
- `arca.CONFIG.loan_management_system_SCHEMA()`: Returns current loan management schema
- `arca.CONFIG.LOS_SCHEMA()`: Returns current loan origination schema

**SQL Pattern**:
```sql
-- Always filter by appropriate schema
WHERE SCHEMA_NAME = arca.CONFIG.loan_management_system_SCHEMA()
```

### Identifier Strategy
- **LEAD_GUID**: Most reliable for joins and deduplication
- **LEGACY_LOAN_ID**: User-friendly for stakeholder communication
- **PAYOFFUID**: Application and loan linking

## Performance Optimization Patterns

### Query Optimization Techniques
- Eliminate unnecessary CTEs
- Push filters down to base queries
- Use appropriate indexes (LEAD_GUID, LOAN_ID)
- Apply date filters early in query execution

### Typical Performance Gains
- **Dashboard queries**: 40-60% improvement
- **Complex joins**: 50-70% improvement
- **Large dataset operations**: Use sampling for exploration

## Regulatory Compliance

### State-Specific Requirements
- **Massachusetts**: Small dollar loan reporting requirements
- **Fair Lending**: Application classification requirements
- **CFPB**: Consumer complaint tracking

**Data Objects**:
- State-specific customer address views
- Loan amount and rate tables
- Compliance tracking tables