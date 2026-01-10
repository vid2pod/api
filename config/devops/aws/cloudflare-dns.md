# Cloudflare DNS Configuration

## Zone Information

- **Domain:** vid2pod.fm
- **Zone ID:** [ZONE_ID]

## DNS Records

### 1. ACM Certificate Validation (CNAME)

This record validates the wildcard SSL certificate (*.vid2pod.fm) in AWS Certificate Manager.

```json
{
  "type": "CNAME",
  "name": "_c0a8d660c06c9d4a798ab23105407ec2.vid2pod.fm",
  "content": "_f3c1192513e85896d293f747564996d4.jkddzztszm.acm-validations.aws.",
  "ttl": 1,
  "proxied": false
}
```

**IMPORTANT:** This record must remain in place for the SSL certificate to stay valid.

### 2. CloudFront Downloads Subdomain (CNAME)

Points downloads.vid2pod.fm to the CloudFront distribution.

```json
{
  "type": "CNAME",
  "name": "downloads.vid2pod.fm",
  "content": "d1wkic791wbnhy.cloudfront.net",
  "ttl": 1,
  "proxied": false
}
```

**Record ID:** 94d8616a4200e710fc36490c62e72e1e

## Adding Records via Cloudflare API

### Using curl:

```bash
curl -X POST "https://api.cloudflare.com/client/v4/zones/[ZONE_ID]/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{
    "type": "CNAME",
    "name": "subdomain.vid2pod.fm",
    "content": "target.example.com",
    "ttl": 1,
    "proxied": false
  }'
```

## Listing Records

```bash
curl -X GET "https://api.cloudflare.com/client/v4/zones/[ZONE_ID]/dns_records" \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" | jq
```

## Notes

- **Proxy Status:** Both records have `proxied: false` because they need to resolve directly (ACM validation requirement and CloudFront custom domain requirement)
- **TTL:** Set to 1 (Auto) for automatic TTL management by Cloudflare
