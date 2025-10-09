# DI-1261: Field Mapping Analysis

## Application Data Fields

Reference for column mapping between legacy and new views.

### Customer PII
- PAYOFFUID (GUID)
- FIRST_NAME
- MIDDLE_NAME
- LAST_NAME
- ADDRESS
- ADDRESS_2
- CITY
- STATE
- POSTAL_CODE
- COUNTRY
- EMAIL
- PHONE_NUMBER
- SSN
- DOB (BIRTH_DATE)

### Application Attributes
- APP_CHANNEL
- UTM_SOURCE
- UTM_MEDIUM
- UTM_CAMPAIGN
- UTM_CONTENT
- CREATED_DATE (APP_CREATED_TS)

### Status Information
- LAST_STATUS (from status_name)
- LAST_STATUS_DATE (from status_timestamp)

## Suppression Data Fields

### Suppression Record
- PAYOFFUID
- suppression_type
- updated_date

### Suppression Types
1. `declined_in_the_past_20_days_loanpro`
2. `declined_in_the_past_20_days_cls`
3. `app_submitted_in_the_past_20_days`
4. `tcpa_suppression`
5. `mail_opt_out`
