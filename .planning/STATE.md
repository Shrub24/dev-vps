---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: unknown
stopped_at: Completed quick-260328-lf9-PLAN.md
last_updated: "2026-03-28T15:51:44.196Z"
last_activity: "2026-03-28 - Completed quick task 260328-lf9: Switch Termix Tailscale Serve from path route to dedicated 8443 port"
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 15
  completed_plans: 15
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-03-21)

**Core value:** Bring up and operate a clear, reproducible, low-complexity first NixOS host that establishes the right foundation for future fleet growth.
**Current focus:** Phase 04 — service-baseline-and-data-safety

## Current Position

Phase: 04
Plan: Not started

## Performance Metrics

**Velocity:**

- Total plans completed: 3
- Average duration: 6 min
- Total execution time: 0.3 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 3 | 19 min | 6 min |

**Recent Trend:**

- Last 5 plans: 01-01, 01-02, 01-03
- Trend: Improving

| Phase 01 P01 | 10 min | 2 tasks | 5 files |
| Phase 01 P02 | 5 min | 2 tasks | 3 files |
| Phase 01 P03 | 4 min | 2 tasks | 6 files |
| Phase 01.1 P01 | 3 min | 2 tasks | 4 files |
| Phase 01.1 P02 | 2 min | 2 tasks | 5 files |
| Phase 01.1.1 P01 | 8 | 2 tasks | 4 files |
| Phase 01.1.1 P02 | 13 | 2 tasks | 5 files |
| Phase quick-260325-ojg-fix-local-direnv-nix-develop-dev-shell-o P01 | 3h 24m | 2 tasks | 2 files |
| Phase 02 P01 | 177 min | 3 tasks | 4 files |
| Phase 02 P02 | 39 min | 2 tasks | 5 files |
| Phase 02 P03 | 20 min | 2 tasks | 6 files |
| Phase 03 P01 | 12 min | 2 tasks | 2 files |
| Phase 03 P02 | 10 min | 2 tasks | 3 files |
| Phase 03 P03 | 15 min | 2 tasks | 3 files |
| Phase 04 P01 | 11 | 2 tasks | 2 files |
| Phase 04 P02 | 15 | 3 tasks | 3 files |
| Phase quick-260328-0gu-add-break-glass-access-guarantees-as-abo P01 | 6 min | 2 tasks | 4 files |
| Phase quick-260328-17w-implement-post-reboot-oci-console-access P01 | 6 min | 2 tasks | 5 files |
| Phase quick-260328-fax-make-application-groups-and-add-termix P01 | 5 min | 2 tasks | 9 files |
| Phase quick-260328-gij-fix-termix-container-wiring-and-startup P01 | 10 min | 2 tasks | 2 files |
| Phase quick-260328-ivn-serve-termix-over-tailscale-serve-https- P01 | 3 min | 2 tasks | 4 files |
| Phase quick-260328-lf9-switch-termix-tailscale-serve-from-path- P01 | 11 min | 2 tasks | 4 files |

## Accumulated Context

### Decisions

Decisions are logged in `PROJECT.md` Key Decisions table.
Recent decisions affecting current work:

- Phase 1: Remove legacy `dev-vps` framing and make the fleet repo shape authoritative.
- Phase 2: Keep secrets split between `secrets/common.yaml` and `hosts/<host>/secrets.yaml` with explicit `.sops.yaml` scoping.
- Phase 3: Bootstrap with `nixos-anywhere` and keep services private and Tailscale-only.
- Phase 4: Start with direct Syncthing-to-Navidrome media flow and safety controls.
- [Phase 01]: Use oci-melb-1 as canonical flake output and host boundary now
- [Phase 01]: Remove legacy package/Home Manager host wiring from active flake composition
- [Phase 01]: Use neutral TARGET_HOST/TARGET_USER naming in operator command surface
- [Phase 01]: CI builds only canonical oci-melb-1 host output
- [Phase 01]: Treat docs/ as canonical authority and keep README orientation-only
- [Phase 01]: Record full cutover and explicit module boundaries in decisions register
- [Phase 01.1]: Isolate OCI disk device defaults in modules/providers/oci/default.nix instead of flake inline overrides.
- [Phase 01.1]: Compose root disk layout from modules/storage/disko-root.nix through host imports to remove legacy nixos disko coupling.
- [Phase 01.1]: Retire legacy nixos/configuration.nix, nixos/digitalocean.nix, and nixos/disko-config.nix once active module wiring is verified.
- [Phase 01.1]: Keep docs/architecture.md and docs/context-history.md as canonical by updating active path references in the same cleanup plan.
- [Phase 01.1.1]: Set just logs default to tailscaled to remove retired codenomad assumptions from operator commands.
- [Phase 01.1.1]: Adopt transitional SOPS regex for secrets/common.yaml and secrets/secrets.yaml plus explicit hosts/<host>/secrets.yaml rule.
- [Phase 01.1.1]: Keep canonical docs explicitly anchored on secrets/common.yaml plus hosts/<host>/secrets.yaml with common template guidance.
- [Phase 01.1.1]: Rewrite planning codebase maps to match active flake->hosts->modules composition after legacy migration cleanup.
- [Phase quick-260325-ojg]: Use genAttrs for multi-system devShell outputs while keeping oci-melb-1 host pinned to aarch64-linux.
- [Phase 02]: Set secrets/common.yaml as default SOPS source while loading tailscale auth material from hosts/oci-melb-1/secrets.yaml only when present.
- [Phase 02]: Use explicit .sops.yaml path rules for common, transitional legacy, and oci host secrets with a host-specific age recipient anchor.
- [Phase 02]: Used ext4 mkfs extraArgs labels for rootfs and srv-data so disko storage contract evaluates cleanly.
- [Phase 02]: Encoded navidrome and slskd startup ordering against network-online and syncthing in service modules.
- [Phase 02]: Keep deploy.sh nixos-anywhere remote-build flags as the canonical OCI bootstrap contract.
- [Phase 02]: Expose host contract checks through just verify-oci-contract for repeatable local validation.
- [Phase 02]: Gate host-only SOPS secret declaration on file presence to preserve two-step bootstrap evaluation.
- [Phase 03]: Enforce bootstrap and storage invariants with fixed-string contract assertions before host installs.
- [Phase 03]: Keep bootstrap guidance limited to Tailscale-first private access with no public ingress steps.
- [Phase 03]: Declare tailscale openFirewall=false explicitly in module state instead of relying on implicit defaults.
- [Phase 03]: Store break-glass recovery as a command-level serial-console runbook in phase artifacts.
- [Phase 03]: Expose a dedicated verify-phase-03 recipe to run all contract checks plus verify-oci-contract.
- [Phase 03]: Keep day-2 deployment host-targeted and explicitly defer deploy-rs adoption.
- [Phase 04]: Keep path authority at /srv/data/media in both top-level dataDir and explicit folder settings.
- [Phase 04]: Use fixed retention literals (cleanoutDays=30, cleanupIntervalS=86400) for predictable Syncthing safeguards.
- [Phase 04]: Keep Navidrome direct-read rooted on /srv/data/media with no inbox staging path.
- [Phase 04]: Expose one operator command verify-phase-04 to run both phase contracts before redeploy.
- [Phase quick-260328-0gu]: Require just breakglass-baseline immediately before just redeploy so rollback anchors are captured pre-change.
- [Phase quick-260328-0gu]: Treat break-glass command coverage as part of tests/phase-03-access-contract.sh so drift fails verification early.
- [Phase quick-260328-17w]: Enforce phase-03 access verification against both declarative sshKeys ownership and OCI console hardening contracts.
- [Phase quick-260328-17w]: Declare ttyAMA0 serial console kernel/getty wiring in the OCI provider module to keep post-reboot console recovery explicit.
- [Phase quick-260328-fax]: Add a narrow applications composition boundary via modules/applications/music.nix and modules/applications/admin.nix
- [Phase quick-260328-fax]: Keep Termix Tailscale-only by introducing modules/services/termix.nix without new public firewall openings
- [Phase quick-260328-gij]: Preserve Termix ownership in modules/services/termix.nix and composition through modules/applications/admin.nix while fixing runtime wiring only.
- [Phase quick-260328-gij]: Enforce Termix upstream runtime contract in phase-03 access checks and fail on legacy termix-official/TERMIX_GUACD_/var/lib wiring strings.
- [Phase quick-260328-ivn]: Keep Termix private by binding container publish to 127.0.0.1:8083 and exposing it only via admin-layer tailscale serve /termix.
- [Phase quick-260328-ivn]: Preserve reusable tailscale module neutrality by placing Serve ownership in modules/applications/admin.nix and asserting this in phase-03 access contracts.
- [Phase quick-260328-lf9]: Replace /termix path assertions with dedicated-port regression and runbook checks while preserving tailscale module agnosticism and private-only posture.
- [Phase quick-260328-lf9]: Move Termix Tailscale Serve contract to dedicated HTTPS port 8443 while keeping backend target on local HTTP 127.0.0.1:8083.

### Roadmap Evolution

- Phase 01.1 inserted after Phase 01: modular provider flakes + integrate and remove legacy nixos flakes (URGENT)
- Phase 01.1.1 inserted after Phase 01.1: Legacy config migration cleanup (URGENT)

### Pending Todos

None yet.

### Blockers/Concerns

- Phase 3: Validate OCI ARM bootstrap specifics and stable device mapping before execution.
- Phase 3: Keep serial-console break-glass posture documented before Tailscale becomes the primary admin path.
- Phase 4: Define acceptable Syncthing conflict/delete recovery posture before calling the baseline stable.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260325-ojg | Fix local direnv nix develop dev shell on x86 after repo switched target to aarch64 | 2026-03-25 | e0a224a | [260325-ojg-fix-local-direnv-nix-develop-dev-shell-o](./quick/260325-ojg-fix-local-direnv-nix-develop-dev-shell-o/) |
| 260328-0gu | Add break-glass access guarantees as above | 2026-03-28 | 46e0297 | [260328-0gu-add-break-glass-access-guarantees-as-abo](./quick/260328-0gu-add-break-glass-access-guarantees-as-abo/) |
| 260328-17w | Implement post-reboot OCI console access | 2026-03-28 | f241fae | [260328-17w-implement-post-reboot-oci-console-access](./quick/260328-17w-implement-post-reboot-oci-console-access/) |
| fast-260328-ssh22 | Implement the open 22 port | 2026-03-28 | 2078d28 | [n/a](./) |
| 260328-fax | Make application groups and add Termix | 2026-03-28 | 22ff075 | [260328-fax-make-application-groups-and-add-termix](./quick/260328-fax-make-application-groups-and-add-termix/) |
| 260328-gij | Fix Termix container wiring and startup | 2026-03-28 | d5e35f4 | [260328-gij-fix-termix-container-wiring-and-startup](./quick/260328-gij-fix-termix-container-wiring-and-startup/) |
| 260328-ivn | Serve Termix over Tailscale Serve HTTPS | 2026-03-28 | 5a1028d | [260328-ivn-serve-termix-over-tailscale-serve-https-](./quick/260328-ivn-serve-termix-over-tailscale-serve-https-/) |
| 260328-lf9 | Switch Termix Tailscale Serve from path route to dedicated 8443 port | 2026-03-28 | 6ce542b | [260328-lf9-switch-termix-tailscale-serve-from-path-](./quick/260328-lf9-switch-termix-tailscale-serve-from-path-/) |

## Session Continuity

Last session: 2026-03-28T15:51:13.252Z
Last activity: 2026-03-28 - Completed quick task 260328-lf9: Switch Termix Tailscale Serve from path route to dedicated 8443 port
Stopped at: Completed quick-260328-lf9-PLAN.md
Resume file: None
