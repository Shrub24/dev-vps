---
phase: 02
slug: oci-bootstrap-and-service-readiness
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 02 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Nix flake checks + `nix eval` structural assertions |
| **Config file** | `flake.nix` |
| **Quick run command** | `nix flake check --no-build --no-write-lock-file path:.` |
| **Full suite command** | `nix flake check --no-write-lock-file path:.` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `nix flake check --no-build --no-write-lock-file path:.`
- **After every plan wave:** Run `nix flake check --no-write-lock-file path:.`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SECR-01, SECR-02 | structure | `rg "path_regex|secrets/common|hosts/oci-melb-1/secrets" .sops.yaml` | ✅ | ⬜ pending |
| 02-01-02 | 01 | 1 | SECR-03, SECR-04 | config | `rg "sops.defaultSopsFile|tailscale_auth_key|hosts/oci-melb-1/secrets.yaml" hosts/oci-melb-1/default.nix` | ✅ | ⬜ pending |
| 02-02-01 | 02 | 1 | SECR-03 | eval | `nix eval --raw path:.#nixosConfigurations.oci-melb-1.config.fileSystems."/srv/data".device` | ✅ | ⬜ pending |
| 02-02-02 | 02 | 1 | SECR-04 | eval | `nix eval path:.#nixosConfigurations.oci-melb-1.config.services.tailscale.enable` | ✅ | ⬜ pending |
| 02-03-01 | 03 | 2 | SECR-03 | command | `just deploy-oci --help || true` | ✅ | ⬜ pending |
| 02-03-02 | 03 | 2 | SECR-01, SECR-02, SECR-04 | integration | `nix flake check --no-build --no-write-lock-file path:. && just verify-oci-contract` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tailscale join with host token | SECR-04 | Requires real tailnet token and network reachability | Run bootstrap on OCI host, then `ssh dev@oci-melb-1 'sudo tailscale status'` and confirm host appears with `tag:oci-melb-1`. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
