# VW_APP_STATUS_TRANSITION

**Schema**: ANALYTICS
**Type**: View
**Purpose**: Application status transition tracking with timestamps and occurrence counts

## Overview

`VW_APP_STATUS_TRANSITION` tracks all status transitions for applications throughout the loan origination lifecycle. For each status, the view provides:
- **MIN_TS**: First time the application entered this status
- **MAX_TS**: Most recent time the application entered this status
- **CNT**: Total number of times the application entered this status

This structure allows analysis of application flow, timing between stages, and identification of applications that revisit certain statuses multiple times.

## Primary Keys and Identifiers

| Field | Type | Description |
|-------|------|-------------|
| `APP_ID` | NUMBER(10,0) | Application ID (legacy identifier) |
| `GUID` | TEXT | Global Unique Identifier - primary join key |

⚠️ **Join Key**: Use `GUID` for joins with other application tables

## Status Categories

### Landing and Start Statuses

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `AFFILIATE_LANDED` | ✓ | ✓ | ✓ | User landed via affiliate link |
| `AFFILIATE_STARTED` | ✓ | ✓ | ✓ | User started application via affiliate |
| `STARTED` | ✓ | ✓ | ✓ | Application started (main entry point) |
| `ALLOCATED` | ✓ | ✓ | ✓ | Application allocated to processing |

**Common Use**: Track entry channel and initial engagement timing

### Application Submission

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `APPLIED` | ✓ | ✓ | ✓ | Application submitted |

**Common Use**: Calculate time from start to submission (`APPLIED_MIN_TS - STARTED_MIN_TS`)

### Credit and Fraud Checks

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `FRAUD_CHECK_RECEIVED` | ✓ | ✓ | ✓ | Fraud check request received |
| `FRAUD_CHECK_FAILED` | ✓ | ✓ | ✓ | Fraud check failed |
| `FRAUD_REJECTED` | ✓ | ✓ | ✓ | Application rejected due to fraud |
| `CREDIT_FREEZE` | ✓ | ✓ | ✓ | Credit file frozen |
| `CREDIT_FREEZE_STACKER_CHECK` | ✓ | ✓ | ✓ | Stacker check during credit freeze |

**Common Use**: Identify fraud patterns and timing of security checks

### Stacker Check Process

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `STACKER_CHECK_REQUESTED` | ✓ | ✓ | ✓ | Stacker check requested |
| `STACKER_CHECK_REQUEST_RECEIVED` | ✓ | ✓ | ✓ | Stacker check request received |
| `STACKER_CHECK_COMPLETED` | ✓ | ✓ | ✓ | Stacker check completed |

**Common Use**: Measure stacker check processing time and volume

### Underwriting and Decision

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `AUTOMATED_UNDERWRITING_REQUESTED` | ✓ | ✓ | ✓ | Automated underwriting requested |
| `AUTOMATED_UNDERWRITING_RECEIVED` | ✓ | ✓ | ✓ | Automated underwriting request received |
| `AUTOMATED_UNDERWRITING_COMPLETED` | ✓ | ✓ | ✓ | Automated underwriting completed |
| `UNDERWRITING` | ✓ | ✓ | ✓ | In underwriting process |
| `UNDERWRITING_COMPLETE` | ✓ | ✓ | ✓ | Underwriting completed |

**Common Use**: Track underwriting funnel and processing times

### Offer Decision Process

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `OFFERS_DECISION_REQUESTED` | ✓ | ✓ | ✓ | Offer decision requested |
| `OFFERS_DECISION_RECEIVED` | ✓ | ✓ | ✓ | Offer decision request received |
| `OFFERS_DECISION_COMPLETED` | ✓ | ✓ | ✓ | Offer decision completed |
| `OFFERS_SHOWN` | ✓ | ✓ | ✓ | Offers displayed to customer |
| `OFFER_SELECTED` | ✓ | ✓ | ✓ | Customer selected an offer |

**Common Use**: Analyze offer presentation and selection timing

### Approval Statuses

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `APPROVED` | ✓ | ✓ | ✓ | Application approved |
| `APPROVED_RECEIVED` | ✓ | ✓ | ✓ | Approval notification received |
| `DECLINED` | ✓ | ✓ | ✓ | Application declined |
| `PARTNER_REJECTED` | ✓ | ✓ | ✓ | Rejected by partner institution |
| `EXPIRED` | ✓ | ✓ | ✓ | Approval expired |
| `WITHDRAWN` | ✓ | ✓ | ✓ | Application withdrawn |

**Common Use**: Calculate approval rates and time to decision

### Truth-in-Lending (TIL) Process

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `TIL_GENERATION_REQUESTED` | ✓ | ✓ | ✓ | TIL document generation requested |
| `TIL_GENERATION_RECEIVED` | ✓ | ✓ | ✓ | TIL generation request received |
| `TIL_GENERATION_COMPLETE` | ✓ | ✓ | ✓ | TIL document generated |
| `TIL_ACKNOWLEDGED` | ✓ | ✓ | ✓ | Customer acknowledged TIL |

**Common Use**: Track regulatory compliance and document timing

### Direct Credit Payment (DCP) Process

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `AWAITING_DCP` | ✓ | ✓ | ✓ | Awaiting DCP setup |
| `DCP_OPT_IN` | ✓ | ✓ | ✓ | Customer opted into DCP |
| `DCP_CAPTURED` | ✓ | ✓ | ✓ | DCP information captured |

**Common Use**: Analyze DCP adoption and timing

### Document Upload and Verification

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `DOC_UPLOAD` | ✓ | ✓ | ✓ | Documents uploaded |
| `ICS` | ✓ | ✓ | ✓ | Income/identity verification status |

**Common Use**: Track document collection timing

### Loan Documentation

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `LOAN_DOCS_READY` | ✓ | ✓ | ✓ | Loan documents ready for signature |
| `LOAN_DOCS_SIGNED_REQUESTED` | ✓ | ✓ | ✓ | Signature requested |
| `LOAN_DOCS_COMPLETED` | ✓ | ✓ | ✓ | Loan documents signed |

**Common Use**: Measure time to sign and document completion rates

### Autopay Setup

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `AUTOPAY_DATA_SUBMITTED` | ✓ | ✓ | ✓ | Autopay data submitted |
| `AUTOPAY_COMPLETED_REQUESTED` | ✓ | ✓ | ✓ | Autopay completion requested |
| `AUTOPAY_OPT_OUT_REQUESTED` | ✓ | ✓ | ✓ | Autopay opt-out requested |
| `AUTOPAY_OPT_OUT_RECEIVED` | ✓ | ✓ | ✓ | Autopay opt-out received |

**Common Use**: Track autopay enrollment and opt-out patterns

### Funding Process

| Status | MIN_TS | MAX_TS | CNT | Description |
|--------|--------|--------|-----|-------------|
| `PRE_FUNDING` | ✓ | ✓ | ✓ | Pre-funding checks |
| `PENDING_FUNDING` | ✓ | ✓ | ✓ | Awaiting funding |
| `FUNDED` | ✓ | ✓ | ✓ | Loan funded |
| `ORIGINATED` | ✓ | ✓ | ✓ | Loan originated |
| `OPEN_REPAYING` | ✓ | ✓ | ✓ | Loan opened and in repayment |

**Common Use**: Calculate time to funding and origination rates

## Common Join Patterns

### Join with Application Data
```sql
SELECT
    a.GUID,
    a.LOAN_ID,
    s.STARTED_MIN_TS,
    s.APPLIED_MIN_TS,
    s.APPROVED_MIN_TS,
    s.FUNDED_MIN_TS
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION a
LEFT JOIN ANALYTICS.VW_APP_STATUS_TRANSITION s
    ON a.GUID = s.GUID
```

### Join with PII Data
```sql
SELECT
    s.GUID,
    p.EMAIL,
    p.FIRST_NAME,
    p.LAST_NAME,
    s.STARTED_MIN_TS,
    s.FUNDED_MIN_TS
FROM ANALYTICS.VW_APP_STATUS_TRANSITION s
LEFT JOIN ANALYTICS_PII.VW_APP_PII p
    ON s.GUID = p.GUID
```

## Common Use Cases

### 1. Application Funnel Analysis
```sql
SELECT
    COUNT(DISTINCT CASE WHEN STARTED_CNT > 0 THEN GUID END) as started,
    COUNT(DISTINCT CASE WHEN APPLIED_CNT > 0 THEN GUID END) as applied,
    COUNT(DISTINCT CASE WHEN APPROVED_CNT > 0 THEN GUID END) as approved,
    COUNT(DISTINCT CASE WHEN FUNDED_CNT > 0 THEN GUID END) as funded
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
```

### 2. Time to Approval
```sql
SELECT
    GUID,
    DATEDIFF('hour', STARTED_MIN_TS, APPROVED_MIN_TS) as hours_to_approval
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
WHERE APPROVED_MIN_TS IS NOT NULL
    AND STARTED_MIN_TS IS NOT NULL
```

### 3. Identify Applications with Multiple Underwriting Attempts
```sql
SELECT
    GUID,
    UNDERWRITING_CNT,
    UNDERWRITING_MIN_TS,
    UNDERWRITING_MAX_TS
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
WHERE UNDERWRITING_CNT > 1
ORDER BY UNDERWRITING_CNT DESC
```

### 4. Daily Application Volume by Entry Point
```sql
SELECT
    DATE(STARTED_MIN_TS) as application_date,
    COUNT(DISTINCT CASE WHEN AFFILIATE_STARTED_CNT > 0 THEN GUID END) as affiliate_apps,
    COUNT(DISTINCT CASE WHEN AFFILIATE_STARTED_CNT = 0 OR AFFILIATE_STARTED_CNT IS NULL THEN GUID END) as direct_apps
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
WHERE STARTED_MIN_TS >= CURRENT_DATE - 30
GROUP BY 1
ORDER BY 1 DESC
```

### 5. Average Processing Times
```sql
SELECT
    AVG(DATEDIFF('minute', STARTED_MIN_TS, APPLIED_MIN_TS)) as avg_start_to_apply_mins,
    AVG(DATEDIFF('minute', APPLIED_MIN_TS, APPROVED_MIN_TS)) as avg_apply_to_approve_mins,
    AVG(DATEDIFF('minute', APPROVED_MIN_TS, FUNDED_MIN_TS)) as avg_approve_to_fund_mins
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
WHERE STARTED_MIN_TS >= CURRENT_DATE - 30
    AND FUNDED_MIN_TS IS NOT NULL
```

### 6. Fraud Detection Rate
```sql
SELECT
    DATE(STARTED_MIN_TS) as application_date,
    COUNT(DISTINCT GUID) as total_apps,
    COUNT(DISTINCT CASE WHEN FRAUD_REJECTED_CNT > 0 THEN GUID END) as fraud_rejected,
    DIV0(COUNT(DISTINCT CASE WHEN FRAUD_REJECTED_CNT > 0 THEN GUID END),
         COUNT(DISTINCT GUID)) * 100 as fraud_rejection_rate_pct
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
WHERE STARTED_MIN_TS >= CURRENT_DATE - 30
GROUP BY 1
ORDER BY 1 DESC
```

### 7. DCP and Autopay Adoption
```sql
SELECT
    DATE(FUNDED_MIN_TS) as funding_date,
    COUNT(DISTINCT GUID) as funded_apps,
    COUNT(DISTINCT CASE WHEN DCP_OPT_IN_CNT > 0 THEN GUID END) as dcp_opted_in,
    COUNT(DISTINCT CASE WHEN AUTOPAY_DATA_SUBMITTED_CNT > 0 THEN GUID END) as autopay_submitted
FROM ANALYTICS.VW_APP_STATUS_TRANSITION
WHERE FUNDED_MIN_TS >= CURRENT_DATE - 30
GROUP BY 1
ORDER BY 1 DESC
```

## Best Practices

### Understanding MIN vs MAX Timestamps
- **MIN_TS**: First occurrence - use for initial timing analysis
- **MAX_TS**: Most recent occurrence - use to identify status revisits
- **CNT**: Number of occurrences - use to find unusual patterns (CNT > 1)

### Filtering Recommendations
- Always filter on relevant timestamp fields for performance
- Use `STARTED_MIN_TS` for date range filtering on all applications
- Use specific status timestamps for filtered analysis (e.g., `FUNDED_MIN_TS` for funded loans)

### NULL Handling
- All timestamp and count fields are nullable
- NULL means the application never entered that status
- Use `IS NOT NULL` to filter for applications that reached a specific status
- Use `CASE WHEN` for conditional counts to handle NULLs properly

### Performance Tips
- Select only the status fields you need (view has 150+ columns)
- Add date filters on relevant timestamp fields
- Index joins on GUID for optimal performance
- Consider using `COUNT(DISTINCT CASE WHEN...)` instead of multiple queries

## Important Notes

⚠️ **Status Counts**: A CNT > 1 indicates an application revisited that status multiple times, which may indicate:
- Resubmissions after corrections
- System retries
- Process loops
- Application amendments

⚠️ **Timing Analysis**: When calculating time differences:
- Use MIN_TS fields for typical "time to X" metrics
- Check CNT fields to identify outliers with multiple status visits
- NULL timestamps indicate status was never reached

⚠️ **Data Freshness**: This view reflects status transitions as recorded in the LOS system. Recent transitions may have slight delays depending on data pipeline refresh schedules.

## Related Views

- [VW_APP_LOAN_PRODUCTION](VW_APP_LOAN_PRODUCTION.md) - Current application/loan data
- [VW_APP_PII](VW_APP_PII.md) - Customer PII information
- [VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT](VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT.md) - Detailed application settings

## Questions?

For questions about this view or data discrepancies, contact the Data Intelligence team or reference the internal data dictionary.