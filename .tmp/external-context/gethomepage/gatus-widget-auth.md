---
source: Context7 API + official docs
library: Homepage (gethomepage)
package: gethomepage
topic: Gatus widget authentication support
fetched: 2026-04-21T00:00:00Z
official_docs: https://gethomepage.dev/widgets/services/gatus/
---

## Relevant docs

Homepage’s native **Gatus** widget exposes only these allowed fields:

- `up`
- `down`
- `uptime`

Example config:

```yaml
widget:
  type: gatus
  url: http://gatus.host.or.ip:port
```

No authentication fields are documented for this widget.
