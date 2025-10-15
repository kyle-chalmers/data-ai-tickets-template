# VW_APP_LOAN_PRODUCTION

**Database**: `BUSINESS_INTELLIGENCE.ANALYTICS`
**Type**: View
**Purpose**: Standardized application production data
**Replaces**: Legacy `VW_APPLICATION` view

---

## Overview

`VW_APP_LOAN_PRODUCTION` is the standardized view for application data in the production environment. It contains application-level information including application dates, customer identifiers, marketing attribution, offer details, and origination status.

### Key Features
- ✅ **Production Applications Only**: Pre-filtered for production data
- ✅ **Application-Centric**: Focus on application lifecycle and decisions
- ✅ **Join-Ready**: Uses `GUID` as primary key for cross-table joins
- ✅ **Marketing-Friendly**: Rich UTM and channel attribution fields

---

## Schema Information

**Last Updated**: October 9, 2025
**Source**: Verified via `INFORMATION_SCHEMA.COLUMNS` query
**Total Columns**: 70+

### Primary Keys & Identifiers

| Field | Type | Description | Usage |
|-------|------|-------------|-------|
| **APP_ID** | PK | Application identifier | Application-level joins |
| **GUID** | FK | Cross-system identifier (same as LEAD_GUID) | **Primary join key - use for all joins** |
| **LOAN_ID** | FK | ⚠️ **Application ID in LOS** (NULL if not originated) | **NOT the loan ID in LMS - see note below** |
| PAYOFF_LOAN_ID | String | User-friendly loan ID (NULL if not originated) | Display purposes |
| CUSTOMER_ID | FK | Customer identifier | Customer-level analysis |

#### ⚠️ Important: LOAN_ID Field

**`LOAN_ID` in VW_APP_LOAN_PRODUCTION is the APPLICATION_ID from LOS (Loan Origination System), NOT the loan ID in LMS (Loan Management System).**

- To get the actual LMS loan ID, join to `VW_LOAN` using `GUID = LEAD_GUID`

**Example:**
```sql
-- WRONG: Don't use LOAN_ID directly for loan joins
SELECT * FROM VW_APP_LOAN_PRODUCTION app
JOIN VW_LOAN loan ON app.LOAN_ID = loan.LOAN_ID  -- ❌ WRONG!

-- CORRECT: Use GUID to join to actual loans
SELECT * FROM VW_APP_LOAN_PRODUCTION app
JOIN VW_LOAN loan ON app.GUID = loan.LEAD_GUID  -- ✅ CORRECT!
```

---

## Field Reference

### 📋 Customer Information

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| SSN | String | Social security number | PII - use with caution |
| EMAIL | String | Email address | May be NULL |
| CUST_ADDR_ST | String | Customer address state | |
| BUREAU_ST | String | Bureau state | |

### 📅 Application Dates & Timestamps

| Field | Type | Description | Business Logic |
|-------|------|-------------|----------------|
| **APP_DT** | Date | Application date | **Primary date field for filtering** |
| APP_TS | Timestamp | Application timestamp | Exact submission time |
| AFFILIATE_LANDED_TS | Timestamp | Affiliate landing page visit | Funnel tracking |
| APPLIED_TS | Timestamp | Application submitted | Funnel tracking |
| OFFER_SHOWN_TS | Timestamp | Offer displayed to customer | Decision point |
| OFFER_SELECTED_TS | Timestamp | Customer accepted offer | Conversion point |
| SSN_ENTERED_TS | Timestamp | SSN entry time | Identity verification step |
| DOC_UPLOAD_TS | Timestamp | Document upload time | Verification step |
| UW_STARTED_TS | Timestamp | Underwriting start | Processing |
| UW_AGENT_ASSIGNED_TS | Timestamp | Agent assignment | Manual review |
| UW_COMPLETE_TS | Timestamp | Underwriting complete | Decision time |
| ESIGN_TS | Timestamp | E-signature completed | Contract signed |
| ORIGINATED_TS | Timestamp | Loan originated (funded) | Funding timestamp (NULL if declined) |
| ORIGINATED_DT | Date | Origination date | Funding date (NULL if declined) |
| WITHDRAWN_TS | Timestamp | Application withdrawn | Terminal status |
| DECLINED_TS | Timestamp | Application declined | Terminal status |
| EXPIRED_TS | Timestamp | Application expired | Terminal status |

### 🎯 Marketing Attribution

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| UTM_SOURCE | String | Traffic source | e.g., 'google', 'facebook' |
| UTM_MEDIUM | String | Marketing medium | e.g., 'cpc', 'email', 'dm' |
| UTM_CONTENT | String | Ad content | A/B test tracking |
| UTM_TERM | String | Search term | Paid search keywords |
| UTM_CAMPAIGN | String | Campaign identifier | Campaign tracking |
| **APP_CHANNEL** | String | Channel grouping | **Primary channel field**(last_touch_attribution_grouping) |
| APP_CHANNEL_PARENT | String | Parent channel | Channel hierarchy |
| DM_INVITATION_CD | String | Direct mail offer code | Single offer code |
| DM_INVITATION_CD_MULTI | String | Multiple offer codes | Comma-separated |
| DM_UTM_CAMPAIGN_MULTI | String | Multiple campaigns | Comma-separated |
| DM_MATCH_CONFIDENCE_LVL | String | Match confidence | Data quality indicator |
| DM_MULTI_DUPE_YN | Boolean | Duplicate flag | Y/N |

### 💰 Offer Amounts & Terms

| Field | Type | Description | Business Logic |
|-------|------|-------------|----------------|
| REQUESTED_LOAN_AMT | Number | Customer requested amount | Initial request |
| MAX_OFFER_AMT | Number | Maximum approved amount | Decision engine output |
| **SELECTED_OFFER_AMT** | Number | Customer selected amount | **Actual offer accepted** |
| LOAN_AMT | Number | Final loan amount (if originated) | NULL if not funded |
| ORIG_FEE_AMT | Number | Origination fee amount | Dollar amount |
| ORIG_FEE_PRCT | Number | Origination fee percentage | Percentage |
| PREM_FEE_AMT | Number | Premium fee amount | Dollar amount |
| PREM_FEE_PRCT | Number | Premium fee percentage | Percentage |
| **TERM** | Number | Loan term in months | Offered/selected term |
| **APR_PRCT** | Number | Annual Percentage Rate | Offered/selected APR |
| **INT_RATE_PRCT** | Number | Interest rate percentage | Offered/selected interest rate |
| MONTHLY_PAYMENT_AMT | Number | Monthly payment amount | Payment calculation |

### 🔍 Credit & Risk

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| CREDIT_SCORE | Number | Credit bureau score | FICO score |
| TIER | String | Risk tier | Pricing tier |
| CP_VERSION | String | Credit policy version | Underwriting rules version |

### ⚙️ Application Processing

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| FUNNEL_TYPE | String | Application funnel | |
| API_PARTNER_DECISION | String | Partner decision | |
| LOAN_PURPOSE | String | Stated loan purpose | e.g., 'debt consolidation' |
| SELECTED_OFFER_ID | String | Offer identifier | Links to offer details |
| **APP_STATUS** | String | Current application status | **e.g., 'Originated', 'Declined', 'Withdrawn'** |
| AGENT_ID | String | Assigned agent | For manual reviews |
| SOURCE_COMPANY | String | Originating company | Business entity |
| CAPITAL_PARTNER | String | Capital partner | Funding source |
| GUID_DUPE_YN | Boolean | Duplicate GUID flag | Y/N data quality check |

### 🛡️ Fraud & Verification Checks

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| AUTOMATION_IDENTITY_CHECK_STATUS | String | Identity verification | Pass/Fail/Manual |
| AUTOMATION_BANK_ACCOUNT_CHECK_STATUS | String | Bank account verification | Pass/Fail/Manual |
| AUTOMATION_INCOME_CHECK_STATUS | String | Income verification | Pass/Fail/Manual |
| INTERNAL_AUTO_INCOME_CHECK_STATUS | String | Internal income check | Pass/Fail |
| DYNAMIC_VERIF_PASS_YN | Boolean | Dynamic verification passed | Y/N |
| INTERNAL_DYNAMIC_VERIF_PASS_YN | Boolean | Internal dynamic verification | Y/N |
| AUTOMATED_FRAUD_DECLINE_YN | Boolean | Auto fraud decline | Y/N |
| MANUAL_FRAUD_REVIEW_YN | Boolean | Manual fraud review required | Y/N |
| MANUAL_FRAUD_DECLINE_YN | Boolean | Manual fraud decline | Y/N |

### 📊 Offer Management

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| COUNTER_OFF_YN | Boolean | Counter offer made | Y/N |

---

## Common Join Patterns

### Standard Application Query
```sql
-- Basic application query
SELECT
    app.GUID,
    app.APP_DT,
    app.APP_CHANNEL,
    app.APP_STATUS,
    app.SELECTED_OFFER_AMT,
    app.TERM,
    app.APR_PRCT
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION app
WHERE app.APP_DT >= '2023-01-01'
```

### Filter Originated Applications Only
```sql
-- Applications that became loans
SELECT
    app.GUID,
    app.APP_DT,
    app.ORIGINATED_DT,
    app.LOAN_ID  -- Note: This is APP_ID, not actual loan ID
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION app
WHERE app.LOAN_ID IS NOT NULL  -- Funded applications only
```

### Application + PII Data
```sql
-- Join with PII view
SELECT
    app.GUID,
    app.APP_DT,
    app.APP_STATUS,
    pii.FIRST_NAME,
    pii.LAST_NAME,
    pii.DATE_OF_BIRTH,
    COALESCE(pii.EMAIL, app.EMAIL) AS email
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION app
LEFT JOIN ANALYTICS_PII.VW_APP_PII pii
    ON app.GUID = pii.GUID
```

### Application + Custom Fields
```sql
-- Join with BRIDGE custom fields for additional data
SELECT
    app.GUID,
    app.APP_DT,
    app.SELECTED_OFFER_AMT,
    cls.TOTAL_ANNUAL_INCOME_LS,
    cls.FRAUD_STATUS,
    cls.APPLICATION_SUBMITTED_DATE
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION app
LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    ON app.GUID = cls.APPLICATION_GUID
```

### Application + Loan Data (For Originated Apps)
```sql
-- CORRECT way to join with loan table
SELECT
    app.GUID,
    app.APP_DT,
    app.ORIGINATED_DT,
    loan.LOAN_ID,  -- Actual LMS loan ID
    loan.ORIGINATION_DATE,
    loan.LOAN_AMOUNT,
    loan.LOAN_STATUS
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION app
INNER JOIN ANALYTICS.VW_LOAN loan
    ON app.GUID = loan.LEAD_GUID  -- Use GUID, not LOAN_ID!
```

---

## Related Views

| View | Purpose | Join Key |
|------|---------|----------|
| `ANALYTICS.VW_APP_STATUS_TRANSITION` | Application status history (46 statuses) | GUID |
| `ANALYTICS_PII.VW_APP_PII` | Application PII data | GUID |
| `ANALYTICS.VW_LOAN` | Loan data (for originated applications) | LEAD_GUID = GUID |
| `BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT` | Custom application fields | APPLICATION_GUID = GUID |
| `ANALYTICS.VW_DECISIONS_CURRENT` | Underwriting decisions | LEAD_GUID = GUID |

---

## Usage Examples

### Example 1: Application Volume by Channel
```sql
-- Analyze application volume by marketing channel
SELECT
    APP_CHANNEL,
    DATE_TRUNC('month', APP_DT) as month,
    COUNT(*) as total_applications,
    COUNT(CASE WHEN LOAN_ID IS NOT NULL THEN 1 END) as funded_applications,
    COUNT(CASE WHEN LOAN_ID IS NOT NULL THEN 1 END)::FLOAT / COUNT(*) as funding_rate
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION
WHERE APP_DT >= '2024-01-01'
GROUP BY APP_CHANNEL, month
ORDER BY month DESC, total_applications DESC
```

### Example 2: Application Funnel Timing
```sql
-- Analyze time between application steps
SELECT
    GUID,
    APP_DT,
    DATEDIFF('hour', APP_TS, OFFER_SHOWN_TS) as hours_to_offer,
    DATEDIFF('hour', OFFER_SHOWN_TS, OFFER_SELECTED_TS) as hours_to_selection,
    DATEDIFF('hour', OFFER_SELECTED_TS, ESIGN_TS) as hours_to_esign,
    DATEDIFF('hour', ESIGN_TS, ORIGINATED_TS) as hours_to_funding,
    APP_STATUS
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION
WHERE APP_DT >= '2024-01-01'
    AND ORIGINATED_DT IS NOT NULL
```

### Example 3: Applications Requiring Manual Review
```sql
-- Find applications flagged for manual fraud review
SELECT
    GUID,
    APP_DT,
    APP_CHANNEL,
    APP_STATUS,
    MANUAL_FRAUD_REVIEW_YN,
    AUTOMATED_FRAUD_DECLINE_YN,
    AUTOMATION_IDENTITY_CHECK_STATUS,
    AUTOMATION_BANK_ACCOUNT_CHECK_STATUS,
    AUTOMATION_INCOME_CHECK_STATUS
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION
WHERE MANUAL_FRAUD_REVIEW_YN = 'Y'
    AND APP_DT >= CURRENT_DATE - 30
ORDER BY APP_DT DESC
```

---

## Data Quality Notes

### Known Issues
- ⚠️ `LOAN_ID` is **NOT** the actual LMS loan ID - it's the application ID (see warning above)
- ⚠️ `LOAN_ID`, `ORIGINATED_DT`, `LOAN_AMT` are NULL for non-originated applications
- ⚠️ Timestamps may be in different timezones - normalize when comparing

### Best Practices
1. ✅ **Always use `GUID` for joins** (most reliable identifier)
2. ✅ **Never join on `LOAN_ID`** - use `GUID = LEAD_GUID` instead
3. ✅ **Check `LOAN_ID IS NOT NULL`** to filter originated applications
4. ✅ **Use `APP_DT` for date filtering** (primary business date)
5. ✅ **Use aliases when migrating** to maintain backward compatibility
6. ✅ **Test field name changes** especially for offer-related fields (TERM, APR_PRCT, INT_RATE_PRCT)

---

**Last Verified**: October 9, 2025
**Verification Method**: Direct schema query + production job analysis
**Maintainer**: Data Intelligence Team