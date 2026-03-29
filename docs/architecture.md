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

- `hosts/oci-melb-1/default.nix` as the active first-host entrypoint today
- `hosts/<host>/default.nix` for host composition
- `hosts/<host>/secrets.yaml` for host-scoped encrypted values
- `modules/providers/oci/default.nix` for OCI-specific host-safe defaults
- `modules/storage/disko-root.nix` for active declarative root disk layout
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

Accepted advanced alternative:

- pre-generated host identity material can be used when first-boot decryption is required
- this is valid but is intentionally treated as a sharper option with higher bootstrap complexity

## Storage and Service Data Model

Current decision:

- one persistent service-state mount on the host (`/srv/data`)
- one dedicated media filesystem mounted at `/srv/media`
- service state organized under subdirectories on `/srv/data`

Initial media/data flow:

- Syncthing manages the library directly
- Navidrome reads from that same direct path
- `/srv/media` is the authoritative shared media library path
- `/srv/data` remains the service-state mount (`/srv/data/syncthing/config`, `/srv/data/navidrome`)
- `modules/applications/music.nix` owns the generic ingest boundary at `/srv/media/inbox` through `music-ingest`
- `modules/applications/music.nix` also defines `music-library` so `dev` and Syncthing share controlled library access
- `slskd` keeps downloads and incomplete state under `/srv/media` (`/srv/media/inbox/slskd` and `/srv/media/slskd/incomplete`)
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
- iterative host updates via simple host-targeted rebuild flow
- fleet deployment tooling introduced after first host stabilization

Fleet tooling posture:

- structure now for future fleet tools
- defer operational overhead until needed

## Known Risks and Constraints

- cloud disk naming can vary; stable identifiers are required for reliable runtime mounts
- bidirectional sync can propagate accidental deletes; versioning and conflict policies are mandatory
- temporary no-backup stance is acceptable only while data authority is still evolving
- aggressive cleanup introduces migration churn; documentation must remain authoritative throughout transition
