# DI-1314: Item 2 - GLBA Privacy Notice / Opt-Out Data

**Status:** DATA NOT AVAILABLE

## Requirement

**Item 2: Privacy - GLBA / Privacy Notice / Opt Out**
**Date Range:** October 1, 2023 - August 31, 2025
**Scope:** CRB Originations Only

### Required Fields
- Unique Identifier (for the customer)
- Customer Name
- Date Privacy Notice Provided
- Date Opt-out Requested
- Date Opt-out Processed

## Investigation Summary

### Comprehensive Database Search Conducted
Searched all relevant schemas in Snowflake for GLBA privacy opt-out and privacy notice tracking:

**Schemas Searched:**
- BUSINESS_INTELLIGENCE.DATA_STORE
- BUSINESS_INTELLIGENCE.ANALYTICS
- BUSINESS_INTELLIGENCE.ANALYTICS_PII
- BUSINESS_INTELLIGENCE.PII
- BUSINESS_INTELLIGENCE.CRON_STORE
- RAW_DATA_STORE.LOANPRO

**Search Patterns Used:**
- `%PRIVACY%`
- `%GLBA%`
- `%CONSENT%`
- `%NOTICE%`
- `%DOCUMENT%`
- `%INFORMATION_SHARING%`

### Findings

**No GLBA Privacy Opt-Out Tables Found:**
- No tables exist for tracking GLBA information-sharing opt-out requests
- No tables exist for tracking privacy notice delivery dates
- No customer-level privacy consent fields found in core tables

**Related Tables Found (Not Applicable):**
- `RPT_UNSUBSCRIBER_SFMC`: Contains **marketing email** opt-outs (CAN-SPAM compliance, not GLBA)
- `RPT_OPTOUT_MAIL_SFMC`: Contains **postal mail** opt-outs (not information-sharing opt-outs)
- `SOURCE_COMPANY_DOCUMENT_ENTITY`: Company-level document storage (not customer-specific privacy notices)

### Key Distinction

**CAN-SPAM vs. GLBA:**
- **CAN-SPAM (Item 1)**: Marketing email unsubscribe requests → `RPT_UNSUBSCRIBER_SFMC` ✅ AVAILABLE
- **GLBA (Item 2)**: Information-sharing opt-out requests for privacy compliance → ❌ NOT AVAILABLE

## Possible Explanations

1. **External System Tracking**: GLBA privacy opt-outs may be tracked in a compliance system outside of LoanPro/Snowflake
2. **Manual Process**: Privacy opt-outs may be handled manually via email, phone, or mail with manual record-keeping
3. **Zero Requests**: Happy Money may not have received any GLBA information-sharing opt-out requests during the timeframe
4. **Combined with Marketing Opt-Outs**: Happy Money may not separate GLBA privacy opt-outs from general marketing opt-outs

## Recommendations

### Immediate Action Required
**Stakeholder must clarify:**
1. Does Happy Money track GLBA information-sharing opt-out requests separately from marketing opt-outs?
2. If yes, where is this data stored (external system, manual records, etc.)?
3. If no separate tracking exists, should this item be documented as:
   - N/A - No separate GLBA opt-out tracking exists
   - N/A - No opt-out requests received during timeframe
   - Use CAN-SPAM opt-outs as proxy for all opt-out requests

### Alternative Data Sources to Check
If data exists outside Snowflake:
- Compliance management systems
- Customer service ticketing systems
- Email archives (manual opt-out requests)
- Physical mail logs
- LoanPro notes/comments (unstructured data)

## Deliverable Status

**Current Status:** BLOCKED - Cannot proceed without stakeholder clarification

**Options:**
1. If data source identified → Create query and CSV output
2. If no tracking exists → Document as N/A with business justification
3. If zero requests → Document as valid finding with zero records

---

**Date Investigated:** 2025-10-15
**Investigator:** Kyle Chalmers
**Discovery Files:** `exploratory_analysis/3_optout_privacy_discovery.sql`
