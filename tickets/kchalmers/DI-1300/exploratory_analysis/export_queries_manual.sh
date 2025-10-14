#!/bin/bash
# DI-1300: Manual CSV export with proper formatting
# This script combines setup + query, runs snow sql, and extracts CSV from output

cd "$(dirname "$0")"
OUTPUT_DIR="../final_deliverables"

echo "Exporting DI-1300 collection activity queries to CSV..."
echo ""

# Query 1: Genesys Phone Call Activity
echo "[1/5] Exporting Genesys Phone Call Activity..."
cat 0_setup_temp_tables.sql 1_query_genesys_phonecall.sql > /tmp/query1.sql
snow sql -f /tmp/query1.sql --format csv -o output_format=csv -o header=true -o timing=false 2>/dev/null | \
  grep -v "^USE WAREHOUSE" | grep -v "^SET " | grep -v "^CREATE" | grep -v "^SELECT 'Setup" | \
  grep -v "Statement executed" | grep -v "^+--" | grep -v "^|" | \
  grep -v "Table.*successfully created" | grep -v "^$" > "$OUTPUT_DIR/1_fortress_q3_2025_genesys_phonecall_activity.csv"

# Query 2: Genesys SMS Activity
echo "[2/5] Exporting Genesys SMS Activity..."
cat 0_setup_temp_tables.sql 2_query_genesys_sms.sql > /tmp/query2.sql
snow sql -f /tmp/query2.sql --format csv -o output_format=csv -o header=true -o timing=false 2>/dev/null | \
  grep -v "^USE WAREHOUSE" | grep -v "^SET " | grep -v "^CREATE" | grep -v "^SELECT 'Setup" | \
  grep -v "Statement executed" | grep -v "^+--" | grep -v "^|" | \
  grep -v "Table.*successfully created" | grep -v "^$" > "$OUTPUT_DIR/2_fortress_q3_2025_genesys_sms_activity.csv"

# Query 3: Genesys Email Activity
echo "[3/5] Exporting Genesys Email Activity..."
cat 0_setup_temp_tables.sql 3_query_genesys_email.sql > /tmp/query3.sql
snow sql -f /tmp/query3.sql --format csv -o output_format=csv -o header=true -o timing=false 2>/dev/null | \
  grep -v "^USE WAREHOUSE" | grep -v "^SET " | grep -v "^CREATE" | grep -v "^SELECT 'Setup" | \
  grep -v "Statement executed" | grep -v "^+--" | grep -v "^|" | \
  grep -v "Table.*successfully created" | grep -v "^$" > "$OUTPUT_DIR/3_fortress_q3_2025_genesys_email_activity.csv"

# Query 4: Loan Notes
echo "[4/5] Exporting Loan Notes..."
cat 0_setup_temp_tables.sql 4_query_loan_notes.sql > /tmp/query4.sql
snow sql -f /tmp/query4.sql --format csv -o output_format=csv -o header=true -o timing=false 2>/dev/null | \
  grep -v "^USE WAREHOUSE" | grep -v "^SET " | grep -v "^CREATE" | grep -v "^SELECT 'Setup" | \
  grep -v "Statement executed" | grep -v "^+--" | grep -v "^|" | \
  grep -v "Table.*successfully created" | grep -v "^$" > "$OUTPUT_DIR/4_fortress_q3_2025_loan_notes.csv"

# Query 5: SFMC Email Activity
echo "[5/5] Exporting SFMC Email Activity..."
cat 0_setup_temp_tables.sql 5_query_sfmc_email.sql > /tmp/query5.sql
snow sql -f /tmp/query5.sql --format csv -o output_format=csv -o header=true -o timing=false 2>/dev/null | \
  grep -v "^USE WAREHOUSE" | grep -v "^SET " | grep -v "^CREATE" | grep -v "^SELECT 'Setup" | \
  grep -v "Statement executed" | grep -v "^+--" | grep -v "^|" | \
  grep -v "Table.*successfully created" | grep -v "^$" > "$OUTPUT_DIR/5_fortress_q3_2025_sfmc_email_activity.csv"

# Cleanup temp files
rm -f /tmp/query*.sql

echo ""
echo "Export completed!"
echo ""
echo "Checking CSV files..."
ls -lh "$OUTPUT_DIR"/*.csv

echo ""
echo "Record counts (excluding headers):"
for file in "$OUTPUT_DIR"/*.csv; do
    if [ -f "$file" ]; then
        count=$(($(wc -l < "$file") - 1))
        echo "  $(basename "$file"): $count records"
    fi
done

echo ""
echo "Sample from first file:"
head -3 "$OUTPUT_DIR/1_fortress_q3_2025_genesys_phonecall_activity.csv"
