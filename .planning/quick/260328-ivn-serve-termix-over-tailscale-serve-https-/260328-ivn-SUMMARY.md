---
phase: quick-260328-ivn-serve-termix-over-tailscale-serve-https-
plan: 01
subsystem: infra
tags: [nixos, tailscale-serve, termix, podman, private-access, contract-test]
requires:
  - phase: quick-260328-fax-make-application-groups-and-add-termix
    provides: admin/service composition boundary and baseline Termix module
  - phase: quick-260328-gij-fix-termix-container-wiring-and-startup
    provides: upstream Termix runtime contract enforcement
provides:
  - Admin-layer systemd ownership for Tailscale Serve HTTPS path /termix
  - Localhost-only Termix host binding at 127.0.0.1:8083:8080
  - Access-contract checks guarding Serve ownership, path, backend target, and private posture
  - Phase-03 runbook command for tailscale serve status verification
affects: [modules/applications/admin.nix, modules/services/termix.nix, phase-03-operations-runbook, phase-03-access-contract]
tech-stack:
  added: []
  patterns:
    - Keep Tailscale Serve application routing in modules/applications/admin.nix while modules/services/tailscale.nix stays reusable and app-agnostic
    - Enforce private admin exposure with positive and negative fixed-string access contracts
key-files:
  created:
    - .planning/quick/260328-ivn-serve-termix-over-tailscale-serve-https-/260328-ivn-SUMMARY.md
  modified:
    - modules/applications/admin.nix
    - modules/services/termix.nix
    - tests/phase-03-access-contract.sh
key-decisions:
  - "Serve routing ownership for Termix remains in the admin application module to avoid expanding the reusable tailscale service module boundary."
  - "Termix remains local HTTP-only on 127.0.0.1:8083 with Tailscale HTTPS /termix as the only intended remote access path."
patterns-established:
  - "Private admin exposure changes must pair implementation edits with contract and runbook assertions in the same quick task."
requirements-completed: [QUICK-260328-IVN-01]
duration: 3 min
completed: 2026-03-28
---

# Phase quick-260328-ivn Plan 01: serve-termix-over-tailscale-serve-https- Summary

**Termix is now reachable privately as Tailscale HTTPS `/termix` from an admin-owned Serve unit while the container itself is constrained to localhost HTTP `127.0.0.1:8083`.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-28T13:50:07Z
- **Completed:** 2026-03-28T13:53:50Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Bound Termix published port to `127.0.0.1:8083:8080` so host-level exposure is localhost-only.
- Added `tailscale-serve-termix` oneshot service in `modules/applications/admin.nix` to own `/termix` Serve setup/teardown on HTTPS 443.
- Extended phase-03 access contract checks to assert Serve ownership/path/backend and reject Funnel/native-HTTPS drift.

## Task Commits

Each task was committed atomically:

1. **Task 1: Bind Termix to localhost and add admin-layer Tailscale Serve orchestration** - `98fd228` (feat)
2. **Task 2: Lock Serve routing into contract checks and the day-2 runbook** - `5a1028d` (test)

## Files Created/Modified
- `modules/services/termix.nix` - Changes Termix port publication from `8083:8080` to `127.0.0.1:8083:8080`.
- `modules/applications/admin.nix` - Adds `tailscale-serve-termix` systemd oneshot with Serve start/stop commands for `/termix`.
- `tests/phase-03-access-contract.sh` - Adds Serve ownership/path/backend assertions and negative checks for Funnel/public/native-HTTPS drift.
- `.planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md` - Adds `tailscale serve status` runbook check and expected `/termix` route output.
- `.planning/quick/260328-ivn-serve-termix-over-tailscale-serve-https-/260328-ivn-SUMMARY.md` - Captures execution outcomes and verification evidence.

## Decisions Made
- Kept `modules/services/tailscale.nix` untouched and application-agnostic while implementing Serve orchestration only in `modules/applications/admin.nix`.
- Used `/termix` path routing with backend `http://127.0.0.1:8083` and explicitly avoided Funnel/public ingress and native Termix HTTPS.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing unrelated dirty edits in `tests/phase-03-access-contract.sh` overlapped a planned task file**
- **Found during:** Task 2
- **Issue:** The repository already had unstaged modifications in the same test file required by this plan; direct editing risked mixing unrelated changes into task commit scope.
- **Fix:** Temporarily stashed pre-existing test changes, applied only plan-required assertions, committed task 2 atomically, then restored the stashed unrelated edits.
- **Files modified:** tests/phase-03-access-contract.sh
- **Verification:** `bash tests/phase-03-access-contract.sh` passed before and after stash restore, and task commit included only task-relevant diff.
- **Committed in:** `5a1028d`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Deviation was strictly to preserve atomicity and protect unrelated worktree changes; no scope expansion.

## Authentication Gates
None.

## Known Stubs
None.

## Issues Encountered
- Pre-existing local modifications overlapped one plan target file; resolved via temporary stash/pop isolation to preserve unrelated dirty worktree state.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `/termix` Tailscale Serve path is now codified in module wiring, regression tests, and day-2 operations checks.
- Verification now fails fast if Termix bind drifts away from localhost-only or if Serve wiring leaks into reusable tailscale module scope.
- Quick task requirement `QUICK-260328-IVN-01` is complete and traceable.

## Self-Check: PASSED
