# Dependency Analysis: LOANPRO_APP_SYSTEM_NOTES vs Existing APPL_HISTORY Objects

## Critical Discovery: Existing Architecture Overlap

The stored procedure `LOANPRO_APP_SYSTEM_NOTES` populates `BUSINESS_INTELLIGENCE.CRON_STORE.SYSTEM_NOTE_ENTITY`, but there are **existing objects** that process the same source data (`RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY`) with overlapping logic.

## Existing Architecture Found

### Current Data Flow
```
RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY
    ↓
ARCA.FRESHSNOW.APPL_HISTORY (Dynamic Table) 
    ↓
ARCA.FRESHSNOW.VW_APPL_HISTORY (View)
    ↓
BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_HISTORY (View - Deduplication)
    ↓
BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_HISTORY (View - Business Layer)
```

### Parallel Process (What We're Replacing)
```
RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY
    ↓
BUSINESS_INTELLIGENCE.CRON_STORE.LOANPRO_APP_SYSTEM_NOTES (Stored Procedure)
    ↓
BUSINESS_INTELLIGENCE.CRON_STORE.SYSTEM_NOTE_ENTITY (Table)
```

## Key Differences Identified

### 1. **Data Coverage**
- **APPL_HISTORY**: Excludes `'Loan settings were created'` records
- **SYSTEM_NOTE_ENTITY**: Includes `'Loan settings were created'` records
- **Impact**: SYSTEM_NOTE_ENTITY has broader data coverage for initial loan creation

### 2. **Schema Structure**
**APPL_HISTORY Schema:**
- ID, APPLICATION_ID, NOTE_TITLE, NOTE_DATA, REFERENCE_TYPE
- NEWVALUE, NEWVALUE_LABEL, OLDVALUE, OLDVALUE_LABEL
- NOTE_TITLE_DETAIL, CREATED, LASTUPDATED

**SYSTEM_NOTE_ENTITY Schema:**  
- APP_ID, CREATED_TS, LASTUPDATED_TS
- LOAN_STATUS_NEW, LOAN_STATUS_OLD  
- NOTE_NEW_VALUE, NOTE_OLD_VALUE
- DELETED_SUB_STATUS_NEW, DELETED_SUB_STATUS_OLD
- NOTE_TITLE_DETAIL

### 3. **Business Logic Differences**
- **APPL_HISTORY**: More comprehensive portfolio handling with categories
- **SYSTEM_NOTE_ENTITY**: Simpler portfolio logic without categories
- **APPL_HISTORY**: Custom field label integration
- **SYSTEM_NOTE_ENTITY**: Raw value processing only

## Downstream Dependencies

### BUSINESS_INTELLIGENCE.BRIDGE.VW_APPL_HISTORY
- **Purpose**: Deduplication layer removing repeated status changes
- **Logic**: Uses ROW_NUMBER() to remove duplicate old/new value pairs
- **Source**: `ARCA.FRESHSNOW.APPL_HISTORY`

### BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPL_HISTORY  
- **Purpose**: Unified application history from multiple sources
- **Sources**: Combines CLS history + LoanPro history
- **Filters**: Excludes loan status changes (only keeps non-status fields)
- **Schema**: Standardized columns across sources

## Risk Assessment

### HIGH RISK
1. **Downstream Dependencies**: ANALYTICS layer already exists and may be consumed by dashboards/reports
2. **Data Coverage Gap**: Excluding 'Loan settings were created' changes behavior significantly  
3. **Schema Incompatibility**: Different column structures require mapping strategy
4. **Business Logic Variance**: Portfolio categories and custom field labels differ

### MEDIUM RISK
1. **Performance Impact**: Dynamic table vs stored procedure refresh patterns
2. **Historical Data**: Transition period data consistency concerns

## Migration Strategy Framework

### Option 1: Enhance Existing Architecture (RECOMMENDED)
```
RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY
    ↓
ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES (New FRESHSNOW View)
    ↓  
ARCA.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES (Materialized Table)
    ↓
[Merge with existing APPL_HISTORY or create parallel path]
```

### Option 2: Replace Existing Architecture  
- Higher risk due to downstream dependencies
- Requires comprehensive testing of ANALYTICS layer consumers
- Need to verify all business logic compatibility

### Option 3: Parallel Implementation
- Run both architectures during transition period
- Validate data consistency between approaches
- Gradual migration of downstream consumers

## Testing Framework Requirements

### 1. **Data Validation Tests**
```sql
-- Record count comparison
SELECT 'Existing APPL_HISTORY' as source, COUNT(*) as records FROM ARCA.FRESHSNOW.APPL_HISTORY
UNION ALL
SELECT 'New Architecture' as source, COUNT(*) as records FROM DEVELOPMENT.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;

-- Coverage gap analysis ('Loan settings were created')
SELECT COUNT(*) as creation_records 
FROM RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY 
WHERE NOTE_TITLE = 'Loan settings were created' 
  AND SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
  AND REFERENCE_TYPE = 'Entity.LoanSettings';
```

### 2. **Business Logic Validation**
```sql
-- Portfolio handling comparison
-- Status change logic comparison  
-- Custom field processing comparison
```

### 3. **Downstream Impact Testing**
```sql
-- Test BRIDGE layer functionality
-- Validate ANALYTICS layer record counts
-- Check dashboard/report data consistency
```

## Materialization Strategy

Following the `VW_APP_OFFERS` → `APP_OFFERS` pattern:

### Phase 1: Create Views in 5-Layer Architecture
```sql
-- FRESHSNOW layer view
CREATE OR REPLACE VIEW ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES AS ...

-- BRIDGE layer view  
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.BRIDGE.VW_LOANPRO_APP_SYSTEM_NOTES AS ...

-- ANALYTICS layer view
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOANPRO_APP_SYSTEM_NOTES AS ...
```

### Phase 2: Materialize FRESHSNOW Table
```sql
-- Create materialized table using view → table pattern
CREATE OR REPLACE TABLE ARCA.FRESHSNOW.LOANPRO_APP_SYSTEM_NOTES COPY GRANTS AS
SELECT * FROM ARCA.FRESHSNOW.VW_LOANPRO_APP_SYSTEM_NOTES;
```

### Phase 3: Update BRIDGE/ANALYTICS to Reference Table
```sql
-- Update BRIDGE to reference materialized table instead of view
-- Update ANALYTICS to reference BRIDGE layer
```

## Recommendations

1. **START WITH PARALLEL IMPLEMENTATION** - Avoid disrupting existing dependencies
2. **COMPREHENSIVE TESTING** - Validate all business logic against existing objects
3. **SCHEMA MAPPING** - Create compatibility layer for downstream consumers  
4. **PHASED MIGRATION** - Gradual transition with validation at each step
5. **ROLLBACK PLAN** - Maintain ability to revert to stored procedure if needed