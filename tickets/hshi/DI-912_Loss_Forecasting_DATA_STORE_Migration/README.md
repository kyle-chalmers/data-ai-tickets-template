# DI-912: Transition Loss Forecasting DATA_STORE

## ✅ STATUS: MIGRATION FEASIBLE - HYBRID APPROACH IDENTIFIED

**Date**: 2025-10-01
**Status**: Ready to proceed with HYBRID migration strategy
**Solution**: Combine DATA_STORE legacy data with current ANALYTICS/BRIDGE sources

**See**:
- `final_deliverables/4_hybrid_migration_strategy.md` for recommended approach
- `exploratory_analysis/data_quality_findings.md` for detailed analysis

## Business Context

The BI-1451 Loss Forecasting job currently uses DATA_STORE schema objects containing Cloud Lending System (CLS) legacy data. Per the 5-layer Snowflake architecture migration initiative, all DATA_STORE references must be replaced with ANALYTICS/BRIDGE equivalents.

**Critical Finding**: The DATA_STORE.VW_LOAN_COLLECTION table contains **legacy data with significantly different coverage** than current ANALYTICS tables. Direct migration would result in:
- **90%+ loss of cease & desist records** (20,650 → 958)
- **66% loss of bankruptcy records** (6,633 → 2,272)
- **99.8% loss of autopay records** (214,590 → 392)

**Jira Ticket**: https://happymoneyinc.atlassian.net/browse/DI-912

**Job Location**: `/Users/hshi/WOW/business-intelligence-data-jobs/jobs/BI-1451_Loss_Forecasting/BI-1451_Loss_Forecasting.py`

## DATA_STORE Dependencies Identified

### 1. `DATA_STORE.MVW_LOAN_TAPE_MONTHLY` (PRIMARY DEPENDENCY)
**Current Usage** (lines 123, 128, 134, 230, 236, 390):
- Gets max as-of date for latest snapshot
- Creates historical loan tape with 3-month roll rate extensions
- Used for charge-off forecasting and DQ-based projections
- Core foundation for entire forecasting model

**Migration Decision**:
- **KEEP using MVW_LOAN_TAPE_MONTHLY** - No monthly loan snapshot exists in ANALYTICS/BRIDGE
- This is the only DATA_STORE object we'll continue using until ANALYTICS equivalent is built

**Future State**: When ANALYTICS.VW_LOAN_MONTHLY_SNAPSHOT is created, migrate to that

### 2. `DATA_STORE.VW_LOAN_COLLECTION` ⚠️ **MIGRATION BLOCKED**
**Current Usage** (lines 574-580):
```sql
, dist_auto as (select PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
                from DATA_STORE.VW_LOAN_COLLECTION
                where PAYOFF_UID in (select PAYOFF_UID
                                     from DATA_STORE.VW_LOAN_COLLECTION
                                     group by 1
                                     having count(*) < 2))
```

**Data Quality Issue Identified**:
- DATA_STORE.VW_LOAN_COLLECTION: 337,219 loans (legacy CLS data)
- ANALYTICS.VW_LOAN: 347,835 loans (current LoanPro data)
- **Massive coverage gaps** in ANALYTICS tables:
  - CEASE_AND_DESIST: 20,650 in DATA_STORE vs 2,678 in VW_LOAN_CONTACT_RULES (only 958 overlap)
  - BANKRUPTCY_FLAG: 6,633 in DATA_STORE vs 2,272 in VW_LOAN_BANKRUPTCY
  - DEBIT_BILL_AUTOMATIC: 214,590 in DATA_STORE vs 392 in VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT

**Proposed ANALYTICS Sources** (INVALID - insufficient coverage):
- ~~`CEASE_AND_DESIST` → ANALYTICS.VW_LOAN_CONTACT_RULES.CEASE_AND_DESIST~~ ❌ Missing 90%+ of data
- ~~`BANKRUPTCY_FLAG` → ANALYTICS.VW_LOAN_BANKRUPTCY (join on LOAN_ID)~~ ❌ Missing 66% of data
- ~~`DEBIT_BILL_AUTOMATIC` → BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT.AUTOPAY_OPT_IN~~ ❌ Missing 99.8% of data

**Required Investigation**:
1. Identify proper LoanPro source for cease & desist status
2. Identify proper LoanPro source for autopay enrollment
3. Understand why VW_LOAN_BANKRUPTCY has fewer records
4. Determine if this job intentionally uses legacy CLS data for forecasting

### 3. `DATA_STORE.PMT`, `DATA_STORE.IPMT`, `DATA_STORE.PPMT` (TEMPORARY UDFs)
**Current Usage** (lines 84-111, 715, 822-844):
- Temporary user-defined functions created at job start
- Used for amortization calculations (payment, interest, principal)
- Dropped at job end

**Migration Decision**:
- **NO MIGRATION NEEDED** - These are temporary functions created/dropped within job execution
- Not persistent DATA_STORE objects requiring migration

## Migration Strategy

### Replacement Query for VW_LOAN_COLLECTION

**Original Pattern**:
```sql
, dist_auto as (select PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
                from DATA_STORE.VW_LOAN_COLLECTION
                where PAYOFF_UID in (select PAYOFF_UID
                                     from DATA_STORE.VW_LOAN_COLLECTION
                                     group by 1
                                     having count(*) < 2))
```

**New ANALYTICS Pattern**:
```sql
, dist_auto as (
    select
        L.LEAD_GUID as PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) as BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) as DEBIT_BILL_AUTOMATIC
    from ANALYTICS.VW_LOAN as L
        left join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
            on L.LOAN_ID = LCR.LOAN_ID
            and LCR.CONTACT_RULE_END_DATE is null
        left join ANALYTICS.VW_LOAN_BANKRUPTCY as BK
            on L.LEAD_GUID = BK.PAYOFF_UID
            and BK.ACTIVE_RECORD_FLAG = TRUE
        left join BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as LOS
            on L.LOAN_ID = LOS.LOAN_ID
)
```

**Key Differences**:
1. **Join Pattern**: Uses VW_LOAN as base, joins to multiple tables instead of single VW_LOAN_COLLECTION
2. **Duplicate Handling**: Original had manual duplicate exclusion (`having count(*) < 2`) - new pattern uses proper active record flags
3. **Field Transformations**:
   - BANKRUPTCY_FLAG: Uses ACTIVE_RECORD_FLAG filter instead of count-based deduplication
   - DEBIT_BILL_AUTOMATIC: Converts AUTOPAY_OPT_IN 'yes'/'no' to boolean TRUE/FALSE
4. **Null Handling**: Uses COALESCE for bankruptcy flag to ensure boolean consistency

## Changes Required

### File: `BI-1451_Loss_Forecasting.py`

**Line 574-580**: Replace VW_LOAN_COLLECTION CTE with new ANALYTICS pattern

**Before**:
```python
       , dist_auto as (select PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
                       from DATA_STORE.VW_LOAN_COLLECTION
                            -- three loans are excluded with this condition because of duplicates or two values:
                            -- a76f33d5-00e8-4f7e-a4d3-65d3907b383f, 4d8d470b-64de-4f3e-8857-593e7b3a4058, 4ba57978-06d4-4e70-b866-2bcfe4d235f3
                       where PAYOFF_UID in (select PAYOFF_UID
                                            from DATA_STORE.VW_LOAN_COLLECTION
                                            group by 1
                                            having count(*) < 2))
```

**After**:
```python
       , dist_auto as (
            select
                L.LEAD_GUID as PAYOFF_UID,
                LCR.CEASE_AND_DESIST,
                COALESCE(BK.BANKRUPTCY_FLAG, FALSE) as BANKRUPTCY_FLAG,
                IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) as DEBIT_BILL_AUTOMATIC
            from ANALYTICS.VW_LOAN as L
                left join ANALYTICS.VW_LOAN_CONTACT_RULES as LCR
                    on L.LOAN_ID = LCR.LOAN_ID
                    and LCR.CONTACT_RULE_END_DATE is null
                left join ANALYTICS.VW_LOAN_BANKRUPTCY as BK
                    on L.LEAD_GUID = BK.PAYOFF_UID
                    and BK.ACTIVE_RECORD_FLAG = TRUE
                left join BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT as LOS
                    on L.LOAN_ID = LOS.LOAN_ID
        )
```

**Lines 693-696**: Update join to dist_auto (no changes needed - already joins on PAYOFF_UID)

**Lines 634-636**: Downstream usage (no changes needed - field names remain same)

## Testing Plan

### 1. QC Query: Validate Field Availability
```sql
-- Verify ANALYTICS tables have required fields
SELECT
    'VW_LOAN_CONTACT_RULES' as source_table,
    COUNT(DISTINCT LOAN_ID) as loan_count,
    SUM(CASE WHEN CEASE_AND_DESIST = TRUE THEN 1 ELSE 0 END) as cease_desist_count
FROM ANALYTICS.VW_LOAN_CONTACT_RULES
WHERE CONTACT_RULE_END_DATE IS NULL;

SELECT
    'VW_LOAN_BANKRUPTCY' as source_table,
    COUNT(DISTINCT PAYOFF_UID) as loan_count,
    SUM(CASE WHEN BANKRUPTCY_FLAG = TRUE THEN 1 ELSE 0 END) as bankruptcy_count
FROM ANALYTICS.VW_LOAN_BANKRUPTCY
WHERE ACTIVE_RECORD_FLAG = TRUE;

SELECT
    'VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT' as source_table,
    COUNT(DISTINCT LOAN_ID) as loan_count,
    SUM(CASE WHEN LOWER(AUTOPAY_OPT_IN) = 'yes' THEN 1 ELSE 0 END) as autopay_count
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT;
```

### 2. QC Query: Compare Old vs New Pattern
```sql
-- Old pattern (DATA_STORE)
WITH old_dist_auto AS (
    SELECT PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID
        FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1
        HAVING COUNT(*) < 2
    )
),
-- New pattern (ANALYTICS/BRIDGE)
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID
            AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID
            AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)
-- Compare counts
SELECT
    'Old Pattern' AS source,
    COUNT(*) AS record_count,
    SUM(CASE WHEN CEASE_AND_DESIST = TRUE THEN 1 ELSE 0 END) AS cease_desist,
    SUM(CASE WHEN BANKRUPTCY_FLAG = TRUE THEN 1 ELSE 0 END) AS bankruptcy,
    SUM(CASE WHEN DEBIT_BILL_AUTOMATIC = TRUE THEN 1 ELSE 0 END) AS autopay
FROM old_dist_auto
UNION ALL
SELECT
    'New Pattern' AS source,
    COUNT(*) AS record_count,
    SUM(CASE WHEN CEASE_AND_DESIST = TRUE THEN 1 ELSE 0 END) AS cease_desist,
    SUM(CASE WHEN BANKRUPTCY_FLAG = TRUE THEN 1 ELSE 0 END) AS bankruptcy,
    SUM(CASE WHEN DEBIT_BILL_AUTOMATIC = TRUE THEN 1 ELSE 0 END) AS autopay
FROM new_dist_auto;
```

### 3. QC Query: Identify Discrepancies
```sql
-- Find loans that appear in one pattern but not the other
WITH old_dist_auto AS (
    SELECT PAYOFF_UID, CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC
    FROM DATA_STORE.VW_LOAN_COLLECTION
    WHERE PAYOFF_UID IN (
        SELECT PAYOFF_UID FROM DATA_STORE.VW_LOAN_COLLECTION
        GROUP BY 1 HAVING COUNT(*) < 2
    )
),
new_dist_auto AS (
    SELECT
        L.LEAD_GUID AS PAYOFF_UID,
        LCR.CEASE_AND_DESIST,
        COALESCE(BK.BANKRUPTCY_FLAG, FALSE) AS BANKRUPTCY_FLAG,
        IFF(LOWER(LOS.AUTOPAY_OPT_IN) = 'yes', TRUE, FALSE) AS DEBIT_BILL_AUTOMATIC
    FROM ANALYTICS.VW_LOAN AS L
        LEFT JOIN ANALYTICS.VW_LOAN_CONTACT_RULES AS LCR
            ON L.LOAN_ID = LCR.LOAN_ID AND LCR.CONTACT_RULE_END_DATE IS NULL
        LEFT JOIN ANALYTICS.VW_LOAN_BANKRUPTCY AS BK
            ON L.LEAD_GUID = BK.PAYOFF_UID AND BK.ACTIVE_RECORD_FLAG = TRUE
        LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT AS LOS
            ON L.LOAN_ID = LOS.LOAN_ID
)
SELECT
    'Only in old pattern' AS discrepancy_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
WHERE NOT EXISTS (SELECT 1 FROM new_dist_auto n WHERE n.PAYOFF_UID = o.PAYOFF_UID)
UNION ALL
SELECT
    'Only in new pattern' AS discrepancy_type,
    COUNT(*) AS loan_count
FROM new_dist_auto n
WHERE NOT EXISTS (SELECT 1 FROM old_dist_auto o WHERE o.PAYOFF_UID = n.PAYOFF_UID)
UNION ALL
SELECT
    'Flag mismatches' AS discrepancy_type,
    COUNT(*) AS loan_count
FROM old_dist_auto o
INNER JOIN new_dist_auto n ON o.PAYOFF_UID = n.PAYOFF_UID
WHERE o.CEASE_AND_DESIST <> n.CEASE_AND_DESIST
   OR o.BANKRUPTCY_FLAG <> n.BANKRUPTCY_FLAG
   OR o.DEBIT_BILL_AUTOMATIC <> n.DEBIT_BILL_AUTOMATIC;
```

### 4. Full Job Test
- Run updated BI-1451 job in dev environment
- Compare output table `CRON_STORE.DSH_LOAN_PORTFOLIO_EXPECTATIONS` before/after
- Validate record counts, forecast values, and business metrics match

## Deployment Strategy

1. **Create updated job file** in final_deliverables/
2. **Run QC queries** to validate ANALYTICS tables have required data
3. **Compare old vs new patterns** to identify any discrepancies
4. **Test in dev environment** using production database connections
5. **Deploy to production** after successful validation
6. **Monitor first production run** for data quality issues

## Assumptions

1. **ANALYTICS.VW_LOAN_CONTACT_RULES** contains CEASE_AND_DESIST field with proper active record filtering
2. **ANALYTICS.VW_LOAN_BANKRUPTCY** contains BANKRUPTCY_FLAG with ACTIVE_RECORD_FLAG for current status
3. **BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT** contains AUTOPAY_OPT_IN with 'yes'/'no' values
4. **VW_LOAN_COLLECTION duplicate handling** via `having count(*) < 2` can be replaced with proper active record flags in new tables
5. **MVW_LOAN_TAPE_MONTHLY** will continue to be used until ANALYTICS.VW_LOAN_MONTHLY_SNAPSHOT is created
6. **Job business logic** (roll rates, charge-off forecasting, DQ calculations) remains unchanged
7. **Output table schema** (CRON_STORE.DSH_LOAN_PORTFOLIO_EXPECTATIONS) remains unchanged

## Success Criteria

✅ DATA_STORE.VW_LOAN_COLLECTION replaced with ANALYTICS/BRIDGE equivalents
✅ All required fields (CEASE_AND_DESIST, BANKRUPTCY_FLAG, DEBIT_BILL_AUTOMATIC) available
✅ Record counts match between old and new patterns (within acceptable tolerance)
✅ Flag values match between old and new patterns
✅ Job runs successfully with updated queries
✅ Output table data quality maintained
✅ Business metrics (forecasts, roll rates) remain consistent
✅ No errors or data quality issues in production

## Related Documentation

- **5-Layer Snowflake Architecture**: See /Users/hshi/WOW/data-intelligence-tickets/CLAUDE.md
- **BI-1451 Job Location**: /Users/hshi/WOW/business-intelligence-data-jobs/jobs/BI-1451_Loss_Forecasting/
- **Reference Jobs Using ANALYTICS Tables**:
  - BI-2482: Uses VW_LOAN_CONTACT_RULES for cease and desist
  - DI-1265: Uses VW_LOAN_CONTACT_RULES pattern
  - BI-1931: Uses VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT for autopay
