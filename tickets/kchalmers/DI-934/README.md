# DI-934: List of Confirmed Fraud Loans and Repurchase Details

## Ticket Information
- **Type:** Data Pull
- **Status:** In Progress
- **Assignee:** kchalmers@happymoney.com
- **Jira Key:** DI-934

## Problem Description
Stakeholder requested a comprehensive analysis of confirmed fraud loans to understand:
1. All loans where fraud has been confirmed (first party or third party)
2. How many of those fraud loans have been repurchased by Happy Money (where current investor is PayOff)

## Requirements
**Output Columns Required:**
- LoanID
- Portfolio ID
- Portfolio Name
- Fraud Type (1st party fraud or 3rd party fraud)
- Fraud Confirmed Date
- Loan Status
- Loan Closed Date

## Final Files (Complete Analysis)
- **`final_query.sql`** - Final SQL query with flattened partner data and proper column ordering
- **`final_dataset.csv`** - Complete results dataset (482 unique fraud loans)

## Solution Approach
1. Expanded fraud criteria to include loans with fraud_confirmed_date OR investigation_results
2. Created binary indicators for each fraud portfolio type
3. Included all partners without filtering
4. Filtered to fraud-related portfolios only

## Key Findings
- **278 total loans** with fraud indicators
- **4 fraud portfolio types**: First Party Confirmed (90), Fraud Declined (158), Identity Theft (12), Pending Investigation (3)
- **Binary indicators** for precise fraud type analysis
- **All current investors included** without PayOff filtering

## Archive
Previous iterations stored in `/archive/` folder for reference.