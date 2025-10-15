# VW_APP_PII

**Schema**: ANALYTICS_PII
**Type**: View
**Purpose**: Customer Personally Identifiable Information (PII) for applications

⚠️ **CRITICAL: This view contains sensitive PII data. Access is restricted and requires proper permissions. Use only when absolutely necessary and handle with care.**

## Overview

`VW_APP_PII` contains personally identifiable information for loan applications. This view is separated from non-PII application data for security and compliance purposes. All queries using this view are logged and monitored.

**Security Requirements**:
- Access requires explicit PII permissions in Snowflake
- Only query PII fields when necessary for the business use case
- Never export PII data to unsecured locations
- Follow all data privacy and compliance policies

## Primary Keys and Identifiers

| Field | Type | Description |
|-------|------|-------------|
| `APP_ID` | NUMBER(38,0) | Application ID (legacy identifier) |
| `GUID` | TEXT | Global Unique Identifier - **primary join key** |

⚠️ **Join Key**: Always use `GUID` (not APP_ID) when joining with other application tables

## Personal Information Fields

### Name Information

| Field | Type | Description |
|-------|------|-------------|
| `FIRST_NAME` | TEXT | Customer's first name |
| `LAST_NAME` | TEXT | Customer's last name |

### Contact Information

| Field | Type | Description |
|-------|------|-------------|
| `PHONE_NBR` | TEXT | Customer's phone number |
| `EMAIL` | TEXT | Customer's email address |

**Common Use**: Customer communication and outreach campaigns

### Address Information

| Field | Type | Description |
|-------|------|-------------|
| `ADDRESS_1` | TEXT | Primary address line |
| `ADDRESS_2` | TEXT | Secondary address line (apt, suite, etc.) |
| `CITY` | TEXT | City |
| `STATE` | TEXT | State (2-letter code) |
| `ZIP_CODE` | TEXT | ZIP code |

**Common Use**: Geographic analysis, marketing campaigns, compliance reporting

### Identity Information

| Field | Type | Description |
|-------|------|-------------|
| `DATE_OF_BIRTH` | DATE | Customer's date of birth |
| `SSN` | TEXT | Social Security Number (full) |
| `SOCIAL_SEC_NBR` | TEXT(9) | Social Security Number (standardized format) |
| `BUREAU_SSN` | TEXT(9) | SSN used for credit bureau pulls |
| `AFF_SSN` | TEXT(9) | SSN from affiliate source |

⚠️ **SSN Fields**: Multiple SSN fields exist for different sources and purposes:
- `SSN`: Original SSN as entered
- `SOCIAL_SEC_NBR`: Standardized/validated SSN
- `BUREAU_SSN`: SSN used for credit pulls (may differ if customer corrected it)
- `AFF_SSN`: SSN from affiliate partners

**Best Practice**: Use `SOCIAL_SEC_NBR` for most analyses as it's the standardized version

## Metadata Fields

| Field | Type | Description |
|-------|------|-------------|
| `IS_APP_YN` | TEXT(1) | Flag indicating if this is an application ('Y'/'N') |
| `SOURCE` | TEXT(7) | Data source system |

## Common Join Patterns

### Join with Application Production Data
```sql
SELECT
    a.GUID,
    a.LOAN_ID,
    a.APPLICATION_DT,
    a.LOAN_AMNT,
    p.FIRST_NAME,
    p.LAST_NAME,
    p.EMAIL,
    p.PHONE_NBR,
    p.STATE,
    p.ZIP_CODE
FROM ANALYTICS.VW_APP_LOAN_PRODUCTION a
INNER JOIN ANALYTICS_PII.VW_APP_PII p
    ON a.GUID = p.GUID
WHERE a.APPLICATION_DT >= CURRENT_DATE - 30
```

### Join with Status Transitions
```sql
SELECT
    s.GUID,
    p.FIRST_NAME,
    p.LAST_NAME,
    p.EMAIL,
    s.STARTED_MIN_TS,
    s.APPROVED_MIN_TS,
    s.FUNDED_MIN_TS
FROM ANALYTICS.VW_APP_STATUS_TRANSITION s
INNER JOIN ANALYTICS_PII.VW_APP_PII p
    ON s.GUID = p.GUID
WHERE s.FUNDED_MIN_TS >= CURRENT_DATE - 7
```

### Join with Custom Loan Settings
```sql
SELECT
    cls.GUID,
    p.EMAIL,
    p.PHONE_NBR,
    cls.TOTAL_ANNUAL_INCOME_LS,
    cls.EMPLOYER_NAME_LS
FROM BRIDGE.VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT cls
INNER JOIN ANALYTICS_PII.VW_APP_PII p
    ON cls.GUID = p.GUID
WHERE cls.APPLICATION_DATE >= CURRENT_DATE - 30
```

## Common Use Cases

### 1. Customer Contact List for Marketing Campaign
```sql
SELECT
    p.GUID,
    p.FIRST_NAME,
    p.LAST_NAME,
    p.EMAIL,
    p.PHONE_NBR,
    a.LOAN_AMNT,
    a.APPLICATION_DT
FROM ANALYTICS_PII.VW_APP_PII p
INNER JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION a
    ON p.GUID = a.GUID
WHERE a.CURRENT_STATUS = 'APPROVED'
    AND a.APPLICATION_DT >= CURRENT_DATE - 7
```

### 2. Geographic Distribution Analysis
```sql
SELECT
    p.STATE,
    p.CITY,
    COUNT(DISTINCT p.GUID) as application_count,
    AVG(a.LOAN_AMNT) as avg_loan_amount
FROM ANALYTICS_PII.VW_APP_PII p
INNER JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION a
    ON p.GUID = a.GUID
WHERE a.APPLICATION_DT >= CURRENT_DATE - 90
GROUP BY p.STATE, p.CITY
ORDER BY application_count DESC
```

### 3. Age Distribution (DOB Analysis)
```sql
SELECT
    FLOOR(DATEDIFF('year', p.DATE_OF_BIRTH, CURRENT_DATE) / 10) * 10 as age_bucket,
    COUNT(DISTINCT p.GUID) as customer_count,
    AVG(a.LOAN_AMNT) as avg_loan_amount
FROM ANALYTICS_PII.VW_APP_PII p
INNER JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION a
    ON p.GUID = a.GUID
WHERE a.APPLICATION_DT >= CURRENT_DATE - 90
    AND p.DATE_OF_BIRTH IS NOT NULL
GROUP BY age_bucket
ORDER BY age_bucket
```

### 4. Duplicate Detection by SSN
```sql
SELECT
    p.SOCIAL_SEC_NBR,
    COUNT(DISTINCT p.GUID) as application_count,
    LISTAGG(DISTINCT p.GUID, ', ') as application_guids
FROM ANALYTICS_PII.VW_APP_PII p
WHERE p.SOCIAL_SEC_NBR IS NOT NULL
    AND p.IS_APP_YN = 'Y'
GROUP BY p.SOCIAL_SEC_NBR
HAVING COUNT(DISTINCT p.GUID) > 1
ORDER BY application_count DESC
```

### 5. Email Domain Analysis
```sql
SELECT
    SPLIT_PART(p.EMAIL, '@', 2) as email_domain,
    COUNT(DISTINCT p.GUID) as customer_count
FROM ANALYTICS_PII.VW_APP_PII p
INNER JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION a
    ON p.GUID = a.GUID
WHERE a.APPLICATION_DT >= CURRENT_DATE - 30
    AND p.EMAIL IS NOT NULL
GROUP BY email_domain
ORDER BY customer_count DESC
LIMIT 20
```

### 6. Data Completeness Check
```sql
SELECT
    COUNT(DISTINCT GUID) as total_records,
    COUNT(DISTINCT CASE WHEN FIRST_NAME IS NOT NULL THEN GUID END) as has_first_name,
    COUNT(DISTINCT CASE WHEN LAST_NAME IS NOT NULL THEN GUID END) as has_last_name,
    COUNT(DISTINCT CASE WHEN EMAIL IS NOT NULL THEN GUID END) as has_email,
    COUNT(DISTINCT CASE WHEN PHONE_NBR IS NOT NULL THEN GUID END) as has_phone,
    COUNT(DISTINCT CASE WHEN ADDRESS_1 IS NOT NULL THEN GUID END) as has_address,
    COUNT(DISTINCT CASE WHEN DATE_OF_BIRTH IS NOT NULL THEN GUID END) as has_dob,
    COUNT(DISTINCT CASE WHEN SOCIAL_SEC_NBR IS NOT NULL THEN GUID END) as has_ssn
FROM ANALYTICS_PII.VW_APP_PII
WHERE IS_APP_YN = 'Y'
```

## Best Practices

### Security and Compliance

1. **Minimize PII Exposure**
   - Only SELECT PII fields when absolutely necessary
   - Use aggregations when possible instead of individual records
   - Never use `SELECT *` on this table

2. **Secure Data Handling**
   - Never export PII to local files or unsecured locations
   - Limit result sets when querying individual customer records
   - Use role-based access controls

3. **Audit Trail**
   - All queries against this view are logged
   - Document business justification for PII access
   - Follow data retention policies

### Query Performance

1. **Always Filter First**
   ```sql
   -- GOOD: Filter non-PII table first
   SELECT p.EMAIL, a.LOAN_AMNT
   FROM ANALYTICS.VW_APP_LOAN_PRODUCTION a
   INNER JOIN ANALYTICS_PII.VW_APP_PII p ON a.GUID = p.GUID
   WHERE a.APPLICATION_DT >= CURRENT_DATE - 7  -- Filter first

   -- AVOID: Scanning entire PII table
   SELECT p.EMAIL, a.LOAN_AMNT
   FROM ANALYTICS_PII.VW_APP_PII p
   INNER JOIN ANALYTICS.VW_APP_LOAN_PRODUCTION a ON p.GUID = a.GUID
   ```

2. **Use INNER JOIN for Existing Applications**
   - Use `INNER JOIN` when you need PII for known applications
   - Use `LEFT JOIN` only when checking for missing PII data

3. **Limit Result Sets**
   - Add `LIMIT` clause when testing queries
   - Use date filters to reduce data volume

### Data Quality Notes

- **Email Validation**: EMAIL field may contain invalid or outdated addresses
- **Phone Number Format**: PHONE_NBR may have varying formats (consider standardization)
- **Address Completeness**: ADDRESS_2 is often NULL (not all customers have apt/suite)
- **SSN Consistency**: Always use SOCIAL_SEC_NBR for standardized SSN
- **NULL Handling**: All fields are nullable - handle appropriately in logic

## Field Usage in Production Jobs

This view is commonly used in:

- **DI-1261**: DMS Vendor Data Feed (email, phone, name, address)
- **BI-2421**: Prescreen Marketing Data (email for customer outreach)
- Various customer communication and outreach campaigns
- Compliance and regulatory reporting
- Fraud detection and duplicate account analysis

## Related Views

- [VW_APP_LOAN_PRODUCTION](VW_APP_LOAN_PRODUCTION.md) - Non-PII application/loan data
- [VW_APP_STATUS_TRANSITION](VW_APP_STATUS_TRANSITION.md) - Application status history
- [VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT](VW_LOS_CUSTOM_LOAN_SETTINGS_CURRENT.md) - Additional application details

## Important Warnings

⚠️ **PII Compliance**: This view contains highly sensitive customer data. Unauthorized access or misuse may result in:
- Regulatory penalties
- Customer privacy violations
- Immediate access revocation
- Disciplinary action

⚠️ **Data Export**: Never export PII data to:
- Personal computers
- Unsecured cloud storage
- Email attachments
- Unencrypted files

⚠️ **Multiple SSN Fields**: Be aware of which SSN field you're using:
- Use `SOCIAL_SEC_NBR` for most analyses (standardized)
- Use `BUREAU_SSN` when analyzing credit bureau pulls
- Other SSN fields are for specific use cases

## Questions?

For questions about PII access, permissions, or data privacy policies, contact:
- Data Intelligence team for technical questions
- Legal/Compliance team for policy questions
- IT Security for access issues