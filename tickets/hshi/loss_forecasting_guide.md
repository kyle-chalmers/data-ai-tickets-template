# Loss Forecasting Guide

## Overview

The Loss Forecasting project (BI-1451) generates forward-looking portfolio health metrics using delinquency-based charge-off forecasting and risk assumptions. This daily automated process supports risk monitoring and strategic portfolio management.

## Business Purpose

**Primary Stakeholders:**
- Risk Team: Portfolio health monitoring and credit policy adjustments

**Key Business Decisions Enabled:**
- Credit policy adjustments based on performance trends
- Risk monitoring and portfolio oversight
- Stress testing and scenario analysis

## Technical Architecture

### Data Sources
- `DATA_STORE.MVW_LOAN_TAPE_MONTHLY` - Monthly loan snapshots (maintained by DE team)
- `cron_store.vw_roll_rates_for_DQ_based_forecast` - Adjusted delinquency roll rates
- `business_intelligence.analytics.vw_decisions_current` - Credit policy and underwriting data

### Outputs
1. **`CRON_STORE.DSH_LOAN_TAPE_MONTHLY_with_3_Month_EXTENDED`**
   - Extended loan tape with 3-month DQ-based forecasting
   - Uses actual roll rates to predict status transitions

2. **`CRON_STORE.DSH_LOAN_PORTFOLIO_EXPECTATIONS`**
   - 60-month portfolio expectations combining actual and projected data
   - Incorporates risk assumptions and stress testing capabilities

### Extension Flag System
- `EXTENSIONFLAG = 0`: Historical data (actual performance)
- `EXTENSIONFLAG = 1`: DQ-based forecast (next 3 months)
- `EXTENSIONFLAG = 2`: Risk assumption projections (months 4-60)

### 60-Month Projection Horizon
The 60-month timeframe covers the full loan lifecycle, since the maximum loan term is 60 months. This allows complete performance projections through loan maturity.

## Core Methodology

### Delinquency-Based Forecasting (3-month)
- Uses actual delinquency amounts and roll rates for charge-off expectations
- Progression model: Current → DQ1 → DQ2 → DQ3 → Charge Off
- Applies adjusted roll rates determined by the Risk team
- Creates month-by-month status transitions

### Risk Assumption Modeling (60-month)
- Extends expectations using risk assumptions for loan performance
- Incorporates credit policy data and underwriting predictions
- Projects monthly cash flows and return calculations

### Stress Testing
- Stress factors are applied to final expectations (not to individual roll rates)
- Stress scenarios are determined by the Risk team
- Used for risk monitoring and scenario analysis

## Key Business Rules

### Delinquency Status Transitions
```
Month 1: DQ3+ → Charge Off, DQ2 → DQ3+, DQ1 → DQ2
Month 2: Similar progression with DQ2_to_CO_Rate
Month 3: Similar progression with DQ1_to_CO_Rate
```

### Charge-Off Calculations
- Principal balance at charge-off = Roll_Rate × Remaining_Principal
- Charge-off count = Roll_Rate (as probability)
- Charge-off date projected based on current delinquency status

## Architecture Issues ⚠️

### Migration Priorities
- **DATA_STORE.VW_LOAN_COLLECTION**: Requires migration to ANALYTICS layer  
- **MVW_LOAN_TAPE_MONTHLY**: Currently acceptable to use (maintained by DE team)
- **CRON_STORE outputs**: Should migrate to ANALYTICS schema
- **Temporary functions**: Created in DATA_STORE schema inappropriately

### Recommended Migrations
- Migrate VW_LOAN_COLLECTION to ANALYTICS layer
- Move output tables to ANALYTICS schema following 5-layer architecture
- Create temporary functions in appropriate schema

## Processing Flow

1. **Setup**: Create Snowflake connection and amortization functions
2. **Parameter Extraction**: Get latest loan tape date and DQ metrics  
3. **Roll Rate Retrieval**: Fetch adjusted roll rates for forecasting
4. **Extended Tape Creation**: Apply 3-month DQ-based projections
5. **Expectations Generation**: Create 60-month portfolio expectations
6. **Cleanup**: Drop temporary functions

## Integration Points

**Portfolio Health Tableau Dashboard**: Live connection updates in real-time after job completion
**Risk Team Reporting**: Primary interface for portfolio health monitoring
**Credit Policy Analysis**: Supports policy adjustment decisions

## Schedule and Dependencies

**Frequency**: Daily at 7:54 AM Pacific Time
**Upstream Dependency**: MVW_LOAN_TAPE_MONTHLY updated daily at 1:40 AM by DE team
**Data Quality Check**: BI-2172 runs after main job to validate outputs
**Runtime**: Processes entire loan portfolio with complex calculations
**Downstream Usage**: Portfolio Health Tableau dashboard with live connection

## Portfolio Segmentation

**Uniform Forecasting Rules**: All loan portfolios use the same roll rates and risk assumptions
**Portfolio Information**: PORTFOLIOID and PORTFOLIONAME are included for reporting segmentation only
**No Portfolio-Specific Logic**: Loan performance forecasting does not vary by capital partner or portfolio type

## Data Quality Validation

**BI-2172 Post-Processing Checks**:
- **MVW_LOAN_TAPE_MONTHLY validation**: Duplicates, missing loans, invalid data
- **Portfolio expectations validation**: Duplicates, missing expectations, data completeness
- **Policy flags validation**: Duplicates and data integrity

## Current Status

**Process Health**: No known issues identified by stakeholders
**Performance**: Stable daily execution with consistent data quality
**Business Value**: Actively used by Risk team for credit policy decisions

## Technical Implementation Details

### Amortization Functions
Creates temporary Excel-equivalent functions:
- `PMT()`: Standard loan payment calculation
- `IPMT()`: Interest portion of payment
- `PPMT()`: Principal portion of payment

### Performance Considerations
- Large dataset processing (entire loan portfolio)
- Complex CTEs and window functions
- 60-month projections for all active loans
- Temporary function creation/deletion pattern

---

*Document Status: Active - Critical monthly risk monitoring process*  
*Architecture Status: Requires DATA_STORE migration planning*  
*Business Impact: High - Supports capital partner relationships and risk oversight*