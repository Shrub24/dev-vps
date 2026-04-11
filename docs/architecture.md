# Architecture

## Purpose

This repository is the infrastructure source of truth for a modular NixOS homelab fleet. It is being repurposed from a single developer VPS configuration into a multi-host, service-oriented infrastructure repository.

Primary objective:

- define and operate reproducible NixOS hosts across providers and regions
- start with a small, reliable base and scale architecture over time
- keep security boundaries explicit (network, secrets, host identity)

## Scope

In scope now:

- Oracle Cloud host `oci-melb-1` as the first fleet node
- DigitalOcean host `do-admin-1` as the second fleet node
- Tailscale-first private access model
- native NixOS services: `navidrome` and `syncthing`
- modular host and service design for future multi-host growth

Out of scope for now:

- Kubernetes stack (`k3s`, `keda`) and cluster scheduling decisions
- internet-facing reverse proxy and public edge hardening
- cloud worker architecture details
- production-grade backup automation design

## Environment Model

Control plane:

- local admin machine drives builds and deployments
- first bootstrap performed with `nixos-anywhere`

First target host:

- hostname: `oci-melb-1`
- provider: Oracle Cloud Free Tier
- architecture: `aarch64-linux` (Ampere)
- network policy: management and service access over Tailscale

Fleet direction:

- future mixed architecture support (`aarch64` and `x86_64`)
- additional provider and region expansion expected
- infrastructure layout should be provider-aware but provider-agnostic where practical

## Design Principles

1. Native first, orchestrated later

- prefer native NixOS modules and systemd services first
- add orchestration only when concrete workload pressure appears

2. Modular composition

- host identity and composition belong in host modules
- reusable behavior belongs in service modules
- provider specifics should be isolated from workload modules

3. Security blast radius minimization

- secrets split by scope
- host-scoped secrets by default
- broad shared secrets only when clearly justified

4. Operational simplicity in early stages

- first host bootstrap should optimize for reliability and recoverability
- avoid unnecessary complexity before fleet scale requires it

## Logical Repository Shape (Target)

The exact file tree can evolve, but the intended shape is:

- `hosts/oci-melb-1/default.nix` and `hosts/do-admin-1/default.nix` as active host entrypoints
- `hosts/<host>/default.nix` for host composition
- `hosts/<host>/secrets.yaml` for host-scoped encrypted values
- `modules/providers/oci/default.nix` for OCI-specific host-safe defaults
- `modules/providers/digitalocean/default.nix` for DigitalOcean host-safe defaults
- `modules/storage/disko-root.nix` for active declarative root disk layout
- `modules/storage/disko-single-disk.nix` for single-disk host layout
- `modules/core/base.nix` for shared baseline policy
- `modules/profiles/base-server.nix` for host profile composition
- `modules/applications/music.nix` for first-pass Syncthing/Navidrome/slskd composition
- `modules/applications/admin.nix` for first-pass private admin composition
- `modules/services/tailscale.nix` for reusable service wiring
- `modules/services/termix.nix` for low-level Termix + guacd container wiring
- `modules/services/*.nix` for reusable service modules with enable flags
- `modules/profiles/*.nix` for shared profile-level composition
- `secrets/common.yaml` for tightly-scoped fleet-shared secrets
- `.sops.yaml` as central recipient policy

## Secrets Architecture

Secrets follow a scoped blast-radius model.

Global scope:

- file: `secrets/common.yaml`
- unencrypted reference: `secrets/common.template.yaml`
- contains only values intentionally shared across hosts

Host scope:

- file: `hosts/<host>/secrets.yaml`
- contains values only that host (and admin identity) should decrypt

Policy scope:

- file: `.sops.yaml`
- defines decryption recipients per file pattern using explicit rules

Operational implications:

- adding a host should not implicitly expose all existing secrets
- moving a service between hosts is an explicit security and operations decision
- per-host enrollment tokens are preferred over shared reusable tokens

## Host Identity and Bootstrap Posture

Preferred baseline:

- `nixos-anywhere` bootstrap with conservative secret bootstrapping
- two-step secrets bootstrap is the default because it reduces pre-install key handling risk
- host key bootstrap defaults to retrieving the live SSH ed25519 host key and deriving an age recipient

Accepted advanced alternative:

- pre-generated host identity material can be used when first-boot decryption is required
- this is valid but is intentionally treated as a sharper option with higher bootstrap complexity
- injected host public key bootstrap is available as an advanced override path

## Storage and Service Data Model

Current decision:

- one persistent service-state mount on the host (`/srv/data`)
- one dedicated media filesystem mounted at `/srv/media`
- service state organized under subdirectories on `/srv/data`

Initial media/data flow:

- Syncthing manages the library directly
- Syncthing manages both `/srv/media/library` and `/srv/media/quarantine` directly
- Navidrome reads from that same direct path
- `/srv/media` is the authoritative shared media library path
- `/srv/data` remains the service-state mount (`/srv/data/syncthing/config`, `/srv/data/navidrome`)
- `modules/applications/music.nix` owns the generic ingest boundary at `/srv/media/inbox` through `music-ingest`
- `/srv/media/inbox` is the ingest boundary scanned by the Beets native album-import worker
- `/srv/media/library` is the promoted canonical subtree for successful inbox candidates
- `/srv/media/quarantine/untagged` is the demotion subtree for inbox leftovers and hard failures
- `/srv/media/quarantine/approved` is the curated quarantine subtree for manually approved items and secondary promotion attempts
- quarantine ownership is `music-ingest`; ACL grants explicit `media` read-only (`r-x`/`r-X`) access and `syncthing` write access for review and sync workflows
- Syncthing folder markers are codified with tmpfiles at `/srv/media/library/.stfolder` and `/srv/media/quarantine/.stfolder` owned by `syncthing:syncthing`
- Beets worker executes transfer-safe automation: inbox modification trigger, `.tmp` lockout, settle/debounce delay, native systemd single-instance execution, native Beets album import + `paths:` placement, then post-run sweep from inbox to untagged
- secondary Beets promotion runner targets `/srv/media/quarantine/approved` with a dedicated approved-flow Beets config and without re-demoting leftovers
- Navidrome stays rooted on `/srv/media` so quarantine and promoted-library content remain visible by default
- Navidrome playlist injection hacks are removed; quarantine remains visible via media root scan only
- `modules/applications/music.nix` also defines `music-library` so `dev` and Syncthing share controlled library access
- `slskd` keeps downloads and incomplete state under `/srv/media` (`/srv/media/inbox/slskd` and `/srv/media/slskd/incomplete`)
- Beets state and import logs remain under `/srv/data/beets` (`/srv/data/beets/state`, `/srv/data/beets/logs`)
- no duplicate media staging dataset is introduced

Future evolution:

- when moving toward `rclone`/VFS and processing workflows, an ingest pipeline can be introduced
- hook-driven processing is expected later, not required for initial baseline

## Network and Access Model

Current model:

- Tailscale is the private connectivity and access fabric
- services remain private/Tailscale-only in the near term
- Termix is exposed as a private admin application over Tailscale only (no new public firewall opening)

Potential later model:

- optional internet exposure via reverse proxy or tunnel, only after baseline hardening

## Deployment Architecture

Bootstrap and rollout order:

- host installation and baseline with `nixos-anywhere`
- regular host updates via `deploy-rs` (`just deploy <host>`)
- dry-activation and validation via `just activate <host>` and `just check`

Fleet tooling posture:

- structure now for future fleet tools
- `deploy-rs` is the primary host deployment path (`deploy.nodes` in flake output)
- per-host deploy metadata is defined in `lib/deploy/hosts.nix`, with reusable wiring in `lib/deploy/default.nix`
- keep `nixos-anywhere` for bootstrap and break-glass flows; use `deploy-rs` for regular host updates
- before any bootstrap/deploy operation, run `just bootstrap-preflight host=<host>` to enforce access-safety invariants (`openssh` enabled, tcp/22 allowed, declarative `dev`/`root` SSH keys present)

Operator commands:

- deploy: `just deploy oci-melb-1` (or `just deploy do-admin-1`)
- deploy without rollback: `just deploy oci-melb-1 rollback=false`
- dry-activate: `just activate oci-melb-1`
- checks: `just check`

Note: `just deploy` takes positional host arguments (`just deploy oci-melb-1`), not `host=...`.

## Known Risks and Constraints

- cloud disk naming can vary; stable identifiers are required for reliable runtime mounts
- bidirectional sync can propagate accidental deletes; versioning and conflict policies are mandatory
- temporary no-backup stance is acceptable only while data authority is still evolving
- aggressive cleanup introduces migration churn; documentation must remain authoritative throughout transition
