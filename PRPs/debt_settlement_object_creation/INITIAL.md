# Data Object Request

## Request Type
- **Operation:** CREATE_NEW
- **Scope:** SINGLE_OBJECT

## Object Definition(s)
- **Primary Object Name:** LOAN_DEBT_SETTLEMENT
- **Object Type:** Preferably DYNAMIC TABLE, but can be VIEW if necessary
- **Target Schema Layer:** ANALYTICS

## Data Grain & Aggregation
- **Grain:** One row per debt settlement and loan, and each loan should only have one debt settlement.
- **Time Period:** all time
- **Key Dimensions:** all debt settlement related fields, with loan_id as the primary key for the loan

## Business Context
**Business Purpose:** This is needed as a source for debt settlement related metrics and analysis, and to ensure that we are capturing all of our debt settlements in a single source of truth, and also highlighting potential data issues associated with these debt settlements that are in. This will serve as a suppression source to ensure we are not including loans that have debt settlements in debt sales. Completing this will also help us complete DI-1246 and DI-1235.

**Primary Use Cases:** 
- Suppression from debt sale files
- Analysis of debt settlement data
- Identifying data quality issues with debt settlement data

**Key Metrics/KPIs:** Count of active debt settlements, a timeline of debt settlement agreements, and it should help us uncover inconsistencies and data issues with our debt settlement data

## Data Sources
**New/Target Sources:** 
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT for all custom fields associated with the loan that are relevant to debt settlement 
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS for all bankruptcy portfolios associated with the loan 
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT joined with BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT on LOAN_SUB_STATUS_ID = ID to get the current status

**Expected Relationships:** on LOAN_ID, and then on LOAN_SUB_STATUS_ID = ID for the loan sub status and loan settings views

**Data Quality Considerations:** Some debt settlements may have debt settlement sub statuses, but not all required information in the custom fields, and vice versa. Debt settlements may also have portfolios attached to them.

**Expected Data Differences:** We should mark the sources of the data, whether we have data coming from all 3 sources, or just one or two.

**Column Values:** Some fields may be entirely NULL, and if they are NULL they can be excluded. There are some fields that you may be able to calculate as well, Settlement Completion Percentage, that are otherwise NULL from the custom fields (SETTLEMENTCOMPLETIONPERCENTAGE), but we can still measure. I will need you to take an exploratory approach to determine appropriate column values.

## Requirements
- **Performance:** As quickly as possible
- **Refresh Pattern:** It should be up to date with the source
- **Data Retention:** all time

## Ticket Information
- **Existing Jira Ticket:** CREATE_NEW
- **Stakeholders:** Kyle Chalmers

## Additional Context
There are a lot of debt settlement fields stored within the custom fields of the loan, and we will need to sort out what fields are valuable and which ones are not valuable. I've created a query below to help provide the context needed for looking at the debt settlement custom fields, but please note there may be other fields I am missing. Please confirm with me what the fields you are selecting, but generally speaking these fields have "SETTLEMENT" in them, but some may not. 
Here is the query:
SELECT SETTLEMENTSTATUS, SETTLEMENT_AMOUNT, SETTLEMENT_AMOUNT_PAID, SETTLEMENT_AGREEMENT_AMOUNT_DCA,
SETTLEMENTCOMPANY, SETTLEMENT_COMPANY_DCA, SETTLEMENT_ACCEPTED_DATE, SETTLEMENT_SETUP_DATE, SETTLEMENT_END_DATE, SETTLEMENTAGREEMENTAMOUNT,
SETTLEMENTCOMPLETIONDATE, SETTLEMENTCOMPLETIONPERCENTAGE, SETTLEMENTSTARTDATE, UNPAID_SETTLEMENT_BALANCE, DEBT_SETTLEMENT_COMPANY, DEBTSETTLEMENTPAYMENTTERMS,
PAYOFF_AT_THE_TIME_OF_SETTLEMENT_ARRANGEMENT, TOTAL_PAID_AT_TIME_OF_SETTLEMENT, AMOUNT_FORGIVEN, EXPECTEDSETTLEMENTENDDATE, THIRD_PARTY_COLLECTION_AGENCY
FROM BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT;
I will need you to take an exploratory approach to determine what the appropriate columns are to include and confirm them with me, and explain why you are including them or excluding them.

**External References:** While it will not be exactly like this, the data created for BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY is a good model for how to combine different sources of data into a single source of truth.
Look at the debt settlement fields utilized and the logic in this query that filters out and searches for debt settlement data /Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1141/final_deliverables/sql_queries/3_Debt_Sale_Population_Final_Bounce_Q2_2025_Debt_Sale_OPTIMIZED.sql . development._tin.bankruptcy_debt_suspend_lookup should not be utilized as a source. This is what we created as a temporary step to filter debt settlements out of the debt sale population.