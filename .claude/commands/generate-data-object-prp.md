# Create Snowflake Data Object PRP

## Data Object Requirements: $ARGUMENTS

Generate a complete PRP for Snowflake data object creation (views, tables, dynamic tables) with comprehensive database research. Read the INITIAL.md requirements file first to understand business objectives, data grain, sources needed, and integration points. If no Jira ticket exists and CREATE_NEW is specified, create the ticket first using acli.

**Template Reference:** Use `PRPs/templates/data-object-initial.md` as the standard input format for data object requests.

The AI agent only gets the context you provide in the PRP and training data. Include all database research findings, schema relationships, and architectural patterns in the PRP. The Agent has Snow CLI and Websearch capabilities, so reference specific database objects, documentation URLs, and implementation patterns.

## Research Process

1. **Database Schema Analysis**
   - Use Snow CLI to explore existing database objects: `snow sql -q "SHOW TABLES IN SCHEMA schema_name"`
   - Identify source tables and views: `snow sql -q "DESCRIBE TABLE schema.table_name"`
   - Map data relationships and dependencies: `snow sql -q "SELECT GET_DDL('VIEW', 'schema.view_name')"`
   - Check existing patterns in similar objects within the 5-layer architecture
   - Validate schema filtering patterns (LMS_SCHEMA(), LOS_SCHEMA())

2. **Architecture Compliance**
   - Verify layer-appropriate referencing (FRESHSNOW → BRIDGE → ANALYTICS → REPORTING)
   - Check deployment patterns from `documentation/db_deploy_template.sql`
   - Review existing DDL in `tickets/*/final_deliverables/` for patterns
   - Ensure COPY GRANTS and environment variable usage

3. **Data Quality Assessment**
   - Run sample queries on source tables: `snow sql -q "SELECT COUNT(*) FROM table LIMIT 1000"`
   - Check for duplicates, nulls, data types: `snow sql -q "SELECT DISTINCT column FROM table"`
   - Validate business logic with existing QC patterns
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
   - Link to related tickets or epic if applicable
   - Document stakeholder requirements and acceptance criteria

6. **User Clarification** (if needed)
   - Verify data grain interpretation matches business expectations
   - Confirm layer placement based on use cases (FRESHSNOW/BRIDGE/ANALYTICS/REPORTING)
   - Validate performance and refresh requirements
   - Clarify any ambiguous business logic or calculations

## PRP Generation

Using PRPs/templates/prp_base.md as template:

### Critical Context to Include and pass to the AI agent as part of the PRP
- **Business Requirements**: Complete INITIAL.md content with data grain, use cases, stakeholders
- **Database Objects**: Complete DDL of related tables/views with `GET_DDL()` output
- **Schema Relationships**: Table joins, foreign keys, and data lineage mapping  
- **Architecture Patterns**: Layer-specific referencing rules and deployment templates
- **Data Samples**: Representative data from source tables (first 5-10 rows with business context)
- **Business Logic**: Existing transformation patterns, calculation logic, and KPI definitions
- **Jira Context**: Full ticket details, stakeholder requirements, acceptance criteria
- **Performance/Compliance**: Indexing patterns, PII handling, regulatory requirements
- **Documentation URLs**: Snowflake documentation for specific features used

### Implementation Blueprint
- **Data Architecture Design**: Which layer(s) the object belongs in and why
- **Source Table Analysis**: Detailed breakdown of input tables and relationships
- **Transformation Logic**: Business rules, calculations, filtering, aggregations
- **Deployment Strategy**: Multi-environment deployment using variable templates
- **Quality Control Plan**: Validation queries and data quality checks
- **Performance Optimization**: Query optimization and execution strategies
- **Task Order**: Sequential implementation steps from research to deployment

### Validation Gates (Must be Executable for the specific data object)
```bash
# Object Creation Validation
snow sql -q "DESCRIBE [SCHEMA].[OBJECT_NAME]" --format csv

# Data Integrity Check  
snow sql -q "SELECT COUNT(*) as total_records FROM [SCHEMA].[OBJECT_NAME]" --format csv

# Business Logic Validation
snow sql -q "$(cat qc_queries/business_logic_validation.sql)" --format csv

# Performance Check
snow sql -q "SELECT COUNT(*) FROM [SCHEMA].[OBJECT_NAME] WHERE [KEY_FILTER]" --format csv

# Architecture Compliance
snow sql -q "SELECT GET_DDL('VIEW', '[SCHEMA].[OBJECT_NAME]')" --format csv
```

*** CRITICAL AFTER YOU ARE DONE RESEARCHING AND EXPLORING THE CODEBASE BEFORE YOU START WRITING THE PRP ***

*** ULTRATHINK ABOUT THE PRP AND PLAN YOUR APPROACH THEN START WRITING THE PRP ***

## Output
Save as: `PRPs/snowflake-data-object-{object-name}.md`

## Quality Checklist
- [ ] Complete database schema analysis with DDL and sample data included
- [ ] Architecture compliance verified (5-layer referencing rules)  
- [ ] All source tables and relationships documented with Snow CLI output
- [ ] Business logic patterns identified from existing tickets
- [ ] Quality control validation queries are executable
- [ ] Deployment strategy includes dev/prod environment handling
- [ ] Performance optimization considerations documented
- [ ] Data lineage and transformation logic clearly specified
- [ ] Error handling and edge cases covered
- [ ] References specific database objects and existing patterns

## Confidence Assessment
Score the PRP on a scale of 1-10 (confidence level for one-pass Snowflake data object creation):

**Scoring Criteria:**
- 8-10: Complete database context, clear architecture compliance, executable validation
- 6-7: Good database research, some missing context or validation gaps  
- 4-5: Basic research, unclear requirements or incomplete architecture analysis
- 1-3: Insufficient database context, missing critical information for implementation

**Target Score: 8+ for production data object creation**

Remember: The goal is one-pass implementation success with production-ready Snowflake objects that follow architectural standards and pass quality validation.