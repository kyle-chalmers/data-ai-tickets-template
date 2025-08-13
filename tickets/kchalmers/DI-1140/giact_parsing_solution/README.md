# GIACT 5.8 Data Parsing Solution

## Overview
This solution provides comprehensive tools for extracting and analyzing GIACT banking verification data from `DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS`. GIACT data is embedded within the JSON `integrations` array as `giact_5_8` objects.

## Quick Start
For immediate results, run the simple extractor:
```sql
snow sql -f "queries/simple_giact_extractor.sql" --format csv
```

## File Structure
```
giact_parsing_solution/
├── README.md                          # This documentation
├── queries/
│   ├── comprehensive_giact_parser.sql # Full-featured extraction with analysis
│   └── simple_giact_extractor.sql     # Quick extraction with parameters
├── sample_data/
│   ├── 2786264.json                   # Sample JSON without giact_5_8
│   ├── 2847525.json                   # Sample JSON without giact_5_8  
│   ├── 2901849.json                   # Sample JSON WITH giact_5_8 ⭐
│   └── 2776363.json                   # Sample JSON without giact_5_8
└── results/
    └── giact_fraud_ring_results.csv   # Sample output from fraud investigation
```

## SQL Scripts

### 1. `comprehensive_giact_parser.sql` - Full-Featured Solution
**Purpose:** Complete GIACT data extraction with fraud analysis, summary statistics, and risk scoring.

**Features:**
- Extracts all GIACT 5.8 parameters and response fields
- Provides fraud risk scoring (HIGH/MEDIUM/LOW RISK)
- Generates summary statistics
- Includes verification code interpretations
- Creates detailed reports

**Usage:**
```sql
-- Run comprehensive analysis
snow sql -f "queries/comprehensive_giact_parser.sql" --format csv

-- Export complete dataset
snow sql -q "SELECT * FROM giact_enhanced ORDER BY fraud_risk_level, account_added_date DESC" --format csv > complete_giact_data.csv
```

**Customization:**
Edit these parameters at the top of the script:
```sql
SET routing_number_filter = '071025661';
SET bank_name_pattern = '%BMO%';
SET recent_account_threshold = 30;
```

### 2. `simple_giact_extractor.sql` - Quick & Easy Extraction  
**Purpose:** Fast, customizable GIACT data extraction for specific investigations.

**Features:**
- Simple parameter configuration
- Essential GIACT fields only
- Risk assessment included
- Fast execution

**Usage:**
```sql
snow sql -f "queries/simple_giact_extractor.sql" --format csv
```

**Customization:**
Edit the DECLARE section:
```sql
DECLARE routing_number_filter VARCHAR DEFAULT '071025661';
DECLARE bank_name_pattern VARCHAR DEFAULT '%BMO%';
DECLARE recent_days_threshold INTEGER DEFAULT 30;
DECLARE start_date DATE DEFAULT '2024-01-01';
DECLARE specific_applications VARCHAR DEFAULT '2901849,2847525';
```

## GIACT Data Structure

### JSON Location
GIACT 5.8 data is located at:
```
DATA:data:integrations[n]:name = 'giact_5_8'
DATA:data:integrations[n]:parameters    # Request sent to GIACT
DATA:data:integrations[n]:response      # Response from GIACT
```

### Key Fields Extracted

#### Request Parameters (`parameters` object):
- `Check:AccountNumber` - Bank account number  
- `Check:RoutingNumber` - Bank routing number
- `Customer:FirstName/LastName` - Customer name
- `Customer:TaxID` - Customer SSN
- `GAuthenticateEnabled/GVerifyEnabled` - GIACT service flags

#### Response Data (`response` object):
- `BankName` - Financial institution name
- `BankAccountType` - Account type (Consumer/Business Checking)
- `AccountAdded/AccountAddedDate` - When account was opened
- `VerificationResponse` - Account verification result code
- `CustomerResponseCode` - Customer verification result code
- `AccountResponseCode` - Account-specific response code
- `ErrorMessage` - Any error messages from GIACT

### Response Code Interpretations

#### Verification Response Codes:
- `1` = Account Verified
- `2` = Account Verified with Conditions  
- `3` = Account Not Verified
- `4` = Account Closed
- `5` = Account Not Found
- `6` = Unable to Verify

#### Customer Response Codes:
- `1` = Customer Verified
- `2` = Customer Verified with Conditions
- `3` = Customer Not Verified
- `4` = Customer Deceased
- `18` = Insufficient Information

## Fraud Investigation Use Cases

### 1. Routing Number Analysis
Find all accounts using specific routing number:
```sql
DECLARE routing_number_filter VARCHAR DEFAULT '071025661';
DECLARE bank_name_pattern VARCHAR DEFAULT NULL; -- All banks
```

### 2. Bank-Specific Investigation  
Find all accounts at specific bank:
```sql
DECLARE routing_number_filter VARCHAR DEFAULT NULL; -- All routing numbers
DECLARE bank_name_pattern VARCHAR DEFAULT '%BMO%';
```

### 3. Recent Account Analysis
Find recently opened accounts (suspicious activity):
```sql
DECLARE recent_days_threshold INTEGER DEFAULT 7; -- Last 7 days
DECLARE start_date DATE DEFAULT DATEADD(day, -30, CURRENT_DATE());
```

### 4. Specific Application Investigation
Analyze specific applications:
```sql
DECLARE specific_applications VARCHAR DEFAULT '2901849,2847525,2831679';
```

## Risk Assessment Logic

The scripts provide automatic risk scoring:

- **HIGH RISK:** Target bank + Target routing number + Recently opened account (≤30 days)
- **MEDIUM RISK:** Target bank + Target routing number + Older account (>30 days)  
- **LOW-MEDIUM RISK:** Target routing number only
- **LOW RISK:** All other accounts

## Sample Data Analysis

### Example: Application 2901849 (HIGH RISK)
- **Customer:** Kevin Woods (SSN: 185543797)
- **Account:** 4853145303 @ BMO BANK NA
- **Routing:** 071025661
- **Opened:** July 17, 2025 (25 days ago)
- **Type:** Consumer Checking
- **Verification:** Code 6 (Unable to Verify)
- **Risk Factors:** All three criteria met (BMO + 071025661 + Recent)

## Performance Notes

- **Data Source:** `DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS`
- **Recommended Warehouse:** `BUSINESS_INTELLIGENCE_LARGE`
- **JSON Parsing:** Uses `LATERAL FLATTEN` for optimal performance
- **Filtering Strategy:** Apply filters early to reduce processing time
- **Memory Usage:** Large result sets may require result pagination

## Technical Implementation Details

### JSON Parsing Method
```sql
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
LATERAL FLATTEN(input => DATA:data:integrations) giact_integration
WHERE giact_integration.value:name::VARCHAR = 'giact_5_8'
```

### Field Extraction Pattern
```sql
-- Extract nested JSON fields
giact_integration.value:parameters:Check:AccountNumber::VARCHAR as account_number,
giact_integration.value:response:BankName::VARCHAR as bank_name,
```

### Date Calculations
```sql
-- Calculate account age
DATEDIFF(DAY, account_added_date, CURRENT_DATE()) as days_since_opened
```

## Troubleshooting

### Common Issues:
1. **No Results:** Check if applications have `giact_5_8` integrations
2. **JSON Parse Errors:** Verify JSON structure in sample data
3. **Performance Issues:** Add more specific filters to reduce data volume
4. **Missing Fields:** Some GIACT responses may have null values

### Debugging Tips:
```sql
-- Check available integrations for an application
SELECT DISTINCT integration.value:name 
FROM DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS,
LATERAL FLATTEN(input => DATA:data:integrations) integration 
WHERE DATA:data:input:payload:applicationId = '2901849';
```

## Export Options

### CSV Export:
```bash
snow sql -f "queries/simple_giact_extractor.sql" --format csv > giact_results.csv
```

### JSON Export:
```bash
snow sql -f "queries/comprehensive_giact_parser.sql" --format json > giact_results.json
```

### Database Table:
```sql
CREATE TABLE my_database.my_schema.giact_results AS
SELECT * FROM giact_enhanced;
```

---
**Solution Version:** 1.0  
**Last Updated:** August 11, 2025  
**Compatible With:** Snowflake, DATA_SCIENCE.MODEL_VAULT.VW_OSCILAR_VERIFICATIONS