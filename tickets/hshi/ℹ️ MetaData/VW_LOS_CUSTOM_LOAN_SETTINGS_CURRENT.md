# VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT

**Database**: `BUSINESS_INTELLIGENCE.BRIDGE`
**Mirror**: `ARCA.FRESHSNOW.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT`
**Type**: View
**Purpose**: Application custom fields from LoanPro LOS (Loan Origination System)
**Schema Filter**: ✅ **No schema filter needed** - LOS-specific view

---

## Overview

`VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT` is a massive custom fields table containing **700+ columns** of application-level data from the LoanPro Loan Origination System (LOS). It stores detailed information about the application process, including dates, verification results, income data, bank accounts, fraud checks, and much more.

### Key Features
- ✅ **Application-Level Only**: Contains data for applications (not originated loans)
- ✅ **No Schema Filtering Required**: Pre-filtered to LOS schema
- ✅ **Rich Custom Fields**: Extensive custom data not in standard views
- ✅ **Join-Ready**: Uses `APPLICATION_GUID` to join with other application tables

### Important Notes
- ⚠️ **Large Table**: 700+ columns - select only fields you need
- ⚠️ **Application Data Only**: Does not contain loan servicing data
- ⚠️ **PII Warning**: Contains sensitive customer information
- ⚠️ **Many deprecated/DNU fields**: Look for "DNU" (Do Not Use) in field names

---

## Schema Information

**Last Updated**: October 9, 2025
**Source**: Verified via `INFORMATION_SCHEMA.COLUMNS` query
**Total Columns**: 700+

### Primary Keys & Identifiers

| Field | Type | Description | Usage |
|-------|------|-------------|-------|
| **LOAN_ID** | PK | Application ID in LOS | ⚠️ Same as APPLICATION_ID |
| **APPLICATION_GUID** | FK | Cross-system identifier | **Primary join key (= LEAD_GUID)** |
| APPLICATION_ID | FK | Application identifier | Same as LOAN_ID |
| SETTINGS_ID | Number | Settings record ID | Internal ID |
| LEAD_GUID | String | Same as APPLICATION_GUID | Duplicate identifier |
| TRANSACTION_ID | String | Transaction identifier | Payment processing |

---

## Commonly Used Fields

### 📅 Application Dates & Timeline

| Field | Type | Description | Business Logic |
|-------|------|-------------|----------------|
| **APPLICATION_STARTED_DATE** | Date | Application start date | Initial landing |
| **APPLICATION_SUBMITTED_DATE** | Date | Application submission date | **Key business date** |
| EXPIRATION_DATE | Date | Offer expiration | Deadline for acceptance |
| OFFER_SHOWN_TIMER | Timestamp | Offer display time | Funnel tracking |
| SELECTED_OFFER_DATE | Timestamp | Customer selected offer | Acceptance time |
| ESIGN_DATE | Timestamp | E-signature date | Contract signed |
| ORIGINATION_DATE | Timestamp | Loan funded date | NULL if not originated |
| APPLICATION_WITHDRAWN_DATE | Date | Withdrawal date | Terminal status |
| APPLICATION_APPROVED_DATE | Date | Approval date | Decision date |
| CREDIT_POLICY_EXECUTION_DATE | Timestamp | Credit policy run date | Underwriting |

### 💰 Loan Amount & Terms

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| **REQUESTED_LOAN_AMOUNT** | Number | Customer requested amount | Initial request |
| INITIAL_REQUESTED_LOAN_AMOUNT | Number | Very first request | May differ from final request |
| LOAN_AMOUNT | Number | Final loan amount | If originated |
| LOAN_AMOUNT_COUNTER_OFFER | Number | Counter offer amount | If applicable |
| TERM_MONTHS | Number | Loan term | In months |
| APR | Number | Annual percentage rate | |
| INTEREST_RATE | Number | Interest rate | |
| MONTHLY_PAYMENT | Number | Payment amount | |
| ORIGINATION_FEE | Number | Fee amount | |
| ORIGINATION_FEE__RATE | Number | Fee percentage | |
| PREMIUM_AMOUNT | Number | Premium fee amount | |
| PREMIUM_RATE | Number | Premium fee rate | |

### 👤 Customer Information

| Field | Type | Description | PII |
|-------|------|-------------|-----|
| FIRST_NAME | String | First name | ✅ PII |
| LAST_NAME | String | Last name | ✅ PII |
| EMAIL | String | Email address | ✅ PII |
| PHONE | String | Phone number | ✅ PII |
| DATE_OF_BIRTH | Date | Date of birth | ✅ PII |
| SOCIAL_SECURITY_NUMBER | String | SSN | ⚠️ **Highly sensitive PII** |
| HOME_ADDRESS_STREET1 | String | Street address line 1 | ✅ PII |
| HOME_ADDRESS_STREET2 | String | Street address line 2 | ✅ PII |
| HOME_ADDRESS_CITY | String | City | ✅ PII |
| HOME_ADDRESS_STATE | String | State | ✅ PII |
| HOME_ADDRESS_ZIP | String | ZIP code | ✅ PII |
| CITIZENSHIP_STATUS | String | Citizenship status | |

### 💵 Income Information

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| **TOTAL_ANNUAL_INCOME_LS** | Number | **Total annual income** | **Most commonly used** |
| TOTAL_STATED_INCOME | Number | Stated income | Customer-provided |
| BORROWER_STATED_ANNUAL_INCOME | Number | Stated annual income | Same as above |
| MONTHLY_HOUSING_PAYMENT_APP | Number | Monthly housing payment | |
| HOUSING_PAYMENT_TYPE_APP | String | Housing payment type | Rent/Mortgage/Own |
| MODEL_VERIFIED_ANNUAL_INCOME | Number | Model-verified income | Automated verification |
| TRUV_VERIFIED_ANNUAL_INCOME | Number | TruV-verified income | Third-party verification |
| OTHER_VERIFIED_ANNUAL_INCOME | Number | Other verified income | Alternative verification |

### Income Detail Fields (up to 10 income sources)
- `ANNUAL_INCOME_1` through `ANNUAL_INCOME_5` - Income amounts
- `INCOME_TYPE_1` through `INCOME_TYPE_5` - Income types
- `EMPLOYER_NAME_1` through `EMPLOYER_NAME_5` - Employer names
- `GROSS_INCOME_AMOUNT_1` through `GROSS_INCOME_AMOUNT_10` - Gross income
- `NET_INCOME_AMOUNT_1` through `NET_INCOME_AMOUNT_10` - Net income
- `GROSS_INCOME_FREQUENCY_1` through `GROSS_INCOME_FREQUENCY_10` - Pay frequency

### 🏦 Bank Account Information

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| ROUTING_NUMBER | String | Bank routing number | Primary account |
| ACCOUNT_NUMBER | String | Bank account number | ⚠️ Sensitive PII |
| BANK_ACCOUNT_TYPE | String | Account type | Checking/Savings |
| INSTITUTION_NAME | String | Bank name | |
| BANK_LINK_SOURCE | String | How account was linked | Plaid/Manual/etc |
| BANK_LINK_DATE | Date | Account link date | |
| ACCOUNT_BALANCE | Number | Account balance | At time of link |
| ACCOUNT_START_DATE | Date | Account open date | |

### Bank Account Verification (5 bank accounts supported)
Each bank account (1-5) has these fields:
- `BANK_1_ID` through `BANK_5_ID` - Bank IDs
- `BANK_1_TYPE` through `BANK_5_TYPE` - Account types
- `BANK_1_GIACT_STATUS` through `BANK_5_GIACT_STATUS` - GIACT verification
- `BANK_1_PLAID_CHECK_STATUS` through `BANK_5_PLAID_CHECK_STATUS` - Plaid verification
- Plus detailed status fields for ownership, balance, history, etc.

### 🔍 Verification & Fraud

| Field | Type | Description | Values |
|-------|------|-------------|--------|
| **FRAUD_STATUS** | String | Fraud investigation status | Under Review/Confirmed/Clear |
| **FRAUD_REASON** | String | Fraud reason/type | Fraud category |
| FRAUD_TYPE | String | Type of fraud | Specific fraud type |
| FRAUD_CASE_ID | String | Case identifier | For tracking |
| **AUTOMATION_IDENTITY_CHECK_STATUS** | String | Identity verification | Pass/Fail/Manual |
| **AUTOMATION_BANK_ACCOUNT_CHECK_STATUS** | String | Bank verification | Pass/Fail/Manual |
| **AUTOMATION_INCOME_CHECK_STATUS** | String | Income verification | Pass/Fail/Manual |
| VERIFICATION_STATUS | String | Overall verification | |
| INCOME_VERIFICATION_RESULT | String | Income check result | |
| BANK_ACCOUNT_VERIFICATION_RESULT | String | Bank check result | |
| IDENTITY_VERIFICATION_RESULT | String | Identity check result | |
| DATAVISOR_FRAUD_RESULT | String | DataVisor score | Fraud detection |
| KOUNT_RESULT | String | Kount fraud score | Third-party fraud |
| OFAC_RESULT | String | OFAC check result | Sanctions screening |
| OFAC_STATUS | String | OFAC status | Pass/Fail |
| MLA_FLAG | String | Military Lending Act flag | Y/N |

### 📊 Credit & Underwriting

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| CREDIT_SCORE | Number | FICO score | Bureau score |
| CREDIT_POLICY_VERSION | String | Policy version | Underwriting rules |
| TIER | String | Risk tier | Pricing tier |
| DTI | Number | Debt-to-income ratio | Percentage |
| OFFER_DECISION_STATUS | String | Decision status | Approve/Decline |
| SELECTED_OFFER_ID | String | Offer ID selected | Specific offer |
| ADVERSE_ACTION_NAME | String | Adverse action | Decline reason |
| ADVERSE_ACTION_REASON | String | Specific reason | Details |
| CONSUMER_STATEMENT | String | Consumer statement | Credit bureau |
| FROZEN_INDICATOR | Boolean | Credit frozen | True/False |
| NO_HIT_INDICATOR | Boolean | No credit file | True/False |

### Credit Policy Fields
- `CREDIT_POLICY_FEDERAL_TAX_PAYMENT` - Tax liens
- `CREDIT_POLICY_STATE_TAX_PAYMENT` - State tax liens
- `CREDIT_POLICY_TRADELINE_REVOLVING_BALANCE` - Revolving debt
- `CREDIT_POLICY_HAPPY_SCORE` - Internal score
- `CREDIT_POLICY_DEDUPED_INQ_6_MO` - Recent inquiries
- Plus 10+ more credit policy fields

### 🎯 Marketing Attribution

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| UTM_SOURCE | String | Traffic source | |
| UTM_MEDIUM | String | Marketing medium | |
| UTM_CAMPAIGN | String | Campaign identifier | |
| UTM_TERM | String | Search term | |
| UTM_CONTENT | String | Ad content | |
| DM_INVITATION_CODE | String | Direct mail code | Offer code |
| DM_GUID | String | Direct mail GUID | Tracking |
| ATTR_CAMPAIGN | String | Attribution campaign | |
| ATTR_IP | String | IP address | |
| ATTR_SEGMENT | String | Customer segment | |

### 💳 Direct Credit Payment (DCP)

Up to 5 DCP attempts supported with these fields for each (1-5):
- `DCP1_ENABLED` through `DCP5_ENABLED` - DCP enabled flag
- `DCP1_TRANSACTIONID` through `DCP5_TRANSACTIONID` - Transaction IDs
- `DCP1_BANKNAME` through `DCP5_BANKNAME` - Bank names
- `DCP1_CARDNUMBER` through `DCP5_CARDNUMBER` - Card numbers
- `DCP1_REQUESTEDAMOUNT` through `DCP5_REQUESTEDAMOUNT` - Amounts
- `DCP1_STATUS` through `DCP5_STATUS` - Payment status
- `DCP1_LASTMODIFIEDDATE` through `DCP5_LASTMODIFIEDDATE` - Last modified

### 💰 Debt Payoff Information

Up to 20 creditors supported:
- `DEBT_CREDITOR_1` through `DEBT_CREDITOR_20` - Creditor names
- `DEBT_CREDITOR_1_PAYOFF_AMOUNT` through `DEBT_CREDITOR_20_PAYOFF_AMOUNT` - Payoff amounts
- `DEBT_CREDITOR_1_OPT_IN` through `DEBT_CREDITOR_20_OPT_IN` - DCP opt-in flags

### 📧 Contact Preferences

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| **EMAIL_MARKETING_CONSENT_LS** | String | Email marketing consent | YES/NO |
| EMAIL_MARKETING_CONSENT_DATE_LS | Date | Consent date | When opted in/out |
| **SMS_CONSENT_LS** | String | SMS consent | YES/NO |
| **SMS_CONSENT_DATE_LS** | Date | SMS consent date | When opted in/out |
| DISCLOSURE_CONSENT | Boolean | Disclosure consent | |
| DISCLOSURE_CONSENT_DATE | Date | Consent date | |

### ⚙️ Processing & Status

| Field | Type | Description | Notes |
|-------|------|-------------|-------|
| OFFER_DECISION_TIMER | Timestamp | Decision timer | Processing time |
| OFFER_SHOWN | Boolean | Offer shown flag | |
| UNDERWRITING_TIMER | Timestamp | UW timer | |
| APPROVED_TIMER | Timestamp | Approval timer | |
| DOC_UPLOAD_TIMER | Timestamp | Doc upload timer | |
| CAPITAL_PARTNER | String | Capital partner | Funding source |
| CAPITAL_PARTNER_ALLOCATION_DATE | Date | Allocation date | |
| ALLOCATION_STATUS | String | Allocation status | |
| TRANSACTION_TIMESTAMP | Timestamp | Transaction time | |
| PRIMARY_STATUS_ID | Number | Primary status | |
| SUB_STATUS_ID | Number | Sub status | |

### 🔐 Third-Party Verifications

| Field | Type | Description | Service |
|-------|------|-------------|---------|
| TRUV_VERIFIED_ANNUAL_INCOME | Number | TruV income | Income verification |
| TRUV_INCOME_SOURCE | String | Income source | Employment type |
| TRUV_RUN_DATE | Date | Verification date | |
| TRUV_SUSPICIOUS_DOCUMENTS | String | Document flag | Y/N |
| TALX_EMPLOYER | String | TALX employer | The Work Number |
| TALX_SALARY | Number | TALX salary | Verified income |
| TALX_HIRE_DATE | Date | Hire date | Employment start |
| GIACT_CUSTOMER_RESPONSE_CODE | String | GIACT customer code | Bank verification |
| GIACT_ACCOUNT_RESPONSE_CODE | String | GIACT account code | Account verification |
| GIACT_RUN_DATE | Date | GIACT run date | |
| PLAID_ACCESS_TOKEN | String | Plaid token | ⚠️ Sensitive |
| OSCILAR_VERIFICATION_REQUEST_ID | String | Oscilar request | Verification ID |

---

## Common Join Patterns

### Join with VW_APP_LOAN_PRODUCTION
```sql
-- Get application + custom fields
SELECT
    app.GUID,
    app.APP_DT,
    app.SELECTED_OFFER_AMT,
    cls.TOTAL_ANNUAL_INCOME_LS,
    cls.APPLICATION_SUBMITTED_DATE,
    cls.FRAUD_STATUS,
    cls.SMS_CONSENT_LS
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION app
LEFT JOIN BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
    ON app.GUID = cls.APPLICATION_GUID
WHERE app.APP_DT >= '2024-01-01'
```

### Select Only Needed Fields (Performance)
```sql
-- ⚠️ Important: Only select fields you need from this 700+ column table
SELECT
    cls.APPLICATION_GUID,
    cls.TOTAL_ANNUAL_INCOME_LS,
    cls.APPLICATION_SUBMITTED_DATE,
    cls.FRAUD_STATUS,
    cls.UTM_CAMPAIGN,
    cls.UTM_MEDIUM,
    cls.UTM_SOURCE
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
WHERE cls.APPLICATION_SUBMITTED_DATE >= '2024-01-01'
```

### Get Fraud Investigation Data
```sql
-- Applications with fraud investigations
SELECT
    cls.APPLICATION_GUID,
    cls.APPLICATION_SUBMITTED_DATE,
    cls.FRAUD_STATUS,
    cls.FRAUD_REASON,
    cls.FRAUD_TYPE,
    cls.FRAUD_CASE_ID,
    cls.DATAVISOR_FRAUD_RESULT,
    cls.KOUNT_RESULT,
    cls.AUTOMATION_IDENTITY_CHECK_STATUS,
    cls.AUTOMATION_BANK_ACCOUNT_CHECK_STATUS
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
WHERE cls.FRAUD_STATUS IS NOT NULL
    AND cls.APPLICATION_SUBMITTED_DATE >= CURRENT_DATE - 90
```

### Get Contact Consent Status
```sql
-- Email and SMS consent for marketing
SELECT
    cls.APPLICATION_GUID,
    cls.EMAIL,
    cls.PHONE,
    cls.EMAIL_MARKETING_CONSENT_LS,
    cls.EMAIL_MARKETING_CONSENT_DATE_LS,
    cls.SMS_CONSENT_LS,
    cls.SMS_CONSENT_DATE_LS
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
WHERE cls.APPLICATION_SUBMITTED_DATE >= '2024-01-01'
```

---

## Field Categories

### ⚠️ Do Not Use (DNU) Fields
Many fields have "DNU" in the name - these should not be used:
- `DNU`, `DNU_12`, `DNU_FR`, `DNU123`, `DNU_SUFFIX`, `DNU_DOB`
- `DO_NOT_USE_123`
- `REPURPOSE_1`, `REPURPOSE_2`

### Bureau/Credit Fields
Fields starting with `BUREAU_*` contain credit bureau data:
- `BUREAU_SSN`, `BUREAU_DOB`, `BUREAU_FIRST_NAME`, `BUREAU_LAST_NAME`
- `BUREAU_ADDRESS`, `BUREAU_STATE`, `BUREAU_CITY`, `BUREAU_ZIP_CODE`
- `BUREAU_SSN_MATCH`, `BUREAU_DOB_MATCH` - Match flags

### Identity Match Fields
Fields starting with `IDENTITY_*` contain verification results:
- `IDENTITY_FIRST_NAME_MATCH`, `IDENTITY_LAST_NAME_MATCH`
- `IDENTITY_ADDRESS_MATCH`, `IDENTITY_DOB_MATCH`, `IDENTITY_SSN_MATCH`
- `IDENTITY_CITIZENSHIP`, `IDENTITY_CREDIT_FREEZE`, `IDENTITY_OFAC`

### Affiliate Fields
Fields starting with `AFF_*` contain affiliate data:
- `AFF_TRACKING_NUMBER`, `AFF_PARTNER_NAME`, `AFF_PARTNER_ID`
- `AFF_POSTED_DATETIME`, `AFF_SSN`, `AFF_CREDIT_SCORE_BRACKET`

---

## Related Views

| View | Purpose | Join Key |
|------|---------|----------|
| `ANALYTICS.VW_APP_LOAN_PRODUCTION` | Application production data | APPLICATION_GUID = GUID |
| `ANALYTICS_PII.VW_APP_PII` | Application PII | APPLICATION_GUID = GUID |
| `ANALYTICS.VW_APP_STATUS_TRANSITION` | Application status history | APPLICATION_GUID = GUID |
| `ANALYTICS.VW_APP_CONTACT_RULES` | Application contact suppressions | APPLICATION_GUID |

---

## Production Jobs Using This View

- **DI-1261_Weekly_Data_Feeds_for_DMS**: Uses `TOTAL_ANNUAL_INCOME_LS`
- **BI-2421_Prescreen_Marketing_Data**: Uses date and UTM fields
- **BI-2517_CRB_Monthly_Fraud_Report**: Uses fraud and verification fields
- **DI-948_NCUA_ACU_Monthly**: Regulatory reporting
- **BI-737_GR_Call_List**: Collections call lists

---

## Best Practices

### Performance
1. ✅ **Select only needed fields** - This is a 700+ column table
2. ✅ **Filter on indexed fields** - `APPLICATION_GUID`, `APPLICATION_SUBMITTED_DATE`
3. ✅ **Avoid `SELECT *`** - Always specify columns

### Data Quality
1. ⚠️ **Many NULL values** - Not all fields populated for all applications
2. ⚠️ **Deprecated fields** - Check for DNU in field names
3. ⚠️ **PII fields** - Use appropriate permissions and handle securely
4. ✅ **Join to VW_APP_LOAN_PRODUCTION** - For complete application picture

### Common Pitfalls
1. ❌ **Don't confuse LOAN_ID with actual loan ID** - This is APPLICATION_ID
2. ❌ **Don't use deprecated DNU fields** - They may contain incorrect data
3. ❌ **Don't assume all verification fields are populated** - Check for NULLs
4. ✅ **Use APPLICATION_GUID for joins** - Most reliable identifier

---

**Last Verified**: October 9, 2025
**Verification Method**: Direct schema query + production job analysis
**Total Fields**: 700+
**Maintainer**: Data Intelligence Team