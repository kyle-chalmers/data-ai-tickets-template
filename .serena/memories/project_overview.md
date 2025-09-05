# Data Intelligence Tickets Repository

## Purpose
This repository serves as a comprehensive knowledge base for solving data intelligence tickets and issues at Happy Money. It consolidates documentation, scripts, and solutions to streamline ticket resolution and maintain institutional knowledge.

## Tech Stack
- **Database Platform**: Snowflake (primary data warehouse)
- **Programming Languages**: SQL (primary), Python (analysis), Bash (automation)
- **CLI Tools**: 
  - `snow` (Snowflake CLI with Duo authentication)
  - `acli` (Jira CLI)
  - `gh` (GitHub CLI)  
  - `tabcmd` (Tableau CLI)
- **Integration Tools**: Slack CLI functions, Google Drive backup automation
- **Architecture**: 5-layer Snowflake architecture (RAW_DATA_STORE → FRESHSNOW → BRIDGE → ANALYTICS → REPORTING)

## Business Context
- **Company**: Happy Money (Financial Technology)
- **Platform**: LoanPro loan management system with extensive customizations
- **Focus**: Data-driven decision making, risk management, customer insights
- **Compliance**: Financial services regulatory requirements