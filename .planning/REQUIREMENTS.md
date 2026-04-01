# Requirements: Modular NixOS Fleet Infrastructure

**Defined:** 2026-03-21
**Core Value:** Bring up and operate a clear, reproducible, low-complexity first NixOS host that establishes the right foundation for future fleet growth.

## v1 Requirements

Requirements for the initial release. Each maps to exactly one roadmap phase.

### Repository

- [x] **REPO-01**: Operator can use a fleet-oriented flake entrypoint and canonical directory layout that separates host identity from reusable modules.
- [x] **REPO-02**: Operator can understand the active architecture, decisions, and migration direction from repository docs without relying on legacy `dev-vps` assumptions.
- [x] **REPO-03**: Operator can extend the repository for a future second host without restructuring the core layout again.

### Bootstrap

- [x] **BOOT-01**: Operator can bootstrap `oci-melb-1` from repository-defined state using a remote install flow.
- [x] **BOOT-02**: Operator can declare the `oci-melb-1` disk layout in code rather than manual partitioning steps.
- [x] **BOOT-03**: Operator can rebuild `oci-melb-1` repeatably from the flake after initial installation.

### Secrets

- [x] **SECR-01**: Operator can store fleet-shared secrets separately from host-specific secrets in encrypted files.
- [x] **SECR-02**: Operator can scope `.sops.yaml` recipients so adding a host does not expose existing host secrets.
- [x] **SECR-03**: Operator can follow a documented two-step secret bootstrap for new host bring-up.
- [x] **SECR-04**: Operator can keep Tailscale enrollment material host-scoped instead of using one reusable shared credential.

### Access

- [x] **ACCS-01**: Operator can reach `oci-melb-1` privately over Tailscale without making services public.
- [x] **ACCS-02**: Operator can use a documented break-glass recovery path if Tailscale or SSH configuration fails.

### Storage

- [x] **STOR-01**: Operator can mount one persistent data volume for `oci-melb-1` using stable identifiers.
- [x] **STOR-02**: Operator can keep Syncthing, Navidrome, and related service data in predictable directories on that persistent mount.

### Services

- [x] **SRVC-01**: Operator can enable `tailscale` declaratively through NixOS configuration.
- [x] **SRVC-02**: Operator can enable `syncthing` declaratively with persistent paths and explicit folder modes.
- [x] **SRVC-03**: Operator can enable `navidrome` declaratively with media paths rooted on the persistent mount.
- [x] **SRVC-04**: Operator can run Syncthing with versioning or conflict safeguards that reduce accidental delete and overwrite risk.
- [x] **SRVC-05**: Operator can have Navidrome read directly from the Syncthing-managed media path without duplicate staging storage.

### Operations

- [x] **OPER-01**: Operator can apply routine configuration changes to `oci-melb-1` through a straightforward host-targeted update workflow.
- [x] **OPER-02**: Operator can keep architecture, plan, and decision documents current when implementation changes behavior or trust boundaries.

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

- [x] **MEDI-01**: Operator can migrate from direct Syncthing-managed media paths to an authority-based ingest flow when operational pressure justifies it.
- **MEDI-02**: Operator can run Beets against `/srv/media/inbox` as an inbox-only singleton tagger without copying, moving, or linking files out of inbox.
- **MEDI-03**: Operator can trigger Beets tagging automatically from new `slskd` inbox arrivals while keeping reports and unresolved outcomes under `/srv/data/beets`.
- **MEDI-04**: Operator can use Discogs, Beatport, and Bandcamp metadata sources for inbox tagging while leaving low-confidence files untouched for manual follow-up.

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
| REPO-01 | Phase 1 | Complete |
| REPO-02 | Phase 1 | Complete |
| REPO-03 | Phase 1 | Complete |
| BOOT-01 | Phase 3 | Complete |
| BOOT-02 | Phase 3 | Complete |
| BOOT-03 | Phase 3 | Complete |
| SECR-01 | Phase 2 | Complete |
| SECR-02 | Phase 2 | Complete |
| SECR-03 | Phase 2 | Complete |
| SECR-04 | Phase 2 | Complete |
| ACCS-01 | Phase 3 | Complete |
| ACCS-02 | Phase 3 | Complete |
| STOR-01 | Phase 3 | Complete |
| STOR-02 | Phase 3 | Complete |
| SRVC-01 | Phase 3 | Complete |
| SRVC-02 | Phase 4 | Complete |
| SRVC-03 | Phase 4 | Complete |
| SRVC-04 | Phase 4 | Complete |
| SRVC-05 | Phase 4 | Complete |
| OPER-01 | Phase 3 | Complete |
| OPER-02 | Phase 1 | Complete |
| MEDI-01 | Phase 04.2 | Complete |
| MEDI-02 | Phase 04.1 | Complete |
| MEDI-03 | Phase 04.1 | Complete |
| MEDI-04 | Phase 04.1 | Complete |

**Coverage:**
- v1 requirements: 21 total
- v2 requirements: 8 total
- Mapped to phases: 24
- Unmapped: 8

---
*Requirements defined: 2026-03-21*
*Last updated: 2026-03-21 after roadmap creation*
