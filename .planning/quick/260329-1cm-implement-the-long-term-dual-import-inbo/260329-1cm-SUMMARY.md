---
phase: quick-260329-1cm-implement-the-long-term-dual-import-inbo
plan: 01
subsystem: infra
tags: [nixos, music-ingest, slskd, syncthing, navidrome, contract-test]
requires:
  - phase: 04-service-baseline-and-data-safety
    provides: direct Syncthing to Navidrome media flow and phase-04 service contracts
provides:
  - Application-owned ingest boundary at /srv/data/inbox via music-ingest
  - slskd confinement to /srv/data/inbox/slskd/{complete,incomplete}
  - Updated phase-04 contracts and docs that fail on ingest-boundary drift
affects: [music-application-layer, slskd-service-boundary, phase-04-service-flow-contract, canonical-docs]
tech-stack:
  added: []
  patterns:
    - Keep generic ingest ownership in modules/applications/music.nix and out of modules/core/users.nix
    - Keep authoritative media library path at /srv/data/media while confining slskd ingest paths
key-files:
  created:
    - .planning/quick/260329-1cm-implement-the-long-term-dual-import-inbo/260329-1cm-SUMMARY.md
  modified:
    - modules/applications/music.nix
    - modules/services/slskd.nix
    - modules/services/syncthing.nix
    - tests/phase-04-service-flow-contract.sh
    - .planning/phases/04-service-baseline-and-data-safety/04-SERVICE-FLOW.md
    - docs/architecture.md
    - docs/decisions.md
key-decisions:
  - "Own /srv/data/inbox at the music application layer with music-ingest instead of broadening core user permissions."
  - "Constrain slskd to /srv/data/inbox/slskd/{complete,incomplete} and preserve /srv/data/media as canonical media authority."
patterns-established:
  - "Application modules own cross-service ingest boundaries; service modules own only service-specific subtrees."
requirements-completed: [QUICK-260329-1CM-01]
duration: 11 min
completed: 2026-03-29
---

# Phase quick-260329-1cm Plan 01: implement-the-long-term-dual-import-inbo Summary

**The music application now owns a shared ingest root at `/srv/data/inbox` via `music-ingest` while slskd is constrained to `/srv/data/inbox/slskd/*` and Syncthing/Navidrome remain authoritative on `/srv/data/media`.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-29T01:00:00Z
- **Completed:** 2026-03-29T01:11:21Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- Added `music-ingest` at the application layer and moved generic `/srv/data/inbox` ownership into `modules/applications/music.nix` with a setgid tmpfiles rule.
- Confined slskd download paths and tmpfiles directory creation to `/srv/data/inbox/slskd/{complete,incomplete}` while preserving `/srv/data/media` sharing.
- Updated phase-04 contract checks and canonical docs/runbook so drift in ownership or path authority fails verification.

## Task Commits

Each task was committed atomically:

1. **Task 1: Move generic inbox ownership to the music application layer** - `330421f` (feat)
2. **Task 2: Align contracts and runbooks to the dual-import inbox model** - `79fdb70` (feat)

## Files Created/Modified
- `modules/applications/music.nix` - Introduces `music-ingest`, grants slskd membership, and owns `/srv/data/inbox` with setgid permissions.
- `modules/services/slskd.nix` - Moves slskd directories to `/srv/data/inbox/slskd/*` and scopes tmpfiles ownership to slskd subtree only.
- `modules/services/syncthing.nix` - Removes generic `/srv/data/inbox` tmpfiles ownership, leaving media-only authority.
- `tests/phase-04-service-flow-contract.sh` - Adds positive/negative assertions for music-ingest ownership, slskd confinement, and Syncthing non-ownership of inbox.
- `.planning/phases/04-service-baseline-and-data-safety/04-SERVICE-FLOW.md` - Documents app-owned inbox root and slskd-specific subtree contract.
- `docs/architecture.md` - Records app-layer ingest boundary ownership and canonical media path authority.
- `docs/decisions.md` - Adds accepted D-019 for `music-ingest` ownership and slskd confinement model.

## Decisions Made
- Implemented D-02/D-03 by placing generic ingest ownership in `modules/applications/music.nix` and not in `modules/core/users.nix`.
- Implemented D-04/D-05 by scoping slskd to a dedicated inbox subtree while keeping Syncthing/Navidrome anchored to `/srv/data/media`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## Authentication Gates
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Contracts now fail if Syncthing reclaims generic inbox ownership or if slskd escapes `/srv/data/inbox/slskd/*`.
- Docs and decision registry now match the long-term dual-import boundary model for future ingest producers.

## Self-Check: PASSED

- FOUND: `.planning/quick/260329-1cm-implement-the-long-term-dual-import-inbo/260329-1cm-SUMMARY.md`
- FOUND: `330421f`
- FOUND: `79fdb70`
