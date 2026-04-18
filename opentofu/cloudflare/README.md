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

## Suggested workflow (phase 1: local recovery)

1. Export canonical policy JSON and verify:
   - `just tofu-sync`
2. Prepare tfvars split:
   - `opentofu/cloudflare/config.auto.tfvars` (committed, non-sensitive only)
   - `opentofu/cloudflare/secrets.auto.tfvars` (local ignored)
3. Initialize local state mode:
   - `just tofu-init`
4. Run OpenTofu commands:
   - `just tofu-check`
   - `just tofu-plan-local`
   - `just tofu-apply-local`

### Local state override (while remote backend is unavailable)

When R2 backend is temporarily unavailable (for example TLS/endpoint bring-up), force local state with:

- `just tofu-init-local`
- `just tofu-plan-local`
- `just tofu-apply-local`

These commands always run `tofu init -reconfigure -backend=false` first.

Current repo default keeps local-state mode active until remote backend is re-enabled.

### Secret split model (phase 1)

- `config.auto.tfvars` is committed and must contain non-sensitive config only.
- `secrets.auto.tfvars` is local-only and ignored.
- Do not place identifying values (emails, account/zone IDs, client IDs, IPs, endpoints, hostnames) in `config.auto.tfvars`.

### Optional phase 2 (deferred in this change)

SOPS + generated runtime files are now supported for OpenTofu operations.

1. Create encrypted source secrets:
   - `secrets/opentofu/cloudflare.yaml` (sops-encrypted)
2. Render local ignored runtime files:
   - `just tofu-runtime`
   - generates `opentofu/cloudflare/secrets.auto.tfvars` and `opentofu/cloudflare/backend.hcl`
3. Initialize remote backend:
   - `just tofu-init-remote`
4. Migrate local state once:
   - `just tofu-init-remote-migrate`

### Secrets file layout and move steps

Keep secrets in this order:

1. Source-of-truth (encrypted):
   - `secrets/opentofu/cloudflare.yaml`
2. Local runtime files (ignored):
   - `opentofu/cloudflare/secrets.auto.tfvars`
   - `opentofu/cloudflare/backend.hcl`

Populate/move values:

1. Start from template:
   - `cp opentofu/cloudflare/secrets.auto.tfvars.example /tmp/secrets.auto.tfvars.migrate`
2. Move values from your current local `opentofu/cloudflare/secrets.auto.tfvars` and `opentofu/cloudflare/backend.hcl` into `secrets/opentofu/cloudflare.yaml` under:
   - `cloudflare.*` for provider/resource variables
   - `backend.*` for R2 backend settings
3. Encrypt/update source:
   - `sops -e -i secrets/opentofu/cloudflare.yaml`
4. Regenerate runtime files from encrypted source:
   - `just tofu-runtime`
5. Remove any ad-hoc temporary secret files outside ignored paths.

## Remote backend (Cloudflare R2)

1. Ensure encrypted source file exists (`secrets/opentofu/cloudflare.yaml`) with backend fields.
2. Render runtime backend file:
   - `just tofu-runtime`
3. Initialize remote backend (no migration):
   - `just tofu-init-remote`
4. Migrate existing local state to remote (one-time):
   - `just tofu-init-remote-migrate`

`backend.hcl` is ignored and must never be committed.

### Existing records

If records already exist in Cloudflare, import them into state before apply:

```
tofu -chdir=opentofu/cloudflare import 'cloudflare_dns_record.service["<name>"]' <record_id>
tofu -chdir=opentofu/cloudflare import 'cloudflare_zero_trust_access_application.service["<name>"]' <app_id>
```

## Stale/desynced state recovery runbook

Use this when Cloudflare resources exist but local OpenTofu state is empty/stale.

1. Sync canonical policy input:
   - `just tofu-sync`
2. Ensure split tfvars are present (`config.auto.tfvars` + local `secrets.auto.tfvars`).
3. Initialize local state:
   - `just tofu-init`
4. Import declared resources from `main.tf` addresses only:
   - DNS records: `cloudflare_dns_record.service["<service>"]`, optional `cloudflare_dns_record.origin[0]`
   - Access apps/policies/IdP: `cloudflare_zero_trust_access_application.service[...]`, `cloudflare_zero_trust_access_policy.*`, `cloudflare_zero_trust_access_identity_provider.main[0]`
   - Zone settings/AOP/rulesets: `cloudflare_zone_setting.*`, `cloudflare_authenticated_origin_pulls_settings.this`, `cloudflare_ruleset.*`
5. Triage duplicates explicitly (common in account-wide Access objects):
   - If duplicate policy/IdP objects exist, choose the canonical object ID and import that ID consistently.
6. Verify drift after recovery:
   - `just tofu-plan-local`
   - Treat null/false provider normalization as noise; treat policy/idp remaps or missing resources as semantic drift requiring an explicit decision.
