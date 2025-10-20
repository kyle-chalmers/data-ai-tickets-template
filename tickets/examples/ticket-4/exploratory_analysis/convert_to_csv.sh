#!/bin/bash
# Convert snow SQL table output to CSV
# Extracts only the final query result table from snow sql output

cd "$(dirname "$0")"
OUTPUT_DIR="../final_deliverables"

convert_query_to_csv() {
    local setup_file="$1"
    local query_file="$2"
    local output_file="$3"
    local query_name="$4"

    echo "[$query_name] Running query..."

    # Run query and save raw output
    cat "$setup_file" "$query_file" | snow sql > /tmp/raw_output.txt 2>&1

    # Extract only the LAST table from the output (the actual query result)
    # This skips all the setup table outputs
    python3 << 'PYTHON_SCRIPT' "$output_file"
import sys
import re

output_file = sys.argv[1]

# Read the raw output
with open('/tmp/raw_output.txt', 'r') as f:
    content = f.read()

# Find all table-like structures (lines with +---+ borders)
tables = []
current_table = []
in_table = False

for line in content.split('\n'):
    if line.startswith('+---') or line.startswith('|'):
        if not in_table:
            current_table = []
            in_table = True
        current_table.append(line)
    elif in_table and line.strip() == '':
        if current_table:
            tables.append(current_table)
            current_table = []
        in_table = False

# Add last table if exists
if current_table:
    tables.append(current_table)

# Get the last table (should be our query result)
if not tables:
    print("No table found in output", file=sys.stderr)
    sys.exit(1)

last_table = tables[-1]

# Parse table to CSV
csv_lines = []
for line in last_table:
    if line.startswith('|') and not line.startswith('+'):
        # Split by | and clean up
        cells = [cell.strip() for cell in line.split('|')[1:-1]]
        # Quote cells that contain commas
        cells = [f'"{cell}"' if ',' in cell else cell for cell in cells]
        csv_lines.append(','.join(cells))

# Remove the separator line (usually second line)
if len(csv_lines) > 1:
    # Check if second line is all dashes
    if all(c in '-+| ' for c in last_table[1]):
        csv_lines = [csv_lines[0]] + csv_lines[2:]

# Write to output file
with open(output_file, 'w') as f:
    for line in csv_lines:
        f.write(line + '\n')

print(f"Converted {len(csv_lines)} lines to {output_file}")
PYTHON_SCRIPT

    local record_count=$(($(wc -l < "$output_file") - 1))
    echo "   Saved $record_count records to $(basename "$output_file")"
}

echo "Converting DI-1300 queries to CSV..."
echo ""

convert_query_to_csv "0_setup_temp_tables.sql" "1_query_genesys_phonecall.sql" \
    "$OUTPUT_DIR/1_fortress_q3_2025_genesys_phonecall_activity.csv" "1/5"

convert_query_to_csv "0_setup_temp_tables.sql" "2_query_genesys_sms.sql" \
    "$OUTPUT_DIR/2_fortress_q3_2025_genesys_sms_activity.csv" "2/5"

convert_query_to_csv "0_setup_temp_tables.sql" "3_query_genesys_email.sql" \
    "$OUTPUT_DIR/3_fortress_q3_2025_genesys_email_activity.csv" "3/5"

convert_query_to_csv "0_setup_temp_tables.sql" "4_query_loan_notes.sql" \
    "$OUTPUT_DIR/4_fortress_q3_2025_loan_notes.csv" "4/5"

convert_query_to_csv "0_setup_temp_tables.sql" "5_query_sfmc_email.sql" \
    "$OUTPUT_DIR/5_fortress_q3_2025_sfmc_email_activity.csv" "5/5"

echo ""
echo "Conversion complete!"
echo ""
ls -lh "$OUTPUT_DIR"/*.csv
