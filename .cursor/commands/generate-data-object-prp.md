# Create Data Object Product Requirements Prompt (PRP)

Generate a complete PRP for data object creation OR modification (views, tables, dynamic tables) with comprehensive database research. Supports single object and multiple related objects.

**Argument**: The PRP folder or INITIAL.md path. If the user types text after `/generate-data-object-prp`, that is the folder containing INITIAL.md or the path to INITIAL.md (e.g., `/generate-data-object-prp videos/prp_data_object_video/PRPs/01_simple_tpch`).

## Prerequisites

References configuration from CLAUDE.md: Database CLI (default `snow`), Ticketing CLI (default `acli`), Dev/Prod databases, Architecture layers.

**Template Reference:** Use `PRPs/templates/data-object-initial.md` as the standard input format.

## Process

1. **Read INITIAL.md** – Understand operation type (CREATE_NEW/ALTER_EXISTING), scope (SINGLE_OBJECT/MULTIPLE_RELATED_OBJECTS), business objectives, data grain, sources, integration points.

2. **Database Schema Analysis** – Use database CLI to explore objects, get DDL, describe tables. Map relationships, validate schema filtering, review sample column values for business-friendly transformation.

3. **Architecture Compliance** – Verify layer referencing, deployment patterns, existing DDL in tickets/*/final_deliverables/.

4. **Data Quality Assessment** – Run sample queries, compare record counts, validate data structure (JOIN vs UNION), question filters that reduce data without justification. If ALTER_EXISTING: before/after comparison queries.

5. **Business Context Research** – Review similar tickets, documentation, validate grain from INITIAL.md.

6. **Iterative User Clarification (REQUIRED)** – After research, ask key questions. Present data structure findings and uncertainties. Escalate QC concerns. Get confirmation before finalizing PRP.

7. **PRP Generation** – Include: Operation type, Business requirements, Current state (if ALTER), Database objects DDL, Schema relationships, Architecture patterns, Data migration analysis, Data samples, Business logic, Downstream dependencies, Development setup, Ticket context, Performance/compliance. Implementation blueprint with operation/scope strategy, object dependency mapping, transformation logic, validation gates, QC plan (single qc_validation.sql), production deployment strategy.

## Critical Gates

- **BEFORE WRITING PRP: ASK KEY QUESTIONS** – Present findings, raise doubts, validate understanding, get confirmation.
- **AFTER USER FEEDBACK: Plan approach, then write PRP.**

## Output

- Save as `PRPs/data-object-{object-name}.md` in the same folder as INITIAL.md.
- Table of Contents at top with anchor links.
- Expected ticket folder reference: `tickets/[username]/[TICKET-ID]/`.

See CLAUDE.md and the full command in .claude/commands/generate-data-object-prp.md for the complete quality checklist and validation gates.
