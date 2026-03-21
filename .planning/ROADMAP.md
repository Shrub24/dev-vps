# Roadmap: Modular NixOS Fleet Infrastructure

## Overview

This roadmap repurposes the repository from legacy `dev-vps` usage into a modular NixOS fleet source of truth, then proves the first concrete outcome: `oci-melb-1` can be bootstrapped, reached privately, rebuilt repeatably, and run the initial private service baseline on stable storage without reopening the repository structure later.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Repository Cutover** - Establish the fleet-oriented repo shape, docs, and growth path. (completed 2026-03-21)
- [ ] **Phase 2: Secrets Policy And Bootstrap** - Lock in scoped secret boundaries and the first-host bootstrap secret flow.
- [ ] **Phase 3: OCI Host Bring-Up And Private Operations** - Make `oci-melb-1` installable, reachable privately, and maintainable from declared state.
- [ ] **Phase 4: Service Baseline And Data Safety** - Run the initial private service baseline on persistent storage with the intended media flow.

## Phase Details

### Phase 1: Repository Cutover
**Goal**: The repository clearly operates as a modular NixOS fleet repo, not a legacy `dev-vps` repo, and is ready to absorb future hosts without another structural rewrite.
**Depends on**: Nothing (first phase)
**Requirements**: REPO-01, REPO-02, REPO-03, OPER-02
**Success Criteria** (what must be TRUE):
  1. Operator can navigate a canonical fleet-oriented flake entrypoint and directory layout that separates host identity from reusable modules.
  2. Operator can read the repository docs and understand the active architecture, decisions, and migration direction without relying on legacy `dev-vps` context.
  3. Operator can add a second host within the established layout instead of needing to restructure the repo again.
  4. Architecture, plan, and decision documents remain the authoritative place to update behavior or trust-boundary changes.
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md - Cut over to host-plus-modules skeleton and canonical flake target.
- [x] 01-02-PLAN.md - Align operator commands and CI with the new canonical host output.
- [x] 01-03-PLAN.md - Reconcile docs authority so canonical docs and entrypoints stay in sync.

### Phase 01.1: modular provider flakes + integrate and remove legacy nixos flakes (INSERTED)

**Goal:** Active host composition uses provider-modular flake wiring and legacy `nixos/*.nix` implementation paths are fully retired from the repository's active architecture.
**Requirements**: REPO-01, REPO-02, REPO-03, OPER-02
**Depends on:** Phase 01
**Plans:** 1/2 plans executed

Plans:
- [ ] 01.1-01-PLAN.md - Modularize provider and storage contracts and rewire active flake composition.
- [ ] 01.1-02-PLAN.md - Remove obsolete legacy `nixos` implementation files and reconcile canonical docs.

### Phase 2: Secrets Policy And Bootstrap
**Goal**: Secret handling is explicitly scoped by blast radius and the first-host bootstrap path has a clear, safe ordering for secret material.
**Depends on**: Phase 1
**Requirements**: SECR-01, SECR-02, SECR-03, SECR-04
**Success Criteria** (what must be TRUE):
  1. Operator can keep fleet-shared secrets and host-specific secrets in separate encrypted files with clear ownership boundaries.
  2. Operator can add a new host without that host gaining decryption access to existing host-scoped secrets.
  3. Operator can follow a documented two-step bootstrap flow for introducing secrets during new host bring-up.
  4. Operator can provision Tailscale enrollment material per host instead of reusing one shared credential across the fleet.
**Plans**: TBD

### Phase 3: OCI Host Bring-Up And Private Operations
**Goal**: `oci-melb-1` can be installed, rebuilt, reached privately, and updated through a reliable host-targeted operating path backed by stable persistent storage.
**Depends on**: Phase 2
**Requirements**: BOOT-01, BOOT-02, BOOT-03, ACCS-01, ACCS-02, STOR-01, STOR-02, SRVC-01, OPER-01
**Success Criteria** (what must be TRUE):
  1. Operator can bootstrap `oci-melb-1` remotely from repository-defined state, including its disk layout, without manual partitioning steps.
  2. Operator can rebuild `oci-melb-1` repeatably from the flake and apply routine host-targeted configuration changes with a straightforward update workflow.
  3. Operator can reach `oci-melb-1` privately over Tailscale with no public service exposure and can declaratively enable that connectivity through NixOS configuration.
  4. Operator can recover access with a documented break-glass path if Tailscale or SSH configuration fails.
  5. Operator can rely on one stable persistent data volume with predictable service directories for baseline workloads.
**Plans**: TBD

### Phase 4: Service Baseline And Data Safety
**Goal**: The initial private service stack runs on `oci-melb-1` with the intended direct media flow and enough sync safety to operate confidently.
**Depends on**: Phase 3
**Requirements**: SRVC-02, SRVC-03, SRVC-04, SRVC-05
**Success Criteria** (what must be TRUE):
  1. Operator can run Syncthing declaratively with persistent paths and explicit folder modes on the host's persistent storage.
  2. Operator can run Navidrome declaratively with media paths rooted on the persistent mount.
  3. Syncthing configuration includes conflict or versioning safeguards that reduce accidental delete and overwrite risk.
  4. Navidrome reads directly from the Syncthing-managed media path without requiring a duplicate staging dataset.
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Repository Cutover | 3/3 | Complete | 2026-03-21 |
| 2. Secrets Policy And Bootstrap | 0/TBD | Not started | - |
| 3. OCI Host Bring-Up And Private Operations | 0/TBD | Not started | - |
| 4. Service Baseline And Data Safety | 0/TBD | Not started | - |
