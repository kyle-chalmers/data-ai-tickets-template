# Create Snowflake Data Object PRP

## Data Object Requirements: $ARGUMENTS

Generate a complete PRP for Snowflake data object creation OR modification (views, tables, dynamic tables) with comprehensive database research. Supports both single object and multiple related objects operations. Read the INITIAL.md requirements file first to understand operation type (CREATE_NEW/ALTER_EXISTING), scope (SINGLE_OBJECT/MULTIPLE_RELATED_OBJECTS), business objectives, data grain, sources needed, and integration points. If no Jira ticket exists and CREATE_NEW is specified, create the ticket first using acli.

**Template Reference:** Use `PRPs/templates/data-object-initial.md` as the standard input format for data object requests.

The AI agent only gets the context you provide in the PRP and training data. Include all database research findings, schema relationships, and architectural patterns in the PRP. The Agent has Snow CLI and Websearch capabilities, so reference specific database objects, documentation URLs, and implementation patterns.

## Research Process

1. **Database Schema Analysis**
   - Use Snow CLI to explore existing database objects: `snow sql -q "SHOW TABLES IN SCHEMA schema_name"`
   - If ALTER_EXISTING: Get current object DDL for all objects: `snow sql -q "SELECT GET_DDL('VIEW', 'schema.existing_object')"`
   - If MULTIPLE_RELATED_OBJECTS: Map inter-object dependencies and creation order requirements
   - Identify source tables and views: `snow sql -q "DESCRIBE TABLE schema.table_name"`
   - Map data relationships and dependencies: `snow sql -q "SELECT GET_DDL('VIEW', 'schema.view_name')"`
   - Check existing patterns in similar objects within the 5-layer architecture
   - Validate schema filtering patterns (LMS_SCHEMA(), LOS_SCHEMA())
   - **CRITICAL**: Review sample column values to identify any that need business-friendly transformation

2. **Architecture Compliance**
   - Verify layer-appropriate referencing (FRESHSNOW → BRIDGE → ANALYTICS → REPORTING)
   - Check deployment patterns from `documentation/db_deploy_template.sql`
   - Review existing DDL in `tickets/*/final_deliverables/` for patterns
   - Ensure COPY GRANTS and environment variable usage

3. **Data Quality Assessment**
   - Run sample queries on source tables: `snow sql -q "SELECT COUNT(*) FROM table LIMIT 1000"`
   - Check for duplicates, nulls, data types: `snow sql -q "SELECT DISTINCT column FROM table"`
   - Test all joins between source objects: `snow sql -q "SELECT COUNT(*) FROM table1 t1 LEFT JOIN table2 t2 ON t1.key = t2.key WHERE t2.key IS NULL"`
   - Compare record counts: source vs target object validation
   - **CRITICAL**: For data objects replacing existing references, examine the actual view/table being replaced to understand current structure and ensure comprehensive coverage
   - Make sure data issues that have been found are flagged for review and presented to the end user, prior to them being excluded
   - Include data quality flags for review instead of excluding duplicates and data issues
   - **CRITICAL**: Validate data structure approach (JOIN for attributes vs UNION for entities) with expected record counts
   - **CRITICAL**: Question any filter that significantly reduces available data without clear business justification
   - If ALTER_EXISTING: Compare old vs new data sources with sample queries to identify expected differences
   - If ALTER_EXISTING: Create before/after comparison queries to validate the migration
   - Identify downstream dependencies using `INFORMATION_SCHEMA.TABLE_CONSTRAINTS` and `SHOW DEPENDENT OBJECTS`
   - Test downstream impact: validate dependent views, tables, and reports still function correctly
   - Document data lineage and transformation requirements

4. **Business Context Research**
   - Review similar tickets in repository for business logic patterns
   - Check `documentation/data_business_context.md` for domain knowledge
   - Validate data grain and aggregation requirements from INITIAL.md
   - Map to existing analytics patterns (roll rates, fraud analysis, etc.)
   - Identify compliance/regulatory requirements for financial data
   - Understand end-user personas and reporting needs

5. **Jira Ticket Management**
   - If ticket exists: `acli jira workitem view DI-XXX` to get full context
   - If CREATE_NEW specified: Create ticket using INITIAL.md business context
   - **Default Epic**: DI-1238 (link new tickets to this epic unless specified otherwise)
   - Link to related tickets or epic if applicable
   - Document stakeholder requirements and acceptance criteria

6. **Iterative User Clarification** (REQUIRED)
   - **CRITICAL**: After initial research, raise key questions iteratively to refine the PRP
   - Question any doubts or questionable parts found during analysis
   - Verify data grain interpretation matches business expectations
   - Confirm layer placement based on use cases (FRESHSNOW/BRIDGE/ANALYTICS/REPORTING)
   - Validate performance and refresh requirements
   - Clarify any ambiguous business logic or calculations
   - Ask about specific data quality issues discovered (duplicates, inconsistencies, missing data)
   - Confirm business rules for handling edge cases and data conflicts
   - **CRITICAL**: Present data structure findings and uncertainties to user for validation before finalizing PRP
   - **CRITICAL**: Escalate any QC concerns or questionable data patterns for user clarification
   - Review transformation logic and normalization approaches before finalizing

## PRP Generation

Using PRPs/templates/data-object-initial.md as input template:

### Critical Context to Include and pass to the AI agent as part of the PRP
- **Operation Type**: CREATE_NEW or ALTER_EXISTING with specific requirements and expectations
- **Business Requirements**: Complete INITIAL.md content with data grain, use cases, stakeholders
- **Current State Analysis**: If ALTER_EXISTING, complete DDL and data samples from existing object
- **Database Objects**: Complete DDL of related tables/views with `GET_DDL()` output
- **Schema Relationships**: Table joins, foreign keys, and data lineage mapping with join validation results
- **Architecture Patterns**: Layer-specific referencing rules and `documentation/db_deploy_template.sql` pattern
- **Data Migration Analysis**: If changing sources, before/after comparison and expected differences
- **Data Samples**: Representative data from source tables (first 5-10 rows with business context)
- **Business Logic**: Existing transformation patterns, calculation logic, and KPI definitions
- **Downstream Dependencies**: Complete dependency analysis and impact assessment for existing consumers
- **Development Environment Setup**: Objects created in DEVELOPMENT/BUSINESS_INTELLIGENCE_DEV for testing
- **Jira Context**: Full ticket details, stakeholder requirements, acceptance criteria
- **Performance/Compliance**: Indexing patterns, PII handling, regulatory requirements
- **Documentation URLs**: Snowflake documentation for specific features used

### Implementation Blueprint
- **Operation Strategy**: CREATE_NEW vs ALTER_EXISTING approach and migration plan
- **Scope Strategy**: SINGLE_OBJECT vs MULTIPLE_RELATED_OBJECTS deployment approach
- **Data Architecture Design**: Which layer(s) the objects belong in and why
- **Object Dependency Mapping**: If multiple objects, document inter-dependencies and creation order
- **Current State Preservation**: If ALTER_EXISTING, document current object structures and behavior
- **Source Table Analysis**: Detailed breakdown of input tables and relationships
- **Migration Analysis**: If changing sources, detailed comparison of old vs new data sources
- **Transformation Logic**: Business rules, calculations, filtering, aggregations for each object
- **Development Phase**: Create objects in DEVELOPMENT and BUSINESS_INTELLIGENCE_DEV using production data
- **CRITICAL VALIDATION REQUIREMENT**: Include explicit instruction for implementer to perform independent data exploration and validation before following PRP guidance
- **DATA GRAIN AND DEDUPLICATION ANALYSIS**: For sources containing historical or time-series data, require thorough exploration:
  - **Mandatory Investigation**: Analyze record counts vs unique identifiers to detect potential duplicates
  - **Grain Analysis**: Determine the correct business grain and identify appropriate deduplication strategies
  - **Time-Series Considerations**: Explore date/timestamp patterns and determine current vs historical record requirements
  - **Validation First**: Always implement duplicate detection as the primary QC test to surface data quality issues early
- **Sequential vs Parallel Development**: Strategy for multiple objects creation/deployment
- **Before/After Testing**: If ALTER_EXISTING, comprehensive comparison between current and new implementation
- **Join Validation**: Comprehensive testing of all table joins and relationship integrity
- **Cross-Object Validation**: If multiple objects, test relationships between created objects
- **Downstream Impact Analysis**: Identify and test all dependent objects with migration scenarios
- **Quality Control Plan**: Single consolidated `qc_validation.sql` file with all mandatory tests (duplicate detection, completeness, integrity, performance)
- **Performance Optimization**: Query optimization strategies (avoid strict time metrics, focus on "as fast as possible")
- **Production Deployment Strategy**: Use `documentation/db_deploy_template.sql` for final deployment with proper sequencing
- **File Organization**: Align with execute command requirements - single QC file, simplified deliverables, README.md + CLAUDE.md structure
- **Task Order**: Analysis → Independent Validation → Development → Testing → Cross-Object Validation → Comparison → User Review → Production Deployment

### Validation Gates (Must be Executable for the specific data object(s))
```bash
# Development Environment Object Creation
snow sql -q "DESCRIBE DEVELOPMENT.[SCHEMA].[OBJECT_NAME]" --format csv
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.[SCHEMA].[OBJECT_NAME]" --format csv

# Comprehensive QC Validation (all tests in single file)
snow sql -q "$(cat qc_validation.sql)" --format csv

# Performance Validation
snow sql -q "EXPLAIN $(cat final_deliverables/1_data_object_creation.sql)" --format csv

# Production Deployment Readiness (after user review)
# snow sql -q "$(cat final_deliverables/2_production_deploy_template.sql)"
```

**Simplified Validation Approach:**
- **Single QC File**: All validation tests consolidated in `qc_validation.sql`
- **Comprehensive Testing**: Includes duplicate detection, completeness, integrity, performance, and comparison testing
- **Executable Commands**: All validation gates can be run with simple Snow CLI commands

*** CRITICAL AFTER YOU ARE DONE RESEARCHING AND EXPLORING THE CODEBASE ***

*** BEFORE WRITING THE PRP: ASK KEY QUESTIONS TO THE USER ***
- Present your findings and raise any doubts or questionable parts
- Ask about data quality issues, business rules, and edge case handling
- Validate your understanding of requirements and transformation logic
- Get confirmation on approach before proceeding with PRP generation

*** AFTER USER FEEDBACK: ULTRATHINK ABOUT THE PRP AND PLAN YOUR APPROACH THEN START WRITING THE PRP ***

## Output Structure

### PRP Document Location
Save as: `PRPs/snowflake-data-object-{object-name}.md` **in the same folder as INITIAL.md file**

### Expected Ticket Folder Reference
**CRITICAL**: Include explicit ticket folder reference in PRP for execute command compatibility:
- **Expected Ticket Folder**: `tickets/[username]/DI-XXX/` 
- This ensures seamless integration with prp-data-object-execute command
- Use actual username (e.g., kchalmers) and ticket number from created ticket

## Quality Checklist
- [ ] Operation type clearly identified (CREATE_NEW/ALTER_EXISTING) with appropriate strategy
- [ ] Scope clearly identified (SINGLE_OBJECT/MULTIPLE_RELATED_OBJECTS) with deployment approach
- [ ] If MULTIPLE_RELATED_OBJECTS: Inter-object dependencies mapped with creation/deployment order
- [ ] Complete database schema analysis with DDL and sample data included for all objects
- [ ] If ALTER_EXISTING: Current state documented with baseline queries and expected changes
- [ ] Architecture compliance verified (5-layer referencing rules) for all objects
- [ ] All source tables and relationships documented with Snow CLI output
- [ ] Join validation tests created and executable for all table relationships
- [ ] If MULTIPLE_RELATED_OBJECTS: Cross-object relationship validation queries created
- [ ] If ALTER_EXISTING: Before/after comparison queries created for data migration validation
- [ ] Downstream dependency analysis completed with migration impact assessment
- [ ] Development environment objects created in DEVELOPMENT/BUSINESS_INTELLIGENCE_DEV
- [ ] Source-to-target data validation queries executable and documented
- [ ] Business logic patterns identified from existing tickets
- [ ] Quality control validation queries are executable with comprehensive testing
- [ ] Production deployment template follows `documentation/db_deploy_template.sql` pattern with proper sequencing
- [ ] Performance optimization considerations documented for all objects (focus on "as fast as possible", avoid strict time metrics)
- [ ] Data lineage and transformation logic clearly specified
- [ ] Error handling and edge cases covered
- [ ] References specific database objects and existing patterns
- [ ] Explicit instructions for implementer to perform independent data exploration before following PRP
- [ ] Clear guidance to not blindly follow PRP but validate each step independently
- [ ] Expected ticket folder reference included for execute command compatibility
- [ ] Single QC validation file structure specified for systematic testing
- [ ] Portfolio exclusions and business logic clearly documented with examples

## Confidence Assessment
Score the PRP on a scale of 1-10 (confidence level for one-pass Snowflake data object creation):

**Scoring Criteria:**
- 8-10: Complete database context, clear architecture compliance, executable validation
- 6-7: Good database research, some missing context or validation gaps  
- 4-5: Basic research, unclear requirements or incomplete architecture analysis
- 1-3: Insufficient database context, missing critical information for implementation

**Target Score: 8+ for production data object creation**

Remember: The goal is one-pass implementation success with production-ready Snowflake objects that follow architectural standards and pass quality validation.