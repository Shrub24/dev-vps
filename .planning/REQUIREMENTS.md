# Requirements: Modular NixOS Fleet Infrastructure

**Defined:** 2026-03-21
**Core Value:** Bring up and operate a clear, reproducible, low-complexity first NixOS host that establishes the right foundation for future fleet growth.

## v1 Requirements

Requirements for the initial release. Each maps to exactly one roadmap phase.

### Repository

- [ ] **REPO-01**: Operator can use a fleet-oriented flake entrypoint and canonical directory layout that separates host identity from reusable modules.
- [ ] **REPO-02**: Operator can understand the active architecture, decisions, and migration direction from repository docs without relying on legacy `dev-vps` assumptions.
- [ ] **REPO-03**: Operator can extend the repository for a future second host without restructuring the core layout again.

### Bootstrap

- [ ] **BOOT-01**: Operator can bootstrap `oci-melb-1` from repository-defined state using a remote install flow.
- [ ] **BOOT-02**: Operator can declare the `oci-melb-1` disk layout in code rather than manual partitioning steps.
- [ ] **BOOT-03**: Operator can rebuild `oci-melb-1` repeatably from the flake after initial installation.

### Secrets

- [ ] **SECR-01**: Operator can store fleet-shared secrets separately from host-specific secrets in encrypted files.
- [ ] **SECR-02**: Operator can scope `.sops.yaml` recipients so adding a host does not expose existing host secrets.
- [ ] **SECR-03**: Operator can follow a documented two-step secret bootstrap for new host bring-up.
- [ ] **SECR-04**: Operator can keep Tailscale enrollment material host-scoped instead of using one reusable shared credential.

### Access

- [ ] **ACCS-01**: Operator can reach `oci-melb-1` privately over Tailscale without making services public.
- [ ] **ACCS-02**: Operator can use a documented break-glass recovery path if Tailscale or SSH configuration fails.

### Storage

- [ ] **STOR-01**: Operator can mount one persistent data volume for `oci-melb-1` using stable identifiers.
- [ ] **STOR-02**: Operator can keep Syncthing, Navidrome, and related service data in predictable directories on that persistent mount.

### Services

- [ ] **SRVC-01**: Operator can enable `tailscale` declaratively through NixOS configuration.
- [ ] **SRVC-02**: Operator can enable `syncthing` declaratively with persistent paths and explicit folder modes.
- [ ] **SRVC-03**: Operator can enable `navidrome` declaratively with media paths rooted on the persistent mount.
- [ ] **SRVC-04**: Operator can run Syncthing with versioning or conflict safeguards that reduce accidental delete and overwrite risk.
- [ ] **SRVC-05**: Operator can have Navidrome read directly from the Syncthing-managed media path without duplicate staging storage.

### Operations

- [ ] **OPER-01**: Operator can apply routine configuration changes to `oci-melb-1` through a straightforward host-targeted update workflow.
- [ ] **OPER-02**: Operator can keep architecture, plan, and decision documents current when implementation changes behavior or trust boundaries.

## v2 Requirements

Deferred until the baseline is proven.

### Validation

- **VALI-01**: Operator can run bootstrap smoke tests before touching the real OCI host.
- **VALI-02**: Operator can run service health assertions and post-deploy verification for the baseline services.

### Fleet Growth

- **FLEE-01**: Operator can scaffold a second host from a reusable host template with minimal duplication.
- **FLEE-02**: Operator can validate modules across both `aarch64-linux` and `x86_64-linux` once a second architecture exists.
- **FLEE-03**: Operator can adopt a fleet deployment framework when simple host-targeted updates stop being sufficient.

### Secrets And Policy

- **POLI-01**: Operator can template per-service secrets and wire service restarts to secret rotation.
- **POLI-02**: Operator can manage Tailscale roles, tags, and ACL strategy for multiple service classes.

### Media Evolution

- **MEDI-01**: Operator can migrate from direct Syncthing-managed media paths to an authority-based ingest flow when operational pressure justifies it.

## Out of Scope

Explicitly excluded for the current planning window.

| Feature | Reason |
|---------|--------|
| Kubernetes, `k3s`, or `keda` in v1 | Adds orchestration complexity before first-host bootstrap, storage, and secrets posture are proven. |
| Public reverse proxy or Internet-facing service exposure in v1 | Expands attack surface before private access and recovery posture are stable. |
| Backup automation before data authority is settled | Risks locking in the wrong source-of-truth assumptions while sync and storage behavior are still evolving. |
| Fleet deployment tooling before host two exists | Adds operational overhead without improving the immediate single-host baseline enough to justify it. |
| Duplicate ingest or staging datasets for media in v1 | Wastes storage and adds path complexity before there is a real processing pipeline. |
| Highly dynamic provider or service meta-abstractions in v1 | Hides the concrete OCI and first-host work that needs explicit debugging and validation. |

## Traceability

Which phases cover which requirements. This section is populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| REPO-01 | Phase 1 | Pending |
| REPO-02 | Phase 1 | Pending |
| REPO-03 | Phase 1 | Pending |
| BOOT-01 | Phase 3 | Pending |
| BOOT-02 | Phase 3 | Pending |
| BOOT-03 | Phase 3 | Pending |
| SECR-01 | Phase 2 | Pending |
| SECR-02 | Phase 2 | Pending |
| SECR-03 | Phase 2 | Pending |
| SECR-04 | Phase 2 | Pending |
| ACCS-01 | Phase 3 | Pending |
| ACCS-02 | Phase 3 | Pending |
| STOR-01 | Phase 3 | Pending |
| STOR-02 | Phase 3 | Pending |
| SRVC-01 | Phase 3 | Pending |
| SRVC-02 | Phase 4 | Pending |
| SRVC-03 | Phase 4 | Pending |
| SRVC-04 | Phase 4 | Pending |
| SRVC-05 | Phase 4 | Pending |
| OPER-01 | Phase 3 | Pending |
| OPER-02 | Phase 1 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0

---
*Requirements defined: 2026-03-21*
*Last updated: 2026-03-21 after roadmap creation*
