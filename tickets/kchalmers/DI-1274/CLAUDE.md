# DI-1274: VW_LOAN_FRAUD Technical Implementation Context

## Overview
VW_LOAN_FRAUD is a consolidated fraud data view that serves as the single source of truth for all fraud-related loan data across Happy Money's LoanPro system. This view combines fraud indicators from three disparate sources into a unified dataset with comprehensive data quality tracking.

## Technical Architecture

### Data Sources Integration
**Source 1: Custom Fields (VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT)**
- Primary fraud investigation fields: `FRAUD_INVESTIGATION_RESULTS`, `FRAUD_CONFIRMED_DATE`
- Contact and process fields: `FRAUD_NOTIFICATION_RECEIVED`, `FRAUD_CONTACT_EMAIL`, `EOS_CARD_DISPUTE_CODE`
- Coverage: 411 of 504 fraud loans (81.5%)
- Note: `FOLLOW_UP_INFORMATION` excluded as it contains generic "Information Received" text inflating population

**Source 2: Portfolios (VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS)**
- Fraud portfolio categories: "First Party Fraud - Confirmed", "Fraud - Declined", "Identity Theft Fraud - Confirmed", "Fraud - Pending Investigation"
- Aggregation strategy: LISTAGG for multiple portfolio assignments per loan
- Workflow progression detection: Flags loans moving from "declined" to "confirmed" status
- Coverage: 356 of 504 fraud loans (70.6%)

**Source 3: Sub-Status (VW_LOAN_SETTINGS_ENTITY_CURRENT + VW_LOAN_SUB_STATUS_ENTITY_CURRENT)**
- Fraud sub-statuses: "Fraud Rejected", "Closed - Confirmed Fraud", "Open - Fraud Process"
- **CRITICAL**: LMS_SCHEMA() filtering applied to exclude 19K+ loans from different schema
- Coverage: 17 of 504 fraud loans (3.4%)

### Data Quality Framework

**Source Completeness Tracking**:
- `HAS_FRAUD_CUSTOM_FIELDS`, `HAS_FRAUD_PORTFOLIO`, `HAS_FRAUD_SUB_STATUS`: Boolean flags for source presence
- `FRAUD_DATA_SOURCE_COUNT`: Count of sources (1-3) providing data for each loan
- `FRAUD_DATA_COMPLETENESS_FLAG`: COMPLETE (3 sources), PARTIAL (2 sources), SINGLE_SOURCE (1 source)
- `FRAUD_DATA_SOURCE_LIST`: Comma-separated list of contributing sources

**Business Logic Validation**:
- `FRAUD_WORKFLOW_PROGRESSION_FLAG`: Detects loans with both "declined" and "confirmed" portfolios
- `FRAUD_DETERMINATION_CONFLICT_FLAG`: Flags conflicting fraud determinations between sources

### Schema Filtering Implementation

**Critical Schema Filtering**:
```sql
-- Sub-status source requires explicit LMS_SCHEMA filtering
WHERE lse.SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
  AND ss.SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
```

**Impact**: Without schema filtering, sub-status source would include 19,007 additional loans from schema `5203309_P` vs. only 17 loans from target schema `5203131_P`.

### Performance and Architecture

**Data Grain**: One row per LOAN_ID achieved through:
- UNION of all fraud loan IDs from three sources
- LEFT JOINs to source-specific aggregated CTEs
- Portfolio aggregation using LISTAGG and COUNT functions

**5-Layer Architecture Compliance**:
- Target layer: ANALYTICS (business-ready consolidated data)
- Source dependencies: BRIDGE layer views and ANALYTICS layer portfolios
- Deployment: FRESHSNOW → ANALYTICS pattern with COPY GRANTS

## Implementation Discoveries

### Data Quality Insights
1. **Generic FOLLOW_UP_INFORMATION**: Field contains 12K+ records with generic "Information Received" text, excluded from fraud criteria
2. **Workflow Progression**: 14 loans show progression from "Fraud - Declined" to confirmed status, indicating investigation maturation
3. **Source Conflicts**: 7 loans have conflicting fraud determinations requiring manual review
4. **Schema Impact**: LMS_SCHEMA filtering reduces sub-status population from 19K+ to 17 loans

### Business Logic Patterns
- Portfolio assignments can be multiple per loan (workflow progression)
- Custom fields provide most comprehensive fraud coverage
- Sub-status data is minimal but critical for current state tracking
- LEAD_GUID coverage is 99.8% (501 of 504 loans)

## Quality Control Results

**All Primary Tests PASSED**:
- ✅ Duplicate Detection: 0 duplicates (504 records = 504 unique loans)
- ✅ Data Grain: One row per LOAN_ID achieved
- ✅ Schema Filtering: Correctly applied, excluding non-target schema data
- ✅ Source Integration: All three sources properly joined and aggregated
- ✅ Performance: View executes efficiently with expected result set size

**Data Quality Flags Working**:
- ✅ Source completeness tracking operational
- ✅ Workflow progression detection functional
- ✅ Conflict flagging identifies 7 loans requiring review

## Deployment Architecture

**Development Environment**: `BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD`
**Production Path**: Use `2_production_deployment_template.sql` with environment variables
**Dependencies**: All source views validated and accessible
**Permissions**: COPY GRANTS preserves existing access controls

## Future Maintenance Notes

1. **Monitor Schema Filtering**: LMS_SCHEMA() configuration changes could affect sub-status population
2. **Portfolio Evolution**: New fraud portfolio types may require view updates
3. **Custom Field Changes**: Additional fraud-related custom fields should be evaluated for inclusion
4. **Conflict Resolution**: 7 flagged conflicts may need business rule clarification
5. **Performance**: Monitor execution time as fraud loan population grows

## Related Tickets
- **Epic**: DI-1238 (Data Intelligence infrastructure)
- **Downstream**: DI-1246, DI-1235 (dependent requirements)
- **Reference Model**: VW_LOAN_DEBT_SETTLEMENT (multi-source consolidation pattern)

This implementation provides a robust, scalable foundation for fraud data consolidation with comprehensive quality tracking and conflict detection capabilities.