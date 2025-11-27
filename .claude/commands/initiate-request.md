# Initiate Analysis Request

Comprehensive command to start new analysis work, create a plan, and execute tasks.

## Usage

Run this command when starting any new analysis project or data request.

## What it does

### 1. Understands the Request
- Asks for project description or ticket reference
- Clarifies scope and requirements
- Identifies data sources needed

### 2. Creates Feature Branch
- **Ensures you're on main branch**: `git checkout main`
- **Pulls latest changes**: `git pull origin main`
- **Creates descriptive feature branch**: `git checkout -b analysis-[description]`

### 3. Creates Project Structure
```
projects/[username]/[project-name]/
├── README.md
├── sql_queries/
├── notebooks/
├── exploratory_analysis/
├── qc_queries/
└── final_deliverables/
```

### 4. Creates a Plan
- Breaks down request into specific tasks
- Identifies dependencies and order
- Asks clarifying questions about:
  - Time periods and date ranges
  - Data sources and tables
  - Business logic and calculations
  - Expected outputs and deliverables
  - Success criteria and validation

### 5. Executes Tasks Systematically
- Works through tasks methodically
- Confirms approach before execution
- Does appropriate pre-research:
  - Checks database schema documentation
  - References quality control standards
  - Reviews business context if available
- Asks for confirmation at key decision points
- Documents all assumptions in README.md

### 6. Validates Work
- Runs QC checks on all deliverables
- Ensures README.md is comprehensive
- Validates all assumptions are documented
- Verifies data quality and completeness

## Example Usage

```
You: "/initiate-request"
Claude: "What analysis project would you like to start?
        (Project description or ticket reference)"

You: "Analyze customer churn patterns for Q4 2024"

Claude: [Creates branch analysis-customer-churn-q4-2024]
        [Creates folder structure]
        "I'll break this down into tasks:
        1. Explore customer activity table structure
        2. Identify Q4 2024 churn patterns
        3. Segment by customer characteristics
        4. Create visualizations
        5. Write QC validation queries

        Before I start, a few questions:
        - Should I include all customer types or focus on specific segments?
        - What defines 'churn' for this analysis? (No activity in 90 days? Account closed?)
        - Do you want daily, weekly, or monthly trend analysis?"

You: [Answers questions]

Claude: [Executes tasks with confirmation]
        "Task 1 complete. Moving to Task 2..."
```

## Key Features

- **Clarifying questions**: Asks what it needs to know upfront
- **Task breakdown**: Divides complex work into manageable steps
- **Pre-research**: Checks documentation before acting
- **Confirmation points**: Asks before major decisions
- **Documentation**: Tracks all assumptions and logic in README.md

## What Gets Created

**README.md template:**
```markdown
# [Project Name]

## Purpose
What problem are we solving? What questions are we answering?

## Requirements
What are the specific requirements and success criteria?

## Methodology
What approach and analysis methods are being used?

## Data Sources
Which tables, databases, and data sources are used?

## Assumptions
What assumptions have been made during the analysis?

## Deliverables
What are the final outputs and where are they located?
```

**Folder structure:**
- `sql_queries/` - Production SQL scripts (numbered for review order)
- `qc_queries/` - Quality control validation queries
- `notebooks/` - Jupyter or Python notebooks
- `exploratory_analysis/` - Development and iteration work
- `final_deliverables/` - Ready-to-deliver outputs (numbered)

---

This is your comprehensive command for starting and executing new analysis work!
