# DI-1314: Not Applicable (N/A) Items Documentation
**CRB Q3 2025 Compliance Testing**
**Date:** 2025-10-14

## Overview

This document provides business justification for items marked as "Not Applicable" (N/A) in the CRB Round 3 2025 Compliance Testing data request.

---

## Item 5: EFTA - Pre-Authorizations (Ref 4.A)

**Status:** N/A

**Regulation:** Electronic Fund Transfer Act (EFTA)

**Requirement:** Documentation and data related to pre-authorized electronic fund transfers

**Business Justification:**
Happy Money's closed-end installment loan products do not involve recurring pre-authorized electronic fund transfers that would trigger EFTA pre-authorization requirements. Loan payments may be set up via AutoPay, but these are standard recurring ACH debits governed by NACHA rules rather than EFTA pre-authorization requirements.

**Confirmation:** Marked "N/A" in source compliance testing spreadsheet

---

## Item 6: FCRA - Credit Line Increases (Ref 5.A)

**Status:** N/A

**Regulation:** Fair Credit Reporting Act (FCRA)

**Requirement:** Data related to credit line increases offered to existing customers

**Business Justification:**
Happy Money offers **closed-end installment loans** with fixed principal amounts determined at origination. These loan products do not include revolving credit features or credit line increase capabilities. Credit line increases are a feature of revolving credit products (credit cards, lines of credit) which Happy Money does not offer through the CRB partnership.

**Product Type:** Closed-end installment loans (fixed term, fixed principal amount)

**Confirmation:** All rows marked "N/A" in source compliance testing spreadsheet

---

## Item 7: Marketing T&C (Terms & Conditions)

**Status:** No Data Request - Performed Without Data

**Regulation:** Marketing compliance and consumer protection

**Requirement:** Review of marketing terms and conditions

**Business Justification:**
Per the source compliance testing spreadsheet instructions, this item is to be "performed without data request." This indicates that CRB will conduct their marketing T&C review through other means (e.g., website review, marketing material samples, policy documentation) rather than requiring a data pull from Happy Money systems.

**Action Required:** None - CRB will handle independently

---

## Item 8: TILA - Card Issuance (Ref 8.A)

**Status:** N/A

**Regulation:** Truth in Lending Act (TILA) - Credit Card Requirements

**Requirement:** Data related to credit card issuance and Truth in Lending disclosures

**Business Justification:**
Happy Money does not issue credit cards through the CRB partnership. The CRB-originated loans are **closed-end installment loans**, not open-end revolving credit (credit cards). TILA credit card issuance requirements (Regulation Z provisions specific to credit cards) do not apply to installment loan products.

**Product Type:** Closed-end installment loans
**Not Applicable:** Credit card-specific TILA requirements

**Note:** TILA still applies to installment loans, but different disclosure requirements apply (APR, payment schedule, total of payments, etc.) which are handled during loan origination, not in this compliance testing context.

---

## Summary Table

| Item | Reference | Regulation | Status | Reason |
|------|-----------|------------|--------|--------|
| 5 | 4.A | EFTA Pre-Authorizations | N/A | No recurring pre-authorized transfers |
| 6 | 5.A | FCRA Credit Line Increases | N/A | Closed-end loans - no credit line increases |
| 7 | - | Marketing T&C | No Data Request | Performed independently by CRB |
| 8 | 8.A | TILA Card Issuance | N/A | No credit card products |

---

## Applicable Items (For Context)

The following items **are applicable** and have deliverables:

| Item | Reference | Status | Records |
|------|-----------|--------|---------|
| 1.A | Documentation | ✅ See opt-out mechanisms document | N/A |
| 1.B | CAN-SPAM Email Opt-Outs | ✅ Delivered | 592 |
| 2 | GLBA Privacy Opt-Outs | ❓ Pending clarification | TBD |
| 3 | FCRA Negative Credit Reporting | ✅ Delivered | 7,081 |
| 4.A | FCRA Indirect Disputes (ACDV) | ✅ Delivered | 0 |
| 4.B | FCRA Direct Disputes (AUD) | ❓ Pending clarification | TBD |

---

**Prepared By:** Data Intelligence Team
**Review Date:** 2025-10-14
**Next Review:** As needed for CRB submission
