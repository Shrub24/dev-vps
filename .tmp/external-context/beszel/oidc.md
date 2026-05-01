---
source: Context7 API
library: Beszel
package: beszel
topic: oidc
fetched: 2026-04-15T00:00:00Z
official_docs: https://github.com/henrygd/beszel-docs/blob/main/en/guide/oauth.md
---

## Confirmed OIDC-related variables
- `APP_URL`
- `DISABLE_PASSWORD_AUTH`
- `USER_CREATION`

## Confirmed callback URL
- `<APP_URL>/api/oauth2-redirect`

## Minimal config
```yaml
services:
  beszel:
    image: henrygd/beszel
    environment:
      APP_URL: https://beszel.example.com
      DISABLE_PASSWORD_AUTH: "true"
      USER_CREATION: "true"
```

## Notes
- Docs confirm OAuth2/OIDC login support.
- No provider-specific OIDC issuer/client keys were confirmed in the fetched docs.
