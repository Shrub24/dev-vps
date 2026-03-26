---
phase: 03-oci-host-bring-up-and-private-operations
status: passed
verified: 2026-03-26
requirements_checked: [BOOT-01, BOOT-02, BOOT-03, ACCS-01, ACCS-02, STOR-01, STOR-02, SRVC-01, OPER-01]
plans_verified: [03-01, 03-02, 03-03]
---

# Phase 03 Verification

Phase 03 goal is met: bootstrap, private access posture, and day-2 host-targeted operations are now backed by executable contract tests and operator runbooks.

## Must-Have Checks

1. Bootstrap contract is machine-enforced: **PASS**
   - Evidence: `tests/phase-03-bootstrap-contract.sh` asserts `nixos-anywhere`, `--build-on-remote`, flake target, host import, and disk label/mount invariants.
   - Evidence: `03-BOOTSTRAP.md` uses the same command contract and troubleshooting checks.

2. Tailscale-first private access posture is explicit: **PASS**
   - Evidence: `modules/services/tailscale.nix` declares `services.tailscale = { enable = true; openFirewall = false; };`.
   - Evidence: `tests/phase-03-access-contract.sh` enforces trusted interface and service firewall invariants.

3. Break-glass recovery path is tracked in-repo: **PASS**
   - Evidence: `03-BREAKGLASS.md` includes serial console flow, generation rollback, and tailscaled restart/status commands.

4. Day-2 operations and storage path invariants are executable: **PASS**
   - Evidence: `tests/phase-03-operations-contract.sh` enforces `redeploy` command contract and `/srv/data` service paths.
   - Evidence: `justfile` includes `verify-phase-03` and `03-OPERATIONS.md` documents verify → redeploy → post-check sequence.

5. Prior-phase regression checks remain green: **PASS**
   - Evidence: `bash tests/phase-02-03-host-contract.sh` exits 0 after Phase 03 changes.

6. Requirement coverage for this phase: **PASS**
   - BOOT-01, BOOT-02, STOR-01 covered by Plan 03-01 artifacts.
   - ACCS-01, ACCS-02, SRVC-01 covered by Plan 03-02 artifacts.
   - BOOT-03, OPER-01, STOR-02 covered by Plan 03-03 artifacts.

## Verification Commands Run

- `bash tests/phase-03-bootstrap-contract.sh`
- `bash tests/phase-03-access-contract.sh`
- `bash tests/phase-03-operations-contract.sh`
- `just verify-phase-03`
- `bash tests/phase-02-03-host-contract.sh`

## Verification Debt

- `just redeploy` failed in this executor environment because `oci-melb-1` is not resolvable from the runner (`ssh: Could not resolve hostname oci-melb-1`). Live host-targeted deploy validation must be executed from an operator environment with network reachability.
- Serial-console recovery flow in `03-BREAKGLASS.md` remains a live-environment operational validation item.

## Human Verification

None required to accept code and documentation artifacts for this phase.
