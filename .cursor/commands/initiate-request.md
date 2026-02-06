# Initiate Analysis Request

Starts new analysis work: creates a plan, sets up structure, and executes tasks.

Run when starting any new analysis project or data request.

## What it does

1. **Understands the Request** – Ask for project description or ticket reference; clarify scope, requirements, and data sources.
2. **Creates Feature Branch** – Ensure on main, pull latest, create descriptive branch (e.g., `analysis-[description]`).
3. **Creates Project Structure** – `projects/[username]/[project-name]/` with README.md, sql_queries/, notebooks/, exploratory_analysis/, qc_queries/, final_deliverables/.
4. **Creates a Plan** – Break into tasks, identify dependencies, ask clarifying questions (time periods, data sources, business logic, outputs, success criteria).
5. **Executes Tasks** – Work through tasks methodically, confirm approach before execution, do pre-research (schema docs, QC standards, business context), ask for confirmation at key points, document assumptions in README.md.
6. **Validates Work** – Run QC checks, ensure README is complete, validate assumptions documented, verify data quality and completeness.

## Key Features

- Ask clarifying questions upfront.
- Break complex work into manageable steps.
- Check documentation before acting.
- Ask before major decisions.
- Track assumptions and logic in README.md.

## What Gets Created

- README.md with Purpose, Requirements, Methodology, Data Sources, Assumptions, Deliverables.
- sql_queries/, qc_queries/, notebooks/, exploratory_analysis/, final_deliverables/ (numbered for review order).
