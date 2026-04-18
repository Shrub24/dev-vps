---
source: official docs + Cloudflare Terraform provider docs
library: Cloudflare Provider
package: cloudflare
topic: zone settings speed features
fetched: 2026-04-18T00:00:00Z
official_docs: https://raw.githubusercontent.com/cloudflare/terraform-provider-cloudflare/master/docs/resources/zone_settings_override.md
---

## `cloudflare_zone_settings_override`

Relevant supported zone settings fields:

- `rocket_loader` (String)
- `minify { css, html, js }`
- `mirage` (String)
- `polish` (String)
- `browser_cache_ttl` (Number)
- `cache_level` (String)
- `automatic_https_rewrites` (String)
- `brotli` (String)

## Important limitation

These settings are **zone-wide**. Provider docs do not show a hostname-scoped equivalent.

## Minify shape

```hcl
minify {
  css  = "on"
  js   = "off"
  html = "off"
}
```
