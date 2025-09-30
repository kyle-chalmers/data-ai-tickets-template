# DI-1272: Enhanced VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT

## Executive Summary

Enhanced the `VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT` view by adding **185 missing fields** from CUSTOM_FIELD_VALUES, increasing coverage from **278 fields** to **463 fields** (67% increase). Comprehensive null analysis performed on 127,023 LMS records with business value assessment for each field category.

## Business Impact

### Data Completeness Enhancement
- **Before**: 278 fields (63% coverage)
- **After**: 463 fields (100% of identified fields)
- **Enhancement**: 185 new fields (67% increase)

### Key Capabilities Enabled
- **Enhanced Fraud Investigation**: 42+ fraud tracking fields including Jira ticket references
- **Complete Bankruptcy Analytics**: All bankruptcy-related fields for comprehensive analysis
- **Advanced Loan Modifications**: Complete modification tracking and workflow fields
- **Enhanced Customer Analytics**: HAPPY_SCORE and bureau score tracking
- **Legal & Compliance**: Complete attorney and legal case management

## Field Population Analysis Results

**Based on 127,023 LMS records (September 2025)**

### Existing Field Quality Issues
- **REPOSSESSION_COMPANY_NAME**: 100% null - **recommend removal**
- **BANKRUPTCY_CASE_NUMBER**: 94.96% null (6,416 records)
- **ATTORNEY_NAME**: 95.32% null (5,948 records)
- **DATE_OF_DEATH**: 99.98% null (25 records)
- **SETTLEMENT_AMOUNT**: 99.21% null (1,004 records)

### New Field Business Value Assessment

| Category | Population Rate | Records | Business Priority | Status |
|----------|----------------|---------|------------------|--------|
| **Loan Modifications** | 7.35% avg | ~9,350 | HIGH | Active business process |
| **Analytics (HAPPY_SCORE)** | 9.66% | 12,274 | HIGH | Highest adoption |
| **Bankruptcy Enhancement** | 5.05% | 6,418 | HIGH | Matches existing patterns |
| **Fraud Investigation** | 0.33% avg | 774 | MEDIUM | Active investigations |
| **Legal & Compliance** | 0.20% avg | ~255 | LOW | Limited current usage |
| **Attorney Enhancement** | 0.00% | 0 | FUTURE | Unused features |
| **System Integration** | 0.00% | 0 | FUTURE | Legacy/future capability |

### Key Business Insights
1. **Loan modification fields show highest usage** - indicates active business process
2. **HAPPY_SCORE has strong adoption** - 9.66% population for customer analytics
3. **Bankruptcy fields align with existing usage** - consistent ~5% population pattern
4. **Fraud investigation active but targeted** - low but consistent usage for ongoing cases
5. **Attorney enhancement fields completely unused** - may be future functionality

## Comprehensive Bankruptcy Field Analysis

### Complete Bankruptcy Field Set (15 total fields)

**Existing Fields (13 fields)**:
- BANKRUPTCY_CASE_NUMBER, BANKRUPTCY_COURT_DISTRICT, BANKRUPTCY_FILING_DATE
- BANKRUPTCY_STATUS, BANKRUPTCY_FLAG, BANKRUPTCY_VENDOR
- BANKRUPTCY_ORDERED_* fields (4 court-ordered restructuring fields)
- BANKRUPTCY_NOTIFICATION_RECEIVED_DATE, DISCHARGE_DATE, DISMISSAL_DATE

**New Fields Added (2 fields)**:
- **BANKRUPTCY_BALANCE**: Outstanding debt amount for recovery analytics
- **BANKRUPTCY_CHAPTER**: Chapter 7/13 classification for legal proceedings

### Bankruptcy Analytics Workflow
1. **Pre-Filing**: BANKRUPTCY_NOTIFICATION_RECEIVED_DATE, ATTORNEY_RETAINED
2. **Filing**: BANKRUPTCY_FILING_DATE, BANKRUPTCY_CASE_NUMBER, BANKRUPTCY_CHAPTER
3. **Court Orders**: BANKRUPTCY_ORDERED_* fields (amount, rate, payments)
4. **Management**: BANKRUPTCY_STATUS, BANKRUPTCY_BALANCE, BANKRUPTCY_FLAG
5. **Resolution**: DISCHARGE_DATE, DISMISSAL_DATE

## Technical Implementation

### Architecture Deployment
- **FRESHSNOW**: Enhanced view with all 463 fields
- **BRIDGE**: SELECT * inheritance from FRESHSNOW
- **ANALYTICS**: SELECT * inheritance from BRIDGE

### Critical Requirements
- **Schema Filtering**: All fields filtered using `schema_name = ARCA.config.lms_schema()`
- **Data Type Casting**: TRY_CAST for all date/numeric fields for error handling
- **Backward Compatibility**: All existing 278 fields maintain identical structure

### Field Categories Added (185 New Fields)

| Category | Count | Examples | Business Value |
|----------|-------|----------|----------------|
| **Fraud Investigation** | 42 | FRAUD_JIRA_TICKET1-20, FRAUD_STATUS_RESULTS1-20 | High - Active tracking |
| **Loan Modifications** | 25 | LOAN_MOD_EFFECTIVE_DATE, MOD_IN_PROGRESS | High - Active process |
| **Legal & Compliance** | 30 | DCA_START_DATE, PROOF_OF_CLAIM_DEADLINE_DATE | Medium - Compliance |
| **Analytics Enhancement** | 12 | HAPPY_SCORE, LATEST_BUREAU_SCORE | High - Customer insights |
| **System Integration** | 15 | CLS_CLEARING_DATE, UNDERWRITER_DECISION | Future - Legacy/new features |
| **Attorney Enhancement** | 6 | ATTORNEY_ORGANIZATION, ATTORNEY_PHONE2-3 | Future - Currently unused |
| **Settlement & Collections** | 8 | SETTLEMENT_TYPE, APPROVED_SETTLEMENT_AMOUNT | Medium - Process tracking |
| **Communication & Misc** | 47 | DATE_ENTERED, COMMUNICATION_STATUS, US_CITIZENSHIP | Low - Various purposes |

## Implementation Recommendations

### Priority 1 (Immediate Business Value)
- **Loan Modification fields**: Highest usage category (7.35% avg population)
- **HAPPY_SCORE**: Strong adoption for analytics (9.66% population)
- **Bankruptcy Chapter**: Aligns with existing bankruptcy usage patterns

### Priority 2 (Active but Targeted)
- **Fraud Investigation fields**: Active usage for ongoing investigations (0.33% avg)
- **Bankruptcy Balance**: Supports recovery analytics

### Priority 3 (Future Capability)
- **Attorney Enhancement fields**: Currently unused but may gain adoption
- **System Integration fields**: Legacy or future functionality

## Files Delivered

### Production Ready
1. **`1_enhanced_view_ddl.sql`**: Complete DDL with 463 fields
2. **`2_deployment_script.sql`**: 5-layer architecture deployment script

### Quality Control
- **`qc_queries/`**: Comprehensive validation suite
  - `1_enhanced_view_validation.sql`: Core field validation
  - `2_new_fields_accessibility_test.sql`: New field access testing
  - `3_existing_fields_null_analysis.sql`: Existing field quality analysis
  - `4_new_fields_null_analysis.sql`: New field population analysis

### Source Materials
- **`current_production_ddl.sql`**: Original production view structure
- **`all_available_fields.csv`**: Complete inventory of 441 available fields
- **`missing_fields.txt`**: List of 185 missing fields identified

## Assumptions Made

1. **Schema Filtering**: All fields apply LMS schema filter for data consistency
2. **Data Types**: Inferred from field naming patterns and business context
3. **Backward Compatibility**: All existing 278 fields maintain identical structure
4. **Business Logic**: Maintained existing view joins and filtering logic
5. **Performance**: Current query performance acceptable with 67% more fields
6. **Field Usage**: Population rates indicate current business value and adoption

## 100% NULL Fields Analysis - LoanPro Cleanup Opportunity

### Overview
**Finding**: **226 of 463 custom fields (49%) are completely unused** across all 127,023 LMS records analyzed (September 2025).

**Business Impact**: Nearly half of LoanPro custom fields contain zero data, creating unnecessary clutter in the UI, admin interfaces, and system complexity.

**Recommendation**: Systematic removal of unused fields to streamline LoanPro configuration and improve user experience.

### Fields by Category (226 Total)

**High-Priority Cleanup Candidates (62 fields)**
- Repossession Fields: 13 (entire module unused)
- Investor Fields: 15 (INVESTOR1-15 all null)
- CLS System Integration: 9 (legacy/future capability)
- Extended Fraud Investigation: 25 (FRAUD_JIRA_TICKET_9-20, FRAUD_STATUS_RESULTS_9-20, FRAUD_CONTACT_EMAIL)

**Business Process Fields - Unused Portions (78 fields)**
- Bankruptcy: 20 (including BANKRUPTCY_BALANCE, BANKRUPTCY_CHAPTER, court order fields)
- SCRA/Military: 12 (all military service tracking fields)
- Skip-A-Pay/Hardship: 9 (all skip-a-pay program variants)
- Loan Modification: 8 (unused modification tracking fields)
- DCA/Collections: 8 (DCA workflow fields)
- Settlement: 7 (settlement tracking fields)
- Debt Sale: 8 (debt sale workflow)
- Attorney: 7 (attorney contact details)

**System Integration & Legacy Fields (86 fields)**
- Miscellaneous/Legacy: 47 (various unused features)
- Credit Bureau/Reporting: 8 (bureau score tracking, complaint fields)
- Servicer/Third-Party: 6 (servicer management)
- Trustage Insurance: 5 (insurance program fields)
- Funding/Origination: 6 (funding process fields)
- Recall/Objection: 5 (recall workflow)
- Portfolio/Channel: 3 (portfolio classification)

### Detailed Field Inventory

<details>
<summary><b>Repossession Fields (13 fields)</b></summary>

- REPOSSESSION_CASE_NUMBER
- REPOSSESSION_CITY
- REPOSSESSION_COMPANY_CONTACT_NAME
- REPOSSESSION_COMPANY_EMAIL_ADDRESS
- REPOSSESSION_COMPANY_NAME
- REPOSSESSION_COMPANY_PHONE_NUMBER
- REPOSSESSION_COUNTY
- REPOSSESSION_DATE
- REPOSSESSION_MANAGER_DECLINE_DATE
- REPOSSESSION_REVIEW_DECISION
- REPOSSESSION_STATE
- CUSTOMER_REDEEMED_COLLATERAL
- BALANCE_AT_TIME_OF_DEBT_SALE
</details>

<details>
<summary><b>Fraud Investigation Fields - Extended Slots (25 fields)</b></summary>

- FRAUD_JIRA_TICKET_9 through FRAUD_JIRA_TICKET_20 (12 fields)
- FRAUD_STATUS_RESULTS_9 through FRAUD_STATUS_RESULTS_20 (12 fields)
- FRAUD_CONTACT_EMAIL (1 field)

**Note**: Slots 1-8 are actively used (0.33% population); slots 9-20 completely unused
</details>

<details>
<summary><b>Investor Fields (15 fields)</b></summary>

- INVESTOR1
- INVESTOR2
- INVESTOR3
- INVESTOR4
- INVESTOR5
- INVESTOR6
- INVESTOR7
- INVESTOR8
- INVESTOR9
- INVESTOR10
- INVESTOR11
- INVESTOR12
- INVESTOR13
- INVESTOR14
- INVESTOR15
</details>

<details>
<summary><b>CLS System Integration (9 fields)</b></summary>

- CLS_ACCOUNT_ID
- CLS_CLEARING_DATE
- CLS_CREATED_DATETIME
- CLS_LAST_MODIFIED_DATETIME
- CLS_REVERSAL_REASON_CODE
- CLS_REVERSAL_REFERENCE
- CLS_REVERSAL_TRANSACTION_NAME
- CLS_TRANSACTION_DATE
- REVERSAL_TRANSACTION_DATETIME
</details>

<details>
<summary><b>Bankruptcy Fields (20 fields)</b></summary>

- BANKRUPTCY_BALANCE
- BANKRUPTCY_CHAPTER
- BANKRUPTCY_ORDERED_NEW_INTEREST_RATE
- BANKRUPTCY_ORDERED_NEW_LOAN_AMOUNT
- BANKRUPTCY_ORDERED_NEW_PAYMENT_AMOUNT
- BANKRUPTCY_ORDERED_NUMBER_OF_PAYMENTS
- BANKRUPTCY_VENDOR
- DATE_CLOSED
- DATE_CONVERTED
- DATE_DISCHARGED
- DATE_DISMISSED
- DATE_JOINT_DEBTOR_DISCHARGED
- DATE_JOINT_DEBTOR_DISMISSED
- DATE_PLAN_CONFIRMED
- DATE_REOPENED
- DATE_TERMINATED
- DATE_TRANSFERRED
- JOINT_DEBTOR_DISCHARGED_DATE
- JOINT_DEBTOR_DISMISSED_DATE
- JOINT_DEBTOR_DISPOSITION
</details>

<details>
<summary><b>SCRA/Military Fields (12 fields)</b></summary>

- ACTIVE_DUTY_END_DATE
- ACTIVE_DUTY_START_DATE
- MILITARY_BRANCH
- SCRA_ACTIVE_DUTY_END_DATE5
- SCRA_ACTIVE_DUTY_START_DATE5
- SCRA_CERTIFIED
- SCRA_DECLINE_REASON
- SCRA_END_DATE
- SCRA_NOTIFICATION_DATE5
- SCRA_ORDERS_RECEIVED_DATE
- SCRA_REQUEST_RECEIVED_DATE
- SCRA_START_DATE
</details>

<details>
<summary><b>Skip-A-Pay/Hardship Fields (9 fields)</b></summary>

- DISASTER_SKIP_A_PAY_ENROLLMENT
- DSAP1_MOD_END_DATE
- DSAP2_MOD_END_DATE
- DSAP_MOD_START_DATE
- SSAP1_MOD_END_DATE
- SSAP2_MOD_END_DATE
- SSAP_MOD_START_DATE
- STANDARD_SKIP_A_PAY_ENROLLMENT_START_DATE
- HARDSHIP_ENROLLMENT_START_DATE
</details>

<details>
<summary><b>Loan Modification Fields (8 fields)</b></summary>

- MOD_TERM_EXTENSION
- PAYMENT_AMOUNT_BEFORE_MODIFICATION
- PERCENTAGE_OF_CURRENT_PAYMENT
- MANAGER_REVIEW_PERCENTAGE_OF_CURRENT_PAYMENT
- MANAGER_REVIEW_PERCENTAGE_OF_CURRENT_PAYMENT_C
- MEMBER_REQUESTED_PAYMENT_REDUCTION_RANGE
- MEMBER_REQUESTED_PAYMENT_REDUCTION_RANGE_C
- MATURITY_DATE_BEFORE_MOD_C
</details>

<details>
<summary><b>DCA/Collections Fields (8 fields)</b></summary>

- DCA_CLOSE_DATE
- DCA_CLOSE_REASON
- DCA_END_DATE
- DCA_RECALL_ACKNOWLEDGMENT_DATE
- DCA_START_DATE
- AMOUNT_DUE_TO_HAPPY_MONEY_DCA
- FEE_RATE_DCA
- THIRD_PARTY_COLLECTION_AGENCY
</details>

<details>
<summary><b>Settlement Fields (7 fields)</b></summary>

- SETTLEMENT_AGREEMENT_AMOUNT_DCA
- SETTLEMENT_COMPANY_DCA
- SETTLEMENT_END_DATE
- SETTLEMENT_SETUP_DATE
- SETTLEMENT_STATUS_DCA
- UNPAID_SETTLEMENT_BALANCE
- DEBT_REPURCHASE_STATUS
</details>

<details>
<summary><b>Debt Sale Fields (8 fields)</b></summary>

- DEBT_BUYER
- DEBT_REQUEST_SENT_TEST
- DEBT_REQUEST_TEST
- DEBT_SALE_STATUS
- SOLD_DATE
- SECONDARY_BUYER
- SECONDARY_SELLER
- DATE_SUBMITTED_TO_REFERRER
</details>

<details>
<summary><b>Attorney Fields (7 fields)</b></summary>

- ATTORNEY_ORGANIZATION
- ATTORNEY_PHONE_2
- ATTORNEY_PHONE_3
- ATTORNEY_PREFERRED_METHOD_OF_CONTACT_C
- ATTORNEY_STREET_1
- ATTORNEY_STREET_2
- ATTORNEY_STREET_3
</details>

<details>
<summary><b>Trustage Insurance Fields (5 fields)</b></summary>

- TRUSTAGE_CLAIM_NUMBER
- TRUSTAGE_END_DATE
- TRUSTAGE_PAYMENT_GUARD_INSURANCE_PROGRAM_ENROLLMENT_DATE
- TRUSTAGE_START_DATE
- HARDSHIP_DESCRIPTION
</details>

<details>
<summary><b>Credit Bureau/Reporting Fields (8 fields)</b></summary>

- BORROWER_SUBSCRIBER_ID
- LATEST_BUREAU_SCORE
- LATEST_BUREAU_SCORE_DATE
- REFRESHED_BUREAU_SCORE
- REFRESHED_BUREAU_SCORE_DATE
- CORRECTED_CREDIT_REPORTING_ITEM
- INCORRECT_CREDIT_REPORTING_ITEM
- COMPLAINT_STATUS
</details>

<details>
<summary><b>Servicer/Third-Party Fields (6 fields)</b></summary>

- SERVICER_END_DATE
- SERVICER_NAME
- SERVICER_START_DATE
- THIRD_PARTY_COMMUNICATION_WITH_HM_ABOUT_DEBT
- THIRD_PARTY_CONTACT
- CREDIT_COUNSELOR_COMPANY
</details>

<details>
<summary><b>Recall/Objection Fields (5 fields)</b></summary>

- HM_RECALL_DATE
- HM_RECALL_REASON
- RECALL_OBJECTION_APPROVED_DATE
- RECALL_OBJECTION_DENIED_DATE
- RECALL_OBJECTION_REASON
</details>

<details>
<summary><b>Funding/Origination Fields (6 fields)</b></summary>

- FUNDING_CANCELLATION_REASON
- FUNDING_STATUS
- INDIRECT_AMOUNT_ORIGINATION_INTEREST
- INDIRECT_LENDER_ORIGINATION_FEE
- INDIRECT_PURCHASE_DATE
- ORIGINATION_FEE
</details>

<details>
<summary><b>Portfolio/Channel Fields (3 fields)</b></summary>

- PORTFOLIO_ID_C
- PORTFOLIO_NAME_C
- CHANNEL
</details>

<details>
<summary><b>Miscellaneous/Legacy Fields (47 fields)</b></summary>

- ADVERSE_ACTION_TEMPLATE_ID
- AGENT_NAME_COMPLETED_POC
- AMOUNT_DUE_TO_HAPPY_MONEY
- CHOSEN_NAME
- CLAIM_COMPLETED_DATE
- COMMUNICATION_STATUS
- CONTINGENCY_STATUS_CODE
- CONTINGENCY_STATUS_CODE_APPLY_DATE
- CONVERTED_DATE
- DATE_ENTERED
- DEATH_CONFIRMED_DATE
- DISCHARGED_DATE
- DISPOSITION
- DNU
- EXPECTED_RESPONSE_DATE
- EXTERNAL_DELIVERY_ID
- FEMA_ACTIVE_END_DATE
- FEMA_ACTIVE_START_DATE
- FILING_FEE_STATUS
- HARDSHIP_ENROLLMENT_END_DATE
- INCOME_TYPE5
- IS_MIGRATED
- LAST_DATE_TO_FILE_CLAIMS
- LAST_DATE_TO_FILE_CLAIMS_GOVT
- MEMBER_PORTAL_VERSION
- NEW_DUE_DATE
- NUMBER_OF_SKIPS
- NUMBER_PAYMENTS_SKIPPED
- PAYOFF_UID
- PLAN_CONFIRMED_DATE
- PROCESSING_FEES_PAID
- PROMISE_TO_PAY_DATE
- PROMO_PERIOD_EXPIRATION_DATE
- REAFFIRMATION_DATE
- REFERRAL_SHOWN_DATE
- REOPENED_DATE
- REPURPOSE_2
- REPURPOSE_3
- REPURPOSE_4
- REPURPOSE_CF
- REQUESTED_FIRST_PAYMENT_DATE
- SALE_DATE_CONFIGURATION
- SALE_FLAG
- SOURCE_OF_REFERRAL
- STATE_RATE
- TEMPORARY_PAYMENT_REDUCTION_TERM
- TENANT_ID
- TEN_DAY_PAYOFF
- US_CITIZENSHIP
- VALIDATION_OF_DEBT_STATUS
</details>

### Cleanup Recommendations

**Immediate Removal Candidates (62 fields)**
1. **Repossession module**: 13 fields - entire feature unused
2. **Investor tracking**: 15 fields - INVESTOR1-15 all null
3. **CLS integration**: 9 fields - legacy/future system
4. **Extended fraud slots**: 25 fields - slots 9-20 unused (keep 1-8)

**Phase 2 Review (78 fields)**
Business process fields requiring stakeholder validation before removal:
- Bankruptcy, SCRA, Settlement, DCA workflows
- Confirm these represent abandoned features vs. future needs

**Phase 3 Cleanup (86 fields)**
System integration and legacy fields requiring technical review

### SERV Ticket Reference
**SERV-755**: LoanPro Custom Fields Cleanup - Remove 199 Unused Fields (100% NULL)
https://happymoneyinc.atlassian.net/browse/SERV-755

---

## Deployment Notes

### Pre-Deployment
1. **Backup current view** - Saved in `current_production_ddl.sql`
2. **Verify schema access** - Ensure `ARCA.config.lms_schema()` function available
3. **Permission validation** - Check COPY GRANTS across layers

### Post-Deployment Validation
1. **Field count verification** - Confirm 463 fields in all layers
2. **Performance monitoring** - Track query execution times
3. **Business validation** - Test key analytics use cases
4. **Population monitoring** - Track adoption of high-value fields over time

---

**Developer**: Kyle Chalmers (kchalmers@happymoney.com) | **Ticket**: DI-1272 | **Date**: September 2025