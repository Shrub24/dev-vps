---
phase: 02-oci-bootstrap-and-service-readiness
plan: 03
subsystem: infra
tags: [nixos-anywhere, nixos-rebuild, oci, tailscale, syncthing, navidrome, slskd]
requires:
  - phase: 02-01
    provides: secrets split and host-scoped sops wiring baseline
  - phase: 02-02
    provides: service module and storage layout foundations
provides:
  - Canonical host composition now imports worker + syncthing/navidrome/slskd modules
  - Canonical operator contract includes install, redeploy, and verify-oci-contract flows
  - Tiered service readiness guide with process checks and explicit deferrals
affects: [phase-03-bootstrap-validation, operations-runbook, service-hardening]
tech-stack:
  added: []
  patterns: [host-level sequencing guards, justfile contract verification, deferred functional probes]
key-files:
  created:
    - .planning/phases/02-oci-bootstrap-and-service-readiness/02-SERVICE-READINESS.md
  modified:
    - hosts/oci-melb-1/default.nix
    - modules/services/slskd.nix
    - deploy.sh
    - justfile
    - tests/phase-02-03-host-contract.sh
key-decisions:
  - "Keep deploy.sh nixos-anywhere remote-build flags as the canonical OCI bootstrap contract."
  - "Expose host contract checks through just verify-oci-contract for repeatable local validation."
  - "Gate host-only SOPS secret declaration on file presence to preserve two-step bootstrap evaluation."
patterns-established:
  - "Host wiring pattern: imports from modules/* plus host-level service ordering overrides"
  - "Readiness pattern: process-level checks mandatory now, secret-dependent probes deferred"
requirements-completed: [SECR-03, SECR-04]
duration: 20 min
completed: 2026-03-26
---

# Phase 2 Plan 3: Canonical Operator Path and Service Readiness Summary

**OCI host composition now imports service/profile boundaries with enforced startup ordering, and operators have one canonical install/redeploy/verify contract with tiered readiness checks.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-03-26T15:15:49Z
- **Completed:** 2026-03-26T15:35:50Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Wired `oci-melb-1` to import `syncthing`, `navidrome`, `slskd`, and `worker-interface` modules while keeping private Tailscale-only firewall posture.
- Added canonical `verify-oci-contract` target in `justfile` and preserved bootstrap flags in `deploy.sh`.
- Added phase readiness documentation separating mandatory process-level checks from deferred secret-dependent functional probes.

## Task Commits

Each task was committed atomically:

1. **Task 1: Compose host with new service/profile modules and startup sequencing** - `0d4989c` (test), `f139463` (feat)
2. **Task 2: Normalize canonical operator entry path and add contract verification target** - `01f4cb1` (feat)

## Files Created/Modified
- `hosts/oci-melb-1/default.nix` - Imports new service/profile modules, enforces consumer ordering, and gates host secret declaration for bootstrap-safe eval.
- `modules/services/slskd.nix` - Adds required share directory wiring for valid option contract.
- `deploy.sh` - Preserves canonical nixos-anywhere remote-build bootstrap path.
- `justfile` - Adds `verify-oci-contract` target for deterministic eval checks.
- `tests/phase-02-03-host-contract.sh` - TDD contract assertions for host imports/firewall/ordering.
- `.planning/phases/02-oci-bootstrap-and-service-readiness/02-SERVICE-READINESS.md` - Process-level and deferred readiness runbook.

## Decisions Made
- Kept `deploy.sh` as install authority and `just` as day-2 operations authority (`redeploy` + `verify-oci-contract`).
- Added host-level ordering guards for `navidrome` and `slskd` consumers even when service modules include ordering.
- Treated missing required `slskd` options and missing host secret file as blocking correctness issues and fixed inline.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed missing required `slskd` option contract**
- **Found during:** Task 2 verification (`just verify-oci-contract`)
- **Issue:** Nix evaluation failed because `services.slskd.domain`, `services.slskd.environmentFile`, and `services.slskd.settings.shares.directories` were required but unset.
- **Fix:** Added `services.slskd.domain` and `services.slskd.environmentFile` in host config, tmpfiles rule for environment file, and `shares.directories` in `modules/services/slskd.nix`.
- **Files modified:** `hosts/oci-melb-1/default.nix`, `modules/services/slskd.nix`
- **Verification:** `just verify-oci-contract` now evaluates all required checks successfully.
- **Committed in:** `01f4cb1`

**2. [Rule 3 - Blocking] Gated host secret declaration for two-step bootstrap**
- **Found during:** Task 2 verification (`just verify-oci-contract`)
- **Issue:** Evaluation failed when `hosts/oci-melb-1/secrets.yaml` was absent.
- **Fix:** Wrapped `sops.secrets.tailscale_auth_key` under `lib.mkIf (builtins.pathExists ...)` to keep pre-secret bootstrap evaluation valid.
- **Files modified:** `hosts/oci-melb-1/default.nix`
- **Verification:** `just verify-oci-contract` passes without requiring host secret file presence.
- **Committed in:** `01f4cb1`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** All fixes were required to make the canonical verification contract executable; no scope creep beyond plan goals.

## Auth Gates

None.

## Issues Encountered
- `rg` pattern beginning with `--` in acceptance command required `rg -- "pattern"` invocation to avoid flag parsing.

## User Setup Required

None - no external service configuration required in this plan.

## Next Phase Readiness
- Host/module boundaries and operator command surface are now stable for phase-level OCI bootstrap validation.
- Deferred items remain explicit: orchestration tooling (D-19) and backup automation (D-20).

---
*Phase: 02-oci-bootstrap-and-service-readiness*
*Completed: 2026-03-26*

## Self-Check: PASSED

- FOUND: `.planning/phases/02-oci-bootstrap-and-service-readiness/02-oci-bootstrap-and-service-readiness-03-SUMMARY.md`
- FOUND: `0d4989c`
- FOUND: `f139463`
- FOUND: `01f4cb1`
