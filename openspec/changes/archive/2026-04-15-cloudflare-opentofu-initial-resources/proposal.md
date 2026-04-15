## Why

`cloudflare-opentofu-control-plane` established ownership and data contracts, but the Cloudflare OpenTofu stack still has no concrete resources. We need an initial, minimal resource set so Cloudflare DNS is declarative and sourced from the canonical policy map.

**Core Value:** make Cloudflare DNS records for published web services repo-managed and policy-driven.

## What Changes

- Implement initial Cloudflare resources in `opentofu/cloudflare`.
- Generate DNS records from `generated/policy/web-services.json` (which is exported from `policy/web-services.nix`).
- Respect per-service Cloudflare policy fields (notably `proxied`) from the canonical map.
- Manage the shared `origin` DNS record used as CNAME target for published service records.
- Add basic OpenTofu execution guidance and local validation workflow.

## Capabilities

### New Capabilities
- `cloudflare-initial-resources`: policy-driven Cloudflare DNS record declarations for first host services.

### Modified Capabilities
- `cloudflare-control-plane`: moves from scaffold-only to concrete first resources.

## Non-Goals

- Full Cloudflare Access application/policy rollout in this change.
- Terraform/OpenTofu state backend migration in this change.
- Runtime app OIDC wiring in Nix.
