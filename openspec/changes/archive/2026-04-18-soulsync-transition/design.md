## Context

`oci-melb-1` currently composes Syncthing, Navidrome, slskd, and beets-inbox from `modules/applications/music.nix`. The ingest baseline is beets-driven and works well for deterministic batch import, but it is less aligned with day-to-day DJ workflows (singles, promos, partial releases, and selected cuts) and modern source flexibility. The change must preserve stable fleet contracts (`/srv/media`, `/srv/data`, host-scoped secrets, edge policy model) while switching primary ingest ownership to SoulSync.

This is cross-cutting: service composition, host secrets, edge route policy, and behavior contracts all change together. It also touches a security-sensitive surface (new public gated route) and workflow-sensitive data flow (promotion/demotion lanes).

## Goals / Non-Goals

**Goals:**
- Make SoulSync the primary ingest/control-plane service on `oci-melb-1`.
- Preserve existing media path contract: `inbox/slskd`, `library`, `quarantine/untagged`, `quarantine/approved`.
- Keep beets available as fallback rescue tooling while removing beets-inbox as default automation.
- Expose SoulSync from day 1 through existing `do-admin-1` edge model (`tailscale-upstream`, Cloudflare Access, AOP).
- Keep rollout conservative: Discogs-first metadata bias, track-first partial import behavior, no broad mutation of pre-existing library content.

**Non-Goals:**
- No day-1 automated beets fallback pipeline.
- No replacement of Syncthing/Navidrome/slskd with alternative services.
- No app-native OIDC requirement for SoulSync day 1.
- No custom SoulSync fork to remove player features.

## Decisions

- **SS-1 (Primary ingest ownership):** SoulSync becomes primary ingest owner; beets-inbox leaves default path.
  - **Rationale:** Matches operator workflow and source/metadata needs while keeping current filesystem contracts.
  - **Alternative considered:** Keep dual backend switch (`beets|soulsync`) long-term. Rejected to avoid permanent complexity and split operational truth.

- **SS-2 (Container-first deployment):** Run SoulSync as pinned upstream container via Podman/`virtualisation.oci-containers`.
  - **Rationale:** Upstream is Docker-first; minimizes packaging risk and shortens initial integration cycle.
  - **Alternative considered:** Native Python service packaging in NixOS. Rejected for day 1 due to higher maintenance and unknowns.

- **SS-3 (Path and lane contract):** Keep `quarantine/untagged` as unresolved lane and `quarantine/approved` as fallback handoff lane; map SoulSync staging/import lane to `approved`.
  - **Rationale:** Preserves existing operator mental model and supports rescue handoff without inventing new path taxonomy now.
  - **Alternative considered:** Rename quarantine to review paths now. Rejected for rollout simplicity.

- **SS-4 (Promotion ownership):** Canonical final promotion should re-enter through SoulSync whenever feasible; beets may finalize rescue only as a practical fallback edge case.
  - **Rationale:** Keeps one primary promotion contract while allowing pragmatic recovery if upstream behavior is limiting.
  - **Alternative considered:** Let beets own fallback finalization by default. Rejected because it dilutes primary ownership and complicates auditability.

- **SS-5 (Library mutation guard):** SoulSync may read existing library context but SHALL NOT run broad retag/reorg/repair automation over pre-existing library files in initial rollout.
  - **Rationale:** Reduces blast radius and regression risk during migration.
  - **Alternative considered:** Full-platform jobs enabled immediately. Rejected as too risky for day-1 cutover.

- **SS-6 (Public exposure model):** Publish `soulsync` route on `do-admin-1` using existing canonical web-services policy model with `tailscale-upstream`, Cloudflare Access, and AOP.
  - **Rationale:** Aligns with established secure public service pattern in repo.
  - **Alternative considered:** Tailscale-only access for SoulSync. Rejected per operator requirement for mobile public gated access.

- **SS-7 (Playback posture):** Day-1 public route is UI/control-plane first with best-effort playback suppression; rollout does not block on perfect suppression.
  - **Rationale:** Upstream exposes built-in player; no clean disable toggle is guaranteed. Access/AOP controls already bound risk.
  - **Alternative considered:** Defer public route until full suppression is proven. Rejected due to explicit day-1 exposure decision.

- **SECR-1 (Secrets posture):** Introduce host-scoped SoulSync secrets for required integrations and treat additional providers as optional enablement gated by presence of credentials.
  - **Rationale:** Preserves blast-radius isolation and avoids hard dependency on nonessential providers.
  - **Alternative considered:** Require all provider secrets up front. Rejected for operability and rollout friction.

## Risks / Trade-offs

- **[R1] SoulSync lacks a clean auto-watch import from `approved`** → **Mitigation:** Treat `approved` as operator-triggered SoulSync import lane in day 1; document behavior and revisit automation later.
- **[R2] Player/stream controls remain visible on public UI** → **Mitigation:** Apply low-risk suppression/hide methods if available; keep strict Cloudflare Access + AOP; document residual behavior.
- **[R3] Metadata drift on partial releases** → **Mitigation:** Set track-first defaults and Discogs-first bias; avoid album-consistency-heavy workflows for partial imports.
- **[R4] Existing library mutation regressions** → **Mitigation:** Explicitly disable/avoid broad library repair/retag jobs in rollout defaults.
- **[R5] Optional provider misconfiguration causing startup failures** → **Mitigation:** Gate provider enablement by secret/config presence and keep fail-safe defaults.

## Migration Plan

1. Add `modules/services/soulsync.nix` with pinned container image, persistent state dirs under `/srv/data/soulsync`, and media path mounts.
2. Add host-scoped SoulSync secrets/templates in `hosts/oci-melb-1/default.nix`.
3. Wire SoulSync into `modules/applications/music.nix` and remove beets-inbox from primary composition.
4. Keep beets runtime available for manual rescue workflows.
5. Refine Navidrome composition so inbox is excluded and only library+quarantine are exposed.
6. Add `soulsync` service route to canonical web policy consumed by `do-admin-1` edge ingress.
7. Validate build/eval (`nix flake check`) and route/service behavior.
8. Smoke-test key flows: trusted import, unresolved handling, fallback handoff via approved lane, public gated UI.

**Rollback strategy:**
- Revert SoulSync composition and route policy commits.
- Re-enable beets-inbox as primary automation using prior module defaults.
- Preserve filesystem paths/data to avoid destructive rollback.

## Open Questions

- Can SoulSync natively auto-promote from the `approved` staging lane without custom glue, or is operator-triggered import the expected canonical behavior?
- What exact low-risk mechanism is available for best-effort player suppression in SoulSync web UI (config, CSS/feature flag, or none)?
