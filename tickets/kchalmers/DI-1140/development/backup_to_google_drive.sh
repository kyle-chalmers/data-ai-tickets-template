#!/bin/bash

# DI-1140 Google Drive Backup Script
# Backs up all final deliverables to Google Drive

echo "Starting Google Drive backup for DI-1140..."

# Create a timestamp for the backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="DI-1140_BMO_Fraud_Investigation_${TIMESTAMP}"

# Create backup directory structure
echo "Creating backup directory: ${BACKUP_NAME}"

# Zip the final deliverables
cd /Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1140
zip -r "${BACKUP_NAME}.zip" final_deliverables/ sql_queries/

echo "Backup created: ${BACKUP_NAME}.zip"
echo "Size: $(du -h ${BACKUP_NAME}.zip | cut -f1)"

# Note: To upload to Google Drive, you would typically use:
# - Google Drive API
# - rclone configured with Google Drive
# - gdrive CLI tool
# 
# Example with gdrive:
# gdrive upload "${BACKUP_NAME}.zip"

echo "Backup complete. Ready for manual upload to Google Drive."
echo "File location: /Users/kchalmers/Development/data-intelligence-tickets/tickets/kchalmers/DI-1140/${BACKUP_NAME}.zip"