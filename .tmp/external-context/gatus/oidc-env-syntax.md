---
source: Context7 API
library: Gatus
package: gatus
topic: oidc env syntax
fetched: 2026-04-15T00:00:00Z
official_docs: https://github.com/twin/gatus/blob/master/README.md
---

## OIDC env var syntax in config

Current Gatus docs show plain environment-variable substitution in YAML config:

```yaml
security:
  oidc:
    client-id: ${CLIENT_ID}
    client-secret: $CLIENT_SECRET
```

Supported/mentioned syntax:
- `${VAR}` — supported
- `$VAR` — supported
- `$$` — escapes a literal `$`

Not documented as supported in current Gatus docs:
- `{{ env }}`
