# Project Research Summary

**Project:** Modular NixOS Fleet Infrastructure
**Domain:** Modular NixOS homelab fleet infrastructure
**Researched:** 2026-03-21
**Confidence:** HIGH

## Executive Summary

This project is a host-centric NixOS fleet repository, not a generic self-hosting repo and not the old `dev-vps` layout with extra modules bolted on. The research consistently points to a simple expert pattern: pin a stable NixOS flake, model each machine under `hosts/<host>/`, keep reusable logic in thin profiles and service modules, and bootstrap the first Oracle ARM host with `nixos-anywhere` plus `disko`. For the current milestone, success means `oci-melb-1` can be rebuilt from declared state, reached privately over Tailscale, and run `syncthing` plus `navidrome` on a predictable persistent mount.

The recommended approach is deliberately conservative. Use `nixos-25.11`, `sops-nix` with `age`, a two-step secrets bootstrap, Tailscale-first private access, and direct Syncthing-to-Navidrome media flow. Defer deploy frameworks, public ingress, backup automation, and ingest pipelines until the first host is stable. That keeps the repo operationally boring while still preserving the boundaries needed for future multi-host growth.

The main risks are structural drift and bootstrap sharp edges. The biggest failure modes are letting legacy `dev-vps` patterns survive, broadening secret recipients too early, assuming x86-style `nixos-anywhere` behavior on OCI ARM, and treating private-only access as sufficient recovery design. Mitigate them by cutting over to one canonical repo shape early, encoding `.sops.yaml` trust boundaries before adding secrets, proving the exact `aarch64` install path before service rollout, and keeping serial-console break-glass access documented before Tailscale becomes the primary admin path.

## Key Findings

### Recommended Stack

The stack recommendation is clear and cohesive: stable NixOS with flakes for reproducibility, `nixos-anywhere` plus `disko` for remote bootstrap, `sops-nix` plus `age` for encrypted Git-managed secrets, and native NixOS services for the initial private service baseline. The first host should stay simple: GPT + EFI + ext4 root + one ext4 data mount, `nixos-rebuild --target-host` for updates, and `deploy-rs` only after additional hosts create real fan-out pressure.

**Core technologies:**
- `NixOS 25.11` - base OS and package set; stable enough for first-host bring-up while the repo shape is still changing.
- `Flakes` - reproducible repo entrypoint; one lockfile and one canonical build path for all hosts.
- `nixos-anywhere` - remote bootstrap; standard SSH-driven install flow for new machines.
- `disko` - declarative partitioning; keeps disk layout in code instead of runbooks.
- `sops-nix` + `sops` + `age` - secret management; encrypted-in-Git with activation-time decryption and simpler operations than GPG.
- `deploy-rs` - later multi-host deployment path; useful after the repo has more than one or two active hosts.
- `nixos-facter` - hardware fact capture; reduces hand-written OCI/UEFI guesses.

**Critical version requirements:**
- Pin `nixpkgs` to `nixos-25.11` for the baseline.
- Use `nixos-anywhere` `1.13.0` with `disko` `1.13.0`-line compatibility.
- Treat `sops-nix` as a pinned flake input and pair it with current `sops` and `age`.

### Expected Features

The v1 capability set is mostly table-stakes infra work, not product flourish. The repo must prove deterministic first-host bootstrap, scoped secrets, private access, predictable persistent storage, declarative service modules, Syncthing safety controls, and a simple update path. Differentiators like smoke tests and fleet-ready scaffolding matter next, but they are only valuable once the baseline actually works.

**Must have (table stakes):**
- Deterministic first-host bootstrap for `oci-melb-1`.
- Host-centric modular layout that separates host identity from reusable logic.
- Scoped secrets with explicit blast radius in `.sops.yaml`.
- Private access baseline via Tailscale with no public ingress.
- Native modules for `tailscale`, `syncthing`, and `navidrome`.
- Persistent storage model with stable service paths.
- Syncthing versioning and intentional folder modes.
- Straightforward host update workflow.

**Should have (competitive):**
- Bootstrap smoke tests and flake checks.
- Fleet-ready host scaffolding for host two.
- Per-service secret templating and restart wiring.
- Service health assertions and post-deploy verification.

**Defer (v2+):**
- Multi-arch validation gates until a second architecture is real.
- Tailscale role/tag expansion for multiple service classes.
- Authority-based media ingest and `rclone`/VFS evolution.
- Fleet deploy framework or orchestration stack before simple host-targeted updates stop being enough.

### Architecture Approach

The architecture research strongly favors host-first assembly with thin, explicit layers. `flake.nix` should assemble `nixosConfigurations` from small inventory metadata, each host directory should own identity and provider quirks, profiles should compose intent, service modules should expose options rather than bake in assumptions, and secrets should enter only at the edges. The first host should remain the proving ground for these boundaries instead of abstracting for imaginary future consumers.

**Major components:**
1. `flake.nix` plus `lib/` - pins inputs and assembles hosts consistently.
2. `hosts/oci-melb-1/` - owns host identity, hardware facts, networking, disk mapping, and host secrets references.
3. `modules/core/` and `modules/profiles/` - define shared server policy and reusable compositions.
4. `modules/services/` - encapsulate `tailscale`, `syncthing`, and `navidrome` behind explicit options and paths.
5. `.sops.yaml`, `secrets/common.yaml`, and `hosts/*/secrets.yaml` - enforce trust boundaries for secret access.

### Critical Pitfalls

1. **Dual-mission repo drift** - cut over early to one fleet-oriented layout and archive or remove legacy `dev-vps` paths and docs.
2. **Over-broad secret scope** - default to host-scoped secret files, keep `secrets/common.yaml` minimal, and review recipients as a trust-boundary change.
3. **ARM bootstrap assumptions** - prove the exact OCI `aarch64` install path instead of assuming default x86_64 `nixos-anywhere` behavior.
4. **No break-glass access** - validate OCI serial-console recovery before making Tailscale the primary admin path.
5. **Unsafe Syncthing + Navidrome data model** - enable versioning, define library authority, and keep Navidrome read-only on the music tree.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Repository Cutover And Skeleton
**Rationale:** Everything else depends on one authoritative repo shape and removal of legacy mission drift.
**Delivers:** Fleet-oriented flake entrypoint, `hosts/`, `modules/`, `lib/`, scoped secret locations, and cleaned-up docs/entrypoints.
**Addresses:** Host-centric modular layout, authoritative docs, future host growth without rewrite.
**Avoids:** Dual-mission repo drift and premature over-abstraction.

### Phase 2: Secrets And Identity Bootstrap
**Rationale:** Secrets scope and identity ordering must exist before access or service rollout.
**Delivers:** `.sops.yaml` policy, `secrets/common.yaml`, `hosts/oci-melb-1/secrets.yaml`, `age` recipient model, and two-step bootstrap plan.
**Uses:** `sops-nix`, `sops`, `age`, `ssh-to-age`.
**Implements:** Secret policy boundary between shared and host-scoped data.
**Avoids:** Broad recipient rules and first-boot decryption failures.

### Phase 3: OCI Host Bootstrap And Persistence
**Rationale:** The exact ARM install path and stable storage layout must be proven before higher-level services are debugged.
**Delivers:** `oci-melb-1` host assembly, provider-specific networking, `disko` layout, fact capture, persistent mount conventions, and reinstall docs.
**Uses:** `nixos-anywhere`, `disko`, `nixos-facter`, `nixos-25.11`.
**Implements:** Host-first assembly and provider/storage isolation.
**Avoids:** x86 bootstrap assumptions, unstable device naming, and hidden filesystem assumptions.

### Phase 4: Private Access Baseline
**Rationale:** Management access must be reliable before service exposure.
**Delivers:** SSH baseline, Tailscale enrollment, host naming, minimal ACL/tag posture, and documented break-glass recovery.
**Addresses:** Private access baseline and straightforward host operations.
**Avoids:** Lockout after Tailscale cutover and over-trusting private-only defaults.

### Phase 5: Service Baseline And Data Safety
**Rationale:** Services should land only after storage, secrets, and access are stable.
**Delivers:** Declarative `tailscale`, `syncthing`, and `navidrome` modules in active use; persistent paths; Syncthing versioning; Navidrome read-only media access; manual recovery posture.
**Addresses:** Native service modules, persistent storage model, Syncthing safety controls, initial private service baseline.
**Avoids:** Sync-driven data loss, permission drift, and accidental authority assumptions without backups.

### Phase 6: Validation And Fleet Readiness
**Rationale:** Once the first host is boring, add quality gates and only the next layer of scale support.
**Delivers:** `flake check`, bootstrap smoke tests, health assertions, optional `deploy-rs` checks, and host-two-friendly scaffolding.
**Addresses:** Bootstrap smoke tests, service verification, and future fleet growth.
**Avoids:** Scaling tooling too early while still preparing the repo for multi-host operation.

### Phase Ordering Rationale

- The order follows the dependency chain from research: repo shape -> secrets -> bootstrap/storage -> private access -> services -> validation.
- The grouping matches the architecture boundaries, so host identity, provider quirks, services, and secrets stay cleanly separated.
- This sequencing directly reduces the highest-risk pitfalls by proving trust boundaries and recovery paths before user-facing workloads depend on them.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3:** OCI ARM bootstrap specifics, installer fallback path, and stable OCI device mapping should stay under active validation.
- **Phase 4:** Tailscale ACL/tag policy and break-glass recovery details may need targeted planning to avoid tailnet overexposure or lockout.
- **Phase 5:** Syncthing authority, delete/conflict policy, and acceptable-loss posture need explicit operational decisions.

Phases with standard patterns (skip research-phase):
- **Phase 1:** Host-centric repo restructuring is well-supported by existing project docs and architecture research.
- **Phase 2:** `sops-nix` plus `age` path-scoped secret design is well-documented and already aligned across research outputs.
- **Phase 6:** Flake checks and smoke-test scaffolding are standard follow-on work once the host baseline exists.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Based mostly on official NixOS, `nixos-anywhere`, `disko`, `sops-nix`, Tailscale, Syncthing, and Navidrome sources with concrete version guidance. |
| Features | MEDIUM | Strongly grounded in project intent and official docs, but prioritization of differentiators is more inferred than directly validated by upstream sources. |
| Architecture | HIGH | Architecture patterns align tightly with NixOS module design norms and the project's own documented target state. |
| Pitfalls | HIGH | Major risks are backed by official tool behavior and concrete OCI/Tailscale/Syncthing sharp edges, with only some OCI+A1 failure modes remaining situational. |

**Overall confidence:** HIGH

### Gaps to Address

- ARM bootstrap fallback details - confirm the exact `nixos-anywhere` flow, recovery path, and any OCI image/kexec caveats before phase execution.
- Secret bootstrap timing - validate which secrets are needed at install time, first boot, activation, and steady state so `neededForUsers` and persisted key paths are correct.
- Tailnet policy shape - decide the minimum viable host tags, ACLs, and approval model before services go live.
- Data authority and recovery posture - define which copy of the media library is authoritative during v1 and document manual restore expectations before calling the host stable.
- Mixed-arch growth triggers - defer cross-arch validation work until another architecture is real, but define the trigger so it does not stay vague.

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` - official-source-backed stack, versions, and first-host recommendations.
- `.planning/research/ARCHITECTURE.md` - host-first layout, component boundaries, and build-order guidance.
- `.planning/research/PITFALLS.md` - phase-specific risks grounded in NixOS, OCI, Tailscale, Syncthing, and Navidrome behavior.
- `.planning/PROJECT.md` - project goals, constraints, and active requirements.
- https://nixos.org/download/ - stable NixOS and Nix release line confirmation.
- https://github.com/nix-community/nixos-anywhere and docs - bootstrap flow and ARM caveats.
- https://github.com/nix-community/disko - declarative disk layout patterns.
- https://github.com/Mic92/sops-nix - activation-time secret handling and `age` workflow.
- https://tailscale.com/kb/1085/auth-keys - tagged and scoped key guidance.
- https://docs.syncthing.net/users/versioning.html - versioning and sync safety behavior.

### Secondary (MEDIUM confidence)
- `.planning/research/FEATURES.md` - feature prioritization, differentiators, and anti-features synthesized from project context plus official docs.
- Oracle Cloud serial console and consistent device path docs - provider recovery and storage mapping guidance.

### Tertiary (LOW confidence)
- None material; remaining uncertainty is mostly implementation-specific validation rather than source quality.

---
*Research completed: 2026-03-21*
*Ready for roadmap: yes*
