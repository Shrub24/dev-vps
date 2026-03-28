---
phase: quick-260328-lf9-switch-termix-tailscale-serve-from-path-
plan: 01
subsystem: infra
tags: [nixos, tailscale-serve, termix, private-access, contract-test, runbook]
requires:
  - phase: quick-260328-ivn-serve-termix-over-tailscale-serve-https-
    provides: admin-layer tailscale serve ownership and localhost-only termix binding
provides:
  - Dedicated Tailscale HTTPS Termix access contract on port 8443
  - Localhost-only Termix backend contract without /termix path coupling
  - Regression and runbook guards that fail on stale /termix assumptions
affects: [modules/applications/admin.nix, modules/services/termix.nix, phase-03-access-contract, phase-03-operations-runbook]
tech-stack:
  added: []
  patterns:
    - Keep Tailscale Serve application wiring in admin composition while tailscale service module remains app-agnostic
    - Enforce private-only dedicated-port admin exposure through contract tests and runbook guidance
key-files:
  created:
    - .planning/quick/260328-lf9-switch-termix-tailscale-serve-from-path-/260328-lf9-SUMMARY.md
  modified:
    - modules/applications/admin.nix
    - modules/services/termix.nix
    - tests/phase-03-access-contract.sh
    - .planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md
key-decisions:
  - "Use dedicated Tailscale HTTPS port 8443 for Termix instead of /termix path routing while preserving private-only exposure."
  - "Remove Termix path-base coupling and enforce dedicated-port expectations in both tests and operations guidance."
patterns-established:
  - "Private admin access contract changes must update module wiring, tests, and operator runbook in the same quick task."
requirements-completed: [QUICK-260328-LF9-01]
duration: 11 min
completed: 2026-03-28
---

# Phase quick-260328-lf9 Plan 01: switch-termix-tailscale-serve-from-path- Summary

**Termix now uses an admin-owned dedicated Tailscale HTTPS listener on port 8443 that proxies to local HTTP 127.0.0.1:8083 without any /termix path coupling.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-28T15:34:10Z
- **Completed:** 2026-03-28T15:45:18Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Rewired `tailscale-serve-termix` to use `--https=8443` with matching dedicated-port `off` command in admin composition.
- Removed `VITE_BASE_PATH` from Termix service wiring while preserving localhost-only `127.0.0.1:8083:8080` backend exposure.
- Replaced stale `/termix` contract checks and runbook wording with dedicated-port `8443` expectations.

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewire Termix from path-based Serve to dedicated HTTPS port 8443** - `0414756` (feat)
2. **Task 2: Replace stale `/termix` contract checks and operator guidance with dedicated-port expectations** - `6ce542b` (test)

## Files Created/Modified
- `modules/applications/admin.nix` - Swaps `/termix` path serve contract for dedicated `--https=8443` serve and off commands.
- `modules/services/termix.nix` - Removes `VITE_BASE_PATH` so runtime no longer assumes path-prefixed hosting.
- `tests/phase-03-access-contract.sh` - Asserts dedicated-port contract and fails fast if `/termix`/`VITE_BASE_PATH` assumptions reappear.
- `.planning/phases/03-oci-host-bring-up-and-private-operations/03-OPERATIONS.md` - Updates operator expectation to dedicated 8443 listener proxying to local Termix backend.
- `.planning/quick/260328-lf9-switch-termix-tailscale-serve-from-path-/260328-lf9-SUMMARY.md` - Captures execution outcomes and verification evidence.

## Decisions Made
- Followed locked decisions exactly: dedicated HTTPS port Serve, no native Termix TLS, no Funnel/public ingress, and no app-specific routing in `modules/services/tailscale.nix`.

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates
None.

## Known Stubs
None.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dedicated-port Termix access contract (`8443` -> `http://127.0.0.1:8083`) is now enforced in module wiring, regression checks, and day-2 operations guidance.
- Access checks now fail if stale `/termix` path-based assumptions or `VITE_BASE_PATH` coupling reappear.
- Quick task requirement `QUICK-260328-LF9-01` is complete and traceable.

## Self-Check: PASSED
