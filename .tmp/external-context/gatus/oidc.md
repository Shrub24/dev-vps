---
source: Context7 API
library: Gatus
package: gatus
topic: oidc
fetched: 2026-04-15T00:00:00Z
official_docs: https://github.com/twin/gatus/blob/master/README.md
---

## Confirmed OIDC keys
- `security.oidc.issuer-url`
- `security.oidc.redirect-url`
- `security.oidc.client-id`
- `security.oidc.client-secret`
- `security.oidc.scopes`
- Optional: `security.oidc.allowed-subjects`
- Optional: `security.oidc.session-ttl`

## Minimal config
```yaml
security:
  oidc:
    issuer-url: "https://auth.example.org"
    redirect-url: "https://status.example.org/authorization-code/callback"
    client-id: "gatus-client-id"
    client-secret: "gatus-client-secret"
    scopes: ["openid"]
```

## Notes
- Docs explicitly confirm Gatus OIDC support.
- Redirect URL must end with `/authorization-code/callback`.
