## Context

The repository currently has strong Nix/runtime modeling for ingress behavior, but Cloudflare-side policy is not yet represented as canonical, declarative repo state. This change introduces a single shared policy model and makes OpenTofu and Nix both consume it.

## Goals / Non-Goals

**Goals:**
- Define canonical source of truth at `policy/web-services.nix` for service/subdomain edge behavior.
- Define OpenTofu Cloudflare control-plane ownership.
- Capture global policy defaults for Access/AOP posture.
- Support explicit host-level and route-level exception overrides.
- Model music/Navidrome as grey-cloud in control-plane declarations.

**Non-Goals:**
- App-native OIDC runtime wiring in Nix modules.
- CrowdSec host enforcement work.
- Refactoring unrelated Nix host/service modules.

## Decisions

### Decision CP-1: Canonical policy map is shared and primary
`policy/web-services.nix` SHALL be the canonical declaration of service/subdomain access/network behavior.

### Decision CP-2: Cloudflare resources are generated from canonical policy
Cloudflare DNS/Access/policy resources SHALL be generated via OpenTofu from the canonical policy map exported as JSON.

### Decision CP-3: Defaults first, exceptions explicit
A global default policy SHALL exist, with host/route overrides only when explicitly declared.

### Decision CP-4: Music route is a distinct grey-cloud class
Music/Navidrome SHALL be declared as grey-cloud in control-plane policy so edge assumptions stay explicit.

### Decision CP-5: Nix runtime also consumes canonical policy
Runtime/Nix changes SHALL consume canonical policy declarations instead of hardcoding duplicated policy decisions ad hoc.

## Risks / Trade-offs

- **[Risk] Drift between OpenTofu and runtime assumptions** → **Mitigation:** one canonical map + generated JSON + contract assertions.
- **[Risk] Over-broad exceptions** → **Mitigation:** require per-host/per-route declaration with rationale.
- **[Risk] Early complexity increase** → **Mitigation:** keep module scope minimal and focused on currently used routes.

## Migration Plan

1. Add canonical policy map at `policy/web-services.nix`.
2. Add JSON export pipeline for OpenTofu consumption.
3. Add OpenTofu Cloudflare control-plane structure and provider wiring.
4. Declare global defaults and host/route exception schema (including music grey-cloud class).
5. Expose outputs consumed by runtime/Nix changes.
6. Add OpenSpec contract checks for shared-policy declarations and consumers.

## Open Questions

- Which minimal policy schema fields are required in `policy/web-services.nix` for first rollout?
- Should multi-zone support be modeled now or deferred until second provider/zone appears?
