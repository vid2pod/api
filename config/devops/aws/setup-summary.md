# AWS S3 Bucket Setup Summary

This document summarizes all the commands used to set up the `downloads.vid2pod.com` S3 bucket and IAM user.

## 1. Create S3 Bucket

```bash
aws s3 mb s3://downloads.vid2pod.com --profile personal --region us-east-1
```

Created the S3 bucket `downloads.vid2pod.com` in the `us-east-1` region.

## 2. Disable Block Public Access

```bash
aws s3api put-public-access-block \
  --bucket downloads.vid2pod.com \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
  --profile personal
```

Disabled Block Public Access settings to allow public read access to objects in the bucket.

## 3. Apply Bucket Policy

```bash
aws s3api put-bucket-policy \
  --bucket downloads.vid2pod.com \
  --policy file://config/aws/bucket-policy.json \
  --profile personal
```

Applied the bucket policy from `config/aws/bucket-policy.json` to allow public read access to all objects.

## 4. Apply CORS Policy

```bash
aws s3api put-bucket-cors \
  --bucket downloads.vid2pod.com \
  --cors-configuration file://config/aws/cors-policy.json \
  --profile personal
```

Applied the CORS policy from `config/aws/cors-policy.json` to allow cross-origin GET and HEAD requests.

## 5. Create IAM User

```bash
aws iam create-user \
  --user-name vid2pod-downloads \
  --profile personal
```

Created IAM user `vid2pod-downloads` with the following details:
- User ID: `[REDACTED]`
- ARN: `arn:aws:iam::[ACCOUNT_ID]:user/vid2pod-downloads`

## 6. Create IAM Policy

```bash
aws iam create-policy \
  --policy-name vid2pod-downloads-policy \
  --policy-document file://config/aws/iam-policy.json \
  --profile personal
```

Created IAM policy `vid2pod-downloads-policy` with the following details:
- Policy ID: `[REDACTED]`
- ARN: `arn:aws:iam::[ACCOUNT_ID]:policy/vid2pod-downloads-policy`

This policy grants the following permissions on the `downloads.vid2pod.com` bucket:
- `s3:PutObject`
- `s3:GetObject`
- `s3:DeleteObject`
- `s3:ListBucket`

## 7. Attach Policy to User

```bash
aws iam attach-user-policy \
  --user-name vid2pod-downloads \
  --policy-arn arn:aws:iam::[ACCOUNT_ID]:policy/vid2pod-downloads-policy \
  --profile personal
```

Attached the `vid2pod-downloads-policy` to the `vid2pod-downloads` user.

## 8. Generate Access Credentials

```bash
aws iam create-access-key \
  --user-name vid2pod-downloads \
  --profile personal
```

Generated access credentials for the IAM user. The credentials have been saved to `.env.production` as:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## Summary

The S3 bucket `downloads.vid2pod.com` is now configured with:
- Public read access for all objects
- CORS enabled for GET and HEAD requests from any origin
- An IAM user `vid2pod-downloads` with full access to manage objects in the bucket
- Credentials stored in `.env.production`

## Configuration Files Used

- `config/aws/bucket-policy.json` - Bucket policy for public read access
- `config/aws/cors-policy.json` - CORS configuration
- `config/aws/iam-policy.json` - IAM policy for bucket access
