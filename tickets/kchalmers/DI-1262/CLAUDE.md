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