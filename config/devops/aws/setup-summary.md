# AWS S3 Bucket Setup Summary

This document summarizes all the commands used to set up the `downloads.vid2pod.fm` S3 bucket and IAM user.

## 1. Create S3 Bucket

```bash
aws s3 mb s3://downloads.vid2pod.fm --profile personal --region us-east-1
```

Created the S3 bucket `downloads.vid2pod.fm` in the `us-east-1` region.

**Default Settings:**
- Object Ownership: `BucketOwnerEnforced` (ACLs disabled)
- This is the recommended secure configuration
- ActiveStorage config must NOT include any ACL settings (no `public: true`, no `acl:` option)

## 2. Configure Block Public Access

```bash
# Initially disabled for public access (now replaced with CloudFront OAC)
aws s3api put-public-access-block \
  --bucket downloads.vid2pod.fm \
  --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false" \
  --profile personal
```

**Note:** With CloudFront OAC now in place, the bucket is private and only accessible via CloudFront. Public access settings remain disabled to allow the CloudFront service principal access via the bucket policy.

## 3. Apply Bucket Policy

```bash
aws s3api put-bucket-policy \
  --bucket downloads.vid2pod.fm \
  --policy file://config/devops/aws/bucket-policy.json \
  --profile personal
```

Applied the bucket policy from `config/devops/aws/bucket-policy.json`.

**Current Policy:** Allows CloudFront service principal access via Origin Access Control (OAC). Only CloudFront distribution `E4WMP9IYV6KIP` can access bucket objects.

## 4. Apply CORS Policy

```bash
aws s3api put-bucket-cors \
  --bucket downloads.vid2pod.fm \
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

This policy grants the following permissions on the `downloads.vid2pod.fm` bucket:
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

## 9. Request Wildcard SSL Certificate

```bash
aws acm request-certificate \
  --domain-name "*.vid2pod.fm" \
  --validation-method DNS \
  --region us-east-1 \
  --profile personal
```

Created wildcard SSL certificate for `*.vid2pod.fm`:
- Certificate ARN: `arn:aws:acm:us-east-1:[ACCOUNT_ID]:certificate/d1c85002-1a94-46cc-9d8d-aafaa743c4ef`
- Validation: DNS (CNAME record added to Cloudflare - see `cloudflare-dns.md`)
- Covers all subdomains: downloads.vid2pod.fm, api.vid2pod.fm, etc.

## 10. Add DNS Validation Record to Cloudflare

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/[ZONE_ID]/dns_records" \
  -H "Authorization: Bearer [REDACTED]" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "_c0a8d660c06c9d4a798ab23105407ec2.vid2pod.fm",
    "content": "_f3c1192513e85896d293f747564996d4.jkddzztszm.acm-validations.aws.",
    "ttl": 1,
    "proxied": false
  }'
```

This record validates the SSL certificate with AWS Certificate Manager.

## 11. Create CloudFront Origin Access Control (OAC)

```bash
aws cloudfront create-origin-access-control \
  --origin-access-control-config Name=vid2pod-s3-oac,Description="Origin Access Control for vid2pod S3 bucket",SigningProtocol=sigv4,SigningBehavior=always,OriginAccessControlOriginType=s3 \
  --profile personal
```

Created OAC with ID: `E1I490A5AU5226`

This allows CloudFront to securely access the private S3 bucket without making it public.

## 12. Create CloudFront Distribution

```bash
aws cloudfront create-distribution \
  --distribution-config file://config/devops/aws/cloudfront-distribution.json \
  --profile personal
```

Created CloudFront distribution:
- Distribution ID: `E4WMP9IYV6KIP`
- Domain: `d1wkic791wbnhy.cloudfront.net`
- Custom Domain: `downloads.vid2pod.fm`
- Origin: S3 bucket `downloads.vid2pod.fm`
- SSL Certificate: Wildcard cert (*.vid2pod.fm)
- Cache Policy: Managed-CachingOptimized
- Origin Request Policy: Managed-CORS-S3Origin

## 13. Update S3 Bucket Policy for CloudFront OAC

```bash
aws s3api put-bucket-policy \
  --bucket downloads.vid2pod.fm \
  --policy file://config/devops/aws/bucket-policy.json \
  --profile personal
```

Updated bucket policy to only allow CloudFront access via OAC. The bucket is no longer publicly accessible.

## 14. Add CloudFront CNAME to Cloudflare

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/[ZONE_ID]/dns_records" \
  -H "Authorization: Bearer [REDACTED]" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "downloads.vid2pod.fm",
    "content": "d1wkic791wbnhy.cloudfront.net",
    "ttl": 1,
    "proxied": false
  }'
```

Points `downloads.vid2pod.fm` to the CloudFront distribution.

## Summary

The S3 bucket `downloads.vid2pod.fm` is now configured with:
- CloudFront CDN distribution for secure, fast global delivery
- Origin Access Control (OAC) - S3 bucket only accessible via CloudFront (not public)
- Wildcard SSL certificate (*.vid2pod.fm) for HTTPS
- Custom domain: downloads.vid2pod.fm
- CORS enabled for GET and HEAD requests from any origin
- An IAM user `vid2pod-downloads` with full access to manage objects in the bucket
- Credentials stored in `.env.production`

## Configuration Files Used

- `config/aws/bucket-policy.json` - Bucket policy for CloudFront OAC access
- `config/aws/cors-policy.json` - CORS configuration
- `config/aws/iam-policy.json` - IAM policy for bucket access
- `config/aws/cloudfront-distribution.json` - CloudFront distribution configuration
- `config/aws/cloudfront-oac.json` - Origin Access Control configuration
- `config/aws/acm-certificate.md` - SSL certificate documentation
- `config/aws/cloudflare-dns.md` - DNS configuration documentation
