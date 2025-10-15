#!/usr/bin/env python3
"""
Combine all CSV result files into a single Excel file with multiple tabs
"""

import pandas as pd
from pathlib import Path

# Define paths
RESULTS_DIR = Path(__file__).parent.parent / 'results'
OUTPUT_DIR = Path('/Users/hshi/WOW/drive-tickets/DI-1297 Phone Test Results Analysis')
OUTPUT_FILE = OUTPUT_DIR / 'DI-1297_Phone_Test_Results_Combined.xlsx'

# Define CSV files and their tab names
csv_files = [
    {
        'file': RESULTS_DIR / '01_daily_group_size_trends_results.csv',
        'sheet_name': 'Daily Group Size',
        'description': 'Daily account counts by test/control group'
    },
    {
        'file': RESULTS_DIR / '02_cure_rate_cohort_analysis_results.csv',
        'sheet_name': 'Cure Rate Cohort',
        'description': 'Long-term cohort cure tracking'
    },
    {
        'file': RESULTS_DIR / '03_cure_rate_rolling_monthly_results.csv',
        'sheet_name': 'Cure Rate Monthly',
        'description': 'Month-over-month cure rates'
    },
    {
        'file': RESULTS_DIR / '04_roll_rate_analysis_results.csv',
        'sheet_name': 'Roll Rate',
        'description': 'DPD bucket progression tracking'
    }
]

def main():
    print("=" * 70)
    print("Combining CSV Results into Excel File")
    print("=" * 70)

    # Create Excel writer
    with pd.ExcelWriter(OUTPUT_FILE, engine='openpyxl') as writer:
        for csv_info in csv_files:
            print(f"\nProcessing: {csv_info['sheet_name']}")
            print(f"  File: {csv_info['file'].name}")

            try:
                # Read CSV
                df = pd.read_csv(csv_info['file'])
                print(f"  Rows: {len(df):,}")
                print(f"  Columns: {len(df.columns)}")

                # Write to Excel tab
                df.to_excel(writer, sheet_name=csv_info['sheet_name'], index=False)
                print(f"  ✓ Written to sheet '{csv_info['sheet_name']}'")

            except Exception as e:
                print(f"  ✗ Error: {e}")

    print("\n" + "=" * 70)
    print(f"✓ Excel file created: {OUTPUT_FILE}")
    print("=" * 70)

    # Print file info
    file_size = OUTPUT_FILE.stat().st_size / 1024  # KB
    print(f"\nFile size: {file_size:.1f} KB")
    print(f"Sheets: {len(csv_files)}")

if __name__ == '__main__':
    main()
