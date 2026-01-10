# ACM SSL Certificate Configuration

## Wildcard Certificate for *.vid2pod.fm

**Certificate ARN:** `arn:aws:acm:us-east-1:[ACCOUNT_ID]:certificate/d1c85002-1a94-46cc-9d8d-aafaa743c4ef`

This wildcard certificate covers all subdomains under vid2pod.fm, including:
- downloads.vid2pod.fm
- api.vid2pod.fm
- Any future subdomains

## Request Command

```bash
aws acm request-certificate \
  --domain-name "*.vid2pod.fm" \
  --validation-method DNS \
  --region us-east-1 \
  --profile personal
```

## DNS Validation Record

The certificate was validated using a CNAME record in Cloudflare:

- **Type:** CNAME
- **Name:** `_c0a8d660c06c9d4a798ab23105407ec2.vid2pod.fm`
- **Value:** `_f3c1192513e85896d293f747564996d4.jkddzztszm.acm-validations.aws.`
- **TTL:** 1 (Auto)
- **Proxy:** Off

This DNS record must remain in place for the certificate to stay valid.

## Certificate Details

- **Region:** us-east-1 (required for CloudFront)
- **Validation Method:** DNS
- **Status:** ISSUED
- **Domain:** *.vid2pod.fm (wildcard)

## Usage

This certificate is currently used by:
- CloudFront distribution E4WMP9IYV6KIP (downloads.vid2pod.fm)

Additional CloudFront distributions or services can use this same certificate for any *.vid2pod.fm subdomain.
