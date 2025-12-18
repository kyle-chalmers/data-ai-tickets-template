# Execute Data Object Product Requirements Prompt (PRP)

## PRP File: $ARGUMENTS

Execute a comprehensive data object creation or modification following the provided PRP. This command handles both single and multiple related objects with full development-to-production workflow.

## Prerequisites

This command references configuration from your repository's CLAUDE.md. If not specified, defaults are used:
- **Database CLI:** As specified in CLAUDE.md, or defaults to `snow` CLI for Snowflake
- **Ticketing CLI:** As specified in CLAUDE.md, or defaults to `acli` for Jira
- **Dev/Prod Databases:** Development and production database/schema names from CLAUDE.md
- **Architecture Layers:** Your data architecture pattern from CLAUDE.md (optional)

**Expected PRP Format:** Generated using `/generate-data-object-prp` command with complete database research and validation requirements.

## Execution Process

### Phase 1: PRP Analysis and Setup
1. **Read and validate PRP completeness**
   - Verify all critical context sections are present
   - Confirm operation type (CREATE_NEW/ALTER_EXISTING) and scope (SINGLE/MULTIPLE_RELATED_OBJECTS)
   - Validate database research findings and architectural compliance

2. **Environment Setup**
   - Create ticket folder structure following standards: `tickets/[user]/[TICKET-ID]/`
   - Initialize development environment connections (your development database/schema)
   - Use TodoWrite tool to create comprehensive task tracking list
   - Prepare simplified QC validation structure

3. **Dependency Analysis**
   - If MULTIPLE_RELATED_OBJECTS: Map creation order and dependencies
   - If ALTER_EXISTING: Document current state and migration requirements
   - Validate downstream impact analysis

### Phase 2: Development Implementation
1. **Database Object Creation (Development Environment)**
   - Create objects in your development database/schema
   - Follow architecture compliance as defined in your CLAUDE.md
   - Use production data for realistic testing
   - Implement proper schema filtering as defined in your data catalog
   - **CRITICAL**: Verify all column values are business-ready and data structure matches expected grain

2. **Quality Control Implementation - CRITICAL**
   - **STEP 1 - CREATE OBJECT FIRST**: Always create the actual development object using production data BEFORE writing QC validation
   - **STEP 2 - PERMISSION TROUBLESHOOTING**: If permission errors occur, systematically explore available roles and schemas:
     - Test different database roles and document permission constraints
     - Work within available permissions rather than stopping execution
     - Never proceed with QC until actual object is successfully created
   - **STEP 3 - QC THE ACTUAL OBJECT**: Write `qc_validation.sql` to validate the ACTUAL development object, not source tables
   - **QC Target**: All validation queries must reference the created development object
   - **MANDATORY DUPLICATE TESTING**: Check for duplicate records in the development object with detailed analysis
     - **CRITICAL EXPLORATION**: Investigate any duplicate records to understand root cause and implement appropriate solutions
     - **DATA GRAIN ANALYSIS**: Ensure implementation matches intended business grain through thorough data exploration
   - **MANDATORY COMPLETENESS VALIDATION**: Verify all expected records are present in the development object
   - **MANDATORY DATA INTEGRITY CHECKS**: Validate referential integrity and business rules in the development object
   - **MANDATORY PERFORMANCE TESTING**: Ensure development object queries run efficiently with acceptable response times
   - **QC QUERY FORMAT**: Use clean, functional queries with test identifiers in comments (e.g., `--1.1: Test Name`) not in SELECT statements
   - **CONSOLIDATE QC QUERIES**: Group related tests to minimize number of queries for easier execution
   - **CRITICAL QC ESCALATION**: If any QC uncertainties or data quality concerns arise, present findings to user for clarification before proceeding
   - Execute all validation gates from PRP against the development object with comprehensive documentation
   - If ALTER_EXISTING: **CRITICAL** - Compare new vs existing object data with diff analysis
   - If MULTIPLE_RELATED_OBJECTS: Test cross-object relationships and dependencies
   - Validate join integrity and business logic with explicit validation queries against development objects

3. **Performance Optimization**
   - Execute EXPLAIN plans for all objects
   - Optimize query performance while maintaining correctness
   - Test optimized queries against original results using `diff`

### Phase 3: Validation and Documentation
1. **Comprehensive Testing - CRITICAL AND MANDATORY**
   - **DUPLICATE ANALYSIS**: Explicit duplicate detection with counts and examples
   - **DATA COMPLETENESS**: Record count validation and missing data analysis
   - **DATA INTEGRITY**: Referential integrity checks and constraint validation
   - **PERFORMANCE VALIDATION**: Query execution time analysis and optimization verification
   - **COMPARISON TESTING**: If replacing existing object, side-by-side data comparison
   - Source-to-target data validation with detailed reconciliation
   - Downstream dependency testing with impact analysis
   - Migration impact assessment (if applicable)
   - Business logic validation with test cases
   - Performance benchmarking against requirements

2. **Documentation Generation - Human-Focused**
   - **Simple README.md**: Clear, concise summary for human reviewers (no technical jargon)
   - **CLAUDE.md**: Complete context file for future AI assistance with this data object
   - Document all QC results with pass/fail status and specific findings
   - **File Consolidation**: Update/overwrite outdated files, eliminate redundancy
   - Number final deliverables only: `1_[description].sql`, `2_[description].csv`
   - Create production deployment template using your deployment pattern

### Phase 4: Production Readiness
1. **Final Validation**
   - Run complete validation suite in development environment
   - Verify all objects function correctly with expected data
   - Confirm architectural compliance and performance requirements
   - Validate all downstream dependencies remain functional

2. **Production Deployment Preparation**
   - Generate production deployment script using variable templates
   - Create rollback procedures if modifying existing objects
   - Prepare stakeholder communication and deployment timeline
   - Document any breaking changes or migration requirements

3. **[OPTIONAL] Ticket Transition**
   - If ticketing system configured: Transition ticket status appropriately
   - Assign ticket to the user who issued the command
   - Add completion comment with deliverable summary (keep concise)
   - *Skip this section if ticketing system not configured*

## Success Criteria

### Technical Requirements
- [ ] All objects successfully created in development environments
- [ ] Complete QC validation suite passes with documented results
- [ ] Performance requirements met with optimized queries
- [ ] Architecture compliance verified
- [ ] All downstream dependencies tested and functional

### Quality Assurance - MANDATORY VALIDATION
- [ ] **DUPLICATE TESTING COMPLETE**: Explicit duplicate analysis with documented results
- [ ] **DATA COMPLETENESS VERIFIED**: All expected records present with count reconciliation
- [ ] **DATA INTEGRITY VALIDATED**: Referential integrity and constraint checks pass
- [ ] **PERFORMANCE REQUIREMENTS MET**: Query execution times within acceptable limits
- [ ] **COMPARISON ANALYSIS COMPLETE**: If replacing existing, detailed before/after comparison
- [ ] Source-to-target data validation confirms 100% accuracy
- [ ] Join integrity tests pass for all table relationships with documented results
- [ ] Business logic validation confirms expected calculations with test cases
- [ ] If ALTER_EXISTING: Migration analysis shows expected changes only with diff documentation
- [ ] If MULTIPLE_RELATED_OBJECTS: Cross-object relationships validated with dependency testing

### Documentation and Delivery - Human-Optimized
- [ ] **Simple README.md**: Clear, concise business summary (no technical jargon)
- [ ] **CLAUDE.md created**: Complete context file for future AI assistance
- [ ] **File consolidation complete**: Outdated files updated/removed, no redundancy
- [ ] **Final deliverables only**: Only essential numbered files remain
- [ ] Production deployment template ready for execution
- [ ] QC results documented with pass/fail status and specific findings
- [ ] File organization optimized for human review and understanding

### Architecture and Compliance
- [ ] Objects follow proper layer referencing rules
- [ ] Schema filtering implemented correctly as defined in data catalog
- [ ] COPY GRANTS and environment variables used appropriately (if applicable)
- [ ] Deployment strategy accounts for proper sequencing

## Output Structure - Simplified and Clean

```
tickets/[user]/[TICKET-ID]/
├── README.md                    # Simple business summary for human reviewers
├── CLAUDE.md                    # Complete technical context for future AI assistance
├── final_deliverables/          # Essential deliverables only
│   ├── 1_data_object_creation.sql
│   ├── 2_production_deploy_template.sql
│   └── 3_validation_summary.csv
├── qc_validation.sql            # Single comprehensive QC validation file
└── source_materials/            # PRP and reference materials only
```

**Simplified Approach:**
- **Single QC File**: All validation tests consolidated into `qc_validation.sql`
- **Essential Files Only**: Remove development artifacts and working files
- **Human-Optimized**: Clear structure for review and understanding
- **CLAUDE.md**: Complete technical context for future AI assistance

## Error Handling and Fallback

1. **Database Connection Issues**
   - Verify database CLI authentication status
   - Check database and schema permissions
   - Provide clear error messages with resolution steps

2. **PRP Validation Failures**
   - Identify missing critical context sections
   - Request additional database research if needed
   - Validate architectural compliance before proceeding

3. **Quality Control Failures**
   - Document specific QC failures with detailed analysis
   - Provide recommended remediation steps
   - Do not proceed to production without QC validation

4. **Performance Issues**
   - Document performance bottlenecks with EXPLAIN output
   - Provide optimization recommendations
   - Consider alternative approaches if performance targets not met

## Security and Compliance

- **PII Handling**: Ensure proper data masking and access controls
- **Schema Filtering**: Validate schema filtering as defined in your data catalog
- **Regulatory Compliance**: Follow your organization's data requirements
- **Access Control**: Use COPY GRANTS to preserve existing permissions (if applicable)

## Final Notes

- **Development First**: Always create and test in development environments before production
- **Quality Gates**: All validation must pass before production deployment
- **Stakeholder Review**: Present development results for approval before production deployment
- **Rollback Planning**: Have rollback procedures ready for any production changes

## CRITICAL VALIDATION REQUIREMENTS

**MANDATORY TESTS - DO NOT PROCEED WITHOUT:**

1. **DUPLICATE DETECTION**: Explicit duplicate analysis with counts and sample records
2. **DATA COMPLETENESS**: Full record count reconciliation between source and target
3. **DATA INTEGRITY**: Referential integrity checks and constraint validation
4. **PERFORMANCE VALIDATION**: Query execution time analysis within acceptable limits
5. **COMPARISON TESTING**: If altering existing objects, detailed before/after comparison

**FILE ORGANIZATION REQUIREMENTS:**

- **Simple README.md**: Business summary for human reviewers (no technical jargon)
- **CLAUDE.md**: Complete technical context for future AI assistance
- **Single QC File**: All validation tests in `qc_validation.sql`
- **File Consolidation**: Update/overwrite outdated files, eliminate redundancy
- **Essential deliverables only**: Remove development artifacts and working files

**TODOWRITE INTEGRATION:**
- Use TodoWrite tool to create comprehensive task tracking throughout execution
- Mark tasks as in_progress, completed as work progresses
- Ensure systematic completion of all validation requirements

This command ensures comprehensive, quality-assured data object implementation with mandatory validation requirements, simplified file organization, and systematic task tracking.
