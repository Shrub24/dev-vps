# Modular NixOS Fleet Infrastructure

## What This Is

This repository is the infrastructure source of truth for a modular NixOS homelab fleet. It is being repurposed from a legacy `dev-vps` setup into a host-centric, service-oriented repository that can reliably bootstrap and operate `oci-melb-1` first, then expand to additional hosts, providers, and architectures over time.

## Core Value

Bring up and operate a clear, reproducible, low-complexity first NixOS host that establishes the right foundation for future fleet growth.

## Requirements

### Validated

- [x] Repository structure clearly reflects a fleet-oriented NixOS mission instead of the legacy `dev-vps` mission. *(Validated in Phase 1: Repository Cutover)*
- [x] Operator-facing architecture/decision/migration docs are canonical and current under `docs/`. *(Validated in Phase 1: Repository Cutover)*
- [x] The repository remains easy to extend to more hosts without another large structural rewrite. *(Validated in Phase 1: Repository Cutover)*
- [x] `oci-melb-1` can be bootstrapped repeatably with a reliable, debuggable first-host path. *(Validated in Phase 03: oci-host-bring-up-and-private-operations)*
- [x] Secrets management follows explicit blast-radius scoping across common and host-specific data. *(Validated in Phase 03: oci-host-bring-up-and-private-operations)*
- [x] The initial private service baseline (`tailscale`, `syncthing`, `navidrome`) works with the intended storage and access model. *(Validated in Phase 04: service-baseline-and-data-safety)*
- [x] Beets can run as an inbox-only singleton tagger on `/srv/media/inbox` with automatic `slskd` trigger flow and `/srv/data/beets` reporting/state boundaries. *(Validated in Phase 04.1: add-beets-inbox-only-singleton-ingestion-phase)*

### Active

- [ ] Beets inbox automation must satisfy the updated acceptance criteria: trigger on inbox modification, skip while `.tmp` transfer files exist, apply a settle/debounce window, run quiet native album import (`singletons: no`, `group_albums: yes`) with Beets path templates preserving original filenames, rely on native systemd single-instance execution, then sweep remaining inbox audio into `/srv/media/untagged`.

### Out of Scope

- Kubernetes, `k3s`, `keda`, and cluster scheduling now - intentionally deferred until there is concrete workload pressure.
- Internet-facing reverse proxy and public edge hardening now - services stay private and Tailscale-only during the baseline phase.
- Cloud worker architecture and processing pipeline details now - future-facing, but not needed to validate the first host.
- Production-grade backup automation now - defer until data authority and host posture are more mature.
- Early optimization for hypothetical fleet scale - clarity and operational simplicity come first.

## Context

The repository originally centered on a single-machine developer VPS workflow with Home Manager customization, CodeNomad access, and `repo-sync` assumptions. The project intentionally pivoted toward a modular multi-host NixOS homelab fleet, with Oracle Cloud Free Tier as the first concrete deployment target.

Current architecture intent is already documented in `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, and `docs/context-history.md`. Those documents establish a native-service-first direction, a host-centric module layout, Tailscale-first private access, and a scoped secrets model. They also make clear that the migration should aggressively remove legacy direction instead of letting two repository missions coexist.

Research and prior planning already converged on a practical first-host posture: use `nixos-anywhere` for bootstrap, keep provider specifics isolated from reusable modules, start with one persistent data mount, run Syncthing in bidirectional mode with safety controls, and let Navidrome read directly from the sync-managed media path. Future hooks, `rclone`/VFS authority, public exposure, and more advanced fleet tooling are all intentionally deferred until operational pressure justifies them.

Phase 01.1 completed the provider/storage modularization cutover (`modules/providers/oci/default.nix`, `modules/storage/disko-root.nix`) and retired legacy `nixos/*.nix` implementation files, keeping docs and active architecture paths aligned.

Phase 01.1.1 completed legacy config migration cleanup by removing retired operator defaults, migrating secret scaffold naming to `secrets/common.template.yaml`, and refreshing `.planning/codebase` architecture maps to the active `flake.nix` + `hosts/` + `modules/` structure.

Phase 03 completed bootstrap, access, and operations contract locking with executable `tests/phase-03-*.sh` checks, Tailscale-first runbooks, and host-targeted day-2 workflow consolidation.

Phase 04 completed direct Syncthing-to-Navidrome service-flow enforcement with explicit Syncthing mode/versioning safeguards, phase contract scripts, and a unified `verify-phase-04` operator verification command.

Phase 04.1 completed Beets inbox-only singleton ingestion with automatic file-event-driven execution from `/srv/media/inbox/slskd`, conservative non-promoting import behavior, and `/srv/data/beets` state/report ownership documented and enforced by contract tests.

Phase 04.2 completed all-inbox Beets auto-promotion by moving successful files into `/srv/media/library` with filename preservation, transfer-safe demotion sweep into `/srv/media/untagged`, and report-first unresolved tracking under `/srv/data/beets` while keeping Navidrome visibility rooted on `/srv/media`.

## Constraints

- **Platform**: First host is `oci-melb-1` on Oracle Cloud Free Tier using `aarch64-linux` - the initial solution must work on that concrete target.
- **Compatibility**: Fleet direction should support later mixed `aarch64` and `x86_64` hosts - provider-aware where needed, provider-agnostic where practical.
- **Security**: Secrets must be scoped by blast radius with explicit `.sops.yaml` rules - adding a host must not implicitly expose existing secrets.
- **Network**: Management and service access are private and Tailscale-first - public exposure is not part of the initial baseline.
- **Operations**: First-host bring-up should favor reliability, recoverability, and break-glass access over cleverness - early networking and secret bootstrap sharp edges must stay low.
- **Migration**: Legacy `dev-vps` assumptions and stale documentation should be removed or archived coherently - avoid long-lived dual-mission drift.
- **Storage**: The initial data model uses one persistent mount with predictable service subdirectories - avoid duplicate staging datasets early.
- **Complexity**: Native NixOS services and simple rollout flow come before orchestration tooling - only add higher-complexity systems when real pressure exists.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Reposition the repository from `dev-vps` to modular fleet infrastructure | The active goal is reproducible multi-host NixOS infrastructure, not a single developer VPS workflow | Validated in Phase 1 |
| Anchor the first implementation around `oci-melb-1` | A concrete first host sharpens architecture, secrets policy, and bootstrap design | Validated in Phase 1 |
| Start with native services: `tailscale`, `syncthing`, `navidrome` | This validates the new direction faster and with lower operational complexity than early orchestration | Pending |
| Use scoped secrets split between `secrets/common.yaml` and `hosts/<host>/secrets.yaml` | This minimizes blast radius and supports future host growth safely | Pending |
| Default to two-step secret bootstrap | This lowers pre-install secret handling risk during early host bring-up | Pending |
| Keep services private and Tailscale-only for now | This reduces attack surface during the migration and first-host validation period | Pending |
| Keep Syncthing bidirectional with safety controls and let Navidrome read the direct path | This matches current workflow needs without premature ingest pipeline complexity | Pending |
| Defer fleet tooling, backup automation, and `rclone`/VFS evolution until pressure exists | The current planning window prioritizes clarity and a stable baseline over speculative architecture | Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-01 after Phase 04.2 completion*
