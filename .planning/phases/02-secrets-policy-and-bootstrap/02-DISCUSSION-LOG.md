# Phase 2: Secrets Policy And Bootstrap - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `02-CONTEXT.md`.

**Date:** 2026-03-22
**Phase:** 02-secrets-policy-and-bootstrap
**Areas discussed:** Bootstrap flow, Disk + mount model, Service readiness bar, Post-install ops, Architecture/technical goals

---

## Bootstrap flow

| Option | Description | Selected |
|--------|-------------|----------|
| Temp Linux -> anywhere | Boot temporary Linux image and run `nixos-anywhere` over SSH | ✓ |
| Direct custom image | Pre-baked image pipeline first | |
| Manual install | Hand-install baseline | |

**User's choice:** Temp Linux -> anywhere.
**Notes:** Chosen as standard for OCI first-host bring-up.

| Option | Description | Selected |
|--------|-------------|----------|
| Remote build on target | `--build-on-remote` posture from x86_64 operator host | ✓ |
| Cross-build locally | Force local cross-building first | |
| Hybrid fallback | Try local then fallback remote | |

**User's choice:** Remote build on target.
**Notes:** Matches prior validation direction and operator environment.

| Option | Description | Selected |
|--------|-------------|----------|
| After first boot | Host-specific secrets not required for initial bring-up success | ✓ |
| During first install | Require full secret bootstrap immediately | |
| Placeholder secrets only | Dummy placeholders during install | |

**User's choice:** After first boot.
**Notes:** Deeper secrets flow moved later.

| Option | Description | Selected |
|--------|-------------|----------|
| Require tested fallback | Prove non-SSH recovery path now | |
| Document fallback only | Document now, test later | |
| Defer fallback | Accept SSH-first for this phase | ✓ |

**User's choice:** Defer fallback.
**Notes:** OCI serial concept explained; user deferred hard recovery validation.

---

## Disk + mount model

| Option | Description | Selected |
|--------|-------------|----------|
| GPT+EFI+root+one data | ext4 root + one persistent data filesystem | ✓ |
| Root only now | Single filesystem then evolve later | |
| Advanced fs now | btrfs/zfs-first complexity | |

**User's choice:** GPT+EFI+root+one data.
**Notes:** Keep first-host shape simple and reproducible.

| Option | Description | Selected |
|--------|-------------|----------|
| Single canonical mount | One stable mount with service subdirectories | ✓ |
| Per-service custom mounts | Separate mount conventions per service | |
| Keep under /var only | No explicit persistent mount baseline | |

**User's choice:** Single canonical mount.

| Option | Description | Selected |
|--------|-------------|----------|
| Stable IDs only | by-id/by-uuid targeting required | ✓ |
| Allow /dev/vdX | Allow transient provider names | |
| Either is fine | No strict policy | |

**User's choice:** Stable IDs only.

| Option | Description | Selected |
|--------|-------------|----------|
| Baseline dirs only | Prepare paths/ownership, no real migration | ✓ |
| Include real data migration | Move existing data in this phase | |
| No storage prep | Defer all prep | |

**User's choice:** Baseline dirs only.

---

## Service readiness bar

| Option | Description | Selected |
|--------|-------------|----------|
| Tailscale + Syncthing + Navidrome | Baseline service trio | |
| Tailscale only | Networking-only phase | |
| Tailscale + one app | Partial app baseline | |
| Custom: tailscale + syncthing + slskd + navidrome | Extended service scope for this phase | ✓ |

**User's choice:** `tailscale`, `syncthing`, `slskd`, `navidrome`.
**Notes:** User expanded service list to include `slskd`.

| Option | Description | Selected |
|--------|-------------|----------|
| Enabled + active + basic check | Process and basic endpoint/status checks | |
| Enabled + active only | Process state only | |
| Full functional validation | Full end-to-end checks | |
| Custom: enabled + active mostly | Service-dependent checks where secrets may block deeper probes | ✓ |

**User's choice:** Enabled + active mostly, service-dependent depth.
**Notes:** Secret-dependent checks may be deferred.

| Option | Description | Selected |
|--------|-------------|----------|
| Tailscale-first private only | No public ingress in this phase | ✓ |
| Mixed private/public | Allow some public exposure | |
| Localhost only | No remote access baseline | |

**User's choice:** Tailscale-first private only.

| Option | Description | Selected |
|--------|-------------|----------|
| Tiered checks | Process-level now; secret-backed checks later | ✓ |
| Block on all checks | Require all checks now | |
| No checks now | Enable only; verify later | |

**User's choice:** Tiered checks.

---

## Post-install ops

| Option | Description | Selected |
|--------|-------------|----------|
| nixos-rebuild target-host | Standard update path for first-host operations | ✓ |
| deploy-rs now | Adopt orchestration now | |
| Manual SSH steps | No canonical update command | |

**User's choice:** `nixos-rebuild --target-host`.

| Option | Description | Selected |
|--------|-------------|----------|
| flake check + host eval | Preflight + post-apply sanity checks | ✓ |
| flake check only | Preflight only | |
| Manual verification only | No scripted checks baseline | |

**User's choice:** `flake check + host eval`.

| Option | Description | Selected |
|--------|-------------|----------|
| One canonical path | Keep `justfile`/`deploy.sh` aligned | ✓ |
| Multiple equivalent paths | Allow parallel operator paths | |
| Docs only | Defer script standardization | |

**User's choice:** One canonical path.

| Option | Description | Selected |
|--------|-------------|----------|
| Deploy orchestration + backups | Defer both | |
| Only deploy orchestration | Defer deploy orchestration only | |
| Defer nothing | Pull advanced ops in now | |
| Custom: defer deploy orchestration + backups + robust sops flow | Keep all as later phase concerns | ✓ |

**User's choice:** Defer deploy orchestration, backups, and robust small blast-radius host-driven `sops-nix` flow.

---

## Architecture and technical goals

| Option | Description | Selected |
|--------|-------------|----------|
| Host composes service modules | Host wiring + modular services boundary | ✓ |
| Provider composes services | Provider module controls service graph | |
| Monolithic host file | Keep all logic in one file | |

**User's choice:** Host composes service modules.

| Option | Description | Selected |
|--------|-------------|----------|
| Canonical media tree + inbox | Synced tree as SSOT; ingest via staging/promote | ✓ |
| Apps write directly to media tree | Consumers mutate canonical tree directly | |
| Temporary mixed writes | Allow mixed writes now | |

**User's choice:** Canonical media tree + inbox.
**Notes:** User clarified Syncthing keeps files in sync and effectively anchors SSOT; `slskd` downloads to inbox and worker flow promotes to synced media.

| Option | Description | Selected |
|--------|-------------|----------|
| Network -> sync -> consumers | Explicit startup dependency contract | ✓ |
| Independent startup | No strict ordering | |
| Consumer-first | Consumers start before sync path settles | |

**User's choice:** Network -> sync -> consumers.

| Option | Description | Selected |
|--------|-------------|----------|
| Worker profile interface | Define extension boundary now; implement later | ✓ |
| No worker interface yet | Decide when first worker lands | |
| Implement one worker now | Add worker runtime in this phase | |

**User's choice:** Worker profile interface now, worker implementation later.

---

## the agent's Discretion

- Exact command implementations for service checks and host eval probes.
- Exact folder names under canonical data mount when they preserve ownership model.
- Exact module/profile filenames for future worker boundary.

## Deferred Ideas

- Strong break-glass recovery validation (OCI serial and non-SSH recovery proofing).
- Robust secrets blast-radius hardening and host-driven secret rollout.
- Deploy orchestration tooling and backup automation.
