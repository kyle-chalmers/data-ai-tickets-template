# GIACT Data Parsing Solution

## Overview
This solution provides comprehensive tools for extracting GIACT banking verification data from `ARCA.FRESHSNOW.MVW_HM_Verification_Responses`. GIACT data is embedded within the JSON `integrations` array.

## Key Features
- **Future-proof:** Supports all GIACT versions (`giact_%` pattern)
- **Optimized:** Uses materialized view for faster performance
- **Complete:** Extracts all available GIACT fields
- **Clean:** No ORDER BY statements for optimal performance
- **Focused:** Pure data extraction without business logic

## Quick Start
For immediate results, run the comprehensive parser:
```sql
snow sql -f "queries/comprehensive_giact_parser.sql" --format csv
```

## File Structure
```
giact_parsing_solution/
├── README.md                          # This documentation
├── 01_query_giact_data.sql            # Step 1: Query GIACT data from production
├── 02_deploy_giact_view.sql           # Step 2: Deploy view to DEVELOPMENT.FRESHSNOW
├── 03_qc_oscilar_giact_view.sql       # Step 3: QC the deployed view
├── 04_production_deployment.sql       # Step 4: Deploy to production environments
├── queries/
│   └── comprehensive_giact_parser.sql # Complete GIACT field extraction
└── sample_data/
    ├── 2786264.json                   # Sample JSON data
    ├── 2847525.json                   # Sample JSON data
    ├── 2901849.json                   # Sample JSON WITH giact_5_8 ⭐
    └── 2776363.json                   # Sample JSON data
```

## SQL Scripts

### 1. `comprehensive_giact_parser.sql` - Complete GIACT Data Extraction
**Purpose:** Extract all available GIACT fields from the JSON structure.

**Features:**
- All GIACT parameters and response fields (41 total extractions)
- Account age calculation in days
- Complete field mapping from JSON structure
- No business logic or risk assessment
- Future-proof with `giact_%` pattern
- Optimized with materialized view and no ORDER BY

**Usage:**
```sql
snow sql -f "queries/comprehensive_giact_parser.sql" --format csv
```

### 2. `01_query_giact_data.sql` - Step 1: Production Data Query
**Purpose:** Query GIACT data directly from production source.

**Features:**
- Raw SELECT statement from `ARCA.FRESHSNOW.MVW_HM_Verification_Responses`
- All 41 GIACT fields extracted from JSON
- Account age calculation in days
- No ORDER BY for optimal performance
- Future-proof with `giact_%` pattern

**Usage:**
```sql
snow sql -f "01_query_giact_data.sql" --format csv
```

### 3. `02_deploy_giact_view.sql` - Step 2: Development Environment Deployment
**Purpose:** Deploy GIACT parsing as a view in DEVELOPMENT.FRESHSNOW.

**Features:**
- Creates `DEVELOPMENT.FRESHSNOW.VW_OSCILAR_GIACT_DATA` view
- Uses production data from `ARCA.FRESHSNOW.MVW_HM_Verification_Responses`
- All 41 GIACT fields with proper column definitions
- Includes verification queries
- COPY GRANTS for permission preservation

**Usage:**
```sql
snow sql -f "02_deploy_giact_view.sql"
```

### 4. `03_qc_oscilar_giact_view.sql` - Step 3: Quality Control Validation
**Purpose:** Comprehensive QC of the deployed GIACT view.

**Features:**
- Data completeness analysis
- Duplicate detection
- Null value evaluation
- GIACT integration version validation
- Date range and temporal analysis
- Error message analysis
- Sample data preview

**Usage:**
```sql
snow sql -f "03_qc_oscilar_giact_view.sql" --format csv
```

### 5. `04_production_deployment.sql` - Step 4: Production Environment Deployment
**Purpose:** Deploy GIACT view to production environments using standardized template.

**Features:**
- Deploys to ARCA.FRESHSNOW → BUSINESS_INTELLIGENCE.BRIDGE → BUSINESS_INTELLIGENCE.ANALYTICS
- Environment variable switching (dev/prod)
- COPY GRANTS for permission preservation
- Verification queries included
- Follows standardized deployment pattern

**Usage:**
```sql
snow sql -f "04_production_deployment.sql"
```

## GIACT Data Structure

### JSON Location
GIACT data is located at:
```
DATA:data:integrations[n]:name LIKE 'giact_%'
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
- `CreatedDate` - GIACT processing timestamp
- `ItemReferenceId` - GIACT internal reference

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

## Account Age Calculation

All scripts include account age calculation:
```sql
CASE 
    WHEN giact.value:response:AccountAddedDate::TIMESTAMP IS NOT NULL
    THEN DATEDIFF(DAY, giact.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE())
    ELSE NULL
END as account_age_days
```

## Performance Optimizations

### Materialized View Usage
- **Data Source:** `ARCA.FRESHSNOW.MVW_HM_Verification_Responses`
- **Benefit:** Pre-computed materialized view for faster access
- **Structure:** APPLICATION_ID, BORROWER_ID, DATA (JSON)

### Query Optimizations
- **No ORDER BY:** All queries exclude ORDER BY for maximum performance
- **Flexible Filtering:** Uses `LIKE 'giact_%'` to support future versions
- **Efficient JSON Parsing:** Uses `LATERAL FLATTEN` for optimal performance

### Version Flexibility
```sql
-- Future-proof GIACT version matching
WHERE giact.value:name::VARCHAR LIKE 'giact_%'
```

## Technical Implementation

### JSON Parsing Method
```sql
FROM ARCA.FRESHSNOW.MVW_HM_Verification_Responses vr,
LATERAL FLATTEN(input => vr.DATA:data:integrations) giact
WHERE giact.value:name::VARCHAR LIKE 'giact_%'
```

### Field Extraction Pattern
```sql
-- Extract nested JSON fields
giact.value:parameters:Check:AccountNumber::VARCHAR as account_number,
giact.value:response:BankName::VARCHAR as bank_name,
```

## Data Availability
- **Total GIACT Records:** 8,556 integrations available
- **Current Version:** giact_5_8
- **Coverage:** All applications with GIACT verification data

## Usage Examples

### Basic Data Extraction:
```bash
snow sql -f "queries/comprehensive_giact_parser.sql" --format csv > all_giact_data.csv
```

### Specific Bank Filter:
```sql
-- Add WHERE clause to any query for filtering
AND UPPER(giact.value:response:BankName::VARCHAR) LIKE '%BMO%'
```

### Routing Number Filter:
```sql
-- Filter by specific routing number
AND giact.value:parameters:Check:RoutingNumber::VARCHAR = '071025661'
```

### Recent Accounts Only:
```sql
-- Filter for recently opened accounts
AND DATEDIFF(DAY, giact.value:response:AccountAddedDate::TIMESTAMP, CURRENT_DATE()) <= 30
```

## Troubleshooting

### Common Issues:
1. **No Results:** Verify GIACT integrations exist for applications
2. **JSON Parse Errors:** Check JSON structure in sample data
3. **Performance Issues:** Use specific filters to reduce data volume
4. **Null Values:** Some GIACT responses may have missing fields

### Debugging Commands:
```sql
-- Check available GIACT versions
SELECT DISTINCT giact.value:name::VARCHAR 
FROM ARCA.FRESHSNOW.MVW_HM_Verification_Responses vr,
LATERAL FLATTEN(input => vr.DATA:data:integrations) giact
WHERE giact.value:name::VARCHAR LIKE 'giact_%';

-- Count total GIACT records
SELECT COUNT(*) as total_giact_records
FROM ARCA.FRESHSNOW.MVW_HM_Verification_Responses vr,
LATERAL FLATTEN(input => vr.DATA:data:integrations) giact
WHERE giact.value:name::VARCHAR LIKE 'giact_%';
```

## Export Options

### CSV Export:
```bash
snow sql -f "queries/comprehensive_giact_parser.sql" --format csv > complete_giact_data.csv
```

### Database Table Creation:
```sql
CREATE TABLE my_schema.giact_data AS
SELECT * FROM (
    -- Insert any GIACT parser query here
);
```

---
**Solution Version:** 2.0  
**Last Updated:** August 14, 2025  
**Data Source:** ARCA.FRESHSNOW.MVW_HM_Verification_Responses  
**GIACT Versions Supported:** All (giact_%)