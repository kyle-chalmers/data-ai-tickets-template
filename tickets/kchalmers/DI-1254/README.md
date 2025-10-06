# DI-1254: Sale Files for Resurgent - BK Sale Evaluation

## Ticket Information
- **Jira Link:** https://happymoneyinc.atlassian.net/browse/DI-1254
- **Type:** Data Pull
- **Status:** In Progress
- **Assignee:** Kyle Chalmers
- **Branch:** `DI-1254_and_DI-1211`

## Business Context

### Objective
Generate standard debt sale files (loan-level + transaction history) for charged-off bankruptcy (BK) loans being evaluated for potential sale to Resurgent. This evaluation includes loans with bankruptcy filings that are not already placed with other debt buyers.

### Business Impact
Enables Resurgent to:
- Evaluate portfolio of BK loans for potential purchase
- Assess recovery potential based on bankruptcy status
- Analyze payment history and transaction patterns
- Price the portfolio appropriately

### Debt Sale Standards
This pull follows Happy Money's standard debt sale file format, ensuring consistency with previous sales to Bounce, Jefferson Capital, and other debt buyers.

## Deliverables

### SQL Files (Numbered for Execution Order)
1. **`1_bk_debt_sale_population.sql`** - Loan-level file (run first)
   - Creates temp table: `RESURGENT_BK_SALE_EVAL_2025`
   - Comprehensive loan data with PII, bankruptcy info, payment metrics

2. **`2_bk_debt_sale_transactions.sql`** - Transaction file (run second)
   - Creates temp table: `RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS`
   - Complete transaction history for population loans

### QC Queries (In `qc_queries/` Folder)
1. **`1_duplicate_loan_check.sql`** - Verify no duplicate records
2. **`2_record_count_summary.sql`** - Population and transaction counts
3. **`3_bankruptcy_distribution.sql`** - BK chapter and status analysis
4. **`4_exclusion_verification.sql`** - Validate exclusion criteria
5. **`5_transaction_validation.sql`** - Transaction file QC

### Output Files (To Be Generated)
- **`RESURGENT_BK_SALE_EVAL_2025.csv`** - Loan-level data
- **`RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS.csv`** - Transaction history

## Fraud Detection - Temporary Implementation

### IMPORTANT: VW_LOAN_FRAUD Placeholder

This query uses **inline fraud detection logic as a placeholder** until DI-1312 is deployed to production.

**Current Implementation:**
```sql
WITH cte_fraud_placeholder AS (
    -- Conservative inline fraud detection using:
    -- 1. Portfolio category = 'Fraud'
    -- 2. Sub-status containing 'Fraud'
    -- 3. CLS confirmed fraud tags (for legacy data)
    ...
)
```

**Future Migration (once DI-1312 deployed):**
```sql
-- Replace fraud placeholder with:
LEFT JOIN BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD vlf
    ON vl.LOAN_ID::TEXT = vlf.LOAN_ID::TEXT
WHERE vlf.IS_FRAUD = FALSE OR vlf.IS_FRAUD IS NULL
```

**Migration Steps:**
1. Locate `cte_fraud_placeholder` CTE in query (around line 50)
2. Comment out entire CTE
3. Add LEFT JOIN to VW_LOAN_FRAUD
4. Update WHERE clause to use `vlf.IS_FRAUD`
5. Remove inline fraud detection logic
6. Test and validate exclusion counts match

## Inclusion & Exclusion Criteria

### Inclusion Criteria
- **Status:** 'Charge off'
- **Data as of:** Most recent monthly loan tape
- **Chargeoff date:** On or before pull date
- **Recovery status:** NOT fully recovered (recoveries < principal at chargeoff)

### Exclusion Criteria
1. **Fraud Loans**
   - Source: Inline placeholder logic (future: VW_LOAN_FRAUD)
   - Conservative detection using portfolios, sub-statuses, CLS tags

2. **Deceased Borrowers**
   - Portfolio category = 'Deceased'
   - Bureau response reason = 'subjectDeceased'

3. **Active/Complete Settlements**
   - Settlement status IN ('Active', 'Complete')
   - Has settlement portfolio

4. **Existing Placements**
   - Placement status IN: Resurgent, Bounce, Jefferson Capital, FTFCU, ARS, Remitter

5. **Closed Loans**
   - Loan closed date IS NOT NULL

## Data Architecture

### Modern Views Used
Following DI-1312 modern view architecture:
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_BANKRUPTCY` - Bankruptcy data
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_DEBT_SETTLEMENT` - Settlement exclusions
- `BUSINESS_INTELLIGENCE.ANALYTICS.VW_LP_PAYMENT_TRANSACTION` - Payment history
- `BUSINESS_INTELLIGENCE.ANALYTICS_PII.VW_MEMBER_PII` - PII data
- `BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT` - Placement status

**Note:** No legacy lookup tables used - this query represents modern data architecture standards.

## Loan-Level File Data Fields

### PII Fields
- FIRSTNAME, LASTNAME, SSN
- STREETADDRESS1, STREETADDRESS2, CITY, STATE, ZIPCODE
- DATE_OF_BIRTH, EMAIL, PHONENUMBER

### Loan Identifiers
- LOANID (CLS legacy ID)
- LEGACY_LOAN_ID
- LEAD_GUID (universal identifier)
- LP_LOAN_ID (LoanPro ID)

### Financial Details
- UNPAIDBALANCEDUE (calculated: principal + interest - recoveries - waivers)
- CHARGEOFFDATE
- PRINCIPALBALANCEATCHARGEOFF
- INTERESTBALANCEATCHARGEOFF
- RECOVERIESPAIDTODATE
- LASTPAYMENTDATE, LASTPAYMENTAMOUNT

### Bankruptcy Information
- BANKRUPTCY_STATUS (Petition Filed, Discharged, Dismissed, etc.)
- CASE_NUMBER
- BANKRUPTCY_CHAPTER (7, 11, 13)
- BANKRUPTCYFILEDATE (Filing date)
- POC_REQUIRED (Proof of claim required)
- POC_DEADLINE_DATE
- POC_COMPLETED_DATE (Proof of claim filed date)
- DISCHARGE_DATE

### Loan Origination
- ORIGINATIONDATE, LOANAMOUNT, TERM
- INTERESTRATE, APR
- BUREAUFICOSCORE, EMPLOYMENTSTATUS, ANNUALINCOME

### Flags and Indicators
- SCRAFLAG (Y/N - SCRA protected)
- DECEASED_INDICATOR (TRUE/FALSE)
- FRAUD_INDICATOR (TRUE/FALSE - from placeholder)
- LOAN_CURRENT_PLACEMENT
- FIRST_PAYMENT_DEFAULT_INDICATOR

### Contact Rules
- SUSPEND_PHONE, SUSPEND_TEXT, SUSPEND_EMAIL, SUSPEND_LETTER
- CEASE_AND_DESIST

### Data Quality
- FRAUD_DATA_SOURCE (tracks fraud detection method)
- LOAN_CLOSED_DATE

## Transaction File Data Fields

### Transaction Identifiers
- TRANSACTION_ID
- PAYOFFUID (LEAD_GUID)
- LOANID

### Transaction Details
- LOAN_TRANSACTION_DATE
- POSTED_DATE
- LOAN_TRANSACTION_TYPE (Payment, Charge Off, Rate Change, etc.)
- DESCRIPTION (detailed transaction description)
- LOAN_TRANSACTION_AMOUNT

### Payment Breakdown
- PAYMENT_FLAG (TRUE for payments)
- LOAN_PRINCIPAL (principal portion)
- LOAN_INTEREST (interest portion)
- STARTING_BALANCE
- ENDING_BALANCE

### Event Flags
- POSTCHARGEOFFEVENT (TRUE if after chargeoff)
- CHARGEOFFEVENTIND (TRUE if chargeoff transaction)
- LOAN_REVERSED, LOAN_REJECTED, LOAN_CLEARED

### Context Fields (from population)
- LOAN_CURRENT_PLACEMENT
- BANKRUPTCY_STATUS, BANKRUPTCYCHAPTER, DISCHARGE_DATE
- SCRAFLAG, DECEASED_INDICATOR, FRAUD_INDICATOR
- PORTFOLIONAME, UNPAIDBALANCEDUE, CHARGEOFFDATE

## Assumptions Made

### 1. BK Loan Evaluation Criteria
**Assumption:** "BK Sale Evaluation" includes all charged-off loans, with bankruptcy information provided where available, but does not exclude loans without bankruptcy filings.

**Reasoning:** The ticket title specifies "BK Sale Evaluation" but the description requests "charged off loans" without specifying bankruptcy as a requirement. This suggests Resurgent wants to evaluate the full chargedoff portfolio including BK status as a data point.

**Impact:** Population includes both loans with and without bankruptcy filings. Bankruptcy fields will be NULL for loans without BK filings.

### 2. Data As Of Date
**Assumption:** Data is as of the most recent monthly loan tape (previous month-end).

**Reasoning:** Standard debt sale practice uses monthly tape for consistency and data stability.

**Impact:** Data reflects position as of last month-end, not real-time current state.

### 3. Fraud Detection Methodology
**Assumption:** Conservative fraud detection using multiple sources (portfolios, sub-statuses, CLS tags) until VW_LOAN_FRAUD is available.

**Reasoning:** DI-1312 VW_LOAN_FRAUD is not yet deployed. Inline logic matches DI-1312 design for consistent exclusions.

**Impact:** Fraud exclusions are conservative - may exclude borderline cases. Easy migration path once VW_LOAN_FRAUD deploys.

### 4. Placement Exclusion Logic
**Assumption:** Loans with ANY of these placement statuses are excluded:
- Resurgent, Bounce, Jefferson Capital, FTFCU, ARS, Remitter

**Reasoning:** These represent existing debt buyer relationships or internal placements (FTFCU). Including them would create conflicts.

**Impact:** Ensures clean portfolio without existing obligations.

### 5. Settlement Exclusion Categories
**Assumption:** Exclude loans where settlement status is 'Active' OR 'Complete', OR has settlement portfolio.

**Reasoning:** Active settlements represent ongoing payment arrangements. Complete settlements may still have reconciliation pending. Settlement portfolios indicate Happy Money is actively managing the debt.

**Impact:** Conservative exclusion prevents conflicts with existing settlement servicing.

### 6. Fully Recovered Definition
**Assumption:** Fully recovered = `RECOVERIESPAIDTODATE >= PRINCIPALBALANCEATCHARGEOFF`

**Reasoning:** If all chargedoff principal has been recovered, there's nothing left to sell.

**Impact:** Excludes loans with no remaining balance to recover.

### 7. Transaction History Scope
**Assumption:** Include ALL transactions (payments and other) for evaluation purposes, not just post-chargeoff.

**Reasoning:** Debt buyers need complete payment history to assess borrower payment patterns and recovery likelihood.

**Impact:** Transaction file includes full loan history from origination through current.

## Execution Instructions

### Prerequisites
- Snowflake CLI configured with proper authentication
- Access to BUSINESS_INTELLIGENCE_LARGE warehouse
- BUSINESS_INTELLIGENCE_PII role for PII access

### Step 1: Run Population Query
```bash
cd /Users/kchalmers/Development/data-intelligence-tickets
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/1_bk_debt_sale_population.sql
```
**Expected Runtime:** 5-10 minutes
**Output Table:** `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025`

### Step 2: Run Transaction Query
```bash
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/2_bk_debt_sale_transactions.sql
```
**Expected Runtime:** 10-15 minutes
**Output Table:** `BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS`

### Step 3: Run All QC Queries
```bash
# Duplicate checks
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/qc_queries/1_duplicate_loan_check.sql

# Record counts
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/qc_queries/2_record_count_summary.sql

# Bankruptcy distribution
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/qc_queries/3_bankruptcy_distribution.sql

# Exclusion verification
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/qc_queries/4_exclusion_verification.sql

# Transaction validation
snow sql -f tickets/kchalmers/DI-1254/final_deliverables/qc_queries/5_transaction_validation.sql
```

### Step 4: Export to CSV
```bash
# Population file
snow sql -q "SELECT * FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025" --format csv -o header=true -o timing=false > tickets/kchalmers/DI-1254/final_deliverables/RESURGENT_BK_SALE_EVAL_2025.csv

# Transaction file
snow sql -q "SELECT * FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS" --format csv -o header=true -o timing=false > tickets/kchalmers/DI-1254/final_deliverables/RESURGENT_BK_SALE_EVAL_2025_TRANSACTIONS.csv
```

### Step 5: Validate CSV Quality
```bash
# Check for proper headers and no extra rows
head -5 tickets/kchalmers/DI-1254/final_deliverables/RESURGENT_BK_SALE_EVAL_2025.csv
tail -5 tickets/kchalmers/DI-1254/final_deliverables/RESURGENT_BK_SALE_EVAL_2025.csv

# Verify record counts match
wc -l tickets/kchalmers/DI-1254/final_deliverables/*.csv
```

## Quality Control

### Expected QC Results

**1. Duplicate Checks (Should All Return 0)**
- No duplicate LOANIDs
- No duplicate LEAD_GUIDs
- No duplicate LP_LOAN_IDs
- No duplicate TRANSACTION_IDs

**2. Exclusion Verification (Should All Return 0)**
- Fraud loans in population: 0
- Deceased loans in population: 0
- Loans with excluded placement status: 0
- Closed loans in population: 0

**3. Data Integrity**
- Record count matches between population and transaction files (loan count)
- All loans in population have at least one transaction
- Transaction type distribution looks reasonable

**4. Bankruptcy Analysis**
- Chapter distribution (7, 11, 13, NULL)
- Status distribution (Petition Filed, Discharged, Dismissed, etc.)
- POC analysis (required, filed, completed)

### QC Validation Checklist
- [ ] No duplicate loan records
- [ ] All exclusion criteria verified (0 excluded loans in output)
- [ ] Bankruptcy data populated for loans with BK filings
- [ ] Transaction count per loan is reasonable
- [ ] Payment transaction totals reconcile
- [ ] CSV files have proper headers only (no extra rows)
- [ ] Record counts documented

## Known Limitations

### 1. Fraud Detection Placeholder
- Using inline logic until VW_LOAN_FRAUD (DI-1312) is deployed
- Conservative approach may exclude borderline cases
- Migration path documented for future update

### 2. CLS Legacy Data
- Some older loans may have incomplete LoanPro data
- CLS fraud tags used as fallback for pre-migration loans

### 3. Bankruptcy Data Completeness
- Bankruptcy data depends on external bureau updates
- Some recent filings may not be captured yet
- Manual verification recommended for critical cases

## Next Steps

### For Delivery to Resurgent
1. Review QC results and document any findings
2. Package CSV files with data dictionary
3. Coordinate delivery method (secure SFTP, etc.)
4. Provide contact for questions/clarification

### For Data Engineering
1. Monitor DI-1312 deployment status
2. Plan fraud detection migration when VW_LOAN_FRAUD available
3. Document any data quality patterns discovered

### For Future Debt Sales
1. This query can be reused as template
2. Update exclusion criteria as needed (placement statuses, etc.)
3. Adjust chargeoff date range for different evaluation periods

## Related Tickets
- **DI-1211**: Placement Data Quality Analysis (placement exclusion validation)
- **DI-1312**: VW_LOAN_FRAUD creation (fraud detection modernization)
- **DI-928**: Previous Theorem/Resurgent debt sale (reference pattern)
- **DI-931**: Bounce H2 2024 debt sale (reference pattern)
