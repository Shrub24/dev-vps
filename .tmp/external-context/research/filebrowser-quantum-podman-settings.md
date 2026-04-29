---
source: official docs (filebrowserquantum.com)
library: FileBrowser Quantum
package: filebrowserquantum
topic: container runtime settings for Podman
fetched: 2026-04-23T00:00:00Z
official_docs: https://filebrowserquantum.com/en/docs/getting-started/docker/
---

## 1) Official container images/tags
- Docker Hub: `gtstef/filebrowser`
- GHCR: `ghcr.io/gtsteffaniak/filebrowser`
- Tags called out in docs: `latest`, `stable`, `beta`, `stable-slim`, `beta-slim`

## 2) Default listen port and protocol
- Default host/container example uses `80:80`
- Docs/healthcheck confirm HTTP on port `80` (`http://localhost:80/health`)
- For a different config port, healthcheck must match the internal port

## 3) Config file location and format
- Format: YAML (`config.yaml`)
- Docker default config location: `/home/filebrowser/data/config.yaml`
- Config discovery order: CLI `-c`, env `FILEBROWSER_CONFIG`, then defaults

## 4) Minimum persistent mounts
- Required persistent data mount: `/home/filebrowser/data`
  - holds config, database, and tmp/cache
- Files/source mount(s): at least one content directory, e.g. `/path/to/your/folder:/folder`
- Default DB location in Docker: `/home/filebrowser/data/database.db`

## 5) Initial admin env vars
- `FILEBROWSER_ADMIN_PASSWORD` → admin password
- Docs also list `FILEBROWSER_CONFIG`, `FILEBROWSER_DATABASE`, `FILEBROWSER_JWT_TOKEN_SECRET`, `FILEBROWSER_OIDC_CLIENT_ID`, `FILEBROWSER_OIDC_CLIENT_SECRET`, `FILEBROWSER_ONLYOFFICE_SECRET`, etc.
- Minimal initial admin setup in docs uses config file `auth.adminUsername`/`auth.adminPassword`; env vars are optional but supported for secrets/overrides

## 6) Minimal run example from docs
```bash
docker run -d \
  -v $(pwd):/srv \
  -p 80:80 \
  gtstef/filebrowser:stable
```
- Access: `http://localhost`
- Example login: `admin` / `admin`

## Useful URLs
- Docker guide: https://filebrowserquantum.com/en/docs/getting-started/docker/
- Config files: https://filebrowserquantum.com/en/docs/getting-started/config/
- Env vars: https://filebrowserquantum.com/en/docs/reference/environment-variables/
- Standalone guide: https://filebrowserquantum.com/en/docs/user-guides/other/standalone/
