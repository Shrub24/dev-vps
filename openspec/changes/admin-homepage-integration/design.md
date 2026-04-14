## Context

`applications.admin` already enables Homepage and multiple admin services (Cockpit, Beszel hub, Gatus, Vaultwarden, Filebrowser, Ntfy, Webhook), but Homepage is not yet treated as the primary operator surface with stable external routing. Existing edge-ingress contracts already support flat subdomain routing and Cloudflare Access-gated defaults for sensitive services, so this change should compose with that model rather than introducing a new ingress pattern.

Stakeholders are operators using `do-admin-1` as admin edge and service host. The repository constraints require explicit exposure policy, minimal public surface, and private-origin upstream behavior for admin routes.

## Goals / Non-Goals

**Goals:**
- Define Homepage as the practical central admin dashboard in the admin baseline.
- Expose Homepage on `admin.shrublab.xyz` through existing edge-ingress patterns.
- Keep admin route policy explicit: Cloudflare Access-gated at edge, private-origin upstream.
- Prefer native Homepage widgets where feasible; always include stable links even when widgets require auth.
- Add contract checks that ensure route intent and homepage baseline wiring do not regress.

**Non-Goals:**
- Implementing cross-host log replication/aggregation (explicitly deferred).
- Re-architecting ingress stack or replacing edge-proxy-ingress.
- Full auth/session SSO unification across all admin backends in this pass.

## Decisions

### Decision AH-1: Homepage is a visibility/launch surface first
Use Homepage as the unified operator landing page with two layers:
1) reliable service links for all core admin tools,
2) native widgets for priority systems (Cockpit/Beszel/Gatus) where practical.

**Rationale:** links are robust regardless of backend auth mode; widgets can be incrementally hardened.

### Decision AH-2: Route via existing edge-ingress policy model
Expose `admin.shrublab.xyz` as a normal edge-proxy-ingress route declaration (not custom one-off Caddy logic).

**Rationale:** keeps routing ownership modular and aligned with existing spec guarantees.

### Decision AH-3: Keep admin route Cloudflare Access-gated + private-origin
For this route, preserve sensitive-service defaults: Access-gated public edge, private-origin upstream transport.

**Rationale:** satisfies minimal-open-surface expectation while providing operational convenience.

### Decision AH-4: Incremental widget tolerance
Initial baseline allows some widgets to be partially populated or auth-challenged, provided route availability and link usability are stable.

**Rationale:** avoids blocking dashboard rollout on full downstream auth integration.

## Risks / Trade-offs

- **[Risk] Widget auth mismatch causes noisy/empty tiles** → **Mitigation:** treat links as required baseline; make widget population best-effort with explicit follow-up tasks.
- **[Risk] Route policy drift broadens exposure** → **Mitigation:** add contract checks for exposure mode/access flags and private-origin assumptions.
- **[Risk] Homepage config becomes host-specific sprawl** → **Mitigation:** keep shared defaults in `modules/applications/admin.nix`; host only declares route ownership/domain specifics.

## Migration Plan

1. Update OpenSpec delta specs for `admin-services` and `edge-proxy-ingress`.
2. Implement Homepage services/widgets/links baseline in admin application module.
3. Declare and wire `admin.shrublab.xyz` route through edge-ingress on `do-admin-1`.
4. Update contract tests for admin module and edge ingress route guarantees.
5. Deploy to `do-admin-1` and verify dashboard availability and route behavior.
6. Keep rollback path as standard host rollback (`deploy-rs`/system profile rollback) without introducing new state migrations.

## Open Questions

- Which exact Homepage widgets are currently stable with existing auth posture for Cockpit/Beszel/Gatus in this fleet?
- Should admin homepage route enforce additional path-level policy constraints beyond service-level Access gating?
