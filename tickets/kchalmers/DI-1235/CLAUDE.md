# CLAUDE Context: VW_LOAN_DEBT_SETTLEMENT Enhancement (DI-1235)

## Technical Overview

This ticket enhanced the existing debt settlement view by integrating settlement action history, expanding from 4 to 6 data sources (5 active, 1 placeholder).

## Object Details

### Target Object
- **Name**: `VW_LOAN_DEBT_SETTLEMENT`
- **Schema**: `BUSINESS_INTELLIGENCE.ANALYTICS`
- **Type**: VIEW
- **Grain**: One row per loan with any debt settlement indicator
- **Architecture Layer**: ANALYTICS (references BRIDGE and ANALYTICS sources)

### Development Object
- **Schema**: `BUSINESS_INTELLIGENCE_DEV.ANALYTICS`
- **Columns**: 39 total (6 new ACTIONS columns)
- **Tested Volume**: 14,187 unique loans

## Data Sources (6-Source Architecture)

### Source 1: CUSTOM_FIELDS (Existing - Unchanged)
```sql
BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
-- Filters: Settlement custom field population indicators
-- ~14,060 loans
```

### Source 2: PORTFOLIOS (Existing - Unchanged)
```sql
BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
-- Filter: PORTFOLIO_CATEGORY = 'Settlement'
-- Aggregated: LISTAGG portfolios, MAX dates, COUNT
-- ~1,102 loans
```

### Source 3: SUB_STATUS (Existing - Unchanged)
```sql
BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT + VW_LOAN_SUB_STATUS_ENTITY_CURRENT
-- Filter: LOAN_SUB_STATUS_ID = '57' (Closed - Settled in Full)
-- Schema filter: LMS_SCHEMA()
-- ~63,560 loans
```

### Source 4: DOCUMENTS (Existing - Unchanged)
```sql
BUSINESS_INTELLIGENCE.ANALYTICS.LOAN_DOCUMENTS
-- Filter: SECTION_TITLE = 'Settlements'
-- Aggregated: Latest document, COUNT, LISTAGG filenames
-- Volume: TBD
```

### Source 5: ACTIONS (NEW - DI-1235) ✅
```sql
BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS
-- Filter: RESULT_TEXT = 'Settlement Payment Plan Set up'
-- Aggregation: MIN/MAX dates, COUNT, MAX_BY for latest details
-- Many:1 Relationship: 876 unique loans, 921 total actions (45 loans with 2+ actions)
```

**ACTIONS CTE Structure**:
```sql
ACTIONS AS (
    SELECT
        LOAN_ID::VARCHAR,
        MIN(ACTION_RESULT_TS) as EARLIEST_SETTLEMENT_ACTION_DATE,
        MAX(ACTION_RESULT_TS) as LATEST_SETTLEMENT_ACTION_DATE,
        COUNT(*) as SETTLEMENT_ACTION_COUNT,
        MAX_BY(AGENT_NAME, ACTION_RESULT_TS) as LATEST_SETTLEMENT_ACTION_AGENT,
        MAX_BY(NOTE, ACTION_RESULT_TS) as LATEST_SETTLEMENT_ACTION_NOTE,
        'ACTIONS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS
    WHERE RESULT_TEXT = 'Settlement Payment Plan Set up'
    GROUP BY LOAN_ID
)
```

### Source 6: CHECKLIST_ITEMS (NEW - DI-1235, Placeholder) ⚠️
```sql
-- COMMENTED OUT - Awaiting data population in VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT
-- Current Status: 0 records
-- When activated: Will add settlement checklist tracking fields
```

## Implementation Details

### CTE Flow
1. **PORTFOLIOS** - Portfolio aggregation
2. **CUSTOM_FIELDS** - Custom field indicators
3. **SUB_STATUS** - Loan sub status filtering
4. **DOCUMENTS** - Document aggregation
5. **ACTIONS** - Action history aggregation (NEW)
6. **CHECKLIST_ITEMS** - Commented placeholder (NEW)
7. **settlement_loans** - UNION of all sources (includes ACTIONS, CHECKLIST commented)
8. **Final SELECT** - Left joins with all CTEs

### Settlement Population Union
```sql
settlement_loans AS (
    SELECT LOAN_ID FROM CUSTOM_FIELDS
    UNION SELECT LOAN_ID FROM PORTFOLIOS
    UNION SELECT LOAN_ID FROM SUB_STATUS WHERE LOAN_SUB_STATUS_ID = '57'
    UNION SELECT LOAN_ID FROM DOCUMENTS
    UNION SELECT LOAN_ID FROM ACTIONS  -- NEW
    -- UNION SELECT LOAN_ID FROM CHECKLIST_ITEMS  -- Placeholder
)
```

### New Columns (After LATEST_SETTLEMENT_DOCUMENT_UPDATE_DATE)
```sql
act.EARLIEST_SETTLEMENT_ACTION_DATE,
act.LATEST_SETTLEMENT_ACTION_DATE,
act.SETTLEMENT_ACTION_COUNT,
act.LATEST_SETTLEMENT_ACTION_AGENT,
act.LATEST_SETTLEMENT_ACTION_NOTE,
-- Checklist columns commented out (placeholder)
```

### Data Source Tracking Updates

**Updated Calculation**:
```sql
DATA_SOURCE_COUNT = (
    CASE WHEN cls.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN d.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN 1 ELSE 0 END +
    CASE WHEN act.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END  -- NEW
    -- + CASE WHEN chk.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END  -- Placeholder
)

-- Range: 1-5 (will be 1-6 when CHECKLIST active)
```

**Updated Completeness Flag**:
```sql
DATA_COMPLETENESS_FLAG = CASE
    WHEN DATA_SOURCE_COUNT >= 5 THEN 'COMPLETE'  -- 5-6 sources
    WHEN DATA_SOURCE_COUNT >= 2 THEN 'PARTIAL'    -- 2-4 sources
    ELSE 'SINGLE_SOURCE'                          -- 1 source
END
```

**New Boolean Flags**:
- `HAS_SETTLEMENT_ACTION` - TRUE for 876 loans
- `HAS_SETTLEMENT_CHECKLIST` - Commented placeholder

**Updated DATA_SOURCE_LIST**:
- Now includes 'ACTIONS' when `act.LOAN_ID IS NOT NULL`
- CHECKLIST_ITEMS source commented out

## QC Validation Summary

### Critical Validations ✅
- **No Duplicates**: One row per LOAN_ID confirmed
- **ACTIONS Integrity**: 876 source loans = 876 view loans with HAS_SETTLEMENT_ACTION
- **Field Population**: 100% of ACTIONS fields populated for flagged loans
- **Date Logic**: All EARLIEST_SETTLEMENT_ACTION_DATE <= LATEST_SETTLEMENT_ACTION_DATE
- **Backward Compatibility**: All 33 existing columns preserved unchanged
- **Join Accuracy**: Zero unmatched ACTIONS loans

### Volume Analysis
- **Production**: 14,183 loans
- **Development**: 14,187 loans (+4 new loans from ACTIONS source)
- **ACTIONS Coverage**: 876 loans (872 existing + 4 new)

### Data Distribution
- **5 Sources (COMPLETE)**: 112 loans (0.79%)
- **2-4 Sources (PARTIAL)**: 1,460 loans (10.29%)
- **1 Source (SINGLE_SOURCE)**: 12,615 loans (88.92%)

## Backward Compatibility

### Preserved Elements
- All 33 existing columns with identical logic
- All existing CTEs (PORTFOLIOS, CUSTOM_FIELDS, SUB_STATUS, DOCUMENTS) unchanged
- Column order: New columns added after existing document fields
- COPY GRANTS: Permissions preserved in deployment

### No Breaking Changes
- Existing queries continue to work
- Existing column values match production exactly (validated with sample comparison)
- New columns return NULL for loans without ACTIONS data

## Performance Considerations

- New ACTIONS CTE adds aggregation overhead (876 loans, 921 records)
- Overall view performance remains acceptable (validated in QC)
- No observed degradation in sample query execution

## Deployment Strategy

### Phase 1: Development (Completed)
```sql
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT COPY GRANTS AS ...
```

### Phase 2: Production (Ready for User Approval)
Use `3_production_deploy_template.sql` with variable-based deployment:
```sql
DECLARE
    v_de_db varchar default 'ARCA';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE';
BEGIN
    EXECUTE IMMEDIATE ('CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT COPY GRANTS AS ...');
END;
```

## CHECKLIST_ITEMS Activation Guide

When `VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT` has data:

1. Uncomment CHECKLIST_ITEMS CTE
2. Configure filter criteria (settlement-related checklist names/items)
3. Uncomment settlement_loans UNION for CHECKLIST_ITEMS
4. Uncomment LEFT JOIN CHECKLIST_ITEMS in final query
5. Uncomment checklist column selections
6. Uncomment HAS_SETTLEMENT_CHECKLIST flag
7. Uncomment checklist term in DATA_SOURCE_COUNT calculation
8. Update DATA_SOURCE_LIST array to include chk.SOURCE

## Known Issues & Limitations

### Current State
- CHECKLIST_ITEMS source has 0 records (data population issue being resolved)
- LATEST_SETTLEMENT_ACTION_NOTE may contain very long HTML content (no truncation)
- ACTION_TEXT is always 'Charge Off' for settlement actions (constant value)

### Future Enhancements
- Activate CHECKLIST_ITEMS when data available
- Consider NOTE field truncation if performance impacts observed
- Potential additional settlement action result types

## Related Documentation

- **Original Ticket**: DI-1262 (initial VW_LOAN_DEBT_SETTLEMENT creation)
- **PRP**: `/PRPs/debt_settlement_object_update/snowflake-data-object-vw-loan-debt-settlement-update.md`
- **Architecture**: 5-layer Snowflake architecture (ANALYTICS layer)
- **Data Business Context**: `documentation/data_business_context.md`

## Key Technical Patterns

### Many:1 Aggregation Pattern
- Used for ACTIONS source (some loans have multiple settlement action records)
- Strategy: MIN for earliest, MAX for latest, COUNT for total, MAX_BY for latest details
- Pattern reusable for CHECKLIST_ITEMS when activated

### 6-Source Architecture Pattern
- Expandable union-based population (settlement_loans CTE)
- Left joins preserve all sources with NULL handling
- Boolean flags + count + list for comprehensive tracking
- Completeness categorization based on source count thresholds

### Placeholder Implementation Pattern
- Commented CTE with example structure
- Commented UNION, LEFT JOIN, column selections
- Clear activation instructions in comments
- Future-ready without impacting current functionality

## File References

### Deliverables
- `final_deliverables/1_vw_loan_debt_settlement_enhanced.sql` - View DDL
- `final_deliverables/2_qc_validation_results.csv` - QC results
- `final_deliverables/3_production_deploy_template.sql` - Deployment script
- `qc_validation.sql` - Comprehensive QC queries

### Source Materials
- `/PRPs/debt_settlement_object_update/data-object-initial.md` - Original requirements
- `/PRPs/debt_settlement_object_update/snowflake-data-object-vw-loan-debt-settlement-update.md` - Complete PRP

---
*Last Updated: DI-1235 Implementation (October 2025)*
*AI Context File - Complete technical reference for future modifications*
