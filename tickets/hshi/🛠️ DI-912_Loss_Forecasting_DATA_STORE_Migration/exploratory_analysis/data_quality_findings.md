# DI-912: Critical Data Quality Findings

## Summary

**MIGRATION BLOCKED**: The BI-1451 Loss Forecasting job uses `DATA_STORE.VW_LOAN_COLLECTION` which contains **legacy CLS data** that does not map cleanly to current LoanPro-based ANALYTICS tables.

## Data Comparison Results

### Record Count Discrepancies

| Source | Total Records | Cease & Desist | Bankruptcy | Autopay |
|--------|---------------|----------------|------------|---------|
| **Old Pattern** (DATA_STORE.VW_LOAN_COLLECTION) | 337,219 | 20,650 (6.1%) | 6,633 (2.0%) | 214,590 (63.6%) |
| **New Pattern** (ANALYTICS/BRIDGE) | 347,905 | 2,650 (0.8%) | 2,272 (0.7%) | 392 (0.1%) |

### Key Findings

1. **Record Count Mismatch**:
   - DATA_STORE: 337,219 loans (deduplicated)
   - VW_LOAN: 347,835 loans
   - **Gap**: ~10,600 more loans in VW_LOAN (newer LoanPro data)

2. **CEASE_AND_DESIST Coverage**:
   - DATA_STORE shows 20,650 loans with cease & desist
   - VW_LOAN_CONTACT_RULES shows only 2,678 total (active records)
   - **Only 958 out of 20,624 loans (4.6%) match** between old and new

3. **BANKRUPTCY Coverage**:
   - DATA_STORE shows 6,633 loans with bankruptcy
   - VW_LOAN_BANKRUPTCY shows 2,272 active bankruptcy records
   - Significant gap in coverage

4. **AUTOPAY Coverage**:
   - DATA_STORE shows 214,590 loans with autopay enabled (63.6%)
   - VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT shows only 392 (0.1%)
   - **Massive discrepancy** - suggests different data source or field

## Root Cause Analysis

### CLS vs LoanPro Data

`DATA_STORE.VW_LOAN_COLLECTION` appears to be:
- **Legacy CLS (Cloud Lending System / Salesforce) data**
- Historical loan collection with older platform data
- Not current/active LoanPro data

Evidence:
1. Record count doesn't match current VW_LOAN (337K vs 348K)
2. Flag values use 'Y'/'N' strings (CLS pattern) vs TRUE/FALSE booleans (LoanPro pattern)
3. DEBIT_BILL_AUTOMATIC uses 'Ach On'/'Off' instead of yes/no
4. Massive data coverage gaps for all flags

### AUTOPAY_OPT_IN Field Issue - RESOLVED

**Discovery**: Found correct autopay source - `BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT`
- Uses numeric values (1/0) instead of 'yes'/'no'
- VW_LMS has **70,265 autopay enabled** vs 392 in VW_LOS
- Much better coverage but still **67% gap** vs DATA_STORE (214,590)

**Updated Coverage with VW_LMS**:
- Old Pattern: 214,590 autopay enabled (63.6%)
- New Pattern (VW_LMS): 70,265 autopay enabled (20.2%)
- **Improvement**: From 99.8% loss to 67% loss
- **Still significant gap**: 144,325 missing records

## Impact on BI-1451 Loss Forecasting

The job currently uses `dist_auto` CTE to get collection-related flags for forecasting. The migration to ANALYTICS tables would result in:

1. **Missing 90%+ of cease & desist suppressions** (20,650 → 958)
2. **Missing 66% of bankruptcy flags** (6,633 → 2,272)
3. **Missing 99.8% of autopay flags** (214,590 → 392)

**This would fundamentally break the forecasting model's business logic.**

## Recommendations

### Option 1: Keep Using DATA_STORE.VW_LOAN_COLLECTION (SHORT TERM)
- **Action**: Document that this specific DATA_STORE table must remain until proper migration path is identified
- **Rationale**: Critical business logic depends on this data
- **Risk**: Continues using legacy schema against architecture principles

### Option 2: Investigate Proper LoanPro Sources (RECOMMENDED)
- **Action**: Work with platform team to identify correct LoanPro tables for:
  - Cease & desist status
  - Bankruptcy flags
  - Autopay enrollment status
- **Questions to answer**:
  - Where is current cease & desist data stored in LoanPro?
  - Where is current autopay status stored (not VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT.AUTOPAY_OPT_IN)?
  - Why does VW_LOAN_BANKRUPTCY have fewer records than DATA_STORE?
  - Are there BRIDGE/FRESHSNOW sources we should use instead?

### Option 3: Hybrid Approach
- **Action**: Migrate what we can, keep DATA_STORE for gaps
- **Approach**:
  - Use VW_LOAN_BANKRUPTCY for bankruptcy (accept 66% coverage as accurate current state)
  - Keep DATA_STORE.VW_LOAN_COLLECTION for cease & desist and autopay until proper sources found
- **Risk**: Mixing legacy and current data may cause inconsistencies

## Next Steps

1. **Consult with platform/data architecture team** about:
   - Proper LoanPro source for cease & desist flags
   - Proper LoanPro source for autopay status
   - Whether DATA_STORE.VW_LOAN_COLLECTION should be migrated or kept

2. **Investigate BRIDGE/FRESHSNOW layers**:
   - Check if BRIDGE has better coverage for these fields
   - Verify if FRESHSNOW has cease & desist / autopay data

3. **Review job business logic**:
   - Understand how these flags impact forecasting
   - Determine acceptable data quality thresholds
   - Assess if historical CLS data is intentionally used

4. **Document exception**:
   - If DATA_STORE.VW_LOAN_COLLECTION must be kept, document as architectural exception
   - Create plan for eventual migration when proper LoanPro sources are available

## Query Results Reference

### VW_LOAN_CONTACT_RULES Coverage
```
Total loans: 515,583
Active rules: 515,583
Cease & desist: 2,678
```

### VW_LOAN_BANKRUPTCY Coverage
```
Total loans: 7,868
Active records: 2,386
Active bankruptcy: 2,274
```

### VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT Coverage
```
Total loans: 3,452,773
Autopay enabled: 10,249
Autopay disabled: 3,390
Autopay NULL: 3,439,134
```

### Overlap Analysis
```
Old pattern loans with CEASE_AND_DESIST='Y': 20,624
Found in VW_LOAN_CONTACT_RULES: 958 (4.6% coverage)
```

## Conclusion

**DI-912 migration is BLOCKED pending clarification on proper LoanPro data sources.**

The current ANALYTICS/BRIDGE tables do not provide equivalent coverage to DATA_STORE.VW_LOAN_COLLECTION. This appears to be a fundamental difference between legacy CLS data and current LoanPro data, not a simple table mapping issue.

**Recommendation**: Escalate to platform/architecture team for guidance before proceeding with migration.
