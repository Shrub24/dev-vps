## Why

Current ingress wording still mixes "Tailscale-first/private" and "public edge" in a way that can be misread as end-user traffic always flowing over Tailscale. We need explicit language that separates public edge exposure from private upstream transport semantics.

## What Changes

- Clarify architecture/spec wording to describe a **public edge bastion** (Cloudflare + Caddy) for declared web routes.
- Clarify that **Cloudflare Access** is the default access gate for admin web routes.
- Clarify that **`tailscale-upstream` is preferred for cross-host private-origin upstream transport**.
- Clarify that **`direct` means edge-local localhost upstream only** (not cross-host default transport).
- Preserve **`tailscale-only`** as the explicit mode for routes that must not be publicly rendered.
- Update architecture/decisions docs to match the same transport and exposure vocabulary.

## Capabilities

### New Capabilities
- *(none)*

### Modified Capabilities
- `edge-proxy-ingress`: clarify public-edge vs private-upstream semantics and edge-local-only `direct` meaning.
- `network-access`: clarify baseline private-first model with explicit public edge bastion and private-origin upstream preference.
- `admin-services`: clarify admin web route model as access-gated edge + private-origin upstream defaults.
- `fleet-infrastructure`: clarify fleet-level access model language for edge bastion + private-origin host roles.
- `operations`: clarify operational verification language for edge reachability and policy checks.

## Impact

- Affected specs: `openspec/specs/{edge-proxy-ingress,network-access,admin-services,fleet-infrastructure,operations}/spec.md`
- Affected docs: `docs/architecture.md`, `docs/decisions.md`
- No behavioral code-path changes intended; this is wording and contract-clarity alignment.
