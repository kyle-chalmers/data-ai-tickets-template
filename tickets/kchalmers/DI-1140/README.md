# DI-1140: Identify Originated Loans Associated w/ Suspected Small Fraud Ring

## Overview
Investigation of potential small fraud ring associated with BMO Bank accounts using routing number 071025661, focusing on recently opened accounts (less than 30 days).

## Key Findings

### GIACT 5.8 Integration Analysis
- **Total Accounts Found:** 34 applications with GIACT verification data
- **Unique Customers:** 34 individual borrowers
- **BMO Bank Accounts:** 43 accounts identified
- **HIGH RISK Accounts:** 1 account (BMO + RT# 071025661 + opened ≤30 days)
- **MEDIUM RISK Accounts:** 42 accounts (BMO + RT# 071025661 + opened >30 days)

### Account Opening Timeline
- **Date Range:** December 9, 2024 to July 17, 2025
- **Most Recent:** July 17, 2025 (25 days ago)
- **Accounts Opened Last 30 Days:** 1 account

### Account Types
- **Consumer Checking:** 37 accounts (86%)
- **Business Checking:** 3 accounts (14%)

## High-Risk Account Details
**Application ID 2901849** (Kevin Woods):
- **Account Number:** 4853145303
- **Routing Number:** 071025661
- **Bank:** BMO BANK NA
- **Account Type:** Consumer Checking
- **Account Added:** July 17, 2025 ("Less Than 7 Days")
- **Risk Level:** HIGH RISK
- **SSN:** 185543797
- **Address:** 936 Brenham Ln, Matthews, NC 28105

## Technical Implementation

### Data Source
- **Primary:** `DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS`
- **Integration:** `giact_5_8` within JSON `integrations` array
- **Method:** LATERAL FLATTEN to extract nested JSON data

### SQL Queries Developed
1. **giact_5_8_fraud_investigation.sql** - Comprehensive extraction query
2. **giact_fraud_summary.sql** - Summary statistics and analysis
3. **giact_5_8_extraction_query.sql** - Initial exploratory query

### Key Data Points Extracted
- Customer information (name, SSN, address)
- Bank account details (account number, routing number, type)
- GIACT verification results (response codes, bank name)
- Account opening dates and age
- Fraud risk classification

## File Structure
```
tickets/kchalmers/DI-1140/
├── README.md                                    # This documentation
├── sample_json_files/                          # JSON samples from Oscilar
│   ├── 2786264.json
│   ├── 2847525.json
│   ├── 2901849.json                           # Contains giact_5_8 integration
│   └── 2776363.json
├── final_deliverables/
│   ├── giact_5_8_fraud_investigation.sql      # Main extraction query
│   ├── giact_fraud_summary.sql               # Summary analysis
│   ├── giact_fraud_ring_results.csv          # Full results dataset
│   └── results_data/
│       └── 1_rt_071025661_los_applications_results.csv  # Initial RT# analysis
└── exploratory_analysis/
    └── giact_5_8_extraction_query.sql         # Initial development query
```

## Fraud Investigation Criteria

### Risk Classification
- **HIGH RISK:** BMO Bank + RT# 071025661 + Account opened ≤30 days
- **MEDIUM RISK:** BMO Bank + RT# 071025661 + Account opened >30 days  
- **LOW RISK:** All other accounts

### Investigation Parameters
- **Target Bank:** BMO BANK NA (pattern: `%BMO%`)
- **Target Routing Number:** 071025661
- **Recency Threshold:** 30 days from account opening
- **Extended Search:** 45 days to catch edge cases

## Next Steps
1. **Manual Review:** Investigate HIGH RISK application 2901849 in detail
2. **Pattern Analysis:** Look for connections between MEDIUM RISK accounts
3. **Cross-Reference:** Compare with other fraud detection systems
4. **Monitoring:** Set up alerts for new BMO + 071025661 combinations

## SQL Query Usage

### Run Main Investigation Query
```sql
-- Execute comprehensive fraud investigation
snow sql -f "final_deliverables/giact_5_8_fraud_investigation.sql" --format csv
```

### Generate Summary Report  
```sql
-- Get summary statistics
snow sql -f "final_deliverables/giact_fraud_summary.sql" --format csv
```

## Technical Notes
- GIACT 5.8 integration provides real-time bank account verification
- JSON parsing uses Snowflake's LATERAL FLATTEN function
- Account opening dates sourced from GIACT `AccountAddedDate` field
- Bank names standardized through GIACT `BankName` response field

---
**Investigation Status:** Complete  
**Date:** August 11, 2025  
**Analyst:** K. Chalmers