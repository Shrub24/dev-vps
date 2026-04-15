## Context

`do-admin-1` already uses edge-proxy-ingress with Cloudflare Access-gated admin routes. This pivot keeps Access + Pocket ID but moves route posture to full orange-cloud intent and removes CrowdSec from host-layer controls. Cloudflare becomes the primary traffic blocking/firewall layer for exposed routes in this scope.

Canonical service/subdomain policy is owned in `policy/web-services.nix`. Cloudflare control-plane resources and enforcement declarations are managed by `cloudflare-opentofu-control-plane`; this change consumes and aligns runtime behavior with that ownership.

## Goals / Non-Goals

**Goals:**
- Host Pocket ID in this change as the shared IdP runtime.
- Switch Cloudflare Access upstream IdP from Google OAuth to Pocket ID generic OIDC.
- Use Pocket ID as OIDC issuer for supported phase-1 apps: `gatus`, `beszel`, `termix`.
- Preserve explicit edge route policy and keep admin routes Access-gated by default.
- Keep CrowdSec out of this change scope and rely on Cloudflare edge firewall/traffic controls.
- Set full orange-cloud exposure posture in this scope.
- Keep Navidrome orange-cloud with no Access gate and CDN/caching disabled for media streaming.
- Keep Vaultwarden explicitly out of this OIDC/Access wave (special-case behavior acknowledged).
- Keep Pocket ID route as direct orange-cloud exception to avoid Access->IdP loop.

**Non-Goals:**
- Authelia deployment or migration work.
- Authoring Cloudflare OpenTofu resources directly in this change.
- File-management app OIDC in this phase (Filestash paid SSO limitation; classic Filebrowser not in phase set).
- Solving every app auth edge-case in this pass (e.g., Syncthing/Webhook/Ntfy/Cockpit).

## Decisions

### Decision CO-1: Identity source is Pocket ID for this phase
For supported apps, app-native OIDC SHALL point at Pocket ID issuer endpoints and host-scoped app credentials.

**Rationale:** avoids duplicating Cloudflare SaaS OIDC app-provider setup per self-hosted service and gives one reusable issuer across apps.

### Decision CO-2: Edge gate remains in place by default
Cloudflare Access route gating remains default for admin browser routes; app OIDC is additive for supported services.

**Rationale:** preserves current exposure guardrails and keeps transitions low-risk.

### Decision CO-2a: Cloudflare Access upstream IdP is switched in this change
Cloudflare Access SHALL use Pocket ID as upstream generic OIDC IdP in this change scope.

**Rationale:** ensures Access and app-native OIDC share the same identity source.

### Decision CO-3: Vaultwarden is an explicit exception in phase 1
Vaultwarden remains outside Access gate and app-native Pocket ID OIDC rollout in this change.

**Rationale:** Bitwarden client/API behavior and vault unlock semantics make it a separate integration class.

### Decision CO-4: Music/Navidrome uses orange-cloud posture with caching disabled
Music route handling is updated to use orange-cloud posture while explicitly disabling CDN/caching for the music endpoint in control-plane policy.

**Rationale:** avoid relying on Cloudflare-proxied/WAF assumptions for bulk media streaming.

### Decision CO-5: CrowdSec is removed from this rollout
CrowdSec and the firewall bouncer are not part of this rollout.

**Rationale:** avoids bouncer credential/runtime complexity during this identity and route-posture migration.

### Decision CO-6: Cloudflare edge controls are primary traffic blocking layer
Traffic blocking and firewalling in this rollout are handled by Cloudflare controls in the control plane rather than host-level CrowdSec.

**Rationale:** simplifies host runtime and consolidates protection where orange-cloud traffic is terminated.

## Risks / Trade-offs

- **[Risk] Double-auth friction (Access + app OIDC)** → **Mitigation:** accepted in phase 1; keep policy explicit and revisit simplification later.
- **[Risk] Pocket ID becomes critical-path dependency** → **Mitigation:** keep route and bootstrap explicit; validate discovery/JWKS/login flow before app rollout.
- **[Risk] OIDC secret sprawl across apps** → **Mitigation:** host-scoped SOPS templates and strict secret naming.
- **[Risk] Reduced host-layer abuse controls in this wave** → **Mitigation:** rely on Cloudflare WAF/firewall/traffic policies, keep Access defaults strict, keep explicit exception set small, and disable CDN/caching on music endpoint.
- **[Risk] Vaultwarden policy confusion** → **Mitigation:** document as explicit exception in proposal/spec/tasks.

## Migration Plan

1. Update OpenSpec artifacts to lock app/runtime scope and explicit exceptions.
2. Consume canonical shared policy from `policy/web-services.nix` and Cloudflare control-plane ownership from `cloudflare-opentofu-control-plane`.
3. Add Pocket ID runtime module + route exception and host-scoped secret/template model on `do-admin-1`.
4. Switch Cloudflare Access upstream IdP to Pocket ID in OpenTofu variables/resources.
5. Wire phase-1 app OIDC settings in admin module (`gatus`, `beszel`, `termix`) using Pocket ID issuer.
6. Remove CrowdSec/bouncer host wiring and related contract expectations.
7. Update edge-ingress + contract assertions for Access defaults, exceptions (Pocket ID/Vaultwarden/Navidrome), full orange-cloud posture, and disabled-caching music behavior.
8. Validate and deploy to `do-admin-1`, then verify Access login path, app logins, route behavior, and music endpoint behavior.

## Open Questions

- Should Vaultwarden API/browser split be handled in a dedicated follow-up change or a path-split extension of this one?
