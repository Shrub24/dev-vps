## Context

The fleet currently follows a private-first Tailscale baseline with modular host/service composition, but does not yet have a reusable ingress layer for selective public exposure. We need a Phase-1 design that introduces Caddy as a modular edge/origin proxy while preserving existing private access defaults and enabling per-service exposure decisions per host.

Key constraints:
- Keep day-1/phase-1 complexity low and reversible.
- Preserve OpenSpec security boundaries (private-by-default, explicit opt-in for exposure).
- Support mixed host roles (edge host and private origin host) without hardcoded topology assumptions.

## Goals / Non-Goals

**Goals:**
- Introduce a reusable `edge-proxy-ingress` capability with per-service route policy where phase-1 defaults to `tailscale-upstream` and `tailscale-only`, and `direct` is deferred to explicit edge-local exceptions.
- Define modular host wiring so each host can independently expose selected services.
- Use Cloudflare DNS-01 challenge integration for certificate automation in Caddy.
- Serve via a single primary domain using flat subdomain routing for phase-1 service exposure.
- Keep admin/sensitive routes private-origin by default, with Cloudflare Access as the default browser-admin edge control when publicly routed.
- Make operations verifiable via contracts/smoke checks.

**Non-Goals:**
- No Cloudflare tunnel adoption in this phase.
- No global CDN cache policy rollout in this phase.
- No multi-origin load balancing/failover orchestration in this phase.
- No broad public exposure of all services by default.

## Decisions

1. **Module shape: split policy from service definitions**
   - Add ingress capability as service-level module primitives and app/host composition inputs.
   - Rationale: keeps service modules reusable while host/app layers choose exposure mode.
   - Alternative rejected: hardcoding one ingress topology per host (too rigid).

2. **Per-service exposure mode model**
    - Each route declares one of: `direct`, `tailscale-upstream`, `tailscale-only`.
    - Default mode is `tailscale-upstream` for centralized domain access with private transport preserved.
    - `direct` is retained as a schema mode but deferred from normal phase-1 use; if used, it is edge-local-only and explicit.
    - Rationale: captures intended phase-1 topology while preserving future flexibility.
    - Alternative rejected: boolean public/private flag (too coarse for edge-to-origin routing).

3. **Certificate automation via Cloudflare DNS-01**
   - Integrate Caddy DNS challenge provider using host-scoped secrets.
   - Rationale: avoids HTTP challenge coupling to edge path correctness during bootstrap.
   - Alternative rejected: HTTP-01 only (more brittle across proxied topologies).

4. **Private-first default remains canonical**
   - Public routes require explicit opt-in per service.
   - Most services remain Tailscale-encrypted (`tailscale-upstream` or `tailscale-only`).
   - Admin web routes default to Cloudflare Access-protected edge + private upstream transport.
   - Rationale: aligns with current security posture while preserving single-domain usability.

5. **Host-role composition, not host-type lock-in**
   - Support edge host and private origin host as composition choices, not global assumptions.
   - Rationale: enables future host relocation/scaling without refactoring module contracts.

## Risks / Trade-offs

- **[Risk] Route policy drift causes accidental exposure** → Mitigation: explicit default-deny public policy and contract tests for route exposure map.
- **[Risk] Cloudflare secret handling broadens blast radius** → Mitigation: host-scoped DNS API secrets in SOPS with minimal token scope.
- **[Risk] Proxy chains hide root cause during incidents** → Mitigation: add structured operator checks (origin reachability, Caddy config/test, cert status).
- **[Trade-off] Added ingress flexibility increases config surface** → Mitigation: constrain phase-1 to minimal route schema and defer advanced edge features.

## Migration Plan

1. Add ingress module contracts and capability specs.
2. Add host-scoped DNS challenge secret scaffolding.
3. Implement minimal Caddy service module with route policy inputs.
4. Validate phase-1 with `tailscale-upstream` and `tailscale-only`; keep `direct` deferred unless explicitly needed for edge-local exceptions.
5. Add contract/smoke checks and rollback notes.
6. Roll out first to non-critical route(s), then expand per service.

Rollback strategy:
- Disable ingress module on affected host and revert to existing private-only service access.
- Keep service modules independent so route exposure can be rolled back without disabling services.

## Open Questions

- Should `tailscale-upstream` routes require explicit health-check endpoints in phase-1?
- Do we need any edge-local `direct` routes in phase-1, or defer fully to a later change?
- Do we standardize one route metadata schema now for future cache/failover phases, or keep phase-1 minimal and evolve later?
