---
phase: quick-260329-2hf-define-sdb-mount-srv-media-and-move-medi
plan: 01
subsystem: infra
tags: [nixos, disko, oci, syncthing, navidrome, slskd, storage-contract]
requires:
  - phase: 04-service-baseline-and-data-safety
    provides: direct media-flow contracts and service-path assertions
provides:
  - Dedicated OCI media disk contract /dev/sdb -> /srv/media
  - Service media authority migration to /srv/media with /srv/data ingest/state preserved
  - Updated phase-03/phase-04 contracts and docs that fail on media-path drift
affects: [oci-provider-storage, disko-layout, music-service-paths, phase-03-contracts, phase-04-contracts, canonical-docs]
tech-stack:
  added: []
  patterns:
    - Keep root/bootstrap disk and GRUB wiring on bootstrapDisk while introducing a separate media disk contract
    - Keep /srv/data for inbox and service-state paths while /srv/media becomes authoritative media storage
key-files:
  created:
    - .planning/quick/260329-2hf-define-sdb-mount-srv-media-and-move-medi/260329-2hf-SUMMARY.md
  modified:
    - hosts/oci-melb-1/bootstrap-config.nix
    - modules/providers/oci/default.nix
    - modules/storage/disko-root.nix
    - modules/services/syncthing.nix
    - modules/services/navidrome.nix
    - modules/services/slskd.nix
    - tests/phase-03-bootstrap-contract.sh
    - tests/phase-03-operations-contract.sh
    - tests/phase-04-syncthing-contract.sh
    - tests/phase-04-service-flow-contract.sh
    - .planning/phases/04-service-baseline-and-data-safety/04-SERVICE-FLOW.md
    - docs/architecture.md
    - docs/decisions.md
key-decisions:
  - "Declare oci-melb-1 mediaDisk as /dev/sdb and bind it to disko disk.media mounted at /srv/media."
  - "Move Syncthing/Navidrome/slskd shared-library media authority to /srv/media while preserving /srv/data inbox and service-state ownership."
patterns-established:
  - "Provider bootstrap config supplies disk contracts; storage module owns filesystem/mount realization; service modules consume canonical mount paths."
requirements-completed: [QUICK-260329-2HF-01]
duration: 1 min
completed: 2026-03-29
---

# Phase quick-260329-2hf Plan 01: define-sdb-mount-srv-media-and-move-medi Summary

**OCI host storage now defines a dedicated `/dev/sdb` media filesystem mounted at `/srv/media`, and Syncthing/Navidrome/slskd consume that authoritative media path while `/srv/data` remains the inbox and service-state boundary.**

## Performance

- **Duration:** 1 min
- **Started:** 2026-03-29T02:04:13Z
- **Completed:** 2026-03-29T02:05:25Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments
- Added host/provider/storage wiring so `oci-melb-1` declares `mediaDisk = "/dev/sdb"` and disko mounts a dedicated ext4 media filesystem at `/srv/media`.
- Migrated Syncthing `dataDir`/folder path, Navidrome `MusicFolder`, and slskd shared-library path from `/srv/data/media` to `/srv/media` without moving inbox/service-state paths off `/srv/data`.
- Updated phase-03 and phase-04 contract checks plus canonical runbook/architecture/decision docs so path drift back to `/srv/data/media` fails verification.

## Task Commits

Each task was committed atomically:

1. **Task 1: Define the dedicated `/srv/media` mount contract for OCI** - `9d739c9` (feat)
2. **Task 2: Move media-consuming services to `/srv/media` without changing ingest boundaries** - `f83991d` (feat)
3. **Task 3: Align runbooks and architecture records to the new media mount** - `4ba5199` (feat)

## Files Created/Modified
- `hosts/oci-melb-1/bootstrap-config.nix` - Adds `mediaDisk = "/dev/sdb"` host contract.
- `modules/providers/oci/default.nix` - Binds `bootstrapConfig.mediaDisk` into `disko.devices.disk.media.device`.
- `modules/storage/disko-root.nix` - Declares dedicated ext4 `srv-media` filesystem mounted at `/srv/media`.
- `modules/services/syncthing.nix` - Moves media authority (`dataDir`, folder path, tmpfiles media directory) to `/srv/media` and keeps config under `/srv/data/syncthing/config`.
- `modules/services/navidrome.nix` - Moves `MusicFolder` to `/srv/media` while preserving `DataFolder = "/srv/data/navidrome"`.
- `modules/services/slskd.nix` - Moves only shared-library path to `/srv/media` and preserves `/srv/data` download/incomplete paths.
- `tests/phase-03-bootstrap-contract.sh` - Enforces `mediaDisk`, provider binding, and `/srv/media` mount literals.
- `tests/phase-03-operations-contract.sh` - Asserts `/srv/media` media authority with `/srv/data` inbox/service-state invariants.
- `tests/phase-04-syncthing-contract.sh` - Asserts Syncthing media authority on `/srv/media`.
- `tests/phase-04-service-flow-contract.sh` - Asserts Syncthing/Navidrome/slskd shared-media path migration and preserves `/srv/data` ingest/state checks.
- `.planning/phases/04-service-baseline-and-data-safety/04-SERVICE-FLOW.md` - Updates direct media flow and no-duplicate-staging text for `/srv/media` authority.
- `docs/architecture.md` - Documents split between `/srv/data` service-state and `/srv/media` dedicated media filesystem.
- `docs/decisions.md` - Adds accepted D-020 recording `/dev/sdb` -> `/srv/media` contract and service-path migration.

## Decisions Made
- Introduced a host-scoped secondary media disk default at bootstrap config level and wired provider/storage modules to realize it declaratively.
- Preserved app-owned ingest and service-state boundaries on `/srv/data` while relocating only canonical media authority to `/srv/media`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## Authentication Gates
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Bootstrap, operations, and phase-04 contracts now fail if media authority drifts back from `/srv/media`.
- Canonical runbook and architecture/decision docs now match the storage split and preserve `/srv/data` ingest/state boundaries.

## Self-Check: PASSED

- FOUND: `.planning/quick/260329-2hf-define-sdb-mount-srv-media-and-move-medi/260329-2hf-SUMMARY.md`
- FOUND: `9d739c9`
- FOUND: `f83991d`
- FOUND: `4ba5199`
