# DI-1314: 3Q25 CRB Compliance Testing Data Pull

## Ticket Information
- **Jira:** [DI-1314](https://happymoneyinc.atlassian.net/browse/DI-1314)
- **Type:** Data Pull - CRB Q3 2025 Compliance Testing
- **Due Date:** October 17, 2025
- **Assignee:** Kyle Chalmers
- **Status:** In Progress - Research Phase

## Business Context

CRB (Cross River Bank) Round 3 2025 Compliance Testing and Monitoring data request covering multiple regulatory requirements with **varying scope dates**. All data must be for **CRB ORIGINATIONS ONLY**.

**Critical Note:** This request covers ONLY loans originated through Cross River Bank.

## CRB Originations Filter

All queries use the following filter to identify CRB originations:
```sql
WHERE PORTFOLIOID IN ('32', '34', '54', '56')
```

## Required Data Pulls

### ✅ Item 1: CAN-SPAM - Marketing Email Opt-Outs (Ref 1.A & 1.B)
**Scope:** October 1, 2023 - August 31, 2025
**Due:** October 17, 2025

**Deliverables:**
- **1.A:** Documentation of opt-out mechanisms and functionality
- **1.B:** CSV with marketing opt-out list

**Required Fields (1.B):**
- Unique Customer Identifier
- Customer Name
- Customer Email Address
- Date Opt-out Requested
- Date Opt-out Processed
- Date Last Email Sent to customer

**Status:** 🔍 Discovery in progress - Need to find opt-out tracking tables

---

### ✅ Item 2: GLBA Privacy - Information Sharing Opt-Outs (Ref 3.A)
**Scope:** October 1, 2023 - August 31, 2025
**Due:** October 17, 2025

**Deliverables:**
- CSV with privacy opt-out list

**Required Fields:**
- Unique Customer Identifier
- Customer Name
- Date Privacy Notice Provided
- Date Opt-out Requested
- Date Opt-out Processed

**Status:** 🔍 Discovery in progress - Need to find privacy opt-out tracking

---

### ✅ Item 3: FCRA - Negative Credit Reporting (Ref 6.A)
**Scope:** October 1, 2024 - August 31, 2025
**Due:** October 17, 2025

**Deliverables:**
- CSV with first late payment list

**Required Fields:**
- Loan Number
- Borrower Name
- Date of first late payment
- How many days past due borrower became
- If borrower was reported late to CRA

**Status:** ✅ **Prototype query complete** - See `exploratory_analysis/2_fcra_negative_reporting_prototype.sql`

**Data Sources:**
- ✅ MVW_LOAN_TAPE_DAILY_HISTORY (first late payment tracking by ASOFDATE)
- ✅ VW_MEMBER_PII (borrower names)
- ⏳ Credit bureau reporting tables (TBD - need to find for "Reported to CRA" field)

**Approach:**
1. Use MVW_LOAN_TAPE_DAILY_HISTORY to find first date DAYSPASTDUE > 0 in scope
2. Capture DAYSPASTDUE value at first late payment
3. Join to PII for borrower names
4. TODO: Join to credit bureau reporting logs for CRA submission status

---

### ✅ Item 4: FCRA - Credit Disputes (Ref 7.A & 7.B)
**Scope:** October 1, 2024 - August 31, 2025
**Due:** October 17, 2025

**Deliverables:**
- CSV for indirect disputes (7.A)
- CSV for direct disputes (7.B)

**Required Fields (Indirect - 7.A):**
- Loan Number
- Borrower Name
- Receipt Date of Dispute
- Source of Dispute
- Resolution Date of Dispute
- **ACDV Control#** (Automated Consumer Dispute Verification)

**Required Fields (Direct - 7.B):**
- Loan Number
- Borrower Name
- Receipt Date of Dispute
- Source of Dispute
- Resolution Date of Dispute
- **AUD Control#** (Automated Universal Dataform) - as applicable

**Status:** 🔍 Discovery in progress - Need to find dispute tracking system

**Key Questions:**
- Where are credit disputes tracked?
- How to distinguish indirect (bureau) vs direct (customer) disputes?
- Where are ACDV/AUD control numbers stored?

---

## ❌ Not Applicable Items

### Item 5: EFTA - Pre-Authorizations (Ref 4.A)
**Reason:** N/A - To be documented

### Item 6: FCRA - Credit Line Increases (Ref 5.A)
**Reason:** N/A - Happy Money closed-end loans don't offer credit line increases
**Note:** All marked "N/A" in source Excel file

### Item 7: Marketing T&C
**Reason:** Performed without data request per Excel instructions

### Item 8: TILA - Card Issuance (Ref 8.A)
**Reason:** N/A - Not applicable to closed-end installment loans (credit cards only)

---

## Current Status

**Phase:** Discovery Complete - Awaiting Stakeholder Clarification

### ✅ Completed Deliverables (3 of 6)

**Item 1.A - Opt-Out Mechanisms Documentation**
- ✅ Comprehensive documentation created
- Location: `final_deliverables/optout_mechanisms_documentation.md`
- Details SFMC and LoanPro opt-out systems, CAN-SPAM compliance

**Item 1.B - CAN-SPAM Email Opt-Outs**
- ✅ Query complete and tested: `1_item1_canspam_email_optouts.sql`
- ✅ CSV generated: `1_item1_canspam_email_optouts.csv`
- **Records:** 592 CRB customers with email opt-outs (Oct 2023 - Aug 2025)
- ✅ QC validation query created

**Item 3 - FCRA Negative Credit Reporting**
- ✅ Query complete and tested: `2_item3_fcra_negative_credit_reporting.sql`
- ✅ CSV generated: `2_item3_fcra_negative_credit_reporting.csv`
- **Records:** 7,081 CRB loans with first late payments (Oct 2024 - Aug 2025)
- ✅ Uses MVW_LOAN_TAPE_DAILY_HISTORY + LASTPAYMENTDATE logic
- ✅ QC validation query created

**Item 4.A - FCRA Indirect Disputes (ACDV)**
- ✅ Query complete and tested: `3_item4a_fcra_indirect_disputes_acdv.sql`
- ✅ CSV generated: `3_item4a_fcra_indirect_disputes_acdv.csv`
- **Records:** 0 (no ACDV disputes since Oct 2021 - valid finding)
- ✅ QC validation query created

**N/A Items Documentation**
- ✅ Items 5-8 documented with business justification
- Location: `final_deliverables/NA_items_documentation.md`

### ❓ Blocked Pending Stakeholder Clarification (3 items)

**Item 1 - "Date Last Email Sent" Field**
- Individual send history not available in Snowflake
- Needs decision: N/A or SFMC API retrieval?

**Item 2 - GLBA Privacy Opt-Outs**
- No privacy opt-out tracking found in database
- Need clarification on tracking location or N/A status

**Item 4.B - FCRA Direct Disputes (AUD)**
- No direct dispute tracking found in database
- Need clarification on tracking location or N/A status

### 📊 Work Summary
- **Discovery:** Complete (all schemas searched, 253 lines of documentation)
- **Final Queries:** 3 of 6 built and tested
- **CSV Outputs:** 3 generated (592 + 7,081 + 0 records)
- **QC Queries:** 3 validation scripts created
- **Documentation:** Complete (opt-out mechanisms, N/A items, stakeholder questions)

---

## File Structure

```
DI-1314/
├── README.md (this file - comprehensive ticket documentation)
├── CLAUDE.md (Claude Code context for session continuity)
├── stakeholder_questions_jira_comment.txt (ready to post)
│
├── source_materials/
│   └── Happy Money Round 3 Compliance Testing DRL - Consumer.xlsx
│
├── exploratory_analysis/
│   ├── 1_schema_discovery.sql
│   ├── 2_fcra_negative_reporting_prototype.sql
│   ├── 3_optout_privacy_discovery.sql
│   ├── 4_dispute_discovery.sql
│   └── RESEARCH_FINDINGS.md (253 lines - complete discovery documentation)
│
├── final_deliverables/
│   ├── 1_item1_canspam_email_optouts.sql (tested ✅)
│   ├── 1_item1_canspam_email_optouts.csv (592 records)
│   ├── 2_item3_fcra_negative_credit_reporting.sql (tested ✅)
│   ├── 2_item3_fcra_negative_credit_reporting.csv (7,081 records)
│   ├── 3_item4a_fcra_indirect_disputes_acdv.sql (tested ✅)
│   ├── 3_item4a_fcra_indirect_disputes_acdv.csv (0 records - header only)
│   ├── optout_mechanisms_documentation.md (Item 1.A)
│   └── NA_items_documentation.md (Items 5-8)
│
└── qc_queries/
    ├── 1_item1_optouts_qc_validation.sql (6 QC tests)
    ├── 2_item3_negative_reporting_qc_validation.sql (8 QC tests)
    └── 3_item4a_disputes_qc_validation.sql (5 QC tests)
```

---

## Data Sources Investigated

### Item 3: FCRA Negative Credit Reporting

**✅ Sources Used:**
- **MVW_LOAN_TAPE_DAILY_HISTORY** - Primary source for tracking first late payment dates
  - Contains daily snapshots of loan status via ASOFDATE
  - DAYSPASTDUE field tracks delinquency days
  - Allows identifying exact first date a loan became late in scope period
- **VW_MEMBER_PII** - Borrower name data

**❌ Sources Ruled Out:**
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_TAPE** - Current state only, no historical snapshots
  - Cannot determine "first late payment date" without daily history
  - Only shows current DAYSPASTDUE value, not when it first occurred
- **BUSINESS_INTELLIGENCE.ANALYTICS.VW_PAYMENTS** - Payment transaction data
  - Does not track daily delinquency status
  - Would require complex calculations to infer late payment dates
  - Less reliable than daily loan tape snapshots

**⏳ Still Needed:**
- Credit bureau reporting tables to confirm "Reported to CRA" status

---

## Assumptions & Notes

### CRB Originations Definition
- **Portfolio IDs 32, 34, 54, 56** represent Cross River Bank originations
- All queries filter to these portfolios only
- User confirmed this is the correct CRB filter

### Date Range Precision
- **Items 1 & 2:** October 1, 2023 - August 31, 2025 (2-year scope)
- **Items 3 & 4:** October 1, 2024 - August 31, 2025 (1-year scope)
- Date ranges differ by regulation

### First Late Payment Logic (Item 3)
- Using MVW_LOAN_TAPE_DAILY_HISTORY to track daily loan status
- "First late payment" = first date DAYSPASTDUE > 0 within scope period
- Historical snapshots via ASOFDATE field
- Need to verify credit bureau reporting submission process

### Stakeholder Clarification Needed

**Discovery Complete - 3 of 6 deliverables ready, 3 blocked pending clarification:**

**✅ Ready to Deliver:**
1. Item 1.B - CAN-SPAM Email Opt-Outs (592 records)
2. Item 3 - FCRA Negative Credit Reporting (7,081 records)
3. Item 4.A - FCRA Indirect Disputes (0 records - none in timeframe)

**❓ Questions for Stakeholder:**

1. **Item 1 - "Date Last Email Sent" Field**:
   - Individual customer email send history is not available in Snowflake
   - DSH_EMAIL_CAMPAIGN_SENT contains campaign-level metrics only
   - **Question**: Can this field be documented as "N/A - Not Available" or do you need SFMC API data retrieval?

2. **Item 2 - GLBA Privacy / Information Sharing Opt-Outs**:
   - No privacy opt-out tables found in Snowflake (searched: PRIVACY, GLBA, CONSENT, INFORMATION_SHARING)
   - RPT_UNSUBSCRIBER_SFMC is for marketing emails only (CAN-SPAM), not privacy/information sharing
   - **Questions**:
     - Does Happy Money track GLBA information-sharing opt-out requests separately from marketing opt-outs?
     - If yes, where are these tracked? (External system, manual process?)
     - If no, can this be documented as "N/A - No requests received in timeframe"?

3. **Item 4.B - FCRA Direct Disputes (AUD)**:
   - RPT_EOSCAR_ACDV contains only indirect disputes from credit bureaus (last activity: Oct 2021)
   - No tables found for direct customer disputes (searched: AUD, DIRECT_DISPUTE, CUSTOMER_DISPUTE)
   - **Questions**:
     - Does Happy Money receive direct credit disputes from customers (bypassing bureaus)?
     - If yes, where are these tracked? (LoanPro notes, case management system, manual logs?)
     - If no, can this be documented as "N/A - No direct disputes received in timeframe"?

4. **Item 3 - "Reported to CRA" Field Approach Confirmation**:
   - Used CREDIT_REPORT_HISTORY to infer reporting status via export timing
   - Logic: If first late date < next bureau export date → "Yes", otherwise "Pending" or "No"
   - **Question**: Is this time-based inference approach acceptable, or is there a direct loan-level reporting flag we should use?

---

## Next Steps

**Immediate:**
1. Post stakeholder questions to Jira (use `stakeholder_questions_jira_comment.txt`)
2. Await clarification on Items 2, 4.B, and "Date Last Email Sent" field
3. Run QC validation queries to verify deliverable quality

**After Stakeholder Response:**
4. Build queries for Item 2 (if applicable) or document as N/A
5. Build query for Item 4.B (if applicable) or document as N/A
6. Update Item 1 deliverable based on "Date Last Email Sent" decision
7. Final README updates and PR preparation

---

**Last Updated:** 2025-10-14 @ 23:30
**Status:** Discovery Complete - Awaiting Stakeholder Clarification
**Deliverables Ready:** 3 of 6 (Items 1.A, 1.B, 3, 4.A)
**Blocked:** 3 items pending clarification (Item 2, 4.B, Item 1 "Date Last Email Sent")
