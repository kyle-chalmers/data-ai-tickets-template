#!/bin/bash
# QC Analysis: Identify loans without activity in each data source

cd "$(dirname "$0")/.."

echo "=== Loans Without Activity by Data Source ==="
echo ""

# All 15 target loans
cat ../../source_materials/attachment_c_15_loans.csv | tail -n +2 | sort > /tmp/all_15_loans.txt

# Extract unique PAYOFFUIDs from each CSV
tail -n +2 1_fortress_q3_2025_genesys_phonecall_activity.csv | cut -d',' -f7 | sort -u > /tmp/phone_loans.txt
tail -n +2 2_fortress_q3_2025_genesys_sms_activity.csv | cut -d',' -f6 | sort -u > /tmp/sms_loans.txt
tail -n +2 3_fortress_q3_2025_genesys_email_activity.csv | cut -d',' -f6 | sort -u > /tmp/email_loans.txt
tail -n +2 4_fortress_q3_2025_loan_notes.csv | cut -d',' -f1 | sort -u > /tmp/notes_loans.txt
tail -n +2 5_fortress_q3_2025_sfmc_email_activity.csv | cut -d',' -f2 | sort -u > /tmp/sfmc_loans.txt

echo "1. GENESYS PHONE CALLS - Loans WITHOUT Activity:"
comm -23 /tmp/all_15_loans.txt /tmp/phone_loans.txt | while read uuid; do
    loanid=$(grep "$uuid" ../../source_materials/attachment_c_15_loans.csv -A 20 | head -1 | cut -d',' -f2 2>/dev/null || echo "N/A")
    echo "   - $uuid"
done
echo ""

echo "2. GENESYS SMS - Loans WITHOUT Activity:"
comm -23 /tmp/all_15_loans.txt /tmp/sms_loans.txt | while read uuid; do
    echo "   - $uuid"
done
echo ""

echo "3. GENESYS EMAIL - Loans WITHOUT Activity:"
comm -23 /tmp/all_15_loans.txt /tmp/email_loans.txt | while read uuid; do
    echo "   - $uuid"
done
echo ""

echo "4. LOAN NOTES - Loans WITHOUT Activity:"
missing_notes=$(comm -23 /tmp/all_15_loans.txt /tmp/notes_loans.txt)
if [ -z "$missing_notes" ]; then
    echo "   ✓ ALL 15 loans have loan note records"
else
    echo "$missing_notes" | while read uuid; do
        echo "   - $uuid"
    done
fi
echo ""

echo "5. SFMC EMAIL - Loans WITHOUT Activity:"
comm -23 /tmp/all_15_loans.txt /tmp/sfmc_loans.txt | while read uuid; do
    echo "   - $uuid"
done
echo ""

echo "=== Summary ==="
phone_count=$(wc -l < /tmp/phone_loans.txt | xargs)
sms_count=$(wc -l < /tmp/sms_loans.txt | xargs)
email_count=$(wc -l < /tmp/email_loans.txt | xargs)
notes_count=$(wc -l < /tmp/notes_loans.txt | xargs)
sfmc_count=$(wc -l < /tmp/sfmc_loans.txt | xargs)

echo "- Phone Calls: $phone_count of 15 loans had activity ($(comm -23 /tmp/all_15_loans.txt /tmp/phone_loans.txt | wc -l | xargs) without)"
echo "- SMS: $sms_count of 15 loans had activity ($(comm -23 /tmp/all_15_loans.txt /tmp/sms_loans.txt | wc -l | xargs) without)"
echo "- Email: $email_count of 15 loans had activity ($(comm -23 /tmp/all_15_loans.txt /tmp/email_loans.txt | wc -l | xargs) without)"
echo "- Loan Notes: $notes_count of 15 loans had activity ($(comm -23 /tmp/all_15_loans.txt /tmp/notes_loans.txt | wc -l | xargs) without)"
echo "- SFMC: $sfmc_count of 15 loans had activity ($(comm -23 /tmp/all_15_loans.txt /tmp/sfmc_loans.txt | wc -l | xargs) without)"
