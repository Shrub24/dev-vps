---
phase: quick-260328-gij-fix-termix-container-wiring-and-startup
plan: 01
subsystem: infra
tags: [nixos, termix, podman, tailscale, contract-test]
requires:
  - phase: quick-260328-fax-make-application-groups-and-add-termix
    provides: admin application boundary and initial Termix module wiring
provides:
  - Upstream-aligned Termix container runtime contract (image, guacd env keys, persistent data mount)
  - Access-contract regression checks that fail if legacy Termix wiring strings reappear
affects: [termix-runtime, phase-03-access-contract, admin-application-boundary]
tech-stack:
  added: []
  patterns:
    - Keep Termix runtime wiring aligned to upstream container contract and enforce it with fixed-string regression checks
key-files:
  created:
    - .planning/quick/260328-gij-fix-termix-container-wiring-and-startup/260328-gij-SUMMARY.md
  modified:
    - modules/services/termix.nix
    - tests/phase-03-access-contract.sh
key-decisions:
  - "Preserve application-layer ownership by keeping Termix implemented in modules/services/termix.nix and composed from modules/applications/admin.nix."
  - "Keep Termix private/Tailscale-only and avoid introducing any public firewall openings while fixing startup wiring."
patterns-established:
  - "Termix runtime contract checks must assert positive upstream wiring and negative legacy-string regressions."
requirements-completed: [QUICK-260328-GIJ-01]
duration: 10 min
completed: 2026-03-28
---

# Phase quick-260328-gij Plan 01: fix-termix-container-wiring-and-startup Summary

**Termix now targets the upstream `ghcr.io/lukegus/termix:latest` runtime contract (`GUACD_HOST`/`GUACD_PORT`, `/app/data`) with regression checks that block legacy wiring from returning.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-28T12:02:54Z
- **Completed:** 2026-03-28T12:12:35Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Updated `modules/services/termix.nix` to use upstream image/runtime wiring needed for successful container startup.
- Enforced the corrected wiring contract in `tests/phase-03-access-contract.sh` with both required and forbidden string assertions.
- Preserved private admin posture: Termix remains composed through `modules/applications/admin.nix` without any new public firewall rules.

## Task Commits

Each task was committed atomically:

1. **Task 1: Correct Termix container runtime wiring to upstream contract** - `4f21f3b` (fix)
2. **Task 2: Lock the corrected Termix integration into the access contract** - `d5e35f4` (test)

## Files Created/Modified
- `modules/services/termix.nix` - Replaced legacy Termix image/env/path wiring with upstream contract values.
- `tests/phase-03-access-contract.sh` - Added contract checks requiring new Termix wiring and failing on legacy strings.
- `.planning/quick/260328-gij-fix-termix-container-wiring-and-startup/260328-gij-SUMMARY.md` - Captures execution, decisions, deviations, and verification evidence.

## Decisions Made
- Kept module boundaries unchanged (service implementation in `modules/services/termix.nix`, composition in `modules/applications/admin.nix`) and applied only runtime contract fixes.
- Enforced regressions directly in the existing phase-03 access contract test rather than introducing a separate test file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Verification environment lacked `nix` on PATH**
- **Found during:** Task 2 verification
- **Issue:** Plan verification command used `nix eval`, but shell reported `nix: command not found`.
- **Fix:** Switched verification invocation to absolute binary path `/nix/var/nix/profiles/default/bin/nix`.
- **Files modified:** None (execution environment workaround only)
- **Verification:** `bash tests/phase-03-access-contract.sh` and absolute-path `nix eval ... --raw` both succeeded.
- **Committed in:** N/A (no repository file change)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep; workaround was limited to command execution and all plan outputs were delivered.

## Issues Encountered
- `nix` was unavailable via PATH in this execution shell; resolved by using absolute binary path for required evaluation checks.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Termix startup wiring now matches upstream runtime expectations and is contract-tested.
- Access contract fails quickly if old image/env/path strings are reintroduced.
- Private/Tailscale-only admin boundary remains intact with no new public firewall exposure.

## Self-Check: PASSED
