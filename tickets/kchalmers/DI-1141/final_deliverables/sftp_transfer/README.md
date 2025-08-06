# SFTP Transfer Utilities - DI-1141

This folder contains all utilities and credentials needed to transfer Bounce Q2 2025 debt sale files to the SFTP server.

## Files in this folder

### Authentication
- `bounce_sftp_key` - SSH private key for SFTP authentication (600 permissions)

### Transfer Tools
- `transfer_bounce_files.py` - Automated Python script using paramiko
- `jira_transfer_confirmation.txt` - Transfer completion confirmation log

## Connection Details
- **Server:** sftp.finbounce.com
- **Username:** happy-money
- **Remote Directory:** /lendercsvbucket/happy-money
- **Authentication:** SSH key-based (no password)

## Quick Transfer
Run the automated transfer script:
```bash
python3 transfer_bounce_files.py
```

## Manual Transfer
For manual SFTP transfer:
```bash
sftp -i bounce_sftp_key -o StrictHostKeyChecking=no happy-money@sftp.finbounce.com
cd /lendercsvbucket/happy-money
put ../results_data/Bounce_Q2_2025_Debt_Sale_Population_1591_loans_FINAL.csv
put ../results_data/Bounce_Q2_2025_Debt_Sale_Transactions_52482_transactions_FINAL.csv
ls -la
bye
```

## Transfer Status
✅ **Completed:** August 4, 2025 at 10:09 AM PST
- Population file: 1,121,609 bytes
- Transaction file: 18,839,057 bytes
- Both files verified on remote server

## Security Notes
- SSH key has 600 permissions (owner read/write only)
- Key is also backed up to Google Drive
- Connection uses StrictHostKeyChecking=no for automation