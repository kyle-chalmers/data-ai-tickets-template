# Task Completion Requirements

## Quality Control (MANDATORY)
Every finalized query MUST have explicit QC todo items:
1. "Run and debug finalized query - fix any errors"
2. "Execute quality control checks and self-correct issues"  
3. "Optimize query for performance and re-test"
4. "Validate data quality and record counts"

## QC Validation Must Include:
- **Filter Verification**: Validate all WHERE clauses and schema filters
- **Duplicate Detection**: Check for and explain duplicate records
- **Business Logic Validation**: Verify calculations and business rules
- **Record Count Reconciliation**: Compare input vs output counts
- **Join Validation**: Verify join conditions and unmatched records

## File Organization Standards
- **Update, Don't Create**: Always overwrite existing files rather than create versions
- **Numbered Deliverables**: All final outputs numbered in logical review order
- **Archive Versions**: Move development iterations to archive_versions/
- **Clean Structure**: Minimal folders, avoid unnecessary complexity

## Documentation Requirements
- **Complete README.md**: Business context and ALL assumptions documented
- **Quality Control Results**: Document specific validation steps
- **Performance Metrics**: Document optimization results where applicable

## Deployment Checklist
- [ ] All QC scripts executed and documented
- [ ] Performance optimization completed and tested
- [ ] Documentation comprehensive and business-focused
- [ ] Files organized and numbered for review
- [ ] Original code backed up when modifying database objects