# Example Workflow: Customer Analysis with Databricks + Claude

Practical example demonstrating how to use Databricks CLI and MCP together with Claude Code for data analysis.

---

## Scenario

Analyze e-commerce customer data in Databricks Unity Catalog to identify high-value segments and purchasing patterns.

**Business Questions:**
1. What are our top customer segments by revenue?
2. What are common purchasing patterns across regions?
3. Which products drive the most repeat purchases?

---

## Prerequisites

- Databricks CLI installed and configured
- Access to Unity Catalog with sample data
- (Optional) Databricks MCP configured for interactive exploration

---

## Workflow Steps

### Phase 1: Data Exploration (MCP)

Use MCP for interactive schema discovery and initial exploration:

**Prompts to use with Claude:**
```
"List all tables in the main catalog"
"Show me the schema for the customers table"
"What columns are in the orders table?"
"Give me a sample of 5 rows from the customer_orders view"
```

**What this accomplishes:**
- Understand available data sources
- Discover column names and data types
- Identify relationships between tables
- Get quick data samples

---

### Phase 2: Query Development (CLI + Files)

Create SQL queries based on exploration findings.

**Files created:**
- `1_data_exploration.sql` - Initial data profiling
- `2_customer_segmentation.sql` - Main analysis query
- `3_export_results.sql` - Final results for export

**Execute with CLI:**
```bash
# Run exploration query
databricks sql execute -f final_deliverables/1_data_exploration.sql --profile biprod

# Run main analysis
databricks sql execute -f final_deliverables/2_customer_segmentation.sql --profile biprod

# Export to CSV
databricks sql execute -f final_deliverables/3_export_results.sql --profile biprod > results.csv
```

---

### Phase 3: Quality Control (CLI)

Validate results with QC queries.

**Files created:**
- `qc_queries/1_record_count_validation.sql` - Verify row counts
- `qc_queries/2_revenue_totals_check.sql` - Validate calculations

**Execute QC:**
```bash
# Run all QC queries
databricks sql execute -f qc_queries/1_record_count_validation.sql --profile biprod
databricks sql execute -f qc_queries/2_revenue_totals_check.sql --profile biprod
```

---

## Example Queries

### 1. Data Exploration

```sql
-- File: final_deliverables/1_data_exploration.sql
-- Purpose: Understand data structure and quality

-- Check customer distribution by region
SELECT
    region,
    COUNT(DISTINCT customer_id) as customer_count,
    COUNT(DISTINCT order_id) as order_count
FROM main.analytics.customer_orders
GROUP BY region
ORDER BY customer_count DESC;

-- Check date range of data
SELECT
    MIN(order_date) as earliest_order,
    MAX(order_date) as latest_order,
    DATEDIFF(MAX(order_date), MIN(order_date)) as days_of_data
FROM main.analytics.customer_orders;

-- Sample data review
SELECT *
FROM main.analytics.customer_orders
LIMIT 10;
```

### 2. Customer Segmentation Analysis

```sql
-- File: final_deliverables/2_customer_segmentation.sql
-- Purpose: Identify high-value customer segments

WITH customer_metrics AS (
    SELECT
        customer_id,
        region,
        COUNT(DISTINCT order_id) as total_orders,
        SUM(order_amount) as total_revenue,
        AVG(order_amount) as avg_order_value,
        MAX(order_date) as last_order_date,
        DATEDIFF(CURRENT_DATE(), MAX(order_date)) as days_since_last_order
    FROM main.analytics.customer_orders
    WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
    GROUP BY customer_id, region
),
customer_segments AS (
    SELECT
        *,
        CASE
            WHEN total_revenue >= 10000 THEN 'High Value'
            WHEN total_revenue >= 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END as value_segment,
        CASE
            WHEN days_since_last_order <= 30 THEN 'Active'
            WHEN days_since_last_order <= 90 THEN 'At Risk'
            ELSE 'Churned'
        END as activity_segment
    FROM customer_metrics
)
SELECT
    value_segment,
    activity_segment,
    region,
    COUNT(*) as customer_count,
    SUM(total_revenue) as segment_revenue,
    AVG(total_orders) as avg_orders_per_customer,
    AVG(avg_order_value) as avg_order_value
FROM customer_segments
GROUP BY value_segment, activity_segment, region
ORDER BY segment_revenue DESC;
```

### 3. Export Results

```sql
-- File: final_deliverables/3_export_results.sql
-- Purpose: Final query for CSV export

SELECT
    customer_id,
    region,
    total_orders,
    total_revenue,
    avg_order_value,
    last_order_date,
    value_segment,
    activity_segment
FROM (
    -- Copy the CTE logic from 2_customer_segmentation.sql
    WITH customer_metrics AS (
        SELECT
            customer_id,
            region,
            COUNT(DISTINCT order_id) as total_orders,
            SUM(order_amount) as total_revenue,
            AVG(order_amount) as avg_order_value,
            MAX(order_date) as last_order_date,
            DATEDIFF(CURRENT_DATE(), MAX(order_date)) as days_since_last_order
        FROM main.analytics.customer_orders
        WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
        GROUP BY customer_id, region
    )
    SELECT
        *,
        CASE
            WHEN total_revenue >= 10000 THEN 'High Value'
            WHEN total_revenue >= 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END as value_segment,
        CASE
            WHEN days_since_last_order <= 30 THEN 'Active'
            WHEN days_since_last_order <= 90 THEN 'At Risk'
            ELSE 'Churned'
        END as activity_segment
    FROM customer_metrics
)
ORDER BY total_revenue DESC;
```

---

## Quality Control Queries

### 1. Record Count Validation

```sql
-- File: qc_queries/1_record_count_validation.sql
-- Purpose: Ensure no data loss in transformations

-- Source data counts
SELECT 'Source Customer Orders' as check_name, COUNT(*) as record_count
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)

UNION ALL

-- Distinct customers in analysis
SELECT 'Distinct Customers', COUNT(DISTINCT customer_id)
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)

UNION ALL

-- Orders with valid amounts
SELECT 'Valid Order Amounts', COUNT(*)
FROM main.analytics.customer_orders
WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
  AND order_amount > 0;
```

### 2. Revenue Totals Check

```sql
-- File: qc_queries/2_revenue_totals_check.sql
-- Purpose: Verify revenue calculations match source

WITH source_revenue AS (
    SELECT
        SUM(order_amount) as total_revenue,
        COUNT(DISTINCT customer_id) as customer_count
    FROM main.analytics.customer_orders
    WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
),
analysis_revenue AS (
    SELECT
        SUM(total_revenue) as total_revenue,
        COUNT(DISTINCT customer_id) as customer_count
    FROM (
        SELECT
            customer_id,
            SUM(order_amount) as total_revenue
        FROM main.analytics.customer_orders
        WHERE order_date >= DATE_SUB(CURRENT_DATE(), 365)
        GROUP BY customer_id
    )
)
SELECT
    'Source' as source_type,
    s.total_revenue,
    s.customer_count
FROM source_revenue s

UNION ALL

SELECT
    'Analysis',
    a.total_revenue,
    a.customer_count
FROM analysis_revenue a;

-- Difference should be 0
```

---

## Combined CLI + MCP Workflow

### Using Both Tools Together

```bash
# 1. Explore with MCP (via Claude)
# Ask: "What tables exist in the main catalog?"
# Ask: "Show schema for customer_orders table"

# 2. Develop queries in files (using Claude Code)
# Claude helps write SQL based on schema exploration

# 3. Test queries with CLI
databricks sql execute -f final_deliverables/1_data_exploration.sql

# 4. Refine with Claude
# Ask: "Optimize this query for large datasets"
# Ask: "Add a filter for active customers only"

# 5. Run QC validation
databricks sql execute -f qc_queries/1_record_count_validation.sql

# 6. Export final results
databricks sql execute -f final_deliverables/3_export_results.sql > customer_segments.csv
```

---

## Expected Output

### Sample Results

**Customer Segmentation Summary:**
```
value_segment | activity_segment | region        | customer_count | segment_revenue | avg_orders
High Value    | Active          | North America | 127            | 1,847,292       | 12.4
High Value    | At Risk         | North America | 43             | 589,441         | 9.2
Medium Value  | Active          | Europe        | 284            | 2,103,847       | 6.8
...
```

**QC Results:**
```
check_name                  | record_count
Source Customer Orders      | 145,293
Distinct Customers          | 8,421
Valid Order Amounts         | 145,293
```

---

## Key Learnings

### What MCP Does Well
- Quick schema discovery
- Interactive data sampling
- Conversational refinement of queries
- Understanding table relationships

### What CLI Does Well
- Executing production queries
- Exporting large result sets
- Scheduled/automated workflows
- Integration with CI/CD pipelines

### Combined Benefits
- **Faster development:** Explore with MCP, execute with CLI
- **Better quality:** Iterate quickly with conversational queries
- **Production ready:** CLI ensures reliable, repeatable execution

---

## Next Steps

1. **Modify for your data:** Replace table names with your Unity Catalog tables
2. **Add your credentials:** Configure CLI with your workspace details
3. **Run the workflow:** Execute each phase and review results
4. **Iterate:** Use Claude to refine queries based on findings

---

## Resources

- [Databricks CLI Setup](../instructions/DATABRICKS_CLI_SETUP.md)
- [Databricks MCP Setup](../instructions/DATABRICKS_MCP_SETUP.md)
- [CLI vs MCP Comparison](../databricks_cli_v_mcp_comparison/DATABRICKS_CLI_VS_MCP.md)
- [Troubleshooting Guide](../instructions/TROUBLESHOOTING.md)

---

**Note:** This example assumes Unity Catalog tables exist. Adapt table names and schemas to match your actual Databricks environment.
