---
source: Context7 API
library: Cloudflare Docs
package: cloudflare
topic: terraform provider v5 api token permissions
fetched: 2026-04-16T00:00:00Z
official_docs: https://developers.cloudflare.com/fundamentals/api/how-to/create-via-api/
---

## Minimal token permissions

> Cloudflare permission *names* are cosmetic; Cloudflare recommends using permission group IDs in API token policies. Scope matters: zone-scoped permissions only apply to zone resources, while Zero Trust Access / IdP resources are account-scoped.

### Zone scope
- **DNS Edit** — needed for `cloudflare_dns_record`
- **Zone Settings Edit** — needed for `cloudflare_zone_setting` (`ssl`, `always_use_https`)
- **DNS Edit** (also required) — for `cloudflare_authenticated_origin_pulls_settings`
- **Zone WAF Write / Rulesets Write** — needed for `cloudflare_ruleset` when the phase is zone-scoped (`http_request_firewall_managed`, `http_request_firewall_custom`, `http_ratelimit`, `http_request_cache_settings`)

### Account scope
- **Access: Apps and Policies Write** — needed for `cloudflare_zero_trust_access_application`
- **Access: Apps and Policies Write** — needed for `cloudflare_zero_trust_access_policy`
- **Access: Organizations, Identity Providers, and Groups Write** — needed for `cloudflare_zero_trust_access_identity_provider`
- **Rulesets Write** — needed for any account-scoped `cloudflare_ruleset` (same phase names when managed at account level)

## Caveats
- Zero Trust Access resources are **account-level**; zone permissions do not cover them.
- `cloudflare_ruleset` permissions depend on **where** the ruleset is managed (zone vs account), not just the phase name.
- Cloudflare’s docs emphasize using permission group **IDs**; names can change.
- For Access applications/policies, Cloudflare docs explicitly call out **Access: Apps and Policies Write**.
- For identity providers, docs explicitly call out **Access: Organizations, Identity Providers, and Groups Write**.

## Safe baseline for this repo
If you want one practical token for this repo, use:
- **Zone**: DNS Edit, Zone Settings Edit, Rulesets Write / Zone WAF Write
- **Account**: Access: Apps and Policies Write, Access: Organizations, Identity Providers, and Groups Write

If you later discover you only manage zone rulesets, you can remove account-level Rulesets Write.

## Official docs
- https://developers.cloudflare.com/fundamentals/api/how-to/create-via-api/
- https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/deployment-guides/terraform/
- https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/
- https://developers.cloudflare.com/waf/managed-rules/
