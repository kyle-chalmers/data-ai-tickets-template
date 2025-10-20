#!/bin/bash
# DI-1300: Run all collection activity queries

cd "$(dirname "$0")"
OUTPUT_DIR="../final_deliverables"

echo "Starting DI-1300 collection activity queries..."
echo "Output directory: $OUTPUT_DIR"
echo ""

# Step 1: Setup temp tables (this MUST be run in the same session as queries)
echo "[1/6] Setting up temp tables..."
snow sql -f 0_setup_temp_tables.sql

# Since temp tables don't persist between sessions, we need to run each query
# with the setup included. Let's create combined scripts.

echo "[2/6] Running Query 1: Genesys Phone Call Activity..."
cat 0_setup_temp_tables.sql 1_query_genesys_phonecall.sql | snow sql --format csv > "$OUTPUT_DIR/1_fortress_q3_2025_genesys_phonecall_activity.csv"

echo "[3/6] Running Query 2: Genesys SMS Activity..."
cat 0_setup_temp_tables.sql 2_query_genesys_sms.sql | snow sql --format csv > "$OUTPUT_DIR/2_fortress_q3_2025_genesys_sms_activity.csv"

echo "[4/6] Running Query 3: Genesys Email Activity..."
cat 0_setup_temp_tables.sql 3_query_genesys_email.sql | snow sql --format csv > "$OUTPUT_DIR/3_fortress_q3_2025_genesys_email_activity.csv"

echo "[5/6] Running Query 4: Loan Notes..."
cat 0_setup_temp_tables.sql 4_query_loan_notes.sql | snow sql --format csv > "$OUTPUT_DIR/4_fortress_q3_2025_loan_notes.csv"

echo "[6/6] Running Query 5: SFMC Email Activity..."
cat 0_setup_temp_tables.sql 5_query_sfmc_email.sql | snow sql --format csv > "$OUTPUT_DIR/5_fortress_q3_2025_sfmc_email_activity.csv"

echo ""
echo "All queries completed!"
echo "Checking output files..."
ls -lh "$OUTPUT_DIR"/*.csv

echo ""
echo "Record counts:"
for file in "$OUTPUT_DIR"/*.csv; do
    count=$(wc -l < "$file")
    echo "  $(basename "$file"): $count lines"
done
