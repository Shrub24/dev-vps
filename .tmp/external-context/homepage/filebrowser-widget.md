---
source: official docs
library: gethomepage/homepage
package: homepage
topic: filebrowser widget authentication
fetched: 2026-04-23T00:00:00Z
official_docs: https://gethomepage.dev/widgets/services/filebrowser/
---

## Filebrowser widget

Homepage documents the Filebrowser service widget with these auth-related fields:

- `username`
- `password`
- `authHeader` (for proxy header authentication)

Example:

```yaml
widget:
  type: filebrowser
  url: http://filebrowserhostorip:port
  username: username
  password: password
  authHeader: X-My-Header # If using Proxy header authentication
```

Allowed fields shown in the docs: `available`, `used`, `total`.

## Takeaway

Yes: the Filebrowser widget supports basic auth credentials and a custom auth header for proxy-header authentication.

## Caveat

This is the current official docs page; if you are on an older Homepage release, confirm the widget schema matches your version.