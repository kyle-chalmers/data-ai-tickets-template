#!/usr/bin/env python3
"""
Quality Control: Verify date distributions in CSV files match portfolio distributions
"""

import pandas as pd
import subprocess
import json

def get_portfolio_distribution():
    """Get the expected distribution from Snowflake"""
    print("="*60)
    print("FETCHING EXPECTED PORTFOLIO DISTRIBUTION FROM SNOWFLAKE")
    print("="*60)
    
    query = """
    SELECT 
        CASE 
            WHEN PORTFOLIONAME IN ('Theorem Main Master Fund LP - Loan Sale', 
                                  'Theorem Prime Plus Yield Fund Master LP - Loan Sale')
            THEN 'Theorem'
            ELSE 'Non-Theorem'
        END as portfolio_type,
        COUNT(*) as loan_count
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED
    GROUP BY portfolio_type
    ORDER BY portfolio_type
    """
    
    result = subprocess.run(
        ['snow', 'sql', '-q', query, '--format', 'json'],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"Error executing query: {result.stderr}")
        return {}
    
    data = json.loads(result.stdout)
    distribution = {row['PORTFOLIO_TYPE']: row['LOAN_COUNT'] for row in data}
    
    print("\nExpected Distribution from Database:")
    print(f"  Non-Theorem portfolios: {distribution.get('Non-Theorem', 0)} loans")
    print(f"  Theorem portfolios: {distribution.get('Theorem', 0)} loans")
    print(f"  Total: {sum(distribution.values())} loans")
    
    return distribution

def check_marketing_file():
    """Check marketing goodbye letters file"""
    print("\n" + "="*60)
    print("CHECKING MARKETING GOODBYE LETTERS FILE")
    print("="*60)
    
    df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/marketing_goodbye_letters_bounce_2025_q2_final.csv')
    
    # Count by SALE_DATE
    date_counts = df['SALE_DATE'].value_counts().sort_index()
    
    print("\nDate Distribution in Marketing File:")
    for date, count in date_counts.items():
        print(f"  {date}: {count} loans")
    print(f"  Total: {len(df)} loans")
    
    # Map to portfolio types
    theorem_count = date_counts.get('2025-08-11', 0)
    non_theorem_count = date_counts.get('2025-08-08', 0)
    
    return {
        'file': 'marketing_goodbye_letters',
        'total': len(df),
        'theorem_date_count': theorem_count,
        'non_theorem_date_count': non_theorem_count,
        'date_distribution': date_counts.to_dict()
    }

def check_credit_reporting_file():
    """Check credit reporting file"""
    print("\n" + "="*60)
    print("CHECKING CREDIT REPORTING FILE")
    print("="*60)
    
    df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/credit_reporting_bounce_2025_q2_final.csv')
    
    # Count by PLACEMENT_STATUS_STARTDATE
    date_counts = df['PLACEMENT_STATUS_STARTDATE'].value_counts().sort_index()
    
    print("\nDate Distribution in Credit Reporting File:")
    for date, count in date_counts.items():
        print(f"  {date}: {count} loans")
    print(f"  Total: {len(df)} loans")
    
    # Map to portfolio types
    theorem_count = date_counts.get('2025-08-11', 0)
    non_theorem_count = date_counts.get('2025-08-08', 0)
    
    return {
        'file': 'credit_reporting',
        'total': len(df),
        'theorem_date_count': theorem_count,
        'non_theorem_date_count': non_theorem_count,
        'date_distribution': date_counts.to_dict()
    }

def check_bulk_upload_file():
    """Check bulk upload file"""
    print("\n" + "="*60)
    print("CHECKING BULK UPLOAD FILE")
    print("="*60)
    
    df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/bulk_upload_bounce_2025_q2_final.csv')
    
    # Count by PLACEMENT_STATUS_STARTDATE
    date_counts = df['PLACEMENT_STATUS_STARTDATE'].value_counts().sort_index()
    
    print("\nDate Distribution in Bulk Upload File:")
    for date, count in date_counts.items():
        print(f"  {date}: {count} loans")
    print(f"  Total: {len(df)} loans")
    
    # Map to portfolio types
    theorem_count = date_counts.get('2025-08-11', 0)
    non_theorem_count = date_counts.get('2025-08-08', 0)
    
    return {
        'file': 'bulk_upload',
        'total': len(df),
        'theorem_date_count': theorem_count,
        'non_theorem_date_count': non_theorem_count,
        'date_distribution': date_counts.to_dict()
    }

def cross_check_loan_ids():
    """Cross-check specific loan IDs to verify portfolio alignment"""
    print("\n" + "="*60)
    print("CROSS-CHECKING SAMPLE LOAN IDS")
    print("="*60)
    
    # Get a few Theorem loans from database
    query = """
    SELECT 
        LOANID,
        PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED
    WHERE PORTFOLIONAME IN ('Theorem Main Master Fund LP - Loan Sale', 
                            'Theorem Prime Plus Yield Fund Master LP - Loan Sale')
    LIMIT 5
    """
    
    result = subprocess.run(
        ['snow', 'sql', '-q', query, '--format', 'json'],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        theorem_loans = json.loads(result.stdout)
        
        # Load CSV files
        marketing_df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/marketing_goodbye_letters_bounce_2025_q2_final.csv')
        credit_df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/credit_reporting_bounce_2025_q2_final.csv')
        bulk_df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/bulk_upload_bounce_2025_q2_final.csv')
        
        print("\nSample Theorem Loans Verification:")
        for loan in theorem_loans[:3]:
            loan_id = loan['LOANID']
            portfolio = loan['PORTFOLIONAME']
            
            print(f"\nLoan ID: {loan_id}")
            print(f"  Portfolio: {portfolio}")
            
            # Check in each file
            marketing_date = marketing_df[marketing_df['LOAN_ID'] == loan_id]['SALE_DATE'].values
            if len(marketing_date) > 0:
                print(f"  Marketing SALE_DATE: {marketing_date[0]} {'✓' if marketing_date[0] == '2025-08-11' else '✗'}")
            
            credit_date = credit_df[credit_df['LOAN_ID'] == loan_id]['PLACEMENT_STATUS_STARTDATE'].values
            if len(credit_date) > 0:
                print(f"  Credit PLACEMENT_STATUS_STARTDATE: {credit_date[0]} {'✓' if credit_date[0] == '2025-08-11' else '✗'}")
            
            bulk_date = bulk_df[bulk_df['LOANID'] == loan_id]['PLACEMENT_STATUS_STARTDATE'].values
            if len(bulk_date) > 0:
                print(f"  Bulk PLACEMENT_STATUS_STARTDATE: {bulk_date[0]} {'✓' if bulk_date[0] == '2025-08-11' else '✗'}")
    
    # Get a few Non-Theorem loans
    query = """
    SELECT 
        LOANID,
        PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED
    WHERE PORTFOLIONAME NOT IN ('Theorem Main Master Fund LP - Loan Sale', 
                                'Theorem Prime Plus Yield Fund Master LP - Loan Sale')
    LIMIT 5
    """
    
    result = subprocess.run(
        ['snow', 'sql', '-q', query, '--format', 'json'],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        non_theorem_loans = json.loads(result.stdout)
        
        print("\nSample Non-Theorem Loans Verification:")
        for loan in non_theorem_loans[:3]:
            loan_id = loan['LOANID']
            portfolio = loan['PORTFOLIONAME']
            
            print(f"\nLoan ID: {loan_id}")
            print(f"  Portfolio: {portfolio}")
            
            # Check in each file
            marketing_date = marketing_df[marketing_df['LOAN_ID'] == loan_id]['SALE_DATE'].values
            if len(marketing_date) > 0:
                print(f"  Marketing SALE_DATE: {marketing_date[0]} {'✓' if marketing_date[0] == '2025-08-08' else '✗'}")
            
            credit_date = credit_df[credit_df['LOAN_ID'] == loan_id]['PLACEMENT_STATUS_STARTDATE'].values
            if len(credit_date) > 0:
                print(f"  Credit PLACEMENT_STATUS_STARTDATE: {credit_date[0]} {'✓' if credit_date[0] == '2025-08-08' else '✗'}")
            
            bulk_date = bulk_df[bulk_df['LOANID'] == loan_id]['PLACEMENT_STATUS_STARTDATE'].values
            if len(bulk_date) > 0:
                print(f"  Bulk PLACEMENT_STATUS_STARTDATE: {bulk_date[0]} {'✓' if bulk_date[0] == '2025-08-08' else '✗'}")

def main():
    """Main QC execution"""
    print("="*60)
    print("DATE-PORTFOLIO ALIGNMENT QUALITY CONTROL")
    print("="*60)
    
    # Get expected distribution
    expected = get_portfolio_distribution()
    
    # Check each file
    marketing_results = check_marketing_file()
    credit_results = check_credit_reporting_file()
    bulk_results = check_bulk_upload_file()
    
    # Cross-check sample loans
    cross_check_loan_ids()
    
    # Final validation summary
    print("\n" + "="*60)
    print("QC VALIDATION SUMMARY")
    print("="*60)
    
    print("\nExpected vs Actual Alignment:")
    print(f"\nExpected from Database:")
    print(f"  Theorem (2025-08-11): {expected.get('Theorem', 0)} loans")
    print(f"  Non-Theorem (2025-08-08): {expected.get('Non-Theorem', 0)} loans")
    
    print(f"\nActual in CSV Files:")
    print(f"\nMarketing Goodbye Letters:")
    print(f"  2025-08-11: {marketing_results['theorem_date_count']} loans {'✓' if marketing_results['theorem_date_count'] == expected.get('Theorem', 0) else '✗'}")
    print(f"  2025-08-08: {marketing_results['non_theorem_date_count']} loans {'✓' if marketing_results['non_theorem_date_count'] == expected.get('Non-Theorem', 0) else '✗'}")
    
    print(f"\nCredit Reporting:")
    print(f"  2025-08-11: {credit_results['theorem_date_count']} loans {'✓' if credit_results['theorem_date_count'] == expected.get('Theorem', 0) else '✗'}")
    print(f"  2025-08-08: {credit_results['non_theorem_date_count']} loans {'✓' if credit_results['non_theorem_date_count'] == expected.get('Non-Theorem', 0) else '✗'}")
    
    print(f"\nBulk Upload:")
    print(f"  2025-08-11: {bulk_results['theorem_date_count']} loans {'✓' if bulk_results['theorem_date_count'] == expected.get('Theorem', 0) else '✗'}")
    print(f"  2025-08-08: {bulk_results['non_theorem_date_count']} loans {'✓' if bulk_results['non_theorem_date_count'] == expected.get('Non-Theorem', 0) else '✗'}")
    
    # Overall pass/fail
    all_match = (
        marketing_results['theorem_date_count'] == expected.get('Theorem', 0) and
        marketing_results['non_theorem_date_count'] == expected.get('Non-Theorem', 0) and
        credit_results['theorem_date_count'] == expected.get('Theorem', 0) and
        credit_results['non_theorem_date_count'] == expected.get('Non-Theorem', 0) and
        bulk_results['theorem_date_count'] == expected.get('Theorem', 0) and
        bulk_results['non_theorem_date_count'] == expected.get('Non-Theorem', 0)
    )
    
    print("\n" + "="*60)
    if all_match:
        print("✅ QC PASSED: All files have correct date-portfolio alignment!")
    else:
        print("❌ QC FAILED: Date distributions do not match portfolio distributions!")
    print("="*60)

if __name__ == "__main__":
    main()