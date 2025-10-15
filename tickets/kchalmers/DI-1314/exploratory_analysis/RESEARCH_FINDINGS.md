# DI-1314: Discovery Research Findings
**Date:** 2025-10-14
**Status:** Discovery Complete

## Executive Summary

All four required data sources have been identified and are ready for query development:

1. ✅ **Item 1 (CAN-SPAM)**: RPT_UNSUBSCRIBER_SFMC + VW_LOAN_CONTACT_RULES
2. ❓ **Item 2 (GLBA Privacy)**: No dedicated privacy opt-out tracking found - needs stakeholder clarification
3. ✅ **Item 3 (FCRA Negative Reporting)**: MVW_LOAN_TAPE_DAILY_HISTORY + CREDIT_REPORT_HISTORY
4. ✅ **Item 4 (FCRA Disputes)**: RPT_EOSCAR_ACDV (indirect disputes found, direct disputes TBD)

---

## Item 1: CAN-SPAM Marketing Email Opt-Outs

### Primary Table: `BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC`
**Status:** ✅ FOUND - Ready for query development

**Structure:**
- EMAIL (VARCHAR 255)
- DATEUNSUBSCRIBED (TIMESTAMP_NTZ)
- SOURCE (VARCHAR 255) - Values include "Subscriber_Preferences"

**Row Count:** 746,473 total unsubscribers

**Usage Notes:**
- Contains email opt-out/unsubscribe data from Salesforce Marketing Cloud
- DATEUNSUBSCRIBED will map to "Date Opt-out Requested/Processed"
- Need to join to member/loan data to get CRB loans only
- Join path: RPT_UNSUBSCRIBER_SFMC.EMAIL → VW_MEMBER_PII.EMAIL → VW_LOAN → MVW_LOAN_TAPE (PORTFOLIOID filter)

### Secondary Table: `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES`
**Status:** ✅ FOUND - Supplemental opt-out data

**Structure:**
- LOAN_ID (VARCHAR)
- CEASE_AND_DESIST (BOOLEAN)
- SUPPRESS_EMAIL (BOOLEAN)
- SUPPRESS_PHONE (BOOLEAN)
- SUPPRESS_TEXT (BOOLEAN)
- SUPPRESS_LETTER (BOOLEAN)
- CONTACT_RULE_START_DATE (TIMESTAMP_NTZ)
- CONTACT_RULE_END_DATE (TIMESTAMP_NTZ)
- SOURCE (VARCHAR)

**Usage Notes:**
- Loan-level contact suppression rules from LoanPro
- SUPPRESS_EMAIL = TRUE indicates email opt-out at loan level
- CONTACT_RULE_START_DATE maps to opt-out date
- Can be used as secondary opt-out source or validation

### Challenge: "Date Last Email Sent"
**Status:** ❓ Needs investigation

**Options Identified:**
- `BUSINESS_INTELLIGENCE.CRON_STORE.DSH_EMAIL_CAMPAIGN_SENT` - Contains campaign-level metrics but NO individual customer email send dates
- May need to query Salesforce Marketing Cloud API/logs for individual send history
- **Recommendation:** Clarify with stakeholder if this field is required or can be N/A

---

## Item 2: GLBA Privacy Notice / Information Sharing Opt-Outs

### Status: ❓ NO DEDICATED TABLE FOUND

**Discovery Results:**
- No tables found matching: %PRIVACY%, %GLBA%, %CONSENT%, %INFORMATION_SHARING%
- RPT_OPTOUT_MAIL_SFMC exists but is for **postal mail** opt-outs (physical mail), not privacy/information sharing
- VW_MEMBER_PII has EMAIL field but no privacy consent fields

**Key Distinction:**
- **CAN-SPAM (Item 1)**: Marketing email opt-outs → RPT_UNSUBSCRIBER_SFMC ✅
- **GLBA (Item 2)**: Information sharing opt-outs for privacy compliance → NOT FOUND ❓

**Hypothesis:**
- Privacy notices may be handled outside LoanPro/Snowflake (external compliance system)
- Happy Money may not track GLBA opt-outs separately from CAN-SPAM
- May need to consult Compliance team

**Recommendation:**
- Clarify with stakeholder: Does Happy Money receive GLBA information-sharing opt-out requests?
- If yes, where are they tracked?
- If no, document as "N/A - No opt-out requests received in timeframe"

---

## Item 3: FCRA Negative Credit Reporting (First Late Payments)

### Primary Table: `BUSINESS_INTELLIGENCE.DATA_STORE.MVW_LOAN_TAPE_DAILY_HISTORY`
**Status:** ✅ FOUND - Prototype query complete

**Structure:**
- LOANID, PAYOFFUID
- ASOFDATE (historical snapshot date)
- DAYSPASTDUE (days overdue)
- PORTFOLIOID (for CRB filter)
- All MVW_LOAN_TAPE fields available historically

**Usage:**
```sql
-- Find first date each loan went late (DAYSPASTDUE > 0) in scope period
SELECT LOANID,
       MIN(ASOFDATE) as FIRST_LATE_DATE,
       MIN_BY(DAYSPASTDUE, ASOFDATE) as DAYS_PAST_DUE_AT_FIRST_LATE
FROM MVW_LOAN_TAPE_DAILY_HISTORY
WHERE PORTFOLIOID IN ('32','34','54','56')
  AND DAYSPASTDUE > 0
  AND ASOFDATE BETWEEN '2024-10-01' AND '2025-08-31'
GROUP BY LOANID
```

**Status:** Prototype query complete in `2_fcra_negative_reporting_prototype.sql`

### Credit Bureau Reporting Table: `RAW_DATA_STORE.LOANPRO.CREDIT_REPORT_HISTORY`
**Status:** ✅ FOUND - For "Reported to CRA" field

**Structure:**
- ID (report ID)
- ENTITY_TYPE ("Entity.Loan")
- TIME_COMPLETED (when bureau export completed)
- FILE_NAME (e.g., "Loan-cbExport-5203131-20241101.zip")
- FILE_LINK (S3 path to export file)

**Usage Notes:**
- Contains credit bureau export files (Metro2 format)
- TIME_COMPLETED indicates when loan data was furnished to bureaus
- Latest exports: Jul 2025, Aug 2025, Oct 2025
- Can join by loan and time to determine if late payment was reported

**Challenge:**
- CREDIT_REPORT_HISTORY contains export file metadata, not individual loan reporting status
- May need to parse export files OR use time-based logic (if late payment occurred before export date → likely reported)
- **Recommendation:** Use time-based approach - if first late date < next credit report export date, mark as "Yes" for reported

---

## Item 4: FCRA Credit Disputes

### Item 4.A: Indirect Disputes (ACDV)

#### Primary Table: `BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV`
**Status:** ✅ FOUND - Ready for query development

**Structure:**
- ACDVCONTROLNUMBER (VARCHAR 255) - **ACDV Control #**
- ACCOUNTNUMBER (VARCHAR 255) - Loan account number
- DATERECEIVED (VARCHAR 255) - **Receipt Date**
- DATERESPONDED (VARCHAR 255) - **Resolution Date**
- ORIGINATOR (VARCHAR 255) - Bureau name (**Source of Dispute**)
  - Values: "EFX" (Equifax), "EXP" (Experian), "TUN" (TransUnion)
- CONSUMERFIRSTNAME, MIDDLENAME, LASTNAME - Borrower name
- DISPUTECODE (FLOAT) - Type of dispute
- RESPONSECODE (FLOAT) - Resolution code
- DATAFURNISHER (VARCHAR 255) - "Payoff Inc" or "Happy Money DBA Payoff Inc."

**Row Count:** 3,185 total ACDV disputes

**Date Format Warning:** Dates are stored as VARCHAR in format "YYYY-MM-DD" - need TO_DATE conversion

**Usage:**
```sql
SELECT
    ACCOUNTNUMBER as LOAN_NUMBER,
    CONSUMERFIRSTNAME || ' ' || LASTNAME as BORROWER_NAME,
    TO_DATE(DATERECEIVED, 'YYYY-MM-DD') as RECEIPT_DATE,
    ORIGINATOR as SOURCE_OF_DISPUTE,
    TO_DATE(DATERESPONDED, 'YYYY-MM-DD') as RESOLUTION_DATE,
    ACDVCONTROLNUMBER as ACDV_CONTROL_NUMBER
FROM BUSINESS_INTELLIGENCE.PII.RPT_EOSCAR_ACDV
WHERE TO_DATE(DATERECEIVED, 'YYYY-MM-DD') BETWEEN '2024-10-01' AND '2025-08-31'
```

**Next Step:** Join to MVW_LOAN_TAPE to filter for CRB portfolios only

### Item 4.B: Direct Disputes (AUD)

**Status:** ❓ NO TABLE FOUND

**Discovery Results:**
- No tables found matching: %AUD%, %DIRECT_DISPUTE%, %CUSTOMER_DISPUTE%
- RPT_EOSCAR_ACDV only contains **indirect** disputes from credit bureaus

**Hypothesis:**
- Direct disputes (customer → Happy Money) may be tracked in:
  - LoanPro notes/comments system
  - External case management system
  - Manual process (email, phone calls logged separately)
- AUD (Automated Universal Dataform) control numbers may not be in database

**Recommendation:**
- Clarify with stakeholder: Does Happy Money receive direct credit disputes from customers?
- If yes, where are they tracked?
- If no, document as "N/A - No direct disputes received in timeframe"
- Possible that all disputes come through bureaus (ACDV only)

---

## Summary of Query Development Status

| Item | Data Pull | Table(s) Found | Status | Next Action |
|------|-----------|---------------|--------|-------------|
| 1.A | Opt-out Mechanisms Documentation | N/A | ✅ Ready | Document LoanPro/SFMC opt-out process |
| 1.B | Marketing Email Opt-Outs | RPT_UNSUBSCRIBER_SFMC | ✅ Ready | Build final query |
| 2 | Privacy Opt-Outs | ❓ Not Found | ❓ Blocked | Clarify with stakeholder |
| 3 | Negative Credit Reporting | MVW_LOAN_TAPE_DAILY_HISTORY + CREDIT_REPORT_HISTORY | ✅ Ready | Complete query with CRA reporting logic |
| 4.A | Indirect Disputes (ACDV) | RPT_EOSCAR_ACDV | ✅ Ready | Build final query with CRB filter |
| 4.B | Direct Disputes (AUD) | ❓ Not Found | ❓ Blocked | Clarify with stakeholder |

---

## Stakeholder Questions for Clarification

1. **Item 1 - "Date Last Email Sent"**: Is individual customer email send history available from SFMC? Or can this field be N/A?

2. **Item 2 - GLBA Privacy Opt-Outs**:
   - Does Happy Money receive information-sharing opt-out requests separate from marketing opt-outs?
   - If yes, where are these tracked?
   - Are privacy notices tracked in the system?

3. **Item 4.B - Direct Disputes**:
   - Does Happy Money receive direct credit disputes from customers (bypassing bureaus)?
   - If yes, where are these tracked?
   - Should we only include ACDV (indirect) disputes if direct disputes don't exist?

4. **Item 3 - "Reported to CRA" Field**:
   - Confirm approach: Use credit report export dates to infer reporting status (if late date < export date → "Yes")?
   - Or is there a more direct loan-level reporting flag?

---

## Files Organization

**Discovery Queries:**
- `1_schema_discovery.sql` - General table searches
- `2_fcra_negative_reporting_prototype.sql` - ✅ Working prototype for Item 3
- `3_optout_privacy_discovery.sql` - Opt-out and privacy table searches
- `4_dispute_discovery.sql` - Dispute table searches

**Next Steps:**
1. Seek clarification on blocked items (2, 4.B, questions above)
2. Build final queries for ready items (1.B, 3, 4.A)
3. Create QC validation queries
4. Generate CSV outputs
5. Document N/A items with business justification

---

**Last Updated:** 2025-10-14 @ 22:00
**Discovery Phase:** COMPLETE
**Ready for Query Development:** Items 1.B, 3, 4.A (3 of 6 deliverables)
**Needs Clarification:** Items 1.A "last email sent", 2, 4.B (3 items blocked)
