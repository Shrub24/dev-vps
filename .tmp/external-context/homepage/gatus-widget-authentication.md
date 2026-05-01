---
source: official docs + source code
library: Homepage
package: homepage
topic: gatus widget authentication
fetched: 2026-04-21T00:00:00Z
official_docs: https://gethomepage.dev/widgets/services/gatus/
---

# Gatus widget support

Supported fields for the Gatus widget are only:
- `type: gatus`
- `url`

Docs example:
```yaml
widget:
  type: gatus
  url: http://gatus.host.or.ip:port
```

Docs explicitly say:
- Allowed fields: `['up', 'down', 'uptime']`

Source behavior (`src/widgets/gatus/widget.js`):
- `api: '{url}/{endpoint}'`
- `proxyHandler: genericProxyHandler`
- `mappings.status.endpoint = 'api/v1/endpoints/statuses'`
- no widget-local `headers`, `username`, `password`, `key`, or `apiKey` fields are defined

Generic widget options do **not** add auth support to Gatus by themselves.
The shared `genericProxyHandler` only injects:
- `widget.headers`
- `widget.username` + `widget.password` → Basic auth header
- `req.extraHeaders`

But because the Gatus widget config does not define those auth fields in its schema, they are not part of supported Gatus widget config in current Homepage releases.

Relevant source/doc links:
- https://gethomepage.dev/widgets/services/gatus/
- https://raw.githubusercontent.com/gethomepage/homepage/dev/src/widgets/gatus/widget.js
- https://raw.githubusercontent.com/gethomepage/homepage/dev/src/utils/proxy/handlers/generic.js
- https://raw.githubusercontent.com/gethomepage/homepage/dev/docs/widgets/services/gatus.md
- https://raw.githubusercontent.com/gethomepage/homepage/dev/docs/widgets/authoring/proxies.md

Practical recommendation for this repo:
- If Gatus is behind auth, prefer placing Homepage and Gatus on the same trusted network path, or expose an internal unauthenticated read-only endpoint for the widget.
- If you need auth today, use a `customapi` widget (or add a custom proxy handler) so you can explicitly set `headers` or Basic auth for the Gatus endpoint.
- Do not rely on undocumented `username/password/headers` support in `type: gatus`; it is not implemented in current Homepage source.
