---
source: Pocket ID docs + repo
library: pocket-id
package: pocket-id
topic: deployment
fetched: 2026-04-15T00:00:00Z
official_docs: https://docs.pocket-id.org/docs/introduction
---

## Required fields
- Container image: `ghcr.io/pocket-id/pocket-id:v2`
- Port: `1411`
- Persistent data path: `/app/data`
- `APP_URL`
- `ENCRYPTION_KEY` or `ENCRYPTION_KEY_FILE`

## Minimal config snippet
```yaml
services:
  pocket-id:
    image: ghcr.io/pocket-id/pocket-id:v2
    restart: unless-stopped
    ports:
      - "1411:1411"
    env_file: .env
    volumes:
      - ./data:/app/data
```

`.env`
```env
APP_URL=https://id.example.com
ENCRYPTION_KEY=base64-32-byte-secret
TRUST_PROXY=true
PUID=1000
PGID=1000
```

## Caveats
- The docs show Docker as the recommended setup path.
- `APP_URL` must match the public base URL used by clients.
- `ENCRYPTION_KEY` must be at least 16 bytes; file-based keys are also supported.
- The repo’s compose example exposes `1411:1411` and stores data in `./data:/app/data`.
- Treat the issuer/base URL as the same externally reachable Pocket ID URL you configure in `APP_URL`.
