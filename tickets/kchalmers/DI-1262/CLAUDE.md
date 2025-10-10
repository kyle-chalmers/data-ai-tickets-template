# CLAUDE.md: LOAN_DEBT_SETTLEMENT Technical Context

## Data Object Overview
- **Object Name**: LOAN_DEBT_SETTLEMENT
- **Target**: BUSINESS_INTELLIGENCE.ANALYTICS (Dynamic Table preferred, View fallback)
- **Jira Ticket**: DI-1262 (linked to Epic DI-1238)
- **Data Grain**: One row per loan with any debt settlement indicator

## Source Data Architecture

### 1. Custom Loan Settings (Primary)
- **Source**: BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
- **Volume**: 14,066 loans with settlement indicators
- **Key Fields**: SETTLEMENTSTATUS, DEBT_SETTLEMENT_COMPANY, SETTLEMENT_AMOUNT, etc.
- **Join Key**: LOAN_ID

### 2. Settlement Portfolios (Secondary)
- **Source**: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
- **Filter**: PORTFOLIO_CATEGORY = 'Settlement'
- **Volume**: 1,047 loans
- **Portfolio Types**: Settlement Setup, Settlement Successful, Settlement Failed

### 3. Loan Sub Status (Tertiary)
- **Source**: VW_LOAN_STATUS_ARCHIVE_CURRENT + VW_LOAN_SUB_STATUS_ENTITY_CURRENT
- **Filter**: LOAN_SUB_STATUS_TEXT = 'Closed - Settled in Full'
- **Volume**: 458 distinct current loans
- **Schema Filter**: LMS_SCHEMA() applied

## Implementation Logic

### Multi-Source Consolidation Pattern
```sql
-- Following VW_LOAN_BANKRUPTCY pattern:
1. custom_settings_source - Primary settlement data
2. portfolio_source - Portfolio assignments (no overlap with custom)
3. sub_status_source - Sub status data (no overlap with others)
4. settlement_portfolios - LISTAGG aggregation
5. settlement_sub_status - Current status only
6. UNION ALL sources + LEFT JOIN aggregated data
```

### Data Source Tracking
- **HAS_CUSTOM_FIELDS**: Boolean flag
- **HAS_SETTLEMENT_PORTFOLIO**: Boolean flag
- **HAS_SETTLEMENT_SUB_STATUS**: Boolean flag
- **DATA_SOURCE_COUNT**: 1-3 (number of sources with data)
- **DATA_COMPLETENESS_FLAG**: 'COMPLETE', 'PARTIAL', 'SINGLE_SOURCE'
- **DATA_SOURCE_LIST**: Comma-separated source names

### Settlement Field Handling

**Included Fields** (population > 0%):
- SETTLEMENTSTATUS (7.24%)
- DEBT_SETTLEMENT_COMPANY (9.66%)
- SETTLEMENTCOMPANY (9.21%)
- SETTLEMENT_AMOUNT (0.78%)
- SETTLEMENT_AMOUNT_PAID (0.13%)
- SETTLEMENTAGREEMENTAMOUNT (6.60%)
- Financial and date fields with data

**Excluded Fields** (entirely NULL):
- SETTLEMENT_COMPANY_DCA
- SETTLEMENT_AGREEMENT_AMOUNT_DCA
- SETTLEMENT_END_DATE
- SETTLEMENT_SETUP_DATE
- THIRD_PARTY_COLLECTION_AGENCY
- UNPAID_SETTLEMENT_BALANCE

**Calculated Fields**:
- SETTLEMENT_COMPLETION_PERCENTAGE: Uses existing or calculates from amounts

## Quality Control Validation

### Mandatory Tests (All PASSED)
1. **Record Count Validation**: 14,068 total loans
2. **Duplicate Detection**: PASS - No duplicate loan IDs
3. **Data Completeness**: 248 complete, 1,007 partial, 12,807 single source
4. **Business Logic**: Valid status values, no negative amounts
5. **Join Integrity**: 100% success rate on key joins
6. **Performance**: Query execution acceptable

### Data Quality Findings
- **Status Values**: Active, Complete, Broken, Inactive
- **Portfolio Types**: Setup, Successful, Failed
- **Source Overlap**: Minimal overlap requires comprehensive union approach
- **Volume Distribution**: Custom fields dominate (99.7% of total)

## Architecture Compliance

### Layer References (✅ Validated)
- ANALYTICS layer placement approved
- References BRIDGE and ANALYTICS layers only
- Follows 5-layer architecture rules
- Uses COPY GRANTS for permission preservation

### Development Environment
- **Development DB**: Uses DEVELOPMENT.FRESHSNOW for base table
- **Dev BI**: BUSINESS_INTELLIGENCE_DEV for views
- **Production**: Multi-environment deployment template ready

## Business Context

### Primary Use Cases
1. **Debt Sale Suppression**: Filter settlements from debt sale population
2. **Settlement Analysis**: Comprehensive settlement tracking and reporting
3. **Data Quality**: Identify inconsistencies across settlement sources
4. **Supporting Analytics**: Foundation for DI-1246 and DI-1235

### Key Business Rules
- One row per loan with any settlement indicator
- Include loans from ANY of the 3 sources
- Preserve NULL values to show data gaps
- No source prioritization - combine all available data
- Follow VW_LOAN_BANKRUPTCY aggregation patterns exactly

## Performance Considerations

### Query Optimization
- Schema filtering with LMS_SCHEMA() function
- QUALIFY for deduplication in sub status
- Efficient UNION strategy to avoid overlaps
- LEFT JOIN pattern for optional data

### Dynamic Table Configuration
- TARGET_LAG = '1 hour'
- WAREHOUSE = BUSINESS_INTELLIGENCE
- Alternative VIEW implementation available

## Deployment Strategy

### Production Deployment
1. **Template Available**: Uses db_deploy_template.sql pattern
2. **Environment Variables**: Dev/Prod database switching
3. **COPY GRANTS**: Preserves existing permissions
4. **Fallback Option**: VIEW creation if Dynamic Table fails
5. **Post-Deployment Validation**: Automated record count checks

### Dependencies
- VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
- VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
- VW_LOAN_STATUS_ARCHIVE_CURRENT
- LMS_SCHEMA() function
- Standard BRIDGE/ANALYTICS layer views

## Multi-Remediation Settlement Analysis Enhancement

### Analysis Implementation
**Purpose**: Analyze settlement data coverage for 2,423 loans with multiple remediations using VW_LOAN_DEBT_SETTLEMENT.

### Technical Approach Refinements
```sql
-- Final optimized query structure:
SELECT
    multi.PAYOFF_LOAN_ID,
    LOWER(multi.LEAD_GUID) AS LEAD_GUID,  -- Case normalization
    vlds.LOAN_ID::varchar as loan_id,     -- Type consistency
    -- All settlement fields...
FROM "BUSINESS_INTELLIGENCE_DEV"."CRON_STORE"."CO_LOANS_WITH_MULTI_REMEDIATIONS" multi
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT vlds
    ON lower(multi.LEAD_GUID) = lower(vlds.LEAD_GUID)  -- Robust case-insensitive matching
ORDER BY vlds.data_source_count DESC NULLS LAST, multi.PAYOFF_LOAN_ID;  -- Prioritize complete data
```

### Key Implementation Improvements
1. **Direct Table Access**: Uses permanent CRON_STORE table instead of staged file approach
2. **Case-Insensitive Matching**: `LOWER()` functions ensure robust LEAD_GUID joins
3. **Intelligent Ordering**: Results sorted by settlement data completeness (DATA_SOURCE_COUNT DESC)
4. **Type Consistency**: Explicit varchar casting for LOAN_ID field
5. **Production-Ready**: Fully qualified table names for environment stability

### Analysis Results
- **Total Loans Analyzed**: 2,423 multi-remediation loans
- **Settlement Data Coverage**: 430 loans (17.75%) have settlement data
- **Data Quality**: Case-insensitive matching eliminates potential join misses
- **Business Value**: Prioritized results show most complete settlement data first

### Technical Benefits
- **Robust Joins**: Case normalization prevents GUID case sensitivity issues
- **Better UX**: Results ordered by data completeness for analyst efficiency
- **Production Stability**: Direct table access eliminates staging dependencies
- **Data Integrity**: Type casting ensures consistent field formats

## File Organization

### Deliverables Structure
```
tickets/kchalmers/DI-1262/
├── README.md (Business summary with multi-remediation QC)
├── CLAUDE.md (This technical context)
├── final_deliverables/
│   ├── 1_loan_debt_settlement_creation.sql
│   ├── 2_production_deploy_template.sql
│   ├── 4_multi_remediation_settlement_query.sql (Enhanced with table access)
│   └── 4_multi_remediation_settlement_results.csv (2,423 loans analyzed)
├── qc_validation.sql (Comprehensive QC suite)
├── source_materials/ (PRP, references, and COloanswithmultipleremediations.csv)
└── exploratory_analysis/ (Development queries)
```

### Quality Gates Completed
- [x] All settlement fields identified and validated
- [x] Portfolio aggregation follows VW_LOAN_BANKRUPTCY pattern
- [x] Data source tracking comprehensive and accurate
- [x] Join validation successful for all sources
- [x] NULL handling preserves data source gaps
- [x] QC validation covers all business logic
- [x] Performance optimization completed
- [x] Production deployment template ready
- [x] Multi-remediation analysis with enhanced case-insensitive matching
- [x] Results prioritization by settlement data completeness

## Future Maintenance

### Data Quality Monitoring
- Monitor DATA_SOURCE_COUNT distribution
- Track settlement field population rates
- Validate portfolio assignment consistency
- Monitor performance and refresh patterns

### Enhancement Opportunities
- Additional settlement status normalization
- Historical settlement tracking (if needed)
- Integration with debt sale suppression automation
- Advanced settlement analytics and metrics
## DI-1235 Enhancement: 6-Source Architecture (October 2025)

### Architecture Evolution
**Original (DI-1262)**: 3 sources (CUSTOM_FIELDS, PORTFOLIOS, SUB_STATUS)  
**Post-DOCUMENTS**: 4 sources  
**Post-DI-1235**: 6 sources (ACTIONS active, CHECKLIST_ITEMS placeholder)

### Source 5: ACTIONS Implementation
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

**Key Pattern**: Many:1 aggregation using MIN/MAX/COUNT/MAX_BY functions  
**Coverage**: 876 unique loans, 921 total action records  
**Business Value**: Settlement workflow visibility and agent tracking

### Source 6: CHECKLIST_ITEMS Placeholder
```sql
-- COMMENTED OUT - Awaiting data population
-- Placeholder structure ready for activation when VW_LMS_CHECKLIST_ITEM_ENTITY_CURRENT has data
-- Expected fields: SETTLEMENT_CHECKLIST_COUNT, SETTLEMENT_CHECKLISTS, LATEST_CHECKLIST_UPDATE
```

**Status**: 0 records, awaiting user guidance on filter criteria  
**Activation**: Requires filter configuration and aggregation strategy confirmation

### Updated Data Tracking

**DATA_SOURCE_COUNT Calculation**:
```sql
(
    CASE WHEN cls.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sp.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN d.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sss.LOAN_ID IS NOT NULL AND sss.CURRENT_STATUS = 'Closed - Settled in Full' THEN 1 ELSE 0 END +
    CASE WHEN act.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END  -- NEW
    -- + CASE WHEN chk.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END  -- Placeholder
) as DATA_SOURCE_COUNT
```

**DATA_COMPLETENESS_FLAG Thresholds**:
- **COMPLETE**: 5-6 sources (6 when CHECKLIST active)
- **PARTIAL**: 2-4 sources
- **SINGLE_SOURCE**: 1 source

**New Boolean Flags**:
- `HAS_SETTLEMENT_ACTION` - TRUE for loans with ACTIONS data
- `HAS_SETTLEMENT_CHECKLIST` - Placeholder (commented out)

### Technical Implementation Notes

**Backward Compatibility**: ✅ Maintained
- All 33 existing columns preserved unchanged
- New columns added after existing document fields
- Existing queries continue to work
- COPY GRANTS preserves permissions

**Join Strategy**:
```sql
-- Settlement actions data (NEW - DI-1235)
LEFT JOIN ACTIONS act
    ON sl.LOAN_ID = act.LOAN_ID

-- Settlement checklist data (PLACEHOLDER - DI-1235, commented out)
-- LEFT JOIN CHECKLIST_ITEMS chk
--     ON sl.LOAN_ID = chk.LOAN_ID
```

**Settlement Population Union**:
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

### QC Validation Results (DI-1235)
- ✅ No duplicates (one row per LOAN_ID maintained)
- ✅ ACTIONS source: 876 loans match source exactly
- ✅ All ACTIONS fields 100% populated for flagged loans
- ✅ Date logic valid (EARLIEST <= LATEST)
- ✅ Backward compatibility verified
- ✅ Join integrity confirmed
- ✅ Performance acceptable

### Volume Impact Analysis
- **DI-1262 Original**: 14,074 loans
- **After DOCUMENTS**: 14,183 loans
- **After ACTIONS (DI-1235)**: 14,187 loans (+4 new, 0.03% increase)
- **Enrichment**: 872 existing loans gained ACTIONS data

### Data Distribution (Post-DI-1235)
- **COMPLETE (5 sources)**: 112 loans (0.79%)
- **PARTIAL (2-4 sources)**: 1,460 loans (10.29%)
- **SINGLE_SOURCE**: 12,615 loans (88.92%)

### CHECKLIST_ITEMS Activation Procedure
When data becomes available:
1. Uncomment CHECKLIST_ITEMS CTE
2. Configure filter criteria for settlement checklists
3. Uncomment settlement_loans UNION for CHECKLIST_ITEMS
4. Uncomment LEFT JOIN in main query
5. Uncomment checklist column selections
6. Uncomment HAS_SETTLEMENT_CHECKLIST flag
7. Uncomment checklist term in DATA_SOURCE_COUNT
8. Update DATA_SOURCE_LIST array construction

### Related DI-1235 Documentation
- **Ticket Folder**: `tickets/kchalmers/DI-1235/`
- **PRP**: `PRPs/debt_settlement_object_update/snowflake-data-object-vw-loan-debt-settlement-update.md`
- **Enhanced DDL**: `tickets/kchalmers/DI-1235/final_deliverables/1_vw_loan_debt_settlement_enhanced.sql`
- **Production Template**: `tickets/kchalmers/DI-1235/final_deliverables/3_production_deploy_template.sql`

---
*Technical Context Updated: DI-1235 Enhancement (October 2025)*
