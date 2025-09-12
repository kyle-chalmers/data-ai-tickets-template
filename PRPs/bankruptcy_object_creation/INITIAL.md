# Data Object Request

## Request Type
- **Operation:** CREATE_NEW
- **Scope:** SINGLE_OBJECT

## Object Definition(s)
- **Primary Object Name:** LOAN_BANKRUPTCY
- **Object Type:** Preferably DYNAMIC TABLE, but can be VIEW if necessary
- **Target Schema Layer:** ANALYTICS


## Data Grain & Aggregation
- **Grain:** One row per bankruptcy and loan, so a loan can be on multiple rows, but bankruptcy filings should be unique to the row
- **Time Period:** all time
- **Key Dimensions:** all bankruptcy related fields, with case number being the primary key for a bankruptcy and then loan_id for the loan

## Business Context
**Business Purpose:** This is needed as a source for bankruptcy related metrics and analysis, and to suppress loans that are bankrupt within this job https://github.com/HappyMoneyInc/business-intelligence-data-jobs/blob/main/jobs/BI-2482_Outbound_List_Generation_for_GR/BI-2482_Outbound_List_Generation_for_GR.py#L440-L448 as currently it is referencing an outdated table that comes from our legacy system Cloud Lending Solutions that is no longer referenced. We need a source of truth to quickly and easily understand our bankruptcy data.

**Primary Use Cases:** 
- Suppression logic for outbound lists
- Analysis of bankruptcy data

**Key Metrics/KPIs:** count of active bankruptcies for all of our loans, a timeline of bankruptcy filings, it should also help us uncover inconsistencies and data issues with our bankruptcy data

## Data Sources
**New/Target Sources:** 
- BUSINESS_INTELLIGENCE.BRIDGE.VW_BANKRUPTCY_ENTITY_CURRENT for all bankruptcy data stored in the bankruptcy entity
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT for all custom fields associated with the loan that are relevant to bankruptcy 
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS for all bankruptcy portfolios associated with the loan 
- BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT joined with BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SUB_STATUS_ENTITY_CURRENT on LOAN_SUB_STATUS_ID = ID to get the current status

**Expected Relationships:** on LOAN_ID, and then on LOAN_SUB_STATUS_ID = ID for the loan sub status and loan settings views

**Data Quality Considerations:** There may be duplicated data between the custom fields data and the bankruptcy entity data, so we should default to using the bankruptcy entity data. There may also be inconsistencies between the custom fields data and the bankruptcy entity data, so we should mark the source of the data in the table. Please find and raise any data quality issues with me as there will probably be a few.

**Expected Data Differences:** The VW_BANKRUPTCY_ENTITY_CURRENT should be the primary table here, but there may be some data that is only in the custom fields data, so we should mark the source of the data in the table.  

## Requirements
- **Performance:** As quickly as possible
- **Refresh Pattern:** It should be up to date with the source
- **Data Retention:** all time

## Ticket Information
- **Existing Jira Ticket:** CREATE_NEW
- **Stakeholders:** Kyle Chalmers

## Additional Context
The data inside the chapter, petition_status, and process_status columns in the bankruptcy entity should be cleaned up and normalized as well. If you have any issues working with the sources of data please let me know. Also BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE is meant to have bankruptcy data, so compare our final object to that to make sure we are capturing all the data we need, but expect this final object to have more data than that since I believe it is frozen.