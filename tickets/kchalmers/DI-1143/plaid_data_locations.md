# Plaid Data Locations in Oscilar JSON (applicationId: 1914384)

## Primary Plaid Data Objects

### 1. **bankAccounts** (Line 248-252)
- Contains `plaidAccessToken` 
- Location: `payload.bankAccounts[].plaidAccessToken`
- Line 250: `plaidAccessToken: "access-production-3be61fa9-eefd-4a95-99de-b743b84a17bf"`

### 2. **user** (Line 286-290)
- Contains `plaidAccessTokens` array
- Location: `payload.user.plaidAccessTokens[]`
- Line 288-289: Array of Plaid access tokens

### 3. **Plaid Asset Report Data** (Multiple Locations)
- **Line 13719**: `plaidAssetReportId` in response object
- **Line 13752**: `plaidAssetReportId` in leadGuid response  
- **Line 94260**: `plaidAssetReportId` in nested response
- **Line 117577**: `plaidAssetReportId` in items array
- **Line 140880**: `plaidAssetReportId` in nested items
- **Line 140912**: `plaidAssetReportId` in response details

### 4. **Plaid_Assets Service Call** (Line 13803)
- Location: `results[].name: "Plaid_Assets"`
- Contains full Plaid asset report response with accounts and transactions

### 5. **Parse_Plaid_Assets_Report_copy Service** (Line 37119)
- Location: `results[].name: "Parse_Plaid_Assets_Report_copy"`
- Line 37121: `HM_Plaid_Assets_items` array
- Line 50531: `plaid_account_id_array`
- Line 50540-50541: Parsed Plaid report results

### 6. **plaid_name_match Service** (Line 70910)
- Location: `results[].name: "plaid_name_match"`
- Line 70914: `plaid_name` parameter
- Contains name matching logic results

### 7. **Income_Verification_Model_Results** (Lines 161442-161841)
All Plaid verification fields:
- **Account Holder Data** (Lines 161442-161468):
  - `plaid_AccountHolderAddress_1` through `_5`
  - `plaid_AccountHolderEmails_1` through `_5`
  
- **Balance Checks** (Lines 161469-161474):
  - `plaid_BalanceCheck` (main)
  - `plaid_BalanceCheck_1` through `_5`
  
- **Name Verification** (Lines 161475-161481):
  - `plaid_BankName`
  - `plaid_NameCheck` (main)
  - `plaid_NameCheck_1` through `_5`
  
- **Transaction History** (Lines 161482-161487):
  - `plaid_TransactionHistory` (main)
  - `plaid_TransactionHistory_1` through `_5`
  
- **Account IDs** (Lines 161488-161499):
  - `plaid_account_id_1` through `_5`
  - `plaid_account_id_array`
  
- **Asset Report Details** (Lines 161500-161501):
  - `plaid_asset_report_date_last_updated`
  - `plaid_asset_report_id`
  
- **Name Matching Results** (Lines 161502-161511):
  - `plaid_name_match_1` through `_5`
  
- **Account Details** (Lines 161512-161830):
  - `plaid_results_Last4OfTheAccount_1` through `_5`
  - `plaid_results_accountHolderName_1` through `_5`  
  - `plaid_results_account_1` through `_5` (full account objects)
  
- **Transaction Data** (Lines 161831-161835):
  - `plaid_results_latest_transactions_1` through `_5`
  
- **Access Tokens** (Lines 161836-161840):
  - `plaid_token_1` through `_5`

### 8. **Workflow Steps with Plaid References** (Lines 69-191)
Plaid-related workflow steps:
- Line 69: `Plaid Assets Token Check`
- Line 75: `Plaid Assets Report Content Check`
- Line 87: `Plaid - Account 1 Check`
- Line 99-117: `Plaid - Account 1 Results Check` (multiple)
- Line 123: `Plaid - Account 2 Check`
- Line 129: `Plaid - Account 3 Check`
- Line 135: `Plaid - Account 4 Check`
- Line 141: `Plaid - Account 5 Check`
- Line 171-189: `Plaid Reconcilliation` (multiple)

### 9. **Failure Reasons** (Lines 70928-70963)
Contains Plaid-related failure messages:
- Line 70930-70933: Plaid transaction and name check failures
- Line 70945-70962: GIACT override messages mentioning "Plaid mismatch" and "no Plaid link"

## SQL Extraction Strategy

To extract this data from `DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS.DATA`:

```sql
-- Extract primary Plaid access tokens
JSON_EXTRACT_PATH_TEXT(DATA, 'payload', 'bankAccounts', 0, 'plaidAccessToken') as plaid_access_token,
JSON_EXTRACT_PATH_TEXT(DATA, 'payload', 'user', 'plaidAccessTokens', 0) as user_plaid_token,

-- Extract Plaid asset report IDs
JSON_EXTRACT_PATH_TEXT(DATA, 'results', 0, 'response', 'plaidAssetReportId') as plaid_asset_report_id,

-- Extract Income Verification Model Results
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_asset_report_id') as model_plaid_report_id,
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_BankName') as plaid_bank_name,
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_NameCheck') as plaid_name_check,
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_BalanceCheck') as plaid_balance_check,
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_TransactionHistory') as plaid_transaction_history,

-- Extract account details (for accounts 1-5)
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_account_id_1') as plaid_account_1,
JSON_EXTRACT_PATH_TEXT(DATA, 'Income_Verification_Model_Results', 'plaid_results_accountHolderName_1') as plaid_holder_name_1,
-- Repeat for accounts 2-5 as needed
```

## Key Findings

1. **Multiple Plaid Data Locations**: Plaid data appears in various parts of the JSON structure
2. **Primary Storage**: Most detailed Plaid data is in `Income_Verification_Model_Results` object
3. **Account Support**: System supports up to 5 Plaid accounts per application
4. **Verification Fields**: Includes name, balance, and transaction history checks
5. **Asset Reports**: Full asset report data with transactions stored in service call results