# Data Object Creation Request

## Object Definition
**Object Name:** [descriptive_name]
**Object Type:** [VIEW/TABLE/DYNAMIC_TABLE]
**Target Schema Layer:** [FRESHSNOW/BRIDGE/ANALYTICS/REPORTING]

## Data Grain & Aggregation
**Grain:** [e.g., "One row per loan per month", "One row per customer", "One row per transaction"]
**Time Period:** [e.g., "Historical + current", "Last 24 months", "Daily snapshots"]
**Key Dimensions:** [e.g., "loan_id, customer_id, date", "customer_id, product_type"]

## Business Context
**Business Purpose:** [1-2 sentences describing why this object is needed]
**Primary Use Cases:** 
- [Use case 1 - who will use it and how]
- [Use case 2]
**Key Metrics/KPIs:** [Specific calculations or metrics this object should enable]

## Data Sources
**Primary Sources:** [Table names if known, or general description]
**Expected Relationships:** [How tables connect - loan to customer, payment to loan, etc.]
**Data Quality Considerations:** [Known issues, duplicates, missing data patterns]

## Requirements
**Performance:** [Query response time expectations, data volume estimates]
**Refresh Pattern:** [Real-time, hourly, daily, on-demand]
**Data Retention:** [How long to retain data]
**Compliance/Security:** [PII handling, regulatory requirements]

## Ticket Information
**Existing Jira Ticket:** [DI-XXX or "CREATE_NEW"]
**Priority:** [High/Medium/Low]
**Stakeholders:** [Business owners, analysts who requested this]
**Delivery Timeline:** [Target completion date]

## Additional Context
[Any other relevant information, similar objects that exist, specific business rules, etc.]