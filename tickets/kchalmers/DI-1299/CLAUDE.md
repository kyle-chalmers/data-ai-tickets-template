# CLAUDE.md: Technical Context for DI-1299

## Overview

This file provides complete technical context for future AI assistance with VW_DSH_OUTBOUND_GENESYS_OUTREACHES optimization (conversion from view to dynamic table).

## Ticket Information

- **Jira Ticket:** DI-1299
- **Type:** ALTER_EXISTING
- **Scope:** SINGLE_OBJECT
- **Status:** Ready for Review and Deployment (Permission Limited)
- **Created:** 2025-10-01
- **Assignee:** kchalmers@happymoney.com
- **Epic:** DI-1238

## Problem Analysis

### Performance Bottlenecks Identified

1. **Correlated Subquery (6+ executions):**
   ```sql
   DATE((Select MIN(DATE(DATEADD('day', -1, record_insert_date)))
         from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
   ```
   - Executed in dqs CTE, phone_calls CTE (2×), sent_texts CTE (2×), emails_sent CTE
   - Each execution scans 4.5M rows

2. **MVW_LOAN_TAPE_DAILY_HISTORY Multiple Scans (533M rows × 3 = 1.6B row scans):**
   - dqs CTE: Filters by status, aggregates by date/portfolio/loanstatus
   - emails_sent CTE: Joins to email events with complex DPD logic
   - gr_email_lists CTE: Joins to outbound lists history

3. **Large Activity Table Double Joins:**
   - phone_calls CTE: 2 joins to VW_GENESYS_PHONECALL_ACTIVITY
   - sent_texts CTE: 2 joins to VW_GENESYS_SMS_ACTIVITY
   - Both tables extremely large (queries timeout)

4. **Email Campaign Hard-Coding:**
   - 2,901 distinct campaigns mapped via massive CASE statements
   - Unmaintainable, difficult to add new campaigns

### Data Volumes

- GENESYS_OUTBOUND_LIST_EXPORTS: 4.5M rows (Phone: 3.27M, Text: 1.2M)
- MVW_LOAN_TAPE_DAILY_HISTORY: 533M rows, 731 distinct dates since Oct 2023
- DSH_EMAIL_MONITORING_EVENTS: 152M rows (2,901 distinct campaigns)
- VW_GENESYS_PHONECALL_ACTIVITY: Very large (timeout on COUNT)
- VW_GENESYS_SMS_ACTIVITY: Very large (timeout on COUNT)
- RPT_OUTBOUND_LISTS_HIST: 5.1M rows (GR Email)

## Solution Architecture

### Optimization Strategy

1. **Convert to Dynamic Table:**
   - Target lag: 12 hours
   - Refresh mode: FULL (complex aggregations, no incremental key)
   - Warehouse: BUSINESS_INTELLIGENCE
   - Materialization pre-computes all expensive joins

2. **Eliminate Correlated Subqueries:**
   ```sql
   WITH min_dates AS (
       SELECT
           MIN(DATE(DATEADD('day', -1, record_insert_date))) as min_record_insert_date,
           MIN(DATE(LOADDATE)) as min_loaddate
       FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
   )
   ```
   - Impact: 6+ scans of 4.5M rows → 1 scan

3. **Reduce MVW_LOAN_TAPE Scans:**
   ```sql
   loan_tape_base AS (
       SELECT ASOFDATE, PAYOFFUID, LOANID, STATUS, DAYSPASTDUE, PORTFOLIONAME, PORTFOLIOID
       FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
       CROSS JOIN min_dates md
       WHERE DATE(ASOFDATE) >= md.min_record_insert_date
   )
   ```
   - Impact: 533M rows × 3 scans → 533M rows × 1 scan
   - Reused in dqs, emails_sent, gr_email_lists CTEs

4. **Maintain Double-Join Pattern (Business Requirement):**
   ```sql
   -- Join A: Campaign-based calls via inin-outbound-id
   LEFT JOIN VW_GENESYS_PHONECALL_ACTIVITY a ON a."inin-outbound-id" = c."inin-outbound-id"
   -- Join B: Manual calls via PAYOFFUID + date
   LEFT JOIN VW_GENESYS_PHONECALL_ACTIVITY b ON c.PAYOFFUID = b.PAYOFFUID AND DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE)
   ```
   - Captures both campaign-based and manual outbound calls/texts
   - Critical for accurate metrics

5. **Email Campaign Lookup Table (Optional Enhancement):**
   - LKP_EMAIL_CAMPAIGN_DPD_MAPPING table
   - 2,901 campaigns → structured mapping
   - Pattern-based DPD bucket inference
   - ~100-300 campaigns require manual review

### Expected Performance Improvement

- **Before:** Timeout or multiple minutes per query
- **After:** Sub-second query response (<1 second)
- **Speedup:** 600-1000× faster
- **Dashboard refresh:** Every 12 hours (automated)

## Database Objects

### Primary Object

**Dynamic Table:** `BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES`
- Replaces view: VW_DSH_OUTBOUND_GENESYS_OUTREACHES
- View wrapper maintains backward compatibility

**Columns (23 total):**
1. ASOFDATE (DATE)
2. LOANSTATUS (VARCHAR) - DPD buckets
3. PORTFOLIONAME (VARCHAR)
4. PORTFOLIOID (VARCHAR)
5. ALL_ACTIVE_LOANS (NUMBER)
6. DQ_COUNT (NUMBER)
7-15. Phone metrics: CALL_LIST, CALL_ATTEMPTED, CONNECTIONS, VOICEMAILS_ATTEMPTED, VOICEMAILS_LEFT, RPCS, PTPS, OTPS, CONVERSIONS
16-21. Text metrics: TEXT_LIST, TEXTS_SENT, TEXT_RPCS, TEXT_PTPS, TEXT_OTPS, TEXT_CONVERSIONS
22-23. Email metrics: EMAILS_SENT, GR_EMAIL_LIST

### Supporting Object (Optional)

**Lookup Table:** `BUSINESS_INTELLIGENCE.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING`
- CAMPAIGN_NAME (VARCHAR, PK)
- DPD_BUCKET (VARCHAR) - DPD3-14, DPD15-29, etc.
- DPD_MIN, DPD_MAX (INT)
- SPECIAL_RULE (VARCHAR)
- ACTIVE_FLAG (BOOLEAN)
- CREATED_DATE, UPDATED_DATE (TIMESTAMP)

## Data Sources

### Source Tables

1. **BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS**
   - Base for phone_calls and sent_texts CTEs
   - Columns: PAYOFFUID, PORTFOLIONAME, DAYSPASTDUE, CHANNEL, inin-outbound-id, LOADDATE, RECORD_INSERT_DATE

2. **BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY**
   - Loan population and status information
   - **CRITICAL:** Scanned 3 times in original view, 1 time in optimized version
   - Columns: PAYOFFUID, LOANID, STATUS, DAYSPASTDUE, PORTFOLIONAME, PORTFOLIOID, ASOFDATE

3. **BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY**
   - Phone call disposition and metrics
   - Double join: inin-outbound-id AND PAYOFFUID+date
   - Columns: CONVERSATIONID, inin-outbound-id, PAYOFFUID, DISPOSITION_CODE, INTERACTION_START_TIME, ORIGINATINGDIRECTION, CALL_DIRECTION

4. **BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY**
   - SMS disposition and metrics
   - Double join: inin-outbound-id AND PAYOFFUID+date
   - Columns: CONVERSATIONID, inin-outbound-id, PAYOFFUID, DISPOSITION_CODE, INTERACTION_START_TIME, ORIGINATINGDIRECTION

5. **BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS**
   - Email send events from SFMC
   - Columns: SUBSCRIBER_KEY, DERIVED_PAYOFFUID, EVENT_DATE, SENT, SEND_TABLE_EMAIL_NAME

6. **BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST**
   - GR Email outbound list history
   - Columns: PAYOFFUID, LOAD_DATE, SET_NAME, SUPPRESSION_FLAG, LOAN_TAPE_ASOFDATE

7. **BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT**
   - Email attribution via subscriber key matching
   - Columns: CUSTOMER_ID, LOAN_ID, SCHEMA_NAME

8. **BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT**
   - Email attribution via application GUID
   - Columns: LOAN_ID, APPLICATION_GUID, ORIGINATION_DATE, APPLICATION_STARTED_DATE

## CTE Structure

### Optimized Dynamic Table CTEs

1. **min_dates** - Calculate minimum dates once (eliminates 6+ correlated subqueries)
2. **loan_tape_base** - Single scan of MVW_LOAN_TAPE_DAILY_HISTORY
3. **dqs** - Delinquent population metrics (active loans, delinquent count)
4. **phone_calls** - Phone outreach metrics (double join for campaign + manual calls)
5. **sent_texts** - SMS outreach metrics (double join for campaign + manual texts)
6. **subscriber_key_matching** - Email attribution logic
7. **emails_sent** - Email outreach metrics
8. **gr_email_lists** - GR Email list metrics
9. **Final SELECT** - Aggregate all metrics with COALESCE for zero defaults

### Business Logic

**DPD Bucket Logic (used 6 times):**
```sql
CASE
    WHEN status = 'Current' AND to_number(dayspastdue) < 3 THEN 'Current'
    WHEN to_number(dayspastdue) >= 3 AND to_number(dayspastdue) < 15 THEN 'DPD3-14'
    WHEN to_number(dayspastdue) >= 15 AND to_number(dayspastdue) < 30 THEN 'DPD15-29'
    WHEN to_number(dayspastdue) >= 30 AND to_number(dayspastdue) < 60 THEN 'DPD30-59'
    WHEN to_number(dayspastdue) >= 60 AND to_number(dayspastdue) < 90 THEN 'DPD60-89'
    WHEN to_number(dayspastdue) >= 90 THEN 'DPD90+'
    WHEN status = 'Sold' THEN 'Sold'
    WHEN status = 'Paid in Full' THEN 'Paid in Full'
    WHEN status = 'Charge off' THEN 'Charge off'
    WHEN status = 'Debt Settlement' THEN 'Debt Settlement'
    WHEN status = 'Cancelled' THEN 'Cancelled'
    WHEN status IS NULL THEN 'Originated'
END
```

**Phone/SMS Disposition Logic:**
- CONNECTIONS: Any disposition code present
- VOICEMAILS_ATTEMPTED: 'Other::Left Message', 'Voicemail Not Set Up or Full'
- VOICEMAILS_LEFT: 'Other::Left Message'
- RPCs: LEFT(DISPOSITION_CODE, 3) = 'MBR'
- PTPs: 'MBR::DPD::Promise to Pay (PTP)', 'MBR::Payment Requests::ACH Retry', 'MBR::Payment Type Change::Manual to ACH'
- OTPs: 'MBR::Payment Requests::One Time Payments (OTP)'
- CONVERSIONS: PTPs + OTPs

## Quality Control

### QC Test Suite (qc_validation.sql)

1. **Row Count Comparison** - Expect: Identical counts between view and dynamic table
2. **Date Range Validation** - Expect: Same min/max dates
3. **Duplicate Detection** - Expect: Zero duplicates on grain (ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID)
4. **Metric Sum Validation** - Expect: Within 0.1% variance for ALL_ACTIVE_LOANS, DQ_COUNT, CALL_ATTEMPTED, EMAILS_SENT
5. **Sample Row Comparison** - Expect: All 23 columns match exactly for random 100 rows
6. **Data Completeness** - Expect: Similar portfolio and status distributions
7. **Data Integrity** - Expect: No NULL values in key columns, DQ_COUNT <= ALL_ACTIVE_LOANS
8. **Performance Comparison** - Expect: Sub-second response for dynamic table
9. **Dynamic Table Health** - Expect: scheduling_state = 'ACTIVE'

### Known Issues

1. **Permission Limitations:**
   - Current role (BUSINESS_INTELLIGENCE_PII) lacks CREATE privileges on BUSINESS_INTELLIGENCE_DEV.REPORTING
   - SQL scripts complete and ready for authorized user (DBA/Admin)

2. **Email Campaign Mapping:**
   - Automated pattern parsing maps ~2,600 of 2,901 campaigns
   - ~100-300 campaigns require manual DPD bucket classification
   - Optional enhancement - initial deployment uses current hard-coded logic

## Implementation Notes

### Development Environment

- **Database:** BUSINESS_INTELLIGENCE_DEV
- **Schema:** REPORTING
- **Objects:**
  - DT_DSH_OUTBOUND_GENESYS_OUTREACHES (dynamic table)
  - LKP_EMAIL_CAMPAIGN_DPD_MAPPING (optional lookup table)

### Production Environment

- **Database:** BUSINESS_INTELLIGENCE
- **Schema:** REPORTING
- **Objects:**
  - DT_DSH_OUTBOUND_GENESYS_OUTREACHES (dynamic table)
  - VW_DSH_OUTBOUND_GENESYS_OUTREACHES (view wrapper for backward compatibility)
  - VW_DSH_OUTBOUND_GENESYS_OUTREACHES_BACKUP_20251001 (original view backup)

### Deployment Sequence

1. Backup original view (rename)
2. Create dynamic table
3. Create view wrapper (maintains interface)
4. Verify grants
5. Test query performance
6. Monitor dynamic table refresh

### Rollback Procedure

```sql
DROP VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
ALTER VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_BACKUP_20251001
  RENAME TO VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
DROP DYNAMIC TABLE BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES;
```

## File Organization

```
tickets/kchalmers/DI-1299/
├── README.md                                                    # Business summary
├── CLAUDE.md                                                    # This file - technical context
├── final_deliverables/
│   ├── 1_email_campaign_lookup_creation_dev.sql                # Optional lookup table
│   ├── 2_optimized_dynamic_table_dev.sql                       # Development dynamic table
│   └── 3_production_deployment.sql                             # Production deployment
├── qc_validation.sql                                            # Comprehensive QC (8 tests)
├── original_code/
│   └── original_view_ddl.sql                                   # Original view backup
└── source_materials/
    ├── data-object-initial.md                                   # Initial requirements
    └── snowflake-data-object-vw-dsh-outbound-genesys-outreaches.md  # Complete PRP
```

## Related Work

### Similar Tickets

- **DI-974:** DSH_GR_DAILY_ROLL_TRANSITION dynamic table optimization (reference pattern)
  - Same optimization techniques: shared CTEs, eliminate subqueries, dynamic table materialization
  - Located: tickets/kchalmers/DI-974/deliverables/sql_final/daily_roll_transition_table/deploy_dynamic_table.sql

### Documentation References

- **5-Layer Architecture:** documentation/README.md (FRESHSNOW → BRIDGE → ANALYTICS → REPORTING)
- **Database Deployment Template:** documentation/db_deploy_template.sql
- **Data Catalog:** documentation/data_catalog.md (MVW_LOAN_TAPE_DAILY_HISTORY, GENESYS views)

## Future Enhancements

1. **Email Campaign Lookup Table:** Replace hard-coded CASE statements with maintainable lookup table
2. **DPD Bucket UDF:** Create shared function to eliminate duplicated DPD logic
3. **Incremental Refresh:** Explore incremental refresh if data grain supports it
4. **Target Lag Adjustment:** Tune refresh frequency based on actual dashboard usage patterns
5. **Warehouse Size Optimization:** Monitor refresh times and adjust warehouse if needed

## Monitoring

### Post-Deployment Metrics

1. **Query Performance:**
   ```sql
   SELECT DATE(start_time) as query_date,
          COUNT(*) as query_count,
          AVG(execution_time) / 1000 as avg_seconds,
          MAX(execution_time) / 1000 as max_seconds
   FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
   WHERE query_text ILIKE '%VW_DSH_OUTBOUND_GENESYS_OUTREACHES%'
     AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
   GROUP BY 1
   ORDER BY 1 DESC;
   ```

2. **Dynamic Table Health:**
   ```sql
   SELECT name, target_lag, data_timestamp, scheduling_state, last_suspended_on
   FROM INFORMATION_SCHEMA.DYNAMIC_TABLES
   WHERE name = 'DT_DSH_OUTBOUND_GENESYS_OUTREACHES'
     AND schema_name = 'REPORTING'
     AND database_name = 'BUSINESS_INTELLIGENCE';
   ```

3. **Cost Monitoring:**
   ```sql
   SELECT DATE(start_time) as usage_date,
          warehouse_name,
          SUM(credits_used) as total_credits
   FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
   WHERE warehouse_name = 'BUSINESS_INTELLIGENCE'
     AND start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
   GROUP BY 1, 2
   ORDER BY 1 DESC;
   ```

## Contact

- **Assignee:** Kyle Chalmers (kchalmers@happymoney.com)
- **Stakeholders:** External Partners (dashboard users)
- **Epic:** DI-1238 (Data Object Alteration)
