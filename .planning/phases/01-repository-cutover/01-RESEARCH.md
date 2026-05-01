---
phase: 01
slug: repository-cutover
status: complete
created: 2026-03-21
source: plan-phase
---

# Phase 01 Research - Repository Cutover

## Objective

Define a concrete implementation approach for cutting the repository from legacy `dev-vps` shape to a host-centric fleet layout while keeping the flake evaluable and docs authoritative.

## Inputs Reviewed

- `.planning/ROADMAP.md` (Phase 1 goal and success criteria)
- `.planning/REQUIREMENTS.md` (REPO-01, REPO-02, REPO-03, OPER-02)
- `.planning/phases/01-repository-cutover/01-CONTEXT.md` (locked decisions D-01..D-12)
- `flake.nix`, `justfile`, `deploy.sh`, `.github/workflows/ci.yml`
- `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, `docs/context-history.md`
- `.planning/codebase/ARCHITECTURE.md`, `.planning/codebase/CONCERNS.md`

## Findings

1. **Immediate blocker to reliable cutover validation:** `flake.nix` references missing `home/dev.nix` and `pkgs/*/package.nix`; CI mirrors those broken outputs. Phase 1 must remove those references or replace them with real fleet-wired paths as part of cutover (D-07, D-08).
2. **Repository mission drift remains in active wiring:** output name `nixosConfigurations.dev-vps`, DigitalOcean provider module, and droplet-focused ops scripts conflict with the target first-host identity `oci-melb-1` (D-02, D-05).
3. **Docs already define intended architecture:** `docs/` is ahead of code. Cutover should align code and command surface to existing docs, then tighten docs for canonical authority (D-09, D-10, D-12).
4. **Best low-risk sequencing:** contracts and directory shape first, then flake + host assembly, then command/CI surface, then documentation reconciliation.

## Recommended Implementation Shape

- Create `hosts/oci-melb-1` as the active host composition root (D-02).
- Create and wire `modules/core`, `modules/profiles`, and `modules/services` with only currently wired baseline modules (D-03, D-04).
- Remove legacy references to absent Home Manager and custom package overlays from active flake outputs (D-07, D-08).
- Rename active target to fleet host identity and update operators/CI to the same target.
- Keep `docs/` as canonical source; keep `README.md` short and orientation-only; keep `CLAUDE.md` aligned as derived mirror (D-09, D-10, D-11).

## Risks and Mitigations

- **Risk:** Large move breaks evaluation.
  - **Mitigation:** Ensure each task includes `nix flake check --no-build --no-write-lock-file path:.` verification and explicit grep checks for removed legacy references.
- **Risk:** Docs and implementation diverge during migration.
  - **Mitigation:** Include a dedicated docs authority task with concrete acceptance criteria for canonical file updates (OPER-02).
- **Risk:** Hidden dependence on legacy names in scripts/CI.
  - **Mitigation:** Include command surface task covering `justfile`, `deploy.sh`, and `.github/workflows/ci.yml` in one wave.

## Validation Architecture

Phase 1 should use command-level automated validation (no unit test framework exists):

- Quick loop command: `nix flake check --no-build --no-write-lock-file path:.`
- Build confirmation command: `nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel`
- Surface checks:
  - `rg "dev-vps|DROPLET_" flake.nix justfile deploy.sh .github/workflows/ci.yml`
  - `rg "home/dev.nix|pkgs/codenomad|pkgs/opencode|pkgs/repo-sync" flake.nix`

Nyquist implication: every implementation task in Phase 1 can and should provide an automated command under 60 seconds for smoke validation, plus one full `nix build` at plan completion.

## Decision Fit Check

- D-01 full cutover: supported by replacing active composition root now.
- D-02 host identity under `hosts/oci-melb-1`: mandatory in plan.
- D-03 module grouping under `modules/core|profiles|services`: mandatory in plan.
- D-04 minimal scaffolding: avoid creating unused modules/files.
- D-05/D-06 legacy removal from mainline: remove stale provider/personal-tooling baseline from active wiring.
- D-07 remove broken refs now: explicit flake cleanup is required.
- D-08 remove personal-tooling baseline concerns: remove those package/service dependencies from active baseline.
- D-09..D-12 docs authority and conflict cleanup: include explicit documentation task.

## Output for Planner

Use 2-3 execution plans:

1. **Code structure cutover plan** (host + modules + flake wiring)
2. **Ops surface alignment plan** (justfile/deploy/CI)
3. **Documentation authority plan** (`docs/`, `README.md`, `CLAUDE.md`)

Each plan should map to REPO-01/02/03 and OPER-02 with no requirement left uncovered.
