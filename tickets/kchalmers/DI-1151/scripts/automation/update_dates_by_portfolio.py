#!/usr/bin/env python3
"""
Update dates in debt sale CSV files based on portfolio names.
- Theorem portfolios: 2025-08-11
- All other portfolios: 2025-08-08
"""

import csv
import pandas as pd
import subprocess
import json

# Define the Theorem portfolios
THEOREM_PORTFOLIOS = [
    "Theorem Main Master Fund LP - Loan Sale",
    "Theorem Prime Plus Yield Fund Master LP - Loan Sale"
]

# Define dates
THEOREM_DATE = "2025-08-11"
NON_THEOREM_DATE = "2025-08-08"

def get_portfolio_mapping():
    """Get loan ID to portfolio mapping from Snowflake"""
    print("Fetching portfolio mapping from Snowflake...")
    
    query = """
    SELECT 
        LOANID,
        PORTFOLIONAME
    FROM BUSINESS_INTELLIGENCE_DEV.CRON_STORE.BOUNCE_DEBT_SALE_Q2_2025_SALE_SELECTED
    """
    
    result = subprocess.run(
        ['snow', 'sql', '-q', query, '--format', 'json'],
        capture_output=True,
        text=True
    )
    
    if result.returncode != 0:
        print(f"Error executing query: {result.stderr}")
        return {}
    
    # Parse JSON output
    data = json.loads(result.stdout)
    
    # Create mapping dictionary
    portfolio_map = {}
    for row in data:
        loan_id = row['LOANID']
        portfolio = row['PORTFOLIONAME']
        portfolio_map[loan_id] = portfolio
    
    print(f"Loaded {len(portfolio_map)} loan-to-portfolio mappings")
    return portfolio_map

def update_marketing_file(portfolio_map):
    """Update marketing goodbye letters file"""
    input_file = '/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/marketing_goodbye_letters_bounce_2025_q2_final.csv'
    output_file = '/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/marketing_goodbye_letters_bounce_2025_q2_final_updated.csv'
    
    print("\nUpdating marketing goodbye letters file...")
    
    theorem_count = 0
    non_theorem_count = 0
    not_found_count = 0
    
    with open(input_file, 'r', newline='') as infile, \
         open(output_file, 'w', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in reader:
            loan_id = row['LOAN_ID']
            
            if loan_id in portfolio_map:
                portfolio = portfolio_map[loan_id]
                if portfolio in THEOREM_PORTFOLIOS:
                    row['SALE_DATE'] = THEOREM_DATE
                    theorem_count += 1
                else:
                    row['SALE_DATE'] = NON_THEOREM_DATE
                    non_theorem_count += 1
            else:
                # If not found, default to non-Theorem date
                row['SALE_DATE'] = NON_THEOREM_DATE
                not_found_count += 1
                print(f"  Warning: Loan {loan_id} not found in portfolio mapping")
            
            writer.writerow(row)
    
    print(f"  Updated {theorem_count} Theorem loans to {THEOREM_DATE}")
    print(f"  Updated {non_theorem_count} non-Theorem loans to {NON_THEOREM_DATE}")
    if not_found_count > 0:
        print(f"  Warning: {not_found_count} loans not found in mapping")
    
    return output_file

def update_credit_reporting_file(portfolio_map):
    """Update credit reporting file"""
    input_file = '/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/credit_reporting_bounce_2025_q2_final.csv'
    output_file = '/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/credit_reporting_bounce_2025_q2_final_updated.csv'
    
    print("\nUpdating credit reporting file...")
    
    theorem_count = 0
    non_theorem_count = 0
    not_found_count = 0
    
    with open(input_file, 'r', newline='') as infile, \
         open(output_file, 'w', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in reader:
            loan_id = row['LOAN_ID']
            
            if loan_id in portfolio_map:
                portfolio = portfolio_map[loan_id]
                if portfolio in THEOREM_PORTFOLIOS:
                    row['PLACEMENT_STATUS_STARTDATE'] = THEOREM_DATE
                    theorem_count += 1
                else:
                    row['PLACEMENT_STATUS_STARTDATE'] = NON_THEOREM_DATE
                    non_theorem_count += 1
            else:
                # If not found, default to non-Theorem date
                row['PLACEMENT_STATUS_STARTDATE'] = NON_THEOREM_DATE
                not_found_count += 1
                print(f"  Warning: Loan {loan_id} not found in portfolio mapping")
            
            writer.writerow(row)
    
    print(f"  Updated {theorem_count} Theorem loans to {THEOREM_DATE}")
    print(f"  Updated {non_theorem_count} non-Theorem loans to {NON_THEOREM_DATE}")
    if not_found_count > 0:
        print(f"  Warning: {not_found_count} loans not found in mapping")
    
    return output_file

def update_bulk_upload_file(portfolio_map):
    """Update bulk upload file"""
    input_file = '/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/bulk_upload_bounce_2025_q2_final.csv'
    output_file = '/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/bulk_upload_bounce_2025_q2_final_updated.csv'
    
    print("\nUpdating bulk upload file...")
    
    theorem_count = 0
    non_theorem_count = 0
    not_found_count = 0
    
    with open(input_file, 'r', newline='') as infile, \
         open(output_file, 'w', newline='') as outfile:
        
        reader = csv.DictReader(infile)
        fieldnames = reader.fieldnames
        writer = csv.DictWriter(outfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for row in reader:
            loan_id = row['LOANID']
            
            if loan_id in portfolio_map:
                portfolio = portfolio_map[loan_id]
                if portfolio in THEOREM_PORTFOLIOS:
                    row['PLACEMENT_STATUS_STARTDATE'] = THEOREM_DATE
                    theorem_count += 1
                else:
                    row['PLACEMENT_STATUS_STARTDATE'] = NON_THEOREM_DATE
                    non_theorem_count += 1
            else:
                # If not found, default to non-Theorem date
                row['PLACEMENT_STATUS_STARTDATE'] = NON_THEOREM_DATE
                not_found_count += 1
                print(f"  Warning: Loan {loan_id} not found in portfolio mapping")
            
            writer.writerow(row)
    
    print(f"  Updated {theorem_count} Theorem loans to {THEOREM_DATE}")
    print(f"  Updated {non_theorem_count} non-Theorem loans to {NON_THEOREM_DATE}")
    if not_found_count > 0:
        print(f"  Warning: {not_found_count} loans not found in mapping")
    
    return output_file

def validate_updates():
    """Validate the updated files"""
    print("\n" + "="*60)
    print("VALIDATION SUMMARY")
    print("="*60)
    
    # Check marketing file
    df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/marketing_goodbye_letters_bounce_2025_q2_final_updated.csv')
    print("\nMarketing Goodbye Letters:")
    print(df['SALE_DATE'].value_counts())
    
    # Check credit reporting file
    df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/credit_reporting_bounce_2025_q2_final_updated.csv')
    print("\nCredit Reporting:")
    print(df['PLACEMENT_STATUS_STARTDATE'].value_counts())
    
    # Check bulk upload file
    df = pd.read_csv('/Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1151/final_deliverables/bulk_upload_bounce_2025_q2_final_updated.csv')
    print("\nBulk Upload:")
    print(df['PLACEMENT_STATUS_STARTDATE'].value_counts())
    
    print("\n" + "="*60)
    print("Expected counts:")
    print(f"  Theorem loans ({THEOREM_DATE}): 284")
    print(f"  Non-Theorem loans ({NON_THEOREM_DATE}): 1,199")
    print(f"  Total: 1,483")
    print("="*60)

def main():
    """Main execution function"""
    print("="*60)
    print("DEBT SALE DATE UPDATE BY PORTFOLIO")
    print("="*60)
    print(f"Theorem portfolios will be set to: {THEOREM_DATE}")
    print(f"All other portfolios will be set to: {NON_THEOREM_DATE}")
    
    # Get portfolio mapping
    portfolio_map = get_portfolio_mapping()
    
    if not portfolio_map:
        print("Error: Could not fetch portfolio mapping. Exiting.")
        return
    
    # Update each file
    marketing_file = update_marketing_file(portfolio_map)
    credit_file = update_credit_reporting_file(portfolio_map)
    bulk_file = update_bulk_upload_file(portfolio_map)
    
    # Validate updates
    validate_updates()
    
    print("\n" + "="*60)
    print("UPDATE COMPLETE")
    print("="*60)
    print("\nUpdated files created:")
    print(f"  - {marketing_file}")
    print(f"  - {credit_file}")
    print(f"  - {bulk_file}")
    print("\nOriginal files preserved with original names.")

if __name__ == "__main__":
    main()