# IAM Permissions Setup for S3 and Athena

Complete guide to setting up IAM permissions for the S3/Athena video demo.

---

## What You Need

| Capability | Required For |
|------------|--------------|
| **S3 Bucket Creation** | Creating your own bucket for data and Athena results |
| **S3 Object Operations** | Uploading, downloading, listing files |
| **S3 Public Dataset Access** | Reading from `s3://wfclimres` (Wildfire data) |
| **Athena Query Execution** | Running SQL queries |
| **Glue Catalog Access** | Creating databases and tables |

---

## Step 1: Create IAM User (AWS Console)

1. Sign in to [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **IAM** → **Users** → **Create user**
3. Enter username: `claude-code-demo` (or your preference)
4. Click **Next**

---

## Step 2: Attach Permissions

### Option A: Use AWS Managed Policies (Quickest)

Attach these managed policies:
- `AmazonS3FullAccess`
- `AmazonAthenaFullAccess`
- `AWSGlueConsoleFullAccess`

**Note:** These are broad permissions. For production, use Option B.

### Option B: Create Custom Policy (Recommended)

1. Click **Create policy** → **JSON**
2. Paste this policy:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3BucketManagement",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:ListBucket",
                "s3:ListAllMyBuckets",
                "s3:GetBucketLocation",
                "s3:GetBucketPolicy",
                "s3:PutBucketPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "S3ObjectOperations",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::YOUR-BUCKET-NAME-*",
                "arn:aws:s3:::YOUR-BUCKET-NAME-*/*"
            ]
        },
        {
            "Sid": "S3PublicDatasetAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::wfclimres",
                "arn:aws:s3:::wfclimres/*",
                "arn:aws:s3:::nyc-tlc",
                "arn:aws:s3:::nyc-tlc/*",
                "arn:aws:s3:::noaa-gsod-pds",
                "arn:aws:s3:::noaa-gsod-pds/*"
            ]
        },
        {
            "Sid": "AthenaQueryExecution",
            "Effect": "Allow",
            "Action": [
                "athena:StartQueryExecution",
                "athena:StopQueryExecution",
                "athena:GetQueryExecution",
                "athena:GetQueryResults",
                "athena:GetWorkGroup",
                "athena:ListQueryExecutions",
                "athena:ListWorkGroups",
                "athena:BatchGetQueryExecution"
            ],
            "Resource": "*"
        },
        {
            "Sid": "GlueCatalogAccess",
            "Effect": "Allow",
            "Action": [
                "glue:GetDatabase",
                "glue:GetDatabases",
                "glue:CreateDatabase",
                "glue:DeleteDatabase",
                "glue:GetTable",
                "glue:GetTables",
                "glue:CreateTable",
                "glue:DeleteTable",
                "glue:UpdateTable",
                "glue:GetPartitions",
                "glue:CreatePartition",
                "glue:BatchCreatePartition"
            ],
            "Resource": "*"
        }
    ]
}
```

3. Name the policy: `S3-Athena-Demo-Policy`
4. **Create policy**
5. Return to user creation and attach your new policy

---

## Step 3: Create Access Keys

1. After creating the user, go to **Security credentials** tab
2. Click **Create access key**
3. Select **Command Line Interface (CLI)**
4. Check the confirmation box
5. Click **Create access key**
6. **IMPORTANT:** Save both:
   - Access key ID (starts with `AKIA...`)
   - Secret access key (only shown once!)

---

## Step 4: Configure AWS CLI

Run this command and enter your credentials:

```bash
aws configure
```

Enter when prompted:
- **AWS Access Key ID:** `AKIA...your-key...`
- **AWS Secret Access Key:** `your-secret-key`
- **Default region name:** `us-west-2` (for Wildfire data)
- **Default output format:** `json`

---

## Step 5: Verify Setup

```bash
# Check identity
aws sts get-caller-identity

# List your buckets
aws s3 ls

# Test access to Wildfire dataset
aws s3 ls s3://wfclimres/ --region us-west-2

# Test bucket creation
aws s3 mb s3://your-unique-bucket-name-demo-2024 --region us-west-2

# Verify bucket was created
aws s3 ls | grep demo
```

---

## Step 6: Set Up Athena Results Bucket

Athena requires an S3 location to store query results:

```bash
# Create results bucket (use a unique name)
aws s3 mb s3://your-athena-results-bucket-2024 --region us-west-2

# Verify
aws s3 ls | grep athena
```

---

## Troubleshooting

### "Access Denied" on Public Dataset

Public datasets require your AWS account to be in good standing. Verify:

```bash
aws sts get-caller-identity
```

If this works but public buckets fail, the bucket may require specific region:

```bash
aws s3 ls s3://wfclimres/ --region us-west-2
```

### "Unable to locate credentials"

```bash
# Check configuration
aws configure list

# If empty, reconfigure
aws configure
```

### "Bucket name already exists"

S3 bucket names are globally unique. Add random characters:

```bash
aws s3 mb s3://my-athena-demo-$(date +%s) --region us-west-2
```

### "Access Denied" Creating Bucket

Your IAM policy needs `s3:CreateBucket`. Verify policy is attached:

```bash
# This requires IAM read permissions
aws iam list-attached-user-policies --user-name YOUR-USER-NAME
```

Or check in AWS Console → IAM → Users → Your User → Permissions.

---

## Security Notes

1. **Protect credentials:**
   ```bash
   chmod 600 ~/.aws/credentials
   ```

2. **Never commit credentials to git**

3. **Rotate access keys** every 90 days

4. **Use least privilege** - the custom policy above is more restrictive than managed policies

---

## Quick Reference

```bash
# Initial setup
aws configure

# Verify identity
aws sts get-caller-identity

# Create bucket
aws s3 mb s3://bucket-name --region us-west-2

# List public dataset
aws s3 ls s3://wfclimres/ --region us-west-2

# Test Athena (requires workgroup setup)
aws athena list-work-groups
```

---

## Next Steps

Once setup is verified:
1. [Explore the Wildfire dataset](../sample_data/README.md)
2. [Run the example workflow](../example_workflow/README.md)
3. Start recording the demo!
