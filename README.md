# Data Intelligence Tickets

## Purpose

This repository serves as a continuous knowledge base for solving data intelligence tickets and issues. It consolidates documentation, scripts, and solutions to help streamline ticket resolution and maintain institutional knowledge.

## Overview

The data-intelligence-tickets repository is designed to:
- Build a comprehensive knowledge base for recurring issues and solutions
- Document ticket resolutions for future reference
- Provide reusable scripts and tools for common tasks
- Enable efficient collaboration on data intelligence issues

## Available Tools

This project leverages several command-line interface tools:

- **Snowflake CLI (`snow`)**: For database queries and management
- **Jira/Confluence CLI (`acli`)**: For ticket tracking and documentation
- **Tableau CLI (`tabcmd`)**: For Tableau server management
- **Tableau Metadata API (`tableau_metadata`)**: For metadata queries and analysis
- **GitHub CLI (`gh`)**: For repository and issue management

## Getting Started

1. **Review Core Documentation**: Start with these comprehensive guides:
   - [`CLAUDE.md`](CLAUDE.md) - AI assistance instructions and workflows
   - [`documentation/data_catalog.md`](documentation/data_catalog.md) - Database architecture and object reference
   - [`documentation/value_summary.md`](documentation/value_summary.md) - Business impact and value delivered
2. **Ensure CLI Tools**: Verify all required CLI tools are installed and configured
3. **Search Existing Solutions**: Use repository search to find existing solutions before creating new ones
4. **Follow Documentation Standards**: Contribute new solutions following established patterns

## Repository Structure

```
data-intelligence-tickets/
├── README.md              # This file
├── CLAUDE.md             # Instructions for AI assistance
├── documentation/         # Core documentation and knowledge base
│   ├── data_catalog.md   # Database schema and object documentation
│   ├── db_deploy_template.sql  # Database deployment template
│   ├── prerequisite_installations.md  # Tool installation guide
│   └── value_summary.md  # Business value and impact summary
├── resources/            # Shared scripts and utilities
├── tickets/              # Organized ticket solutions by team member
│   └── [team_member]/
│       └── [TICKET-ID]/
│           ├── README.md
│           ├── source_materials/
│           ├── final_deliverables/
│           └── archive_versions/
└── solutions/            # Legacy - use tickets/ structure instead
```

## Ticket Resolution Process

### 1. Setup and Planning
```bash
# Create ticket branch
git checkout main && git pull origin main
git checkout -b DI-XXX

# Create ticket folder structure
mkdir -p tickets/[team_member]/DI-XXX
cd tickets/[team_member]/DI-XXX

# Initialize README with ticket template
```

### 2. Data Investigation
- **Explore databases**: Use `snow sql` with proper Duo authentication
- **Use LEAD_GUID**: Most reliable identifier across LMS/LOS systems
- **Reference data catalog**: Use [`documentation/data_catalog.md`](documentation/data_catalog.md) for database object reference
- **Document new findings**: Add discoveries to data catalog for future team use
- **Handle duplicates**: Use LISTAGG() and aggregation for flattening

### 3. Query Development
- **Build incrementally**: Start simple, add complexity gradually
- **Handle data quality**: Use inclusive OR conditions for fraud analysis
- **Apply schema filtering**: Use `arca.CONFIG.LMS_SCHEMA()` and `arca.CONFIG.LOS_SCHEMA()`
- **Test with limits**: Use `LIMIT` clauses during development

### 4. Results Analysis
- **Column-by-column completeness**: Analyze missing data patterns
- **Stakeholder focus**: Summarize business impact, not technical details
- **Data quality notes**: Document scattered data sources and limitations

### 5. Documentation and Delivery
- **Clean folder**: Move iterations to `archive/`, keep final files clear
- **Update documentation**: Add fundamental learnings to [`CLAUDE.md`](CLAUDE.md) for future use
- **Jira delivery**: Concise comment with key findings, manual file attachment
- **Google Drive backup**: Copy to team member folder for preservation

### 6. Code Review and Merge
- **Create PR**: Submit for review with comprehensive documentation
- **GitHub integration**: Ensure all work is version-controlled

## Fraud Analysis Specific Guidelines

### Multi-Source Detection
Fraud data requires checking multiple sources:
- **Portfolios**: `VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS` 
- **Investigation results**: `VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT`
- **Loan status**: `VW_LOAN_SUB_STATUS_ENTITY_CURRENT` (status contains "fraud")

### Binary Classification Pattern
```sql
-- Create binary indicators for precise analysis
MAX(CASE WHEN portfolio_name = 'First Party Fraud - Confirmed' THEN 1 ELSE 0 END) as FIRST_PARTY_FRAUD_CONFIRMED,
MAX(CASE WHEN portfolio_name = 'Identity Theft Fraud - Confirmed' THEN 1 ELSE 0 END) as IDENTITY_THEFT_FRAUD_CONFIRMED
```

### Partner Analysis for Repurchase
```sql
-- Flatten partner data to avoid duplicates
LISTAGG(DISTINCT partner_name, '; ') WITHIN GROUP (ORDER BY partner_name) as ALL_PARTNER_NAMES,
CASE WHEN COUNT(DISTINCT partner_name) > 1 THEN 1 ELSE 0 END as MULTIPLE_PARTNERS_INDICATOR
```

## Common Patterns and Solutions

### Schema Filtering
Always filter by schema for loan objects:
- **Loans**: `WHERE SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()`
- **Applications**: `WHERE SCHEMA_NAME = arca.CONFIG.LOS_SCHEMA()`

### Data Type Handling
```sql
-- Cast for reliable joins
CAST(loan_id AS VARCHAR) -- When joining integer to string IDs
loan_id::VARCHAR         -- Snowflake shorthand
```

### Status Information
Use improved status tables for current loan state:
- `VW_LOAN_SETTINGS_ENTITY_CURRENT` joined with
- `VW_LOAN_SUB_STATUS_ENTITY_CURRENT` for actual status text

## Completed Tickets Log

This section maintains a chronological log of all completed tickets with links to their documentation.

### 2025

#### July
- **[DI-934](tickets/kchalmers/DI-934/README.md)** - Fraud Loan Analysis with Repurchase Details  
  *Kyle Chalmers* | Complete fraud loan analysis across multiple data sources with binary classification patterns and partner ownership tracking

- **[DI-1065](tickets/kchalmers/DI-1065/README.md)** - Fortress Quarterly Due Diligence Payment History  
  *Kyle Chalmers* | Payment history extraction for 80 Fortress loans with quality control validation and attachment source tracking

- **[DI-1099](tickets/kchalmers/DI-1099/README.md)** - Theorem Goodbye Letter List for Loan Sale to Resurgent  
  *Kyle Chalmers* | Generated goodbye letter lists for 2,179 Theorem loans being sold to Resurgent with SFMC integration and portfolio breakdown

- **[DI-1100](tickets/kchalmers/DI-1100/README.md)** - Theorem (Pagaya) Credit Reporting and Placement Upload List for Loan Sale  
  *Kyle Chalmers* | Credit reporting and LoanPro placement upload files for 1,770 Theorem portfolio loans with Resurgent placement status

#### August  
- **[DI-974](tickets/kchalmers/DI-974/README.md)** - Add SIMM Placement Flag to Intra-month Roll Rate Dashboard  
  *Kyle Chalmers* | Added dual SIMM placement flags (current and historical) to roll rate dashboards with 40-60% performance optimization

- **[DI-1137](tickets/kchalmers/DI-1137/README.md)** - Regulator Request: Massachusetts - Applications and Loans  
  *Kyle Chalmers* | Massachusetts regulator request for loan and application data for pending license application, including small dollar high rate loan analysis

- **[DI-1140](tickets/kchalmers/DI-1140/README.md)** - Identify Originated Loans Associated w/ Suspected Small Fraud Ring  
  *Kyle Chalmers* | Fraud ring investigation targeting BMO Bank accounts with recent account opening patterns and routing number analysis

- **[DI-1141](tickets/kchalmers/DI-1141/README.md)** - Sale Files for Bounce - Q2 2025 Sale  
  *Kyle Chalmers* | Q2 2025 debt sale population (1,591 loans, $19.8M) with enhanced settlement monitoring, optimized SQL queries (50-70% performance improvement), and comprehensive exclusion analysis

- **[DI-1143](tickets/kchalmers/DI-1143/README.md)** - Align Oscilar Plaid Data Structure With Historical Plaid DATA_STORE Structure  
  *Kyle Chalmers* | Created views to transform Oscilar Plaid data to match historical DATA_STORE structure for Prism vendor compatibility
- **[DI-1146](tickets/kchalmers/DI-1146/README.md)** - Mobile vs Desktop Application Analysis  
  *Kyle Chalmers* | Device usage pattern analysis showing 68.9% mobile-only vs 26.9% desktop-only applications with 99.96% data coverage and 4.35% cross-device behavior

---

## Contributing

When resolving tickets:
1. **Follow the 6-step process** outlined above
2. **Document learnings** in CLAUDE.md for future tickets
3. **Maintain clean folder structure** with archive organization
4. **Provide stakeholder-focused summaries** not technical deep-dives
5. **Backup to Google Drive** team member folders
6. **Submit PR** for review and knowledge sharing
7. **Add ticket to log** above with link to README.md and brief description
