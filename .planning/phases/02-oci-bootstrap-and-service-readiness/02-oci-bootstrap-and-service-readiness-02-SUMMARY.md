---
phase: 02-oci-bootstrap-and-service-readiness
plan: 02
subsystem: infra
tags: [nixos, disko, syncthing, navidrome, slskd, systemd]
requires:
  - phase: 02-01
    provides: secrets topology and bootstrap-safe host secret loading
provides:
  - GPT+EFI+ext4 root+data storage contract with canonical /srv/data mount
  - private-first syncthing/navidrome/slskd module contracts with startup ordering
  - deferred worker interface option boundary without worker implementations
affects: [02-03 host composition, oci-melb-1 service readiness verification]
tech-stack:
  added: []
  patterns:
    - module-per-service contracts under modules/services
    - canonical data paths rooted at /srv/data for producer/consumer flow
key-files:
  created:
    - modules/services/syncthing.nix
    - modules/services/navidrome.nix
    - modules/services/slskd.nix
    - modules/profiles/worker-interface.nix
  modified:
    - modules/storage/disko-root.nix
key-decisions:
  - "Used ext4 mkfs extraArgs labels (-L rootfs, -L srv-data) to satisfy stable-id intent while keeping disko evaluation valid."
  - "Encoded consumer ordering in navidrome/slskd modules via wants/after network-online.target and syncthing.service."
patterns-established:
  - "Service readiness modules should default to private-only behavior (no firewall openings)."
  - "Canonical media path is /srv/data/media and ingest staging path is /srv/data/inbox."
requirements-completed: [SECR-03, SECR-04]
duration: 39 min
completed: 2026-03-26
---

# Phase 2 Plan 2: Storage and service-readiness contracts Summary

**Canonical /srv/data storage baseline plus syncthing-navidrome-slskd module contracts with explicit network->sync->consumer startup ordering.**

## Performance

- **Duration:** 39 min
- **Started:** 2026-03-26T02:02:48Z
- **Completed:** 2026-03-26T02:41:32Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Extended disko layout to GPT + EFI + ext4 root (60G) + ext4 data (`/srv/data`) with resilient data mount options.
- Added reusable Syncthing, Navidrome, and Slskd service modules with canonical `/srv/data/media` and `/srv/data/inbox` ownership model.
- Added `fleet.worker.enable` interface boundary to defer worker implementations while preserving phase contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend disko layout to canonical root+data baseline** - `a5acfa5` (feat)
2. **Task 2: Add private-first service modules and worker interface boundary** - `442f864` (feat)

## Files Created/Modified
- `modules/storage/disko-root.nix` - Added `data` partition and `/srv/data` mount contract with stable ext4 labels via mkfs args.
- `modules/services/syncthing.nix` - Enabled syncthing with config/data under `/srv/data` and tmpfiles for media/inbox directories.
- `modules/services/navidrome.nix` - Enabled navidrome consuming `/srv/data/media` and ordered service after network/syncthing.
- `modules/services/slskd.nix` - Enabled slskd with inbox complete/incomplete paths under `/srv/data/inbox` and ordered startup dependencies.
- `modules/profiles/worker-interface.nix` - Declared `fleet.worker.enable` option boundary with no worker units.

## Decisions Made
- Kept storage contract focused on one persistent non-root service mount (`/srv/data`) to align with D-06 and reduce early-operational complexity.
- Set service modules to private-first defaults (`openFirewall = false`) and encoded startup sequencing directly in consumer modules.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported disko filesystem label attribute**
- **Found during:** Task 1 (storage module verification)
- **Issue:** `label = "srv-data"`/`"rootfs"` under disko filesystem content caused Nix evaluation failure because the option does not exist.
- **Fix:** Switched to supported `extraArgs = [ "-L" "<label>" ]` for ext4 labels on both root and data filesystems.
- **Files modified:** `modules/storage/disko-root.nix`
- **Verification:** Plan verification command succeeded and `nix eval ...fileSystems."/srv/data".mountPoint` returned `/srv/data`.
- **Committed in:** `a5acfa5`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary correction to make the planned storage contract evaluable; no scope creep.

## Issues Encountered
- Initial disko label syntax was invalid for this module schema; corrected during verification.

## User Setup Required
None - no external service configuration required for this plan.

## Next Phase Readiness
- Host-level composition can now import these service/profile modules in Plan 02-03.
- Storage and service path contracts are in place for readiness checks and operator workflow wiring.

## Self-Check: PASSED

- Verified SUMMARY and all plan-created/modified files exist.
- Verified task commit hashes `a5acfa5` and `442f864` are present in git history.

---
*Phase: 02-oci-bootstrap-and-service-readiness*
*Completed: 2026-03-26*
