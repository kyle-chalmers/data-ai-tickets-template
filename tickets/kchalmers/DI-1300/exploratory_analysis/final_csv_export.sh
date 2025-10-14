#!/bin/bash
# Final CSV export - extract only CSV data from snow sql output

cd "$(dirname "$0")"
OUTPUT_DIR="../final_deliverables"

echo "Exporting all 5 queries to CSV..."

# Query 1: Genesys Phone Call
echo "[1/5] Genesys Phone Call Activity..."
snow sql -f combined_query_1.sql --format csv 2>/dev/null | \
  awk '/^RECORDING_URL,/{flag=1} flag' > "$OUTPUT_DIR/1_fortress_q3_2025_genesys_phonecall_activity.csv"

# Create combined files for remaining queries
# Query 2: SMS
cat 0_setup_temp_tables.sql 2_query_genesys_sms.sql > /tmp/combined_query_2.sql
echo "[2/5] Genesys SMS Activity..."
snow sql -f /tmp/combined_query_2.sql --format csv 2>/dev/null | \
  awk '/^INTERACTION_START_TIME,/{flag=1} flag' > "$OUTPUT_DIR/2_fortress_q3_2025_genesys_sms_activity.csv"

# Query 3: Email
cat 0_setup_temp_tables.sql 3_query_genesys_email.sql > /tmp/combined_query_3.sql
echo "[3/5] Genesys Email Activity..."
snow sql -f /tmp/combined_query_3.sql --format csv 2>/dev/null | \
  awk '/^INTERACTION_START_TIME,/{flag=1} flag' > "$OUTPUT_DIR/3_fortress_q3_2025_genesys_email_activity.csv"

# Query 4: Loan Notes
cat 0_setup_temp_tables.sql 4_query_loan_notes.sql > /tmp/combined_query_4.sql
echo "[4/5] Loan Notes..."
snow sql -f /tmp/combined_query_4.sql --format csv 2>/dev/null | \
  awk '/^PAYOFFUID,/{flag=1} flag' > "$OUTPUT_DIR/4_fortress_q3_2025_loan_notes.csv"

# Query 5: SFMC Email
cat 0_setup_temp_tables.sql 5_query_sfmc_email.sql > /tmp/combined_query_5.sql
echo "[5/5] SFMC Email Activity..."
snow sql -f /tmp/combined_query_5.sql --format csv 2>/dev/null | \
  awk '/^sent,/{flag=1} flag' > "$OUTPUT_DIR/5_fortress_q3_2025_sfmc_email_activity.csv"

echo ""
echo "Export complete!"
echo ""
ls -lh "$OUTPUT_DIR"/*.csv

echo ""
echo "Record counts:"
for file in "$OUTPUT_DIR"/*.csv; do
    count=$(($(wc -l < "$file") - 1))
    echo "  $(basename "$file"): $count records"
done
