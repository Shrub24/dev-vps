---
phase: 01
slug: repository-cutover
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-21
---

# Phase 01 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | command-level Nix validation (no unit test framework) |
| **Config file** | `justfile`, `.github/workflows/ci.yml` |
| **Quick run command** | `nix flake check --no-build --no-write-lock-file path:.` |
| **Full suite command** | `nix flake check --no-build --no-write-lock-file path:. && nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `nix flake check --no-build --no-write-lock-file path:.`
- **After every plan wave:** Run `nix flake check --no-build --no-write-lock-file path:. && nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | REPO-01 | integration | `nix flake check --no-build --no-write-lock-file path:.` | ✅ | ⬜ pending |
| 01-01-02 | 01 | 1 | REPO-03 | static-check | `rg "hosts/oci-melb-1|modules/core|modules/profiles|modules/services" flake.nix` | ✅ | ⬜ pending |
| 01-02-01 | 02 | 2 | REPO-01 | integration | `nix build --no-link --no-write-lock-file path:.#nixosConfigurations.oci-melb-1.config.system.build.toplevel` | ✅ | ⬜ pending |
| 01-02-02 | 02 | 2 | REPO-02 | static-check | `rg "oci-melb-1|target-host|flake" justfile deploy.sh .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 01-03-01 | 03 | 2 | REPO-02, OPER-02 | docs-check | `rg "docs/" README.md CLAUDE.md` | ✅ | ⬜ pending |

*Status: ⬜ pending - ✅ green - ❌ red - ⚠ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
