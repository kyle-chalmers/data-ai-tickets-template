#!/usr/bin/env python3
"""
DI-1300: Export collection activity queries to CSV
Uses snowflake-connector-python for clean CSV output
"""

import snowflake.connector
import csv
import os
from pathlib import Path

# Configuration
OUTPUT_DIR = Path("../final_deliverables")
Q3_START = '2025-07-01'
Q3_END = '2025-09-30'

# Get Snowflake connection from snow CLI config
conn = snowflake.connector.connect(
    account=os.getenv('SNOWFLAKE_ACCOUNT'),
    authenticator='externalbrowser'
)

cursor = conn.cursor()

print("Setting up temp tables...")
cursor.execute("USE WAREHOUSE BUSINESS_INTELLIGENCE_LARGE")

# Create temp tables (setup from 0_setup_temp_tables.sql)
with open('0_setup_temp_tables.sql', 'r') as f:
    setup_sql = f.read()
    # Execute each statement
    for statement in setup_sql.split(';'):
        statement = statement.strip()
        if statement and not statement.startswith('--'):
            cursor.execute(statement)

print("Temp tables created successfully!")

# Query definitions with output filenames
queries = [
    ('1_query_genesys_phonecall.sql', '1_fortress_q3_2025_genesys_phonecall_activity.csv'),
    ('2_query_genesys_sms.sql', '2_fortress_q3_2025_genesys_sms_activity.csv'),
    ('3_query_genesys_email.sql', '3_fortress_q3_2025_genesys_email_activity.csv'),
    ('4_query_loan_notes.sql', '4_fortress_q3_2025_loan_notes.csv'),
    ('5_query_sfmc_email.sql', '5_fortress_q3_2025_sfmc_email_activity.csv'),
]

# Execute each query and save to CSV
for i, (sql_file, csv_file) in enumerate(queries, 1):
    print(f"[{i}/5] Executing {sql_file}...")

    with open(sql_file, 'r') as f:
        query_sql = f.read()

    # Set variables
    cursor.execute(f"SET q3_start_date = '{Q3_START}'")
    cursor.execute(f"SET q3_end_date = '{Q3_END}'")

    # Execute query
    cursor.execute(query_sql)

    # Get results and column names
    results = cursor.fetchall()
    columns = [desc[0] for desc in cursor.description]

    # Write to CSV
    output_path = OUTPUT_DIR / csv_file
    with open(output_path, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(columns)
        writer.writerows(results)

    print(f"   Saved {len(results)} records to {csv_file}")

cursor.close()
conn.close()

print("\nAll queries completed successfully!")
print(f"\nOutput files in {OUTPUT_DIR}:")
for _, csv_file in queries:
    path = OUTPUT_DIR / csv_file
    size = path.stat().st_size
    lines = sum(1 for _ in open(path))
    print(f"  {csv_file}: {lines-1} records ({size:,} bytes)")
