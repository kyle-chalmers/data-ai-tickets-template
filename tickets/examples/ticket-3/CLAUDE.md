# CLAUDE.md - ticket-3 Technical Implementation Guide

## Project Summary
**ticket-3: Enhanced VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT with 185 Missing CUSTOM_FIELD_VALUES**

Enhanced view from 278 fields to 463 fields (67% increase) by adding missing CUSTOM_FIELD_VALUES fields. Comprehensive null analysis performed showing business value concentrated in loan modifications (7.35% usage), analytics (9.66% HAPPY_SCORE usage), and fraud investigation (0.33% active cases).

## Critical Technical Requirements

### Schema Filtering (MANDATORY)
```sql
WHERE cs.schema_name = ARCA.CONFIG.loan_management_system_SCHEMA()
  AND le.schema_name = ARCA.CONFIG.loan_management_system_SCHEMA()
```
**ALL fields MUST use this filter** - ensures loan_management_system data only, prevents duplicate records from multiple instances.

### Data Type Casting Patterns
```sql
-- Date fields
TRY_CAST(CUSTOM_FIELD_VALUES:FIELDNAME::VARCHAR AS DATE) AS FIELD_NAME

-- Numeric fields
TRY_CAST(CUSTOM_FIELD_VALUES:FIELDNAME::VARCHAR AS NUMERIC(30,2)) AS FIELD_NAME

-- Text fields
CUSTOM_FIELD_VALUES:FIELDNAME::VARCHAR AS FIELD_NAME

-- Special case (numeric field names)
CUSTOM_FIELD_VALUES:"10DAYPAYOFF"::VARCHAR AS TEN_DAY_PAYOFF
```

### 5-Layer Architecture Deployment
**Environment Variables in deployment script:**
```sql
-- Dev (default)
v_de_db varchar default 'DEVELOPMENT';
v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';

-- Prod (uncomment for production)
-- v_de_db varchar default 'ARCA';
-- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
```

**Deployment sequence**: FRESHSNOW → BRIDGE → ANALYTICS
- FRESHSNOW: Enhanced view definition
- BRIDGE: `SELECT * FROM FRESHSNOW`
- ANALYTICS: `SELECT * FROM BRIDGE`

## Implementation Insights from Null Analysis

### Business Priority Fields (Active Usage)
- **HAPPY_SCORE**: 9.66% population - highest adoption
- **Loan Modification fields**: 7.35% avg - active business process
- **BANKRUPTCY_CHAPTER**: 5.05% population - aligns with existing bankruptcy usage
- **Fraud Investigation**: 0.33% avg - targeted but active usage

### Completely Unused Fields (0% population)
- **Attorney Enhancement** (6 fields): All null - future capability
- **System Integration** (3 fields): All null - legacy/future features
- **REPOSSESSION_COMPANY_NAME** (existing): 100% null - recommend removal

### Quality Control Validation
Key QC queries in `qc_queries/`:
1. **Field count validation**: Ensure 463 fields in all layers
2. **Schema filtering verification**: Confirm loan_management_system-only data
3. **New field accessibility**: Test all 185 new fields accessible
4. **Population analysis**: Monitor adoption of high-value fields

## Common SQL Patterns

### Enhanced View Structure
```sql
SELECT
    -- === EXISTING 278 FIELDS (exact production order) ===
    le.id AS LOAN_ID,
    cs.entity_id AS SETTINGS_ID,
    TRY_CAST(CUSTOM_FIELD_VALUES:PROCESSINGFEESPAID::VARCHAR AS NUMERIC(30,2)) AS PROCESSING_FEES_PAID,
    -- ... all existing fields ...

    -- === NEW FIELDS (185) - GROUPED BY CATEGORY ===
    -- Fraud Investigation (42 fields)
    CUSTOM_FIELD_VALUES:FRAUDJIRATICKET1::VARCHAR AS FRAUD_JIRA_TICKET_1,
    -- Loan Modifications (25 fields)
    TRY_CAST(CUSTOM_FIELD_VALUES:LOANMODEFFECTIVEDATE::VARCHAR AS DATE) AS LOAN_MOD_EFFECTIVE_DATE,
    -- ... etc by category ...

FROM ARCA.FRESHSNOW.TRANSFORMED_CUSTOM_FIELD_ENTITY_CURRENT cs
INNER JOIN ARCA.FRESHSNOW.LOAN_ENTITY_CURRENT le ON (cs.entity_id = le.settings_id)
WHERE cs.entity_type = 'Entity.LoanSettings'
  AND cs.schema_name = ARCA.CONFIG.loan_management_system_SCHEMA()
  AND le.schema_name = ARCA.CONFIG.loan_management_system_SCHEMA()
```

## Troubleshooting Common Issues

### Schema Filter Problems
- **Issue**: Non-loan_management_system schema records appearing
- **Solution**: Verify `ARCA.CONFIG.loan_management_system_SCHEMA()` function exists and filtering applied

### Data Type Casting Errors
- **Issue**: TRY_CAST failures
- **Solution**: Check field naming (some require quotes like "10DAYPAYOFF")

### Performance Issues
- **Issue**: Slow query execution
- **Solution**: Monitor with 67% more fields; consider indexing if needed

### Missing Field Data
- **Issue**: New fields return NULL
- **Solution**: Verify field exists in CUSTOM_FIELD_VALUES JSON structure

## Field Categories and Business Value

| Category | Count | Usage Rate | Priority | Examples |
|----------|-------|------------|----------|----------|
| Loan Modifications | 25 | 7.35% | HIGH | LOAN_MOD_EFFECTIVE_DATE |
| Analytics | 12 | 9.66% (HAPPY_SCORE) | HIGH | HAPPY_SCORE, LATEST_BUREAU_SCORE |
| Fraud Investigation | 42 | 0.33% | MEDIUM | FRAUD_JIRA_TICKET_1 |
| Bankruptcy Enhancement | 2 | 5.05% | HIGH | BANKRUPTCY_CHAPTER |
| Legal & Compliance | 30 | 0.20% | LOW | DCA_START_DATE |
| Attorney Enhancement | 6 | 0.00% | FUTURE | ATTORNEY_ORGANIZATION |
| System Integration | 15 | 0.00% | FUTURE | CLS_CLEARING_DATE |

## Deployment Checklist

### Pre-Deployment
- [ ] Backup current view: `SELECT GET_DDL('VIEW', 'ARCA.FRESHSNOW.VW_loan_management_system_CUSTOM_LOAN_SETTINGS_CURRENT')`
- [ ] Verify schema function: `SELECT ARCA.CONFIG.loan_management_system_SCHEMA()`
- [ ] Check permissions: COPY GRANTS across layers

### Deployment
- [ ] Test in DEV first with development environment variables
- [ ] Switch to production variables for PROD deployment
- [ ] Deploy FRESHSNOW → BRIDGE → ANALYTICS sequence

### Post-Deployment
- [ ] Run QC queries: Validate 463 field count
- [ ] Performance check: Monitor query execution time
- [ ] Business validation: Test key analytics use cases
- [ ] Monitor adoption: Track population of high-value fields

## Performance Considerations
- **67% more fields** but 100+ completely null (no performance impact)
- **TRY_CAST error handling** prevents query failures
- **Existing joins unchanged** maintains current performance baseline
- **Monitor initial deployment** for any execution time changes

---

**Key Point**: This enhancement provides complete CUSTOM_FIELD_VALUES access while maintaining backward compatibility and performance through proper schema filtering and error handling.