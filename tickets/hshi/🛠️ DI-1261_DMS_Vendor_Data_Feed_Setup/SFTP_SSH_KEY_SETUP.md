# DMS SFTP - SSH Key Authentication Setup

**Date**: October 7, 2025
**Status**: ✅ Complete and Ready for Testing

---

## Setup Summary

DI-1261 job configured to use **SSH key authentication** instead of password-based authentication for secure SFTP file transfer to DMS.

---

## SSH Key Details

### Private Key Location
```
/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem
```

**Storage**:
- S3: `s3://hm-rstudio-datascience-cron/secrets/sftp_key/sftp_privatekey_dms.pem`
- DBFS: Mounted and accessible to Databricks jobs
- Access: Restricted to authorized jobs only

### Public Key
- ✅ Uploaded to DMS server by user
- ✅ Added to DMS authorized_keys
- ✅ Ready for authentication

---

## DMS SFTP Connection

| Parameter | Value |
|-----------|-------|
| Host | ftp-01.teamdms.com |
| Port | 22 |
| Username | hshi@happymoney.com |
| Authentication | SSH Private Key |
| Library | paramiko |

---

## Implementation

### Code Pattern
```python
import paramiko

# Connection details
host = "ftp-01.teamdms.com"
port = 22
username = "hshi@happymoney.com"
private_key_path = "/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem"

# Load private key
private_key = paramiko.RSAKey.from_private_key_file(private_key_path)

# Connect to SFTP
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
ssh.connect(hostname=host, username=username, pkey=private_key, port=port)

# Upload file
sftp = ssh.open_sftp()
sftp.put(local_file, remote_file)
sftp.close()
ssh.close()
```

### Benefits vs Password Authentication

| Aspect | SSH Key | Password |
|--------|---------|----------|
| Security | ✅ High | ⚠️ Medium |
| Secrets Management | ✅ No secrets needed | ❌ Databricks secrets required |
| Industry Standard | ✅ Yes | ❌ Legacy |
| Error Handling | ✅ Python exceptions | ⚠️ Shell exit codes |
| Code Quality | ✅ Clean Python | ⚠️ Subprocess + bash |

---

## Reference Implementations

### Similar Jobs Using SSH Keys

**DI-566 (Experian)**:
```python
# Downloads key from S3 to /tmp/
private_key_path = '/tmp/sftp_ssh4k_rsa'
s3.download_file(bucket_name, private_key_name, private_key_path)
key = paramiko.RSAKey.from_private_key_file(private_key_path)
```

**DI-1223 (Bounce)**:
```python
# Uses key from DBFS FileStore
private_key_path = "/dbfs/FileStore/shared_uploads/bounce_sftp_key"
private_key = paramiko.RSAKey.from_private_key_file(private_key_path)
```

**DI-916 (Credit Karma)**:
```python
# Uses key with passphrase from secrets
private_key_content = dbutils.secrets.get(scope="credit_karma_secrets", key="credit_karma_sftp_private_key")
key = paramiko.RSAKey.from_private_key_file(private_key_path, password=key_passphrase)
```

**DI-1261 (DMS)** - Current Implementation:
```python
# Uses key from shared SFTP key folder (same as other vendors)
private_key_path = "/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem"
private_key = paramiko.RSAKey.from_private_key_file(private_key_path)
```

---

## Testing

### Manual Connection Test

Run this in a Databricks notebook to verify SSH key authentication:

```python
import paramiko

# Connection details
host = "ftp-01.teamdms.com"
port = 22
username = "hshi@happymoney.com"
private_key_path = "/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem"

# Load private key
print("Loading private key...")
try:
    private_key = paramiko.RSAKey.from_private_key_file(private_key_path)
    print("✅ Private key loaded successfully")
except Exception as e:
    print(f"❌ Failed to load private key: {str(e)}")
    raise

# Connect to SFTP server
print(f"Connecting to {host}...")
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

try:
    ssh.connect(hostname=host, username=username, pkey=private_key, port=port)
    print("✅ SSH connection established")

    sftp = ssh.open_sftp()
    print("✅ SFTP session opened")

    # List files in root directory
    files = sftp.listdir('/')
    print(f"Files in root directory: {files}")

    sftp.close()
    print("✅ Connection test successful!")

except Exception as e:
    print(f"❌ Connection failed: {str(e)}")
    raise

finally:
    ssh.close()
```

### Expected Output
```
Loading private key...
✅ Private key loaded successfully
Connecting to ftp-01.teamdms.com...
✅ SSH connection established
✅ SFTP session opened
Files in root directory: [...]
✅ Connection test successful!
```

---

## Troubleshooting

### Error: "Permission denied (publickey)"
**Cause**: Public key not properly added to DMS server
**Solution**: Verify with DMS that public key was uploaded correctly

### Error: "No such file or directory"
**Cause**: Private key path incorrect or file doesn't exist
**Solution**: Verify key file exists:
```python
import os
key_path = "/dbfs/mnt/rstudio/cron/secrets/sftp_key/sftp_privatekey_dms.pem"
print(f"Key exists: {os.path.exists(key_path)}")
```

### Error: "Could not deserialize key data"
**Cause**: Invalid or corrupted private key file
**Solution**: Re-upload private key to S3

### Error: "Connection timeout"
**Cause**: Network issue or wrong hostname
**Solution**: Verify host `ftp-01.teamdms.com` is accessible from Databricks

---

## Security Notes

### Key Protection
- ✅ Private key never stored in code or version control
- ✅ Stored in S3 with restricted access
- ✅ Mounted in Databricks via secure DBFS mount
- ✅ Only accessible to authorized Databricks jobs

### Key Rotation
To rotate SSH keys in the future:
1. Generate new SSH key pair
2. Upload new public key to DMS
3. Upload new private key to S3 (same path: `secrets/sftp_key/sftp_privatekey_dms.pem`)
4. Test connection with new key
5. DMS removes old public key from server

---

## Deployment Status

### ✅ Setup Complete
- [x] SSH key pair generated
- [x] Public key uploaded to DMS server
- [x] Private key uploaded to S3
- [x] Private key accessible in Databricks DBFS
- [x] Job code updated to use SSH key authentication
- [x] paramiko library added to job dependencies

### ⏳ Testing Required (Pending IP Whitelisting)
- [ ] Get Databricks workspace IP addresses
- [ ] Request DMS to whitelist Databricks IPs
- [ ] Manual SSH connection test in Databricks
- [ ] Test file upload to DMS SFTP
- [ ] Verify file appears on DMS server
- [ ] End-to-end job test in dev environment

---

**Status**: ⏳ SSH Key Setup Complete - Pending Databricks IP Whitelisting by DMS
**Last Updated**: October 9, 2025
