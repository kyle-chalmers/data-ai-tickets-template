# AWS CLI Setup Guide

Complete setup guide for AWS CLI integration with Claude Code.

---

## Prerequisites

- AWS Account
- macOS, Linux, or Windows
- Admin access to install software
- AWS IAM user with programmatic access

---

## Step 1: Install AWS CLI

### macOS (Homebrew)

```bash
brew install awscli
```

### macOS (Official Installer)

```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
rm AWSCLIV2.pkg
```

### Linux

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws/
```

### Windows

Download and run the installer:
https://awscli.amazonaws.com/AWSCLIV2.msi

### Verify Installation

```bash
aws --version
# Expected: aws-cli/2.x.x Python/3.x.x ...
```

---

## Step 2: Create IAM User and Access Keys

### Option A: AWS Console (Recommended for New Users)

1. Sign in to [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **IAM** → **Users** → **Create user**
3. Enter username (e.g., `claude-code-user`)
4. Select **Attach policies directly**
5. Attach these policies:
   - `AmazonS3FullAccess` (or scoped policy - see below)
   - `AmazonAthenaFullAccess`
   - `AWSGlueConsoleFullAccess`
6. Click **Create user**
7. Go to **Security credentials** tab
8. Click **Create access key**
9. Select **Command Line Interface (CLI)**
10. Save the Access Key ID and Secret Access Key

### Option B: AWS CLI (If You Already Have Admin Access)

```bash
# Create user
aws iam create-user --user-name claude-code-user

# Attach policies
aws iam attach-user-policy \
  --user-name claude-code-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-user-policy \
  --user-name claude-code-user \
  --policy-arn arn:aws:iam::aws:policy/AmazonAthenaFullAccess

aws iam attach-user-policy \
  --user-name claude-code-user \
  --policy-arn arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess

# Create access key
aws iam create-access-key --user-name claude-code-user
```

---

## Step 3: Configure AWS CLI

### Basic Configuration

```bash
aws configure
```

Enter when prompted:
- **AWS Access Key ID**: Your access key
- **AWS Secret Access Key**: Your secret key
- **Default region name**: e.g., `us-east-1`
- **Default output format**: `json` (recommended)

### Verify Configuration

```bash
# Check identity
aws sts get-caller-identity

# Expected output:
{
    "UserId": "AIDAEXAMPLEID",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/claude-code-user"
}
```

### Test S3 Access

```bash
aws s3 ls
```

---

## Step 4: Configure Claude Code Permissions

Add AWS CLI permissions to your `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(aws sts get-caller-identity)",
      "Bash(aws s3 ls*)",
      "Bash(aws s3 cp*)",
      "Bash(aws s3 sync*)",
      "Bash(aws glue get-*)",
      "Bash(aws athena list-*)",
      "Bash(aws athena get-*)",
      "Bash(aws athena start-query-execution*)"
    ],
    "ask": [
      "Bash(aws s3 rm*)",
      "Bash(aws s3 mv*)",
      "Bash(aws glue create-*)",
      "Bash(aws glue delete-*)"
    ],
    "deny": [
      "Bash(aws iam *)",
      "Bash(aws ec2 *)",
      "Bash(aws rds *)"
    ]
  }
}
```

---

## Step 5: Set Up Athena

### Create Results Bucket

Athena requires an S3 bucket to store query results:

```bash
# Create bucket (bucket names must be globally unique)
aws s3 mb s3://my-athena-results-bucket-12345

# Verify
aws s3 ls | grep athena
```

### Configure Default Workgroup

```bash
# Check current workgroup settings
aws athena get-work-group --work-group primary

# Update to use your results bucket
aws athena update-work-group \
  --work-group primary \
  --configuration-updates '{
    "ResultConfigurationUpdates": {
      "OutputLocation": "s3://my-athena-results-bucket-12345/"
    }
  }'
```

---

## Step 6: Test the Integration

### S3 Test

```bash
# List buckets
aws s3 ls

# Create test file
echo "id,name,value" > test.csv
echo "1,test,100" >> test.csv

# Upload to S3
aws s3 cp test.csv s3://your-bucket/test/test.csv

# Verify
aws s3 ls s3://your-bucket/test/

# Cleanup
rm test.csv
```

### Athena Test

```bash
# Simple query (replace with your database)
aws athena start-query-execution \
  --query-string "SELECT 1 as test" \
  --work-group "primary" \
  --output text --query 'QueryExecutionId'

# Check result (use the returned ID)
aws athena get-query-results --query-execution-id YOUR_QUERY_ID
```

---

## Named Profiles (Optional)

For multiple AWS accounts or environments:

### Create Profiles

```bash
# Production profile
aws configure --profile production

# Development profile
aws configure --profile development
```

### Use Profiles

```bash
# Specify profile per command
aws s3 ls --profile production

# Or set environment variable
export AWS_PROFILE=production
aws s3 ls
```

### Profile Configuration Files

**~/.aws/credentials:**
```ini
[default]
aws_access_key_id = AKIA...DEFAULT
aws_secret_access_key = secret...default

[production]
aws_access_key_id = AKIA...PROD
aws_secret_access_key = secret...prod

[development]
aws_access_key_id = AKIA...DEV
aws_secret_access_key = secret...dev
```

**~/.aws/config:**
```ini
[default]
region = us-east-1
output = json

[profile production]
region = us-west-2
output = json

[profile development]
region = us-east-1
output = json
```

---

## Security Best Practices

### 1. Secure Credentials File

```bash
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
ls -la ~/.aws/
```

### 2. Use Least Privilege

Instead of full access policies, create scoped policies:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-data-bucket",
        "arn:aws:s3:::my-data-bucket/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "athena:StartQueryExecution",
        "athena:GetQueryExecution",
        "athena:GetQueryResults"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. Rotate Access Keys

```bash
# Create new key
aws iam create-access-key --user-name claude-code-user

# Update configuration with new key
aws configure

# Delete old key
aws iam delete-access-key \
  --user-name claude-code-user \
  --access-key-id OLD_KEY_ID
```

### 4. Never Commit Credentials

Add to `.gitignore`:
```
.aws/
*.pem
*.key
```

---

## Troubleshooting

### "Unable to locate credentials"

```bash
# Check configuration
aws configure list

# Verify files exist
ls -la ~/.aws/

# Check environment variables
echo $AWS_ACCESS_KEY_ID
echo $AWS_PROFILE
```

### "Access Denied"

```bash
# Check current identity
aws sts get-caller-identity

# List attached policies
aws iam list-attached-user-policies --user-name YOUR_USER
```

### "Region not specified"

```bash
# Set default region
aws configure set region us-east-1

# Or specify per command
aws s3 ls --region us-east-1
```

### "Athena query failed"

```bash
# Get error details
aws athena get-query-execution \
  --query-execution-id YOUR_QUERY_ID \
  --query 'QueryExecution.Status'
```

---

## Quick Reference

```bash
# Installation
brew install awscli

# Configuration
aws configure
aws sts get-caller-identity

# Test commands
aws s3 ls
aws glue get-databases
aws athena list-work-groups

# Security
chmod 600 ~/.aws/credentials
```

---

## Next Steps

1. [Explore the example workflow](../example_workflow/README.md)
2. Review the [CLAUDE.md reference](../CLAUDE.md) for common commands
3. Set up your first S3 bucket and Athena database
