# DI-1148: Create LMS-Filtered Bank Account Views

## Overview
Creation of standardized views for bank account information filtered to the LMS (Loan Management System) schema across FRESHSNOW and BRIDGE layers.

## Solution Components

### Views Created
1. **FRESHSNOW.VW_BANK_ACCOUNT_LMS** - Source view with LMS filtering
2. **BRIDGE.VW_BANK_ACCOUNT_LMS** - Pass-through view from FRESHSNOW

### Key Features
- Dynamic schema filtering using `config.lms_schema()`
- Environment-agnostic deployment (dev/prod switch via variables)
- Comprehensive bank account information including:
  - Loan and customer identifiers
  - Account details (type, number, routing)
  - Account status flags (primary, active)
  - Timestamps for audit trail
- All views include COPY GRANTS to preserve permissions

### Data Sources
- loan_entity_current
- loan_settings_entity_current  
- loan_customer_current
- customer_entity_current (PII schema)
- payment_account_entity_current
- checking_account_entity_current

## Deployment Instructions

1. Review the deployment script in `scripts/bank_account_los_views_deploy.sql`
2. Ensure proper environment variables are set (dev vs prod)
3. Execute the script in Snowflake
4. Verify views created successfully in both schemas

## Files
- `scripts/bank_account_lms_views_deploy.sql` - Main deployment script following db_deploy_template.sql pattern