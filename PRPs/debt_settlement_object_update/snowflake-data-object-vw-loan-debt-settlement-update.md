# Snowflake Data Object PRP: VW_LOAN_DEBT_SETTLEMENT Enhancement

## Operation Summary
- **Operation Type**: ALTER_EXISTING
- **Scope**: SINGLE_OBJECT
- **Jira Ticket**: DI-1235 (Enhancement to VW_LOAN_DEBT_SETTLEMENT)
- **Expected Ticket Folder**: `tickets/kchalmers/DI-1235/`
- **Related Tickets**: DI-1262 (original creation), DI-1246

## Business Context

### Business Purpose
Enhance the existing `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT` view by integrating two additional settlement data sources to provide more comprehensive debt settlement tracking and improve data quality visibility.

### Primary Use Cases
- **Enhanced Debt Sale Suppression**: More complete settlement identification for debt sale exclusions
- **Comprehensive Settlement Analysis**: Full visibility across all settlement data sources
- **Data Quality Investigation**: Identify gaps and inconsistencies across expanded source set
- **Settlement Action Tracking**: Historical timeline of settlement setup activities

### Key Metrics/KPIs
- Count of active debt settlements by source (expanded from 4 to 6 sources)
- Settlement action timeline and agent tracking
- Data completeness across all settlement tracking sources
- Settlement configuration and approval workflow visibility

## Data Architecture Design

### Current State
- **Object Name**: `VW_LOAN_DEBT_SETTLEMENT`
- **Current Schema**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT`
- **Object Type**: VIEW
- **Current Data Grain**: One row per loan with any debt settlement indicator
- **Current Volume**: 14,183 unique loans
- **Current Sources**: 4 (CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS, DOCUMENTS)

### Target State
- **Same Object Name**: `VW_LOAN_DEBT_SETTLEMENT`
- **Same Schema**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT`
- **Object Type**: VIEW (unchanged)
- **Data Grain**: One row per loan (unchanged)
- **Expected Volume**: ~15,000+ unique loans (6% increase)
- **Updated Sources**: 6 (adding ACTIONS and CHECKLIST_ITEMS)

### Architecture Compliance
- **Layer Placement**: ANALYTICS layer ✅
- **Source Layer Compliance**: References BRIDGE and ANALYTICS layers only ✅
- **Backward Compatibility**: MAINTAIN - All existing columns and logic preserved
- **Deployment Strategy**: Development first (BUSINESS_INTELLIGENCE_DEV), then production after validation

## Current Object Analysis

### Existing DDL Structure
```sql
-- Current View: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
-- 4 CTEs: PORTFOLIOS, CUSTOM_FIELDS, SUB_STATUS, DOCUMENTS
-- Settlement population union: Custom Fields + Portfolios + Sub Status + Documents
-- Main query: Left joins from settlement_loans to all source CTEs
-- Data tracking: 4-source system with HAS_* flags and DATA_SOURCE_LIST
```

**Current Columns (preserved)**:
- Loan identifiers: LOAN_ID, LEAD_GUID
- Settlement status: SETTLEMENTSTATUS, CURRENT_STATUS
- Financial fields: SETTLEMENT_AMOUNT, SETTLEMENT_AMOUNT_PAID, etc.
- Company info: SETTLEMENT_COMPANY (consolidated from two fields)
- Dates: Multiple settlement date fields
- Portfolio info: SETTLEMENT_PORTFOLIOS, portfolio dates, counts
- Document info: SETTLEMENT_DOCUMENTS, counts, latest document
- Data source flags: HAS_CUSTOM_FIELDS, HAS_SETTLEMENT_PORTFOLIO, HAS_SETTLEMENT_DOCUMENT, HAS_SETTLEMENT_SUB_STATUS
- Tracking: DATA_SOURCE_COUNT (1-4), DATA_COMPLETENESS_FLAG, DATA_SOURCE_LIST

## New Source Analysis

### Source 5: Settlement Actions (VW_LOAN_ACTION_AND_RESULTS) ✅

**Source Details**:
```sql
-- Source: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS
-- Filter: RESULT_TEXT = 'Settlement Payment Plan Set up'
-- Volume: 876 unique loans, 921 total action records
-- Many:1 Relationship: Some loans have multiple settlement action records (45 loans with 2+ actions)
-- Join Key: LOAN_ID
```

**Schema Structure**:
- `LOAN_ID` - Loan identifier
- `ACTION_RESULT_TS` - Timestamp of action
- `AGENT_ID` - Agent who performed action
- `AGENT_NAME` - Agent name
- `ACTION_TEXT` - Always 'Charge Off' for settlement actions
- `RESULT_TEXT` - Always 'Settlement Payment Plan Set up' for settlements
- `NOTE` - Rich text containing settlement details (amounts, terms, dates)

**Sample Data**:
```
LOAN_ID: 96793
ACTION_RESULT_TS: 2025-01-22 10:58:17
AGENT_NAME: [Agent Name]
RESULT_TEXT: Settlement Payment Plan Set up
NOTE: "Accepted a settlement offer in the amount of $2722.11 to be paid in 6 payments..."
```

**Fields to Add (Aggregated from Multiple Actions)**:
- `EARLIEST_SETTLEMENT_ACTION_DATE` - First settlement action timestamp
- `LATEST_SETTLEMENT_ACTION_DATE` - Most recent settlement action timestamp
- `SETTLEMENT_ACTION_COUNT` - Total number of settlement actions per loan
- `LATEST_SETTLEMENT_ACTION_AGENT` - Agent name from most recent action
- `LATEST_SETTLEMENT_ACTION_NOTE` - NOTE field from most recent action (may be lengthy)

**Aggregation Strategy**:
```sql
-- Handle many:1 relationship with aggregation
ACTIONS AS (
    SELECT
        LOAN_ID,
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

### Source 6: Checklist Items (VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT) ⚠️

**Current Status**:
- Table currently has **0 records** in production
- Data issue being resolved by user
- PRP includes placeholder structure for future integration

**Source Details**:
```sql
-- Source: BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT
-- Filter: TBD - Settlement-related checklist items (to be determined when data available)
-- Volume: 0 records currently (awaiting data fix)
-- Expected Relationship: Potentially many:1 (multiple checklist items per loan)
-- Join Key: LOAN_ID
```

**Schema Structure**:
- `LOAN_ID` - Loan identifier
- `CHECKLIST_ID` - Checklist identifier
- `CHECKLIST_ITEM_ID` - Item identifier
- `CHECKLIST_NAME` - Name of checklist
- `CHECKLIST_ITEM_NAME` - Name of checklist item
- `CHECKLIST_ITEM_VALUE` - Item value (0/1 boolean)
- `CHECKLIST_ITEM_ORDER` - Display order
- `STATUS_CATALOG_ID` - Status reference
- `LASTUPDATED` - Last update timestamp
- `UNIQUE_CHECKLIST_ID` - Unique identifier

**Placeholder Implementation**:
```sql
-- PLACEHOLDER: Checklist items source (awaiting data population)
-- UNCOMMENT AND CONFIGURE WHEN DATA BECOMES AVAILABLE
/*
, CHECKLIST_ITEMS AS (
    SELECT
        LOAN_ID,
        -- TBD: Aggregation strategy for checklist items
        -- Example fields (adjust based on actual settlement checklist structure):
        -- COUNT(DISTINCT CHECKLIST_ID) as SETTLEMENT_CHECKLIST_COUNT,
        -- LISTAGG(DISTINCT CHECKLIST_NAME, '; ') as SETTLEMENT_CHECKLISTS,
        -- MAX(LASTUPDATED) as LATEST_CHECKLIST_UPDATE,
        'CHECKLIST_ITEMS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT
    WHERE CHECKLIST_NAME ILIKE '%settlement%' -- TBD: Adjust filter criteria
       OR CHECKLIST_ITEM_NAME ILIKE '%settlement%'
    GROUP BY LOAN_ID
)
*/
```

**Fields to Add (Placeholder - Commented Out)**:
- `SETTLEMENT_CHECKLIST_COUNT` - Number of settlement-related checklists (TBD)
- `SETTLEMENT_CHECKLISTS` - List of checklist names (TBD)
- `LATEST_CHECKLIST_UPDATE` - Most recent checklist update date (TBD)

**Note**: Implementation will require user guidance on:
1. Specific checklist names/items that indicate settlements
2. Aggregation strategy for multiple checklist items per loan
3. Which checklist fields are most valuable for settlement analysis

## Enhanced Data Source Tracking

### Updated Tracking Logic (4 → 6 Sources)

**Current Tracking (4 sources)**:
- DATA_SOURCE_COUNT: Range 1-4
- DATA_SOURCE_LIST: Combinations of CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS, DOCUMENTS
- DATA_COMPLETENESS_FLAG: COMPLETE (4), PARTIAL (2-3), SINGLE_SOURCE (1)

**New Tracking (6 sources)**:
- DATA_SOURCE_COUNT: Range 1-6 (initially 1-5 until checklist data available)
- DATA_SOURCE_LIST: Add ACTIONS (and CHECKLIST_ITEMS when available)
- DATA_COMPLETENESS_FLAG:
  - COMPLETE: 6 sources (or 5 without checklist)
  - PARTIAL: 2-4 sources
  - SINGLE_SOURCE: 1 source

**New Boolean Flags**:
- `HAS_SETTLEMENT_ACTION` - Boolean for actions source presence
- `HAS_SETTLEMENT_CHECKLIST` - Boolean for checklist source presence (placeholder)

**Updated Calculation Logic**:
```sql
-- Enhanced data source counting (6 sources)
COALESCE(
    CASE WHEN cls.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN d.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN 1 ELSE 0 END +
    CASE WHEN act.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    -- CASE WHEN chk.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END + -- Uncomment when checklist data available
    0
) as DATA_SOURCE_COUNT

-- Updated completeness flag
CASE
    WHEN DATA_SOURCE_COUNT >= 5 THEN 'COMPLETE'  -- 5-6 sources (6 when checklist active)
    WHEN DATA_SOURCE_COUNT >= 2 THEN 'PARTIAL'    -- 2-4 sources
    ELSE 'SINGLE_SOURCE'                          -- 1 source
END as DATA_COMPLETENESS_FLAG
```

## Implementation Blueprint

### Multi-Source Enhancement Strategy

**CTE Structure (Expanding from 4 to 6 CTEs)**:

1. **PORTFOLIOS** - Settlement portfolio aggregation (EXISTING - unchanged)
2. **CUSTOM_FIELDS** - Custom loan settings with settlement indicators (EXISTING - unchanged)
3. **SUB_STATUS** - Settlement-related loan sub statuses (EXISTING - unchanged)
4. **DOCUMENTS** - Settlement document tracking (EXISTING - unchanged)
5. **ACTIONS** - Settlement action history aggregation (NEW - fully specified)
6. **CHECKLIST_ITEMS** - Settlement checklist tracking (NEW - placeholder/commented)
7. **settlement_loans** - UNION of all sources (UPDATED - add ACTIONS, placeholder for CHECKLIST)
8. **Final SELECT** - Left joins to combine all data sources (UPDATED - add new fields)

### Settlement Population Union (Updated)

**Current Logic**:
```sql
settlement_loans AS (
    SELECT LOAN_ID FROM CUSTOM_FIELDS
    UNION
    SELECT LOAN_ID FROM PORTFOLIOS
    UNION
    SELECT LOAN_ID FROM SUB_STATUS WHERE LOAN_SUB_STATUS_ID = '57'
    UNION
    SELECT LOAN_ID FROM DOCUMENTS
)
```

**Enhanced Logic**:
```sql
settlement_loans AS (
    SELECT LOAN_ID FROM CUSTOM_FIELDS
    UNION
    SELECT LOAN_ID FROM PORTFOLIOS
    UNION
    SELECT LOAN_ID FROM SUB_STATUS WHERE LOAN_SUB_STATUS_ID = '57'
    UNION
    SELECT LOAN_ID FROM DOCUMENTS
    UNION
    SELECT LOAN_ID FROM ACTIONS  -- NEW
    -- UNION
    -- SELECT LOAN_ID FROM CHECKLIST_ITEMS  -- Uncomment when data available
)
```

### Column Additions

**New Columns to Add (After LATEST_SETTLEMENT_DOCUMENT_UPDATE_DATE)**:
```sql
-- Settlement Action Information (from ACTIONS CTE)
act.EARLIEST_SETTLEMENT_ACTION_DATE,
act.LATEST_SETTLEMENT_ACTION_DATE,
act.SETTLEMENT_ACTION_COUNT,
act.LATEST_SETTLEMENT_ACTION_AGENT,
act.LATEST_SETTLEMENT_ACTION_NOTE,

-- Settlement Checklist Information (PLACEHOLDER - commented out)
-- chk.SETTLEMENT_CHECKLIST_COUNT,
-- chk.SETTLEMENT_CHECKLISTS,
-- chk.LATEST_CHECKLIST_UPDATE,
```

**Updated Data Source Flags (After existing HAS_* flags)**:
```sql
-- New source flags
CASE WHEN act.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_ACTION,
-- CASE WHEN chk.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_SETTLEMENT_CHECKLIST, -- Uncomment when available
```

### Left Join Additions

**Add to Final Query (After DOCUMENTS join)**:
```sql
-- Settlement actions
LEFT JOIN ACTIONS act
    ON sl.LOAN_ID = act.LOAN_ID

-- Settlement checklist items (PLACEHOLDER - commented out)
-- LEFT JOIN CHECKLIST_ITEMS chk
--     ON sl.LOAN_ID = chk.LOAN_ID
```

## Development Environment Setup

### Phase 1: Development Deployment
```bash
# Deploy to development environment first
snow sql -q "$(cat final_deliverables/1_vw_loan_debt_settlement_enhanced.sql)" --format csv

# Verify development deployment
snow sql -q "DESCRIBE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv
```

### Phase 2: Comprehensive QC Validation
```bash
# Run all QC tests from single consolidated file
snow sql -q "$(cat final_deliverables/qc_validation.sql)" --format csv
```

### Phase 3: Production Deployment (After User Review)
```bash
# Deploy to production using deployment template
# snow sql -q "$(cat final_deliverables/2_production_deploy_template.sql)"
```

## Quality Control Plan

### Single Consolidated QC File: `qc_validation.sql`

**QC Test Categories**:

**1. Source Data Validation**
```sql
-- Validate new ACTIONS source
-- Record count: 876 unique loans, 921 total actions
-- Many:1 verification: Loans with multiple actions
-- Filter validation: RESULT_TEXT = 'Settlement Payment Plan Set up'

-- Placeholder for CHECKLIST_ITEMS source (when available)
-- Current record count: 0 (awaiting data fix)
```

**2. Before/After Comparison**
```sql
-- Production baseline: 14,183 loans
-- Development enhanced: Expected ~15,000+ loans (6% increase)
-- New loan additions: ~800-900 loans from ACTIONS source
-- Overlap analysis: Existing loans gaining ACTIONS data
```

**3. Join Integrity Testing**
```sql
-- Verify ACTIONS left join integrity
-- Check for unmatched LOAN_IDs
-- Validate aggregation accuracy (MIN, MAX, COUNT, MAX_BY)
-- Confirm no duplicate loan records in final output
```

**4. Data Source Tracking Validation**
```sql
-- Verify DATA_SOURCE_COUNT ranges 1-5 (or 1-6 when checklist active)
-- Validate HAS_SETTLEMENT_ACTION flag accuracy
-- Check DATA_SOURCE_LIST includes 'ACTIONS' appropriately
-- Confirm DATA_COMPLETENESS_FLAG logic with 6-source thresholds
```

**5. New Column Population Analysis**
```sql
-- EARLIEST_SETTLEMENT_ACTION_DATE <= LATEST_SETTLEMENT_ACTION_DATE
-- SETTLEMENT_ACTION_COUNT matches distinct action records
-- LATEST_SETTLEMENT_ACTION_AGENT populated for all action loans
-- NOTE field length analysis (may be very long HTML content)
```

**6. Backward Compatibility Check**
```sql
-- All existing columns present and unchanged
-- Existing column values match production view
-- No changes to CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS, DOCUMENTS logic
-- LEAD_GUID join still accurate
```

**7. Performance Validation**
```sql
-- Query execution time measurement (target: as fast as possible)
-- Compare dev vs prod execution times
-- Analyze impact of new ACTIONS aggregation CTE
```

**8. Duplicate Detection**
```sql
-- Confirm one row per LOAN_ID (no duplicates)
-- Validate settlement_loans UNION integrity
-- Check for data quality issues in new sources
```

## Critical Implementation Requirements

### EXPLICIT VALIDATION REQUIREMENT
**⚠️ CRITICAL**: Implementer must perform independent data exploration and validation before following PRP guidance. Do not blindly follow this PRP - validate each step independently with sample queries and data verification.

### Data Source Integration Rules
1. **Preserve ALL existing logic** - No changes to CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS, DOCUMENTS CTEs
2. **Add ACTIONS source** - Fully specified aggregation logic with many:1 handling
3. **Placeholder CHECKLIST_ITEMS** - Commented implementation awaiting data population
4. **Maintain backward compatibility** - All existing columns and values unchanged
5. **Extend tracking system** - Update from 4-source to 6-source tracking logic

### Consolidation Logic
- **Union Approach**: Add ACTIONS to settlement_loans union (CHECKLIST placeholder)
- **Left Join Strategy**: Add ACTIONS left join (CHECKLIST placeholder)
- **Aggregation Handling**: Use MIN/MAX/COUNT/MAX_BY for many:1 ACTIONS relationship
- **NULL Preservation**: Maintain NULL values for loans without ACTIONS/CHECKLIST data

### Backward Compatibility Requirements
- **All existing columns**: Preserved with identical logic
- **All existing values**: Must match production view exactly
- **All existing sources**: CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS, DOCUMENTS unchanged
- **Column order**: Add new columns after existing document fields

## File Organization Requirements

### Expected Deliverable Structure
```
tickets/kchalmers/DI-1235/
├── README.md                                    # Complete documentation with assumptions
├── final_deliverables/                          # Numbered for review order
│   ├── 1_vw_loan_debt_settlement_enhanced.sql  # Enhanced view DDL
│   ├── 2_production_deploy_template.sql        # Multi-environment deployment
│   └── qc_validation.sql                       # Single consolidated QC file
├── source_materials/                            # Research queries and analysis
│   ├── actions_source_exploration.sql          # ACTIONS data exploration
│   └── checklist_source_investigation.sql      # CHECKLIST investigation
└── exploratory_analysis/                        # Development and testing queries
```

### Additional Documentation Updates

**1. Update DI-1262 Ticket Documentation**:
```
tickets/kchalmers/DI-1262/
├── README.md                                    # Update with ACTIONS and DOCUMENTS sources
└── CLAUDE.md                                    # Update with current architecture (6 sources)
```

**2. DI-1262 README.md Update**:
- Document the evolution: Original creation (4 sources) → Documents added → ACTIONS + CHECKLIST added
- Update data source list: CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS, DOCUMENTS, ACTIONS, CHECKLIST_ITEMS
- Note checklist source is placeholder pending data availability

**3. DI-1262 CLAUDE.md Update**:
- Document the 6-source architecture pattern
- Explain many:1 aggregation strategy for ACTIONS
- Note placeholder approach for CHECKLIST_ITEMS

## Expected Impact Analysis

### Volume Changes
- **Current Production**: 14,183 unique loans
- **Expected After Enhancement**: ~15,000+ unique loans (6-7% increase)
- **New Loans from ACTIONS**: ~800-900 loans (876 unique in ACTIONS source)
- **New Loans from CHECKLIST**: TBD (currently 0 records)
- **Enriched Existing Loans**: Some of 14,183 existing loans will gain ACTIONS data

### Data Completeness Improvement
- **Before**: 4 sources maximum per loan
- **After**: 6 sources maximum per loan (5 until checklist available)
- **Expected Distribution**:
  - COMPLETE (5-6 sources): Low percentage (most comprehensive tracking)
  - PARTIAL (2-4 sources): Majority of loans
  - SINGLE_SOURCE (1 source): Data quality concern loans

### Business Impact
- **Enhanced Suppression**: More accurate debt sale exclusions with ACTIONS source
- **Workflow Visibility**: Settlement action timeline and agent tracking
- **Data Quality**: Better identification of incomplete settlement tracking
- **Historical Context**: Settlement setup action history provides audit trail

## Production Deployment Strategy

### Deployment Template Pattern
Following `documentation/db_deploy_template.sql` for multi-layer deployment:

```sql
DECLARE
    -- dev databases
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';

    -- prod databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';

BEGIN
    -- FRESHSNOW section (if needed for this view)
    -- BRIDGE section (if needed for this view)

    -- ANALYTICS section (primary deployment)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT
        COPY GRANTS AS
            [Enhanced View Definition with ACTIONS and CHECKLIST placeholders]
    ');
END;
```

### Deployment Checklist
- [ ] Development deployment successful
- [ ] QC validation passed (all tests green)
- [ ] Backward compatibility verified (existing columns match production)
- [ ] New ACTIONS fields populated correctly
- [ ] Data source tracking updated accurately (1-5 or 1-6 range)
- [ ] Performance acceptable (as fast as possible)
- [ ] User review completed
- [ ] Production deployment approved
- [ ] COPY GRANTS verified for permission preservation

## Validation Gates

### Pre-Deployment Validation
```bash
# Development environment object verification
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv

# Record count comparison
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv

# New source validation
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT WHERE HAS_SETTLEMENT_ACTION = TRUE" --format csv

# Comprehensive QC validation
snow sql -q "$(cat qc_validation.sql)" --format csv
```

### Post-Deployment Validation
```bash
# Production deployment verification
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv

# Sample new column verification
snow sql -q "SELECT LOAN_ID, LATEST_SETTLEMENT_ACTION_DATE, SETTLEMENT_ACTION_COUNT FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT WHERE HAS_SETTLEMENT_ACTION = TRUE LIMIT 10" --format csv

# Data source distribution
snow sql -q "SELECT DATA_SOURCE_COUNT, COUNT(*) as loan_count FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT GROUP BY DATA_SOURCE_COUNT ORDER BY DATA_SOURCE_COUNT" --format csv
```

## Database Object References

### Source Objects (Complete DDL Available)
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_ACTION_AND_RESULTS** - 876 settlement loans
  - Columns: LOAN_ID, ACTION_RESULT_TS, AGENT_ID, AGENT_NAME, ACTION_TEXT, RESULT_TEXT, NOTE
  - Filter: `RESULT_TEXT = 'Settlement Payment Plan Set up'`
  - Many:1 relationship (some loans have 2+ actions)

- **BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT** - 0 records (awaiting data)
  - Columns: LOAN_ID, CHECKLIST_ID, CHECKLIST_ITEM_ID, CHECKLIST_NAME, CHECKLIST_ITEM_NAME, CHECKLIST_ITEM_VALUE, CHECKLIST_ITEM_ORDER, STATUS_CATALOG_ID, LASTUPDATED, UNIQUE_CHECKLIST_ID
  - Filter: TBD (settlement-related checklists)
  - Relationship: TBD (potentially many:1)

### Current View Object
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT** - 14,183 loans
  - Complete DDL provided in initial requirements
  - 4 existing CTEs: PORTFOLIOS, CUSTOM_FIELDS, SUB_STATUS, DOCUMENTS
  - settlement_loans union approach
  - Data source tracking: HAS_* flags, DATA_SOURCE_COUNT, DATA_SOURCE_LIST

## Assumptions and Constraints

### Documented Assumptions
1. **ACTIONS Source Stability**: `RESULT_TEXT = 'Settlement Payment Plan Set up'` is the complete and accurate filter for settlement actions
2. **CHECKLIST Data Availability**: User will provide guidance when VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT is populated
3. **Backward Compatibility Priority**: All existing columns and values must remain identical
4. **Many:1 Aggregation**: Latest action details (MAX_BY) and earliest/latest dates (MIN/MAX) are appropriate aggregation strategy
5. **NOTE Field Length**: LATEST_SETTLEMENT_ACTION_NOTE may contain very long HTML content (no truncation specified)
6. **Data Source Count Threshold**: 5-6 sources = COMPLETE, 2-4 = PARTIAL, 1 = SINGLE_SOURCE is appropriate breakdown
7. **Production Data Freeze**: Current production view has 14,183 loans (baseline for comparison)

### Implementation Constraints
- **No Schema Changes**: ALTER_EXISTING view only, no table creation
- **COPY GRANTS Required**: Must preserve existing permissions
- **Development First**: Must deploy to BUSINESS_INTELLIGENCE_DEV before production
- **User Review Required**: Cannot deploy to production without user approval
- **Placeholder Management**: CHECKLIST_ITEMS must remain commented until user instructs activation

## Quality Gates Checklist

- [ ] All ACTIONS fields extracted and aggregated correctly
- [ ] CHECKLIST_ITEMS placeholder properly commented with clear activation instructions
- [ ] Settlement population union includes ACTIONS (CHECKLIST commented)
- [ ] Left joins added for ACTIONS (CHECKLIST commented)
- [ ] Data source tracking updated to 6-source system (5 active, 1 placeholder)
- [ ] New boolean flags: HAS_SETTLEMENT_ACTION (HAS_SETTLEMENT_CHECKLIST commented)
- [ ] DATA_SOURCE_COUNT logic updated to 1-6 range (currently 1-5)
- [ ] DATA_COMPLETENESS_FLAG thresholds updated for 6 sources
- [ ] All existing columns preserved unchanged
- [ ] Backward compatibility validated with production baseline
- [ ] QC validation comprehensive and executable
- [ ] DI-1262 documentation updated (README.md and CLAUDE.md)
- [ ] Development deployment successful
- [ ] Performance acceptable (as fast as possible)
- [ ] User review completed before production deployment

## Expected Outcomes

### Business Impact
- **More Comprehensive Settlement Tracking**: 6-source integration (5 active immediately)
- **Enhanced Debt Sale Accuracy**: Better suppression with ACTIONS source addition
- **Settlement Workflow Visibility**: Action timeline and agent tracking for operational insights
- **Future Extensibility**: Placeholder framework for CHECKLIST_ITEMS when data available

### Technical Deliverables
- **Enhanced Production View**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT` with 2 new sources
- **Expanded Data Coverage**: ~15,000+ loans with settlement indicators (6% increase)
- **Multi-Source Integration**: 6-source architecture with 5 active, 1 placeholder
- **Complete Documentation**: DI-1235 + DI-1262 documentation updates
- **Quality Control Framework**: Comprehensive before/after validation

### Documentation Updates
- **DI-1262 README.md**: Document data source evolution and current 6-source architecture
- **DI-1262 CLAUDE.md**: Explain implementation patterns and placeholder approach
- **DI-1235 README.md**: Complete project documentation with assumptions and QC results

## Confidence Assessment: 9/10

This PRP provides comprehensive database context with complete DDL for ACTIONS source, clear placeholder strategy for CHECKLIST_ITEMS source, detailed backward compatibility requirements, and executable validation steps. The ALTER_EXISTING approach maintains all existing functionality while cleanly integrating new settlement data sources.

**Success Criteria**: One-pass implementation with production-ready view enhancement that adds ACTIONS source immediately, preserves all existing functionality, and provides clear activation path for CHECKLIST_ITEMS source when data becomes available.

**Deduction Rationale**: -1 point for CHECKLIST_ITEMS uncertainty (awaiting data population and filter criteria), but comprehensive placeholder approach mitigates risk.
