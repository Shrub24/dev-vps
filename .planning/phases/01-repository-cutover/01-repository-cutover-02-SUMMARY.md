---
phase: 01-repository-cutover
plan: 02
subsystem: infra
tags: [nix, ci, just, nixos-rebuild, nixos-anywhere]
requires:
  - phase: 01-01
    provides: Canonical `nixosConfigurations.oci-melb-1` output
provides:
  - Operator command surface aligned to `oci-melb-1`
  - CI checks aligned to canonical host output
affects: [operations, automation]
tech-stack:
  added: []
  patterns: [host-centric command naming, canonical flake target reuse across operator and CI workflows]
key-files:
  created: []
  modified: [justfile, deploy.sh, .github/workflows/ci.yml]
key-decisions:
  - "Use `TARGET_HOST` and `TARGET_USER` neutral naming across operator recipes."
  - "CI validates only canonical host outputs that exist in active flake wiring."
patterns-established:
  - "Operator and CI commands must target the same flake host output."
  - "Legacy personal tooling assumptions are removed from status and build defaults."
requirements-completed: [REPO-01, REPO-03]
duration: 5 min
completed: 2026-03-21
---

# Phase 1 Plan 2: Repository Cutover Summary

**Operator scripts and CI now use the same `oci-melb-1` canonical flake target without droplet/dev-vps assumptions.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-21T03:28:34Z
- **Completed:** 2026-03-21T03:33:33Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Replaced droplet/dev-vps naming in command wrappers with neutral `TARGET_HOST`/`TARGET_USER` variables.
- Repointed deploy and rebuild commands to `path:.#oci-melb-1` and `nixosConfigurations.oci-melb-1`.
- Updated CI workflow to keep `nix flake check --no-build` and build only the canonical host output.

## Task Commits
1. **Task 1: Update operator commands from droplet/dev-vps to host-centric target** - `7a8cca5` (feat)
2. **Task 2: Align CI checks with canonical host output** - `b9a8a7a` (feat)

## Files Created/Modified
- `justfile` - Host-centric variable naming and canonical target commands.
- `deploy.sh` - Canonical host flake target and neutral CLI usage text.
- `.github/workflows/ci.yml` - CI build aligned to `nixosConfigurations.oci-melb-1` only.

## Decisions Made
- Removed legacy status and profile commands tied to personal-tooling outputs that no longer exist in active flake outputs.
- Kept CI minimal and canonical: one flake check step plus one canonical host build step.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Ready for Plan 03 documentation authority reconciliation with implementation references now stable.

## Self-Check: PASSED
