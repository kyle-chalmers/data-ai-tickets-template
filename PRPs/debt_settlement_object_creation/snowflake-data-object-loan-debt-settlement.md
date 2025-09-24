# Snowflake Data Object PRP: LOAN_DEBT_SETTLEMENT

## Operation Summary
- **Operation Type**: CREATE_NEW
- **Scope**: SINGLE_OBJECT
- **Jira Ticket**: DI-1262 (linked to Epic DI-1238)
- **Expected Ticket Folder**: `tickets/kchalmers/DI-1262/`

## Business Context

### Business Purpose
Create a comprehensive debt settlement data object combining custom loan settings, portfolio assignments, and loan sub status data to serve as single source of truth for debt settlement analysis and debt sale suppression.

### Primary Use Cases
- **Debt Sale Suppression**: Exclude loans with active debt settlements from debt sale files
- **Settlement Analysis**: Comprehensive analysis of debt settlement data across all sources
- **Data Quality Investigation**: Identify inconsistencies and gaps in settlement data tracking
- **Supporting Analytics**: Enable completion of DI-1246 and DI-1235

### Key Metrics/KPIs
- Count of active debt settlements by source and status
- Timeline of debt settlement agreements and completion rates
- Data completeness across settlement tracking sources
- Settlement completion percentages and financial impact

## Data Architecture Design

### Target Object Definition
- **Object Name**: `LOAN_DEBT_SETTLEMENT`
- **Target Schema**: `BUSINESS_INTELLIGENCE.ANALYTICS`
- **Object Type**: DYNAMIC TABLE (preferred) or VIEW
- **Data Grain**: One row per loan with any debt settlement indicator
- **Expected Volume**: ~70,000+ loans (union of all settlement sources)

### Architecture Compliance
- **Layer Placement**: ANALYTICS layer ✅
- **Source Layer Compliance**: References BRIDGE and ANALYTICS layers only ✅
- **Deployment Strategy**: Use `documentation/db_deploy_template.sql` pattern for FRESHSNOW → BRIDGE → ANALYTICS deployment

## Source Table Analysis

### 1. Custom Loan Settings (Primary Source)
```sql
-- Source: BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
-- Key Fields: All settlement-related custom fields
-- Volume: 14,060 loans with settlement indicators
-- Join Key: LOAN_ID
```

**Settlement Fields to Include (ALL fields, exclude if entirely NULL)**:
- `SETTLEMENTSTATUS` - Active, Complete, Broken, Inactive
- `SETTLEMENT_AMOUNT` - Agreed settlement amount
- `SETTLEMENT_AMOUNT_PAID` - Amount paid toward settlement
- `SETTLEMENT_AGREEMENT_AMOUNT_DCA` - DCA-specific settlement amount
- `SETTLEMENTCOMPANY` - Settlement company name
- `SETTLEMENT_COMPANY_DCA` - DCA settlement company
- `SETTLEMENT_ACCEPTED_DATE` - Date settlement was accepted
- `SETTLEMENT_SETUP_DATE` - Date settlement was set up
- `SETTLEMENT_END_DATE` - Settlement end date
- `SETTLEMENTAGREEMENTAMOUNT` - Total agreement amount
- `SETTLEMENTCOMPLETIONDATE` - Date settlement completed
- `SETTLEMENTCOMPLETIONPERCENTAGE` - Completion percentage (may calculate if NULL)
- `SETTLEMENTSTARTDATE` - Settlement start date
- `UNPAID_SETTLEMENT_BALANCE` - Remaining balance
- `DEBT_SETTLEMENT_COMPANY` - Primary debt settlement company
- `DEBTSETTLEMENTPAYMENTTERMS` - Payment terms
- `PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT` - Payoff amount at settlement
- `TOTAL_PAID_AT_TIME_OF_SETTLEMENT` - Total paid amount
- `AMOUNT_FORGIVEN` - Forgiven amount
- `EXPECTEDSETTLEMENTENDDATE` - Expected end date
- `THIRD_PARTY_COLLECTION_AGENCY` - Collection agency info

### 2. Settlement Portfolios (Secondary Source)
```sql
-- Source: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
-- Filter: PORTFOLIO_CATEGORY = 'Settlement'
-- Volume: 1,102 loans with settlement portfolios
-- Join Key: LOAN_ID
```

**Portfolio Types Identified**:
- Settlement Setup
- Settlement Successful
- Settlement Failed

### 3. Loan Sub Status (Tertiary Source)
```sql
-- Source: BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT
-- Joined with: BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT
-- Filter: Settlement-related status titles
-- Volume: 63,560 loans with settlement sub status
-- Primary Status: "Closed - Settled in Full"
-- Join Keys: LOAN_SUB_STATUS_ID = ID
```

## Data Quality Assessment

### Source Overlap Analysis
- **Total Unique Population**: ~70,000+ loans (union of all sources)
- **Custom Fields Only**: 14,060 loans
- **Portfolio Assignment Only**: 1,102 loans
- **Sub Status Only**: 63,560 loans
- **Incomplete Coverage**: Minimal overlap between sources requires comprehensive consolidation

### Known Data Quality Issues
- **Inconsistent Statuses**: Loans with settlement custom fields but non-settlement sub statuses (Declined, Charged-Off)
- **Partial Data Coverage**: Loans may have data in only 1-2 of the 3 sources
- **NULL Field Prevalence**: Many settlement custom fields are entirely NULL
- **Status Misalignment**: Settlement portfolios don't always align with custom field statuses

### Data Quality Flags to Include
- `DATA_SOURCE_COUNT` - Number of sources with settlement data (1-3)
- `DATA_SOURCE_LIST` - Comma-separated list of data sources
- `HAS_CUSTOM_FIELDS` - Boolean indicator
- `HAS_SETTLEMENT_PORTFOLIO` - Boolean indicator
- `HAS_SETTLEMENT_SUB_STATUS` - Boolean indicator
- `DATA_COMPLETENESS_FLAG` - 'COMPLETE', 'PARTIAL', 'SINGLE_SOURCE'

## Implementation Blueprint

### Multi-Source Consolidation Strategy
Following the VW_LOAN_BANKRUPTCY pattern with these CTEs:

1. **custom_settings_source** - All loans with settlement custom fields
2. **portfolio_source** - All loans with settlement portfolios (aggregated like bankruptcy portfolios)
3. **sub_status_source** - All loans with settlement-related sub statuses
4. **settlement_portfolios_agg** - Portfolio aggregation (LISTAGG, COUNT, Boolean flags)
5. **all_settlement_loans** - UNION of all three sources
6. **final_consolidation** - Left joins to combine all data sources

### Calculated Fields Strategy
- **Settlement Completion Percentage**: Calculate if NULL in custom fields using `SETTLEMENT_AMOUNT_PAID / SETTLEMENT_AMOUNT * 100`
- **Data Source Tracking**: Mark which sources contain data for each loan
- **Settlement Portfolio Summary**: Aggregate like bankruptcy portfolios in VW_LOAN_BANKRUPTCY
- **Most Recent Settlement**: If multiple records, prioritize by most recent update

### Portfolio Aggregation (Following Bankruptcy Pattern)
```sql
settlement_portfolios AS (
    SELECT
        port.LOAN_ID,
        LISTAGG(DISTINCT port.PORTFOLIO_NAME, '; ') as SETTLEMENT_PORTFOLIOS,
        COUNT(DISTINCT port.PORTFOLIO_NAME) as SETTLEMENT_PORTFOLIO_COUNT
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS port
    WHERE port.PORTFOLIO_CATEGORY = 'Settlement'
    GROUP BY port.LOAN_ID
)
```

### Data Architecture Implementation
```sql
-- Target Dynamic Table Structure
CREATE OR REPLACE DYNAMIC TABLE BUSINESS_INTELLIGENCE.ANALYTICS.LOAN_DEBT_SETTLEMENT
    TARGET_LAG = '1 hour'
    WAREHOUSE = BUSINESS_INTELLIGENCE_MEDIUM
AS
-- Implementation follows VW_LOAN_BANKRUPTCY multi-source pattern
-- with custom field prioritization and comprehensive data source tracking
```

## Quality Control Plan

### Comprehensive QC Validation (Single File: `qc_validation.sql`)

**1. Record Count Validation**
```sql
-- Total loan count from each source
-- Union count validation
-- Distinct loan count verification
```

**2. Data Completeness Assessment**
```sql
-- NULL field analysis by source
-- Data source coverage statistics
-- Settlement field population rates
```

**3. Business Logic Validation**
```sql
-- Settlement status consistency checks
-- Amount field logical validation
-- Date field chronological validation
-- Portfolio vs custom field alignment
```

**4. Duplicate Detection**
```sql
-- Duplicate loan detection
-- Multiple settlement records per loan
-- Data source overlap analysis
```

**5. Join Integrity Testing**
```sql
-- Source table join validation
-- Unmatched loan ID analysis
-- Schema name filtering verification
```

**6. Performance Optimization**
```sql
-- Query execution time measurement
-- Index usage analysis
-- Dynamic table refresh performance
```

## Development Environment Setup

### Phase 1: Development Objects
```bash
# Create development version first
snow sql -q "CREATE OR REPLACE DYNAMIC TABLE DEVELOPMENT.FRESHSNOW.LOAN_DEBT_SETTLEMENT ..."
snow sql -q "CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOAN_DEBT_SETTLEMENT ..."
snow sql -q "CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT ..."
```

### Phase 2: Validation Commands
```bash
# Comprehensive QC validation
snow sql -q "$(cat qc_validation.sql)" --format csv

# Development object verification
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT" --format csv
```

### Phase 3: Production Deployment
```bash
# Use deployment template for production (after user review)
# snow sql -q "$(cat final_deliverables/2_production_deploy_template.sql)"
```

## Critical Implementation Requirements

### EXPLICIT VALIDATION REQUIREMENT
**⚠️ CRITICAL**: Implementer must perform independent data exploration and validation before following PRP guidance. Do not blindly follow this PRP - validate each step independently with sample queries and data verification.

### Data Source Priority Rules
1. **Include ALL sources** - Loans with any settlement indicator from any source
2. **No source prioritization** - Preserve all data sources as-is with NULL handling
3. **Comprehensive tracking** - Mark data source presence for every loan
4. **NULL field exclusion** - Exclude settlement fields that are entirely NULL across all loans

### Consolidation Logic
- **Union Approach**: Combine all loans from all three sources
- **Left Join Strategy**: Use custom fields as base, left join portfolios and sub status
- **NULL Preservation**: Maintain NULL values to show data source gaps
- **No Status Conflicts**: Include misaligned statuses for data quality analysis

## File Organization Requirements

### Expected Deliverable Structure
```
tickets/kchalmers/DI-1262/
├── README.md                                    # Complete documentation with assumptions
├── final_deliverables/                          # Numbered for review order
│   ├── 1_loan_debt_settlement_creation.sql     # Dynamic table creation SQL
│   ├── 2_production_deploy_template.sql        # Multi-environment deployment
│   └── qc_validation.sql                       # Single consolidated QC file
├── source_materials/                           # Research queries and analysis
└── exploratory_analysis/                       # Development and testing queries
```

### Quality Gates
- [ ] All settlement fields identified and included (exclude if entirely NULL)
- [ ] Portfolio aggregation follows VW_LOAN_BANKRUPTCY pattern exactly
- [ ] Data source tracking comprehensive and accurate
- [ ] Join validation successful for all three sources
- [ ] NULL handling preserves data source gaps appropriately
- [ ] QC validation covers all business logic requirements
- [ ] Performance optimization completed and tested
- [ ] Development environment objects created and tested
- [ ] Production deployment template ready for multi-layer deployment

## Expected Outcomes

### Business Impact
- **Comprehensive Settlement Tracking**: Single source of truth for all debt settlements
- **Enhanced Debt Sale Accuracy**: Improved suppression logic with complete settlement data
- **Data Quality Insights**: Clear visibility into settlement data inconsistencies
- **Analytics Foundation**: Robust foundation for settlement analysis and reporting

### Technical Deliverables
- **Production-Ready Dynamic Table**: `BUSINESS_INTELLIGENCE.ANALYTICS.LOAN_DEBT_SETTLEMENT`. If we cannot create the dynamic table, create a view instead with the name of `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT`.
- **Comprehensive Data Coverage**: ~70,000+ loans with any settlement indicator
- **Multi-Source Integration**: Seamless consolidation of 3 settlement data sources
- **Quality Control Framework**: Complete validation and monitoring capabilities

## Confidence Assessment: 9/10

This PRP provides comprehensive database context, clear architecture compliance, executable validation steps, and follows established patterns from VW_LOAN_BANKRUPTCY. The multi-source consolidation strategy addresses all identified data quality concerns while maintaining data integrity and business logic requirements.

**Success Criteria**: One-pass implementation with production-ready dynamic table that comprehensively captures debt settlement data across all sources with proper data quality tracking and architecture compliance.