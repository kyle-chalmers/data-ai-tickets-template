# PRP Data Object Video - Claude Context

## Project Summary

This video project demonstrates the Product Requirements Prompt (PRP) workflow for creating Snowflake data objects. It showcases how AI can help transform data infrastructure challenges into opportunities.

## What Has Been Completed

### Project Setup
- Created branch `prp_data_object_video`
- Established folder structure with PRPs/, images/
- Copied `data-object-initial.md` template to video folder

### Documentation
- **README.md**: Conceptual overview with:
  - Video hook and value proposition
  - Three-phase workflow explanation (Define → Generate → Execute)
  - Links to context engineering source videos (Rasmus Widing, Cole Medin)
  - Command reference and adaptation guide

### Example INITIAL.md Files Created
Two example questionnaires are ready for PRP generation:

1. **Example 1: Simple View** (`PRPs/01_simple_tpch/INITIAL.md`)
   - Object: `VW_CUSTOMER_ORDER_SUMMARY`
   - Type: VIEW
   - Sources: TPC-H tables (CUSTOMER, ORDERS, LINEITEM, NATION, REGION)
   - Grain: One row per customer
   - Purpose: Demonstrate clean, straightforward workflow

2. **Example 2: Complex Dynamic Table** (`PRPs/02_multi_grain_analytics/INITIAL.md`)
   - Object: `DT_ORDER_ANALYTICS_MULTI_GRAIN`
   - Type: DYNAMIC_TABLE
   - Sources: All TPC-H tables
   - Grain: Mixed (line-item detail with order/customer/regional aggregations)
   - Purpose: Demonstrate complex multi-grain pattern handling

### Assets
- `images/what_we_will_learn.jpg` - Video hook slide
- `images/tpch_schema.png` - TPC-H schema diagram

## What Still Needs To Be Done

### Phase 2: Generate PRPs
Run the generate command on each INITIAL.md to create the full PRP documents:

```bash
# Example 1: Simple View
/generate-data-object-prp videos/prp_data_object_video/PRPs/01_simple_tpch/INITIAL.md

# Example 2: Complex Dynamic Table
/generate-data-object-prp videos/prp_data_object_video/PRPs/02_multi_grain_analytics/INITIAL.md
```

**Expected outputs:**
- `PRPs/01_simple_tpch/snowflake-data-object-customer-order-summary.md`
- `PRPs/02_multi_grain_analytics/snowflake-data-object-order-analytics-multi-grain.md`

### Phase 3: Execute PRPs
Run the execute command to implement the data objects:

```bash
# Example 1
/prp-data-object-execute videos/prp_data_object_video/PRPs/01_simple_tpch/snowflake-data-object-customer-order-summary.md

# Example 2
/prp-data-object-execute videos/prp_data_object_video/PRPs/02_multi_grain_analytics/snowflake-data-object-order-analytics-multi-grain.md
```

**Expected outputs:**
- Development objects created in Snowflake
- QC validation results
- Production deployment templates

### Video Recording
- Record walkthrough of the three-phase process
- Capture the AI research and clarification interactions
- Show QC validation and results
- Update README.md with final YouTube link

## Technical Context

### Data Source
- **Database**: `SNOWFLAKE_SAMPLE_DATA`
- **Schema**: `TPCH_SF100` (100GB scale factor)
- **Documentation**: https://docs.snowflake.com/en/user-guide/sample-data-tpch

### TPC-H Table Sizes
| Table | Rows |
|-------|------|
| LINEITEM | 600M |
| ORDERS | 150M |
| PARTSUPP | 80M |
| PART | 20M |
| CUSTOMER | 15M |
| SUPPLIER | 1M |
| NATION | 25 |
| REGION | 5 |

### Key Relationships
- CUSTOMER → ORDERS (1:many via C_CUSTKEY)
- ORDERS → LINEITEM (1:many via O_ORDERKEY)
- CUSTOMER → NATION → REGION (geographic hierarchy)

## Framework References

This workflow adapts the PRP framework from:
- [Context Engineering Quick Start](https://www.youtube.com/watch?v=H3lCPUx7TEE) by Rasmus Widing
- [Context Engineering is the New Vibe Coding](https://www.youtube.com/watch?v=Egeuql3Lrzg) by Cole Medin

## PR Status

- **PR #26**: https://github.com/kyle-chalmers/data-ai-tickets-template/pull/26
- **Branch**: `prp_data_object_video`
