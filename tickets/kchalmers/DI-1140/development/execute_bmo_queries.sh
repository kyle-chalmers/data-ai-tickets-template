#!/bin/bash

# DI-1140: BMO Fraud Investigation - Execute Updated Queries 3-6
# This script executes the updated BMO fraud investigation queries that exclude routing number 071025661
# and generates CSV results files to overwrite existing ones.

echo "DI-1140: BMO Fraud Investigation - Execute Updated Queries 3-6"
echo "=================================================================="

# Set working directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_DIR="${SCRIPT_DIR}/../results_data"

# Ensure results directory exists
mkdir -p "$RESULTS_DIR"

# Array of queries to execute
declare -a QUERIES=(
    "3_all_bmo_los_investigation_aggregated.sql:3_all_bmo_los_investigation_results.csv:All BMO LOS Investigation (Aggregated)"
    "4_all_bmo_lms_investigation_aggregated.sql:4_all_bmo_lms_investigation_results.csv:All BMO LMS Investigation (Aggregated)"
    "5_detailed_all_bmo_los_applications.sql:5_detailed_all_bmo_los_applications_individual_records.csv:Detailed All BMO LOS Applications (Individual Records)"
    "6_detailed_all_bmo_lms_loans.sql:6_detailed_all_bmo_lms_loans_individual_records.csv:Detailed All BMO LMS Loans (Individual Records)"
)

# Track execution results
declare -a RESULTS=()
SUCCESSFUL_EXECUTIONS=0

# Execute each query
for query_info in "${QUERIES[@]}"; do
    IFS=':' read -r sql_file csv_file description <<< "$query_info"
    
    echo ""
    echo "Executing: $description"
    echo "SQL File: $sql_file"
    echo "Output: $csv_file"
    
    # Full paths
    SQL_PATH="${SCRIPT_DIR}/${sql_file}"
    CSV_PATH="${RESULTS_DIR}/${csv_file}"
    
    # Check if SQL file exists
    if [[ ! -f "$SQL_PATH" ]]; then
        echo "ERROR: SQL file not found: $SQL_PATH"
        RESULTS+=("FAILED:$description:File not found")
        continue
    fi
    
    # Execute query using snow CLI and save to CSV
    if snow sql -f "$SQL_PATH" --format csv > "$CSV_PATH" 2>/dev/null; then
        # Count records (subtract 1 for header)
        RECORD_COUNT=$(($(wc -l < "$CSV_PATH") - 1))
        
        # Ensure record count is not negative
        if [[ $RECORD_COUNT -lt 0 ]]; then
            RECORD_COUNT=0
        fi
        
        echo "SUCCESS: Saved $RECORD_COUNT records to $csv_file"
        RESULTS+=("SUCCESS:$description:$RECORD_COUNT records")
        ((SUCCESSFUL_EXECUTIONS++))
    else
        echo "ERROR: Failed to execute query for $description"
        RESULTS+=("FAILED:$description:Query execution failed")
    fi
done

# Print summary
echo ""
echo "=================================================================="
echo "EXECUTION SUMMARY"
echo "=================================================================="

for result in "${RESULTS[@]}"; do
    IFS=':' read -r status description info <<< "$result"
    echo "$status: $description"
    echo "  $info"
    echo ""
done

echo "Successfully executed $SUCCESSFUL_EXECUTIONS out of ${#QUERIES[@]} queries."

if [[ $SUCCESSFUL_EXECUTIONS -eq ${#QUERIES[@]} ]]; then
    echo ""
    echo "All queries executed successfully! CSV files have been overwritten with updated results."
    echo ""
    echo "NOTE: These results now exclude routing number 071025661 as specified."
    echo ""
    echo "Updated CSV files:"
    for query_info in "${QUERIES[@]}"; do
        IFS=':' read -r sql_file csv_file description <<< "$query_info"
        echo "  - ${RESULTS_DIR}/${csv_file}"
    done
else
    echo ""
    echo "Warning: $((${#QUERIES[@]} - SUCCESSFUL_EXECUTIONS)) queries failed to execute."
fi

echo ""
echo "=================================================================="