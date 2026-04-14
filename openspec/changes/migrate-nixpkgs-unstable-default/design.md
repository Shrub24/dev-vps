## Context

Active repository code currently mixes package sets: `nixos-25.11` as primary flake input and `nixos-unstable` for selected tooling/runtime paths (`devShell` tool choice and Beets runtime in `modules/services/beets-inbox.nix`). This split adds decision overhead and increases maintenance friction during active development. The requested direction is to make `nixos-unstable` the default package baseline and remove unused fallback complexity until a concrete exception is needed.

This change touches core flake wiring and cross-host package resolution, so it must preserve mixed-architecture behavior (`aarch64-linux` and `x86_64-linux`) and keep host state semantics unchanged (`system.stateVersion` remains as-is).

## Goals / Non-Goals

**Goals:**
- Establish one default package source by setting primary `nixpkgs` to `nixos-unstable`.
- Remove active `nixpkgs-unstable` secondary-input usage from code paths.
- Keep host outputs and module composition behavior intact aside from package-source selection.
- Align canonical docs with the new unstable-default package policy.

**Non-Goals:**
- No CI/CD policy expansion or Renovate automation work in this change.
- No service topology, secrets model, storage model, or network policy redesign.
- No `system.stateVersion` migration.

## Decisions

### D1 — Use one primary nixpkgs input (`nixos-unstable`)
**Decision:** Replace primary `nixpkgs` input ref with `nixos-unstable` and remove dedicated `nixpkgs-unstable` input from active flake wiring.

**Rationale:** Reduces split-package-set complexity and makes package provenance explicit and consistent across hosts/modules.

**Alternative considered:** Keep stable primary and retain selective unstable overrides.
- Rejected because it preserves current clutter and ongoing exception churn.

### D2 — Keep exceptions allowed, but not pre-provisioned
**Decision:** Do not keep an unused stable secondary input “just in case.” Reintroduce stable input only when a concrete package/module issue appears.

**Rationale:** Keeps active configuration minimal and avoids carrying unused fallback complexity.

**Alternative considered:** Keep secondary stable input present but unused.
- Rejected for now because it increases mental overhead without immediate value.

### D3 — Preserve host compatibility semantics
**Decision:** Keep `system.stateVersion` unchanged and avoid behavioral changes outside package-source defaults.

**Rationale:** `system.stateVersion` is migration-compatibility metadata, not the active nixpkgs channel; changing it would expand risk and scope.

**Alternative considered:** Update `system.stateVersion` with channel shift.
- Rejected as incorrect coupling and unnecessary migration risk.

### D4 — Update canonical docs in same change window
**Decision:** Update `docs/architecture.md`, `docs/decisions.md`, and `docs/plan.md` to reflect unstable-default policy.

**Rationale:** Prevents doc/code drift and keeps canonical guidance authoritative.

**Alternative considered:** Defer doc updates.
- Rejected because it would immediately create policy ambiguity.

## Risks / Trade-offs

- [Risk] Upstream nixpkgs-unstable churn can introduce more frequent breakage than stable snapshots.
  → **Mitigation:** Keep scope narrow (package-source policy only), preserve existing rollback/deploy flows, and allow targeted future exceptions if concrete breakages appear.

- [Risk] Multi-host evaluation differences between `aarch64-linux` and `x86_64-linux` may surface after unifying package source.
  → **Mitigation:** Validate both active host outputs during implementation verification.

- [Risk] Historical planning docs may still mention stable-first rationale.
  → **Mitigation:** Treat `docs/` as canonical and update derived guidance (`CLAUDE.md`) where applicable; leave historical artifacts as non-canonical context unless explicitly requested.

- [Trade-off] Removing pre-provisioned stable fallback optimizes clarity but may require a quick follow-up if a regression appears.
  → **Mitigation:** Reintroduce a stable input as a targeted exception only when justified by concrete failure.
