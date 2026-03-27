---
phase: 04-service-baseline-and-data-safety
plan: 01
subsystem: infra
tags: [syncthing, contract-test, data-safety]
requires:
  - phase: 03-oci-host-bring-up-and-private-operations
    provides: baseline service modules and verification patterns
provides:
  - Explicit Syncthing sendreceive folder contract on /srv/data/media
  - Executable phase contract assertions for Syncthing safety settings
affects: [04-02, verification]
tech-stack:
  added: []
  patterns: [fixed-string bash contract assertions]
key-files:
  created:
    - tests/phase-04-syncthing-contract.sh
  modified:
    - modules/services/syncthing.nix
key-decisions:
  - Keep Syncthing authoritative media path explicitly set under settings.folders."media".
  - Enforce trashcan versioning retention values declaratively to prevent drift.
patterns-established:
  - "Contract tests assert exact Nix literals for critical safety behavior"
requirements-completed: [SRVC-02, SRVC-04]
duration: 11min
completed: 2026-03-27
---

# Phase 04 Plan 01: Syncthing Mode and Safeguards Summary

**Syncthing now declares explicit sendreceive folder behavior with trashcan versioning safeguards on `/srv/data/media`, enforced by a dedicated phase contract test.**

## Performance

- **Duration:** 11 min
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added failing-first executable contract test for Syncthing mode and safety settings.
- Added explicit `settings.folders."media"` path, mode, and versioning safeguards to Syncthing module.
- Verified with `bash tests/phase-04-syncthing-contract.sh` and `just verify-oci-contract`.

## Task Commits
1. **Task 1: Add failing-first Syncthing contract test for mode and safeguards** - `f28170e` (test)
2. **Task 2: Implement explicit Syncthing folder mode and versioning safeguards** - `e6063e3` (feat)

## Files Created/Modified
- `tests/phase-04-syncthing-contract.sh` - Enforces exact Syncthing contract literals for SRVC-02/SRVC-04.
- `modules/services/syncthing.nix` - Adds explicit `media` folder contract and trashcan versioning params.

## Decisions Made
- Keep path authority at `/srv/data/media` in both top-level `dataDir` and explicit folder settings.
- Use fixed retention literals (`cleanoutDays = "30"`, `cleanupIntervalS = "86400"`) for predictable safeguards.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
Wave 1 safety and Syncthing mode contract are locked and ready for wave 2 service-flow validation.

## Self-Check: PASSED
