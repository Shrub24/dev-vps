---
source: Context7 + official restic docs
library: restic
package: restic
topic: s3-custom-endpoint-r2
fetched: 2026-05-05T00:00:00Z
official_docs: https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html
---

## Restic S3/custom endpoint notes

- Supported S3 repo forms:
  - `s3:<endpoint>/<bucket>`
  - `s3:https://<server>:<port>/<bucket>`
  - `s3:http://<server>:<port>/<bucket>` (for HTTP endpoints like MinIO)
- Path-style is the expected form for S3 backends; virtual-hosted-style bucket-in-hostname URLs are not supported.
- For custom S3-compatible endpoints, restic supports setting:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_SESSION_TOKEN` (temporary creds)
  - `AWS_DEFAULT_REGION` (optional; defaults to `us-east-1`)
  - `-o s3.region=...` as an alternative to `AWS_DEFAULT_REGION`
  - `-o s3.bucket-lookup=auto|dns|path`
  - `-o s3.list-objects-v1=true` for buggy ListObjectsV2 servers
- R2-specific caveat documented by restic: no dedicated R2 backend; use the generic S3-compatible backend. Use path-style and set the correct endpoint/region.
- Recommended NixOS pattern:
  - store repo URL/password in secrets
  - set `RESTIC_REPOSITORY`/`RESTIC_PASSWORD_FILE`
  - export S3 creds via systemd service environment or `EnvironmentFile`
  - use `restic backup -r "$RESTIC_REPOSITORY" ...` with `-o s3.bucket-lookup=path` and `AWS_DEFAULT_REGION` if needed

## Source URLs
- https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#amazon-s3
- https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#s3-compatible-storage
- https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#minio-server
- https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#backblaze-b2
