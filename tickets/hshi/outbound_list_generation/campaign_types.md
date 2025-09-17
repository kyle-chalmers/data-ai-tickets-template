# Campaign Types & Configuration

## Campaign Summary Table

| Set Name | Lists | Destination System | Job | Primary Suppression |
|----------|-------|-------------------|-----|---------------------|
| **BI-2482: Collections & Recovery (GR)** |
| Call List | DPD3-14, DPD15-29, DPD30-59, DPD60-89, DPD90+, Blue, Due Diligence DPD3-89 | Genesys (Phone) | BI-2482 + BI-737 | Global + State Regulations + DNC Phone + Phone Test |
| SMS | Payment Reminder, Due Date, DPD3-44, TruStage DPD17/33 | Genesys (Text) | BI-2482 + BI-820 | Global + DNC Text + Autopay |
| GR Email | GR Email | Genesys (Email) | BI-2482 | Global + DNC Email |
| GR Physical Mail | DPD15 Control/Test, DPD75 Control/Test | Genesys (Mail) | BI-2482 + BI-2609 | Global + DNC Letter |
| Recovery Weekly | Recovery Weekly | Genesys (Mail) | BI-2482 | Global + DNC Letter (Tuesday only) |
| Recovery Monthly Email | Recovery Monthly Email | Genesys (Email) | BI-2482 | Global + DNC Email/Letter + State Limitations (1st Tuesday) |
| Remitter | DPD60+ Min Pay | Genesys (Text) | BI-2482 + BI-813 | Global + DNC Text |
| SIMM | DPD3-119 | SIMM Partner System | BI-2482 + DI-862 | Global + DNC Phone |
| SST | DPD3-119 | Genesys (Phone) | BI-2482 | Global + State Regulations + DNC Phone |
| **DI-986: Marketing & Customer Engagement (Funnel)** |
| Email Non-Opener SMS | AppAbandon, OfferShown, OfferSelected, DocUpload, ESign | Genesys (Text) | DI-749 + DI-986 | Global + DNC Text + Email Non-Opener Logic |
| Allocated Capital Partner | PartnerAllocated | Partner Email System | DI-986 | Global + Partner-Specific Rules |
| Prescreen Email | Prescreen Email Campaign | SFMC | DI-986 + DI-977 | Global + DNC Email + State Exclusions (NV, IA, MA) |
| PIF Email | PIF Email, 6M to PIF Email | SFMC via SFTP | DI-986 + DI-1049 | Global + DNC Email + Account/Customer Level |
| SMS Funnel Communication | Started, Credit Freeze, Offers Shown, Offer Selected, Doc Upload, Underwriting, Allocated, Loan Docs Ready | Genesys (Text) | DI-986 | Global + DNC Text + Application Journey Logic |
| AutoPaySMS | AutoPay Enrollment | Genesys (Text) | DI-986 | Global + DNC Text + AutoPay Status |

## Campaign Details

### BI-2482: Collections & Recovery (GR - Goal Realignment)

**Purpose**: Generates daily outbound contact lists for **collections and recovery** efforts targeting delinquent accounts.

**Key Features**:
- DPD-based segmentation (3-14, 15-29, 30-59, 60-89, 90+ days past due)
- Portfolio-specific rules (Blue FCU, USAlliance, MSU FCU, SST)
- A/B testing for physical mail campaigns
- Time-based campaigns (weekly/monthly recovery)
- Strict regulatory compliance (state-specific rules)

### DI-986: Marketing & Customer Engagement (Funnel)

**Purpose**: Generates daily outbound marketing lists for **customer engagement** and funnel communication campaigns.

**Key Features**:
- Application journey-based campaigns
- Email marketing integration with SFMC
- Customer lifecycle campaigns (PIF, 6M to PIF)
- Partner communication workflows
- Cross-channel engagement optimization

---

## Suppression Rules

### Global Suppression (All Campaigns)
- **Bankruptcy**: Active bankruptcy flags
- **Cease & Desist**: Via `VW_LOAN_CONTACT_RULES`
- **One-Time Payment (OTP)**: Pending payment requests
- **Loan Modification**: Recent modification requests
- **Natural Disaster**: ZIP codes in affected areas
- **Individual Suppression**: Manually suppressed accounts
- **Next Workable Date**: Future contact restrictions
- **3rd Party Placement**: Charge-off accounts with collection agencies

**Note**: `VW_LOAN_CONTACT_RULES` includes SMS opt-out from LoanPro (`SMS_CONSENT_LS = 'NO'`)

### Set-Level Suppression
- **State Regulations**: Minnesota, Massachusetts, DC compliance
- **Do Not Contact**: Phone, text, letter, email preferences
- **Delinquent Amount Zero**: Accounts with zero balances

### List-Level Suppression
- **Phone Test**: Exclude test accounts from production
- **Autopay**: Accounts with automatic payments
- **Remitter**: Accounts in remitter campaigns

### Funnel-Specific Suppression
- **DNC Preferences**: Text and email opt-outs
- **State Exclusions**: NV, IA, MA for credit union campaigns
- **Credit Policy**: Decline decisions, non-tier 1-3 customers
- **Account Level**: Email opt-outs, unsubscribes, delinquency, charge-offs
- **Customer Level**: Recent applications, active accounts, delinquency history

## Key Differences Between Jobs

| Aspect | BI-2482 (GR) | DI-986 (Funnel) |
|--------|--------------|-----------------|
| **Purpose** | Collections & Recovery | Marketing & Engagement |
| **Primary Focus** | Delinquent accounts | Application funnel |
| **Suppression Complexity** | High (regulatory compliance) | Medium (marketing preferences) |
| **Campaign Types** | DPD-based, recovery-focused | Journey-based, engagement-focused |
| **Data Sources** | Loan tape, collections data | Application data, marketing data |
| **Compliance Requirements** | Strict (state regulations) | Moderate (marketing regulations) |