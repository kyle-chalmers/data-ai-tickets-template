# Snowflake Data Object PRP: VW_LOAN_FRAUD

## Operation Context
- **Operation Type**: CREATE_NEW
- **Scope**: SINGLE_OBJECT
- **Expected Ticket Folder**: `tickets/kchalmers/DI-XXXX/` (to be created)

## Business Requirements

### Primary Object Definition
- **Object Name**: VW_LOAN_FRAUD
- **Object Type**: VIEW
- **Target Schema Layer**: BUSINESS_INTELLIGENCE.ANALYTICS
- **Data Grain**: One row per loan with any fraud indicator
- **Time Period**: All time (current and historical)

### Business Purpose
This view serves as a **single source of truth for all fraud-related loan data** across Happy Money's LoanPro system. It consolidates fraud indicators from three disparate sources (custom fields, portfolios, and sub-statuses) to enable:

1. **Debt Sale Suppression**: Exclude fraudulent loans from debt sale populations
2. **Fraud Analysis**: Comprehensive fraud case timeline and volume analysis
3. **Data Quality Identification**: Surface inconsistencies and gaps in fraud data across systems
4. **Business Intelligence**: Support DI-1246 and DI-1235 downstream requirements

### Key Stakeholders
- **Primary**: Kyle Chalmers (Data Intelligence Team)
- **Use Cases**: Debt sale operations, fraud analysis, data quality management

## Current State Analysis

### Data Volume Assessment
**Total Fraud Loans Identified**: 504 unique loans across all sources
**Source Records**: 784 total records (indicating multi-source overlaps)

**Data Distribution by Source Count**:
- 47.8% (241 loans) have fraud data from 1 source only
- 48.8% (246 loans) have fraud data from 2 sources
- 3.4% (17 loans) have fraud data from all 3 sources

### Source Table Analysis

#### 1. Custom Fields Source: VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
**Purpose**: LoanPro custom loan settings with fraud investigation fields
**Key Fields** (with population counts out of 127,044 total records):
- `FRAUD_INVESTIGATION_RESULTS`: 254 records (values: "Confirmed", "Declined")
- `FRAUD_CONFIRMED_DATE`: 249 records (date range: 2022-01-19 to 2025-09-18)
- `FRAUD_CONTACT_EMAIL`: 2 records (very low population)
- `FRAUD_NOTIFICATION_RECEIVED`: 248 records
- `FOLLOW_UP_INFORMATION`: 12,090 records
- `EXPECTED_RESPONSE_DATE`: 0 records (**completely NULL - will be commented out**)
- `EOS_CARD_DISPUTE_CODE`: 242 records

#### 2. Portfolio Source: VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
**Purpose**: Portfolio categorization for fraud cases
**Fraud Portfolios Identified**:
- "First Party Fraud - Confirmed": 186 loans
- "Fraud - Declined": 163 loans
- "Identity Theft Fraud - Confirmed": 16 loans
- "Fraud - Pending Investigation": 6 loans

#### 3. Sub-Status Source: VW_LOAN_SUB_STATUS_ENTITY_CURRENT + VW_LOAN_SETTINGS_ENTITY_CURRENT
**Purpose**: Current loan sub-status with fraud classifications
**Fraud Sub-Statuses** (with LMS_SCHEMA filter applied):
- "Fraud Rejected": 19,007 loans (**largest fraud population**)
- "Closed - Confirmed Fraud": 18 loans
- "Open - Fraud Process": 1 loan

### Architecture Compliance
Following 5-layer Snowflake architecture:
- **Target Layer**: ANALYTICS (appropriate for business-ready consolidated data)
- **Source Dependencies**: BRIDGE layer views (VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT, VW_LOAN_SETTINGS_ENTITY_CURRENT, VW_LOAN_SUB_STATUS_ENTITY_CURRENT) and ANALYTICS layer (VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS)
- **Schema Filtering**: All sources properly filtered with `SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()` where applicable

### Reference Model Analysis: VW_LOAN_DEBT_SETTLEMENT
The debt settlement view provides an excellent template for consolidating multiple data sources:

**Key Patterns to Apply**:
- **Multi-source union strategy**: Combines custom fields, portfolios, and sub-statuses
- **Data completeness flags**: `HAS_CUSTOM_FIELDS`, `HAS_SETTLEMENT_PORTFOLIO`, `HAS_SETTLEMENT_SUB_STATUS`
- **Source tracking**: `DATA_SOURCE_COUNT`, `DATA_SOURCE_LIST`, `DATA_COMPLETENESS_FLAG`
- **Consolidated business logic**: Priority handling for conflicting data between sources

## Implementation Blueprint

### Data Architecture Design

#### Population Strategy
**Include ALL fraud indicators** following user confirmation:
- All loans with fraud-related custom fields (regardless of investigation result)
- All loans in fraud-related portfolios (confirmed, declined, pending)
- All loans with fraud-related sub-statuses (including "Fraud Rejected")

#### Data Grain and Deduplication
**Grain**: One row per LOAN_ID with consolidated fraud information from all sources
**Deduplication Strategy**:
- Use LOAN_ID as primary key for final output
- Aggregate multiple portfolio assignments per loan
- Handle multiple dates by taking earliest/latest as appropriate
- Include source tracking for data quality analysis

#### Schema Filtering Implementation
```sql
-- Custom fields: No additional schema filter (already current data)
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT

-- Portfolio source: No schema filter (analytics layer)
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS

-- Sub-status source: CRITICAL - Apply LMS_SCHEMA filter
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT lse
JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT ss
WHERE lse.SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
  AND ss.SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()
```

### Data Source Integration Strategy

#### 1. Custom Fields Integration
```sql
-- Primary fraud investigation fields
FRAUD_INVESTIGATION_RESULTS,
FRAUD_CONFIRMED_DATE,
FRAUD_NOTIFICATION_RECEIVED,
FRAUD_CONTACT_EMAIL,
FOLLOW_UP_INFORMATION,
EOS_CARD_DISPUTE_CODE
-- EXPECTED_RESPONSE_DATE -- Commented out: completely NULL field
```

#### 2. Portfolio Integration
```sql
-- Aggregate fraud portfolios per loan
LISTAGG(DISTINCT portfolio_name, '; ') as FRAUD_PORTFOLIOS,
COUNT(DISTINCT portfolio_id) as FRAUD_PORTFOLIO_COUNT,
MIN(portfolio_created_date) as EARLIEST_FRAUD_PORTFOLIO_DATE,
MAX(portfolio_created_date) as LATEST_FRAUD_PORTFOLIO_DATE
```

#### 3. Sub-Status Integration
```sql
-- Current fraud sub-status with schema filtering
CURRENT_FRAUD_SUB_STATUS,
FRAUD_SUB_STATUS_DATE,
-- Historical sub-status tracking if needed
```

#### 4. Data Quality Flags (Following VW_LOAN_DEBT_SETTLEMENT Pattern)
```sql
-- Source presence indicators
CASE WHEN custom_fields.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_CUSTOM_FIELDS,
CASE WHEN portfolios.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_PORTFOLIO,
CASE WHEN sub_status.LOAN_ID IS NOT NULL THEN TRUE ELSE FALSE END as HAS_FRAUD_SUB_STATUS,

-- Data completeness summary
COALESCE(
    CASE WHEN custom_fields.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN portfolios.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN sub_status.LOAN_ID IS NOT NULL THEN 1 ELSE 0 END,
    0
) as FRAUD_DATA_SOURCE_COUNT,

CASE
    WHEN FRAUD_DATA_SOURCE_COUNT = 3 THEN 'COMPLETE'
    WHEN FRAUD_DATA_SOURCE_COUNT = 2 THEN 'PARTIAL'
    ELSE 'SINGLE_SOURCE'
END as FRAUD_DATA_COMPLETENESS_FLAG,

REPLACE(CONCAT_WS(', ',
    CASE WHEN custom_fields.LOAN_ID IS NOT NULL THEN 'CUSTOM_FIELDS' ELSE '' END,
    CASE WHEN portfolios.LOAN_ID IS NOT NULL THEN 'PORTFOLIOS' ELSE '' END,
    CASE WHEN sub_status.LOAN_ID IS NOT NULL THEN 'SUB_STATUS' ELSE '' END
),' , ',' ') as FRAUD_DATA_SOURCE_LIST
```

### Development Environment Setup

#### DEVELOPMENT Database Objects
```sql
-- Development layer for testing
CREATE OR REPLACE VIEW DEVELOPMENT.FRESHSNOW.VW_LOAN_FRAUD
-- Development analytics layer
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
```

### Critical Validation Requirements

#### Mandatory Independent Data Exploration
**CRITICAL INSTRUCTION FOR IMPLEMENTER**: Before following this PRP, perform independent data exploration to validate:

1. **Duplicate Detection**: Execute comprehensive duplicate analysis on LOAN_ID
```sql
SELECT LOAN_ID, COUNT(*) as duplicate_count
FROM target_view
GROUP BY LOAN_ID
HAVING COUNT(*) > 1;
```

2. **Data Grain Validation**: Confirm one row per loan assumption
```sql
SELECT
    COUNT(*) as total_rows,
    COUNT(DISTINCT LOAN_ID) as unique_loans,
    CASE WHEN total_rows = unique_loans THEN 'GRAIN_CORRECT' ELSE 'GRAIN_VIOLATION' END as grain_check
```

3. **Source Overlap Analysis**: Validate fraud indicator conflicts
```sql
-- Check for conflicting fraud determinations across sources
SELECT
    COUNT(*) as conflict_count,
    custom_investigation_result,
    portfolio_type,
    sub_status_type
WHERE custom_investigation_result = 'Declined'
  AND (portfolio_type LIKE '%Confirmed%' OR sub_status_type LIKE '%Confirmed%')
```

4. **Schema Filter Verification**: Ensure proper LMS_SCHEMA filtering
```sql
-- Validate schema filtering is working correctly
SELECT DISTINCT schema_name, COUNT(*)
FROM source_tables
GROUP BY schema_name;
```

**QC Gates**: All validation queries must pass before proceeding with implementation.

### Production Deployment Strategy

#### Deployment Template (Based on documentation/db_deploy_template.sql)
```sql
DECLARE
    -- dev databases
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';

    -- prod databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';

BEGIN
    -- FRESHSNOW section
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            [FULL_COLUMN_LIST]
        ) COPY GRANTS AS
            [VIEW_DEFINITION]
    ');

    -- ANALYTICS section (target layer)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            [FULL_COLUMN_LIST]
        ) COPY GRANTS AS
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_LOAN_FRAUD
    ');
END;
```

### Quality Control Plan

#### Single Consolidated QC Validation File: `qc_validation.sql`
```sql
-- 1. Duplicate Detection Test
SELECT 'Duplicate Check' as test_name,
       COUNT(*) as total_records,
       COUNT(DISTINCT LOAN_ID) as unique_loans,
       COUNT(*) - COUNT(DISTINCT LOAN_ID) as duplicate_count;

-- 2. Data Completeness Test
SELECT 'Data Completeness' as test_name,
       COUNT(*) as total_loans,
       COUNT(CASE WHEN HAS_FRAUD_CUSTOM_FIELDS THEN 1 END) as custom_fields_count,
       COUNT(CASE WHEN HAS_FRAUD_PORTFOLIO THEN 1 END) as portfolio_count,
       COUNT(CASE WHEN HAS_FRAUD_SUB_STATUS THEN 1 END) as sub_status_count;

-- 3. Data Conflict Analysis
SELECT 'Data Conflict Check' as test_name,
       COUNT(*) as potential_conflicts
FROM VW_LOAN_FRAUD
WHERE FRAUD_INVESTIGATION_RESULTS = 'Declined'
  AND (FRAUD_PORTFOLIOS LIKE '%Confirmed%' OR CURRENT_FRAUD_SUB_STATUS LIKE '%Confirmed%');

-- 4. Source Coverage Test
SELECT FRAUD_DATA_COMPLETENESS_FLAG,
       COUNT(*) as loan_count,
       ROUND((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()), 2) as percentage
FROM VW_LOAN_FRAUD
GROUP BY FRAUD_DATA_COMPLETENESS_FLAG;

-- 5. Performance Test
EXPLAIN SELECT * FROM VW_LOAN_FRAUD LIMIT 1000;
```

### File Organization Requirements

#### Expected Ticket Structure
```
tickets/kchalmers/DI-XXXX/
├── README.md                                    # Complete documentation with assumptions
├── final_deliverables/                          # Numbered for review order
│   ├── 1_vw_loan_fraud_ddl.sql                 # Main view creation with commented NULL fields
│   └── 2_production_deployment_template.sql     # Production deployment script
├── qc_validation.sql                           # Single consolidated QC file
└── original_code/                              # Reference materials from debt settlement model
```

#### Field Commenting Strategy for NULL Fields
```sql
-- Include all fraud-related fields, commenting out completely NULL ones:
FRAUD_INVESTIGATION_RESULTS,
FRAUD_CONFIRMED_DATE,
FRAUD_NOTIFICATION_RECEIVED,
FRAUD_CONTACT_EMAIL,
FOLLOW_UP_INFORMATION,
EOS_CARD_DISPUTE_CODE,
-- EXPECTED_RESPONSE_DATE, -- Commented out: Field is 100% NULL across all 127K+ records
```

## Database Object Dependencies

### Source Dependencies
```sql
-- Direct dependencies (must exist and be accessible)
BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT
BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT

-- Configuration dependency
arca.CONFIG.LMS_SCHEMA() -- For schema filtering
```

### Validation Commands
```bash
# Development Environment Object Creation
snow sql -q "DESCRIBE DEVELOPMENT.FRESHSNOW.VW_LOAN_FRAUD" --format csv
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD" --format csv

# Comprehensive QC Validation
snow sql -q "$(cat qc_validation.sql)" --format csv

# Performance Validation
snow sql -q "EXPLAIN $(cat final_deliverables/1_vw_loan_fraud_ddl.sql)" --format csv

# Production Deployment Readiness (after user review)
# snow sql -q "$(cat final_deliverables/2_production_deployment_template.sql)"
```

## Key Assumptions Documented

### Business Logic Assumptions
1. **Fraud Scope**: Including ALL fraud-related loans (confirmed, declined, pending, rejected) for comprehensive analysis
2. **Historical Data**: All fraud cases from system inception to present included in single view
3. **Data Grain**: One row per LOAN_ID achievable through aggregation of multiple portfolio/status records
4. **Source Priority**: No single source takes precedence - all sources treated equally with conflict flagging

### Technical Assumptions
1. **Schema Filtering**: LMS_SCHEMA() filter applies only to sub-status source, not custom fields or portfolios
2. **NULL Field Handling**: EXPECTED_RESPONSE_DATE excluded due to 100% NULL population across all records
3. **Performance**: View will perform adequately for 500+ loan population without materialization
4. **Data Quality**: Source conflicts are expected and will be flagged rather than resolved programmatically

### Data Architecture Assumptions
1. **Layer Placement**: ANALYTICS layer appropriate for business-ready consolidated fraud data
2. **COPY GRANTS**: Existing permissions structure will be preserved in deployment
3. **Deployment Strategy**: Development → Production deployment using template pattern from db_deploy_template.sql

## Confidence Assessment

**Confidence Score: 9/10**

**High Confidence Justification**:
- Complete database context with all source table structures analyzed
- Clear business requirements with user confirmation on key design decisions
- Proven reference model (VW_LOAN_DEBT_SETTLEMENT) providing tested consolidation patterns
- Comprehensive validation strategy with executable QC queries
- Proper architecture compliance with 5-layer model
- Detailed source dependency mapping and schema filtering requirements

**Risk Mitigation**: Mandatory independent data exploration step ensures implementer validates all assumptions before execution.

## Expected Implementation Timeline

1. **Data Exploration & Validation** (1-2 hours): Independent verification of PRP assumptions
2. **Development Object Creation** (1 hour): Create view in DEVELOPMENT environment
3. **Quality Control Testing** (1 hour): Execute all QC validation queries and resolve issues
4. **User Review & Approval** (External): Stakeholder validation of development version
5. **Production Deployment** (30 minutes): Execute production deployment template

**Total Implementation Time**: ~4 hours + user review time

**Success Criteria**: Production-ready VW_LOAN_FRAUD view with comprehensive fraud data consolidation, data quality flags, and passing QC validation.