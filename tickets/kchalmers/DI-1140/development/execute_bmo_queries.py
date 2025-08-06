#!/usr/bin/env python3
"""
DI-1140: BMO Fraud Investigation - Execute Updated Queries 3-6
This script executes the updated BMO fraud investigation queries that exclude routing number 071025661
and generates CSV results files to overwrite existing ones.
"""

import snowflake.connector
import pandas as pd
import os
import sys
from pathlib import Path

# Configuration
QUERIES_TO_EXECUTE = [
    {
        'query_file': '3_all_bmo_los_investigation_aggregated.sql',
        'output_file': '3_all_bmo_los_investigation_results.csv',
        'description': 'All BMO LOS Investigation (Aggregated)'
    },
    {
        'query_file': '4_all_bmo_lms_investigation_aggregated.sql', 
        'output_file': '4_all_bmo_lms_investigation_results.csv',
        'description': 'All BMO LMS Investigation (Aggregated)'
    },
    {
        'query_file': '5_detailed_all_bmo_los_applications.sql',
        'output_file': '5_detailed_all_bmo_los_applications_individual_records.csv', 
        'description': 'Detailed All BMO LOS Applications (Individual Records)'
    },
    {
        'query_file': '6_detailed_all_bmo_lms_loans.sql',
        'output_file': '6_detailed_all_bmo_lms_loans_individual_records.csv',
        'description': 'Detailed All BMO LMS Loans (Individual Records)'
    }
]

def get_snowflake_connection():
    """
    Create Snowflake connection using standard environment variables or connection parameters.
    You may need to modify this based on your specific Snowflake configuration.
    """
    try:
        # Try to use environment variables first
        conn = snowflake.connector.connect(
            user=os.getenv('SNOWFLAKE_USER'),
            password=os.getenv('SNOWFLAKE_PASSWORD'),
            account=os.getenv('SNOWFLAKE_ACCOUNT'),
            warehouse=os.getenv('SNOWFLAKE_WAREHOUSE'),
            database=os.getenv('SNOWFLAKE_DATABASE'),
            schema=os.getenv('SNOWFLAKE_SCHEMA'),
            role=os.getenv('SNOWFLAKE_ROLE')
        )
        return conn
    except Exception as e:
        print(f"Failed to connect using environment variables: {e}")
        print("Please ensure your Snowflake environment variables are set:")
        print("SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_ACCOUNT, SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA, SNOWFLAKE_ROLE")
        return None

def read_sql_file(file_path):
    """Read SQL file and return its contents."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            return file.read()
    except Exception as e:
        print(f"Error reading SQL file {file_path}: {e}")
        return None

def execute_query_and_save_csv(conn, sql_content, output_path, description):
    """Execute SQL query and save results to CSV."""
    try:
        print(f"\nExecuting: {description}")
        print(f"Output: {output_path}")
        
        # Execute the query
        cursor = conn.cursor()
        cursor.execute(sql_content)
        
        # Fetch column names
        columns = [desc[0] for desc in cursor.description]
        
        # Fetch all results
        results = cursor.fetchall()
        cursor.close()
        
        if not results:
            print(f"Warning: No results returned for {description}")
            return 0
        
        # Create DataFrame
        df = pd.DataFrame(results, columns=columns)
        
        # Save to CSV with headers
        df.to_csv(output_path, index=False, header=True)
        
        record_count = len(df)
        print(f"Successfully saved {record_count} records to {output_path}")
        return record_count
        
    except Exception as e:
        print(f"Error executing query for {description}: {e}")
        return -1

def main():
    """Main execution function."""
    print("DI-1140: BMO Fraud Investigation - Execute Updated Queries 3-6")
    print("=" * 70)
    
    # Get current directory paths
    current_dir = Path(__file__).parent
    results_dir = current_dir.parent / 'results_data'
    
    # Ensure results directory exists
    results_dir.mkdir(exist_ok=True)
    
    # Connect to Snowflake
    print("Connecting to Snowflake...")
    conn = get_snowflake_connection()
    if not conn:
        sys.exit(1)
    
    print("Successfully connected to Snowflake.")
    
    # Track results
    execution_results = []
    
    # Execute each query
    for query_config in QUERIES_TO_EXECUTE:
        query_file_path = current_dir / query_config['query_file']
        output_file_path = results_dir / query_config['output_file']
        
        # Read SQL file
        sql_content = read_sql_file(query_file_path)
        if not sql_content:
            print(f"Skipping {query_config['description']} due to file read error")
            continue
        
        # Execute query and save CSV
        record_count = execute_query_and_save_csv(
            conn, 
            sql_content, 
            output_file_path, 
            query_config['description']
        )
        
        execution_results.append({
            'query': query_config['description'],
            'file': query_config['output_file'],
            'record_count': record_count
        })
    
    # Close connection
    conn.close()
    
    # Print summary
    print("\n" + "=" * 70)
    print("EXECUTION SUMMARY")
    print("=" * 70)
    
    successful_executions = 0
    for result in execution_results:
        status = "SUCCESS" if result['record_count'] >= 0 else "FAILED"
        if result['record_count'] >= 0:
            successful_executions += 1
        
        print(f"{status}: {result['query']}")
        print(f"  File: {result['file']}")
        if result['record_count'] >= 0:
            print(f"  Records: {result['record_count']}")
        print()
    
    print(f"Successfully executed {successful_executions} out of {len(QUERIES_TO_EXECUTE)} queries.")
    
    if successful_executions == len(QUERIES_TO_EXECUTE):
        print("\nAll queries executed successfully! CSV files have been overwritten with updated results.")
        print("\nNOTE: These results now exclude routing number 071025661 as specified.")
    else:
        print(f"\nWarning: {len(QUERIES_TO_EXECUTE) - successful_executions} queries failed to execute.")

if __name__ == "__main__":
    main()