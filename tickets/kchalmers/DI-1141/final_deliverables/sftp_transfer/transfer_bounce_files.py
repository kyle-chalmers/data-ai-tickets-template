#!/usr/bin/env python3
"""
Transfer Bounce Q2 2025 debt sale files to SFTP server
DI-1141: Sale Files for Bounce - Q2 2025 Sale
"""
import paramiko
import os
import sys
from datetime import datetime

def transfer_files():
    # SFTP connection details from JIRA comment
    hostname = 'sftp.finbounce.com'
    username = 'happy-money'
    private_key_path = os.path.join(os.path.dirname(__file__), 'bounce_sftp_key')
    remote_directory = '/lendercsvbucket/happy-money'
    
    # Files to transfer
    base_path = '/Users/kchalmers/Library/CloudStorage/GoogleDrive-kchalmers@happymoney.com/Shared drives/Data Intelligence/Tickets/Kyle Chalmers/DI-1141/final_deliverables'
    files_to_transfer = [
        {
            'local_path': f'{base_path}/Bounce_Q2_2025_Debt_Sale_Population_1591_loans_FINAL.csv',
            'remote_name': 'Bounce_Q2_2025_Debt_Sale_Population_1591_loans_FINAL.csv'
        },
        {
            'local_path': f'{base_path}/Bounce_Q2_2025_Debt_Sale_Transactions_52482_transactions_FINAL.csv',
            'remote_name': 'Bounce_Q2_2025_Debt_Sale_Transactions_52482_transactions_FINAL.csv'
        }
    ]
    
    try:
        print("=== Bounce Q2 2025 Debt Sale File Transfer ===")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # Verify local files exist
        print("Checking local files...")
        for file_info in files_to_transfer:
            local_path = file_info['local_path']
            if not os.path.exists(local_path):
                raise FileNotFoundError(f"Local file not found: {local_path}")
            
            file_size = os.path.getsize(local_path)
            print(f"✅ {os.path.basename(local_path)} ({file_size:,} bytes)")
        print()
        
        # Load the private key
        print("Loading SSH private key...")
        private_key = paramiko.RSAKey.from_private_key_file(private_key_path)
        
        # Create SSH client
        print("Connecting to SFTP server...")
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        # Connect to the server
        ssh_client.connect(
            hostname=hostname,
            username=username,
            pkey=private_key,
            timeout=30
        )
        
        # Create SFTP client
        sftp_client = ssh_client.open_sftp()
        
        # Change to target directory
        sftp_client.chdir(remote_directory)
        print(f"Changed to remote directory: {remote_directory}")
        print()
        
        # Transfer each file
        for i, file_info in enumerate(files_to_transfer, 1):
            local_path = file_info['local_path']
            remote_name = file_info['remote_name']
            
            print(f"[{i}/{len(files_to_transfer)}] Transferring {remote_name}...")
            
            # Check if file already exists on remote
            try:
                remote_stat = sftp_client.stat(remote_name)
                print(f"⚠️  File already exists on remote (size: {remote_stat.st_size:,} bytes)")
                response = input("Overwrite? (y/N): ").strip().lower()
                if response != 'y':
                    print("Skipping file transfer")
                    continue
            except FileNotFoundError:
                print("File does not exist on remote - proceeding with transfer")
            
            # Transfer the file
            start_time = datetime.now()
            sftp_client.put(local_path, remote_name)
            end_time = datetime.now()
            
            # Verify transfer
            remote_stat = sftp_client.stat(remote_name)
            local_size = os.path.getsize(local_path)
            
            if remote_stat.st_size == local_size:
                duration = (end_time - start_time).total_seconds()
                print(f"✅ Transfer successful! ({local_size:,} bytes in {duration:.1f}s)")
            else:
                print(f"❌ Transfer verification failed! Local: {local_size:,}, Remote: {remote_stat.st_size:,}")
                return False
            print()
        
        # List final directory contents
        print("Final remote directory listing:")
        files = sftp_client.listdir('.')
        for file in sorted(files):
            if file.endswith('.csv') or 'Bounce' in file:
                stat = sftp_client.stat(file)
                print(f"  {file} ({stat.st_size:,} bytes)")
        
        # Close connections
        sftp_client.close()
        ssh_client.close()
        
        print()
        print("🎉 All files transferred successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Transfer failed: {e}")
        return False

if __name__ == "__main__":
    success = transfer_files()
    sys.exit(0 if success else 1)