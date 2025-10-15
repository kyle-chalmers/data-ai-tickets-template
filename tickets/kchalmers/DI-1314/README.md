# DI-1314: 3Q25 CRB Compliance Testing Data Pull

## Ticket Information
- **Jira:** [DI-1314](https://happymoneyinc.atlassian.net/browse/DI-1314)
- **Type:** Data Pull - CRB Q3 2025 Compliance Testing
- **Due Date:** October 17, 2025
- **Assignee:** Kyle Chalmers
- **Status:** Awaiting Stakeholder Clarification on Item 2

## Business Context

CRB (Cross River Bank) Q3 2025 Compliance Testing and Monitoring data request covering two regulatory requirements. All data must be for **CRB ORIGINATIONS ONLY**.

**IMPORTANT:** Requirements were updated on 2025-10-15 to focus on only two data pulls (CAN-SPAM and GLBA Privacy). All other items (negative credit reporting, disputes) have been removed from scope.

## CRB Originations Filter

All queries use the following filter to identify CRB originations:
```sql
WHERE PORTFOLIOID IN ('32', '34', '54', '56')
```

**Portfolios:**
- 32: Theorem Main Master Fund LP - Loan Sale
- 34: Theorem Prime Plus Yield Fund Master LP - Loan Sale
- 54: (CRB portfolio)
- 56: (CRB portfolio)

---

## Required Data Pulls

### ✅ Item 1: CAN-SPAM - Marketing Email Opt-Outs
**Scope:** October 1, 2023 - August 31, 2025 (2 years)
**Due:** October 17, 2025

**Required Fields:**
- Unique Customer Identifier
- Customer Name
- Customer Email Address
- Date Opt-out Requested
- Date Opt-out Processed
- Date Last Email Sent to customer

**Status:** ✅ **COMPLETE**

**Deliverables:**
- ✅ SQL Query: `final_deliverables/1_item1_canspam_email_optouts.sql`
- ✅ CSV Output: `final_deliverables/1_item1_canspam_email_optouts.csv`
- **Record Count:** 592 CRB customers with email opt-outs
- ✅ QC Validation: `qc_queries/1_item1_optouts_qc_validation.sql`

**Data Source:** `BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC`

**Note:** "Date Last Email Sent" field is NULL in output - individual customer email send history not available in Snowflake. Only campaign-level send data exists in DSH_EMAIL_CAMPAIGN_SENT.

---

### ❌ Item 2: Privacy - GLBA / Privacy Notice / Opt Out
**Scope:** October 1, 2023 - August 31, 2025 (2 years)
**Due:** October 17, 2025

**Required Fields:**
- Unique Customer Identifier
- Customer Name
- Date Privacy Notice Provided
- Date Opt-out Requested
- Date Opt-out Processed

**Status:** ❌ **BLOCKED - DATA NOT AVAILABLE**

**Investigation Summary:**
Comprehensive database search conducted across all Snowflake schemas. No GLBA privacy opt-out or privacy notice tracking tables found.

**Schemas Searched:**
- BUSINESS_INTELLIGENCE (DATA_STORE, ANALYTICS, ANALYTICS_PII, PII, CRON_STORE)
- RAW_DATA_STORE.LOANPRO

**Search Patterns:**
- %PRIVACY%, %GLBA%, %CONSENT%, %NOTICE%, %DOCUMENT%, %INFORMATION_SHARING%

**Key Finding:**
- `RPT_UNSUBSCRIBER_SFMC`: Contains **marketing email** opt-outs (CAN-SPAM, not GLBA)
- `RPT_OPTOUT_MAIL_SFMC`: Contains **postal mail** opt-outs (not information-sharing)
- No customer-level GLBA privacy consent or opt-out tracking found

**Deliverables:**
- ✅ Documentation: `final_deliverables/2_item2_glba_privacy_optouts_NOT_AVAILABLE.md`

**Stakeholder Action Required:**
1. Confirm if GLBA information-sharing opt-outs are tracked separately from marketing opt-outs
2. If yes, provide data source location (external system, manual records, etc.)
3. If no, determine appropriate response:
   - Document as N/A - No separate tracking exists
   - Document as N/A - No requests received
   - Use CAN-SPAM opt-outs as proxy

---

## Archived Items (Out of Scope)

The following items were part of the original ticket but have been removed from the updated requirements:

**Archived in `archive_versions/`:**
- Item 3: FCRA Negative Credit Reporting (7,081 records - complete)
- Item 4.A: FCRA Indirect Disputes ACDV (0 records - complete)
- Related SQL queries and QC validation scripts

---

## Current Status

**Overall Status:** 1 of 2 deliverables complete, 1 blocked pending stakeholder clarification

### ✅ Complete (1 item)
- **Item 1:** CAN-SPAM Email Opt-Outs (592 records, CSV delivered)

### ❌ Blocked (1 item)
- **Item 2:** GLBA Privacy Opt-Outs (data not found in Snowflake)

### 📊 Work Summary
- **Item 1:** Query built, tested, CSV generated, QC validation created
- **Item 2:** Comprehensive discovery completed, no data source identified
- **Documentation:** Complete investigation documentation created

---

## File Structure

```
DI-1314/
├── README.md (this file)
├── CLAUDE.md (Claude Code session context - archived, may be outdated)
│
├── source_materials/
│   └── Happy Money Round 3 Compliance Testing DRL - Consumer.xlsx
│
├── exploratory_analysis/
│   ├── 1_schema_discovery.sql
│   ├── 3_optout_privacy_discovery.sql
│   └── RESEARCH_FINDINGS.md
│
├── final_deliverables/
│   ├── 1_item1_canspam_email_optouts.sql ✅
│   ├── 1_item1_canspam_email_optouts.csv (592 records) ✅
│   ├── 2_item2_glba_privacy_optouts_NOT_AVAILABLE.md ⚠️
│   ├── optout_mechanisms_documentation.md
│   └── NA_items_documentation.md
│
├── qc_queries/
│   └── 1_item1_optouts_qc_validation.sql
│
└── archive_versions/
    ├── 2_fcra_negative_reporting_prototype.sql (removed from scope)
    ├── 4_dispute_discovery.sql (removed from scope)
    ├── 2_item3_fcra_negative_credit_reporting.* (removed from scope)
    ├── 3_item4a_fcra_indirect_disputes_acdv.* (removed from scope)
    └── [related QC queries] (removed from scope)
```

---

## Data Sources

### Item 1: CAN-SPAM Email Opt-Outs

**Primary Table:** `BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC`
- EMAIL: Customer email address
- DATEUNSUBSCRIBED: Timestamp of unsubscribe action
- SOURCE: Opt-out source (e.g., "_Subscribers", "Subscriber_Preferences")

**Join Path:**
```
RPT_UNSUBSCRIBER_SFMC.EMAIL (case-insensitive match)
→ VW_MEMBER_PII.EMAIL (+ MEMBER_ID)
→ VW_LOAN.MEMBER_ID (+ LEAD_GUID)
→ MVW_LOAN_TAPE.PAYOFFUID (+ CRB portfolio filter)
```

**Total Unsubscribers:** 746,473 (all customers)
**CRB Unsubscribers:** 592 (filtered to CRB portfolios)

### Item 2: GLBA Privacy Opt-Outs

**Status:** No data source identified in Snowflake

**Possible Alternative Sources:**
- External compliance management system
- Manual tracking (email, phone, mail logs)
- Customer service ticketing system
- LoanPro notes/comments (unstructured)

---

## Assumptions & Notes

### CRB Originations
- Portfolio IDs 32, 34, 54, 56 represent CRB originations
- Filter applied consistently across all queries
- Includes both active and inactive/closed loans

### Email Opt-Out Logic (Item 1)
- DATEUNSUBSCRIBED used for both "requested" and "processed" dates (SFMC doesn't separate)
- Email matching is case-insensitive and trimmed for consistency
- Customer may have multiple CRB loans - de-duplicated by MEMBER_ID
- "Date Last Email Sent" = NULL (individual send history not available)

### GLBA Privacy Opt-Outs (Item 2)
- **Key Distinction:** GLBA information-sharing opt-outs are different from CAN-SPAM marketing opt-outs
- CAN-SPAM = Marketing communications
- GLBA = Financial information sharing with third parties
- No evidence of separate GLBA tracking in data warehouse

---

## Stakeholder Questions

### Item 2: GLBA Privacy Opt-Outs - BLOCKING QUESTION

**Context:** Comprehensive database search found no GLBA privacy opt-out tracking in Snowflake.

**Questions:**
1. Does Happy Money track GLBA information-sharing opt-out requests separately from marketing email opt-outs?
2. If YES - where is this data stored?
   - External compliance system?
   - Manual tracking/logs?
   - Customer service ticketing?
   - Other location?
3. If NO - how should we document this item?
   - N/A - No separate GLBA tracking exists
   - N/A - No opt-out requests received in timeframe
   - Alternative approach?

**Impact:** Cannot proceed with Item 2 deliverable without clarification.

### Item 1: "Date Last Email Sent" Field - INFORMATIONAL

**Context:** Individual customer email send history not available in Snowflake. Only campaign-level data exists.

**Current Approach:** Field populated as NULL in CSV output with documentation.

**Question:** Is this acceptable or do you need alternative approach (e.g., SFMC API retrieval)?

---

## Next Steps

### Immediate Actions
1. ✅ Update README with simplified requirements
2. ✅ Create documentation for Item 2 (data not available)
3. ⏳ Post stakeholder question to Jira ticket
4. ⏳ Await clarification on Item 2 data source

### After Stakeholder Response
1. If Item 2 data source identified:
   - Build query following Item 1 pattern
   - Generate CSV output
   - Create QC validation script
   - Update README with final status

2. If Item 2 documented as N/A:
   - Update documentation with business justification
   - Mark deliverable as N/A
   - Prepare for final PR submission

3. Final Steps:
   - Run QC validation on all deliverables
   - Update README with final status
   - Create Jira completion comment
   - Submit PR for review

---

**Last Updated:** 2025-10-15
**Status:** Awaiting stakeholder clarification on Item 2 (GLBA Privacy Opt-Outs)
**Deliverables:** 1 of 2 complete (Item 1 ✅, Item 2 ⚠️ Blocked)
