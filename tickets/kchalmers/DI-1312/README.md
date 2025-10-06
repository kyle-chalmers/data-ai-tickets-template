# DI-1312: Create VW_LOAN_FRAUD - Single Source of Truth for Fraud Data

## Ticket Information
- **Jira Link:** https://happymoneyinc.atlassian.net/browse/DI-1312
- **Type:** Data Engineering Task
- **Status:** In Spec
- **Epic:** DI-1238 (Data Object Alteration)
- **Assignee:** Kyle Chalmers

## Business Summary

Created comprehensive fraud view combining three data sources (custom fields, portfolios, sub-statuses) into a single source of truth for fraud loan identification, analysis, and debt sale suppression.

**Key Achievement**: 506 production fraud loans successfully consolidated with conservative classification logic ensuring no fraud cases are missed.

## Deliverables

### 1. Development Views (Complete ✓)
- `BUSINESS_INTELLIGENCE_DEV.ANALYTICS.VW_LOAN_FRAUD` - Single view with core fraud logic

### 2. Production Deployment Template
- `final_deliverables/2_production_deploy_vw_loan_fraud.sql` - Ready for production deployment

### 3. Quality Control
- `qc_validation.sql` - 12 comprehensive validation test categories
- All tests PASSED with 509 loans confirmed

## Key Findings

### Fraud Loan Population
- **Total Fraud Loans**: 509
- **Source Distribution**:
  - Custom Fields: 414 loans (81%)
  - Fraud Portfolios: 361 loans (71%)
  - Fraud Sub-Status: 20 loans (4%)

### Data Source Overlap
- **Complete Data** (all 3 sources): 20 loans (4%)
- **Partial Data** (2 sources): 246 loans (48%)
- **Single Source**: 243 loans (48%)

### Fraud Status Classification
- **CONFIRMED**: 210 loans (41%) - Confirmed fraud via any source
- **DECLINED**: 155 loans (30%) - Investigation declined
- **UNKNOWN**: 141 loans (28%) - Has fraud indicator but no clear status
- **UNDER_INVESTIGATION**: 3 loans (1%) - Active investigation

### Date Analysis
- **Loans with EARLIEST_FRAUD_DATE**: 502 of 509 (99%)
- **Oldest Fraud Date**: 2022-01-19
- **Newest Fraud Date**: 2025-10-01

## Business Logic

### Conservative Fraud Classification
**Rule**: If ANY source indicates confirmed fraud, the loan is classified as CONFIRMED.

This ensures maximum protection for debt sale operations - better to exclude a loan unnecessarily than include a fraudulent loan.

### IS_ACTIVE_FRAUD Flag
A loan has `IS_ACTIVE_FRAUD = TRUE` if:
- Has fraud portfolio (any type), OR
- Has fraud sub-status (Open or Closed), OR
- Has confirmed investigation result

**Result**: 361 of 509 loans (71%) flagged as active fraud

### EARLIEST_FRAUD_DATE Calculation
Minimum date across all fraud date fields:
- FRAUD_NOTIFICATION_RECEIVED
- FRAUD_CONFIRMED_DATE
- FIRST_PARTY_FRAUD_CONFIRMED_DATE
- IDENTITY_THEFT_FRAUD_CONFIRMED_DATE
- FRAUD_PENDING_INVESTIGATION_DATE
- FRAUD_DECLINED_DATE

NULL dates are excluded from calculation.

## Use Cases

### 1. Debt Sale Suppression
**Purpose**: Exclude fraud loans from debt sale populations

**Example Usage**:
```sql
-- Exclude confirmed fraud from debt sale
SELECT loan_data.*
FROM debt_sale_population loan_data
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD fraud
    ON loan_data.LOAN_ID = fraud.LOAN_ID
WHERE fraud.IS_CONFIRMED_FRAUD IS NULL
   OR fraud.IS_CONFIRMED_FRAUD = FALSE;
```

### 2. Fraud Analysis and Reporting
**Purpose**: Track fraud cases, timelines, outcomes

**Example Usage**:
```sql
-- Fraud trend analysis by month
SELECT
    DATE_TRUNC('month', EARLIEST_FRAUD_DATE) as fraud_month,
    FRAUD_STATUS,
    COUNT(*) as fraud_count
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
WHERE EARLIEST_FRAUD_DATE IS NOT NULL
GROUP BY fraud_month, FRAUD_STATUS
ORDER BY fraud_month DESC;
```

### 3. Data Quality Monitoring
**Purpose**: Identify inconsistencies in fraud data

**Example Usage**:
```sql
-- Find loans with conflicting fraud classifications
SELECT
    LOAN_ID,
    FRAUD_INVESTIGATION_RESULTS,
    FRAUD_PORTFOLIOS,
    FRAUD_STATUS,
    DATA_QUALITY_FLAG
FROM BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD
WHERE DATA_QUALITY_FLAG = 'INCONSISTENT';
```

## QC Results Summary

### All Critical Tests PASSED
- ✓ Total loans: 509 (matches expected)
- ✓ Zero duplicate LOAN_IDs
- ✓ All boolean flags properly set (no NULLs)
- ✓ Conservative classification logic working correctly
- ✓ EARLIEST_FRAUD_DATE calculation working (502 loans with dates)

### Data Quality Findings
- **No INCONSISTENT loans** - No conflicting classifications found
- **Sub-status lag** - Only 20 of 509 loans have fraud sub-status (expected, documented)
- **LEAD_GUID coverage** - 81% of loans have LEAD_GUID (414 of 509)

## Assumptions Made

### 1. Conservative Fraud Classification
**Assumption**: If any source confirms fraud, classify as CONFIRMED regardless of other sources.

**Reasoning**: Debt sale suppression requires maximum protection - false positive is better than false negative.

**Impact**: Some declined investigations may still show as CONFIRMED if they have a confirmed portfolio.

### 2. Active Fraud Definition
**Assumption**: Fraud portfolio presence = active fraud, even if investigation declined.

**Reasoning**: Portfolios reflect current operational state; inclusion indicates business treats as fraud.

**Impact**: 361 loans flagged as active (including some with declined investigations).

### 3. UNKNOWN Status Category
**Assumption**: Loans with fraud indicators but no clear status should be flagged for review.

**Reasoning**: 141 loans have fraud confirmed dates but no investigation result or matching portfolio.

**Impact**: These loans need manual review to determine appropriate classification.

### 4. Date Field Priority
**Assumption**: All date fields equally valid for EARLIEST_FRAUD_DATE calculation.

**Reasoning**: Different dates represent different fraud lifecycle events; earliest is most meaningful.

**Impact**: EARLIEST_FRAUD_DATE may not match any single source field.

### 5. Sub-Status Lag Acceptable
**Assumption**: Low sub-status coverage (20 loans) reflects operational lag, not data issue.

**Reasoning**: Custom fields and portfolios updated more frequently than sub-status changes.

**Impact**: IS_ACTIVE_FRAUD doesn't require sub-status presence.

## Integration Impact

### Related Tickets
- **DI-1246** (1099C Data Review): Can now use VW_LOAN_FRAUD for fraud exclusion
- **DI-1235** (Settlements Dashboard): Can add fraud indicators to settlement analysis
- **DI-1141** (Debt Sale Population): Will replace inline fraud logic with VW_LOAN_FRAUD reference

### Downstream Systems
None currently - this is a new view. Future integrations should reference `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD`.

## Technical Details

### Architecture
- **Layer**: ANALYTICS only (single-layer deployment)
- **Data Grain**: One row per LOAN_ID with any fraud indicator
- **Referencing**: References BRIDGE layer views (VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT, VW_LOAN_SETTINGS_ENTITY_CURRENT, etc.)
- **Performance**: Fast queries (~1 second for full table scan of 509 rows)

### Schema Filtering
Properly applies `BUSINESS_INTELLIGENCE.CONFIG.LMS_SCHEMA()` filtering to avoid duplicate data from multiple LoanPro instances.

### Column Structure
- **Identifiers**: LOAN_ID (primary key), LEAD_GUID
- **Source Data**: Custom fields, portfolios, sub-status (preserved as-is)
- **Calculated Fields**: EARLIEST_FRAUD_DATE, FRAUD_STATUS
- **Boolean Flags**: IS_CONFIRMED_FRAUD, IS_DECLINED_FRAUD, IS_UNDER_INVESTIGATION, IS_ACTIVE_FRAUD
- **Data Quality**: HAS_CUSTOM_FIELDS, HAS_FRAUD_PORTFOLIO, HAS_FRAUD_SUB_STATUS, DATA_SOURCE_COUNT, DATA_COMPLETENESS_FLAG, DATA_SOURCE_LIST, DATA_QUALITY_FLAG

## Files Included

- `README.md` - This file (business summary)
- `CLAUDE.md` - Complete technical context for future AI assistance
- `final_deliverables/1_vw_loan_fraud_development.sql` - Development view creation
- `final_deliverables/2_production_deploy_vw_loan_fraud.sql` - Production deployment template
- `qc_validation.sql` - Comprehensive quality control validation
- `source_materials/snowflake-data-object-vw-loan-fraud.md` - Original PRP document

## Production Deployment

**Status**: Ready for deployment after user review

**Pre-Deployment Steps**:
1. Review development view output
2. Confirm fraud classification logic with stakeholders
3. Schedule deployment window
4. Notify Collections team and Fraud team

**Deployment Command**:
```bash
snow sql -f final_deliverables/2_production_deploy_vw_loan_fraud.sql
```

**Post-Deployment**:
1. Verify row count matches development (~509)
2. Update DI-1141 debt sale query to use new view
3. Document in CLAUDE.md for future reference

## Contact

- **Primary**: Kyle Chalmers (kchalmers@happymoney.com)
- **Jira Ticket**: DI-1312
- **Git Branch**: DI-1312

---

**Completed**: 2025-10-02
**Development Environment**: All views created and QC validated
**Ready for**: User review and production deployment approval
