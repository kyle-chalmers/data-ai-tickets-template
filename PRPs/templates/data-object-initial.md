# Data Object Request

## Request Type
**Operation:** [CREATE_NEW/ALTER_EXISTING]
**Scope:** [SINGLE_OBJECT/MULTIPLE_RELATED_OBJECTS]

## Object Definition(s)
**Primary Object Name:** [descriptive_name]
**Object Type:** [VIEW/TABLE/DYNAMIC_TABLE]  
**Target Schema Layer:** [FRESHSNOW/BRIDGE/ANALYTICS/REPORTING]

## Related Objects (if MULTIPLE_RELATED_OBJECTS)
**Object 2:** [name] - [type] - [layer] - [relationship to primary]
**Object 3:** [name] - [type] - [layer] - [relationship to primary]
**Dependencies:** [How objects depend on each other - creation order, references]
**Deployment Strategy:** [Sequential/parallel deployment approach]

## Existing Object Context (if ALTER_EXISTING)
**Current Object(s):** [schema.object_name - full path(s) to existing object(s)]
**Current Data Sources:** [List current underlying tables/views the existing objects use]
**Existing Dependencies:** [Known downstream objects that depend on these - views, reports, dashboards]
**Expected Changes:** [What will change - data sources, business logic, columns, performance]
**Backward Compatibility:** [MAINTAIN/BREAKING_CHANGES - whether existing consumers should continue to work]
**Source Migration:** [If altering existing - describe transition from old sources to new sources]
**Migration Order:** [If multiple objects - sequence for altering to maintain dependencies]

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
**New/Target Sources:** [Table names for new data sources to be used]
**Expected Relationships:** [How tables connect - loan to customer, payment to loan, etc.]
**Data Quality Considerations:** [Known issues, duplicates, missing data patterns]
**Expected Data Differences:** [If changing sources - describe expected changes in data volume, values, or structure]

## Requirements
**Performance:** [Query response time expectations, data volume estimates]
**Refresh Pattern:** [Real-time, hourly, daily, on-demand]
**Data Retention:** [How long to retain data]
**Compliance/Security:** [PII handling, regulatory requirements]

## Ticket Information
**Existing Jira Ticket:** [DI-XXX or "CREATE_NEW"]
**Stakeholders:** [Business owners, analysts who requested this]

## Additional Context
[Any other relevant information, similar objects that exist, specific business rules, etc.]