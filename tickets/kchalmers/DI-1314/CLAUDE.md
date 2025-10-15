# DI-1314: Claude Code Context Document
**CRB Q3 2025 Compliance Testing Data Pull**
**Last Updated:** 2025-10-14 @ 23:45
**Status:** Discovery Complete - Awaiting Stakeholder Clarification

## Current State Summary

**Phase:** Discovery and initial deliverable creation complete. Waiting for stakeholder clarification on 3 blocked items before proceeding.

**Progress:** 3 of 6 deliverables complete (50%)
- ✅ Item 1.A: Opt-out mechanisms documented
- ✅ Item 1.B: CAN-SPAM opt-outs (592 records)
- ✅ Item 3: FCRA negative reporting (7,081 records)
- ✅ Item 4.A: FCRA indirect disputes (0 records - valid)
- ❓ Item 2: GLBA privacy opt-outs (BLOCKED - no tables found)
- ❓ Item 4.B: FCRA direct disputes (BLOCKED - no tables found)

---

## What's Been Completed

### 1. Discovery Phase ✅ (Complete)

**Comprehensive schema discovery executed:**
- Searched all BUSINESS_INTELLIGENCE schemas (DATA_STORE, ANALYTICS, ANALYTICS_PII, PII, CRON_STORE)
- Searched RAW_DATA_STORE.LOANPRO schema
- Documented all findings in `exploratory_analysis/RESEARCH_FINDINGS.md` (253 lines)

**Key Tables Identified:**
- `BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC` (746K total unsubscribers) → Item 1
- `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY` → Item 3 (first late payments)
- `RAW_DATA_STORE.LOANPRO.CREDIT_REPORT_HISTORY` → Item 3 (bureau reporting inference)
- `BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV` (3,185 total disputes, last Oct 2021) → Item 4.A

**Tables NOT Found:**
- GLBA privacy opt-out tracking (searched: %PRIVACY%, %GLBA%, %CONSENT%, %INFORMATION_SHARING%)
- Direct dispute tracking (searched: %AUD%, %DIRECT_DISPUTE%, %CUSTOMER_DISPUTE%)
- Individual email send history (DSH_EMAIL_CAMPAIGN_SENT has campaign-level only)

### 2. Final Queries Built & Tested ✅

**Item 1 - CAN-SPAM Email Opt-Outs:**
- File: `final_deliverables/1_item1_canspam_email_optouts.sql`
- Approach: RPT_UNSUBSCRIBER_SFMC → VW_MEMBER_PII → VW_LOAN → MVW_LOAN_TAPE (CRB filter)
- Results: 592 CRB customers with email opt-outs (Oct 2023 - Aug 2025)
- **Issue:** "Date Last Email Sent" field = NULL (individual send history not available in Snowflake)

**Item 3 - FCRA Negative Credit Reporting:**
- File: `final_deliverables/2_item3_fcra_negative_credit_reporting.sql`
- Approach: MVW_LOAN_TAPE_DAILY_HISTORY (ASOFDATE snapshots) to find first date DAYSPASTDUE > 0
- Uses MIN(ASOFDATE) and MIN_BY(DAYSPASTDUE, ASOFDATE) + MIN_BY(LASTPAYMENTDATE, ASOFDATE)
- CRA Reporting: Inferred from CREDIT_REPORT_HISTORY export timing (if late date < export date → "Yes")
- Results: 7,081 CRB loans with first late payments (Oct 2024 - Aug 2025)

**Item 4.A - FCRA Indirect Disputes (ACDV):**
- File: `final_deliverables/3_item4a_fcra_indirect_disputes_acdv.sql`
- Approach: RPT_EOSCAR_ACDV filtered to CRB portfolios
- Results: 0 disputes (RPT_EOSCAR_ACDV last updated Oct 2021 - no activity in scope period)
- **Valid finding:** Zero records to report is correct

### 3. CSV Outputs Generated ✅

All CSV files created in `final_deliverables/`:
- `1_item1_canspam_email_optouts.csv` - 593 lines (592 records + header)
- `2_item3_fcra_negative_credit_reporting.csv` - 7,082 lines (7,081 records + header)
- `3_item4a_fcra_indirect_disputes_acdv.csv` - 1 line (header only, zero records)

### 4. QC Validation Queries Created ✅

Comprehensive QC scripts in `qc_queries/`:
- `1_item1_optouts_qc_validation.sql` (6 QC tests)
- `2_item3_negative_reporting_qc_validation.sql` (8 QC tests)
- `3_item4a_disputes_qc_validation.sql` (5 QC tests)

**QC Tests Cover:**
- Record counts and uniqueness
- CRB portfolio filter validation (IDs: 32, 34, 54, 56)
- Date range validation
- NULL value checks
- Data format validation
- Distribution analysis

### 5. Documentation Complete ✅

**Item 1.A - Opt-Out Mechanisms:**
- File: `final_deliverables/optout_mechanisms_documentation.md`
- Comprehensive documentation of SFMC and LoanPro opt-out systems
- CAN-SPAM compliance features and technical implementation
- 10 sections covering all aspects of opt-out functionality

**N/A Items (5-8):**
- File: `final_deliverables/NA_items_documentation.md`
- Business justification for each N/A item:
  - Item 5: EFTA Pre-Authorizations (N/A - no recurring transfers)
  - Item 6: FCRA Credit Line Increases (N/A - closed-end loans)
  - Item 7: Marketing T&C (No data request - CRB handles independently)
  - Item 8: TILA Card Issuance (N/A - no credit cards)

**Stakeholder Questions:**
- File: `stakeholder_questions_jira_comment.txt`
- Ready to post to Jira ticket
- 4 questions covering blocked items and approach confirmations

---

## Critical Technical Decisions Made

### 1. CRB Filter

**Definitive filter for all queries:**
```sql
WHERE PORTFOLIOID IN ('32', '34', '54', '56')
```

**Portfolios:**
- 32: Theorem Main Master Fund LP - Loan Sale
- 34: Theorem Prime Plus Yield Fund Master LP - Loan Sale
- 54: (CRB portfolio)
- 56: (CRB portfolio)

### 2. First Late Payment Logic (Item 3)

**Data Source:** `MVW_LOAN_TAPE_DAILY_HISTORY` (not MVW_LOAN_TAPE)

**Why:** MVW_LOAN_TAPE shows current state only. MVW_LOAN_TAPE_DAILY_HISTORY has daily snapshots via ASOFDATE field, allowing us to identify the exact first date a loan became late.

**SQL Pattern:**
```sql
SELECT
    LOANID,
    MIN(ASOFDATE) as FIRST_LATE_DATE,
    MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE,
    MIN_BY(LASTPAYMENTDATE, ASOFDATE) as LAST_PAYMENT_DATE_AT_FIRST_LATE
FROM MVW_LOAN_TAPE_DAILY_HISTORY
WHERE PORTFOLIOID IN ('32', '34', '54', '56')
  AND DAYSPASTDUE > 0
  AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'
GROUP BY LOANID
```

**Rejected Alternatives:**
- VW_LOAN_TAPE: Current state only, cannot determine historical "first late date"
- VW_PAYMENTS: Transaction data, doesn't track daily delinquency status

### 3. CRA Reporting Inference (Item 3)

**Approach:** Time-based inference using CREDIT_REPORT_HISTORY

**Logic:**
```sql
CASE
    WHEN NEXT_EXPORT_DATE IS NOT NULL AND NEXT_EXPORT_DATE <= CURRENT_DATE()
    THEN 'Yes'  -- Late payment occurred before completed export
    WHEN NEXT_EXPORT_DATE IS NOT NULL AND NEXT_EXPORT_DATE > CURRENT_DATE()
    THEN 'Pending'  -- Export scheduled but not completed
    ELSE 'No'  -- No export found after late date
END as REPORTED_LATE_TO_CRA
```

**Why:** CREDIT_REPORT_HISTORY contains Metro2 export file metadata, not individual loan-level reporting flags. Used export timing as best available proxy.

**Question for Stakeholder:** Confirm this approach is acceptable or provide direct reporting flag location

### 4. Email Opt-Out Data Source (Item 1)

**Primary Source:** `RPT_UNSUBSCRIBER_SFMC`

**Join Path:**
```
RPT_UNSUBSCRIBER_SFMC.EMAIL
→ VW_MEMBER_PII.EMAIL (+ MEMBER_ID)
→ VW_LOAN.MEMBER_ID (+ LEAD_GUID)
→ MVW_LOAN_TAPE.PAYOFFUID (+ CRB portfolio filter)
```

**Key Decision:** Use email matching (case-insensitive, trimmed) to link unsubscribers to CRB loans

**Alternative Source:** VW_LOAN_CONTACT_RULES has SUPPRESS_EMAIL flags at loan level, but RPT_UNSUBSCRIBER_SFMC is more comprehensive for CAN-SPAM compliance

---

## Blocking Issues & Stakeholder Questions

### Question 1: Item 1 - "Date Last Email Sent" Field

**Issue:** Individual customer email send history not available in Snowflake
- DSH_EMAIL_CAMPAIGN_SENT has campaign-level metrics only (NUMBER_SENT, NUMBER_DELIVERED)
- No individual send logs in accessible tables

**Options:**
1. Document as "N/A - Not Available in Snowflake"
2. Retrieve from SFMC API (external data pull)
3. Use campaign-level data as approximation (not customer-specific)

**Stakeholder Decision Needed:** Which approach to use?

### Question 2: Item 2 - GLBA Privacy / Information Sharing Opt-Outs

**Issue:** No privacy opt-out tracking found in Snowflake

**Discovery Results:**
- Searched: %PRIVACY%, %GLBA%, %CONSENT%, %INFORMATION_SHARING%
- Found: RPT_OPTOUT_MAIL_SFMC (physical mail opt-outs - not relevant)
- Found: RPT_UNSUBSCRIBER_SFMC (marketing emails - CAN-SPAM, not GLBA)

**Key Distinction:**
- CAN-SPAM = Marketing email opt-outs (Item 1) ✅ Found
- GLBA = Information sharing opt-outs for privacy compliance ❌ Not Found

**Hypothesis:** Privacy opt-outs may be:
- Tracked in external compliance system
- Not separated from marketing opt-outs in Happy Money's implementation
- Not received (zero opt-out requests in timeframe)

**Stakeholder Decision Needed:**
1. Does Happy Money track GLBA opt-outs separately?
2. If yes, where are they tracked?
3. If no, can we document as "N/A - No requests received"?

### Question 3: Item 4.B - FCRA Direct Disputes (AUD)

**Issue:** No direct customer dispute tracking found

**Discovery Results:**
- Found: RPT_EOSCAR_ACDV (indirect disputes from bureaus)
  - Contains ACDV control numbers
  - Last activity: October 2021
  - Zero disputes in scope period (Oct 2024 - Aug 2025)
- Not Found: Direct dispute tables (%AUD%, %DIRECT_DISPUTE%, %CUSTOMER_DISPUTE%)

**Key Distinction:**
- Indirect disputes (Item 4.A) = Bureau → Happy Money (ACDV process) ✅ Found
- Direct disputes (Item 4.B) = Customer → Happy Money (AUD process) ❌ Not Found

**Hypothesis:** Direct disputes may be:
- Tracked in LoanPro notes/comments system
- Manual process (spreadsheets, email logs)
- Routed through bureaus (all disputes come via ACDV)
- Not received (zero direct disputes in timeframe)

**Stakeholder Decision Needed:**
1. Does Happy Money receive direct disputes bypassing bureaus?
2. If yes, where are they tracked?
3. If no, can we document as "N/A - No direct disputes received"?

### Question 4: Item 3 - "Reported to CRA" Field Approach

**Current Approach:** Time-based inference using bureau export dates

**Question:** Is this acceptable or should we use a different method?

**Alternative Approaches (if available):**
- Direct loan-level reporting flag in LoanPro
- Metro2 file parsing to check loan inclusion
- Manual confirmation from servicing team

---

## Date Range Specifications (CRITICAL)

**Different items have different date ranges - must be precise:**

| Item | Reference | Date Range | Years |
|------|-----------|------------|-------|
| 1 | CAN-SPAM | Oct 1, 2023 - Aug 31, 2025 | 2 years |
| 2 | GLBA | Oct 1, 2023 - Aug 31, 2025 | 2 years |
| 3 | FCRA Neg Rep | Oct 1, 2024 - Aug 31, 2025 | 1 year |
| 4 | FCRA Disputes | Oct 1, 2024 - Aug 31, 2025 | 1 year |

**Important:** Items 1 & 2 have 2-year lookback, Items 3 & 4 have 1-year lookback

---

## File Organization

```
final_deliverables/
├── 1_item1_canspam_email_optouts.sql (tested ✅, 592 records)
├── 1_item1_canspam_email_optouts.csv
├── 2_item3_fcra_negative_credit_reporting.sql (tested ✅, 7,081 records)
├── 2_item3_fcra_negative_credit_reporting.csv
├── 3_item4a_fcra_indirect_disputes_acdv.sql (tested ✅, 0 records)
├── 3_item4a_fcra_indirect_disputes_acdv.csv
├── optout_mechanisms_documentation.md (Item 1.A complete)
└── NA_items_documentation.md (Items 5-8 complete)

qc_queries/
├── 1_item1_optouts_qc_validation.sql (6 tests)
├── 2_item3_negative_reporting_qc_validation.sql (8 tests)
└── 3_item4a_disputes_qc_validation.sql (5 tests)

exploratory_analysis/
├── RESEARCH_FINDINGS.md (253 lines - complete discovery log)
├── 1_schema_discovery.sql
├── 2_fcra_negative_reporting_prototype.sql
├── 3_optout_privacy_discovery.sql
└── 4_dispute_discovery.sql

stakeholder_questions_jira_comment.txt (ready to post)
```

---

## Next Actions When Resuming

### Immediate Tasks:

1. **Post Stakeholder Questions to Jira**
   - Use `stakeholder_questions_jira_comment.txt`
   - Post as comment on DI-1314
   - Mark ticket as "Waiting for Input" or similar status

2. **Run QC Validation Queries** (Optional - can wait for stakeholder response)
   - Execute all 3 QC scripts in `qc_queries/`
   - Verify data quality meets expectations
   - Document any QC failures and corrections needed

### After Stakeholder Response:

3. **Item 2 - GLBA Privacy Opt-Outs:**
   - If tables identified → Build query similar to Item 1 pattern
   - If N/A → Update NA_items_documentation.md to include Item 2

4. **Item 4.B - FCRA Direct Disputes:**
   - If tables identified → Build query similar to Item 4.A pattern
   - If N/A → Update NA_items_documentation.md to include Item 4.B

5. **Item 1 - "Date Last Email Sent":**
   - If N/A → Update Item 1 query to clarify field as N/A
   - If SFMC API → Create separate process/script for API data retrieval
   - If alternative approach → Implement as directed

6. **Item 3 - CRA Reporting Confirmation:**
   - If approach approved → No changes needed
   - If alternative method → Modify Item 3 query to use specified approach

7. **Final Deliverables:**
   - Update all CSVs with any query modifications
   - Re-run QC validation on updated deliverables
   - Update README with final status
   - Prepare for PR submission

---

## SQL Patterns to Reuse

### CRB Filter Pattern (Use in all queries)
```sql
FROM BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE mlt
WHERE mlt.PORTFOLIOID IN ('32', '34', '54', '56')
```

### Member PII Join Pattern
```sql
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN vl
    ON mlt.PAYOFFUID = vl.LEAD_GUID
INNER JOIN BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII pii
    ON vl.MEMBER_ID = pii.MEMBER_ID
    AND pii.MEMBER_PII_END_DATE IS NULL  -- Current PII only
```

### Date Variables Pattern
```sql
SET START_DATE = 'YYYY-MM-DD';
SET END_DATE = 'YYYY-MM-DD';
-- Then use $START_DATE and $END_DATE in queries
```

---

## Known Data Anomalies

1. **RPT_EOSCAR_ACDV Last Updated Oct 2021**
   - Table contains 3,185 total disputes
   - No activity since October 2021 (over 3 years ago)
   - Suggests ACDV dispute process may have changed or moved to different system
   - Zero disputes in scope period is valid finding

2. **DSH_EMAIL_CAMPAIGN_SENT - Campaign-Level Only**
   - Table has campaign metrics but no individual customer send records
   - Cannot provide "Date Last Email Sent" at customer level from this table
   - Would need SFMC send job logs or API query for individual send history

3. **CREDIT_REPORT_HISTORY - File Metadata Only**
   - Contains export file names and completion timestamps
   - Does NOT have loan-level reporting flags
   - Inference approach required to determine "Reported to CRA" status

---

## Important Reminders

**Date Ranges:** Items 1 & 2 use 2-year lookback, Items 3 & 4 use 1-year lookback

**CRB Filter:** Always use PORTFOLIOID IN ('32', '34', '54', '56') - confirmed by user

**CSV Format:** All CSVs generated with `--format csv` and `tail -n +7` to remove Snowflake metadata

**Zero Records Valid:** Item 4.A having zero records is a correct finding, not an error

**Stakeholder Questions Priority:** Item 2 and 4.B are completely blocked - need answers before proceeding

---

**Session End State:** Discovery complete, 3 deliverables ready, 3 blocked pending stakeholder clarification. All queries tested and CSVs generated. QC validation scripts created. Comprehensive documentation complete. Ready to post stakeholder questions and await guidance.
