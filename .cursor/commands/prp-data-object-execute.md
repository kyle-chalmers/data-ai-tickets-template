# Execute Data Object Product Requirements Prompt (PRP)

Execute a data object creation or modification following the provided PRP. Handles single and multiple related objects with full development-to-production workflow.

**Argument**: The PRP file path. If the user types text after `/prp-data-object-execute`, that is the path to the PRP file (e.g., `/prp-data-object-execute videos/prp_data_object_video/PRPs/01_simple_tpch/snowflake-data-object-customer-order-summary.md`).

## Prerequisites

References CLAUDE.md for Database CLI, Ticketing CLI, Dev/Prod databases, Architecture layers.

**Expected PRP Format:** Generated using `/generate-data-object-prp` with complete database research.

## Execution Process

### Phase 1: PRP Analysis and Setup
1. Read and validate PRP completeness.
2. **Ticket Creation (MANDATORY FIRST)** – Create Jira ticket if CREATE_NEW; verify if existing. Use `acli`. Transition to "In Progress". Record ticket key.
3. **Environment Setup** – Create `tickets/[username]/[TICKET-ID]/` with actual ticket key. Use TodoWrite for task tracking.
4. **Dependency Analysis** – Map creation order if MULTIPLE_RELATED_OBJECTS; document migration if ALTER_EXISTING.

### Phase 2: Development Implementation
1. **Database Object Creation** – Create objects in dev database/schema. Follow architecture, schema filtering. Verify column values and grain.
2. **Quality Control (CRITICAL)** – CREATE OBJECT FIRST, then write qc_validation.sql against the actual object. Mandatory: duplicate testing, completeness, integrity, performance. QC queries in comments (e.g., `--1.1: Test Name`). Escalate uncertainties to user.
3. **Performance Optimization** – EXPLAIN plans, optimize, test with diff.

### Phase 3: Validation and Documentation
1. **Comprehensive Testing** – Duplicate analysis, data completeness, integrity, performance, comparison (if replacing).
2. **Documentation** – Simple README.md, CLAUDE.md, QC results, file consolidation, numbered deliverables only, production deploy template.

### Phase 4: Production Readiness
1. Final validation, production deployment preparation, rollback procedures.
2. Ticket completion comment via acli (<100 words). Do NOT transition to Done until user approves production deployment.

## Output Structure

```
tickets/[user]/[TICKET-ID]/
├── README.md
├── CLAUDE.md
├── final_deliverables/
│   ├── 1_data_object_creation.sql
│   ├── 2_production_deploy_template.sql
│   └── 3_validation_summary.csv
├── qc_validation.sql
└── source_materials/
```

## Mandatory Validation (Do Not Proceed Without)

1. Duplicate detection with counts and samples
2. Data completeness reconciliation
3. Data integrity checks
4. Performance validation
5. Comparison testing (if altering existing)

See .claude/commands/prp-data-object-execute.md for full success criteria, error handling, and security/compliance.
