---
phase: 02-oci-bootstrap-and-service-readiness
plan: 01
subsystem: infra
tags: [sops, sops-nix, tailscale, nixos, secrets]
requires:
  - phase: 01.1.1-legacy-config-migration-cleanup
    provides: active host/module layout and updated secret documentation baseline
provides:
  - explicit sops path scoping for shared and host-scoped secret files
  - host-scoped tailscale secret template and host wiring for two-step bootstrap
  - operator runbook for base install then host secret introduction
affects: [phase-02-plan-02, phase-02-plan-03, secrets-operations, host-bootstrap]
tech-stack:
  added: []
  patterns:
    - two-step bootstrap with optional host secret material at base install time
    - explicit host path-based recipient scoping in .sops.yaml
key-files:
  created:
    - hosts/oci-melb-1/secrets.template.yaml
    - .planning/phases/02-oci-bootstrap-and-service-readiness/02-SECRETS-BOOTSTRAP.md
  modified:
    - .sops.yaml
    - hosts/oci-melb-1/default.nix
key-decisions:
  - "Set secrets/common.yaml as default SOPS source and load tailscale enrollment from hosts/oci-melb-1/secrets.yaml only when present."
  - "Use explicit .sops.yaml path rules for common, transitional legacy, and oci host secret files with a host-specific recipient anchor."
patterns-established:
  - "Host-scoped enrollment material: tailscale auth key lives in hosts/<host>/secrets.yaml, not shared secret files."
  - "Bootstrap safety guard: secret-dependent service wiring is conditional on host secret file existence."
requirements-completed: [SECR-01, SECR-02, SECR-03, SECR-04]
duration: 177 min
completed: 2026-03-26
---

# Phase 2 Plan 1: Secrets Topology And Bootstrap Contract Summary

**Path-scoped SOPS recipient policy with host-scoped Tailscale enrollment wiring and a concrete two-step operator bootstrap contract.**

## Performance

- **Duration:** 177 min
- **Started:** 2026-03-25T22:49:20Z
- **Completed:** 2026-03-26T01:45:53Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Split `.sops.yaml` into explicit rules for `secrets/common.yaml`, transitional `secrets/secrets.yaml`, and `hosts/oci-melb-1/secrets.yaml` with an OCI host recipient anchor.
- Added `hosts/oci-melb-1/secrets.template.yaml` containing only `tailscale.auth_key` to enforce host-scoped enrollment material.
- Updated `hosts/oci-melb-1/default.nix` to use `secrets/common.yaml` by default and only set `services.tailscale.authKeyFile` when host secrets exist.
- Added `.planning/phases/02-oci-bootstrap-and-service-readiness/02-SECRETS-BOOTSTRAP.md` with explicit Step A / Step B operator commands and deferred boundaries (D-04, D-19, D-20).

## Task Commits

Each task was committed atomically:

1. **Task 1: Enforce host-safe SOPS path scoping and host secret template** - `cd39458` (feat)
2. **Task 2: Wire oci host config to common+host secret split** - `29e53cf` (feat)
3. **Task 3: Add explicit two-step secret bootstrap runbook for operators** - `8110a89` (docs)

## Files Created/Modified

- `.sops.yaml` - Added explicit path-scoped creation rules and `oci_melb_1_age` anchor.
- `hosts/oci-melb-1/secrets.template.yaml` - Added host-scoped Tailscale auth key template.
- `hosts/oci-melb-1/default.nix` - Split default vs host secret files and gated `authKeyFile` on host secret presence.
- `.planning/phases/02-oci-bootstrap-and-service-readiness/02-SECRETS-BOOTSTRAP.md` - Added two-step operator bootstrap contract and deferred scope statements.

## Decisions Made

- Keep base bootstrap successful without host-specific secret material by guarding secret-dependent Tailscale config with `builtins.pathExists ../../hosts/oci-melb-1/secrets.yaml`.
- Preserve transitional compatibility for legacy `secrets/secrets.yaml` while making `secrets/common.yaml` and host-specific paths explicit and auditable.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed planning state metadata after `state advance-plan` parse failure**
- **Found during:** Post-task state update sequence
- **Issue:** `gsd-tools state advance-plan` reported parse error for Current Plan/Total Plans in Phase and did not advance human-readable state fields.
- **Fix:** Manually updated `.planning/STATE.md` current focus/position and `.planning/ROADMAP.md` Phase 2 plan progress/checklist to reflect completed `02-01`.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Confirmed Phase 2 shows `1/3 In Progress` in roadmap and state now points to next plan.

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Metadata synchronization completed successfully; implementation scope unchanged.

## Issues Encountered

- `state advance-plan` returned a parse error on current STATE format; remaining state tooling commands worked and final state/roadmap entries were corrected manually.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 2 requirements `SECR-01..SECR-04` are represented in executable repository state.
- Next plans can build service readiness and storage contracts on top of explicit secret boundaries and the documented two-step bootstrap flow.

---
*Phase: 02-oci-bootstrap-and-service-readiness*
*Completed: 2026-03-26*

## Self-Check: PASSED

- FOUND: `.planning/phases/02-oci-bootstrap-and-service-readiness/02-oci-bootstrap-and-service-readiness-01-SUMMARY.md`
- FOUND commits: `cd39458`, `29e53cf`, `8110a89`
