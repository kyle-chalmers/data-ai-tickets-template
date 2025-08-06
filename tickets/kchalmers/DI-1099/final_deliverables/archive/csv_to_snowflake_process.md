# CSV to Snowflake Table Creation Process

## Overview
Simple, reliable process for creating Snowflake tables from CSV files using direct INSERT statements.

## Proven Process (Tested with 2,179 loan records)

### Step 1: Prepare CSV File
```bash
# Ensure CSV is clean and accessible
cd /path/to/csv/directory
wc -l "filename.csv"  # Confirm total record count (includes header)
head -5 "filename.csv"  # Verify format and structure
```

### Step 2: Create Target Table Structure
```sql
-- Create empty table with appropriate schema
CREATE TABLE [database].[schema].[table_name] (
    FIELD1 VARCHAR(50),
    FIELD2 VARCHAR(200),
    FIELD3 FLOAT
    -- Add all required fields with appropriate data types
);
```

### Step 3: Create Complete INSERT Statement
```bash
# Generate complete INSERT statement with all CSV values
echo "-- Direct INSERT with all selected records" > /tmp/complete_insert.sql
echo "INSERT INTO [target_table]" >> /tmp/complete_insert.sql
echo "SELECT source.FIELD1, source.FIELD2, source.FIELD3" >> /tmp/complete_insert.sql
echo "FROM [source_table] source" >> /tmp/complete_insert.sql
echo "WHERE source.KEY_FIELD IN (" >> /tmp/complete_insert.sql

# Add all CSV values as comma-separated list (clean formatting)
tail -n +2 "filename.csv" | \
    tr -d '\r' | \
    sed "s/^/'/" | \
    sed "s/$/'/" | \
    tr '\n' ',' | \
    sed 's/,$//' >> /tmp/complete_insert.sql

echo ");" >> /tmp/complete_insert.sql

# Execute the complete INSERT statement
snow sql -f /tmp/complete_insert.sql --format csv
```

### Step 4: Final Validation
```sql
-- Comprehensive validation query
WITH validation_summary AS (
    SELECT 
        COUNT(*) as total_records,
        COUNT(DISTINCT key_field) as unique_records,
        MIN(numeric_field) as min_value,
        MAX(numeric_field) as max_value,
        COUNT(DISTINCT category_field) as category_count
    FROM [target_table]
)
SELECT 
    'Final Validation' as check_type,
    total_records,
    unique_records,
    CASE 
        WHEN total_records = [expected_count] THEN 'SUCCESS: ALL RECORDS INSERTED'
        WHEN total_records > ([expected_count] * 0.95) THEN 'PARTIAL SUCCESS: MOST RECORDS INSERTED'
        ELSE 'ISSUE: LOW INSERT COUNT'
    END as status,
    min_value,
    max_value,
    category_count
FROM validation_summary;
```

## Key Success Factors

### 1. Simple Direct Approach
- **Single INSERT statement**: Most efficient and reliable method
- **Remove carriage returns**: `tr -d '\r'` essential for clean CSV data
- **Proper quoting**: Use `sed "s/^/'/" | sed "s/$/'/"` for string fields  
- **Clean comma separation**: `tr '\n' ',' | sed 's/,$//'` for IN clauses

### 2. Data Preparation
- **Verify CSV structure**: Confirm header vs data rows
- **Clean formatting**: Remove carriage returns and extra whitespace
- **Single file generation**: Create one complete INSERT statement file

### 3. SQL Approach  
- **IN clause method**: Most reliable for exact matching
- **JOIN with source table**: Ensures data integrity and gets additional fields
- **Direct execution**: Use `snow sql -f` to execute complete statement file

### 4. Validation Requirements
- **Count verification**: Total records, unique records, expected vs actual
- **Data quality checks**: Min/max values, category distributions  
- **Success confirmation**: Clear validation of complete insertion

## Example Implementation (DI-1099)
```bash
# Real example: 2,179 loans from CSV to THEOREM_DEBT_SALE_Q1_2025_SALE_SELECTED  
# Result: 2,179 loans inserted (100% success)
# Process time: <1 minute with direct INSERT
```

## Common Issues and Solutions

### Issue: Overcomplicated Batch Processing
**Solution**: Use single direct INSERT statement - simpler and more reliable

### Issue: Formatting Problems  
**Solution**: Always use `tr -d '\r'` to remove carriage returns from CSV

### Issue: SQL Length Concerns
**Solution**: Modern Snowflake handles large IN clauses efficiently - no need for batching

### Issue: Performance Concerns
**Solution**: Direct INSERT with IN clause is faster than multiple batch operations

## Best Practices
1. **Always validate CSV format** before starting process
2. **Use direct INSERT approach** - simpler and more reliable than batching
3. **Clean data formatting** to prevent SQL errors (remove carriage returns)
4. **Validate results** with comprehensive QC queries  
5. **Document expected vs actual counts** for future reference
6. **Keep it simple** - avoid over-engineering the solution