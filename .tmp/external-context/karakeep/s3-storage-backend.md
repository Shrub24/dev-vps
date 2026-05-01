---
source: Karakeep Docs
official_docs: https://docs.karakeep.app/configuration/environment-variables/
topic: S3 storage backend
fetched: 2026-04-30T00:00:00Z
---

## S3-compatible asset storage

Karakeep uses S3-compatible object storage when `ASSET_STORE_S3_ENDPOINT` is set.

| Variable | Purpose | Required | Example |
|---|---|---:|---|
| `ASSET_STORE_S3_ENDPOINT` | S3 endpoint URL; enables S3 storage | Optional, but required to switch to S3 | `https://minio.example.com` |
| `ASSET_STORE_S3_REGION` | S3 region | Optional | `us-east-1` |
| `ASSET_STORE_S3_BUCKET` | Bucket name for assets | Required when using S3 | `karakeep-assets` |
| `ASSET_STORE_S3_ACCESS_KEY_ID` | Access key ID | Required when using S3 | `minioadmin` |
| `ASSET_STORE_S3_SECRET_ACCESS_KEY` | Secret access key | Required when using S3 | `secret` |
| `ASSET_STORE_S3_FORCE_PATH_STYLE` | Force path-style requests; useful for MinIO | Optional | `true` |

### Minimal example

```env
ASSET_STORE_S3_ENDPOINT=https://minio.example.com
ASSET_STORE_S3_BUCKET=karakeep-assets
ASSET_STORE_S3_ACCESS_KEY_ID=minioadmin
ASSET_STORE_S3_SECRET_ACCESS_KEY=secret
ASSET_STORE_S3_FORCE_PATH_STYLE=true
```

Notes:
- S3 is automatically detected when an endpoint is provided.
- The bucket must already exist and credentials need read/write/delete permissions.
- Switching storage backends after storing assets requires manual migration.
