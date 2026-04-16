## Context

`modules/applications/admin.nix` has accumulated identity wiring, service definitions, monitoring inventory, dashboard content, and tailscale/systemd glue in one file. In parallel, `hosts/do-admin-1/default.nix` carries policy resolution, secrets/templates, and networking-specific behavior in a single host entrypoint.

The repo already has the right primitives for a cleaner structure:
- `policy/web-services.nix` as canonical service catalog for edge/runtime metadata
- `lib/policy.nix` as the resolver/transformation layer
- existing service/application split under `modules/services/` and `modules/applications/`

This change formalizes that layered model for admin services while preserving existing behavior and private-first constraints.

## Goals / Non-Goals

**Goals:**
- Split admin service wiring into service-owned modules under `modules/services/admin/`.
- Keep `applications.admin` as a composition entrypoint under `modules/applications/admin/default.nix`.
- Split complex config payloads into adjacent data files (Homepage and Gatus support).
- Derive Gatus endpoint inventory from `policy/web-services.nix` (routing + health metadata).
- Consolidate SSOT for primary domain, subdomains/paths, and origin ports so these values are authored once and consumed by ingress, monitoring, and module wiring.
- Keep Homepage presentation metadata separate from policy.
- Perform a light host split for `do-admin-1` into `secrets.nix`, `edge.nix`, `networking.nix`.
- Preserve behavior: private-first posture, host-scoped secrets, OIDC posture for phase-1 apps.

**Non-Goals:**
- Introducing admin subgroup toggles (`monitoring.enable`, etc.).
- Redesigning provider/storage/base host composition.
- Expanding policy schema with monitor toggles in this pass.
- Deriving Homepage UI structure from route policy.
- Feature expansion beyond structural refactor.

## Decisions

### Decision ADM-1: Adopt layered admin module architecture
- **Chosen:** enforce `policy -> lib resolver -> service modules -> application composition -> host assembly` layering.
- **Why:** matches current repo direction and reduces mixed-responsibility files.
- **Alternatives considered:**
  - Keep monolithic `applications/admin.nix`: rejected due to ongoing maintainability issues.
  - Add `modules/policy/`: rejected for now because `policy/` + `lib/policy.nix` already express this layer cleanly.

### Decision ADM-2: Service-level admin modules with admin namespace
- **Chosen:** create admin service modules under `modules/services/admin/` and keep reusable custom services (`termix`, `pocket-id`) in existing locations.
- **Why:** gives clear ownership boundaries and future reuse points while avoiding flat namespace sprawl.
- **Alternatives considered:**
  - Split only into `modules/applications/admin/*.nix` concern files: improves readability but leaves service contracts mixed with composition logic.
  - One huge services/admin file: insufficient decomposition.

### Decision ADM-3: Complex services use subdirectories + data files
- **Chosen:** `gatus/` and `homepage/` become subdirs with `default.nix` and adjacent data/config helper files.
- **Why:** keeps module code focused and avoids massive inline attrsets.
- **Alternatives considered:**
  - Keep all payload inline: rejected due to readability and review cost.
  - Move all payload to policy: rejected because Homepage data is presentation-specific, not route policy.

### Decision ADM-4: Gatus inventory derives from policy/web-services
- **Chosen:** generate Gatus endpoints from resolved host services in `policy/web-services.nix` (including health path/status metadata), monitoring all resolved services for now.
- **Why:** removes duplicated service lists and aligns health checks with canonical route inventory.
- **Alternatives considered:**
  - Hand-maintained Gatus endpoint list: rejected due to drift risk.
  - Add monitor toggle now: deferred; can be added later without blocking structural refactor.

### Decision ADM-8: Canonical routing and endpoint values become policy SSOT
- **Chosen:** keep `policy/web-services.nix` (plus policy defaults/host defaults) as the authoritative source for route-level domain/subdomain/path and origin endpoint values consumed by edge, monitoring, and service composition.
- **Why:** removes repeated literals (domain, subdomain, path, port) across modules and reduces drift.
- **Alternatives considered:**
  - Keep values duplicated per module: rejected due to inevitable divergence.
  - Introduce separate domain/ports file in this change: rejected to avoid parallel catalogs; prefer one canonical policy map and helper projections.

### Decision ADM-9: Introduce policy projection helpers for consumers
- **Chosen:** extend policy helper projections in `lib/policy.nix` so consumers can request resolved service endpoints/host/domain/ports without re-defining literals.
- **Why:** centralizes normalization and keeps consuming modules thin.
- **Alternatives considered:**
  - Per-module custom transforms: rejected due to repeated logic.

### Decision ADM-10: Keep Cockpit module migrated but disabled by host override
- **Chosen:** migrate Cockpit into service-level admin module ownership with the rest of admin decomposition, but keep runtime disabled (`enable = false`) as a temporary host-level exception while upstream issue is unresolved.
- **Why:** preserves structural consistency and avoids special-case migration gaps while preventing known-bad runtime activation.
- **Alternatives considered:**
  - Omit Cockpit from migration: rejected because it leaves a structural outlier and future cleanup debt.
  - Keep Cockpit enabled anyway: rejected due to known upstream regression impact.

### Decision ADM-5: Homepage remains presentation-owned
- **Chosen:** Homepage layout/services/bookmarks stay in Homepage module data files and are not policy-derived.
- **Why:** Homepage includes UI metadata (icons, groups, descriptions, widget wiring) that is outside route policy concerns.
- **Alternatives considered:**
  - derive homepage from policy: rejected to avoid overloading policy with UI concerns.

### Decision ADM-6: Light host split in same change
- **Chosen:** split `hosts/do-admin-1/default.nix` into focused imports (`secrets`, `edge`, `networking`) while keeping default as assembly.
- **Why:** removes immediate host-level clutter with low migration risk.
- **Alternatives considered:**
  - no host split: rejected because host file remains over-dense.
  - deep host redesign: rejected as scope/risk inflation.

### Decision ADM-7: Sequence after unstable migration
- **Chosen:** position this change after `migrate-nixpkgs-unstable-default`.
- **Why:** avoids spreading transitional `nixpkgs-unstable` imports across freshly split files.
- **Alternatives considered:**
  - refactor first: rejected due to avoidable churn.

## Risks / Trade-offs

- **[Risk] Structural churn obscures behavior drift** → **Mitigation:** preserve existing option contracts and service posture; validate with flake checks and targeted host evaluation.
- **[Risk] Policy-derived Gatus generation may mismatch legacy endpoint expectations** → **Mitigation:** derive from resolved host services including policy health defaults; keep extension point for extra config later.
- **[Risk] Module boundary ambiguity between service/application layers** → **Mitigation:** define service-owned vs composition-owned responsibilities explicitly in change docs/spec.
- **[Risk] Host split introduces import-order regressions** → **Mitigation:** keep `default.nix` as canonical assembler; migrate blocks without semantic changes and re-evaluate host config.
- **[Risk] Future multi-host divergence if admin modules leak do-admin-specific assumptions** → **Mitigation:** keep provider/host specifics in host files and policy, not reusable admin service modules.
- **[Risk] SSOT scope creep turns policy into a grab-bag** → **Mitigation:** keep policy limited to routing/access/health/endpoint metadata; keep presentation and app-internal settings outside policy.
- **[Risk] Temporary cockpit-disable exception becomes permanent drift** → **Mitigation:** document exception in change artifacts and keep module in place so re-enable is a small host-level toggle once upstream is fixed.

## Migration Plan

1. Confirm unstable-default migration is complete and current branch baseline is aligned.
2. Create new admin service module tree and move service-owned logic from monolithic admin module.
3. Introduce `modules/applications/admin/default.nix` composition entrypoint and split composition concerns (`identity`, `access`, `monitoring`).
4. Implement policy-derived Gatus endpoint generation from resolved host services.
5. Add/adjust policy projection helpers to expose canonical domain/subdomain/path/port values to consumers.
6. Refactor edge/service consumers to use policy projections instead of duplicated literals.
7. Split Homepage payload into dedicated data files under Homepage service subdir.
8. Split `hosts/do-admin-1` into `secrets.nix`, `edge.nix`, `networking.nix`; keep default as assembly.
9. Update imports/references and run validations.
10. Deploy/evaluate on `do-admin-1` workflow and verify no behavior regressions.

Rollback:
- Revert change and switch to previous working generation.
- Restore previous monolithic admin module if needed.

## Open Questions

- Should policy-derived Gatus generation include an explicit future extension hook (e.g., append-only extra endpoints file) in this change or a follow-up?
- Should `services/admin/*` option naming be globally standardized now (prefix conventions) or incrementally as modules evolve?
