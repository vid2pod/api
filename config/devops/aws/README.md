# AWS Infrastructure Documentation

This directory contains configuration files and documentation for the vid2pod AWS infrastructure.

## Quick Reference

### Active Resources

| Resource Type | Name/ID | Purpose |
|--------------|---------|---------|
| S3 Bucket | `downloads.vid2pod.fm` | Stores MP3 audio files |
| CloudFront Distribution | `E4WMP9IYV6KIP` | CDN for fast global delivery |
| CloudFront OAC | `E1I490A5AU5226` | Secure S3 access control |
| ACM Certificate | `d1c85002-1a94-46cc-9d8d-aafaa743c4ef` | Wildcard SSL (*.vid2pod.fm) |
| IAM User | `vid2pod-downloads` | Rails app S3 access |
| Custom Domain | `downloads.vid2pod.fm` | Public download URL |

### DNS (Cloudflare)
- Zone ID: `[ZONE_ID]`
- Domain: `vid2pod.fm`

## Documentation Files

### Setup & Configuration
- **`setup-summary.md`** - Complete setup history with all AWS CLI commands
- **`cloudfront-setup.md`** - CloudFront CDN management guide
- **`acm-certificate.md`** - SSL certificate details
- **`cloudflare-dns.md`** - DNS configuration

### Configuration Files
- **`bucket-policy.json`** - S3 bucket policy (CloudFront OAC access)
- **`cors-policy.json`** - CORS configuration for S3
- **`iam-policy.json`** - IAM user permissions
- **`cloudfront-distribution.json`** - CloudFront distribution config
- **`cloudfront-oac.json`** - Origin Access Control config

## Architecture

```
User Request (HTTPS)
    ↓
downloads.vid2pod.fm (Cloudflare DNS)
    ↓
CloudFront Distribution (E4WMP9IYV6KIP)
    ↓ (via Origin Access Control)
S3 Bucket (downloads.vid2pod.fm) - PRIVATE
    ↑
Rails App (uploads MP3 files)
```

## Common Tasks

### Deploy New Files
Files are uploaded automatically by the Rails app using ActiveStorage and the IAM user credentials.

### Invalidate CloudFront Cache
```bash
aws cloudfront create-invalidation \
  --distribution-id E4WMP9IYV6KIP \
  --paths "/*" \
  --profile personal
```

### Check CloudFront Status
```bash
aws cloudfront get-distribution \
  --id E4WMP9IYV6KIP \
  --profile personal \
  --query 'Distribution.Status'
```

### List S3 Bucket Contents
```bash
aws s3 ls s3://downloads.vid2pod.fm/ --profile personal
```

### View Bucket Policy
```bash
aws s3api get-bucket-policy \
  --bucket downloads.vid2pod.fm \
  --profile personal | jq -r '.Policy | fromjson'
```

## Security Notes

1. **S3 Bucket is Private** - Only accessible via CloudFront OAC
2. **HTTPS Only** - All HTTP traffic redirects to HTTPS
3. **IAM User** - Scoped permissions for Rails app uploads only
4. **Wildcard Certificate** - Covers all *.vid2pod.fm subdomains

## Cost Considerations

- **S3 Storage**: Pay for stored MP3 files
- **CloudFront**: Pay for data transfer out and requests
- **Data Transfer**: Reduced costs due to CloudFront caching
- **Price Class**: Limited to US, Canada, Europe (PriceClass_100)

## Monitoring

CloudFront metrics are available in AWS CloudWatch:
- Request count
- Bytes downloaded
- Error rate (4xx, 5xx)
- Cache hit rate

Access via AWS Console or CLI commands documented in `cloudfront-setup.md`.

## Backup & Recovery

S3 versioning is not currently enabled. Consider enabling for backup:

```bash
aws s3api put-bucket-versioning \
  --bucket downloads.vid2pod.fm \
  --versioning-configuration Status=Enabled \
  --profile personal
```

## Troubleshooting

### ACL Errors in Production

**Error:** `Aws::S3::Errors::AccessControlListNotSupported: The bucket does not allow ACLs`

**Cause:** The bucket uses `BucketOwnerEnforced` object ownership (ACLs disabled).

**Solution:** Ensure `config/storage.yml` has `acl: nil` in the amazon configuration:

```yaml
amazon:
  service: S3
  access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: <%= ENV['AWS_REGION'] || 'us-east-1' %>
  bucket: <%= ENV['AWS_BUCKET'] %>
  acl: nil  # Required for BucketOwnerEnforced
```

Do NOT use `public: true` or any ACL setting when the bucket has ACLs disabled.

## Support

- AWS Account: [ACCOUNT_ID]
- Region: us-east-1
- Profile: personal (for AWS CLI)
