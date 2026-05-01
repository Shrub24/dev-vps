## Why

Cloudflare edge state is currently managed outside this repository, while runtime behavior is managed in Nix. We need one declarative source of truth for service/subdomain edge posture so both Nix and OpenTofu consume the same model.

**Core Value:** establish `policy/web-services.nix` as canonical policy and generate both Cloudflare and runtime behavior from it.

## What Changes

- Introduce canonical shared policy map at `policy/web-services.nix`.
- Define JSON export pipeline from the canonical map (e.g., `generated/policy/web-services.json`) for OpenTofu consumption.
- Use OpenTofu-managed Cloudflare resources generated from that shared policy model.
- Model global edge policy defaults (including Access/AOP posture) with explicit per-host and per-route exceptions.
- Represent music/Navidrome as a grey-cloud route class in the canonical map.
- Publish/consume policy outputs in runtime/Nix changes (including `cloudflare-access-oidc-crowdsec-navidrome`).

## Capabilities

### New Capabilities
- `web-service-policy-source`: Canonical cross-stack policy map at `policy/web-services.nix`.
- `cloudflare-control-plane`: Declarative Cloudflare DNS/Access/policy resources generated from the canonical policy map.

### Modified Capabilities
- `edge-proxy-ingress`: Consumes canonical web-service policy defaults/exceptions instead of ad-hoc policy assumptions.
- `network-access`: Makes public-edge policy and exception boundaries explicit per host/route.

## Impact

- Affected areas (expected):
  - New shared policy map (`policy/web-services.nix`)
  - New OpenTofu Cloudflare control-plane directory and modules
  - JSON export artifact(s) for OpenTofu input
  - Inputs/outputs consumed by host/runtime route policy
  - OpenSpec contracts for edge/access/network posture
- Affected systems:
  - `do-admin-1` (initial consumer)
  - Cloudflare zone/access configuration for admin/music routes
- Dependencies:
  - Existing edge-ingress route model in Nix
  - Cloudflare account/zone resources
