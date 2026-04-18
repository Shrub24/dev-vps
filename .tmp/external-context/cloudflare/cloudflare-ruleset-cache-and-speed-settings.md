---
source: official docs + Cloudflare Terraform provider docs
library: Cloudflare Provider
package: cloudflare
topic: ruleset cache settings and speed settings
fetched: 2026-04-18T00:00:00Z
official_docs: https://raw.githubusercontent.com/cloudflare/terraform-provider-cloudflare/master/docs/resources/ruleset.md
---

## `cloudflare_ruleset` / `http_request_cache_settings`

Relevant `rules.action_parameters` fields supported by provider docs:

- `cache` (Boolean)
- `edge_ttl { mode, default, status_code_ttl }`
- `browser_ttl { mode, default }`
- `cache_key { ignore_query_strings_order, cache_deception_armor, cache_by_device_type, custom_key }`
- `cache_reserve { eligible, minimum_file_size }`
- `serve_stale { disable_stale_while_updating }`
- `respect_strong_etags` (Boolean)
- `origin_error_page_passthru` (Boolean)
- `origin_cache_control` (Boolean)

### Supported hostname-scoped expression

Use a host match in the rule expression, e.g.:

```hcl
expression = "(http.host eq \"example.host.com\")"
```

## Unsupported in `set_cache_settings`

The provider docs for `cloudflare_ruleset` do **not** expose per-host cache-rule fields for:

- Rocket Loader
- Auto Minify
- Mirage
- Polish

Those are surfaced as **zone settings** elsewhere, not as cache-rule action parameters in `http_request_cache_settings`.

## Related `cloudflare_zone_settings_override` fields

Provider docs show these zone settings exist:

- `rocket_loader`
- `minify { css, html, js }`
- `mirage`
- `polish`

But these are zone-wide settings, not hostname-scoped per-rule settings.
