# DI-1314: Item 1.A - Opt-Out Mechanisms Documentation
**CRB Q3 2025 Compliance Testing - CAN-SPAM Compliance**
**Date:** 2025-10-14

## Overview

This document describes Happy Money's email marketing opt-out mechanisms and functionality in compliance with the CAN-SPAM Act of 2003.

---

## 1. Opt-Out Mechanism Overview

### Primary Opt-Out Method: Unsubscribe Link

**Location:** Footer of all marketing emails sent via Salesforce Marketing Cloud (SFMC)

**Functionality:**
- One-click unsubscribe link included in every marketing email
- Link directs customer to subscriber preferences page
- Customer can opt out of specific email types or all marketing communications
- No login or authentication required for opt-out
- Unsubscribe request processed immediately upon submission

**Technology Platform:** Salesforce Marketing Cloud (SFMC)

**Data Storage:** RPT_UNSUBSCRIBER_SFMC table in Snowflake data warehouse

---

## 2. Secondary Opt-Out Methods

### Customer Service Requests

Customers can request opt-out through:
- **Phone:** Customer service representatives can process opt-out requests
- **Email:** Customers can email support to request removal from marketing lists
- **Written Mail:** Physical mail requests are honored

**Processing Time:** Opt-out requests processed within 10 business days per CAN-SPAM requirements

**System Integration:** Customer service opt-outs are entered into LoanPro system via VW_LOAN_CONTACT_RULES suppression flags

---

## 3. Technical Implementation

### 3.1 SFMC Opt-Out Processing

**Subscriber Preferences Page:**
- Hosted by Salesforce Marketing Cloud
- Accessible via unsubscribe links in email campaigns
- Allows granular opt-out selections (by email type/category)
- Immediate processing - no delay or confirmation required

**Opt-Out Tracking:**
- SOURCE field: Typically "Subscriber_Preferences" or "_Subscribers"
- DATEUNSUBSCRIBED: Timestamp when opt-out was processed
- EMAIL: Customer email address requesting opt-out

**Data Sync:** SFMC opt-out data synced to Snowflake RPT_UNSUBSCRIBER_SFMC table for reporting

### 3.2 LoanPro Contact Rules Suppression

**System:** LoanPro loan management platform

**Table:** VW_LOAN_CONTACT_RULES

**Suppression Flags:**
- SUPPRESS_EMAIL: Email opt-out flag
- SUPPRESS_PHONE: Phone opt-out flag
- SUPPRESS_TEXT: SMS/text opt-out flag
- SUPPRESS_LETTER: Physical mail opt-out flag
- CEASE_AND_DESIST: Complete contact opt-out

**Application:**
- Contact rules applied at loan level
- CONTACT_RULE_START_DATE: When suppression becomes active
- CONTACT_RULE_END_DATE: NULL for active suppressions
- Suppressions respected across all communication channels

---

## 4. Opt-Out Scope and Coverage

### What Marketing Communications Are Affected:

**Email Marketing:** (Primary scope for CAN-SPAM)
- Pre-qualification offers
- Promotional campaigns
- Product announcements
- Educational content
- Newsletter communications

**Multi-Channel Suppressions:**
Customers can opt out of:
- Email marketing
- Phone marketing calls
- SMS/text messages
- Physical direct mail

### What Communications Continue:

The following communications are **transactional** and continue even after opt-out:
- Loan servicing communications (payment reminders, due date notices)
- Account notifications (payment confirmations, late payment notices)
- Legally required disclosures
- Fraud alerts and security notifications
- Response to customer-initiated inquiries

**CAN-SPAM Exemption:** Transactional/relationship messages are exempt from CAN-SPAM opt-out requirements

---

## 5. Compliance Features

### CAN-SPAM Act Compliance:

✅ **Clear and Conspicuous Opt-Out Mechanism**
- Unsubscribe link in every marketing email
- Located in email footer per industry standard
- Clear labeling ("Unsubscribe" or "Manage Preferences")

✅ **Easy and Simple Opt-Out Process**
- One-click unsubscribe - no login required
- No fees, costs, or personal information requests
- No barriers or unnecessary steps

✅ **Timely Processing**
- SFMC opt-outs processed immediately
- Customer service opt-outs processed within 10 business days
- Maximum processing time complies with CAN-SPAM 10-day requirement

✅ **Honoring Opt-Out Requests**
- Suppression lists actively maintained
- Email service provider (SFMC) automatically excludes opted-out addresses
- LoanPro contact rules prevent suppressed communications

✅ **Permanent Opt-Out**
- No automatic re-subscription
- Opt-outs remain in effect unless customer explicitly re-subscribes
- Historical opt-out records maintained for compliance

---

## 6. Data Sources and Reporting

### Primary Opt-Out Data Source:

**Table:** `BUSINESS_INTELLIGENCE.PII.RPT_UNSUBSCRIBER_SFMC`

**Fields:**
- EMAIL: Customer email address
- DATEUNSUBSCRIBED: Timestamp of opt-out
- SOURCE: Opt-out source (e.g., "Subscriber_Preferences")

**Total Records:** 746,473 unsubscribers (all-time)

**CRB Scope (Oct 2023 - Aug 2025):** 592 CRB customers opted out

### Secondary Opt-Out Data Source:

**Table:** `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_CONTACT_RULES`

**Fields:**
- LOAN_ID: Loan identifier
- SUPPRESS_EMAIL: Email suppression flag
- CONTACT_RULE_START_DATE: Suppression effective date
- SOURCE: Suppression source system

**Purpose:** Loan-level suppression enforcement

---

## 7. Monitoring and Maintenance

### Regular Monitoring:

- **Opt-Out List Synchronization:** Daily sync between SFMC and Snowflake
- **Suppression List Review:** Monthly review of suppression effectiveness
- **Bounce and Complaint Monitoring:** Tracking of email bounces and spam complaints
- **Compliance Audits:** Periodic review of opt-out mechanisms and processing times

### List Hygiene:

- Invalid email addresses removed from active marketing lists
- Hard bounces automatically suppressed
- Spam complaint triggers immediate suppression
- Duplicate email addresses deduplicated before sends

---

## 8. Process for Re-Subscription

### Customer-Initiated Re-Subscription:

Customers who previously opted out can re-subscribe through:
- **Email Preference Center:** If they saved the link
- **Customer Service:** Contacting support to request re-subscription
- **Website Form:** Marketing communications opt-in checkboxes on website

**Important:** Happy Money does NOT automatically re-subscribe customers. Re-subscription must be customer-initiated and explicit.

---

## 9. Cross-Channel Integration

### Suppression Across Systems:

**SFMC → LoanPro:**
- Email opt-outs in SFMC synced to LoanPro
- Ensures suppression honored across all touchpoints

**LoanPro → SFMC:**
- Customer service opt-outs entered in LoanPro
- Synced to SFMC suppression lists

**Result:** Unified suppression across all customer communication channels

---

## 10. Audit Trail and Record Keeping

### Opt-Out Record Retention:

**Duration:** Indefinite retention for compliance purposes

**Audit Fields:**
- Opt-out request date and time
- Customer email address
- Source of opt-out request
- Processing confirmation

**Purpose:**
- Compliance audits and regulatory reviews
- Dispute resolution
- Historical analysis and reporting

**Accessibility:** Opt-out data queryable via Snowflake for compliance teams

---

## Summary

Happy Money's email marketing opt-out mechanisms comply with CAN-SPAM Act requirements through:

1. ✅ Clear, conspicuous opt-out links in all marketing emails
2. ✅ Simple one-click unsubscribe process with no barriers
3. ✅ Immediate to 10-day processing timeframe
4. ✅ Permanent opt-out unless customer re-subscribes
5. ✅ Multi-channel opt-out options (email, phone, mail)
6. ✅ Comprehensive tracking and audit trail
7. ✅ Cross-system integration for suppression enforcement

**For CRB Compliance Testing:** See Item 1.B deliverable (CSV file) for list of 592 CRB customers who opted out between October 1, 2023 - August 31, 2025.

---

**Prepared By:** Data Intelligence Team
**Review Date:** 2025-10-14
**Related Deliverable:** Item 1.B - CAN-SPAM Email Opt-Outs CSV
