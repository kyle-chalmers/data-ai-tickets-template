# PRP: Optimize VW_DSH_OUTBOUND_GENESYS_OUTREACHES Performance via Dynamic Table Conversion

## Executive Summary

**Operation Type:** ALTER_EXISTING
**Scope:** SINGLE_OBJECT
**Jira Ticket:** DI-1299
**Expected Ticket Folder:** `tickets/kchalmers/DI-1299/`
**Confidence Score:** 9/10

**Objective:** Convert `BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES` from a standard view to a dynamic table to dramatically improve query performance while maintaining identical results and full historical data.

**Current Performance Issues:**
- View scans 533M+ rows from MVW_LOAN_TAPE_DAILY_HISTORY multiple times (3 separate CTEs)
- Correlated subqueries execute 6+ times: `MIN(DATE(...)) from GENESYS_OUTBOUND_LIST_EXPORTS`
- Double joins to extremely large activity tables (VW_GENESYS_PHONECALL_ACTIVITY, VW_GENESYS_SMS_ACTIVITY)
- Queries timeout when attempting to materialize full results
- Complex email campaign mapping with 2,901 distinct campaign names hard-coded

**Optimization Strategy:**
1. Convert to dynamic table with 12-hour refresh lag
2. Create email campaign DPD lookup table (2,901 campaigns → structured mapping)
3. Eliminate correlated subqueries via materialized minimum date
4. Reduce MVW_LOAN_TAPE scans from 3 to 1 via shared CTE
5. Maintain double-join pattern for phone/SMS (business requirement)
6. Preserve full history (Oct 2023 - present, ~2 years)

## Business Context

**Business Purpose:** Provide external partners with daily outbound outreach metrics across phone, text, and email channels for delinquent loan populations.

**Key Stakeholders:** Kyle Chalmers, External Partners (critical dashboard dependency)

**Criticality:** HIGH - External reporting dependency, must maintain backward compatibility

**Data Grain:** Daily aggregated metrics by ASOFDATE, LOANSTATUS (DPD buckets), PORTFOLIONAME, PORTFOLIOID

**Time Period:** October 4, 2023 - Present (driven by GENESYS_OUTBOUND_LIST_EXPORTS availability)

**Key Metrics:**
- ALL_ACTIVE_LOANS, DQ_COUNT (delinquent population)
- CALL_LIST, CALL_ATTEMPTED, CONNECTIONS, VOICEMAILS, RPCs, PTPs, OTPs, CONVERSIONS (phone metrics)
- TEXT_LIST, TEXTS_SENT, TEXT_RPCs, TEXT_PTPs, TEXT_OTPs, TEXT_CONVERSIONS (text metrics)
- EMAILS_SENT, GR_EMAIL_LIST (email metrics)

## Current State Analysis

### Current Object DDL
```sql
-- BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
-- Object Type: VIEW
-- Current performance: Queries timeout or take multiple minutes
-- See data-object-initial.md lines 18-314 for complete current DDL
```

### Data Source Analysis

**Primary Sources:**

1. **BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS** (4.5M rows)
   - Date Range: 2023-10-04 to 2025-10-01
   - Channel Distribution: Phone (3.27M), Text (1.2M), Other (22)
   - Base table for phone_calls and sent_texts CTEs
   - Contains: PAYOFFUID, PORTFOLIONAME, DAYSPASTDUE, CHANNEL, inin-outbound-id, LOADDATE/RECORD_INSERT_DATE

2. **BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY** (533M rows)
   - 731 distinct dates since Oct 2023
   - **CRITICAL BOTTLENECK:** Scanned 3 times independently
   - Used in: dqs CTE, emails_sent CTE (2x), gr_email_lists CTE
   - Contains: PAYOFFUID, LOANID, STATUS, DAYSPASTDUE, PORTFOLIONAME, PORTFOLIOID, ASOFDATE

3. **BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY** (very large, queries timeout)
   - Contains: CONVERSATIONID, inin-outbound-id, PAYOFFUID, DISPOSITION_CODE, INTERACTION_START_TIME
   - Joined 2 ways: by inin-outbound-id AND by PAYOFFUID+date (business requirement for manual calls)

4. **BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY** (very large, queries timeout)
   - Contains: CONVERSATIONID, inin-outbound-id, PAYOFFUID, DISPOSITION_CODE, INTERACTION_START_TIME
   - Joined 2 ways: by inin-outbound-id AND by PAYOFFUID+date (business requirement for manual texts)

5. **BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS** (152M rows)
   - Date Range: 2018-04-09 to 2025-10-01
   - 2,901 distinct SEND_TABLE_EMAIL_NAME values (campaign names)
   - Contains: SUBSCRIBER_KEY, DERIVED_PAYOFFUID, EVENT_DATE, SENT, SEND_TABLE_EMAIL_NAME

6. **BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST** (5.1M rows for GR Email)
   - Contains: PAYOFFUID, LOAD_DATE, SET_NAME, SUPPRESSION_FLAG, LOAN_TAPE_ASOFDATE

**Supporting Tables:**

7. **BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT**
   - Used in subscriber_key_matching CTE for email attribution
   - Contains: CUSTOMER_ID, LOAN_ID, SCHEMA_NAME

8. **BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT**
   - Used in subscriber_key_matching CTE for email attribution
   - Contains: LOAN_ID, APPLICATION_GUID, ORIGINATION_DATE, APPLICATION_STARTED_DATE

### Performance Bottlenecks Identified

**CRITICAL BOTTLENECK #1: Correlated Subquery (6+ executions)**
```sql
-- Executed in dqs CTE, phone_calls CTE (2x), sent_texts CTE (2x), emails_sent CTE
DATE((Select MIN(DATE(DATEADD('day', -1, record_insert_date)))
      from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
```
**Impact:** MIN date calculation runs 6+ times, each scanning 4.5M rows
**Solution:** Materialize as variable/CTE once: `MIN_GENESYS_DATE`

**CRITICAL BOTTLENECK #2: MVW_LOAN_TAPE_DAILY_HISTORY Multiple Scans**
```sql
-- Scanned independently in 3 CTEs:
-- 1. dqs CTE: filters by status, aggregates by date/portfolio/loanstatus
-- 2. emails_sent CTE: joins to email events, complex DPD logic (2x due to coalesce)
-- 3. gr_email_lists CTE: joins to outbound lists history
```
**Impact:** 533M rows scanned 3 times = 1.6B row scans
**Solution:** Create shared `loan_tape_filtered` CTE with pre-filtered date range

**CRITICAL BOTTLENECK #3: Email Campaign Hard-Coding**
```sql
-- 2,901 distinct campaigns mapped via massive CASE statements
WHEN SEND_TABLE_EMAIL_NAME IN ('GR_Batch_DLQ_PastDue_4-14Days_EM1_0823',...50+ values...)
```
**Impact:** Query complexity, unmaintainable, difficult to add new campaigns
**Solution:** Create lookup table `LKP_EMAIL_CAMPAIGN_DPD_MAPPING`

**CRITICAL BOTTLENECK #4: Double Join Pattern (Required)**
```sql
-- phone_calls CTE and sent_texts CTE both use:
left join VW_GENESYS_PHONECALL_ACTIVITY a on a."inin-outbound-id" = c."inin-outbound-id"
left join VW_GENESYS_PHONECALL_ACTIVITY b on c.PAYOFFUID = b.PAYOFFUID and DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE)
```
**Impact:** Each activity table joined twice, extremely large tables
**Solution:** KEEP AS-IS (business requirement), but optimize with dynamic table materialization

**BOTTLENECK #5: Complex DPD Logic Duplication**
```sql
-- DPD bucket logic duplicated 6 times across CTEs:
CASE
    WHEN to_number(dayspastdue) < 3 THEN 'Current'
    WHEN to_number(dayspastdue) >= 3 AND to_number(dayspastdue) < 15 THEN 'DPD3-14'
    ...
END
```
**Impact:** Code duplication, maintenance burden
**Solution:** Create shared `dpd_bucket()` UDF or shared CTE

### Architecture Compliance

**Current State:**
- **Layer:** REPORTING (appropriate for Tableau dashboard)
- **References:** DATA_STORE (legacy), ANALYTICS_PII, PII, CRON_STORE, BRIDGE
- **Issue:** Using DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY (legacy schema)

**5-Layer Architecture Guidance:**
- REPORTING can reference: BRIDGE, ANALYTICS, REPORTING
- **Recommendation:** Continue using DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY (no ANALYTICS alternative exists)
- No changes needed to schema references for this optimization

### Existing Downstream Dependencies

**Known Dependencies:**
- External partner Tableau dashboard (CRITICAL - daily refresh requirement)
- Exact column names and data types must be preserved
- Results must match current view output exactly

**Backward Compatibility Requirements:**
- MAINTAIN: All 23 columns in exact order
- MAINTAIN: Data types, null handling, aggregation logic
- MAINTAIN: Date range (Oct 2023 - present)
- MAINTAIN: DPD bucket definitions and loan status categories

## Optimization Design

### Strategy 1: Convert to Dynamic Table

**Dynamic Table Configuration:**
```sql
CREATE OR REPLACE DYNAMIC TABLE BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES
target_lag = '12 hours'
refresh_mode = FULL  -- Complex query with multiple aggregations
initialize = ON_CREATE
warehouse = BUSINESS_INTELLIGENCE
COPY GRANTS
AS
[optimized query]
```

**Rationale:**
- **12-hour lag:** Balances cost with daily dashboard refresh needs
- **FULL refresh:** Complex aggregations, multiple sources, no incremental key
- **COPY GRANTS:** Preserves existing permissions for external partners
- **Materialization:** Pre-computes all expensive joins and aggregations

**Expected Performance Gain:**
- Current: Timeout or multiple minutes per query
- Expected: Sub-second query response (reading pre-materialized table)
- Dashboard refresh: 12 hours max (automated)

### Strategy 2: Create Email Campaign DPD Lookup Table

**New Lookup Table:**
```sql
CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING (
    CAMPAIGN_NAME VARCHAR(16777216) PRIMARY KEY,
    DPD_BUCKET VARCHAR(50),
    DPD_MIN INT,
    DPD_MAX INT,
    SPECIAL_RULE VARCHAR(200),
    ACTIVE_FLAG BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COPY GRANTS;
```

**Population Strategy:**
- Extract all 2,901 distinct campaign names from DSH_EMAIL_MONITORING_EVENTS
- Parse campaign naming patterns to infer DPD buckets:
  - `*_PastDue_3Days_*` → DPD3-14
  - `*_PastDue_15-29Days_*` → DPD15-29
  - `*_PastDue_30-59Days_*` → DPD30-59
  - `*_PastDue_60Days_*` or `*_60PlusDays_*` → DPD60-89 or DPD90+
- Flag special cases (e.g., `COL_Adhoc_DLQ_PastDue_3-59Days` needs DPD range validation)
- Allow manual override via SPECIAL_RULE field

**Integration:**
```sql
-- Replace massive CASE statement with:
CASE
    WHEN b.status = 'Current' AND to_number(b.dayspastdue) < 3 THEN 'Current'
    WHEN to_number(b.dayspastdue) BETWEEN lkp.DPD_MIN AND lkp.DPD_MAX THEN lkp.DPD_BUCKET
    WHEN lkp.SPECIAL_RULE IS NOT NULL THEN [evaluate special rule]
    WHEN to_number(b.dayspastdue) >= 3 AND to_number(b.dayspastdue) < 15 THEN 'DPD3-14'
    ...
END
FROM ...
LEFT JOIN LKP_EMAIL_CAMPAIGN_DPD_MAPPING lkp ON a.SEND_TABLE_EMAIL_NAME = lkp.CAMPAIGN_NAME
```

**Maintenance:**
- New campaigns auto-detected via monitoring
- DBA updates lookup table vs. ALTER VIEW
- Version control via UPDATED_DATE

### Strategy 3: Eliminate Correlated Subqueries

**Current (6+ executions):**
```sql
WHERE DATE(asofdate) >= DATE((Select MIN(DATE(DATEADD('day', -1, record_insert_date)))
                              from BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS))
```

**Optimized (1 execution):**
```sql
WITH min_dates AS (
    SELECT
        MIN(DATE(DATEADD('day', -1, record_insert_date))) as min_record_insert_date,
        MIN(DATE(LOADDATE)) as min_loaddate,
        MIN(DATE(RECORD_INSERT_DATE)) as min_text_date
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
),
dqs AS (
    SELECT ...
    FROM MVW_LOAN_TAPE_DAILY_HISTORY dlt
    CROSS JOIN min_dates md
    WHERE DATE(asofdate) >= md.min_record_insert_date
    ...
)
```

**Impact:** 6+ scans of 4.5M rows → 1 scan

### Strategy 4: Reduce MVW_LOAN_TAPE Scans

**Current (3 independent scans):**
1. dqs CTE: Active loans by status
2. emails_sent CTE: Email matching via PAYOFFUID+date
3. gr_email_lists CTE: GR email list matching via PAYOFFUID+date

**Optimized (1 scan, reused via CTE):**
```sql
WITH min_dates AS (...),
loan_tape_filtered AS (
    SELECT
        ASOFDATE,
        PAYOFFUID,
        LOANID,
        STATUS,
        DAYSPASTDUE,
        PORTFOLIONAME,
        PORTFOLIOID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    CROSS JOIN min_dates md
    WHERE DATE(ASOFDATE) >= md.min_record_insert_date
        AND STATUS NOT IN ('Sold', 'Charge off', 'Paid in Full', 'Debt Settlement', 'Cancelled')
),
dqs AS (
    SELECT
        DATE(asofdate) AS ASOFDATE,
        [DPD bucket CASE] AS loanstatus,
        portfolioname,
        REPLACE(TO_CHAR(portfolioid), '.00000', '') as portfolioid,
        COUNT(DISTINCT loanid) AS all_active_loans,
        COUNT(DISTINCT CASE WHEN loanstatus IN (...delinquent statuses...) THEN loanid END) AS dq_count
    FROM loan_tape_filtered
    GROUP BY 1, 2, 3, 4
),
emails_sent AS (
    SELECT ...
    FROM DSH_EMAIL_MONITORING_EVENTS a
    LEFT JOIN subscriber_key_matching c ON ...
    INNER JOIN loan_tape_filtered b ON ...  -- Reuse filtered CTE
    ...
),
gr_email_lists AS (
    SELECT ...
    FROM RPT_OUTBOUND_LISTS_HIST OL
    INNER JOIN loan_tape_filtered LT ON ...  -- Reuse filtered CTE
    ...
)
```

**Impact:** 533M rows × 3 scans = 1.6B row scans → 533M rows × 1 scan

**Critical Note for dqs CTE:**
- Current dqs filters: `STATUS NOT IN ('Sold', 'Charge off', ...)`
- Other CTEs need full status range
- **Solution:** Apply dqs-specific filter AFTER shared CTE scan

### Strategy 5: Create DPD Bucket UDF (Optional Enhancement)

**User-Defined Function:**
```sql
CREATE OR REPLACE FUNCTION BUSINESS_INTELLIGENCE.REPORTING.GET_DPD_BUCKET(
    p_status VARCHAR,
    p_dayspastdue NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    CASE
        WHEN p_status = 'Current' AND p_dayspastdue < 3 THEN 'Current'
        WHEN p_dayspastdue >= 3 AND p_dayspastdue < 15 THEN 'DPD3-14'
        WHEN p_dayspastdue >= 15 AND p_dayspastdue < 30 THEN 'DPD15-29'
        WHEN p_dayspastdue >= 30 AND p_dayspastdue < 60 THEN 'DPD30-59'
        WHEN p_dayspastdue >= 60 AND p_dayspastdue < 90 THEN 'DPD60-89'
        WHEN p_dayspastdue >= 90 THEN 'DPD90+'
        WHEN p_status = 'Sold' THEN 'Sold'
        WHEN p_status = 'Paid in Full' THEN 'Paid in Full'
        WHEN p_status = 'Charge off' THEN 'Charge off'
        WHEN p_status = 'Debt Settlement' THEN 'Debt Settlement'
        WHEN p_status = 'Cancelled' THEN 'Cancelled'
        WHEN p_status IS NULL THEN 'Originated'
    END
$$;
```

**Usage:**
```sql
GET_DPD_BUCKET(dlt.status, to_number(dlt.dayspastdue)) AS loanstatus
```

**Impact:** Code standardization, reduced duplication (6 instances → 1 UDF)

### Strategy 6: Maintain Double-Join Pattern

**Business Requirement:**
> Manual calls made outside of campaigns are not associated with campaigns, so even though it was meant to be a part of this campaign, it would not have been noted as such. This double join - specifically the join by payoffuid and date, solves for that issue.

**Current Implementation (KEEP AS-IS):**
```sql
-- Join A: Campaign-based calls via inin-outbound-id
left join VW_GENESYS_PHONECALL_ACTIVITY a
    on a."inin-outbound-id" = c."inin-outbound-id"
    and DATE(a.INTERACTION_START_TIME) >= [min_date]

-- Join B: Manual calls via PAYOFFUID + date
left join VW_GENESYS_PHONECALL_ACTIVITY b
    on c.PAYOFFUID = b.PAYOFFUID
    and DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE)
    and b.ORIGINATINGDIRECTION = 'outbound'
    and b.CALL_DIRECTION = 'outbound'
    and c."CallRecordLastAttempt-PHONE" is null
    and DATE(b.INTERACTION_START_TIME) >= [min_date]

-- Metrics coalesce both joins:
count(distinct COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)) as call_attempted
```

**Optimization:** Dynamic table materialization pre-computes these expensive joins

**Same pattern for SMS:**
- sent_texts CTE maintains double join to VW_GENESYS_SMS_ACTIVITY
- Coalesces CONVERSATIONID from both join paths

## Implementation Blueprint

### Phase 1: Development Environment Setup

**Create Development Objects:**

1. **Email Campaign Lookup Table (Dev):**
```sql
-- Create in DEVELOPMENT database for testing
CREATE OR REPLACE TABLE DEVELOPMENT.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING (
    CAMPAIGN_NAME VARCHAR(16777216) PRIMARY KEY,
    DPD_BUCKET VARCHAR(50),
    DPD_MIN INT,
    DPD_MAX INT,
    SPECIAL_RULE VARCHAR(200),
    ACTIVE_FLAG BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Populate with campaign pattern parsing logic (see population script)
INSERT INTO DEVELOPMENT.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING
SELECT DISTINCT
    SEND_TABLE_EMAIL_NAME as CAMPAIGN_NAME,
    CASE
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%3Days%' OR SEND_TABLE_EMAIL_NAME LIKE '%3-14%' THEN 'DPD3-14'
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%15-29%' THEN 'DPD15-29'
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-59%' OR SEND_TABLE_EMAIL_NAME LIKE '%45Days%' THEN 'DPD30-59'
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60%' AND SEND_TABLE_EMAIL_NAME NOT LIKE '%90%' THEN 'DPD60-89'
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60Plus%' OR SEND_TABLE_EMAIL_NAME LIKE '%90%' THEN 'DPD90+'
        ELSE NULL  -- Requires manual review
    END as DPD_BUCKET,
    CASE
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%3-14%' THEN 3
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%15-29%' THEN 15
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-59%' THEN 30
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60-89%' THEN 60
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60Plus%' OR SEND_TABLE_EMAIL_NAME LIKE '%90%' THEN 90
    END as DPD_MIN,
    CASE
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%3-14%' THEN 14
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%15-29%' THEN 29
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%30-59%' THEN 59
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60-89%' THEN 89
        WHEN SEND_TABLE_EMAIL_NAME LIKE '%60Plus%' OR SEND_TABLE_EMAIL_NAME LIKE '%90%' THEN 9999
    END as DPD_MAX,
    NULL as SPECIAL_RULE,
    TRUE as ACTIVE_FLAG,
    CURRENT_TIMESTAMP() as CREATED_DATE,
    CURRENT_TIMESTAMP() as UPDATED_DATE
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS
WHERE SEND_TABLE_EMAIL_NAME IS NOT NULL;

-- Manual review and updates for NULL DPD_BUCKET campaigns
-- (Approximately 200-300 campaigns may need manual classification)
```

2. **DPD Bucket UDF (Optional - Dev):**
```sql
CREATE OR REPLACE FUNCTION DEVELOPMENT.REPORTING.GET_DPD_BUCKET(
    p_status VARCHAR,
    p_dayspastdue NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    CASE
        WHEN p_status = 'Current' AND p_dayspastdue < 3 THEN 'Current'
        WHEN p_dayspastdue >= 3 AND p_dayspastdue < 15 THEN 'DPD3-14'
        WHEN p_dayspastdue >= 15 AND p_dayspastdue < 30 THEN 'DPD15-29'
        WHEN p_dayspastdue >= 30 AND p_dayspastdue < 60 THEN 'DPD30-59'
        WHEN p_dayspastdue >= 60 AND p_dayspastdue < 90 THEN 'DPD60-89'
        WHEN p_dayspastdue >= 90 THEN 'DPD90+'
        WHEN p_status = 'Sold' THEN 'Sold'
        WHEN p_status = 'Paid in Full' THEN 'Paid in Full'
        WHEN p_status = 'Charge off' THEN 'Charge off'
        WHEN p_status = 'Debt Settlement' THEN 'Debt Settlement'
        WHEN p_status = 'Cancelled' THEN 'Cancelled'
        WHEN p_status IS NULL THEN 'Originated'
    END
$$;
```

3. **Optimized Dynamic Table (Dev):**
```sql
CREATE OR REPLACE DYNAMIC TABLE DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES
target_lag = '12 hours'
refresh_mode = FULL
initialize = ON_CREATE
warehouse = BUSINESS_INTELLIGENCE
AS
WITH min_dates AS (
    SELECT
        MIN(DATE(DATEADD('day', -1, record_insert_date))) as min_record_insert_date,
        MIN(DATE(LOADDATE)) as min_loaddate
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS
),
loan_tape_base AS (
    -- Single scan of 533M row table with date filter
    SELECT
        ASOFDATE,
        PAYOFFUID,
        LOANID,
        STATUS,
        DAYSPASTDUE,
        PORTFOLIONAME,
        PORTFOLIOID
    FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY
    CROSS JOIN min_dates md
    WHERE DATE(ASOFDATE) >= md.min_record_insert_date
),
dqs AS (
    SELECT
        DATE(asofdate) AS ASOFDATE,
        CASE
            WHEN dlt.status = 'Current' AND to_number(dlt.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(dlt.dayspastdue) >= 3 AND to_number(dlt.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(dlt.dayspastdue) >= 15 AND to_number(dlt.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(dlt.dayspastdue) >= 30 AND to_number(dlt.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(dlt.dayspastdue) >= 60 AND to_number(dlt.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(dlt.dayspastdue) >= 90 THEN 'DPD90+'
            WHEN dlt.status = 'Sold' THEN 'Sold'
            WHEN dlt.status = 'Paid in Full' THEN 'Paid in Full'
            WHEN dlt.status = 'Charge off' THEN 'Charge off'
            WHEN dlt.status = 'Debt Settlement' THEN 'Debt Settlement'
            WHEN dlt.status = 'Cancelled' THEN 'Cancelled'
            WHEN dlt.status IS NULL THEN 'Originated'
        END AS loanstatus,
        portfolioname,
        REPLACE(TO_CHAR(portfolioid), '.00000', '') as portfolioid,
        COUNT(DISTINCT loanid) AS all_active_loans,
        COUNT(DISTINCT CASE
            WHEN loanstatus IN ('DPD90+', 'DPD60-89', 'DPD30-59', 'DPD15-29', 'DPD3-14')
                THEN loanid
            ELSE NULL
        END) AS dq_count
    FROM loan_tape_base dlt
    WHERE status NOT IN ('Sold', 'Charge off', 'Paid in Full', 'Debt Settlement', 'Cancelled')
    GROUP BY 1, 2, 3, 4
),
phone_calls AS (
    SELECT
        CASE
            WHEN to_number(c.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(c.dayspastdue) >= 3 AND to_number(c.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(c.dayspastdue) >= 15 AND to_number(c.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(c.dayspastdue) >= 30 AND to_number(c.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(c.dayspastdue) >= 60 AND to_number(c.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(c.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        c.PORTFOLIONAME,
        DATE(LOADDATE) as asofdate,
        count(DISTINCT c.PAYOFFUID) as call_list,
        count(distinct COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)) as call_attempted,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IS NOT NULL
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS connections,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN ('Other::Left Message', 'Voicemail Not Set Up or Full')
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS voicemails_attempted,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'Other::Left Message'
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS voicemails_left,
        COUNT(DISTINCT CASE
            WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS RPCs,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN (
                'MBR::DPD::Promise to Pay (PTP)',
                'MBR::Payment Requests::ACH Retry',
                'MBR::Payment Type Change::Manual to ACH')
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS PTPs,
        COUNT(DISTINCT CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'MBR::Payment Requests::One Time Payments (OTP)'
                THEN COALESCE(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS OTPs,
        PTPs + OTPs AS conversions
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
    CROSS JOIN min_dates md
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY a
        ON a."inin-outbound-id" = c."inin-outbound-id"
        AND DATE(a.INTERACTION_START_TIME) >= md.min_loaddate
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_PHONECALL_ACTIVITY b
        ON c.PAYOFFUID = b.PAYOFFUID
        AND DATE(b.INTERACTION_START_TIME) = DATE(LOADDATE)
        AND b.ORIGINATINGDIRECTION = 'outbound'
        AND b.CALL_DIRECTION = 'outbound'
        AND c."CallRecordLastAttempt-PHONE" is null
        AND DATE(b.INTERACTION_START_TIME) >= md.min_loaddate
    WHERE c.CHANNEL = 'Phone'
    GROUP BY c.PORTFOLIONAME, asofdate, loanstatus
),
sent_texts AS (
    SELECT
        c.PORTFOLIONAME,
        CASE
            WHEN to_number(c.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(c.dayspastdue) >= 3 AND to_number(c.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(c.dayspastdue) >= 15 AND to_number(c.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(c.dayspastdue) >= 30 AND to_number(c.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(c.dayspastdue) >= 60 AND to_number(c.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(c.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        DATE(DATEADD('day', -1, c.RECORD_INSERT_DATE)) as asofdate,
        count(*) as text_list,
        count(coalesce(a.CONVERSATIONID, b.CONVERSATIONID)) as texts_sent,
        COUNT(CASE
            WHEN LEFT(COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE), 3) = 'MBR'
                THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS text_RPCs,
        COUNT(CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) IN (
                'MBR::DPD::Promise to Pay (PTP)',
                'MBR::Payment Requests::ACH Retry',
                'MBR::Payment Type Change::Manual to ACH')
                THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS text_PTPs,
        COUNT(CASE
            WHEN COALESCE(a.DISPOSITION_CODE, b.DISPOSITION_CODE) = 'MBR::Payment Requests::One Time Payments (OTP)'
                THEN coalesce(a.CONVERSATIONID, b.CONVERSATIONID)
            ELSE NULL
        END) AS text_OTPs,
        text_PTPs + text_OTPs AS text_conversions
    FROM BUSINESS_INTELLIGENCE.ANALYTICS_PII.GENESYS_OUTBOUND_LIST_EXPORTS c
    CROSS JOIN min_dates md
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY a
        ON a."inin-outbound-id" = c."inin-outbound-id"
        AND DATE(a.INTERACTION_START_TIME) >= md.min_record_insert_date
    LEFT JOIN BUSINESS_INTELLIGENCE.PII.VW_GENESYS_SMS_ACTIVITY b
        ON c.PAYOFFUID = b.PAYOFFUID
        AND DATE(b.INTERACTION_START_TIME) = DATE(DATEADD('day', -1, c.record_insert_date))
        AND b.ORIGINATINGDIRECTION = 'outbound'
        AND c."SmsLastAttempt-PHONE" is null
        AND DATE(b.INTERACTION_START_TIME) >= md.min_record_insert_date
    WHERE c.CHANNEL = 'Text'
    GROUP BY c.PORTFOLIONAME, loanstatus, asofdate
),
subscriber_key_matching AS (
    SELECT
        vlcc.CUSTOMER_ID,
        vlcc.LOAN_ID as APPLICATION_ID,
        va.APPLICATION_GUID
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_CUSTOMER_CURRENT VLCC
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT VA
        ON VA.LOAN_ID::VARCHAR = VLCC.LOAN_ID::VARCHAR
    WHERE VLCC.SCHEMA_NAME = ARCA.CONFIG.LOS_SCHEMA()
    QUALIFY row_number() over (partition by vlcc.CUSTOMER_ID order by ORIGINATION_DATE desc, APPLICATION_STARTED_DATE desc) = 1
),
emails_sent AS (
    SELECT
        sum(a.sent) as emails_sent,
        date(a.EVENT_DATE) as ASOFDATE,
        CASE
            WHEN b.status = 'Current' AND to_number(b.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(b.dayspastdue) >= 3 AND to_number(b.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(b.dayspastdue) >= 15 AND to_number(b.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(b.dayspastdue) >= 30 AND to_number(b.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(b.dayspastdue) >= 60 AND to_number(b.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(b.dayspastdue) >= 90 THEN 'DPD90+'
            WHEN b.status = 'Sold' THEN 'Sold'
            WHEN b.status = 'Paid in Full' THEN 'Paid in Full'
            WHEN b.status = 'Charge off' THEN 'Charge off'
            WHEN b.status = 'Debt Settlement' THEN 'Debt Settlement'
            WHEN b.status = 'Cancelled' THEN 'Cancelled'
            WHEN b.status IS NULL THEN 'Originated'
        END AS LOANSTATUS,
        b.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
    LEFT JOIN subscriber_key_matching c
        ON a.SUBSCRIBER_KEY::VARCHAR = c.CUSTOMER_ID::VARCHAR
    INNER JOIN loan_tape_base b
        ON COALESCE(a.DERIVED_PAYOFFUID, c.APPLICATION_GUID) = b.PAYOFFUID
        AND date(a.EVENT_DATE) = DATEADD('day', 1, b.ASOFDATE)
    GROUP BY b.PORTFOLIONAME, LOANSTATUS, date(a.EVENT_DATE)
    HAVING sum(a.SENT) > 0
),
gr_email_lists AS (
    SELECT
        count(OL.PAYOFFUID) AS gr_email_list,
        OL.LOAD_DATE as ASOFDATE,
        CASE
            WHEN to_number(LT.dayspastdue) < 3 THEN 'Current'
            WHEN to_number(LT.dayspastdue) >= 3 AND to_number(LT.dayspastdue) < 15 THEN 'DPD3-14'
            WHEN to_number(LT.dayspastdue) >= 15 AND to_number(LT.dayspastdue) < 30 THEN 'DPD15-29'
            WHEN to_number(LT.dayspastdue) >= 30 AND to_number(LT.dayspastdue) < 60 THEN 'DPD30-59'
            WHEN to_number(LT.dayspastdue) >= 60 AND to_number(LT.dayspastdue) < 90 THEN 'DPD60-89'
            WHEN to_number(LT.dayspastdue) >= 90 THEN 'DPD90+'
        END AS loanstatus,
        LT.PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE.CRON_STORE.RPT_OUTBOUND_LISTS_HIST OL
    INNER JOIN loan_tape_base LT
        ON OL.PAYOFFUID = LT.PAYOFFUID
        AND OL.LOAN_TAPE_ASOFDATE = LT.ASOFDATE
    WHERE OL.SET_NAME = 'GR Email'
        AND OL.SUPPRESSION_FLAG = false
    GROUP BY LT.PORTFOLIONAME, loanstatus, OL.LOAD_DATE
)
SELECT
    dqs.*,
    coalesce(pc.call_list, 0) as call_list,
    coalesce(pc.call_attempted, 0) as call_attempted,
    coalesce(pc.connections, 0) as connections,
    coalesce(pc.voicemails_attempted, 0) as voicemails_attempted,
    coalesce(pc.voicemails_left, 0) as voicemails_left,
    coalesce(pc.RPCs, 0) as RPCs,
    coalesce(pc.PTPs, 0) as PTPs,
    coalesce(pc.OTPs, 0) as OTPs,
    coalesce(pc.conversions, 0) as conversions,
    coalesce(st.text_list, 0) as text_list,
    coalesce(texts_sent, 0) as texts_sent,
    coalesce(text_RPCs, 0) as text_RPCs,
    coalesce(text_PTPs, 0) as text_PTPs,
    coalesce(text_OTPs, 0) as text_OTPs,
    coalesce(text_conversions, 0) as text_conversions,
    coalesce(es.emails_sent, 0) as emails_sent,
    coalesce(el.gr_email_list, 0) as gr_email_list
FROM dqs
LEFT JOIN phone_calls pc
    ON dqs.PORTFOLIONAME = pc.PORTFOLIONAME
    AND dqs.loanstatus = pc.loanstatus
    AND dqs.ASOFDATE = pc.asofdate
LEFT JOIN sent_texts st
    ON dqs.PORTFOLIONAME = st.PORTFOLIONAME
    AND dqs.loanstatus = st.loanstatus
    AND dqs.ASOFDATE = st.asofdate
LEFT JOIN emails_sent es
    ON dqs.PORTFOLIONAME = es.PORTFOLIONAME
    AND dqs.loanstatus = es.loanstatus
    AND dqs.ASOFDATE = es.asofdate
LEFT JOIN gr_email_lists el
    ON dqs.PORTFOLIONAME = el.PORTFOLIONAME
    AND dqs.loanstatus = el.loanstatus
    AND dqs.ASOFDATE = el.asofdate;
```

### Phase 2: Independent Validation & Testing

**CRITICAL: Implementer Must Perform Independent Data Exploration**

Before blindly following this PRP, the implementer MUST:

1. **Validate Data Grain Assumptions:**
   - Run record count analysis: GENESYS_OUTBOUND_LIST_EXPORTS by PAYOFFUID, LOADDATE
   - Check for duplicates in base tables
   - Confirm expected cardinality of joins

2. **Test Date Range Logic:**
   - Verify MIN(DATE(...)) calculations produce expected start dates
   - Confirm all CTEs cover same time period (Oct 2023 - present)
   - Check for data gaps or unexpected date ranges

3. **Validate Double-Join Pattern:**
   - Sample 100 random phone calls and verify coalesce logic
   - Confirm manual calls (join B) not in campaigns (join A)
   - Test edge cases: same CONVERSATIONID in both joins

4. **Test Email Campaign Lookup:**
   - Verify all 2,901 campaigns mapped correctly
   - Check for NULL DPD_BUCKET campaigns (require manual review)
   - Compare lookup-based DPD assignment vs. hard-coded CASE results

**Quality Control Tests (qc_validation.sql):**

```sql
-- Test 1: Row Count Comparison (Current View vs Dynamic Table)
-- Expected: Identical row counts
SELECT 'Row Count Comparison' as test_name,
       (SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES) as current_view_count,
       (SELECT COUNT(*) FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES) as dynamic_table_count,
       CASE
           WHEN current_view_count = dynamic_table_count THEN 'PASS'
           ELSE 'FAIL: Row count mismatch'
       END as result;

-- Test 2: Date Range Validation
-- Expected: Same min/max dates
SELECT 'Date Range Validation' as test_name,
       (SELECT MIN(ASOFDATE) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES) as view_min_date,
       (SELECT MAX(ASOFDATE) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES) as view_max_date,
       (SELECT MIN(ASOFDATE) FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES) as dt_min_date,
       (SELECT MAX(ASOFDATE) FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES) as dt_max_date,
       CASE
           WHEN view_min_date = dt_min_date AND view_max_date = dt_max_date THEN 'PASS'
           ELSE 'FAIL: Date range mismatch'
       END as result;

-- Test 3: Duplicate Detection
-- Expected: Zero duplicates on ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID
SELECT 'Duplicate Detection' as test_name,
       COUNT(*) as duplicate_count,
       CASE
           WHEN COUNT(*) = 0 THEN 'PASS'
           ELSE 'FAIL: Duplicates found'
       END as result
FROM (
    SELECT ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID, COUNT(*) as cnt
    FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES
    GROUP BY 1, 2, 3, 4
    HAVING COUNT(*) > 1
);

-- Test 4: Metric Sum Validation (All Active Loans)
-- Expected: Within 0.1% variance (account for timing differences)
SELECT 'All Active Loans Sum Validation' as test_name,
       (SELECT SUM(ALL_ACTIVE_LOANS) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES) as view_sum,
       (SELECT SUM(ALL_ACTIVE_LOANS) FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES) as dt_sum,
       ABS(view_sum - dt_sum) as difference,
       ABS(view_sum - dt_sum) / NULLIF(view_sum, 0) * 100 as pct_difference,
       CASE
           WHEN pct_difference < 0.1 THEN 'PASS'
           ELSE 'FAIL: Metric sum exceeds 0.1% variance'
       END as result;

-- Test 5: Sample Row Comparison (Random 100 rows)
-- Expected: All 23 columns match exactly
WITH sample_keys AS (
    SELECT ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID
    FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES
    ORDER BY RANDOM()
    LIMIT 100
),
view_sample AS (
    SELECT v.*
    FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES v
    INNER JOIN sample_keys s
        ON v.ASOFDATE = s.ASOFDATE
        AND v.LOANSTATUS = s.LOANSTATUS
        AND v.PORTFOLIONAME = s.PORTFOLIONAME
        AND v.PORTFOLIOID = s.PORTFOLIOID
),
dt_sample AS (
    SELECT d.*
    FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES d
    INNER JOIN sample_keys s
        ON d.ASOFDATE = s.ASOFDATE
        AND d.LOANSTATUS = s.LOANSTATUS
        AND d.PORTFOLIONAME = s.PORTFOLIONAME
        AND d.PORTFOLIOID = s.PORTFOLIOID
)
SELECT
    'Sample Row Comparison' as test_name,
    COUNT(*) as mismatch_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL: Sample rows have mismatches'
    END as result
FROM (
    SELECT * FROM view_sample
    EXCEPT
    SELECT * FROM dt_sample
    UNION ALL
    SELECT * FROM dt_sample
    EXCEPT
    SELECT * FROM view_sample
);

-- Test 6: Email Campaign Lookup Coverage
-- Expected: All campaigns in DSH_EMAIL_MONITORING_EVENTS are in lookup table
SELECT 'Email Campaign Lookup Coverage' as test_name,
       COUNT(DISTINCT a.SEND_TABLE_EMAIL_NAME) as total_campaigns,
       COUNT(DISTINCT l.CAMPAIGN_NAME) as mapped_campaigns,
       total_campaigns - mapped_campaigns as unmapped_count,
       CASE
           WHEN unmapped_count = 0 THEN 'PASS'
           ELSE 'WARNING: ' || unmapped_count || ' campaigns not in lookup table'
       END as result
FROM BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_MONITORING_EVENTS a
LEFT JOIN DEVELOPMENT.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING l
    ON a.SEND_TABLE_EMAIL_NAME = l.CAMPAIGN_NAME
WHERE a.SEND_TABLE_EMAIL_NAME IS NOT NULL;

-- Test 7: Performance Baseline (Current View - may timeout)
-- Run with LIMIT to avoid timeout
SELECT 'Current View Performance Baseline' as test_name,
       COUNT(*) as row_count,
       MIN(ASOFDATE) as min_date,
       MAX(ASOFDATE) as max_date
FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
LIMIT 100000;

-- Test 8: Performance Comparison (Dynamic Table)
-- Expected: Sub-second response
SELECT 'Dynamic Table Performance' as test_name,
       COUNT(*) as row_count,
       MIN(ASOFDATE) as min_date,
       MAX(ASOFDATE) as max_date
FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES;
```

### Phase 3: Production Deployment

**Deployment Script Template:**

```sql
-- PRE-DEPLOYMENT CHECKLIST:
-- [ ] All QC tests passed in development
-- [ ] Email campaign lookup table reviewed and approved
-- [ ] Performance testing shows significant improvement
-- [ ] Stakeholder notification sent (external dashboard may refresh slower initially)
-- [ ] Backup plan documented (revert to original view)

-- DEPLOYMENT SEQUENCE:

-- Step 1: Create Production Email Campaign Lookup Table
CREATE OR REPLACE TABLE BUSINESS_INTELLIGENCE.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING (
    CAMPAIGN_NAME VARCHAR(16777216) PRIMARY KEY,
    DPD_BUCKET VARCHAR(50),
    DPD_MIN INT,
    DPD_MAX INT,
    SPECIAL_RULE VARCHAR(200),
    ACTIVE_FLAG BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
) COPY GRANTS;

-- Copy from dev (after manual review/cleanup)
INSERT INTO BUSINESS_INTELLIGENCE.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING
SELECT * FROM DEVELOPMENT.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING;

-- Step 2: Create Production DPD UDF (Optional)
CREATE OR REPLACE FUNCTION BUSINESS_INTELLIGENCE.REPORTING.GET_DPD_BUCKET(
    p_status VARCHAR,
    p_dayspastdue NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    CASE
        WHEN p_status = 'Current' AND p_dayspastdue < 3 THEN 'Current'
        WHEN p_dayspastdue >= 3 AND p_dayspastdue < 15 THEN 'DPD3-14'
        WHEN p_dayspastdue >= 15 AND p_dayspastdue < 30 THEN 'DPD15-29'
        WHEN p_dayspastdue >= 30 AND p_dayspastdue < 60 THEN 'DPD30-59'
        WHEN p_dayspastdue >= 60 AND p_dayspastdue < 90 THEN 'DPD60-89'
        WHEN p_dayspastdue >= 90 THEN 'DPD90+'
        WHEN p_status = 'Sold' THEN 'Sold'
        WHEN p_status = 'Paid in Full' THEN 'Paid in Full'
        WHEN p_status = 'Charge off' THEN 'Charge off'
        WHEN p_status = 'Debt Settlement' THEN 'Debt Settlement'
        WHEN p_status = 'Cancelled' THEN 'Cancelled'
        WHEN p_status IS NULL THEN 'Originated'
    END
$$;

-- Step 3: Rename Current View (Backup)
ALTER VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
RENAME TO VW_DSH_OUTBOUND_GENESYS_OUTREACHES_BACKUP_20251001;

-- Step 4: Create Dynamic Table (Using CREATE OR REPLACE for new name)
CREATE OR REPLACE DYNAMIC TABLE BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES
target_lag = '12 hours'
refresh_mode = FULL
initialize = ON_CREATE
warehouse = BUSINESS_INTELLIGENCE
COPY GRANTS
AS
[Full optimized query from Phase 1, Step 3];

-- Step 5: Create View Wrapper for Backward Compatibility
-- External dashboards query VW_DSH_OUTBOUND_GENESYS_OUTREACHES
CREATE OR REPLACE VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES
COPY GRANTS
AS
SELECT * FROM BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES;

-- Step 6: Verify Grants
SHOW GRANTS ON VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
SHOW GRANTS ON DYNAMIC TABLE BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES;

-- Step 7: Test Query Performance
SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
-- Expected: Sub-second response

-- Step 8: Monitor Dynamic Table Refresh
SHOW DYNAMIC TABLES LIKE 'DT_DSH_OUTBOUND_GENESYS_OUTREACHES';
-- Check SCHEDULING_STATE, REFRESH_MODE, TARGET_LAG

-- ROLLBACK PLAN (if issues arise):
-- DROP VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
-- ALTER VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES_BACKUP_20251001
--   RENAME TO VW_DSH_OUTBOUND_GENESYS_OUTREACHES;
-- DROP DYNAMIC TABLE BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES;
```

### Phase 4: Post-Deployment Monitoring

**Monitoring Tasks:**

1. **Dynamic Table Health:**
```sql
-- Check refresh status
SELECT
    name,
    target_lag,
    data_timestamp,
    scheduling_state,
    last_suspended_on
FROM INFORMATION_SCHEMA.DYNAMIC_TABLES
WHERE name = 'DT_DSH_OUTBOUND_GENESYS_OUTREACHES'
    AND schema_name = 'REPORTING'
    AND database_name = 'BUSINESS_INTELLIGENCE';
```

2. **Query Performance Metrics:**
```sql
-- Monitor query performance over 7 days
SELECT
    DATE(start_time) as query_date,
    COUNT(*) as query_count,
    AVG(execution_time) / 1000 as avg_seconds,
    MAX(execution_time) / 1000 as max_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_text ILIKE '%VW_DSH_OUTBOUND_GENESYS_OUTREACHES%'
    AND start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY 1 DESC;
```

3. **Cost Monitoring:**
```sql
-- Compare warehouse credit usage before/after
SELECT
    DATE(start_time) as usage_date,
    warehouse_name,
    SUM(credits_used) as total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE warehouse_name = 'BUSINESS_INTELLIGENCE'
    AND start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY 1, 2
ORDER BY 1 DESC;
```

4. **Stakeholder Communication:**
   - Email external partners: Dashboard now auto-refreshes every 12 hours
   - Note: First query may take 10-30 seconds (warming dynamic table)
   - Subsequent queries: Sub-second response
   - Escalation contact: Kyle Chalmers

## Validation Gates

**All validation gates must pass before production deployment:**

### Development Environment Validation

```bash
# 1. Verify development dynamic table creation
snow sql -q "DESCRIBE DYNAMIC TABLE DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES" --format csv

# 2. Run comprehensive QC validation
snow sql -q "$(cat qc_validation.sql)" --format csv > qc_results.csv
# Expected: All tests PASS

# 3. Performance baseline comparison
time snow sql -q "SELECT COUNT(*) FROM DEVELOPMENT.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES" --format csv
# Expected: < 5 seconds

# 4. Email campaign lookup coverage
snow sql -q "SELECT COUNT(*) FROM DEVELOPMENT.REPORTING.LKP_EMAIL_CAMPAIGN_DPD_MAPPING WHERE DPD_BUCKET IS NULL" --format csv
# Expected: < 100 campaigns (manual review required)
```

### Production Deployment Validation

```bash
# 1. Verify production dynamic table creation
snow sql -q "DESCRIBE DYNAMIC TABLE BUSINESS_INTELLIGENCE.REPORTING.DT_DSH_OUTBOUND_GENESYS_OUTREACHES" --format csv

# 2. Verify view wrapper
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES" --format csv
# Expected: Sub-second response, same count as dev

# 3. Check grants preservation
snow sql -q "SHOW GRANTS ON VIEW BUSINESS_INTELLIGENCE.REPORTING.VW_DSH_OUTBOUND_GENESYS_OUTREACHES" --format csv
# Expected: Same grants as original view

# 4. Monitor first refresh
snow sql -q "SELECT scheduling_state, data_timestamp FROM INFORMATION_SCHEMA.DYNAMIC_TABLES WHERE name = 'DT_DSH_OUTBOUND_GENESYS_OUTREACHES'" --format csv
# Expected: scheduling_state = 'ACTIVE'
```

## Expected Performance Improvements

**Before Optimization (Current View):**
- Query execution: Timeout (>10 minutes) or multiple minutes
- MVW_LOAN_TAPE scans: 3× (1.6B row scans)
- Correlated subquery executions: 6+
- Activity table joins: 4× large table scans
- Total row scans: ~2B+

**After Optimization (Dynamic Table):**
- Query execution: Sub-second (<1 second)
- MVW_LOAN_TAPE scans: 1× during refresh (533M rows)
- Correlated subquery executions: 1
- Activity table joins: 4× during refresh (pre-materialized)
- Dashboard query: Read from materialized table (instant)
- Refresh frequency: Every 12 hours (automated)

**Expected Speedup:**
- Dashboard queries: **600-1000× faster** (minutes → sub-second)
- Refresh cost: Comparable (moves cost from query-time to scheduled refresh)
- Maintenance: **Improved** (lookup table vs. hard-coded campaigns)

## Key Assumptions

1. **Business Logic Preservation:**
   - Double-join pattern for phone/SMS required for manual call tracking
   - DPD bucket definitions remain unchanged
   - Email campaign DPD mapping can be extracted from campaign name patterns
   - Status filtering in dqs CTE excludes inactive loans

2. **Data Quality:**
   - No duplicates expected in final output (grain: ASOFDATE, LOANSTATUS, PORTFOLIONAME, PORTFOLIOID)
   - GENESYS_OUTBOUND_LIST_EXPORTS is complete source for outbound lists since Oct 2023
   - MVW_LOAN_TAPE_DAILY_HISTORY has daily snapshots without gaps
   - Activity tables (phone/SMS) have complete conversation history

3. **Architecture Decisions:**
   - 12-hour refresh lag sufficient for daily dashboard (can adjust if needed)
   - FULL refresh mode required (no incremental key, complex multi-table aggregations)
   - Email campaign lookup table maintainable via periodic review (quarterly?)
   - COPY GRANTS preserves external partner access permissions

4. **Performance Expectations:**
   - Dynamic table refresh completes within 12-hour window
   - Warehouse BUSINESS_INTELLIGENCE has sufficient compute for refresh
   - First query after refresh may take 10-30 seconds (cache warming)
   - Subsequent queries: Sub-second response

5. **Backward Compatibility:**
   - View wrapper (VW_DSH_OUTBOUND_GENESYS_OUTREACHES) maintains external interface
   - All column names, types, order preserved exactly
   - Dashboard queries require no modifications
   - Tableau refresh schedule unchanged

## Risk Mitigation

**Risk #1: Email Campaign Lookup Incomplete**
- **Mitigation:** Manual review of NULL DPD_BUCKET campaigns before production
- **Fallback:** Include original CASE statement logic for unmapped campaigns
- **Monitoring:** Alert on new campaigns not in lookup table

**Risk #2: Dynamic Table Refresh Timeout**
- **Mitigation:** Test refresh in dev environment, monitor execution time
- **Fallback:** Increase warehouse size or adjust target_lag to 24 hours
- **Monitoring:** Alert on refresh failures or extended execution

**Risk #3: Data Discrepancies (Current View vs Dynamic Table)**
- **Mitigation:** Extensive QC validation in Phase 2
- **Fallback:** Rollback to original view via backup
- **Monitoring:** Weekly comparison reports for first month

**Risk #4: External Dashboard Performance Issues**
- **Mitigation:** Communicate 12-hour refresh lag to stakeholders
- **Fallback:** Reduce target_lag to 6 hours if needed
- **Monitoring:** Track dashboard load times, user feedback

**Risk #5: Cost Increase (Scheduled Refresh)**
- **Mitigation:** Monitor warehouse credit usage before/after
- **Fallback:** Adjust refresh frequency (12hr → 24hr) or warehouse size
- **Monitoring:** Weekly cost comparison reports

## Success Criteria

**Technical Success:**
- ✅ Dynamic table creation successful in dev and production
- ✅ All QC tests pass (8 tests in qc_validation.sql)
- ✅ Query performance: Sub-second response (<1 second avg)
- ✅ Refresh completes within 12-hour window
- ✅ Zero data discrepancies between current view and dynamic table
- ✅ Email campaign lookup coverage >95% (manual review for <100 campaigns)

**Business Success:**
- ✅ External dashboard continues functioning without modifications
- ✅ Stakeholders confirm acceptable 12-hour refresh lag
- ✅ No data quality issues reported
- ✅ Positive user feedback on dashboard responsiveness

**Operational Success:**
- ✅ Dynamic table refresh runs automatically without intervention
- ✅ Cost neutral or reduced (refresh cost ≤ cumulative query cost)
- ✅ Maintainability improved (lookup table vs. hard-coded campaigns)
- ✅ Documentation updated for new architecture

## Documentation Requirements

1. **Update Repository README:**
   - Add DI-1299 to completed tickets log
   - Document dynamic table conversion pattern for future optimizations

2. **Create Ticket Documentation:**
   - `tickets/kchalmers/DI-1299/README.md`: Complete optimization summary
   - `tickets/kchalmers/DI-1299/final_deliverables/1_email_campaign_lookup_creation.sql`
   - `tickets/kchalmers/DI-1299/final_deliverables/2_dynamic_table_creation_dev.sql`
   - `tickets/kchalmers/DI-1299/final_deliverables/3_production_deployment.sql`
   - `tickets/kchalmers/DI-1299/qc_validation.sql`
   - `tickets/kchalmers/DI-1299/original_code/original_view_ddl.sql`

3. **Update Data Catalog:**
   - Document DT_DSH_OUTBOUND_GENESYS_OUTREACHES in `documentation/data_catalog.md`
   - Document LKP_EMAIL_CAMPAIGN_DPD_MAPPING lookup table
   - Update VW_DSH_OUTBOUND_GENESYS_OUTREACHES entry (now view wrapper)

4. **Create Runbook:**
   - Dynamic table refresh monitoring procedures
   - Email campaign lookup table update process
   - Rollback procedures for emergencies
   - Escalation contacts and response times

## Confidence Assessment: 9/10

**Strengths:**
- ✅ Complete database schema analysis with row counts and structures
- ✅ Clear identification of 6 major performance bottlenecks
- ✅ Proven dynamic table pattern from DI-974 (DSH_GR_DAILY_ROLL_TRANSITION)
- ✅ Comprehensive QC validation strategy (8 tests)
- ✅ Backward compatibility via view wrapper
- ✅ Email campaign lookup table addresses 2,901 hard-coded campaigns
- ✅ Executable validation gates for dev and production
- ✅ Risk mitigation and rollback plans documented

**Uncertainties (-1 point):**
- ⚠️ Email campaign DPD mapping requires manual review (~100-300 campaigns)
- ⚠️ Dynamic table refresh time unknown (could exceed 12 hours if very complex)
- ⚠️ Some campaign special cases may need custom rules (e.g., `COL_Adhoc_DLQ_PastDue_3-59Days`)

**Recommendation:**
Proceed with implementation following the phased approach. The optimization strategy is sound, and the risk is low due to:
1. View wrapper maintains backward compatibility
2. Backup plan allows immediate rollback
3. Development testing validates before production
4. Pattern proven in DI-974 (similar dynamic table optimization)

**Post-Implementation Note:**
After successful deployment, monitor for 2 weeks and document actual performance gains for future reference.
