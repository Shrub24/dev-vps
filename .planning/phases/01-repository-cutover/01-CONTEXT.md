# Phase 1: Repository Cutover - Context

**Gathered:** 2026-03-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Make this repository unambiguously fleet-oriented (not legacy `dev-vps`) by cutting over the structure, active baseline paths, and documentation authority so future hosts can be added without another structural rewrite.

</domain>

<decisions>
## Implementation Decisions

### Repository layout
- **D-01:** Execute a full cutover now instead of a bridge layout.
- **D-02:** Place first-host identity under `hosts/oci-melb-1`.
- **D-03:** Group reusable logic under `modules/core`, `modules/profiles`, and `modules/services`.
- **D-04:** Keep scaffolding minimal: only create directories/files that are wired into the active baseline.

### Legacy asset policy
- **D-05:** Remove legacy provider-specific implementation from mainline once the fleet path is in place.
- **D-06:** Keep most historical context in git history, not in active in-repo legacy trees.
- **D-07:** Remove broken legacy references immediately (including missing `home/` and `pkgs/` references in active wiring).
- **D-08:** Remove personal-tooling baseline concerns (for example `codenomad`, `opencode`, `repo-sync`) from the repository mission baseline.

### Documentation authority
- **D-09:** `docs/` is the canonical human-facing architecture and decision source.
- **D-10:** `README.md` should remain a thin orientation entrypoint.
- **D-11:** `CLAUDE.md` is a derived mirror, not the authoritative source.
- **D-12:** If docs conflict during migration, fix or archive immediately.

### the agent's Discretion
- Exact naming for helper files and module sub-slices inside `modules/core`, `modules/profiles`, and `modules/services`.
- Mechanical migration sequencing for moving files while keeping the flake evaluable through each commit.
- How to stage doc cleanup as long as `docs/` stays canonical and conflicts are removed promptly.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and acceptance boundaries
- `.planning/ROADMAP.md` - Phase 1 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` - `REPO-01`, `REPO-02`, `REPO-03`, `OPER-02` requirements mapped to Phase 1.
- `.planning/PROJECT.md` - mission pivot, constraints, and migration non-negotiables.

### Canonical documentation authority for cutover
- `docs/architecture.md` - target repository shape and boundary principles.
- `docs/decisions.md` - accepted decisions including mission pivot and aggressive cleanup posture.
- `docs/plan.md` - migration strategy and documentation maintenance rule.
- `docs/context-history.md` - why the repo direction changed and what legacy assumptions must be retired.

### Current codebase reality to reconcile
- `flake.nix` - current entrypoint and remaining legacy references to remove/replace.
- `deploy.sh` - legacy operational path to align or retire under new baseline.
- `justfile` - active command surface still tied to legacy shape.
- `.github/workflows/ci.yml` - CI assumptions that must match the cutover layout.
- `.planning/codebase/ARCHITECTURE.md` - mapped evidence of current-vs-target architecture drift.
- `.planning/codebase/CONCERNS.md` - risk hot spots relevant to cutover sequencing.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `flake.nix`: already the canonical top-level flake entrypoint; cutover should preserve this role while changing its host/module composition shape.
- `nixos/configuration.nix`: carries reusable baseline NixOS patterns that can be refactored into `modules/core` or `modules/profiles`.
- `nixos/disko-config.nix`: existing declarative disk configuration can be retained as source material when host paths are reorganized.
- `.sops.yaml` and `secrets/secrets.template.yaml`: existing secret-policy assets that should remain aligned with new path ownership.

### Established Patterns
- The active repository still follows a flat, legacy-first structure centered on `flake.nix` plus `nixos/`.
- Operational commands and CI currently reference `dev-vps` assumptions, so cutover work must include automation and docs together.
- Planning artifacts in `.planning/` and intent docs in `docs/` already define fleet direction; implementation must catch up to documented intent.

### Integration Points
- Flake outputs and module imports in `flake.nix` are the primary integration point for moving host identity and shared modules.
- Command wrappers in `justfile` and `deploy.sh` must be updated in lockstep with the new layout.
- CI workflow `.github/workflows/ci.yml` must validate the same canonical paths exposed to operators.
- Top-level docs (`README.md`, `docs/*.md`, `CLAUDE.md`) must be made consistent in one cutover window to avoid dual-mission drift.

</code_context>

<specifics>
## Specific Ideas

- "Real cutover now" rather than maintaining a long-lived bridge structure.
- Keep scaffolding lean: only include files that are immediately wired and used.
- Treat generated agent guidance as derived output; keep durable decision history in `docs/`.

</specifics>

<deferred>
## Deferred Ideas

- Canonical naming strategy variants were not discussed in this session (the selected areas were layout, legacy policy, and docs authority).

</deferred>

---

*Phase: 01-repository-cutover*
*Context gathered: 2026-03-21*
