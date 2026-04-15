## Context

`do-admin-1` already uses edge-proxy-ingress with Cloudflare Access-gated admin routes. We now evolve this from "edge gate only" into a mixed model: keep Access at the edge while enabling app-native OIDC for supported services using Cloudflare Access as the provider. In parallel, we add second-layer abuse control for exposed traffic and a safer grey-cloud posture for music streaming.

Canonical service/subdomain policy is owned in `policy/web-services.nix`. Cloudflare control-plane resources and policy declarations are managed by `cloudflare-opentofu-control-plane`; this change consumes the shared policy in Nix/runtime behavior.

## Goals / Non-Goals

**Goals:**
- Use Cloudflare Access as OIDC provider for supported phase-1 apps: `gatus`, `filebrowser`, `beszel`, `termix`.
- Preserve explicit edge route policy and keep admin routes Access-gated by default.
- Add CrowdSec baseline on `do-admin-1` as second-layer protection, especially for routes that are bypassed from Access gate patterns.
- Set music/Navidrome exposure intent to grey-cloud DNS posture.
- Keep Vaultwarden explicitly out of this OIDC wave (special-case behavior acknowledged).

**Non-Goals:**
- Authelia deployment or migration work.
- Authoring Cloudflare OpenTofu resources directly in this change.
- Solving every app auth edge-case in this pass (e.g., Syncthing/Webhook/Ntfy/Cockpit).

## Decisions

### Decision CO-1: Identity source is Cloudflare Access for this phase
For supported apps, app-native OIDC SHALL point at Cloudflare Access OIDC endpoints and client credentials.

**Rationale:** aligns with existing edge control-plane and avoids adding a second identity stack.

### Decision CO-2: Edge gate remains in place by default
Cloudflare Access route gating remains default for admin routes; app OIDC is additive for supported services.

**Rationale:** preserves current exposure guardrails and keeps transitions low-risk.

### Decision CO-3: Vaultwarden is an explicit exception in phase 1
Vaultwarden remains outside app-level Cloudflare Access OIDC rollout in this change.

**Rationale:** Bitwarden client/API behavior and vault unlock semantics make it a separate integration class.

### Decision CO-4: Music/Navidrome uses grey-cloud posture
Music route handling is updated to reflect grey-cloud DNS posture and no dependency on Access/WAF assumptions.

**Rationale:** avoid relying on Cloudflare-proxied/WAF assumptions for bulk media streaming.

### Decision CO-5: CrowdSec is the second-layer baseline
CrowdSec is added host-wide as a compensating/defense-in-depth control for exposed surfaces.

**Rationale:** improves resilience for non-Access or partially bypassed traffic classes.

## Risks / Trade-offs

- **[Risk] Double-auth friction (Access + app OIDC)** → **Mitigation:** accepted in phase 1; keep policy explicit and revisit simplification later.
- **[Risk] OIDC secret sprawl across apps** → **Mitigation:** host-scoped SOPS templates and strict secret naming.
- **[Risk] CrowdSec false positives** → **Mitigation:** start with conservative baseline and verify logs/decisions before tightening.
- **[Risk] Vaultwarden policy confusion** → **Mitigation:** document as explicit exception in proposal/spec/tasks.

## Migration Plan

1. Update OpenSpec artifacts to lock app/runtime scope and explicit exceptions.
2. Consume canonical shared policy from `policy/web-services.nix` and Cloudflare control-plane ownership from `cloudflare-opentofu-control-plane`.
3. Add host-scoped secret/template model for OIDC app credentials on `do-admin-1`.
4. Wire phase-1 app OIDC settings in admin module (`gatus`, `filebrowser`, `beszel`, `termix`).
5. Add CrowdSec baseline and integrate with relevant ingress/service logs.
6. Update edge-ingress + contract assertions for Access defaults, exceptions, and music posture.
7. Validate and deploy to `do-admin-1`, then verify app logins, route behavior, and CrowdSec activity.

## Open Questions

- Should Vaultwarden API/browser split be handled in a dedicated follow-up change or a path-split extension of this one?
- Do we need per-app Cloudflare Access group claims immediately, or defer fine-grained RBAC to a follow-up hardening pass?
