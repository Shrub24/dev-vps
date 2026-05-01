---
source: official docs + GitHub wiki
library: FileBrowser Quantum
package: filebrowserquantum
topic: oidc-sftp-auth-docker-paths
fetched: 2026-04-23T00:00:00Z
official_docs: https://filebrowserquantum.com/en/docs/
---

# FileBrowser Quantum research

## 1) OIDC configuration

Config path:
```yaml
auth:
  methods:
    oidc:
      enabled: true
      clientId: "filebrowser-client"
      clientSecret: "xxx"
      issuerUrl: "https://sso.example.com/application/o/filebrowser/"
      scopes: "openid email profile"
      userIdentifier: "preferred_username"
```

Supported fields:
- `enabled`
- `clientId`
- `clientSecret` (docs recommend env var)
- `issuerUrl`
- `scopes` (defaults to `openid email profile`)
- `userIdentifier` (`preferred_username`, `email`, `username`, `phone`)
- `adminGroup`
- `userGroups` (v1.3.x+)
- `groupsClaim` (default `groups`)
- `disableVerifyTLS`
- `logoutRedirectUrl`

Notes:
- `createUser` is marked deprecated in OIDC docs; users are created automatically when login succeeds.
- Callback URL is `{baseURL}/api/auth/oidc/callback`.

Env vars:
- `FILEBROWSER_OIDC_CLIENT_ID`
- `FILEBROWSER_OIDC_CLIENT_SECRET`
- also usable: `FILEBROWSER_CONFIG`, `FILEBROWSER_DATABASE`, `FILEBROWSER_JWT_TOKEN_SECRET`

## 2) SFTP source configuration for multiple hosts

Official docs do not show an `sftp` source type in the source config docs. The documented source model is filesystem paths under `server.sources`, so I could not confirm a native SFTP-source block from official docs.

Documented multi-source example:
```yaml
server:
  sources:
    - path: "/path/to/source1"
      name: "My Files"
      config:
        defaultEnabled: true
    - path: "/path/to/source2"
      name: "Secured Files"
```

Relevant source fields:
- `path`
- `name`
- `config.defaultEnabled`
- `config.defaultUserScope`
- `config.createUserDir`
- `config.denyByDefault`
- `config.private`
- `config.disabled`
- `config.useLogicalSize`
- `config.rules`

If you need multiple remote hosts, the docs imply mounting them into the container/host filesystem first, then adding one `server.sources[]` entry per mounted path.

## 3) Local/password auth during smoke, then disable later

Yes. Keep password auth enabled during smoke, then disable it later by setting:
```yaml
auth:
  methods:
    password:
      enabled: false
    oidc:
      enabled: true
```

The docs also note that when OIDC is the only auth method, users are automatically redirected to the OIDC provider.

## 4) Docker image paths and mounts

Image docs: `ghcr.io/gtsteffaniak/filebrowser` (also `gtstef/filebrowser` examples).

Default Docker paths:
- config: `/home/filebrowser/data/config.yaml`
- database: `/home/filebrowser/data/database.db`
- cacheDir example: `/home/filebrowser/data/tmp`
- config override env: `FILEBROWSER_CONFIG`
- database override env: `FILEBROWSER_DATABASE`

Example mount:
```yaml
services:
  filebrowser:
    image: ghcr.io/gtsteffaniak/filebrowser:stable
    volumes:
      - ./data:/home/filebrowser/data
      - /path/to/files:/folder
```

Config file mount example:
```yaml
volumes:
  - /path/to/config.yaml:/home/filebrowser/data/config.yaml
```

The docs do not mention SSH key mounting for SFTP sources; if SFTP is used externally, mount keys into the container and reference them from whatever external sync/mount layer you use.

## Official docs used
- https://github.com/gtsteffaniak/filebrowser/wiki/Configuration-And-Examples/d42441ba6a52f186af4146d894c944a27eacc11a
- https://github.com/gtsteffaniak/filebrowser
- https://filebrowserquantum.com/en/docs/configuration/authentication/oidc/
- https://filebrowserquantum.com/en/docs/configuration/sources/
- https://filebrowserquantum.com/en/docs/reference/environment-variables/
- https://filebrowserquantum.com/en/docs/getting-started/docker/
- https://filebrowserquantum.com/en/docs/getting-started/config/
