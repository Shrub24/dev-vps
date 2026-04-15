## Context

The repository already has:
- canonical policy at `policy/web-services.nix`
- generated JSON input at `generated/policy/web-services.json`
- OpenTofu Cloudflare scaffold under `opentofu/cloudflare`

This change adds the first concrete Cloudflare resources and keeps scope intentionally narrow: DNS records generated from canonical policy.

## Goals / Non-Goals

**Goals:**
- Add concrete Cloudflare DNS resources for policy-declared services.
- Ensure DNS proxy mode follows canonical `cloudflare.proxied` per service.
- Manage shared `origin` endpoint record used by service CNAME targets.
- Keep implementation deterministic and easy to validate locally.

**Non-Goals:**
- Access applications/policies automation.
- Non-DNS Cloudflare resources.
- App/runtime auth changes.

## Decisions

### Decision IR-1: Initial resources are DNS records only
The first OpenTofu rollout SHALL manage DNS records for services declared in canonical policy.

### Decision IR-2: Records are generated from policy JSON
OpenTofu SHALL derive record definitions from `generated/policy/web-services.json` via `jsondecode(file(...))`.

### Decision IR-3: Policy controls proxied vs grey-cloud
Each service record SHALL apply `cloudflare.proxied` from canonical policy so grey-cloud exceptions (e.g., music) are explicit and enforced.

## Risks / Trade-offs

- **Risk:** applying records without imported pre-existing DNS may cause churn.
  **Mitigation:** require operator review with plan before apply; document import/transition flow.
- **Risk:** OpenTofu binary not present in all environments.
  **Mitigation:** keep validation guidance explicit and optional in CI for now.

## Migration Plan

1. Add DNS record resource generation from policy JSON.
2. Add outputs summarizing managed records.
3. Add managed shared origin record support.
3. Document plan/apply and import notes for existing zones.
4. Validate OpenSpec strictly.
