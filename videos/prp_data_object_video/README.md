# Product Requirements Prompt (PRP) for Data Objects

> **YouTube:** [Coming Soon]

## The Value Proposition

With the help of AI, we can move from problematic data infrastructure to clean, easy-to-use infrastructure. **Our data does not have to be in a good place to start the journey with AI**—we can use AI to help us get there.

![What We Will Learn](images/what_we_will_learn.jpg)

### What We Will Learn
1. What the product requirements prompt is and how it provides context for data object creation
2. How to create SQL-based data objects using the `/generate-data-object-prp` and `/prp-data-object-execute` custom commands

### The Value
1. You can utilize AI to accelerate the improvement of your data infrastructure
2. Data quality issues become an *opportunity* to use AI instead of an obstacle blocking AI usage
3. You can adapt the PRP framework for other projects you want to complete

---

## Introduction to Product Requirements Prompts

A **Product Requirements Prompt (PRP)** is a comprehensive specification document that gives an AI agent all the context it needs to implement a data object correctly on the first attempt.

### Why PRPs Matter

Traditional data object development often involves:
- Multiple iterations to understand requirements
- Missing edge cases discovered late
- Inconsistent quality control
- Poor documentation

PRPs solve this by front-loading the research and specification work, enabling **one-pass implementation success**.

---

## The Two-Phase Workflow

### Phase 1: Generate PRP (`/generate-data-object-prp`)

**Purpose:** Research, analyze, and create a comprehensive specification.

**What it does:**
- Performs deep database schema analysis using Snow CLI
- Maps data relationships and dependencies
- Assesses data quality (duplicates, nulls, joins)
- Validates architecture compliance
- Iteratively clarifies requirements with the user
- Generates a complete PRP document

**Output:** `PRPs/snowflake-data-object-{name}.md`

### Phase 2: Execute PRP (`/prp-data-object-execute`)

**Purpose:** Implement, validate, and deploy the data object.

**What it does:**
- Creates objects in development environment
- Implements comprehensive QC validation
- Optimizes query performance
- Generates documentation (README.md, CLAUDE.md)
- Prepares production deployment template

**Output:** Complete ticket folder with validated deliverables

---

## Example 1: Simple TPC-H Customer Order Summary

**Scenario:** Create a dynamic table summarizing customer order metrics using Snowflake's sample TPC-H dataset.

![TPC-H Schema](images/tpch_schema.png)

This example demonstrates the "happy path" with clean, normalized data.

**Data Object:** `DT_CUSTOMER_ORDER_SUMMARY`
- **Grain:** One row per customer
- **Sources:** CUSTOMER, ORDERS, LINEITEM, NATION, REGION
- **Metrics:** Total orders, total revenue, average order value

### Artifacts
- [INITIAL.md](PRPs/01_simple_tpch/INITIAL.md) - The initial questionnaire
- PRP generated after execution

---

## Example 2: Multi-Grain Order Analytics

**Scenario:** Create a complex analytics table that combines multiple grains—demonstrating how AI handles "messy" real-world scenarios.

This example is inspired by `CAST_VOTING_RECORD.ANALYTICS.VW_FINAL_TABLEAU_REPORT`, which combines:
- Fine-grained detail (individual line items)
- Aggregated metrics (order-level summaries)
- Rankings and comparisons (customer-level window functions)

**Data Object:** `DT_ORDER_ANALYTICS_MULTI_GRAIN`
- **Complexity:** Mixed grains, window functions, conditional aggregations
- **Pattern:** CTE-based architecture joining multiple grain levels

### Artifacts
- [INITIAL.md](PRPs/02_multi_grain_analytics/INITIAL.md) - The initial questionnaire
- PRP generated after execution

---

## Adapting the Framework

The PRP workflow can be customized for your own data projects:

1. **Copy the template:** Use `PRPs/templates/data-object-initial.md` as your starting point
2. **Fill in your requirements:** Define grain, sources, business context
3. **Run the generate command:** Let AI research and create the PRP
4. **Review and clarify:** Answer questions, validate assumptions
5. **Execute:** Implement with comprehensive QC

### Key Customization Points
- **Object Type:** VIEW, TABLE, or DYNAMIC_TABLE
- **Target Schema:** Match your architecture layers
- **Performance Requirements:** Refresh patterns, retention
- **Data Quality Handling:** How to treat duplicates, missing data

---

## Command Reference

### Generate Command
```bash
/generate-data-object-prp PRPs/your-project/INITIAL.md
```

### Execute Command
```bash
/prp-data-object-execute PRPs/your-project/snowflake-data-object-name.md
```

---

## Files in This Project

```
videos/prp_data_object_video/
├── README.md                           # This file
├── images/
│   ├── what_we_will_learn.jpg          # Video hook slide
│   └── tpch_schema.png                 # TPC-H schema diagram
└── PRPs/
    ├── templates/
    │   └── data-object-initial.md      # Template for new projects
    ├── 01_simple_tpch/
    │   └── INITIAL.md                  # Simple example questionnaire
    └── 02_multi_grain_analytics/
        └── INITIAL.md                  # Complex example questionnaire
```
