# DI-1179: Fraud-Only Analytics Table

## Overview

This ticket creates a centralized **FRAUD-ONLY** analytics view in the ANALYTICS layer that consolidates fraud detection data sources, eliminating the need for complex ad-hoc queries when analyzing fraud indicators across our loan portfolio. **This view excludes deceased and SCRA data** to focus specifically on fraud detection.

## Business Impact

**Before**: Fraud analysis required running multiple complex queries across various data sources including portfolio assignments, investigation results, application tags, and status text, creating inefficiency and potential for missing fraud indicators.

**After**: Single comprehensive view provides all fraud indicators with standardized logic, improving performance and ensuring consistency across all fraud analysis use cases.

## Data Sources Consolidated

The new view consolidates **ACTIVE LOAN FRAUD DETECTION ONLY** from 4 primary sources (excludes LOS application data):

1. **Portfolio Assignments** (`VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS`)
   - Category: 'Fraud' only
   - Portfolio names like 'Fraud - Confirmed', 'Identity Theft'

2. **LMS Investigation Results** (`VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT`)
   - Active loan fraud investigations only
   - Fields: `FRAUD_INVESTIGATION_RESULTS`

3. **Application Tag-Based Detection** (`VW_APPL_TAGS`) 
   - Tag: 'Confirmed Fraud' (applied to loans through CLS)

4. **Status Text Indicators** (`VW_LOAN_SUB_STATUS_ENTITY_CURRENT`)
   - Pattern matching for fraud-related status text

## Technical Implementation

### Architecture

The solution follows the standard 3-layer deployment pattern:

```
FRESHSNOW (Core logic) → BRIDGE (Pass-through) → ANALYTICS (Consumer view)
```

### Schema Structure

```sql
VW_FRAUD_COMPREHENSIVE_ANALYTICS(
    -- Identifiers
    LOAN_ID, LEAD_GUID, LEGACY_LOAN_ID,
    
    -- Master fraud indicator (boolean)
    IS_FRAUD_ANY,
    
    -- Portfolio-based indicators  
    IS_FRAUD_PORTFOLIO, FRAUD_PORTFOLIO_NAMES, FRAUD_PORTFOLIO_FIRST_DATE,
    
    -- Investigation-based indicators
    IS_FRAUD_INVESTIGATION_LMS, FRAUD_STATUS_LMS, FRAUD_REASON_LMS,
    IS_FRAUD_INVESTIGATION_LOS, FRAUD_STATUS_LOS, FRAUD_REASON_LOS,
    
    -- Application tag indicators
    IS_FRAUD_APPLICATION_TAG, FRAUD_APPLICATION_TAG_DATE,
    
    -- Status text indicators
    IS_FRAUD_STATUS_TEXT, FRAUD_STATUS_TEXT,
    
    -- Aggregated indicators
    FRAUD_DETECTION_METHODS_COUNT, FRAUD_FIRST_DETECTED_DATE, FRAUD_SOURCES_LIST,
    
    -- Metadata
    LAST_UPDATED, RECORD_CREATED_DATE
)
```

### Performance Optimizations

- **Pre-filtered CTEs**: Each data source CTE includes appropriate filtering
- **Efficient joins**: Uses LEAD_GUID as primary join key for reliability
- **Selective output**: Only includes loans with at least one fraud indicator
- **One row per loan**: Ensures clean data structure with unique loan records
- **Array functions**: Efficient fraud source list aggregation using ARRAY_CONSTRUCT

## Deliverables

### Core SQL Files

1. **`1_fraud_comprehensive_analytics_view.sql`**
   - Main view definition with fraud-only detection logic
   - Comprehensive CTEs for each fraud data source
   - Optimized for development environment testing
   - **One row per loan** structure

2. **`2_deployment_script_fraud_analytics.sql`**
   - Multi-environment deployment using standardized template
   - Supports both development and production deployment
   - Includes COPY GRANTS to preserve permissions
   - **Fraud detection only** (no deceased/SCRA)

3. **`3_sample_usage_queries.sql`**
   - Demonstrates common fraud analysis patterns
   - Shows performance improvements over old approaches
   - Examples for debt sale exclusions, fraud portfolio analysis, etc.
   - **Updated to focus on fraud-only use cases**

### Quality Control

4. **`qc_queries/1_fraud_view_validation.sql`**
   - Comprehensive fraud-only validation queries
   - Compares against existing DI-1141 fraud portfolio logic
   - Performance and data quality checks
   - Cross-layer validation (FRESHSNOW → BRIDGE → ANALYTICS)

## Usage Examples

### Simple Fraud Lookup (Replaces Complex Queries)

```sql
-- OLD WAY: Complex multi-table joins
-- NEW WAY: Simple fraud-only lookup
SELECT loan_id, legacy_loan_id, IS_FRAUD_ANY, FRAUD_SOURCES_LIST
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE IS_FRAUD_ANY = TRUE;
```

### Debt Sale Fraud Exclusions

```sql
SELECT vl.loan_id, vl.legacy_loan_id,
       CASE WHEN fca.IS_FRAUD_ANY THEN 'EXCLUDE - Fraud Detected'
            ELSE 'INCLUDE' END as debt_sale_status,
       fca.FRAUD_SOURCES_LIST,
       fca.FRAUD_PORTFOLIO_NAMES
FROM VW_LOAN vl
LEFT JOIN VW_FRAUD_COMPREHENSIVE_ANALYTICS fca
    ON LOWER(vl.lead_guid) = LOWER(fca.LEAD_GUID)
WHERE vl.loan_status = 'Charge off';
```

### Multi-Source Fraud Analysis

```sql
SELECT loan_id, FRAUD_DETECTION_METHODS_COUNT, FRAUD_SOURCES_LIST
FROM VW_FRAUD_COMPREHENSIVE_ANALYTICS
WHERE FRAUD_DETECTION_METHODS_COUNT >= 2
ORDER BY FRAUD_DETECTION_METHODS_COUNT DESC;
```

## Testing and Validation

### Pre-Deployment Testing

1. **Logic Validation**: QC queries compare new view against DI-1141 fraud portfolio patterns
2. **Performance Testing**: Ensure sub-second response times for common fraud queries
3. **Coverage Validation**: Verify all known fraud cases are captured across all 5 data sources
4. **Cross-Layer Testing**: Confirm data consistency across FRESHSNOW → BRIDGE → ANALYTICS
5. **One-Row-Per-Loan Validation**: Ensure no duplicate loan records in output

### Success Metrics

- ✅ **Functional**: All existing fraud detection queries can be replaced with single table lookups
- ✅ **Performance**: Sub-second response times for fraud indicator queries  
- ✅ **Completeness**: 100% coverage of loans identified by current fraud detection methods
- ✅ **Usability**: Business users can easily query fraud status without complex joins
- ✅ **Data Structure**: One row per loan with no duplicates

## Deployment Instructions

### Development Environment (Default)

```sql
-- Execute deployment script as-is
@2_deployment_script_fraud_analytics.sql
```

### Production Environment

```sql
-- 1. Edit deployment script: uncomment prod database variables
-- 2. Comment out dev database variables  
-- 3. Execute deployment script
@2_deployment_script_fraud_analytics.sql
```

### Post-Deployment Validation

```sql
-- Run all QC queries to validate deployment
@qc_queries/1_fraud_view_validation.sql
```

## Integration with Existing Workflows

### Debt Sale Operations (DI-1141 Pattern)
- Replace complex fraud exclusion logic with simple IS_FRAUD_ANY lookup
- Use FRAUD_SOURCES_LIST for detailed exclusion reasoning
- Leverage FRAUD_FIRST_DETECTED_DATE for timeline analysis
- **Focus on fraud exclusions only** (deceased/SCRA handled separately)

### Fraud Portfolio Analysis (DI-934 Pattern)  
- Replace individual portfolio queries with comprehensive fraud breakdown
- Use FRAUD_DETECTION_METHODS_COUNT for risk scoring
- Leverage aggregated indicators for fraud reporting
- **Enhanced with multi-source fraud detection**

### GIACT Analysis (DI-1140 Pattern)
- Combine with investigation results for comprehensive fraud view
- Cross-reference application tags with portfolio assignments
- Use for BMO bank fraud ring type analysis
- **Improved fraud detection accuracy with multiple data sources**

## Future Enhancements

1. **Automated Refresh**: Consider implementing as materialized view for improved performance
2. **Historical Tracking**: Add audit trail for fraud indicator changes over time
3. **Risk Scoring**: Incorporate weighted risk scores based on detection method reliability
4. **Alert Integration**: Connect with monitoring systems for new fraud detection
5. **Additional Data Sources**: Expand to include new fraud detection methods as they become available

## Related Tickets

- **DI-1141**: Debt sale fraud exclusion logic (source pattern)
- **DI-1140**: GIACT fraud analysis and BMO bank fraud ring detection
- **DI-934**: Comprehensive fraud portfolio analysis (baseline validation)

## Support and Maintenance

For questions or issues with the fraud-only analytics view:
1. Review sample usage queries for common fraud analysis patterns
2. Run QC validation queries to diagnose issues
3. Check FRAUD_SOURCES_LIST field for debugging specific detection logic
4. Reference original source queries in related tickets for context
5. Verify one-row-per-loan structure is maintained after any modifications