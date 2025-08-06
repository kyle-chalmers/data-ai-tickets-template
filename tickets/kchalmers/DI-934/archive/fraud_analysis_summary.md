# DI-934 Fraud Loans Analysis Summary

## Overview
Analysis of confirmed fraud loans and their repurchase status based on the executed query.

## Key Findings

### Dataset Summary
- **Total Records**: 620 rows
- **Unique Loans**: 91 loans
- **Data Issue**: Multiple portfolio assignments per loan (average 6.8 rows per loan)

### Loan Status Distribution
- **Charged Off**: 616 records (99.4%)
- **Active**: 4 records (0.6%)

### Repurchase Analysis
- **Not Repurchased**: 560 records (90.3%)
- **Repurchased by Happy Money**: 60 records (9.7%)

### Current Investor Distribution
Top investors holding fraud loans:
- **Alliant CU**: 208 records (33.5%)
- **Happy Money**: 74 records (11.9%)
- **First Tech FCU**: 71 records (11.4%)
- **Cross River Bank TM**: 49 records (7.9%)
- **Payoff FBO Alliant Credit Union**: 49 records (7.9%)
- **Veridian CU**: 39 records (6.3%)
- **GreenState CU**: 29 records (4.7%)
- **Cross River Bank TP**: 24 records (3.9%)
- **USAlliance FCU**: 22 records (3.5%)
- **Teachers FCU**: 20 records (3.2%)

### Data Quality Issues Identified
1. **Multiple Portfolio Assignments**: Same loan appears multiple times due to different portfolio categorizations
2. **Loan Duplication**: Loan 99949 appears 22 times, others appear 10+ times
3. **Mixed PayOff Entities**: Several PayOff-related entities identified in investor list

## Recommendations
1. **Deduplicate Results**: Create one row per loan by selecting primary portfolio or aggregating portfolio information
2. **Clarify Fraud Type Logic**: Business input needed to distinguish 1st party vs 3rd party fraud
3. **Validate Repurchase Logic**: Confirm which PayOff entities indicate repurchase by Happy Money

## Business Impact
- **91 unique confirmed fraud loans** identified
- **Mixed recovery status**: Majority charged off, few still active
- **Distributed ownership**: Fraud loans spread across multiple investors/partners