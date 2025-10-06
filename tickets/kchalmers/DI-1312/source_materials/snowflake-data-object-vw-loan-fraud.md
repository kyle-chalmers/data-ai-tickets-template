# PRP: Snowflake Data Object - VW_LOAN_FRAUD

## Metadata
- **PRP Created**: 2025-10-02
- **Operation Type**: CREATE_NEW
- **Scope**: SINGLE_OBJECT
- **Expected Ticket Folder**: `tickets/kchalmers/DI-[NEW]/`
- **Confidence Score**: 9/10

## Business Context

### Purpose
Create a single source of truth for all fraud-related loan data at Happy Money. This view will serve as:
1. **Suppression source** for debt sale files (exclude fraudulent loans from sales)
2. **Fraud analysis hub** for tracking fraud cases, timelines, and outcomes
3. **Data quality monitoring** tool to identify inconsistencies in fraud data across systems

### Related Tickets
- **DI-1246**: 1099C Data Review - needs fraud exclusion logic
- **DI-1235**: Update Settlements Tableau Dashboard - may need fraud indicators
- **DI-1141**: Debt Sale Population - established fraud filtering patterns (see line 332: `COALESCE(FD.is_fraud, FALSE) = FALSE`)

### Stakeholders
- **Primary**: Kyle Chalmers (Data Intelligence)
- **Secondary**: Collections Team (debt sale operations), Fraud Investigation Team

### Success Criteria
- All 509 unique fraud-related loans captured from three data sources
- Clear data source tracking for quality control
- Conservative fraud classification (if any source confirms fraud, loan is flagged)
- Ready integration for debt sale suppression logic

## Object Definition

### Primary Object
- **Name**: VW_LOAN_FRAUD
- **Type**: VIEW
- **Target Schema**: BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
- **Deployment Pattern**: FRESHSNOW → BRIDGE → ANALYTICS (no REPORTING layer needed)

### Data Grain
- **Grain**: One row per loan with any fraud indicator
- **Key**: LOAN_ID (primary identifier)
- **Time Period**: All time (historical and current fraud cases)
- **Expected Row Count**: ~509 loans (as of 2025-10-02)

## Architecture Compliance

### 5-Layer Architecture Pattern
```
ARCA.FRESHSNOW.VW_LOAN_FRAUD (source logic)
    ↓
BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_FRAUD (pass-through with COPY GRANTS)
    ↓
BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD (final consumer view)
```

### Layer-Appropriate Referencing
FRESHSNOW layer can reference:
- ✓ BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
- ✓ BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
- ✓ BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT
- ✓ BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT
- ✓ BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA() function

### Deployment Template Reference
Use `documentation/db_deploy_template.sql` pattern with:
- Environment variables for dev/prod switching
- COPY GRANTS to preserve permissions
- EXECUTE IMMEDIATE for dynamic SQL
- Sequential deployment: FRESHSNOW → BRIDGE → ANALYTICS

## Data Sources Analysis

### Source 1: Custom Loan Settings (Primary Fraud Data)
**Table**: `BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT`

**Population**: 414 loans with fraud custom fields

**Key Fields**:
```sql
- FRAUD_INVESTIGATION_RESULTS (254 loans)
  Values: "Confirmed" (94), "Declined" (160)

- FRAUD_CONFIRMED_DATE (252 loans)
  Date when fraud was officially confirmed

- FRAUD_NOTIFICATION_RECEIVED (248 loans)
  Date when fraud notification first received

- FRAUD_CONTACT_EMAIL (2 loans)
  Email contact for fraud case (sparse but include per user requirement)
```

**Sample Data**:
```
LOAN_ID: 85059
FRAUD_CONFIRMED_DATE: 2025-01-06
FRAUD_INVESTIGATION_RESULTS: Confirmed
FRAUD_NOTIFICATION_RECEIVED: 2025-01-02
```

**Join Key**: `LOAN_ID`

**DDL Reference**:
```sql
SELECT
    LOAN_ID,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_CONFIRMED_DATE,
    FRAUD_NOTIFICATION_RECEIVED,
    FRAUD_CONTACT_EMAIL
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
WHERE FRAUD_CONFIRMED_DATE IS NOT NULL
   OR FRAUD_INVESTIGATION_RESULTS IS NOT NULL
   OR FRAUD_NOTIFICATION_RECEIVED IS NOT NULL
   OR FRAUD_CONTACT_EMAIL IS NOT NULL
```

### Source 2: Fraud Portfolios
**Table**: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS`

**Population**: 361 loans in fraud portfolios

**Portfolio Breakdown**:
- First Party Fraud - Confirmed: 188 loans
- Fraud - Declined: 163 loans
- Identity Theft Fraud - Confirmed: 19 loans
- Fraud - Pending Investigation: 6 loans

**Key Fields**:
```sql
- PORTFOLIO_NAME
- PORTFOLIO_CATEGORY (should be 'Fraud')
- CREATED (date portfolio assigned)
```

**Sample Data**:
```
LOAN_ID: 106437
PORTFOLIO_NAME: Identity Theft Fraud - Confirmed
PORTFOLIO_CATEGORY: Fraud
CREATED: 2025-01-22T21:32:26
```

**Join Key**: `LOAN_ID`

**DDL Reference**:
```sql
SELECT
    LOAN_ID,
    LISTAGG(DISTINCT PORTFOLIO_NAME, '; ') as FRAUD_PORTFOLIOS,
    COUNT(DISTINCT PORTFOLIO_NAME) as FRAUD_PORTFOLIO_COUNT,
    MAX(CASE WHEN PORTFOLIO_NAME = 'First Party Fraud - Confirmed' THEN CREATED END) as FIRST_PARTY_FRAUD_CONFIRMED_DATE,
    MAX(CASE WHEN PORTFOLIO_NAME = 'Identity Theft Fraud - Confirmed' THEN CREATED END) as IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
    MAX(CASE WHEN PORTFOLIO_NAME = 'Fraud - Declined' THEN CREATED END) as FRAUD_DECLINED_DATE,
    MAX(CASE WHEN PORTFOLIO_NAME = 'Fraud - Pending Investigation' THEN CREATED END) as FRAUD_PENDING_INVESTIGATION_DATE
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
WHERE PORTFOLIO_CATEGORY = 'Fraud'
GROUP BY LOAN_ID
```

### Source 3: Fraud Sub-Status (Current Status)
**Table**: `BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT` (joined with VW_LOAN_SUB_STATUS_ENTITY_CURRENT)

**Population**: 20 loans with fraud sub-status

**Sub-Status Details**:
- ID: 32 - "Open - Fraud Process" (Active: 1)
- ID: 61 - "Closed - Confirmed Fraud" (Active: 1)

**Historical Counts** (from VW_LOAN_STATUS_ARCHIVE_CURRENT):
- Closed - Confirmed Fraud: 2,462 historical records
- Open - Fraud Process: 371 historical records

**Key Fields**:
```sql
- LOAN_SUB_STATUS_ID (32 or 61 for fraud)
- TITLE (from VW_LOAN_SUB_STATUS_ENTITY_CURRENT)
```

**Sample Data**:
```
LOAN_ID: 106437
LOAN_SUB_STATUS_ID: 61
TITLE: Closed - Confirmed Fraud
```

**Join Key**: `ls.LOAN_ID` and `ls.LOAN_SUB_STATUS_ID = lss.ID`

**DDL Reference**:
```sql
SELECT
    ls.LOAN_ID,
    lss.TITLE as CURRENT_SUB_STATUS,
    ls.LOAN_SUB_STATUS_ID
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT ls
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lss
    ON ls.LOAN_SUB_STATUS_ID = lss.ID
    AND lss.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
WHERE ls.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    AND ls.DELETED = 0
    AND ls.LOAN_SUB_STATUS_ID IN (32, 61)  -- Fraud sub-statuses
```

### Data Source Overlap Analysis

**Total Universe**: 509 unique fraud loans

**Source Distribution**:
- Custom Fields only: ~148 loans (414 - 266 overlap)
- Portfolios only: ~95 loans (361 - 266 overlap)
- Sub-Status only: 0 loans (all 20 have custom fields or portfolios)
- Custom Fields + Portfolios: 266 loans
- All three sources: 20 loans

**Quality Insight**: Most fraud identification happens via custom fields and portfolios. Sub-status is only applied to a small subset, suggesting sub-status may lag behind other indicators.

## Data Architecture Design

### Reference Pattern: VW_LOAN_DEBT_SETTLEMENT
Following the established settlement view pattern:

**Pattern Elements**:
1. **Separate CTEs per source** - Identify loans from each data source independently
2. **UNION for complete population** - Combine all sources to get full loan list
3. **LEFT JOIN back to sources** - Retrieve detailed data from each source
4. **Data source tracking flags** - Boolean flags for presence in each source
5. **Data completeness indicators** - Count and classification of data sources

**Adaptation for Fraud**:
```sql
WITH custom_fields AS (
    -- Source 1: Custom fraud fields
    SELECT LOAN_ID, 'CUSTOM_FIELDS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
    WHERE FRAUD_CONFIRMED_DATE IS NOT NULL
       OR FRAUD_INVESTIGATION_RESULTS IS NOT NULL
       OR FRAUD_NOTIFICATION_RECEIVED IS NOT NULL
       OR FRAUD_CONTACT_EMAIL IS NOT NULL
),
fraud_portfolios AS (
    -- Source 2: Fraud portfolios
    SELECT LOAN_ID, 'PORTFOLIOS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
    WHERE PORTFOLIO_CATEGORY = 'Fraud'
    GROUP BY LOAN_ID
),
fraud_sub_status AS (
    -- Source 3: Fraud sub-status
    SELECT ls.LOAN_ID, 'SUB_STATUS' as SOURCE
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT ls
    INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lss
        ON ls.LOAN_SUB_STATUS_ID = lss.ID
        AND lss.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    WHERE ls.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
        AND ls.DELETED = 0
        AND ls.LOAN_SUB_STATUS_ID IN (32, 61)
),
all_fraud_loans AS (
    SELECT LOAN_ID FROM custom_fields
    UNION
    SELECT LOAN_ID FROM fraud_portfolios
    UNION
    SELECT LOAN_ID FROM fraud_sub_status
)
-- Main query joins back to all sources
SELECT
    afl.LOAN_ID,
    -- Custom field data
    cf.FRAUD_INVESTIGATION_RESULTS,
    cf.FRAUD_CONFIRMED_DATE,
    -- ... etc
FROM all_fraud_loans afl
LEFT JOIN custom_fields_cte cf ON afl.LOAN_ID = cf.LOAN_ID
LEFT JOIN fraud_portfolios_cte fp ON afl.LOAN_ID = fp.LOAN_ID
LEFT JOIN fraud_sub_status_cte fss ON afl.LOAN_ID = fss.LOAN_ID
```

### Schema Filtering Best Practices
**Critical**: Apply LMS_SCHEMA() filtering to avoid duplicate data from multiple LoanPro instances:

```sql
WHERE ls.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    AND lss.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
```

## Transformation Logic

### Column Structure (Following VW_LOAN_DEBT_SETTLEMENT Pattern)

**Core Identifiers**:
```sql
LOAN_ID                           -- Primary key
LEAD_GUID                         -- From VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT for joins
```

**Custom Field Data (Source 1)**:
```sql
FRAUD_INVESTIGATION_RESULTS       -- "Confirmed", "Declined", or NULL
FRAUD_CONFIRMED_DATE              -- Date fraud officially confirmed
FRAUD_NOTIFICATION_RECEIVED       -- Date fraud notification first received
FRAUD_CONTACT_EMAIL               -- Contact email (sparse: 2 loans only)
```

**Portfolio Data (Source 2)**:
```sql
FRAUD_PORTFOLIOS                  -- LISTAGG of all fraud portfolio names
FRAUD_PORTFOLIO_COUNT             -- Count of distinct fraud portfolios
FIRST_PARTY_FRAUD_CONFIRMED_DATE  -- Date for specific portfolio
IDENTITY_THEFT_FRAUD_CONFIRMED_DATE
FRAUD_DECLINED_DATE
FRAUD_PENDING_INVESTIGATION_DATE
```

**Current Status Data (Source 3)**:
```sql
CURRENT_SUB_STATUS                -- Current fraud sub-status title
LOAN_SUB_STATUS_ID                -- Sub-status ID (32 or 61)
```

**Calculated Date Fields**:
```sql
EARLIEST_FRAUD_DATE               -- Earliest date across all fraud date fields
                                  -- LEAST(FRAUD_NOTIFICATION_RECEIVED,
                                  --      FRAUD_CONFIRMED_DATE,
                                  --      FIRST_PARTY_FRAUD_CONFIRMED_DATE,
                                  --      IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
                                  --      FRAUD_PENDING_INVESTIGATION_DATE)
```

**Fraud Classification Flags**:
```sql
FRAUD_STATUS                      -- "CONFIRMED", "DECLINED", "UNDER_INVESTIGATION", or "MIXED"
IS_CONFIRMED_FRAUD                -- Boolean: TRUE if any source indicates confirmed fraud
IS_DECLINED_FRAUD                 -- Boolean: TRUE if investigation declined
IS_UNDER_INVESTIGATION            -- Boolean: TRUE if pending investigation portfolio
IS_ACTIVE_FRAUD                   -- Boolean: TRUE if has fraud portfolio OR fraud sub-status OR confirmed investigation
```

**Fraud Status Logic** (Conservative Approach per User Requirements):
```sql
FRAUD_STATUS = CASE
    -- Most conservative: If ANY source confirms fraud, mark as CONFIRMED
    WHEN FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
         OR PORTFOLIO_NAME LIKE '%Confirmed%'
         OR LOAN_SUB_STATUS_ID = 61  -- Closed - Confirmed Fraud
    THEN 'CONFIRMED'

    -- Pending investigation
    WHEN PORTFOLIO_NAME = 'Fraud - Pending Investigation'
         OR LOAN_SUB_STATUS_ID = 32  -- Open - Fraud Process
    THEN 'UNDER_INVESTIGATION'

    -- Declined only if no confirmed indicators
    WHEN FRAUD_INVESTIGATION_RESULTS = 'Declined'
         OR PORTFOLIO_NAME = 'Fraud - Declined'
    THEN 'DECLINED'

    -- Mixed if contradictory data (e.g., confirmed in one source, declined in another)
    WHEN (FRAUD_INVESTIGATION_RESULTS = 'Confirmed' AND PORTFOLIO_NAME = 'Fraud - Declined')
         OR (FRAUD_INVESTIGATION_RESULTS = 'Declined' AND PORTFOLIO_NAME LIKE '%Confirmed%')
    THEN 'MIXED'

    ELSE 'UNKNOWN'
END

IS_ACTIVE_FRAUD = CASE
    -- Active if has fraud portfolio OR current fraud sub-status OR confirmed investigation
    WHEN FRAUD_PORTFOLIO_COUNT > 0
         OR LOAN_SUB_STATUS_ID IN (32, 61)
         OR FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
    THEN TRUE
    ELSE FALSE
END
```

**Data Quality Flags** (Following VW_LOAN_DEBT_SETTLEMENT Pattern):
```sql
HAS_CUSTOM_FIELDS                 -- Boolean: Present in custom fields source
HAS_FRAUD_PORTFOLIO               -- Boolean: Present in fraud portfolios
HAS_FRAUD_SUB_STATUS              -- Boolean: Present in fraud sub-status

DATA_SOURCE_COUNT                 -- Integer: Count of sources (1-3)
DATA_COMPLETENESS_FLAG            -- "COMPLETE" (3), "PARTIAL" (2), "SINGLE_SOURCE" (1)
DATA_SOURCE_LIST                  -- CSV list: e.g., "CUSTOM_FIELDS, PORTFOLIOS"

DATA_QUALITY_FLAG                 -- Quality indicator based on consistency
                                  -- "CONSISTENT" - All sources agree
                                  -- "INCONSISTENT" - Confirmed in one, declined in another
                                  -- "INCOMPLETE" - Missing expected data points
```

**Data Quality Flag Logic**:
```sql
DATA_QUALITY_FLAG = CASE
    -- Inconsistent: Conflicting classifications
    WHEN FRAUD_STATUS = 'MIXED' THEN 'INCONSISTENT'

    -- Complete and consistent
    WHEN DATA_SOURCE_COUNT = 3 AND FRAUD_STATUS IN ('CONFIRMED', 'DECLINED', 'UNDER_INVESTIGATION')
    THEN 'CONSISTENT'

    -- Partial data
    WHEN DATA_SOURCE_COUNT = 2 THEN 'PARTIAL'

    -- Single source only
    WHEN DATA_SOURCE_COUNT = 1 THEN 'SINGLE_SOURCE'

    ELSE 'UNKNOWN'
END
```

### Business Rules

**1. Conservative Fraud Classification**
- If ANY source indicates confirmed fraud → FRAUD_STATUS = 'CONFIRMED'
- Prioritize fraud confirmation over declination
- Flag contradictions with 'MIXED' status for review

**2. Active Fraud Definition**
- Has fraud portfolio (any type) OR
- Has fraud sub-status (Open or Closed) OR
- Has confirmed investigation result
- Result: IS_ACTIVE_FRAUD = TRUE

**3. Data Completeness Assessment**
- COMPLETE: All 3 sources present (custom fields + portfolios + sub-status)
- PARTIAL: 2 sources present
- SINGLE_SOURCE: Only 1 source present
- Flag for data quality review if SINGLE_SOURCE

**4. Date Calculation**
- Use LEAST() function to find earliest fraud indication date
- Exclude NULL dates from calculation
- If all dates NULL, EARLIEST_FRAUD_DATE = NULL

### Expected Data Quality Issues

**Issue 1: Declined Investigations in Confirmed Portfolios**
- **Example**: FRAUD_INVESTIGATION_RESULTS = 'Declined' but PORTFOLIO_NAME = 'First Party Fraud - Confirmed'
- **Handling**: Set FRAUD_STATUS = 'MIXED' and DATA_QUALITY_FLAG = 'INCONSISTENT'
- **Business Action**: Highlight for manual review

**Issue 2: Sub-Status Lag**
- **Observation**: Only 20 loans have fraud sub-status, but 509 have fraud indicators
- **Handling**: Don't require sub-status for IS_ACTIVE_FRAUD flag
- **Business Action**: Document in view comments that sub-status may lag

**Issue 3: Sparse FRAUD_CONTACT_EMAIL**
- **Observation**: Only 2 loans have this field populated
- **Handling**: Include column but expect mostly NULL values
- **Business Action**: May deprecate field in future if never used

**Issue 4: Multiple Fraud Portfolios**
- **Observation**: Some loans may have multiple fraud portfolios (e.g., started as Pending, moved to Confirmed)
- **Handling**: Use LISTAGG to concatenate all portfolios, include separate date columns for each type
- **Business Action**: Use FRAUD_PORTFOLIO_COUNT to identify loans with multiple classifications

## Validation Strategy

### Critical Validation Instruction for Implementer

**⚠️ INDEPENDENT VALIDATION REQUIRED ⚠️**

Before following this PRP's guidance, you MUST perform independent data exploration and validation:

1. **Re-execute all source queries** to verify current data state
2. **Validate row counts** match expected ~509 loans
3. **Sample 10-20 loans** across different fraud statuses and verify logic
4. **Test edge cases**:
   - Loans with MIXED status (confirmed in one source, declined in another)
   - Loans with multiple fraud portfolios
   - Loans with only sub-status (should be 0 based on research)
   - Loans with NULL investigation results but confirmed portfolio
5. **Question any findings** that don't align with business context
6. **DO NOT blindly follow** this PRP - validate each transformation independently

### Data Grain and Deduplication Analysis

**⚠️ MANDATORY INVESTIGATION ⚠️**

**Grain Analysis**:
- Expected grain: One row per LOAN_ID
- Risk: Loans may appear multiple times in VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS if in multiple fraud portfolios
- Mitigation: Use GROUP BY LOAN_ID in portfolio CTE with LISTAGG for portfolio names

**Duplicate Detection Strategy**:
```sql
-- Test 1: Check for duplicate LOAN_IDs in final view
SELECT
    LOAN_ID,
    COUNT(*) as row_count
FROM [final_view]
GROUP BY LOAN_ID
HAVING COUNT(*) > 1
ORDER BY row_count DESC;
-- Expected: 0 rows

-- Test 2: Validate portfolio aggregation
SELECT
    LOAN_ID,
    FRAUD_PORTFOLIO_COUNT,
    FRAUD_PORTFOLIOS
FROM [final_view]
WHERE FRAUD_PORTFOLIO_COUNT > 1
LIMIT 10;
-- Expected: Some loans with multiple portfolios properly aggregated

-- Test 3: Check for historical vs current sub-status issues
SELECT
    ls.LOAN_ID,
    COUNT(*) as sub_status_count
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT ls
INNER JOIN BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT lss
    ON ls.LOAN_SUB_STATUS_ID = lss.ID
WHERE ls.LOAN_SUB_STATUS_ID IN (32, 61)
    AND ls.SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
    AND ls.DELETED = 0
GROUP BY ls.LOAN_ID
HAVING COUNT(*) > 1;
-- Expected: 0 rows (current view should dedupe)
```

**Time-Series Considerations**:
- VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS contains current and historical portfolio assignments
- Use MAX() or LISTAGG() to aggregate multiple portfolio dates per loan
- VW_LOAN_SETTINGS_ENTITY_CURRENT should already be deduplicated (current state only)
- VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT should be one row per loan (current state only)

### Primary Validation Tests (Consolidated in qc_validation.sql)

**Test 1: Row Count Validation**
```sql
-- 1.1: Total fraud loans (should be ~509)
SELECT COUNT(*) as total_fraud_loans FROM VW_LOAN_FRAUD;

-- 1.2: Compare to source counts
WITH source_counts AS (
    SELECT 'Custom Fields' as source, COUNT(DISTINCT LOAN_ID) as loan_count
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT
    WHERE FRAUD_CONFIRMED_DATE IS NOT NULL
       OR FRAUD_INVESTIGATION_RESULTS IS NOT NULL
       OR FRAUD_NOTIFICATION_RECEIVED IS NOT NULL
       OR FRAUD_CONTACT_EMAIL IS NOT NULL
    UNION ALL
    SELECT 'Portfolios', COUNT(DISTINCT LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS
    WHERE PORTFOLIO_CATEGORY = 'Fraud'
    UNION ALL
    SELECT 'Sub-Status', COUNT(DISTINCT LOAN_ID)
    FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT
    WHERE LOAN_SUB_STATUS_ID IN (32, 61)
        AND SCHEMA_NAME = BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()
        AND DELETED = 0
)
SELECT * FROM source_counts;
-- Expected: Custom Fields ~414, Portfolios ~361, Sub-Status ~20
```

**Test 2: Duplicate Detection**
```sql
-- 2.1: Check for duplicate LOAN_IDs
SELECT
    LOAN_ID,
    COUNT(*) as duplicate_count
FROM VW_LOAN_FRAUD
GROUP BY LOAN_ID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- Expected: 0 rows

-- 2.2: Validate unique constraint
SELECT
    COUNT(*) as total_rows,
    COUNT(DISTINCT LOAN_ID) as distinct_loans
FROM VW_LOAN_FRAUD;
-- Expected: Both counts should be equal (~509)
```

**Test 3: Data Source Distribution**
```sql
-- 3.1: Data source count distribution
SELECT
    DATA_SOURCE_COUNT,
    DATA_COMPLETENESS_FLAG,
    COUNT(*) as loan_count
FROM VW_LOAN_FRAUD
GROUP BY DATA_SOURCE_COUNT, DATA_COMPLETENESS_FLAG
ORDER BY DATA_SOURCE_COUNT DESC;
-- Expected: Majority PARTIAL (2 sources), some SINGLE_SOURCE, few COMPLETE

-- 3.2: Source combination breakdown
SELECT
    DATA_SOURCE_LIST,
    COUNT(*) as loan_count
FROM VW_LOAN_FRAUD
GROUP BY DATA_SOURCE_LIST
ORDER BY loan_count DESC;
-- Expected: "CUSTOM_FIELDS, PORTFOLIOS" most common
```

**Test 4: Fraud Status Distribution**
```sql
-- 4.1: Fraud status breakdown
SELECT
    FRAUD_STATUS,
    COUNT(*) as loan_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) as percentage
FROM VW_LOAN_FRAUD
GROUP BY FRAUD_STATUS
ORDER BY loan_count DESC;
-- Expected: Mix of CONFIRMED, DECLINED, UNDER_INVESTIGATION, some MIXED

-- 4.2: Active fraud flag distribution
SELECT
    IS_ACTIVE_FRAUD,
    FRAUD_STATUS,
    COUNT(*) as loan_count
FROM VW_LOAN_FRAUD
GROUP BY IS_ACTIVE_FRAUD, FRAUD_STATUS
ORDER BY IS_ACTIVE_FRAUD DESC, loan_count DESC;
-- Expected: Most loans should have IS_ACTIVE_FRAUD = TRUE
```

**Test 5: Data Quality Assessment**
```sql
-- 5.1: Quality flag distribution
SELECT
    DATA_QUALITY_FLAG,
    COUNT(*) as loan_count
FROM VW_LOAN_FRAUD
GROUP BY DATA_QUALITY_FLAG
ORDER BY loan_count DESC;

-- 5.2: Identify inconsistent fraud classifications
SELECT
    LOAN_ID,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    CURRENT_SUB_STATUS,
    FRAUD_STATUS,
    DATA_QUALITY_FLAG
FROM VW_LOAN_FRAUD
WHERE DATA_QUALITY_FLAG = 'INCONSISTENT'
LIMIT 20;
-- Expected: Loans with conflicting confirmed/declined indicators
```

**Test 6: Date Field Validation**
```sql
-- 6.1: Earliest fraud date calculation
SELECT
    COUNT(*) as total_loans,
    COUNT(EARLIEST_FRAUD_DATE) as has_earliest_date,
    MIN(EARLIEST_FRAUD_DATE) as oldest_fraud_date,
    MAX(EARLIEST_FRAUD_DATE) as newest_fraud_date
FROM VW_LOAN_FRAUD;

-- 6.2: Date field population
SELECT
    COUNT(FRAUD_NOTIFICATION_RECEIVED) as has_notification_date,
    COUNT(FRAUD_CONFIRMED_DATE) as has_confirmed_date,
    COUNT(FIRST_PARTY_FRAUD_CONFIRMED_DATE) as has_portfolio_date,
    COUNT(EARLIEST_FRAUD_DATE) as has_earliest_date
FROM VW_LOAN_FRAUD;

-- 6.3: Verify EARLIEST_FRAUD_DATE logic
SELECT
    LOAN_ID,
    FRAUD_NOTIFICATION_RECEIVED,
    FRAUD_CONFIRMED_DATE,
    FIRST_PARTY_FRAUD_CONFIRMED_DATE,
    IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
    FRAUD_PENDING_INVESTIGATION_DATE,
    EARLIEST_FRAUD_DATE,
    -- Manual validation: earliest should be minimum of all dates
    LEAST(
        FRAUD_NOTIFICATION_RECEIVED,
        FRAUD_CONFIRMED_DATE,
        FIRST_PARTY_FRAUD_CONFIRMED_DATE,
        IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
        FRAUD_PENDING_INVESTIGATION_DATE
    ) as expected_earliest_date
FROM VW_LOAN_FRAUD
WHERE EARLIEST_FRAUD_DATE IS NOT NULL
LIMIT 10;
-- Expected: EARLIEST_FRAUD_DATE should match expected_earliest_date
```

**Test 7: Portfolio Aggregation**
```sql
-- 7.1: Multiple portfolio validation
SELECT
    LOAN_ID,
    FRAUD_PORTFOLIO_COUNT,
    FRAUD_PORTFOLIOS
FROM VW_LOAN_FRAUD
WHERE FRAUD_PORTFOLIO_COUNT > 1
ORDER BY FRAUD_PORTFOLIO_COUNT DESC
LIMIT 10;
-- Expected: Some loans with multiple portfolios properly concatenated

-- 7.2: Portfolio date consistency
SELECT
    LOAN_ID,
    FRAUD_PORTFOLIOS,
    FIRST_PARTY_FRAUD_CONFIRMED_DATE,
    IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
    FRAUD_DECLINED_DATE,
    FRAUD_PENDING_INVESTIGATION_DATE
FROM VW_LOAN_FRAUD
WHERE FRAUD_PORTFOLIO_COUNT > 0
LIMIT 10;
-- Expected: Dates should align with portfolio names
```

**Test 8: Comparison with DI-1141 Fraud Logic**
```sql
-- 8.1: Validate fraud loans would be excluded from debt sale
-- Reference: DI-1141 line 332: COALESCE(FD.is_fraud, FALSE) = FALSE
SELECT
    vf.LOAN_ID,
    vf.FRAUD_STATUS,
    vf.IS_ACTIVE_FRAUD,
    vf.IS_CONFIRMED_FRAUD
FROM VW_LOAN_FRAUD vf
WHERE vf.IS_CONFIRMED_FRAUD = TRUE
LIMIT 10;
-- Expected: These loans should be excluded from debt sale populations

-- 8.2: Count loans that would be suppressed
SELECT
    COUNT(*) as total_fraud_loans,
    COUNT(CASE WHEN IS_CONFIRMED_FRAUD = TRUE THEN 1 END) as confirmed_fraud_suppressions,
    COUNT(CASE WHEN IS_ACTIVE_FRAUD = TRUE THEN 1 END) as active_fraud_suppressions
FROM VW_LOAN_FRAUD;
```

**Test 9: Referential Integrity**
```sql
-- 9.1: Verify all loans have LOAN_ID
SELECT COUNT(*) as null_loan_id_count
FROM VW_LOAN_FRAUD
WHERE LOAN_ID IS NULL;
-- Expected: 0 rows

-- 9.2: Verify LEAD_GUID population
SELECT
    COUNT(*) as total_loans,
    COUNT(LEAD_GUID) as has_lead_guid
FROM VW_LOAN_FRAUD;
-- Expected: Most loans should have LEAD_GUID
```

**Test 10: Null Handling**
```sql
-- 10.1: Check NULL handling in boolean flags
SELECT
    COUNT(CASE WHEN IS_ACTIVE_FRAUD IS NULL THEN 1 END) as null_active_flag,
    COUNT(CASE WHEN IS_CONFIRMED_FRAUD IS NULL THEN 1 END) as null_confirmed_flag,
    COUNT(CASE WHEN HAS_CUSTOM_FIELDS IS NULL THEN 1 END) as null_custom_fields_flag,
    COUNT(CASE WHEN HAS_FRAUD_PORTFOLIO IS NULL THEN 1 END) as null_portfolio_flag,
    COUNT(CASE WHEN HAS_FRAUD_SUB_STATUS IS NULL THEN 1 END) as null_substatus_flag
FROM VW_LOAN_FRAUD;
-- Expected: All should be 0 (boolean flags should never be NULL)

-- 10.2: Check NULL handling in calculated fields
SELECT
    COUNT(CASE WHEN FRAUD_STATUS IS NULL THEN 1 END) as null_fraud_status,
    COUNT(CASE WHEN DATA_COMPLETENESS_FLAG IS NULL THEN 1 END) as null_completeness_flag,
    COUNT(CASE WHEN DATA_SOURCE_LIST IS NULL THEN 1 END) as null_source_list
FROM VW_LOAN_FRAUD;
-- Expected: All should be 0 (all loans should have these calculated)
```

### Performance Validation

**Expected Performance**:
- Target: Query should complete "as quickly as possible"
- Source table sizes: Custom Settings (~441 fraud loans), Portfolios (~361 loans), Sub-Status (~20 loans)
- Join complexity: Multiple LEFT JOINs with aggregations
- No strict time metrics, focus on optimization

**Performance Tests**:
```sql
-- Test 1: Execution time baseline
-- Run with EXPLAIN to understand query plan
EXPLAIN
SELECT * FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD LIMIT 100;

-- Test 2: Full scan timing
SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD;
-- Document execution time for baseline

-- Test 3: Filtered query performance
SELECT *
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
WHERE IS_CONFIRMED_FRAUD = TRUE
    AND FRAUD_STATUS = 'CONFIRMED';
-- Should be fast with boolean flag filtering
```

**Optimization Considerations**:
- Use CTEs for each source to filter early (reduce data volume)
- Apply schema filtering at lowest CTE level
- Consider adding comments for query optimization hints if needed
- Materialized view consideration: If performance is slow, discuss with user

## Development Phase Requirements

### Development Environment Setup

**Critical**: All object creation and testing must occur in DEVELOPMENT/BUSINESS_INTELLIGENCE_DEV databases first:

```sql
-- Development environment objects
DEVELOPMENT.FRESHSNOW.VW_LOAN_FRAUD
BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOAN_FRAUD
BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD
```

**Development Deployment Template**:
```sql
DECLARE
    -- Use dev databases for testing
    v_de_db varchar default 'DEVELOPMENT';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE_DEV';

BEGIN
    -- FRESHSNOW layer (contains source logic)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            -- [Additional columns...]
        ) COPY GRANTS AS
            [VIEW_DEFINITION]
    ');

    -- BRIDGE layer (pass-through)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            -- [Additional columns...]
        ) COPY GRANTS AS
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_LOAN_FRAUD
    ');

    -- ANALYTICS layer (final consumer view)
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            -- [Additional columns...]
        ) COPY GRANTS AS
            SELECT * FROM ' || v_bi_db ||'.BRIDGE.VW_LOAN_FRAUD
    ');
END;
```

### Testing Against Production Data

**Important**: Development views will query production source tables:
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT (prod)
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS (prod)
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT (prod)

This ensures testing against real, current data while keeping new views in dev environment.

### Validation Execution Order

1. **Create development objects** (DEVELOPMENT/BUSINESS_INTELLIGENCE_DEV)
2. **Run all validation tests** from qc_validation.sql
3. **Review test results** with focus on:
   - Row count matches expected ~509 loans
   - Zero duplicates
   - Data quality flags properly identifying issues
   - Conservative fraud classification working correctly
4. **Iterate if needed** to fix any validation failures
5. **Document findings** in ticket README.md
6. **User review and approval** before production deployment

## Production Deployment Strategy

### Deployment Readiness Checklist

Before deploying to production, ensure:
- [ ] All QC validation tests pass in development environment
- [ ] Row count matches expected (~509 loans)
- [ ] Zero duplicate LOAN_IDs
- [ ] FRAUD_STATUS logic correctly handles MIXED cases
- [ ] IS_ACTIVE_FRAUD flag accurately identifies active fraud loans
- [ ] EARLIEST_FRAUD_DATE calculation verified with sample loans
- [ ] Data quality flags properly identifying inconsistencies
- [ ] User has reviewed sample output and approved logic
- [ ] Documentation complete in README.md
- [ ] Production deployment template prepared

### Production Deployment Template

**File**: `final_deliverables/2_production_deploy_vw_loan_fraud.sql`

```sql
USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE;
USE ROLE BUSINESS_INTELLIGENCE_PII;

DECLARE
    -- PRODUCTION databases (uncomment for production deployment)
    v_de_db varchar default 'ARCA';
    v_bi_db varchar default 'BUSINESS_INTELLIGENCE';

BEGIN
    -- FRESHSNOW layer
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_de_db || '.FRESHSNOW.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            FRAUD_INVESTIGATION_RESULTS,
            FRAUD_CONFIRMED_DATE,
            FRAUD_NOTIFICATION_RECEIVED,
            FRAUD_CONTACT_EMAIL,
            FRAUD_PORTFOLIOS,
            FRAUD_PORTFOLIO_COUNT,
            FIRST_PARTY_FRAUD_CONFIRMED_DATE,
            IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
            FRAUD_DECLINED_DATE,
            FRAUD_PENDING_INVESTIGATION_DATE,
            CURRENT_SUB_STATUS,
            LOAN_SUB_STATUS_ID,
            EARLIEST_FRAUD_DATE,
            FRAUD_STATUS,
            IS_CONFIRMED_FRAUD,
            IS_DECLINED_FRAUD,
            IS_UNDER_INVESTIGATION,
            IS_ACTIVE_FRAUD,
            HAS_CUSTOM_FIELDS,
            HAS_FRAUD_PORTFOLIO,
            HAS_FRAUD_SUB_STATUS,
            DATA_SOURCE_COUNT,
            DATA_COMPLETENESS_FLAG,
            DATA_SOURCE_LIST,
            DATA_QUALITY_FLAG
        ) COPY GRANTS AS
            -- [INSERT VIEW DEFINITION FROM DEVELOPMENT]
    ');

    -- BRIDGE layer
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.BRIDGE.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            FRAUD_INVESTIGATION_RESULTS,
            FRAUD_CONFIRMED_DATE,
            FRAUD_NOTIFICATION_RECEIVED,
            FRAUD_CONTACT_EMAIL,
            FRAUD_PORTFOLIOS,
            FRAUD_PORTFOLIO_COUNT,
            FIRST_PARTY_FRAUD_CONFIRMED_DATE,
            IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
            FRAUD_DECLINED_DATE,
            FRAUD_PENDING_INVESTIGATION_DATE,
            CURRENT_SUB_STATUS,
            LOAN_SUB_STATUS_ID,
            EARLIEST_FRAUD_DATE,
            FRAUD_STATUS,
            IS_CONFIRMED_FRAUD,
            IS_DECLINED_FRAUD,
            IS_UNDER_INVESTIGATION,
            IS_ACTIVE_FRAUD,
            HAS_CUSTOM_FIELDS,
            HAS_FRAUD_PORTFOLIO,
            HAS_FRAUD_SUB_STATUS,
            DATA_SOURCE_COUNT,
            DATA_COMPLETENESS_FLAG,
            DATA_SOURCE_LIST,
            DATA_QUALITY_FLAG
        ) COPY GRANTS AS
            SELECT * FROM ' || v_de_db ||'.FRESHSNOW.VW_LOAN_FRAUD
    ');

    -- ANALYTICS layer
    EXECUTE IMMEDIATE ('
        CREATE OR REPLACE VIEW ' || v_bi_db || '.ANALYTICS.VW_LOAN_FRAUD(
            LOAN_ID,
            LEAD_GUID,
            FRAUD_INVESTIGATION_RESULTS,
            FRAUD_CONFIRMED_DATE,
            FRAUD_NOTIFICATION_RECEIVED,
            FRAUD_CONTACT_EMAIL,
            FRAUD_PORTFOLIOS,
            FRAUD_PORTFOLIO_COUNT,
            FIRST_PARTY_FRAUD_CONFIRMED_DATE,
            IDENTITY_THEFT_FRAUD_CONFIRMED_DATE,
            FRAUD_DECLINED_DATE,
            FRAUD_PENDING_INVESTIGATION_DATE,
            CURRENT_SUB_STATUS,
            LOAN_SUB_STATUS_ID,
            EARLIEST_FRAUD_DATE,
            FRAUD_STATUS,
            IS_CONFIRMED_FRAUD,
            IS_DECLINED_FRAUD,
            IS_UNDER_INVESTIGATION,
            IS_ACTIVE_FRAUD,
            HAS_CUSTOM_FIELDS,
            HAS_FRAUD_PORTFOLIO,
            HAS_FRAUD_SUB_STATUS,
            DATA_SOURCE_COUNT,
            DATA_COMPLETENESS_FLAG,
            DATA_SOURCE_LIST,
            DATA_QUALITY_FLAG
        ) COPY GRANTS AS
            SELECT * FROM ' || v_bi_db ||'.BRIDGE.VW_LOAN_FRAUD
    ');
END;

-- Post-deployment validation
SELECT 'Production deployment complete. Running validation...' as status;

-- Quick validation queries
SELECT COUNT(*) as total_fraud_loans FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD;

SELECT
    FRAUD_STATUS,
    COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
GROUP BY FRAUD_STATUS;

SELECT
    DATA_COMPLETENESS_FLAG,
    COUNT(*) as loan_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
GROUP BY DATA_COMPLETENESS_FLAG;
```

### Post-Deployment Actions

After successful production deployment:
1. **Run validation queries** against production view
2. **Compare row counts** with development environment
3. **Test downstream integration**: Update DI-1141 debt sale query to reference new view
4. **Document in README.md**: Production deployment date, final row count, any issues encountered
5. **Update CLAUDE.md** if new patterns discovered during implementation
6. **Notify stakeholders**: Collections team, Fraud team about new view availability

## File Organization

### Expected Ticket Folder Structure
```
tickets/kchalmers/DI-[NEW]/
├── README.md                                    # Complete documentation with assumptions
├── source_materials/
│   └── INITIAL.md                              # Original requirements (copy from PRP folder)
├── final_deliverables/
│   ├── 1_vw_loan_fraud_development.sql         # Development view creation
│   ├── 2_production_deploy_vw_loan_fraud.sql   # Production deployment template
│   └── qc_validation.sql                       # All QC tests consolidated
├── exploratory_analysis/
│   ├── 1_fraud_custom_fields_exploration.sql   # Custom fields investigation
│   ├── 2_fraud_portfolios_exploration.sql      # Portfolio analysis
│   ├── 3_fraud_substatus_exploration.sql       # Sub-status investigation
│   └── 4_source_overlap_analysis.sql           # Cross-source comparison
└── [jira_comment].txt                          # Final comment for Jira ticket
```

### Simplified Deliverables Approach
- **Single QC file**: All validation tests in `qc_validation.sql` (not separate qc_queries/ folder)
- **Numbered execution order**: Files numbered for logical review progression
- **README.md + assumptions**: Complete documentation in single file
- **No version sprawl**: Update existing files rather than creating versions

## Implementation Task Order

1. **Create Jira Ticket** (if not already created)
   - Use INITIAL.md business context
   - Link to epic DI-1238
   - Assign to appropriate team member

2. **Setup Development Environment**
   - Create ticket folder structure
   - Copy INITIAL.md to source_materials/
   - Initialize README.md with assumptions

3. **Independent Data Validation** ⚠️ CRITICAL ⚠️
   - Re-run all database research queries from this PRP
   - Validate current row counts and data patterns
   - Question any discrepancies from PRP expectations
   - Document findings in exploratory_analysis/

4. **Development Phase**
   - Create view in DEVELOPMENT.FRESHSNOW.VW_LOAN_FRAUD
   - Create pass-through in BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOAN_FRAUD
   - Create consumer view in BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD

5. **Testing and Validation**
   - Execute all tests in qc_validation.sql
   - Review test results and fix any issues
   - Iterate on view definition if needed
   - Document QC results in README.md

6. **User Review**
   - Present sample output to Kyle Chalmers
   - Highlight any data quality issues discovered
   - Confirm fraud classification logic with examples
   - Get approval to proceed to production

7. **Production Deployment**
   - Create production deployment template
   - Execute deployment in production (ARCA/BUSINESS_INTELLIGENCE)
   - Run post-deployment validation
   - Document final row counts and status

8. **Downstream Integration**
   - Update DI-1141 debt sale query to reference VW_LOAN_FRAUD
   - Test debt sale suppression logic with new view
   - Document integration points in README.md

9. **Documentation and Closeout**
   - Complete README.md with all assumptions and findings
   - Create Jira comment summarizing deliverables
   - Submit pull request with semantic commit message
   - Archive and backup to Google Drive (with permission)

## Executable Validation Commands

### Development Environment Object Creation
```bash
snow sql -q "DESCRIBE DEVELOPMENT.FRESHSNOW.VW_LOAN_FRAUD" --format csv
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.BRIDGE.VW_LOAN_FRAUD" --format csv
snow sql -q "DESCRIBE BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD" --format csv
```

### Comprehensive QC Validation (Single File)
```bash
snow sql -q "$(cat final_deliverables/qc_validation.sql)" --format csv
```

### Performance Validation
```bash
snow sql -q "EXPLAIN SELECT * FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD LIMIT 100" --format csv
```

### Production Deployment Readiness (After User Review)
```bash
# Verify development view before production deployment
snow sql -q "SELECT COUNT(*) FROM BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD" --format csv

# Deploy to production (requires explicit user permission)
# snow sql -q "$(cat final_deliverables/2_production_deploy_vw_loan_fraud.sql)"
```

## Known Limitations and Future Enhancements

### Current Limitations

1. **Sub-Status Coverage**: Only 20 of 509 fraud loans have fraud-specific sub-status, indicating potential lag in status updates
2. **Sparse FRAUD_CONTACT_EMAIL**: Only 2 loans populated, field may not be actively used
3. **No Historical Tracking**: View shows current state only, doesn't capture fraud status changes over time
4. **Manual Data Quality Review**: Inconsistent data flagged but requires manual investigation to resolve

### Future Enhancement Opportunities

1. **Historical Fraud View**: Create companion view tracking fraud status changes over time using VW_LOAN_STATUS_ARCHIVE_CURRENT
2. **Automated Alerting**: Build data quality monitoring to alert when new MIXED status loans appear
3. **Integration with Similar Views**: Create VW_LOAN_DECEASED and VW_LOAN_SCRA following same pattern
4. **Unified Suppression View**: Combine fraud, deceased, and SCRA into single debt sale suppression source
5. **Materialized View**: If performance becomes concern, consider materializing view with scheduled refresh
6. **Fraud Timeline Analysis**: Add calculated fields for fraud investigation duration, resolution time

## Success Metrics

### Immediate Success Criteria
- [ ] View successfully deployed to ANALYTICS layer
- [ ] All 509+ fraud loans captured
- [ ] Zero duplicate LOAN_IDs
- [ ] Conservative fraud classification working (any confirmed source → CONFIRMED)
- [ ] Data quality flags highlighting inconsistencies
- [ ] All QC validation tests passing

### Integration Success Criteria
- [ ] Successfully integrated into debt sale suppression logic (replacing DI-1141 inline fraud logic)
- [ ] DI-1246 (1099C) can use view for fraud exclusion
- [ ] Collections team can use for fraud loan identification

### Data Quality Success Criteria
- [ ] MIXED status loans identified and documented for review
- [ ] Sub-status lag documented and communicated to stakeholders
- [ ] Sparse field usage (FRAUD_CONTACT_EMAIL) documented for potential deprecation

## Additional Context and References

### Related Tickets Context

**DI-1246: 1099C Data Review**
- Needs to exclude fraud loans from settlement analysis
- Can use `WHERE NOT EXISTS (SELECT 1 FROM VW_LOAN_FRAUD WHERE IS_CONFIRMED_FRAUD = TRUE)`
- Provides clean fraud exclusion without inline logic

**DI-1235: Update Settlements Dashboard**
- May need fraud indicators for settlement data quality
- Can LEFT JOIN to VW_LOAN_FRAUD to show fraud status of settlements
- Helps identify settlements on potentially fraudulent loans

**DI-1141: Debt Sale Population (Reference Implementation)**
- Line 56-62: Inline fraud lookup from development._tin.fraud_scra_decease_lookup
- Line 332: Exclusion logic `COALESCE(FD.is_fraud, FALSE) = FALSE`
- **Future**: Replace inline fraud logic with VW_LOAN_FRAUD reference

### External References

**VW_LOAN_DEBT_SETTLEMENT Pattern**:
- Source: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT`
- Pattern elements successfully adapted: Source CTEs, UNION population, LEFT JOINs, data tracking flags
- Key learning: LISTAGG for multiple portfolios, data completeness flags, source list tracking

**VW_LOAN_BANKRUPTCY Pattern**:
- Source: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY`
- Pattern elements adapted: MOST_RECENT_ACTIVE flag logic, duplicate handling, data source tracking
- Key learning: Conservative classification approach, active vs inactive status determination

### Assumptions Documented

1. **Fraud Definition**: Any loan with fraud indicator from any source (custom fields, portfolios, or sub-status) is considered a fraud case
2. **Conservative Classification**: If any source indicates confirmed fraud, loan is classified as CONFIRMED regardless of other sources
3. **Active Fraud**: Loan is active if has fraud portfolio OR fraud sub-status OR confirmed investigation result
4. **Data Lag Acceptable**: Sub-status lag (only 20 loans) is acceptable and documented; portfolios and custom fields are primary indicators
5. **Portfolio Priority**: Multiple fraud portfolios are aggregated, not prioritized; all portfolio history preserved in LISTAGG
6. **Sparse Field Inclusion**: FRAUD_CONTACT_EMAIL included despite low population per user requirement to capture all available data
7. **Date Calculation**: EARLIEST_FRAUD_DATE uses LEAST() across all date fields, providing best estimate of initial fraud identification
8. **Single Grain**: One row per LOAN_ID is sufficient; no need for historical view in initial implementation

## Confidence Assessment: 9/10

### High Confidence Factors
- ✅ Complete database research with actual data samples
- ✅ Clear business requirements and stakeholder input
- ✅ Established patterns from VW_LOAN_DEBT_SETTLEMENT and VW_LOAN_BANKRUPTCY
- ✅ Conservative fraud classification logic validated with user
- ✅ Comprehensive QC validation strategy with 10 test categories
- ✅ Clear data source tracking and quality flags
- ✅ Executable validation commands provided
- ✅ Architecture compliance verified (5-layer pattern)

### Minor Uncertainty (-1 Point)
- ⚠️ MIXED status handling may need iteration based on actual inconsistency patterns discovered during testing
- ⚠️ Performance optimization may require adjustments based on execution times (no materialization planned initially)

### Mitigation
- Independent data validation required before implementation
- User review of sample output before production deployment
- Iterative testing approach in development environment

**Target Met**: 8+ required for production data object creation

---

## Document Control
- **PRP Version**: 1.0
- **Last Updated**: 2025-10-02
- **Author**: Claude Code (Data Intelligence MCP)
- **Reviewer**: Kyle Chalmers (pending)
- **Status**: Draft - Awaiting Implementation
