# Code Style and Conventions

## SQL Conventions
- **Variables**: Parameterize values at script top with clear comments
- **Formatting**: Standard SQL formatting with proper indentation
- **Comments**: Include comprehensive commenting explaining business logic
- **Data Types**: Use CAST() for type conversions when joining
- **Output**: Always use CSV format with `--format=csv`
- **Headers**: Always include column headers in CSV outputs
- **Error Handling**: Use TRY_TO_NUMBER(), TRY_TO_DATE() for data conversion

## Schema Filtering Standards
```sql
-- Loan Management System (LMS) data
WHERE SCHEMA_NAME = arca.CONFIG.LMS_SCHEMA()

-- Loan Origination System (LOS) data  
WHERE SCHEMA_NAME = arca.CONFIG.LOS_SCHEMA()
```

## Join Strategies
```sql
-- Primary: Use LEAD_GUID (most reliable identifier)
JOIN table2 ON table1.LEAD_GUID = table2.LEAD_GUID

-- Secondary: LEGACY_LOAN_ID for stakeholder references
LEFT JOIN table3 ON CAST(table1.LEGACY_LOAN_ID AS VARCHAR) = table3.EXTERNAL_LOAN_ID
```

## File Naming Conventions
- **Sequential Numbering**: `1_`, `2_`, `3_` for review order
- **Descriptive Names**: Include record counts and clear descriptions
- **Example**: `fortress_payment_history_193_transactions.csv`

## Documentation Standards
- **Concise**: Essential information only, avoid verbosity
- **Business Focus**: Business impact over technical implementation
- **Assumption Documentation**: Enumerate ALL assumptions with reasoning