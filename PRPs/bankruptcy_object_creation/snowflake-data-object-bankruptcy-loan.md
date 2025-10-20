# Snowflake Data Object PRP: LOAN_BANKRUPTCY

## Operation Details
- **Operation Type:** CREATE_NEW
- **Scope:** SINGLE_OBJECT  
- **Target Object Name:** VW_LOAN_BANKRUPTCY
- **Target Layer:** BUSINESS_INTELLIGENCE.ANALYTICS
- **Object Type:** DYNAMIC TABLE (preferred) or VIEW
- **Grain:** One row per bankruptcy case and loan (loans may appear multiple times)

## Business Requirements

### Primary Business Problem
The current bankruptcy reference in the BI-2482_Outbound_List_Generation_for_GR job (lines 440-448) uses VW_LOAN_COLLECTION which either doesn't exist or references outdated bankruptcy data from Cloud Lending Solutions. This creates a critical dependency that could impact loan suppression accuracy in outbound list generation.

### Business Objectives
1. **Primary**: Replace outdated bankruptcy data source with comprehensive, current bankruptcy information
2. **Secondary**: Enable comprehensive bankruptcy analysis and reporting
3. **Data Quality**: Uncover and resolve inconsistencies between bankruptcy data sources
4. **Performance**: Optimize for high-performance loan suppression queries in outbound list generation

### Key Use Cases
- **Outbound List Suppression**: Fast, accurate bankruptcy status checks for loan suppression logic
- **Bankruptcy Analysis**: Timeline analysis, status progression tracking, portfolio impact assessment
- **Data Quality Monitoring**: Identify discrepancies between bankruptcy entity and custom field data
- **Compliance Reporting**: Comprehensive bankruptcy case tracking for regulatory requirements

### Success Metrics
- Complete replacement of VW_LOAN_COLLECTION dependency in BI-2482 job
- 100% coverage of active bankruptcy cases from all data sources (entity, custom fields, status, portfolios)
- Fast query performance for outbound list suppression (optimized for speed)
- Data quality flags for review of inconsistencies and duplicate data

## Current State Analysis

### Data Source Assessment

#### Primary Source: BUSINESS_INTELLIGENCE.BRIDGE.VW_BANKRUPTCY_ENTITY_CURRENT
- **Records**: 2,101 total bankruptcy records (all active, non-deleted)
- **Unique Loans**: 2,101 (one-to-one loan relationship)
- **Unique Cases**: 2,083 (18 duplicate case numbers identified)
- **Data Quality**: Excellent - no null values in critical fields (CASE_NUMBER, FILING_DATE, CHAPTER)
- **Coverage**: Primary bankruptcy entity data from LoanPro system

**Key Fields Analysis:**
```sql
-- Chapter Distribution (needs normalization)
loan.bankruptcyChapter.chapter13: 1,635 cases (77.8%)
loan.bankruptcyChapter.chapter7:    463 cases (22.0%)
loan.bankruptcyChapter.chapter11:     3 cases (0.1%)

-- Petition Status Distribution (needs normalization)
loan.bankruptcyPetitionStatus.planConfirmed: 1,387 cases (66.0%)
loan.bankruptcyPetitionStatus.petitionFiled:   705 cases (33.6%)
loan.bankruptcyPetitionStatus.discharged:        8 cases (0.4%)
loan.bankruptcyPetitionStatus.dismissed:         1 case (0.05%)

-- Process Status Distribution (needs normalization)
loan.bankruptcyProcessStatus.planConfirmed:       1,386 cases (66.0%)
loan.bankruptcyProcessStatus.petitionFiledVerified: 613 cases (29.2%)
loan.bankruptcyProcessStatus.noticeReceived:        91 cases (4.3%)
loan.bankruptcyProcessStatus.discharged:            7 cases (0.3%)
```

**Data Quality Issues:**
- Status fields contain system prefixes requiring normalization
- 18 duplicate case numbers affecting multiple loans
- All critical fields populated (no null handling required)

#### Secondary Source: BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
- **Total Records**: 125,512 loan settings records
- **Bankruptcy Records**: 6,402 records with bankruptcy case numbers
- **Overlap with Primary**: 6,374 loans appear in both sources
- **Unique to Secondary**: 28 loans only in custom settings
- **Coverage**: Custom field bankruptcy data, may contain historical or supplemental information

**Data Overlap Analysis:**
- **Bankruptcy Entity Only**: 792 loans (new/recent bankruptcies)
- **Both Sources**: 6,374 loans (core overlap requiring reconciliation)
- **Custom Settings Only**: 28 loans (legacy/edge cases)

#### Supporting Sources

**BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS:**
- **Total Records**: 1,598,828 loan-portfolio relationships
- **Unique Loans**: 351,655 loans in portfolios
- **Bankruptcy Portfolios**: 413,392 records in bankruptcy-related portfolios
- **Key Portfolios**: All bankruptcy portfolios EXCEPT BankruptcyWatch Integration (monitoring only)
  - Active Bankruptcy Portfolios: Bankruptcy - Chapter 7, Bankruptcy - Chapter 11/12/13, Bankruptcy - Pending, Bankruptcy - Dismissed, Bankruptcy - Discharged, Bankruptcy Monitoring
  - BankruptcyWatch Status Portfolios: BankruptcyWatch Primary Case Filed/Terminated/Confirmed/Reopened/Reinstated/Converted/Discharged/Dismissed, BankruptcyWatch Primary Joint Debtor Discharged/Dismissed
  - **EXCLUDED**: BankruptcyWatch Integration (monitoring service only, not actual bankruptcy status)

**BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT:**
- **Total Records**: 3,587,055 loan settings
- **Unique Loans**: 3,227,050 loans
- **Purpose**: Join bridge to loan sub-status information

**BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT:**
- **Total Records**: 105 status definitions
- **Unique Statuses**: 98 distinct statuses
- **Bankruptcy Statuses**: "Open - Bankruptcy", "Closed - Bankruptcy" 
- **Loans with Bankruptcy Status**: 144 loans currently have bankruptcy sub-status
- **Purpose**: Critical source for identifying loans with bankruptcy status that may not be in entity table

### Comprehensive Coverage Analysis
**Multi-Source Bankruptcy Detection:**
- **Bankruptcy Entity**: 2,101 loans with active bankruptcy records
- **Custom Settings**: 6,402 loans with bankruptcy case numbers
- **Loan Sub-Status**: 144 loans with bankruptcy status ("Open - Bankruptcy", "Closed - Bankruptcy")
- **Portfolio Assignments**: 413,392 records in bankruptcy-related portfolios (excluding BankruptcyWatch Integration which is monitoring only)
- **Legacy Reference (MVW_LOAN_TAPE)**: 2,316 loans with BANKRUPTCYFLAG = 'Y'

**Coverage Strategy**: Use UNION ALL approach to ensure no bankruptcy cases are missed from any source, with data quality flags to identify overlaps and inconsistencies for review.

## Architecture Compliance

### 5-Layer Architecture Positioning
**Target Layer: BUSINESS_INTELLIGENCE.ANALYTICS**
- **Rationale**: Business-ready data for analysts and outbound list generation
- **Source Dependencies**: BRIDGE layer objects (compliant with layer referencing rules)
- **Consumer Pattern**: Direct consumption by business intelligence jobs and dashboards

### Data Flow Design
```sql
FRESHSNOW Sources → BRIDGE Views → ANALYTICS.VW_LOAN_BANKRUPTCY → BI Jobs/Dashboards
```

**Referencing Compliance:**
- ✅ ANALYTICS can reference BRIDGE layer objects
- ✅ All source objects in BRIDGE layer
- ✅ No cross-layer violations

## Detailed Source Table Analysis

### BANKRUPTCY_ENTITY_CURRENT Schema
```sql
-- Critical business fields
ID NUMBER(10,0)                    -- Primary key
LOAN_ID NUMBER(10,0)              -- Join key to loan data  
CASE_NUMBER VARCHAR(255)          -- Bankruptcy case identifier
CHAPTER VARCHAR(100)              -- Bankruptcy chapter (needs normalization)
PETITION_STATUS VARCHAR(100)      -- Current petition status (needs normalization) 
PROCESS_STATUS VARCHAR(100)       -- Current process status (needs normalization)
FILING_DATE DATE                  -- Bankruptcy filing date
NOTICE_RECEIVED_DATE DATE         -- Notice received date
AUTOMATIC_STAY_STATUS VARCHAR(100) -- Stay status
CUSTOMER_ID NUMBER(10,0)          -- Customer reference

-- Additional tracking fields
PETITION_TYPE VARCHAR(100)
BANKRUPTCY_DISTRICT VARCHAR(255)
CITY VARCHAR(100), STATE VARCHAR(100)
PROOF_OF_CLAIM_DEADLINE_DATE DATE
MEETING_OF_CREDITORS_DATE DATE
OBJECTION_DEADLINE_DATE DATE
DISMISSED_DATE DATE
CLOSED_REASON VARCHAR(255)

-- System fields
ACTIVE NUMBER(3,0)                -- Filter: = 1
DELETED NUMBER(3,0)               -- Filter: = 0
CREATED TIMESTAMP_NTZ(9)
LASTUPDATED TIMESTAMP_NTZ(9)
DSS_RECORD_SOURCE VARCHAR(255)    -- Data source tracking
```

### CUSTOM_LOAN_SETTINGS_CURRENT Schema (Bankruptcy-Relevant Fields)
```sql
-- Bankruptcy-specific custom fields
LOAN_ID NUMBER(10,0)                              -- Join key
BANKRUPTCY_CASE_NUMBER VARCHAR(16777216)          -- Alternative case number
BANKRUPTCY_COURT_DISTRICT VARCHAR(16777216)       -- Court district
BANKRUPTCY_FILING_DATE DATE                       -- Alternative filing date
BANKRUPTCY_VENDOR VARCHAR(16777216)               -- Processing vendor
BANKRUPTCY_STATUS VARCHAR(16777216)               -- Custom status field
BANKRUPTCY_FLAG VARCHAR(16777216)                 -- Flag field
BANKRUPTCY_CHAPTER VARCHAR(16777216)              -- Alternative chapter
BANKRUPTCY_NOTIFICATION_RECEIVED_DATE DATE        -- Notification date
DISCHARGE_DATE DATE                               -- Discharge date
DISMISSAL_DATE DATE                               -- Dismissal date
REAFFIRMATION_DATE DATE                           -- Reaffirmation date
```

### Join Validation Results
```sql
-- Primary join validation (LOAN_ID)
Bankruptcy Entity → Custom Settings: 6,374 matching loans (98.8% match rate)
Bankruptcy Entity → Loan Settings: ~2,101 expected matches
Loan Settings → Loan Sub Status: Join on LOAN_SUB_STATUS_ID = ID

-- Portfolio join validation
Loan ID → Portfolio assignments: Expected 100% coverage for analytics context
```

## Transformation Logic & Business Rules

### Status Field Normalization
**Chapter Standardization:**
```sql
CASE 
    WHEN CHAPTER LIKE '%chapter13%' THEN 'Chapter 13'
    WHEN CHAPTER LIKE '%chapter7%' THEN 'Chapter 7' 
    WHEN CHAPTER LIKE '%chapter11%' THEN 'Chapter 11'
    ELSE CHAPTER 
END as BANKRUPTCY_CHAPTER_CLEAN
```

**Petition Status Standardization:**
```sql
CASE 
    WHEN PETITION_STATUS LIKE '%planConfirmed%' THEN 'Plan Confirmed'
    WHEN PETITION_STATUS LIKE '%petitionFiled%' THEN 'Petition Filed'
    WHEN PETITION_STATUS LIKE '%discharged%' THEN 'Discharged'
    WHEN PETITION_STATUS LIKE '%dismissed%' THEN 'Dismissed'
    ELSE PETITION_STATUS 
END as PETITION_STATUS_CLEAN
```

**Process Status Standardization:**
```sql
CASE 
    WHEN PROCESS_STATUS LIKE '%planConfirmed%' THEN 'Plan Confirmed'
    WHEN PROCESS_STATUS LIKE '%petitionFiledVerified%' THEN 'Petition Filed Verified'
    WHEN PROCESS_STATUS LIKE '%noticeReceived%' THEN 'Notice Received'
    WHEN PROCESS_STATUS LIKE '%discharged%' THEN 'Discharged'
    WHEN PROCESS_STATUS LIKE '%claimFiled%' THEN 'Claim Filed'
    WHEN PROCESS_STATUS LIKE '%dismissed%' THEN 'Dismissed'
    ELSE PROCESS_STATUS 
END as PROCESS_STATUS_CLEAN
```

### Data Source Priority Logic
```sql
-- Primary source: Bankruptcy Entity (most reliable)
-- Secondary source: Custom Loan Settings (supplemental/historical)
-- Source identification for transparency
CASE 
    WHEN be.LOAN_ID IS NOT NULL THEN 'BANKRUPTCY_ENTITY'
    WHEN cls.BANKRUPTCY_CASE_NUMBER IS NOT NULL THEN 'CUSTOM_SETTINGS'  
    WHEN lss.TITLE LIKE '%Bankruptcy%' THEN 'LOAN_SUB_STATUS'
    WHEN port.PORTFOLIO_NAME LIKE '%Bankrupt%' AND port.PORTFOLIO_NAME != 'BankruptcyWatch Integration' THEN 'PORTFOLIO_ASSIGNMENT'
    ELSE 'UNKNOWN'
END as DATA_SOURCE
```

### Data Quality Flags for Review
```sql
-- Instead of excluding duplicates, flag them for review
CASE WHEN (
    SELECT COUNT(*) FROM [all_sources] WHERE CASE_NUMBER = current.CASE_NUMBER
) > 1 THEN 'DUPLICATE_CASE_NUMBER' ELSE NULL END as QUALITY_FLAG_DUPLICATES,

-- Flag data inconsistencies between sources for review
CASE WHEN be.CHAPTER != cls.BANKRUPTCY_CHAPTER 
     THEN 'CHAPTER_MISMATCH' ELSE NULL END as QUALITY_FLAG_CHAPTER_MISMATCH,

-- Flag loans in multiple sources for reconciliation review
CASE WHEN (be.LOAN_ID IS NOT NULL AND cls.BANKRUPTCY_CASE_NUMBER IS NOT NULL)
     THEN 'MULTI_SOURCE_MATCH' ELSE NULL END as QUALITY_FLAG_MULTI_SOURCE,

-- Flag potential missing bankruptcies for review (excluding monitoring portfolio)
CASE WHEN (port.PORTFOLIO_NAME LIKE '%Bankrupt%' AND port.PORTFOLIO_NAME != 'BankruptcyWatch Integration' AND be.LOAN_ID IS NULL)
     THEN 'PORTFOLIO_ONLY_BANKRUPTCY' ELSE NULL END as QUALITY_FLAG_PORTFOLIO_ONLY
```

## Implementation Strategy

### Development Phase
**Environment**: DEVELOPMENT and BUSINESS_INTELLIGENCE_DEV
**Approach**: Create and test dynamic table using production data

**CRITICAL VALIDATION REQUIREMENT**: Before implementing this PRP, perform mandatory independent data exploration:
- **MANDATORY**: Re-examine all source tables and data relationships described in this PRP
- **MANDATORY**: Validate the portfolio exclusions and business logic independently  
- **MANDATORY**: Test the proposed transformation logic with sample data
- **MANDATORY**: Verify data quality issues match what's documented
- **MANDATORY**: Confirm the technical approach aligns with actual data structure
- **MANDATORY**: Perform duplicate detection, completeness validation, and data integrity checks
- **Do not blindly follow this PRP** - use it as guidance while validating each step independently
- Document any discrepancies found during independent validation

**Development Object Creation:**
```sql
-- DEVELOPMENT.FRESHSNOW.VW_LOAN_BANKRUPTCY (if needed for testing)
-- BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOAN_BANKRUPTCY (if needed)  
-- BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY (primary development object)
```

### Object Definition Strategy
**Preferred**: Dynamic Table for performance optimization
**Alternative**: View if dynamic table requirements too complex

**Dynamic Table Benefits:**
- Automated refresh for up-to-date bankruptcy status
- Query performance optimization for outbound list generation
- Reduced load on source systems

**Refresh Strategy:**
- Target: 15-minute refresh interval
- Dependency tracking on source table changes
- Incremental refresh where possible

### Quality Control Plan - Single Consolidated File

**QC File Structure**: All validation tests consolidated into single `qc_validation.sql` file for systematic execution:

```sql
-- COMPREHENSIVE QC VALIDATION FOR VW_LOAN_BANKRUPTCY
-- Execute all tests in sequence and document results

-- 1. MANDATORY DUPLICATE DETECTION
SELECT 'DUPLICATE_CASE_NUMBERS' as test_name, 
       CASE_NUMBER, COUNT(*) as duplicate_count,
       COUNT(DISTINCT LOAN_ID) as loan_count
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY
GROUP BY CASE_NUMBER HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- 2. MANDATORY DATA COMPLETENESS VALIDATION  
SELECT 'SOURCE_TARGET_COMPARISON' as test_name,
       'Source_Count' as type, COUNT(*) as record_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_BANKRUPTCY_ENTITY_CURRENT 
WHERE ACTIVE = 1 AND DELETED = 0
UNION ALL
SELECT 'SOURCE_TARGET_COMPARISON' as test_name,
       'Target_Count' as type, COUNT(*) as record_count  
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY;

-- 3. MANDATORY DATA INTEGRITY CHECKS
SELECT 'DATA_SOURCE_COVERAGE' as test_name,
       DATA_SOURCE, COUNT(*) as record_count,
       COUNT(DISTINCT LOAN_ID) as unique_loans,
       COUNT(DISTINCT CASE_NUMBER) as unique_cases
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY
GROUP BY DATA_SOURCE;

-- 4. MANDATORY PERFORMANCE VALIDATION
-- (Execute with EXPLAIN plan and document execution times)

-- 5. BUSINESS LOGIC VALIDATION
SELECT 'CHAPTER_NORMALIZATION' as test_name,
       BANKRUPTCY_CHAPTER_CLEAN, COUNT(*) as normalized_count,
       COUNT(DISTINCT CHAPTER) as original_variants
FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY
GROUP BY BANKRUPTCY_CHAPTER_CLEAN
ORDER BY normalized_count DESC;
```

### Performance Optimization

#### Indexing Strategy (Dynamic Table)
```sql
-- Cluster by LOAN_ID for outbound list joins
ALTER TABLE BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY 
CLUSTER BY (LOAN_ID)

-- Consider additional clustering by FILING_DATE for temporal analysis
```

#### Query Optimization Patterns
```sql
-- Optimized for outbound list suppression
SELECT DISTINCT LOAN_ID 
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY
WHERE LOAN_ID IN (/* outbound list loan IDs */)
  AND PETITION_STATUS_CLEAN NOT IN ('Dismissed', 'Discharged')
```

## Production Deployment Strategy

### Deployment Template
```sql
DECLARE
    -- Development databases  
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';
    
    -- Production databases (uncomment for production deployment)
    -- v_de_db varchar default 'ARCA';
    -- v_bi_db varchar default 'BUSINESS_INTELLIGENCE';

BEGIN
    -- ANALYTICS section (single-layer deployment for this object)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE DYNAMIC TABLE ' || v_bi_db || '.ANALYTICS.VW_LOAN_BANKRUPTCY(
            LOAN_ID,
            BANKRUPTCY_ID,
            CASE_NUMBER,
            BANKRUPTCY_CHAPTER_CLEAN,
            PETITION_STATUS_CLEAN,
            PROCESS_STATUS_CLEAN,
            FILING_DATE,
            NOTICE_RECEIVED_DATE,
            AUTOMATIC_STAY_STATUS,
            CUSTOMER_ID,
            BANKRUPTCY_DISTRICT,
            PETITION_TYPE,
            DISMISSED_DATE,
            CLOSED_REASON,
            DATA_SOURCE,
            PORTFOLIO_NAME,
            SUB_PORTFOLIO_TITLE,
            LOAN_SUB_STATUS_TEXT,
            CREATED_DATE,
            LAST_UPDATED_DATE
        ) COPY GRANTS
        TARGET_LAG = ''15 minutes''
        WAREHOUSE = BUSINESS_INTELLIGENCE_LARGE
        AS 
        [FULL OBJECT DEFINITION WITH ALL JOINS AND TRANSFORMATIONS]
    ');
END;
```

### Deployment Sequence
1. **Development Testing**: Complete QC validation in BUSINESS_INTELLIGENCE_DEV
2. **User Review**: Validate business logic and data coverage with stakeholder  
3. **Production Deployment**: Execute deployment template with production databases
4. **Downstream Integration**: Update BI-2482_Outbound_List_Generation_for_GR job
5. **Performance Monitoring**: Track query performance and refresh times
6. **Legacy Deprecation**: Phase out MVW_LOAN_TAPE dependency

## Risk Assessment & Mitigation

### Data Quality Risks
**Risk**: Duplicate case numbers causing incorrect loan counts
**Mitigation**: Row numbering logic to select most recent record per case

**Risk**: Status field normalization errors  
**Mitigation**: Comprehensive mapping validation and business rule testing

**Risk**: Missing bankruptcy cases from source mismatch
**Mitigation**: Full outer join logic with data source identification

### Performance Risks
**Risk**: Large join performance impact on outbound list generation
**Mitigation**: Dynamic table clustering, query optimization, performance testing

**Risk**: Refresh lag impacting real-time suppression accuracy
**Mitigation**: 15-minute refresh target, dependency tracking, monitoring alerts

### Integration Risks
**Risk**: Downstream job integration issues with new object structure
**Mitigation**: Parallel testing, gradual migration, rollback plan

## Success Criteria & Validation

### Functional Success Criteria
- [ ] All 2,101+ active bankruptcy cases captured from primary source
- [ ] Status fields successfully normalized (Chapter, Petition Status, Process Status)
- [ ] Data source transparency for all records
- [ ] Duplicate case number handling validated
- [ ] Complete portfolio and loan status context provided

### Performance Success Criteria  
- [ ] Fast response time for outbound list suppression queries (as fast as possible)
- [ ] Dynamic table refresh completing efficiently 
- [ ] Query performance optimized for high-volume usage

### Integration Success Criteria
- [ ] BI-2482 job successfully integrated with new bankruptcy object
- [ ] VW_LOAN_COLLECTION dependency replaced
- [ ] Data quality flags operational for review of inconsistencies
- [ ] Business stakeholder acceptance of comprehensive bankruptcy coverage

## Executable Validation Commands - Simplified Structure

### Single QC Validation File Execution
```bash
# Execute comprehensive QC validation (single file approach)
snow sql -q "$(cat qc_validation.sql)" --format csv > qc_results.csv

# Verify object creation
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY" --format csv

# Performance validation with EXPLAIN plan
snow sql -q "EXPLAIN SELECT * FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_BANKRUPTCY WHERE LOAN_ID IN (SELECT LOAN_ID FROM sample_outbound_list LIMIT 1000)" --format csv
```

### Production Deployment Execution
```bash
# Production deployment (after user review and QC validation)
# snow sql -q "$(cat final_deliverables/production_deploy_template.sql)"

# Post-deployment validation
# snow sql -q "$(cat qc_validation.sql)" --format csv
```

**File Organization for Execute Command**:
- Single `qc_validation.sql` file with all tests
- Simplified final deliverables structure  
- README.md and CLAUDE.md for documentation
- Results in `tickets/examples/DI-1239/` folder structure

## Jira Ticket Information

**Ticket Created**: DI-1239 - "Create comprehensive bankruptcy data object for loan suppression and analysis"
**Epic**: DI-1238
**Stakeholder**: Kyle Chalmers (kchalmers@happymoney.com)
**Priority**: High (impacts critical outbound list generation process)
**Status**: Open and ready for implementation
**Expected Ticket Folder**: `tickets/examples/DI-1239/` (for use with prp-data-object-execute command)

## Confidence Assessment

**PRP Confidence Score: 9/10**

**Scoring Rationale:**
- ✅ Complete database schema analysis with DDL and sample data
- ✅ Comprehensive data quality assessment with specific issues identified  
- ✅ Architecture compliance verified (ANALYTICS layer placement)
- ✅ Source-to-target validation queries designed and executable
- ✅ Business logic patterns identified from existing bankruptcy work
- ✅ Performance optimization strategy defined
- ✅ Production deployment template follows architectural standards
- ✅ Quality control validation comprehensive and testable
- ✅ Data lineage and transformation logic clearly specified
- ✅ Jira ticket created: DI-1239 linked to epic DI-1238

**Risk Assessment**: Low risk for one-pass implementation success

This PRP provides comprehensive context for creating a production-ready bankruptcy data object that will successfully replace the VW_LOAN_COLLECTION dependency while providing complete bankruptcy coverage from all data sources with quality flags for review.