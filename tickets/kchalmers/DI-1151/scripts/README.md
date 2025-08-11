# DI-1151 Scripts

## Overview
This folder contains Python scripts created for the DI-1151 debt sale deliverables update process.

## Scripts Organization

### 📁 automation/
**Purpose**: Automated data processing and updates

- **`update_dates_by_portfolio.py`**
  - Updates all three CSV files with portfolio-based dates
  - Fetches portfolio mapping from Snowflake
  - Applies different dates: Theorem (2025-08-11), Non-Theorem (2025-08-08)
  - Creates backup copies and validates updates
  - **Usage**: `python scripts/automation/update_dates_by_portfolio.py`

### 📁 qc_validation/
**Purpose**: Quality control and validation scripts

- **`qc_date_portfolio_alignment.py`**
  - Comprehensive QC validation of date-portfolio alignment
  - Cross-references CSV files with database portfolio distributions
  - Validates sample loan IDs for correct date assignment
  - Provides detailed pass/fail validation results
  - **Usage**: `python scripts/qc_validation/qc_date_portfolio_alignment.py`

## Execution Results
- **Automation**: Successfully updated 1,483 loans across 3 CSV files
- **QC Validation**: All validations passed with 100% accuracy
- **Portfolio Alignment**: Perfect match between database and CSV date distributions

## Dependencies
- Python 3.x
- pandas library
- Snowflake CLI (snow) configured and authenticated
- subprocess and json modules (built-in)