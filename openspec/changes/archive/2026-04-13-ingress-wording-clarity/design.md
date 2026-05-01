## Context

The newly archived phase-1 ingress rollout introduced a public Cloudflare/Caddy edge with route exposure modes. Some wording still implies a blanket "Tailscale-first" data path for all web traffic, which is inaccurate for edge-published routes. We need a precise vocabulary that distinguishes edge exposure from upstream transport.

## Goals / Non-Goals

**Goals:**
- Make edge/public terminology explicit and consistent across state specs and architecture docs.
- Encode admin route default as Cloudflare Access-gated edge + private-origin upstream.
- Encode cross-host upstream preference as `tailscale-upstream`.
- Encode `direct` as edge-local localhost upstream only.
- Preserve `tailscale-only` meaning (no public route rendered).

**Non-Goals:**
- No service/module behavior change.
- No route topology changes.
- No secret rotation or deployment pipeline change.

## Decisions

1. **Use "public edge bastion" terminology explicitly**
   - Describe Cloudflare + Caddy edge as the public ingress surface.
   - Keep host/service private-origin semantics distinct from edge publication.

2. **Define transport semantics by route mode**
   - `tailscale-upstream`: preferred cross-host private-origin transport.
   - `direct`: edge-local localhost upstream only.
   - `tailscale-only`: route not publicly rendered.

3. **Admin route default language**
   - Admin web routes default to Cloudflare Access at edge plus private-origin upstream transport.
   - Keep "private-first" wording as baseline stance, but avoid implying all client traffic traverses Tailscale.

## Risks / Trade-offs

- **[Risk] Terminology drift reappears across docs/specs** → Mitigation: update all affected specs/docs in one pass under one change.
- **[Risk] Readers infer behavior change from wording updates** → Mitigation: explicitly state non-goal of runtime behavior change in proposal/design and handoff notes.

## Migration Plan

1. Add delta specs for the five affected capabilities with full `MODIFIED` requirement blocks.
2. Update architecture and decision entries to match vocabulary.
3. Validate with `openspec validate ingress-wording-clarity --strict` and `openspec validate --specs --strict`.
4. Keep implementation task list scoped to wording-only updates.

Rollback:
- Revert this change set if wording causes ambiguity; no runtime rollback needed because behavior is unchanged.

## Open Questions

- Should a future change split "edge exposure policy" into its own dedicated capability spec to reduce repeated wording across multiple specs?
