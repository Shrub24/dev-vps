# Decisions

This document captures architecture and planning decisions agreed so far. It is intentionally high signal and should be updated as decisions change.

## Decision Register

## D-001: Repository mission changed from dev VPS to fleet infrastructure

Status: Accepted

Decision:

- this repository now targets modular multi-host NixOS infrastructure
- prior single-purpose `dev-vps` framing is legacy and scheduled for cleanup

Rationale:

- current goals are infrastructure reproducibility and service deployment across hosts
- old direction mixed personal environment and app-specific concerns that are now out of focus

## D-002: First host identity

Status: Accepted

Decision:

- first host is `oci-melb-1`

Rationale:

- establishes a concrete anchor for initial architecture and secrets policy

## D-003: Initial service scope

Status: Accepted

Decision:

- initial active services are `navidrome`, `syncthing`, and `tailscale`
- `k3s`, `keda`, and cloud-worker details are explicitly deferred

Rationale:

- native service baseline provides faster validation with lower complexity

## D-004: Secrets model uses blast-radius scoping

Status: Accepted

Decision:

- maintain split between:
  - `secrets/common.yaml`
  - `hosts/<hostname>/secrets.yaml`
- define recipients in `.sops.yaml` with explicit path-scoped rules

Rationale:

- minimizes unnecessary decryption access across hosts
- aligns with future fleet growth and service mobility decisions

## D-005: Tailscale enrollment tokens are host-scoped

Status: Accepted

Decision:

- prefer per-host enrollment secrets over one reusable shared key

Rationale:

- better auditability and smaller blast radius on token exposure

## D-006: Syncthing operating mode starts bidirectional with safety controls

Status: Accepted

Decision:

- start with bidirectional sync
- include versioning/conflict protections in configuration posture

Rationale:

- matches current peer-style workflow
- retains flexibility before authority centralization with later `rclone` direction

## D-007: Storage model starts with one persistent mount

Status: Accepted

Decision:

- use one data mount for now and organize service paths under it
- avoid duplicate datasets/staging initially

Rationale:

- simplest operational model
- avoids unnecessary storage overhead during early stages

## D-008: Media path is direct for now

Status: Accepted

Decision:

- Navidrome reads directly from Syncthing-managed path initially

Rationale:

- reduces complexity and storage duplication
- delayed ingest/pipeline split can be introduced when processing needs are concrete

## D-009: Deployment tooling sequence

Status: Accepted

Decision:

- bootstrap with `nixos-anywhere`
- adopt fleet deployment tooling after first host stabilization

Rationale:

- keeps first-host bring-up simpler
- avoids early operational overhead while preserving future compatibility

## D-010: Secrets bootstrap default is two-step

Status: Accepted

Decision:

- default to two-step bootstrap for secrets on new host bring-up

Rationale:

- lower risk in early bootstrap
- less pre-install handling of sensitive identity material

## D-011: Pre-generated host identity is allowed but treated as advanced

Status: Accepted (conditional)

Decision:

- pre-generated host key material can be used when first-boot secret decryption is required
- this is not the baseline path

Rationale:

- valid approach with deterministic first-boot identity
- higher operational sharpness and identity-coupling complexity than two-step bootstrap

## D-012: Cleanup posture

Status: Accepted

Decision:

- perform aggressive cleanup of legacy `dev-vps` direction on migration branch

Rationale:

- reduces confusion and maintenance burden
- reinforces clear repository mission

## D-013: Access exposure policy

Status: Accepted

Decision:

- keep services private and Tailscale-only for now

Rationale:

- minimizes attack surface during architecture transition

## D-014: Full repository cutover now (no long-lived bridge)

Status: Accepted

Decision:

- use `nixosConfigurations.oci-melb-1` as the active flake output now
- keep host identity in `hosts/oci-melb-1/default.nix`
- remove legacy `nixosConfigurations.dev-vps` and associated personal-tooling outputs from active wiring

Rationale:

- avoids dual-mission drift and broken references in active workflows
- keeps operator and CI surfaces aligned to a single canonical host target

## D-015: Reusable module boundaries are explicit in active paths

Status: Accepted

Decision:

- baseline shared policy lives in `modules/core/base.nix`
- profile composition lives in `modules/profiles/base-server.nix`
- service boundary for private access starts in `modules/services/tailscale.nix`

Rationale:

- separates host identity from reusable logic for future host growth
- keeps provider-specific concerns out of reusable modules

## D-016: Documentation authority and derivation contract

Status: Accepted

Decision:

- `docs/` is canonical for architecture, decisions, and migration direction
- `README.md` remains orientation-only with links to canonical docs
- `CLAUDE.md` is a derived mirror and must not conflict with canonical `docs/`

Rationale:

- prevents conflicting migration narratives during aggressive cutover
- keeps implementation and operator guidance synchronized

## D-017: Add a narrow applications composition layer for current host systems

Status: Accepted

Decision:

- add `modules/applications/music.nix` to compose Syncthing, Navidrome, and slskd for `oci-melb-1`
- add `modules/applications/admin.nix` to compose private admin access through Tailscale plus Termix
- keep low-level implementation in `modules/services/*.nix` and avoid broad repository reorganization

Rationale:

- introduces an explicit logical application boundary without disrupting existing host behavior
- preserves service-level reuse while making host composition easier to reason about

## D-018: Termix runs as a Tailscale-only admin application on oci-melb-1

Status: Accepted

Decision:

- implement Termix with a dedicated low-level module `modules/services/termix.nix` using Podman OCI containers (`termix` + `guacd`)
- persist Termix state under `/srv/data/termix`
- keep public exposure unchanged (no new firewall openings)

Rationale:

- adds private remote admin capability while keeping the project's Tailscale-first posture intact
- keeps runtime/container specifics isolated from host composition and canonical docs

## D-019: Music app owns generic ingest boundary and slskd is confined to service subtree

Status: Accepted

Decision:

- `modules/applications/music.nix` owns `/srv/data/inbox` as a generic ingest boundary through `music-ingest`
- `slskd` is confined to `/srv/data/inbox/slskd/{complete,incomplete}`
- Syncthing and Navidrome remain anchored on `/srv/data/media` as the authoritative library path

Rationale:

- keeps cross-service ingest ownership at the application layer instead of expanding core user/module scope
- allows future ingest producers to share one boundary while preventing slskd path sprawl
- preserves the direct authoritative media flow without reintroducing duplicate staging ownership

## Open Questions (Intentional)

These are known but intentionally unresolved until implementation and operational learning justify final decisions.

- when to introduce service-scoped secret files for movable workloads
- when and how to introduce `rclone`/VFS into media flow
- hook/event framework for future processing pipeline
- backup policy timing once host authority increases
- fleet tool choice and operating model once host count grows
