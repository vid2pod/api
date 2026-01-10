# CloudFront CDN Setup for downloads.vid2pod.fm

## Overview

CloudFront CDN is configured to serve MP3 files from the S3 bucket `downloads.vid2pod.fm` with:
- Custom domain: `downloads.vid2pod.fm`
- SSL/TLS encryption via wildcard certificate
- Origin Access Control (OAC) for secure S3 access
- Global edge caching for fast downloads worldwide

## Key Resources

### CloudFront Distribution
- **Distribution ID:** E4WMP9IYV6KIP
- **Domain:** d1wkic791wbnhy.cloudfront.net
- **Custom Domain:** downloads.vid2pod.fm
- **Status:** Deployed
- **Price Class:** PriceClass_100 (US, Canada, Europe)

### Origin Access Control (OAC)
- **ID:** E1I490A5AU5226
- **Name:** vid2pod-s3-oac
- **Signing:** AWS Signature Version 4 (sigv4)

### SSL Certificate
- **ARN:** arn:aws:acm:us-east-1:[ACCOUNT_ID]:certificate/d1c85002-1a94-46cc-9d8d-aafaa743c4ef
- **Type:** Wildcard (*.vid2pod.fm)
- **Region:** us-east-1
- **Status:** ISSUED

## Architecture Flow

1. User requests: `https://downloads.vid2pod.fm/[s3-key-path]/file.mp3`
2. DNS (Cloudflare) resolves to CloudFront distribution
3. CloudFront checks edge cache for the file
4. If not cached, CloudFront fetches from S3 using OAC
5. File is cached at edge location and served to user
6. Subsequent requests are served from cache (faster)

**Important:** URLs must be direct S3 paths (like `https://downloads.vid2pod.fm/abc123/file.mp3`), NOT Rails routing paths (like `/rails/active_storage/blobs/redirect/...`). CloudFront serves files directly from S3, not through the Rails app.

## Security

- S3 bucket is **private** - not publicly accessible
- Only CloudFront can access S3 via Origin Access Control
- All traffic is HTTPS only (HTTP redirects to HTTPS)
- TLS 1.2 minimum protocol version

## Cache Behavior

- **Cache Policy:** Managed-CachingOptimized (658327ea-f89d-4fab-a63d-7e88639e58f6)
- **Origin Request Policy:** Managed-CORS-S3Origin (88a5eaf4-2fd4-4709-b370-b4c650ea3fcf)
- **Compression:** Enabled (gzip)
- **Allowed Methods:** GET, HEAD
- **Cached Methods:** GET, HEAD
- **HTTP Version:** HTTP/2

## Management Commands

### Check Distribution Status

```bash
aws cloudfront get-distribution \
  --id E4WMP9IYV6KIP \
  --profile personal \
  --query 'Distribution.Status'
```

### Create Cache Invalidation

```bash
# Invalidate all files
aws cloudfront create-invalidation \
  --distribution-id E4WMP9IYV6KIP \
  --paths "/*" \
  --profile personal

# Invalidate specific file
aws cloudfront create-invalidation \
  --distribution-id E4WMP9IYV6KIP \
  --paths "/rails/active_storage/blobs/*/filename.mp3" \
  --profile personal
```

### View Distribution Configuration

```bash
aws cloudfront get-distribution-config \
  --id E4WMP9IYV6KIP \
  --profile personal
```

### Update Distribution

```bash
# First, get current config and ETag
aws cloudfront get-distribution-config \
  --id E4WMP9IYV6KIP \
  --profile personal > current-config.json

# Edit current-config.json as needed

# Apply update with ETag
aws cloudfront update-distribution \
  --id E4WMP9IYV6KIP \
  --if-match [ETAG] \
  --distribution-config file://current-config.json \
  --profile personal
```

## Monitoring

### CloudWatch Metrics

```bash
# Get request count for last hour
aws cloudwatch get-metric-statistics \
  --namespace AWS/CloudFront \
  --metric-name Requests \
  --dimensions Name=DistributionId,Value=E4WMP9IYV6KIP \
  --start-time $(date -u -v-1H +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum \
  --profile personal
```

## Cost Optimization

- **Price Class 100** selected for cost optimization (US, Canada, Europe only)
- Edge caching reduces S3 data transfer costs
- Compression enabled to reduce bandwidth

## Troubleshooting

### URLs Not Resolving

1. Check DNS propagation: `dig downloads.vid2pod.fm`
2. Verify CNAME points to CloudFront: `d1wkic791wbnhy.cloudfront.net`
3. Check distribution status: should be "Deployed"

### 403 Forbidden Errors

1. Verify S3 bucket policy allows CloudFront OAC
2. Check that OAC ID in bucket policy matches: `E1I490A5AU5226`
3. Verify distribution has correct Origin Access Control ID

### SSL Certificate Issues

1. Verify certificate is in us-east-1 region (required for CloudFront)
2. Check certificate status: should be "ISSUED"
3. Verify DNS validation record exists in Cloudflare

## Related Files

- `cloudfront-distribution.json` - Distribution configuration
- `cloudfront-oac.json` - Origin Access Control config
- `bucket-policy.json` - S3 bucket policy
- `acm-certificate.md` - SSL certificate details
- `cloudflare-dns.md` - DNS configuration
