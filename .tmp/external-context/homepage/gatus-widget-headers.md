---
source: Context7 API
library: Homepage
package: gethomepage/homepage
topic: Gatus widget headers support
fetched: 2026-04-21T00:00:00Z
official_docs: https://gethomepage.dev/
---

## Evidence

- **Gatus widget docs** only show:

```yaml
widget:
  type: gatus
  url: http://gatus.host.or.ip:port
```

- **Homepage services docs** state: "Widgets that make HTTP calls support extra request headers via `headers`."
- Context7 also shows a **custom API widget** example with explicit `headers`, but the **Gatus widget snippet does not include `headers`**.

## Conclusion

Generic widget headers are **not documented for the Gatus widget specifically**. If you need custom request headers for a Gatus-backed display, **`customapi` is the documented option**.

## Relevant config

```yaml
widget:
  type: customapi
  url: http://gatus.host.or.ip:port
  headers:
    X-My-Header: value
```
