---
source: official docs
library: gethomepage/homepage
package: homepage
topic: authenticated service patterns
fetched: 2026-04-23T00:00:00Z
official_docs: https://gethomepage.dev/widgets/services/
---

## Recommended patterns for authenticated services

Homepage’s official docs show two relevant patterns:

### 1) Use a dedicated service widget with credentials
The service widget system supports per-widget credentials or tokens where documented. For example, `customapi` supports:

- `username`
- `password`
- `headers`
- `method`
- `requestBody`

Example:

```yaml
widget:
  type: customapi
  url: http://custom.api.host.or.ip:port/path/to/exact/api/endpoint
  username: username
  password: password
  headers:
    X-API-Token: token
```

### 2) Use `iframe` only for browser-loadable content
The `iframe` widget is explicitly **not proxied**; requests come from the browser. That makes it a poor fit for server-side secret handling.

### 3) Prefer a backend/API facade for hard-to-auth services
If the target service needs special auth that Homepage widgets do not support directly, expose a small API endpoint or proxy that returns the status/data you need, then consume it via `customapi`.

## Practical recommendation

- Prefer `customapi` for authenticated status/data fetches.
- Use proxy-header auth only where the widget explicitly supports it (Filebrowser docs do).
- Avoid relying on `iframe` for authenticated dashboards.

## Version caveat

Widget options can change between Homepage releases; validate against the docs for your deployed tag/release.