# Feature Research

**Domain:** modular NixOS homelab fleet repository for first-host bootstrap and private service baseline
**Researched:** 2026-03-21
**Confidence:** MEDIUM

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = repo feels incomplete or unsafe.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Deterministic first-host bootstrap | A modern NixOS infra repo must be able to turn a fresh VM into a working host from the repo, not from ad-hoc shell history. | MEDIUM | Use `nixos-anywhere` with flake-driven install, declarative disk layout, and generated hardware config capture. This is the single strongest v1 credibility signal. |
| Host-centric modular layout | Fleet repos are expected to separate host identity from reusable service logic so adding host two does not force a rewrite. | MEDIUM | `hosts/<host>` for composition plus reusable `modules/services` and `modules/profiles`. Essential for later fleet growth. |
| Scoped secrets with explicit blast radius | Infra users expect secrets to be committed encrypted and scoped so adding a new host does not leak existing credentials. | MEDIUM | Split common vs host secrets, enforce `.sops.yaml` recipient rules, prefer host-specific Tailscale enrollment material. |
| Private access baseline via Tailscale | For a private homelab baseline, secure remote access without public exposure is expected. | LOW | Treat Tailscale as the management plane first. Use one-off or tagged auth keys and avoid making services Internet-facing in v1. |
| Native service modules for `tailscale`, `syncthing`, and `navidrome` | A credible v1 should declare the initial services in NixOS, not depend on hand-managed app state. | MEDIUM | Each service should have an enable flag, predictable ports/paths, sane users/groups, and data paths anchored on the persistent mount. |
| Persistent storage model with predictable service paths | Self-hosted media and sync services are not credible if data placement is ad hoc or tied to ephemeral root disk paths. | MEDIUM | Keep the current one-mount model, with stable mount identifiers and clear subdirectories for media, sync, and service state. |
| Syncthing safety controls | Bidirectional sync without guardrails is a known foot-gun; users expect versioning and recoverability. | MEDIUM | Configure send-receive folders intentionally, enable file versioning, and document conflict/delete behavior. |
| Straightforward host update workflow | After bootstrap, operators expect a simple rebuild path for changes and rollback-oriented operations. | LOW | A host-targeted `nixos-rebuild` or equivalent is enough for v1; defer fleet deploy tooling until a second host creates pressure. |
| Authoritative docs for intent and operations | In infra repos, stale docs quickly become operational risk; users expect architecture, decisions, and plan docs to stay current. | LOW | This repo already treats docs as control-plane artifacts; keep that discipline in v1. |

### Differentiators (Competitive Advantage)

Features that set the repo apart. Not required for v1 credibility, but valuable once the baseline works.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Bootstrap smoke tests (`--vm-test` and host checks) | Makes first-host changes safer and turns bootstrap reliability from belief into evidence. | MEDIUM | Add preflight validation for flake, disk layout, and service enablement before touching the OCI host. |
| Fleet-ready host scaffolding | Makes host two materially easier by providing clear templates for provider-specific and provider-agnostic composition. | MEDIUM | Valuable after `oci-melb-1` stabilizes; not mandatory before that. |
| Per-service secret templating and restart wiring | Reduces secret sprawl and makes secret rotation operationally clean. | MEDIUM | `sops-nix` templates and `restartUnits` are a strong quality-of-life feature once services grow beyond simple auth keys. |
| Multi-arch validation gates | Differentiates the repo as truly fleet-ready instead of “works on one Oracle ARM box.” | HIGH | Add checks that keep modules portable across `aarch64-linux` and later `x86_64-linux` hosts. |
| Tailscale role/tag strategy for service classes | Gives the fleet a cleaner security model than per-device snowflakes. | MEDIUM | Use tagged auth keys and ACL-aware tagging once more hosts or service roles exist. |
| Service health assertions and post-deploy verification | Converts “deployed” into “operational” by checking Syncthing reachability, Navidrome readiness, and Tailscale connectivity. | MEDIUM | Best added after the first stable deployment path exists. |
| Controlled migration path from bidirectional sync to authority-based media ingest | Preserves current workflow while preparing for later `rclone`/VFS or ingest processing without a second repository redesign. | HIGH | Valuable later, but premature for the first-host milestone. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem attractive now but would make this repo worse in the current milestone.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Early Kubernetes / `k3s` / `keda` | Feels “future-proof” and looks like the next logical step for a fleet. | It front-loads orchestration complexity before the repo has proven first-host bootstrap, service persistence, or secrets posture. | Keep native NixOS services and revisit orchestration only after multiple real workloads need scheduling. |
| Public reverse proxy or Internet exposure in v1 | Makes services easy to access and feels more “complete.” | It expands the attack surface before private access, host hardening, and service behavior are stable. | Keep services Tailscale-only and defer public edge design. |
| Backup automation before data authority is settled | Sounds responsible, especially for media and sync workloads. | It locks in assumptions about source of truth while Syncthing mode, storage layout, and future ingest direction are still evolving. | Document manual recovery posture now and add backups after the baseline stabilizes. |
| Fleet deployment tooling before host two exists | Promises scale and consistency. | It adds operational overhead without solving the immediate problem better than host-targeted rebuilds. | Keep the repo structurally compatible with later tooling, but defer the tool itself. |
| Duplicate ingest/staging datasets for media on day one | Feels cleaner architecturally for future processing. | It wastes storage and adds path complexity before there is any actual processing pipeline. | Let Navidrome read the Syncthing-managed path directly for v1. |
| Highly dynamic abstractions for every provider/service | Looks elegant and reusable. | It usually hides the concrete OCI bootstrap work that actually needs to be debugged first. | Keep provider specifics isolated, but bias toward explicit modules over clever meta-abstractions. |

## Feature Dependencies

```text
Deterministic first-host bootstrap
    ├──requires──> Host-centric modular layout
    ├──requires──> Scoped secrets with explicit blast radius
    └──requires──> Persistent storage model with predictable service paths

Private access baseline via Tailscale
    └──requires──> Scoped secrets with explicit blast radius

Native service modules for tailscale/syncthing/navidrome
    ├──requires──> Persistent storage model with predictable service paths
    └──enhances──> Straightforward host update workflow

Syncthing safety controls
    └──requires──> Native service modules for tailscale/syncthing/navidrome

Bootstrap smoke tests
    └──enhances──> Deterministic first-host bootstrap

Fleet-ready host scaffolding
    └──requires──> Host-centric modular layout

Public reverse proxy or Internet exposure in v1
    └──conflicts──> Private access baseline via Tailscale

Early Kubernetes / k3s / keda
    └──conflicts──> Straightforward host update workflow
```

### Dependency Notes

- **Deterministic first-host bootstrap requires modular layout, secrets scope, and storage structure:** installation is only repeatable when host identity, secrets policy, and mount topology are all declared coherently.
- **Private access baseline requires scoped secrets:** Tailscale auth material is part of bootstrap trust and should be host-scoped, not broadly shared.
- **Native service modules require the persistent storage model:** Syncthing and Navidrome become brittle if mount points and data paths are not stable first.
- **Syncthing safety controls require the base service module:** versioning, folder mode, and conflict behavior only matter once Syncthing is expressed declaratively.
- **Bootstrap smoke tests enhance first-host bootstrap:** they reduce the chance that OCI-specific mistakes are discovered only on the real host.
- **Public exposure conflicts with the private baseline:** doing both at once muddies security posture and phase boundaries.
- **Early orchestration conflicts with the simple update workflow:** it solves a future fleet problem by making the present single-host problem harder.

## MVP Definition

### Launch With (v1)

Minimum viable product - what is needed to validate the new repository direction.

- [ ] Deterministic first-host bootstrap - proves the repo can create `oci-melb-1` from declared state.
- [ ] Scoped secrets with explicit blast radius - keeps bootstrap and future host addition safe enough to scale later.
- [ ] Private Tailscale access baseline - gives reliable remote administration and private service exposure without public edge work.
- [ ] Persistent storage model with stable service paths - gives Syncthing and Navidrome a trustworthy place to live.
- [ ] Native service modules for `tailscale`, `syncthing`, and `navidrome` - validates the repository mission with real workloads.
- [ ] Syncthing safety controls - avoids turning “works” into “accidentally deleted the library.”
- [ ] Straightforward host update workflow - keeps post-bootstrap operations simple and repeatable.

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Bootstrap smoke tests - add once the first real install path exists and can be encoded as checks.
- [ ] Per-service secret templating and restart wiring - add when service configs need embedded secrets and rotation.
- [ ] Service health assertions and post-deploy verification - add when baseline deployment succeeds often enough to automate validation.
- [ ] Fleet-ready host scaffolding - add when host two becomes a committed milestone.

### Future Consideration (v2+)

Features to defer until the baseline and growth pattern are proven.

- [ ] Multi-arch validation gates - defer until a second architecture actually enters the fleet.
- [ ] Tailscale role/tag strategy for multiple service classes - defer until there are enough devices to justify the policy surface.
- [ ] Authority-based media ingest and `rclone`/VFS transition - defer until current bidirectional sync becomes an operational constraint.
- [ ] Orchestration stack or fleet deployment framework - defer until simple host-targeted updates stop being sufficient.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Deterministic first-host bootstrap | HIGH | MEDIUM | P1 |
| Scoped secrets with explicit blast radius | HIGH | MEDIUM | P1 |
| Private access baseline via Tailscale | HIGH | LOW | P1 |
| Native service modules for `tailscale`, `syncthing`, and `navidrome` | HIGH | MEDIUM | P1 |
| Persistent storage model with predictable service paths | HIGH | MEDIUM | P1 |
| Syncthing safety controls | HIGH | MEDIUM | P1 |
| Straightforward host update workflow | HIGH | LOW | P1 |
| Bootstrap smoke tests | MEDIUM | MEDIUM | P2 |
| Fleet-ready host scaffolding | MEDIUM | MEDIUM | P2 |
| Per-service secret templating and restart wiring | MEDIUM | MEDIUM | P2 |
| Multi-arch validation gates | MEDIUM | HIGH | P3 |
| Authority-based media ingest transition | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Sources

- Local project intent and constraints: `.planning/PROJECT.md`, `docs/architecture.md`, `docs/decisions.md`, `docs/plan.md`, `docs/context-history.md`
- `nixos-anywhere` quickstart: https://raw.githubusercontent.com/nix-community/nixos-anywhere/main/docs/quickstart.md
- `sops-nix` README: https://raw.githubusercontent.com/Mic92/sops-nix/master/README.md
- Syncthing folder modes: https://docs.syncthing.net/users/foldertypes.html
- Syncthing file versioning: https://docs.syncthing.net/users/versioning.html
- Tailscale auth keys and tagged/pre-approved/ephemeral device patterns: https://tailscale.com/kb/1085/auth-keys

## Confidence Notes

- **HIGH confidence:** v1 table stakes around bootstrap, secrets scoping, private access, storage, and service baseline because they are directly supported by the project documents and official tool docs.
- **MEDIUM confidence:** differentiators around fleet scaffolding, health assertions, and multi-arch validation because they are strong ecosystem patterns but not explicitly required by upstream tooling.
- **LOW confidence:** none asserted as primary recommendations; broad ecosystem web search was unavailable, so recommendations are intentionally grounded in project context plus official documentation rather than trend claims.

---
*Feature research for: modular NixOS homelab fleet repository*
*Researched: 2026-03-21*
