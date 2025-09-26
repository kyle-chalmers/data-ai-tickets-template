# CLAUDE.md - DI-1272 Context & Implementation Guide

## Project Summary
**DI-1272: Enhanced VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT with 188 Missing CUSTOM_FIELD_VALUES**

This ticket enhanced the VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT view by adding 188 missing fields from CUSTOM_FIELD_VALUES, with special focus on bankruptcy-related analytics. The enhancement increases field coverage from 276 fields (62.8%) to 464 fields (100% of practical fields).

## Key Implementation Details

### What Was Done
1. **Extracted Current Production DDL**: Retrieved existing view structure with 276 fields
2. **Analyzed CUSTOM_FIELD_VALUES**: Identified all 441 available fields in JSON object
3. **Field Gap Analysis**: Found 188 missing fields (42.6% of available data)
4. **Enhanced DDL Creation**: Built comprehensive DDL with all 464 fields
5. **Deployment Script**: Created 5-layer architecture deployment
6. **QC Validation**: Developed 25+ comprehensive validation queries
7. **Bankruptcy Field Focus**: Documented all bankruptcy-related fields for analytics

### Critical Technical Requirements
- **Schema Filtering**: ALL fields MUST use `schema_name = ARCA.config.lms_schema()` for LMS data only
- **Data Type Casting**: Use `TRY_CAST(...::VARCHAR AS [TYPE])` for error handling
- **5-Layer Architecture**: Deploy across FRESHSNOW → BRIDGE → ANALYTICS
- **Backward Compatibility**: All existing 276 fields maintain exact structure

### Bankruptcy Field Analysis (Special Focus)
**Existing Bankruptcy Fields (11)**:
- BANKRUPTCYCASENUMBER, BANKRUPTCYCOURTDISTRICT, BANKRUPTCYFILINGDATE
- BANKRUPTCYFLAG, BANKRUPTCYNOTIFICATIONRECEIVEDDATE, BANKRUPTCYSTATUS
- BANKRUPTCYVENDOR, BANKRUPTCY_ORDERED_* fields (4 court-ordered fields)

**New Bankruptcy Fields (2)**:
- **BANKRUPTCYBALANCE**: Outstanding debt amount for recovery analytics
- **BANKRUPTCYCHAPTER**: Chapter 7/13 classification for legal proceedings

## File Structure & Purpose

### Final Deliverables (Production Ready)
- **`1_enhanced_view_ddl.sql`**: Complete DDL with all 464 fields
- **`2_deployment_script.sql`**: Production deployment script with environment variables
- **`3_qc_validation_queries.sql`**: 25+ comprehensive validation queries

### Source Materials
- **`current_production_ddl.sql`**: Original production DDL (276 fields) - BASELINE
- **`all_available_fields.csv`**: Complete list of 441 available fields
- **`currently_parsed_fields.txt`**: Current 276 parsed fields
- **`missing_fields.txt`**: 188 missing fields identified

### Supporting Files
- **`README.md`**: Complete project documentation with bankruptcy analysis
- **`jira_ticket_request.txt`**: Business justification and technical specs
- **`create_jira_ticket.sh`**: Script for ticket creation (if needed)

## Key Field Categories Added (188 New Fields)

1. **Fraud Investigation (42 fields)**: FRAUD_JIRA_TICKET1-20, FRAUD_STATUS_RESULTS1-20, FRAUD_TYPE
2. **Attorney Management (6 fields)**: ATTORNEY_ORGANIZATION, ATTORNEY_PHONE2-3, ATTORNEY_STREET1-3
3. **Loan Modifications (25 fields)**: LOAN_MOD_EFFECTIVE_DATE, MOD_IN_PROGRESS, etc.
4. **System Integration (15 fields)**: CLS_CLEARING_DATE, REVERSAL_TRANSACTION_DATE_TIME
5. **Legal & Compliance (30 fields)**: DCA_START_DATE, PROOF_OF_CLAIM_DEADLINE_DATE
6. **Enhanced Analytics (12 fields)**: HAPPY_SCORE, LATEST_BUREAU_SCORE, US_CITIZENSHIP

## Data Type Strategy
- **Date Fields (~60)**: `TRY_CAST(...::VARCHAR AS DATE)`
- **Numeric Fields (~45)**: `TRY_CAST(...::VARCHAR AS NUMERIC(30,2))`
- **Text Fields (~83)**: Direct VARCHAR casting
- **All fields use TRY_CAST** for error handling

## Quality Control Approach
The QC validation covers:
1. **Field Count Validation**: Ensure 464 fields in all layers
2. **Schema Filtering**: Verify LMS schema only
3. **New Field Access**: Test all 188 new fields are accessible
4. **Data Type Casting**: Validate date/numeric casting works
5. **Layer Consistency**: FRESHSNOW/BRIDGE/ANALYTICS match
6. **Business Logic**: Field relationships and correlations
7. **Performance**: Query execution time monitoring

## Business Impact & Analytics Use Cases

### Bankruptcy Analytics Workflow
1. **Pre-Filing**: BANKRUPTCY_NOTIFICATION_RECEIVED_DATE, ATTORNEY_RETAINED
2. **Filing**: BANKRUPTCY_FILING_DATE, BANKRUPTCY_CASE_NUMBER, BANKRUPTCY_CHAPTER
3. **Court Orders**: BANKRUPTCY_ORDERED_* fields (amount, rate, payments)
4. **Management**: BANKRUPTCY_STATUS, BANKRUPTCY_BALANCE, BANKRUPTCY_FLAG
5. **Resolution**: DISCHARGE_DATE, DISMISSAL_DATE

### Key Analytics Applications
- **Risk Assessment**: Bankruptcy rate analysis, recovery projections
- **Compliance Monitoring**: Court order compliance, SCRA interactions
- **Financial Impact**: Loss recognition, settlement vs bankruptcy comparison
- **Fraud Detection**: Enhanced investigation tracking with Jira integration

## Deployment Considerations

### Pre-Deployment
1. **Backup current view** - Already saved in `current_production_ddl.sql`
2. **Verify schema access** - Ensure `ARCA.config.lms_schema()` function available
3. **Permission validation** - Check COPY GRANTS across layers

### Deployment Process
1. **Dev Environment First**: Test with DEVELOPMENT/BUSINESS_INTELLIGENCE_DEV
2. **Production Variables**: Switch to ARCA/BUSINESS_INTELLIGENCE in script
3. **Layer Sequence**: FRESHSNOW → BRIDGE → ANALYTICS

### Post-Deployment Validation
1. **Run QC queries** in `3_qc_validation_queries.sql`
2. **Field count verification** - Should be 464 in all layers
3. **Performance monitoring** - Track execution times
4. **Business validation** - Test bankruptcy analytics use cases

## Common Patterns & Conventions

### Field Naming
- Exact CUSTOM_FIELD_VALUES JSON keys used
- Consistent with existing 276 field naming
- Business-friendly aliases (e.g., TEN_DAY_PAYOFF for 10DAYPAYOFF)

### SQL Patterns
```sql
-- Date fields
TRY_CAST(CUSTOM_FIELD_VALUES:FIELDNAME::VARCHAR AS DATE) AS FIELD_NAME

-- Numeric fields
TRY_CAST(CUSTOM_FIELD_VALUES:FIELDNAME::VARCHAR AS NUMERIC(30,2)) AS FIELD_NAME

-- Text fields
CUSTOM_FIELD_VALUES:FIELDNAME::VARCHAR AS FIELD_NAME
```

### Schema Filter (CRITICAL)
```sql
WHERE cs.schema_name = ARCA.config.lms_schema()
  AND le.schema_name = ARCA.config.lms_schema()
```

## Jira Ticket Status
- **Ticket**: DI-1272
- **Assignee**: Kyle Chalmers (kchalmers@happymoney.com)
- **Status**: In Spec
- **Parent Epic**: DI-1238 (Data Object Alteration)
- **URL**: https://happymoneyinc.atlassian.net/browse/DI-1272

## Git Information
- **Branch**: di-1262_and_di-1272
- **Pull Request**: https://github.com/HappyMoneyInc/data-intelligence-tickets/pull/39
- **Commit**: Semantic commit with co-authoring (Claude Code)

## Future Considerations
1. **Performance Monitoring**: Track query execution with 68% more fields
2. **Business Adoption**: Monitor use of new fraud/bankruptcy analytics
3. **Data Quality**: Validate population rates of new fields over time
4. **Additional Enhancements**: May identify more fields as business needs evolve

## Troubleshooting Common Issues

### Schema Filter Problems
- **Issue**: Non-LMS schema records appearing
- **Solution**: Verify `ARCA.config.lms_schema()` function and filtering

### Data Type Casting Errors
- **Issue**: TRY_CAST failures
- **Solution**: Check field naming and data format in source

### Performance Issues
- **Issue**: Slow query execution
- **Solution**: Monitor and consider indexed views if needed

### Missing Fields
- **Issue**: New fields return NULL
- **Solution**: Verify field exists in CUSTOM_FIELD_VALUES JSON

---

**This CLAUDE.md provides complete context for understanding and maintaining DI-1272 implementation. All technical details, business context, and deployment procedures are documented for future reference.**