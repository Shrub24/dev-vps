---
phase: 03
slug: oci-host-bring-up-and-private-operations
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-26
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | shell + Nix CLI contract checks |
| **Config file** | none — repository uses command-based validation |
| **Quick run command** | `just verify-oci-contract` |
| **Full suite command** | `just check && just verify-oci-contract` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `just verify-oci-contract`
- **After every plan wave:** Run `just check && just verify-oci-contract`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | BOOT-01, BOOT-02 | contract | `bash tests/phase-03-bootstrap-contract.sh` | ❌ W0 | ⬜ pending |
| 03-01-02 | 01 | 1 | STOR-01 | eval/grep | `nix eval --json path:.#nixosConfigurations.oci-melb-1.config.fileSystems` | ✅ | ⬜ pending |
| 03-02-01 | 02 | 1 | ACCS-01, SRVC-01 | eval/grep | `nix eval path:.#nixosConfigurations.oci-melb-1.config.services.tailscale.enable` | ✅ | ⬜ pending |
| 03-02-02 | 02 | 1 | ACCS-02 | docs contract | `rg "break-glass|serial console|rollback" .planning/phases/03-oci-host-bring-up-and-private-operations/03-BREAKGLASS.md` | ❌ W0 | ⬜ pending |
| 03-03-01 | 03 | 2 | BOOT-03, OPER-01 | contract | `bash tests/phase-03-operations-contract.sh` | ❌ W0 | ⬜ pending |
| 03-03-02 | 03 | 2 | STOR-02 | grep/eval | `rg "/srv/data/(syncthing|media|navidrome|inbox)" modules/services/*.nix` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/phase-03-bootstrap-contract.sh` — bootstrap and disk contract assertions
- [ ] `tests/phase-03-operations-contract.sh` — day-2 update workflow contract assertions
- [ ] `.planning/phases/03-oci-host-bring-up-and-private-operations/03-BREAKGLASS.md` — break-glass recovery runbook

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Serial-console recovery access from OCI control plane | ACCS-02 | Requires cloud console access and live host state | Follow `03-BREAKGLASS.md`: trigger recovery scenario on host, confirm console login and rollback command success |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
