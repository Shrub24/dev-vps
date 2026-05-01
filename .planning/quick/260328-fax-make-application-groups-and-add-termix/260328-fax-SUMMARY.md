---
phase: quick-260328-fax-make-application-groups-and-add-termix
plan: 01
subsystem: infra
tags: [nixos, applications-layer, termix, tailscale, contract-test]
requires:
  - phase: 03-oci-host-bring-up-and-private-operations
    provides: tailscale-first private access baseline and phase-03 access contracts
  - phase: 04-service-baseline-and-data-safety
    provides: syncthing/navidrome/slskd direct media flow contracts
provides:
  - First-pass application composition boundary via modules/applications/music.nix and modules/applications/admin.nix
  - Dedicated low-level termix + guacd container service module with persistent /srv/data/termix state
  - Host, contract tests, and canonical docs aligned to enforce app-layer composition and private admin posture
affects: [oci-host-composition, phase-03-access-contract, phase-04-service-flow-contract, canonical-docs]
tech-stack:
  added: [termix container service module]
  patterns:
    - Keep logical composition in modules/applications while retaining implementation modules under modules/services
    - Enforce private admin posture through fixed-string contract checks rather than implicit assumptions
key-files:
  created:
    - modules/applications/music.nix
    - modules/applications/admin.nix
    - modules/services/termix.nix
    - .planning/quick/260328-fax-make-application-groups-and-add-termix/260328-fax-SUMMARY.md
  modified:
    - hosts/oci-melb-1/default.nix
    - tests/phase-03-access-contract.sh
    - tests/phase-04-service-flow-contract.sh
    - docs/architecture.md
    - docs/decisions.md
    - docs/plan.md
key-decisions:
  - "Add a narrow first-pass applications composition boundary (music/admin) without broad repository reorganization."
  - "Run Termix as a Tailscale-only admin application with no new public firewall opening."
patterns-established:
  - "Cross-service glue for composed systems lives in application modules, not host root files."
requirements-completed: [QUICK-260328-FAX-01]
duration: 5 min
completed: 2026-03-28
---

# Phase quick-260328-fax Plan 01: make-application-groups-and-add-termix Summary

**oci-melb-1 now composes through explicit music/admin application modules while Termix is added as a persistent private Tailscale-only admin service.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-28T11:21:06Z
- **Completed:** 2026-03-28T11:26:19Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added `modules/applications/music.nix` and `modules/applications/admin.nix` as the first-pass logical composition boundary.
- Added `modules/services/termix.nix` implementing Termix + guacd as Podman OCI containers with persistent state under `/srv/data/termix`.
- Rewired host imports, updated phase contracts, and updated canonical docs so the application boundary and private admin posture are enforced and documented.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the first-pass applications layer and Termix service module** - `5d73fe7` (feat)
2. **Task 2: Rewire the host and lock the new boundaries into contracts and canonical docs** - `22ff075` (feat)

## Files Created/Modified
- `modules/applications/music.nix` - Composes Syncthing/Navidrome/slskd and carries music-stack cross-service slskd glue.
- `modules/applications/admin.nix` - Composes Tailscale and Termix as private admin surface.
- `modules/services/termix.nix` - Implements low-level Termix + guacd container runtime and persistent directories.
- `hosts/oci-melb-1/default.nix` - Switches host imports to application layer and removes moved cross-service glue.
- `tests/phase-03-access-contract.sh` - Adds Termix private-admin assertions and guards against firewall-surface drift.
- `tests/phase-04-service-flow-contract.sh` - Asserts music-stack composition now flows through `modules/applications/music.nix`.
- `docs/architecture.md` - Documents application-layer boundary and private Termix posture.
- `docs/decisions.md` - Records decisions D-017 and D-018 for application composition and Tailscale-only Termix.
- `docs/plan.md` - Adds application-layer and Termix paths to active architecture planning anchors.

## Decisions Made
- Added only two application modules (`music`, `admin`) to establish composition intent while keeping low-level service modules unchanged in location.
- Kept Termix private by avoiding any new public firewall opening and preserving Tailscale-first trust boundary assumptions.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Contract checks now fail if host composition bypasses `modules/applications/{music,admin}.nix`.
- Contract checks now fail if Termix private posture drifts toward explicit public firewall exposure.
- Canonical docs reflect the active application boundary and Termix admin posture for future iterations.

## Self-Check: PASSED
