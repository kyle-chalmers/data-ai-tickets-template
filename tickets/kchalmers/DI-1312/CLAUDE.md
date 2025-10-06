# DI-1312: VW_LOAN_FRAUD Technical Context for AI Assistance

## Overview
VW_LOAN_FRAUD consolidates fraud loan data from 3 sources into single source of truth. Deployed across FRESHSNOW → BRIDGE → ANALYTICS layers following 5-layer architecture.

## Data Sources
1. **Custom Fields** (BUSINESS_INTELLIGENCE.BRIDGE.VW_LMS_CUSTOM_LOAN_SETTINGS_CURRENT): 414 loans with FRAUD_INVESTIGATION_RESULTS, FRAUD_CONFIRMED_DATE, FRAUD_NOTIFICATION_RECEIVED, FRAUD_CONTACT_EMAIL
2. **Fraud Portfolios** (BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_PORTFOLIOS_AND_SUB_PORTFOLIOS): 361 loans where PORTFOLIO_CATEGORY = 'Fraud' (First Party Confirmed, Identity Theft Confirmed, Declined, Pending Investigation)
3. **Fraud Sub-Status** (BUSINESS_INTELLIGENCE.BRIDGE.VW_LOAN_SETTINGS_ENTITY_CURRENT + VW_LOAN_SUB_STATUS_ENTITY_CURRENT): 20 loans with LOAN_SUB_STATUS_ID IN (32, 61)

## Key Technical Implementation

### EARLIEST_FRAUD_DATE Calculation
Uses NULLIF/COALESCE pattern to handle NULL dates in LEAST() function:
```sql
NULLIF(
    LEAST(
        COALESCE(cf.FRAUD_NOTIFICATION_RECEIVED, '9999-12-31'::DATE),
        COALESCE(cf.FRAUD_CONFIRMED_DATE, '9999-12-31'::DATE),
        COALESCE(CAST(fp.FIRST_PARTY_FRAUD_CONFIRMED_DATE AS DATE), '9999-12-31'::DATE),
        -- additional date fields...
    ),
    '9999-12-31'::DATE
) as EARLIEST_FRAUD_DATE
```
Result: 502 of 509 loans have EARLIEST_FRAUD_DATE

### Conservative Fraud Classification Logic
```sql
CASE
    WHEN cf.FRAUD_INVESTIGATION_RESULTS = 'Confirmed'
         OR fp.FRAUD_PORTFOLIOS LIKE '%Confirmed%'
         OR fss.LOAN_SUB_STATUS_ID = 61
    THEN 'CONFIRMED'
    WHEN fp.FRAUD_PORTFOLIOS LIKE '%Pending Investigation%'
         OR fss.LOAN_SUB_STATUS_ID = 32
    THEN 'UNDER_INVESTIGATION'
    WHEN (cf.FRAUD_INVESTIGATION_RESULTS = 'Confirmed' AND fp.FRAUD_PORTFOLIOS LIKE '%Declined%')
         OR (cf.FRAUD_INVESTIGATION_RESULTS = 'Declined' AND fp.FRAUD_PORTFOLIOS LIKE '%Confirmed%')
    THEN 'MIXED'
    WHEN cf.FRAUD_INVESTIGATION_RESULTS = 'Declined'
         OR fp.FRAUD_PORTFOLIOS = 'Fraud - Declined'
    THEN 'DECLINED'
    ELSE 'UNKNOWN'
END
```

## Data Grain and Deduplication
- **Grain**: One row per LOAN_ID
- **Deduplication**: Portfolios aggregated using LISTAGG and GROUP BY LOAN_ID
- **No duplicates**: QC validated 509 distinct LOAN_IDs = 509 total rows

## QC Results
- Total loans: 509 (PASS)
- Zero duplicates (PASS)
- Source distribution: 414 custom, 361 portfolios, 20 sub-status (PASS)
- Data completeness: 20 complete (3 sources), 246 partial (2 sources), 243 single source
- Fraud status: 210 CONFIRMED, 155 DECLINED, 141 UNKNOWN, 3 UNDER_INVESTIGATION
- All boolean flags non-NULL (PASS)
- Conservative classification logic validated (PASS)

## Production Deployment Location
- BUSINESS_INTELLIGENCE.ANALYTICS.VW_LOAN_FRAUD (single view with core logic)

## Integration Use Cases
1. **Debt Sale Suppression**: LEFT JOIN to exclude IS_CONFIRMED_FRAUD loans
2. **Fraud Analysis**: Trend analysis using EARLIEST_FRAUD_DATE and FRAUD_STATUS
3. **Data Quality**: Monitor DATA_QUALITY_FLAG for INCONSISTENT classifications

## Known Limitations
- Sub-status lag: Only 20 of 509 loans have fraud sub-status (operational lag, acceptable)
- UNKNOWN status: 141 loans need manual review for proper classification
- LEAD_GUID coverage: 81% (414 of 509) - Some loans missing from custom fields source

## Future Enhancements
- Historical fraud view tracking status changes over time
- Integration with VW_LOAN_DECEASED and VW_LOAN_SCRA for unified suppression
- Automated alerting for new MIXED status loans
- Fraud investigation duration analytics

## Related Tickets
- DI-1246: 1099C Data Review - use for fraud exclusion
- DI-1235: Settlements Dashboard - add fraud indicators
- DI-1141: Debt Sale Population - replace inline fraud logic

## Files
- `final_deliverables/1_vw_loan_fraud_development.sql` - Development deployment
- `final_deliverables/2_production_deploy_vw_loan_fraud.sql` - Production deployment
- `qc_validation.sql` - 12 QC test categories
- `README.md` - Business documentation
