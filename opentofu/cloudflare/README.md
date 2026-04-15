# Cloudflare OpenTofu Control Plane

This directory is the Cloudflare control-plane ownership boundary.

## Ownership

- **Canonical policy source:** `policy/web-services.nix`
- **Generated machine input:** `generated/policy/web-services.json`
- **Cloudflare resource declarations:** this directory (`opentofu/cloudflare`)

## Contract

1. Nix policy is edited in `policy/web-services.nix`.
2. JSON is exported with `./lib/export-web-services-policy.sh <host>`.
3. OpenTofu reads that JSON via `jsondecode(file(...))` and applies Cloudflare resources.

This keeps one source of truth while separating runtime wiring from control-plane ownership.

## Resources in this directory

| Resource | Purpose |
|---|---|
| `cloudflare_dns_record.service` | Service DNS records from canonical policy |
| `cloudflare_dns_record.origin` | Shared origin endpoint (optional) |
| `cloudflare_zero_trust_access_application.service` | Access apps for `access.requireCloudflareAccess = true` services |
| `cloudflare_zero_trust_access_policy.allow_admins` | Shared reusable `allow_admins` policy |
| `cloudflare_zero_trust_access_policy.allow_approved` | Shared reusable `allow_approved` policy |
| `cloudflare_zero_trust_access_identity_provider.main` | Optional IdP configuration for Access (when client credentials are set) |
| `cloudflare_authenticated_origin_pulls_settings.this` | Zone-level AOP toggle |
| `cloudflare_zone_setting.ssl` | Zone SSL mode (`strict`) |
| `cloudflare_zone_setting.always_use_https` | Zone setting to force HTTPS (`on`) |

**Access policy assignment** — each service declares `access.policies` in `policy/web-services.nix` (for example `allow_admins`, `allow_approved`). OpenTofu attaches these shared policy resources to each generated Access application. Services with `access.requireCloudflareAccess = false` get no Access app (e.g. navidrome, vaultwarden).

**Allowed IdPs** — when the identity provider resource is configured, each generated Access application sets `allowed_idps` explicitly to that provider ID.

## Required variables

- `cloudflare_api_token`
- `cloudflare_account_id`
- `cloudflare_zone_id`
- `edge_record_target` (the DNS target used for service subdomains)
- `origin_record_content` (required when `manage_origin_record = true`)

### Optional variables (with defaults)

| Variable | Default | Description |
|---|---|---|
| `dns_record_type` | `CNAME` | DNS record type for service subdomains |
| `manage_origin_record` | `true` | Whether to manage the shared origin record |
| `origin_record_name` | `"origin"` | Subdomain for the shared origin endpoint |
| `origin_record_type` | `"A"` | DNS type for origin record |
| `origin_record_proxied` | `false` | Whether origin record is proxied |
| `admin_email` | _required_ | Admin identity used by policy templates |
| `access_session_duration` | `"24h"` | Session duration for Access applications |
| `temp_access_session_duration` | `"24h"` | Session duration for approval-required policy |
| `primary_domain` | `"shrublab.xyz"` | Primary domain used for service hostnames |
| `aop_enabled` | `true` | Enable zone-level Authenticated Origin Pulls |

## Suggested workflow

1. Export canonical policy JSON and verify:
   - `just tofu-sync`
2. Create local OpenTofu var file (do not commit secrets):
   - `cp opentofu/cloudflare/terraform.tfvars.example opentofu/cloudflare/terraform.tfvars`
   - Fill in required values (including `admin_email`)
3. Run OpenTofu commands:
   - `just tofu-init`
   - `just tofu-check`
   - `just tofu-plan`
   - `just tofu-apply`

### Existing records

If records already exist in Cloudflare, import them into state before apply:

```
tofu -chdir=opentofu/cloudflare import 'cloudflare_dns_record.service["<name>"]' <record_id>
tofu -chdir=opentofu/cloudflare import 'cloudflare_zero_trust_access_application.service["<name>"]' <app_id>
```
