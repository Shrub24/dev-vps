---
phase: 01-repository-cutover
plan: 01
subsystem: infra
tags: [nix, flake, nixos, disko, sops-nix]
requires: []
provides:
  - Canonical `hosts/oci-melb-1` host entrypoint and reusable module boundaries
  - Fleet-oriented `flake.nix` output as `nixosConfigurations.oci-melb-1`
affects: [operations, ci, documentation]
tech-stack:
  added: []
  patterns: [host-plus-module composition, canonical flake host target]
key-files:
  created: [hosts/oci-melb-1/default.nix, modules/core/base.nix, modules/profiles/base-server.nix, modules/services/tailscale.nix]
  modified: [flake.nix, modules/core/base.nix]
key-decisions:
  - "Use `oci-melb-1` as the canonical NixOS flake output now, not as a bridge alias."
  - "Keep only required flake wiring for baseline evaluation and remove legacy personal-tooling outputs."
patterns-established:
  - "Host identity lives under `hosts/<host>/default.nix` and imports reusable modules."
  - "Active flake outputs avoid legacy package overlays and Home Manager coupling."
requirements-completed: [REPO-01, REPO-03]
duration: 10 min
completed: 2026-03-21
---

# Phase 1 Plan 1: Repository Cutover Summary

**Host-centric flake cutover now targets `nixosConfigurations.oci-melb-1` with reusable core/profile/service module boundaries.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-21T03:18:20Z
- **Completed:** 2026-03-21T03:28:20Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Created canonical host entrypoint at `hosts/oci-melb-1/default.nix` with required module imports.
- Added reusable module boundaries under `modules/core`, `modules/profiles`, and `modules/services`.
- Rewired `flake.nix` from `dev-vps` to `nixosConfigurations.oci-melb-1` and removed legacy `home/dev.nix` and `pkgs/*` output references.

## Task Commits
1. **Task 1: Create host-and-module contract files for cutover** - `d86d34a` (feat)
2. **Task 2: Rewire flake to canonical host and remove broken legacy refs** - `55f36c6` (feat)

## Files Created/Modified
- `hosts/oci-melb-1/default.nix` - Canonical host identity and import boundary.
- `modules/core/base.nix` - Shared baseline Nix and SSH policy plus boot loader baseline for evaluation.
- `modules/profiles/base-server.nix` - Thin profile composition entrypoint.
- `modules/services/tailscale.nix` - Reusable Tailscale service module boundary.
- `flake.nix` - Canonical host output and cut legacy package/Home Manager wiring.

## Decisions Made
- Moved active host composition to `hosts/oci-melb-1/default.nix` immediately rather than maintaining dual host output names.
- Preserved `devShells` while removing legacy package outputs and Home Manager host coupling to keep operator tooling available without legacy baseline dependencies.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolved flake evaluation assertions after cutover wiring**
- **Found during:** Task 2 (Rewire flake to canonical host and remove broken legacy refs)
- **Issue:** `nix flake check` failed with missing root filesystem and boot loader assertions after removing legacy host wiring.
- **Fix:** Added `./nixos/disko-config.nix` to active flake modules and boot loader baseline settings in `modules/core/base.nix`.
- **Files modified:** `flake.nix`, `modules/core/base.nix`
- **Verification:** `nix flake check --no-build --no-write-lock-file path:.` passed for configured outputs.
- **Committed in:** `55f36c6`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Fix was required to keep canonical host output evaluable and did not expand scope beyond baseline correctness.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Ready for Plan 02 command-surface and CI alignment against `oci-melb-1` output.
- Legacy operational naming still exists outside this plan scope and is expected to be removed in follow-up plan tasks.

## Self-Check: PASSED
