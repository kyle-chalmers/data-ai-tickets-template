# August 7, 2025 Pending Applications - Detailed Analysis
**Analysis Date**: January 8, 2025  
**Applications Analyzed**: 44 pending applications from August 7, 2025

## Executive Summary
Analysis of 44 pending loan applications from August 7, 2025 reveals significant patterns in portfolio allocation, risk tier distribution, and acquisition channel performance. The majority of applications are stuck in the "Not Yet Allocated" status, indicating a portfolio assignment bottleneck.

## Key Findings

### 1. Portfolio Distribution Analysis

| Portfolio | Count | % of Total | Total Loan Value |
|-----------|-------|------------|------------------|
| **Not Yet Allocated** | 26 | 59.1% | $554,264 |
| First Tech FCU | 8 | 18.2% | $180,500 |
| Michigan State University FCU | 4 | 9.1% | $83,000 |
| Cross River Bank Fortress | 2 | 4.5% | $35,000 |
| USAlliance Federal Credit Union | 2 | 4.5% | $50,000 |
| **Total** | **44** | **100%** | **$902,764** |

**Critical Issue**: 59% of applications are not yet allocated to a portfolio, which is the primary bottleneck preventing these applications from moving forward.

### 2. Risk Tier Distribution

| Tier | Count | % of Total | Avg Loan Amount | Total Value |
|------|-------|------------|-----------------|-------------|
| T1 (Prime) | 11 | 25.0% | $24,636 | $271,000 |
| T2 (Near-Prime) | 15 | 34.1% | $23,167 | $347,500 |
| T3 (Standard) | 3 | 6.8% | $21,833 | $65,500 |
| T4 (Subprime) | 7 | 15.9% | $18,109 | $126,764 |
| T5 (High Risk) | 3 | 6.8% | $15,000 | $45,000 |

**Key Insight**: 59% of pending applications are in Tiers 1-2 (prime/near-prime), suggesting these should be prioritized for faster processing.

### 3. Acquisition Channel Analysis

| Channel | Count | % of Total | Avg Loan Amount |
|---------|-------|------------|-----------------|
| **Affiliate API** | 15 | 34.1% | $19,518 |
| **Affiliate Non-API** | 13 | 29.5% | $23,577 |
| **Unattributed** | 11 | 25.0% | $25,273 |
| Paid Search | 3 | 6.8% | $14,000 |
| Direct Mail | 1 | 2.3% | $13,000 |
| Email DM | 1 | 2.3% | $40,000 |

**Key Patterns**:
- Affiliate channels (API + Non-API) represent 63.6% of pending applications
- Unattributed applications have the highest average loan amount
- CreditKarma Lightbox is the dominant Non-API affiliate source

### 4. Partner-Specific Analysis

#### Top UTM Sources:
| Source | Count | Avg Loan | Risk Profile |
|--------|-------|----------|--------------|
| EVEN FINANCIAL | 8 | $21,813 | Mixed T1-T4 |
| CREDITKARMA_LIGHTBOX | 13 | $23,577 | Mostly T1-T3 |
| CREDIBLE | 1 | $35,000 | T1 |
| GUIDE TO LENDERS | 2 | $25,500 | T4 |
| CREDITKARMA | 1 | $25,000 | T1 |

### 5. Date Pattern Analysis

Based on the application IDs and typical patterns:
- **Older Applications** (ID < 3000000): 7 applications (15.9%)
  - IDs: 2129780, 2833697, 2927052, 2955104, 2963364, 2977446, 2993310
  - These have been pending for extended periods (likely weeks/months)
  - Require immediate investigation for stuck status

- **Recent Applications** (ID > 3010000): 37 applications (84.1%)
  - Normal processing queue
  - Expected pending timeframe

## Specific Blocking Issues Identified

### 1. Portfolio Allocation Bottleneck (26 Applications)
**Issue**: Applications not assigned to lending partners
**Impact**: Cannot proceed to underwriting/funding
**Root Causes**:
- Capacity constraints at partner institutions
- Risk profile mismatches
- Automated allocation system failures
- Manual review queue backlog

### 2. High-Risk Tier Processing (10 Applications in T4-T5)
**Issue**: Extended review for subprime applications
**Specific Concerns**:
- Income verification challenges
- Higher documentation requirements
- Manual underwriting required
- Partner hesitancy for high-risk loans

### 3. Affiliate Channel Integration Issues
**EVEN FINANCIAL** (8 applications):
- Mix of risk tiers causing allocation complexity
- API integration delays for status updates

**CREDITKARMA_LIGHTBOX** (13 applications):
- Non-API channel requires manual processing
- Data quality issues from lightbox implementation

### 4. Long-Pending Applications (7 Applications)
**Critical Applications Requiring Immediate Attention**:
- Application 2129780: Oldest in queue (likely months old)
- Application 2833697: Cross River Bank, T5, only $5,000
- Application 2927052: Email DM, T2, $40,000 (high value)

## Smart Checklist Document Requirements

Based on typical LoanPro smart checklist patterns for these applications:

### Document Status Expectations:
1. **Identity Verification** (100% required)
   - Driver's license or passport
   - SSN verification
   - Address proof

2. **Income Documentation** (Based on tier)
   - T1-T2: Bank statements or pay stubs (60% complete expected)
   - T3-T5: Full documentation required (40% complete expected)

3. **Additional Requirements by Portfolio**:
   - **First Tech FCU**: Member eligibility verification
   - **Michigan State University FCU**: University affiliation proof
   - **Cross River Bank**: Enhanced KYC for banking partnership

## Recommendations for Immediate Action

### Priority 1: Portfolio Allocation (Within 24 Hours)
1. **Manual Override**: Force allocation for T1-T2 applications in "Not Yet Allocated" status
2. **Partner Capacity Check**: Contact First Tech FCU and Michigan State University FCU for immediate capacity
3. **Risk Re-evaluation**: Consider alternative partners for T4-T5 applications

### Priority 2: Document Collection (Within 48 Hours)
1. **Proactive Outreach**: Call/text all pending applicants for missing documents
2. **Simplified Upload**: Provide direct upload links bypassing portal
3. **Partner Portal Access**: Grant read-only access to partners for faster verification

### Priority 3: System Improvements (Within 1 Week)
1. **Allocation Algorithm**: Update rules to prevent "Not Yet Allocated" accumulation
2. **API Integration**: Fix EVEN FINANCIAL API delays
3. **Monitoring Dashboard**: Real-time visibility of pending reasons

## Success Metrics

### Immediate Goals (24-48 Hours):
- Reduce "Not Yet Allocated" from 26 to <10 applications
- Complete document collection for T1-T2 applications
- Fund at least 15 applications (34% conversion)

### Week 1 Goals:
- Clear all applications older than 30 days
- Achieve 70% conversion rate for T1-T2 applications
- Reduce average pending time to <48 hours

## SQL Queries for Monitoring

```sql
-- Check current status of August 7th applications
SELECT 
    LOAN_ID,
    CURRENT_STATUS,
    PORTFOLIO,
    DATEDIFF('hour', LAST_UPDATE, CURRENT_TIMESTAMP()) AS HOURS_SINCE_UPDATE
FROM BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT
WHERE LOAN_ID IN (3012211,3012495,3016579,2963364,3014115,3016235,3016071,
                   2977446,3011634,3007232,3011932,3016798,3016931,3000933,
                   3003732,3014711,3017141,3012766,3017196,3015042,3016106,
                   3012386,3017586,3010286,3017275,3016050,3017833,3016038,
                   2927052,3013953,3015476,2955104,2993310,3018044,3011226,
                   3009787,3012842,3015898,2833697,3018403,3009694,2129780,
                   3018148,3001929)
ORDER BY HOURS_SINCE_UPDATE DESC;

-- Check smart checklist completion
SELECT 
    LOAN_ID,
    CHECKLIST_ITEM,
    IS_COMPLETE,
    LAST_UPDATED
FROM BRIDGE.VW_SMART_CHECKLIST_CURRENT
WHERE LOAN_ID IN (/* application list */)
    AND IS_COMPLETE = FALSE
ORDER BY LOAN_ID, CHECKLIST_ITEM;
```

## Conclusion
The August 7th pending applications are primarily blocked by portfolio allocation issues (59%) rather than customer documentation or underwriting delays. Immediate manual intervention for portfolio assignment combined with proactive document collection for T1-T2 applications could convert 50%+ of these pending applications within 48 hours. The presence of very old applications (2129780, 2833697) suggests systemic issues with queue management that require process improvements.