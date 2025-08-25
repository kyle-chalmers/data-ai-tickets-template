# LOANPRO_APP_SYSTEM_NOTES Procedure Analysis

## Current Architecture Issues

**Current Location:** `BUSINESS_INTELLIGENCE.CRON_STORE` (procedural storage layer)
**Target Architecture:** FRESHSNOW → BRIDGE → ANALYTICS flow

## Data Flow Analysis

### Source Data
- **Primary Source:** `RAW_DATA_STORE.LOANPRO.SYSTEM_NOTE_ENTITY`
- **Schema Filter:** `CONFIG.LOS_SCHEMA()` (LoanPro application schema)
- **Reference Type Filter:** `Entity.LoanSettings`

### Current Process
1. **Delete Operation:** Removes recent records from target table based on max date
2. **Staging Table:** Creates `loanpro_system_note` temp table with parsed JSON data
3. **Complex JSON Parsing:** Extracts loan status changes, portfolio changes, agent changes
4. **Lookup Enrichment:** Joins with multiple reference tables for human-readable values
5. **Final Insert:** Populates `system_note_entity` with enriched data

### Key Business Logic
- **Status Tracking:** Captures loan status and sub-status changes
- **Portfolio Management:** Tracks portfolio additions/removals
- **Agent Assignments:** Records agent changes
- **Source Company:** Tracks source company assignments
- **JSON Parsing:** Complex parsing of nested JSON structures for old/new values

## Architectural Recommendations

### FRESHSNOW Layer (Raw Processing)
Create view that handles the initial JSON parsing and data extraction:
- Parse system note JSON data
- Apply schema filtering
- Convert timezones
- Extract old/new values from nested JSON

### BRIDGE Layer (Clean Abstraction)
Create view that adds lookup enrichments:
- Join with loan status reference tables
- Join with portfolio reference tables
- Join with source company references
- Standardize data types and formats

### ANALYTICS Layer (Business Ready)
Create view optimized for business analysis:
- Final business logic transformations
- Calculated fields for reporting
- Optimized for common query patterns

## Implementation Benefits
1. **Eliminates Procedural Complexity:** Replaces stored procedure with declarative SQL views
2. **Improves Performance:** Views can be optimized and cached
3. **Enhances Maintainability:** SQL views are easier to modify than stored procedures
4. **Enables Real-time Access:** No need for ETL scheduling
5. **Follows Architecture Standards:** Aligns with 5-layer architecture pattern