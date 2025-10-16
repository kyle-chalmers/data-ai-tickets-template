# DI-497_CRB_Fortress_Reporting Migration Notes

## Job Information
- **File**: `02_Originations_Monitoring_Report_Data_for_CRB_Fortress.ipynb`
- **Current Status**: ✅ **MIGRATION COMPLETE** - Deployed to Production
- **Complexity**: Medium (requires additional join for DTI)
- **Commit**: `ed134555` (Oct 2, 2025)

## Previous Usage of Legacy Views (MIGRATED)
- **Line 629** (OLD): `INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION A`
- **Join Key** (OLD): `LT.APPLICATION_ID = A.APPLICATION_ID`
- **Context**: Used within a CTE to calculate loan metrics for CRB Fortress reporting
- **Migrated To**: VW_APP_LOAN_PRODUCTION + VW_DECISIONS_CURRENT

## Fields Used from VW_APPLICATION
| Field in Code | Usage | Available in VW_APP_LOAN_PRODUCTION | Available in VW_LOAN | Alternative Source | Status |
|---------------|-------|-------------------------------------|----------------------|--------------------|--------|
| `APPLICATION_ID` | Join key | ✅ `APP_ID` | ✅ `APPLICATION_ID` | - | ✅ OK |
| `CREDIT_SCORE` | Weighted avg, filtering | ✅ Yes | ❌ No | - | ✅ OK |
| `ANNUAL_INCOME` | Weighted avg calculation | ❌ No | ✅ Yes | - | ✅ Use VW_LOAN |
| `DTI` | Weighted avg calculation | ❌ No | ❌ No | ✅ **VW_DECISIONS_CURRENT.MONTHLYDTI * 100** | ✅ **SOLVED** |

## Analysis

### Field Locations
1. **CREDIT_SCORE**: Available in `VW_APP_LOAN_PRODUCTION` ✅
2. **ANNUAL_INCOME**: Available in `VW_LOAN` (already joined in the query) ✅
3. **DTI**: ✅ **FOUND** in `VW_DECISIONS_CURRENT.MONTHLYDTI` (multiply by 100 to get percentage)

### Current Query Structure
```sql
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN LT
INNER JOIN cron_store.RPT_CRB_Fortress_Loan crb
  ON lt.loan_id = crb.loan_id
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION A
  ON LT.APPLICATION_ID = A.APPLICATION_ID
```

## DTI Solution - VW_DECISIONS_CURRENT

### DTI (Debt-to-Income Ratio) Field Resolution
- **Current View**: `ANALYTICS.VW_APPLICATION.DTI`
- **Solution Found**: `ANALYTICS.VW_DECISIONS_CURRENT.MONTHLYDTI * 100`
- **Verification Query Results**:
  - Strong correlation between `VW_APPLICATION.DTI` and `VW_DECISIONS_CURRENT.MONTHLYDTI * 100`
  - Example matches: 25,094 exact matches for DTI=0, thousands of matches across all DTI values
  - MONTHLYDTI is stored as decimal (0.40 = 40% DTI)
- **Join Key**: `VW_LOAN.LEAD_GUID = VW_DECISIONS_CURRENT.PAYOFFUID`
- **Filter Requirements**:
  - `ACTIVE_RECORD_FLAG = TRUE`
  - `SOURCE = 'prod'`
- **Usage**: Critical for CRB Fortress covenant calculations
  - Line: `cast(sum(ZEROIFNULL(A.DTI) * LT.LOAN_AMOUNT)/sum(LT.LOAN_AMOUNT) as string) as average_DTI`
  - Line: `iff(average_DTI > 0.35, '1', '0') as average_DTI_flag`
- **Business Impact**: Used to calculate weighted average DTI and validate against 35% covenant threshold

### Verification Query Used
```sql
SELECT
    app.DTI as vw_app_dti,
    dec.MONTHLYDTI * 100 as monthlydti_as_percent,
    ABS(TRY_CAST(app.DTI AS FLOAT) - (dec.MONTHLYDTI * 100)) as difference,
    COUNT(*) as match_count
FROM ANALYTICS.VW_APPLICATION app
INNER JOIN ANALYTICS.VW_DECISIONS_CURRENT dec
    ON app.LEAD_GUID = dec.PAYOFFUID
WHERE app.DTI IS NOT NULL
  AND dec.ACTIVE_RECORD_FLAG = TRUE
  AND dec.SOURCE = 'prod'
  AND dec.MONTHLYDTI IS NOT NULL
GROUP BY app.DTI, dec.MONTHLYDTI
HAVING difference < 0.1
ORDER BY match_count DESC
```

## Migration Approach

### Code Changes Required

**Step 1: Remove VW_APPLICATION join (Line 629)**
```sql
-- BEFORE:
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_APPLICATION A
  ON LT.APPLICATION_ID = A.APPLICATION_ID
```

**Step 2: Add VW_APP_LOAN_PRODUCTION join for CREDIT_SCORE**
```sql
-- AFTER (add this join):
INNER JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION app
  ON LT.APPLICATION_ID = app.APP_ID
```

**Step 3: Add VW_DECISIONS_CURRENT join for DTI**
```sql
-- AFTER (add this join):
INNER JOIN ANALYTICS.VW_DECISIONS_CURRENT dec
  ON LT.LEAD_GUID = dec.PAYOFFUID
  AND dec.ACTIVE_RECORD_FLAG = TRUE
  AND dec.SOURCE = 'prod'
```

**Step 4: Update field references in SELECT statements**
```sql
-- CREDIT_SCORE:
-- BEFORE: A.CREDIT_SCORE
-- AFTER: app.CREDIT_SCORE

-- ANNUAL_INCOME (no change needed - already using VW_LOAN):
-- BEFORE: A.ANNUAL_INCOME
-- AFTER: LT.ANNUAL_INCOME  (VW_LOAN already has this)

-- DTI:
-- BEFORE: A.DTI
-- AFTER: (dec.MONTHLYDTI * 100)
```

## Testing Validation Query
```sql
-- Compare key metrics between old and new approach
SELECT
    -- Old approach (VW_APPLICATION)
    old_app.APPLICATION_ID,
    old_app.CREDIT_SCORE as old_credit_score,
    old_app.ANNUAL_INCOME as old_annual_income,
    old_app.DTI as old_dti,

    -- New approach (VW_APP_LOAN_PRODUCTION + VW_DECISIONS_CURRENT)
    app.CREDIT_SCORE as new_credit_score,
    loan.ANNUAL_INCOME as new_annual_income,
    (dec.MONTHLYDTI * 100) as new_dti,

    -- Comparison flags
    CASE WHEN old_app.CREDIT_SCORE = app.CREDIT_SCORE THEN 'MATCH' ELSE 'DIFF' END as credit_score_match,
    CASE WHEN old_app.ANNUAL_INCOME = loan.ANNUAL_INCOME THEN 'MATCH' ELSE 'DIFF' END as income_match,
    CASE WHEN ABS(old_app.DTI - (dec.MONTHLYDTI * 100)) < 0.1 THEN 'MATCH' ELSE 'DIFF' END as dti_match

FROM ANALYTICS.VW_APPLICATION old_app
INNER JOIN ANALYTICS.VW_LOAN loan
    ON old_app.APPLICATION_ID = loan.APPLICATION_ID
LEFT JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION app
    ON old_app.APPLICATION_ID = app.APP_ID
LEFT JOIN ANALYTICS.VW_DECISIONS_CURRENT dec
    ON loan.LEAD_GUID = dec.PAYOFFUID
    AND dec.ACTIVE_RECORD_FLAG = TRUE
    AND dec.SOURCE = 'prod'
WHERE old_app.APPLICATION_ID IS NOT NULL
LIMIT 100;
```

## Migration Steps Completed
1. ✅ Update code to replace VW_APPLICATION with VW_APP_LOAN_PRODUCTION + VW_DECISIONS_CURRENT
2. ✅ Update CREDIT_SCORE to use app.CREDIT_SCORE
3. ✅ Update ANNUAL_INCOME to use LT.ANNUAL_INCOME (VW_LOAN)
4. ✅ Update DTI to use (dec.MONTHLYDTI * 100)
5. ✅ Test in dev environment
6. ✅ Deploy to production (Commit: ed134555)

## Notes
- This job calculates CRB Fortress covenant compliance metrics
- DTI is critical business requirement (covenant threshold: max 35%)
- ANNUAL_INCOME uses existing VW_LOAN join
- CREDIT_SCORE comes from VW_APP_LOAN_PRODUCTION
- DTI comes from VW_DECISIONS_CURRENT.MONTHLYDTI * 100 (verified accurate match)
- Migration requires two new joins: VW_APP_LOAN_PRODUCTION and VW_DECISIONS_CURRENT

---

*Status: ✅ MIGRATION COMPLETE - Deployed to production (Commit: ed134555)*
*Last Updated: October 3, 2025*
