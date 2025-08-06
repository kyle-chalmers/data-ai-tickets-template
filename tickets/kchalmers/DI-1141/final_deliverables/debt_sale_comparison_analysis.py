#!/usr/bin/env python3
"""
DI-1141: Debt Sale Population Analysis
Compare external file vs our population file to identify filtering differences
"""

import pandas as pd
import numpy as np

def load_and_compare_files():
    """Load both CSV files and perform comprehensive comparison"""
    
    # Load the files
    print("Loading CSV files...")
    external_df = pd.read_csv('/Users/kchalmers/Downloads/updated_debt_sale_results.csv')
    our_df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1141/final_deliverables/Bounce_Q2_2025_Debt_Sale_Population_1604_loans.csv')
    
    print(f"External file: {len(external_df):,} loans")
    print(f"Our file: {len(our_df):,} loans")
    print(f"Difference: {len(our_df) - len(external_df):+,} loans\n")
    
    return external_df, our_df

def analyze_loan_differences(external_df, our_df):
    """Identify which loans are different between files"""
    
    external_loans = set(external_df['LOANID'])
    our_loans = set(our_df['LOANID'])
    
    only_in_ours = our_loans - external_loans
    only_in_external = external_loans - our_loans
    common_loans = our_loans & external_loans
    
    print("=== LOAN ID DIFFERENCES ===")
    print(f"Loans only in our file: {len(only_in_ours)}")
    print(f"Loans only in external file: {len(only_in_external)}")
    print(f"Common loans: {len(common_loans):,}")
    
    return only_in_ours, only_in_external, common_loans

def analyze_settlement_patterns(our_df, only_in_ours):
    """Analyze settlement-related fields for loans only in our file"""
    
    print("\n=== SETTLEMENT ANALYSIS FOR LOANS ONLY IN OUR FILE ===")
    
    if only_in_ours:
        our_only = our_df[our_df['LOANID'].isin(only_in_ours)].copy()
        
        # Analyze settlement fields
        print("Settlement Status Distribution:")
        settlement_status = our_only['DEBT_SETTLEMENT_STATUS'].value_counts(dropna=False)
        print(settlement_status)
        
        print("\nSettlement Setup Portfolio Distribution:")
        setup_portfolio = our_only['SETTLEMENT_SETUP_PORTFOLIO'].value_counts(dropna=False)
        print(setup_portfolio)
        
        print("\nDetailed breakdown of loans only in our file:")
        for _, row in our_only.iterrows():
            setup = 'Yes' if row['SETTLEMENT_SETUP_PORTFOLIO'] == True else 'No' if row['SETTLEMENT_SETUP_PORTFOLIO'] == False else 'NULL'
            status = row['DEBT_SETTLEMENT_STATUS'] if pd.notna(row['DEBT_SETTLEMENT_STATUS']) else 'NULL'
            placement = row['LOAN_CURRENT_PLACEMENT'] if pd.notna(row['LOAN_CURRENT_PLACEMENT']) else 'NULL'
            
            print(f"  {row['LOANID']}: Setup={setup}, Status={status}, Placement={placement}")
    
    return our_only if only_in_ours else pd.DataFrame()

def analyze_charge_off_dates(external_df, our_df):
    """Analyze charge-off date distributions"""
    
    print("\n=== CHARGE-OFF DATE ANALYSIS ===")
    
    # Convert to datetime
    external_df['CHARGEOFFDATE'] = pd.to_datetime(external_df['CHARGEOFFDATE'])
    our_df['CHARGEOFFDATE'] = pd.to_datetime(our_df['CHARGEOFFDATE'])
    
    print("External file charge-off date range:")
    print(f"  Min: {external_df['CHARGEOFFDATE'].min()}")
    print(f"  Max: {external_df['CHARGEOFFDATE'].max()}")
    
    print("Our file charge-off date range:")
    print(f"  Min: {our_df['CHARGEOFFDATE'].min()}")
    print(f"  Max: {our_df['CHARGEOFFDATE'].max()}")
    
    # Monthly distribution
    print("\nMonthly distribution - External file:")
    external_monthly = external_df.groupby(external_df['CHARGEOFFDATE'].dt.to_period('M')).size()
    print(external_monthly)
    
    print("\nMonthly distribution - Our file:")
    our_monthly = our_df.groupby(our_df['CHARGEOFFDATE'].dt.to_period('M')).size()
    print(our_monthly)

def analyze_key_exclusion_fields(our_df, only_in_ours):
    """Analyze key fields that might explain exclusions"""
    
    print("\n=== KEY EXCLUSION FIELD ANALYSIS ===")
    
    if only_in_ours:
        our_only = our_df[our_df['LOANID'].isin(only_in_ours)].copy()
        
        # Key exclusion fields to check
        exclusion_fields = [
            'FRAUD_INDICATOR',
            'DEBT_SETTLEMENT_STATUS', 
            'LOAN_CURRENT_PLACEMENT',
            'SETTLEMENT_SETUP_PORTFOLIO',
            'DECEASED_INDICATOR'
        ]
        
        for field in exclusion_fields:
            if field in our_only.columns:
                print(f"\n{field} for loans only in our file:")
                field_dist = our_only[field].value_counts(dropna=False)
                print(field_dist)

def generate_summary_report(external_df, our_df, only_in_ours, only_in_external):
    """Generate a summary report"""
    
    print("\n" + "="*60)
    print("SUMMARY REPORT")
    print("="*60)
    
    print(f"External file loans: {len(external_df):,}")
    print(f"Our file loans: {len(our_df):,}")
    print(f"Net difference: {len(our_df) - len(external_df):+,}")
    
    if only_in_ours:
        our_only = our_df[our_df['LOANID'].isin(only_in_ours)]
        setup_count = our_only['SETTLEMENT_SETUP_PORTFOLIO'].sum() if 'SETTLEMENT_SETUP_PORTFOLIO' in our_only.columns else 0
        
        print(f"\nLoans only in our file: {len(only_in_ours)}")
        print(f"  - With Settlement Setup Portfolio: {setup_count}")
        print(f"  - Settlement Setup percentage: {setup_count/len(only_in_ours)*100:.1f}%")
    
    if only_in_external:
        print(f"\nLoans only in external file: {len(only_in_external)}")
        print(f"  - Loan IDs: {sorted(list(only_in_external))}")
    
    print(f"\nLikely cause of difference:")
    print(f"  External file appears to exclude 'Settlement Setup' portfolio loans")
    print(f"  Our file only excludes 'Settlement Successful' portfolio loans")
    
    print(f"\nRecommendation:")
    print(f"  Add this exclusion to match external file:")
    print(f"  AND SSP.SETTLEMENT_SETUP_PORTFOLIO IS NULL")

if __name__ == "__main__":
    # Load and compare files
    external_df, our_df = load_and_compare_files()
    
    # Analyze differences
    only_in_ours, only_in_external, common_loans = analyze_loan_differences(external_df, our_df)
    
    # Analyze settlement patterns
    our_only_df = analyze_settlement_patterns(our_df, only_in_ours)
    
    # Analyze charge-off dates
    analyze_charge_off_dates(external_df, our_df)
    
    # Analyze key exclusion fields
    analyze_key_exclusion_fields(our_df, only_in_ours)
    
    # Generate summary
    generate_summary_report(external_df, our_df, only_in_ours, only_in_external)
    
    print(f"\nAnalysis complete!")